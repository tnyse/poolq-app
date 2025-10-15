import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Model/pick_model.dart';
import 'player_simulation_service.dart';
import 'time_simulation_service.dart';
import 'nfl_schedule_service.dart';
import 'scoring_service.dart';

/// Controller to manage the 5-player simulation lifecycle
class SimulationController {
  static final SimulationController _instance = SimulationController._internal();
  factory SimulationController() => _instance;
  SimulationController._internal();

  final PlayerSimulationService _playerSim = PlayerSimulationService();
  final TimeSimulationService _timeSim = TimeSimulationService();
  final NFLScheduleService _nflService = NFLScheduleService();
  final ScoringService _scoringService = ScoringService();

  // Simulation state
  bool _isSimulationActive = false;
  String? _currentSimulationWeek;
  List<PickModel>? _currentWeekPicks;
  Map<String, dynamic>? _currentWeekResults;

  /// Start simulation when user submits their picks
  Future<bool> startSimulation(String weekName, PickModel userPick) async {
    try {
      debugPrint('SimulationController: Starting simulation for $weekName');
      _isSimulationActive = true;
      _currentSimulationWeek = weekName;

      // Step 1: Generate and save AI picks
      debugPrint('SimulationController: Generating AI picks...');
      final success = await _playerSim.initializeSimulation(weekName);
      if (!success) {
        debugPrint('SimulationController: Failed to initialize AI picks');
        return false;
      }

      // Step 2: Simulate time progression to after games complete
      debugPrint('SimulationController: Simulating time progression...');
      _simulateTimeProgression(weekName);

      // Step 3: Calculate scores using real game results
      debugPrint('SimulationController: Calculating scores...');
      await _calculateSimulationScores(weekName);

      debugPrint('SimulationController: Simulation started successfully');
      return true;
    } catch (e) {
      debugPrint('SimulationController: Error starting simulation: $e');
      _isSimulationActive = false;
      return false;
    }
  }

  /// Simulate time progression to after games complete
  void _simulateTimeProgression(String weekName) {
    switch (weekName) {
      case 'REG1':
        _timeSim.simulateWeek1(); // After Week 1 games completed
        break;
      case 'REG2':
        _timeSim.simulateWeek2(); // After Week 2 games completed
        break;
      default:
        // For other weeks, simulate being after that week
        _timeSim.setSimulatedWeek(weekName);
        _timeSim.setSimulatedDate(DateTime.now().add(Duration(days: 7)));
    }
  }

  /// Calculate scores for all players using real game results
  Future<void> _calculateSimulationScores(String weekName) async {
    try {
      // Get all picks for the week
      final picks = await _getAllPicksForWeek(weekName);
      if (picks.isEmpty) {
        debugPrint('SimulationController: No picks found for scoring');
        return;
      }

      // Get real game results
      final games = await _nflService.getScheduleWithFallback(weekName);
      if (games.isEmpty) {
        debugPrint('SimulationController: No games found for scoring');
        return;
      }

      // Calculate scores for each player
      List<PickModel> scoredPicks = [];
      for (final pick in picks) {
        final scoredPick = await _calculatePlayerScore(pick, games);
        scoredPicks.add(scoredPick);
      }

      // Sort by score (descending) and tiebreaker (ascending)
      scoredPicks.sort((a, b) {
        if (a.score != b.score) {
          return (b.score ?? 0).compareTo(a.score ?? 0);
        }
        return (a.tiebreakerDiff ?? 999).compareTo(b.tiebreakerDiff ?? 999);
      });

      // Assign ranks
      for (int i = 0; i < scoredPicks.length; i++) {
        scoredPicks[i] = scoredPicks[i].copyWith(rank: i + 1);
      }

      _currentWeekPicks = scoredPicks;
      _currentWeekResults = _generateWeekResults(scoredPicks, games);

      debugPrint('SimulationController: Calculated scores for ${scoredPicks.length} players');
    } catch (e) {
      debugPrint('SimulationController: Error calculating scores: $e');
    }
  }

  /// Calculate score for individual player
  Future<PickModel> _calculatePlayerScore(PickModel pick, List<Map<String, dynamic>> games) async {
    int score = 0;
    int? tiebreakerDiff;

    // Calculate actual total score for tiebreaker
    int actualTotal = 0;
    for (final game in games) {
      final homeScore = game['homeScore'] ?? 0;
      final awayScore = game['awayScore'] ?? 0;
      if (homeScore is int && awayScore is int) {
        actualTotal += homeScore + awayScore;
      }
    }

    // Calculate tiebreaker difference
    if (pick.tiebreaker != null) {
      tiebreakerDiff = (pick.tiebreaker! - actualTotal).abs();
    }

    // Score each pick
    for (int i = 0; i < pick.picks.length && i < games.length; i++) {
      final game = games[i];
      final playerPick = pick.picks[i];
      
      final homeTeam = game['homeTeam']?['abbreviation'] ?? '';
      final awayTeam = game['awayTeam']?['abbreviation'] ?? '';
      final homeScore = game['homeScore'];
      final awayScore = game['awayScore'];
      
      // Only score completed games
      if (homeScore != null && awayScore != null && 
          homeScore is int && awayScore is int) {
        
        String winner;
        if (homeScore > awayScore) {
          winner = homeTeam;
        } else if (awayScore > homeScore) {
          winner = awayTeam;
        } else {
          // Tie - both teams "win" for scoring purposes
          winner = playerPick; // Give credit for tie
        }
        
        if (playerPick == winner) {
          score++;
        }
      }
    }

    return pick.copyWith(
      score: score,
      tiebreakerDiff: tiebreakerDiff,
    );
  }

  /// Get all picks for a week
  Future<List<PickModel>> _getAllPicksForWeek(String weekName) async {
    try {
      final query = await FirebaseFirestore.instance
          .collection('pickrecord')
          .where('week', isEqualTo: weekName)
          .where('paymentStatus', isEqualTo: 'verified')
          .get();

      return query.docs.map((doc) => PickModel.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('SimulationController: Error getting picks: $e');
      return [];
    }
  }

  /// Generate week results summary
  Map<String, dynamic> _generateWeekResults(List<PickModel> picks, List<Map<String, dynamic>> games) {
    final completedGames = games.where((game) => 
      game['homeScore'] != null && game['awayScore'] != null).toList();
    
    return {
      'week': _currentSimulationWeek,
      'totalPlayers': picks.length,
      'totalGames': games.length,
      'completedGames': completedGames.length,
      'leaderboard': picks.map((pick) => {
        'rank': pick.rank,
        'displayName': pick.displayName,
        'score': pick.score,
        'tiebreaker': pick.tiebreaker,
        'tiebreakerDiff': pick.tiebreakerDiff,
        'uid': pick.uid,
      }).toList(),
      'gameResults': completedGames.map((game) => {
        'homeTeam': game['homeTeam']?['abbreviation'],
        'awayTeam': game['awayTeam']?['abbreviation'],
        'homeScore': game['homeScore'],
        'awayScore': game['awayScore'],
        'winner': _getGameWinner(game),
      }).toList(),
      'calculatedAt': DateTime.now().toIso8601String(),
    };
  }

  /// Get winner of a game
  String _getGameWinner(Map<String, dynamic> game) {
    final homeScore = game['homeScore'] ?? 0;
    final awayScore = game['awayScore'] ?? 0;
    final homeTeam = game['homeTeam']?['abbreviation'] ?? '';
    final awayTeam = game['awayTeam']?['abbreviation'] ?? '';
    
    if (homeScore > awayScore) return homeTeam;
    if (awayScore > homeScore) return awayTeam;
    return 'TIE';
  }

  /// Get current simulation status
  Map<String, dynamic> getSimulationStatus() {
    return {
      'isActive': _isSimulationActive,
      'currentWeek': _currentSimulationWeek,
      'hasResults': _currentWeekResults != null,
      'playerCount': _currentWeekPicks?.length ?? 0,
      'timeSimulation': _timeSim.getStatus(),
    };
  }

  /// Get current week results
  Map<String, dynamic>? getCurrentWeekResults() {
    return _currentWeekResults;
  }

  /// Get current week picks
  List<PickModel>? getCurrentWeekPicks() {
    return _currentWeekPicks;
  }

  /// Reset simulation
  void resetSimulation() {
    _isSimulationActive = false;
    _currentSimulationWeek = null;
    _currentWeekPicks = null;
    _currentWeekResults = null;
    _timeSim.disableSimulation();
    debugPrint('SimulationController: Simulation reset');
  }

  /// Advance to next week
  Future<bool> advanceToNextWeek() async {
    if (_currentSimulationWeek == null) return false;
    
    try {
      // Extract current week number and increment
      final weekMatch = RegExp(r'(\d+)').firstMatch(_currentSimulationWeek!);
      if (weekMatch == null) return false;
      
      final currentWeekNum = int.parse(weekMatch.group(1)!);
      final nextWeekNum = currentWeekNum + 1;
      final nextWeek = 'REG$nextWeekNum';
      
      debugPrint('SimulationController: Advancing from ${_currentSimulationWeek} to $nextWeek');
      
      // Reset current week data
      _currentWeekPicks = null;
      _currentWeekResults = null;
      _currentSimulationWeek = nextWeek;
      
      // Set time simulation to before next week starts
      switch (nextWeek) {
        case 'REG2':
          _timeSim.simulatePreWeek2();
          break;
        default:
          _timeSim.setSimulatedWeek(nextWeek);
          _timeSim.setSimulatedDate(DateTime.now().add(Duration(days: 7 * nextWeekNum)));
      }
      
      return true;
    } catch (e) {
      debugPrint('SimulationController: Error advancing week: $e');
      return false;
    }
  }

  /// Check if user can submit picks (simulation not started for this week)
  bool canSubmitPicks(String weekName) {
    return !_isSimulationActive || _currentSimulationWeek != weekName;
  }
}
