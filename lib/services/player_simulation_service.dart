import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Model/pick_model.dart';
import 'nfl_schedule_service.dart';
import 'time_simulation_service.dart';

/// Service to simulate 4 AI players with realistic picking strategies
class PlayerSimulationService {
  static final PlayerSimulationService _instance = PlayerSimulationService._internal();
  factory PlayerSimulationService() => _instance;
  PlayerSimulationService._internal();

  final NFLScheduleService _nflService = NFLScheduleService();
  final TimeSimulationService _timeSimulation = TimeSimulationService();
  final Random _random = Random();

  // AI Player profiles with different strategies
  final List<Map<String, dynamic>> _aiPlayers = [
    {
      'uid': 'ai_player_1',
      'displayName': 'Sarah "The Analyst" Chen',
      'avatar': 'assets/images/user.png',
      'strategy': 'expert',
      'description': 'Studies team stats and makes calculated picks',
      'favoriteTeams': ['KC', 'BUF', 'SF'], // Tends to pick strong teams
    },
    {
      'uid': 'ai_player_2', 
      'displayName': 'Mike "Underdog" Rodriguez',
      'avatar': 'assets/images/user.png',
      'strategy': 'contrarian',
      'description': 'Loves picking underdogs and upsets',
      'favoriteTeams': ['JAX', 'CAR', 'ARI'], // Picks underdogs
    },
    {
      'uid': 'ai_player_3',
      'displayName': 'Alex "Coin Flip" Johnson',
      'avatar': 'assets/images/user.png', 
      'strategy': 'random',
      'description': 'Makes gut decisions, sometimes brilliant',
      'favoriteTeams': [], // No bias
    },
    {
      'uid': 'ai_player_4',
      'displayName': 'Taylor "Home Field" Davis',
      'avatar': 'assets/images/user.png',
      'strategy': 'home_bias',
      'description': 'Believes home field advantage wins games',
      'favoriteTeams': ['GB', 'SEA', 'NO'], // Teams with strong home fields
    },
  ];

  /// Generate picks for all AI players for a given week
  Future<List<PickModel>> generateAIPicksForWeek(String weekName) async {
    try {
      debugPrint('PlayerSimulation: Generating AI picks for $weekName');
      
      // Get games for the week
      final games = await _nflService.getScheduleWithFallback(weekName);
      if (games.isEmpty) {
        debugPrint('PlayerSimulation: No games found for $weekName');
        return [];
      }

      List<PickModel> aiPicks = [];

      // Generate picks for each AI player
      for (final player in _aiPlayers) {
        final picks = _generatePicksForPlayer(player, games, weekName);
        aiPicks.add(picks);
      }

      debugPrint('PlayerSimulation: Generated ${aiPicks.length} AI player picks');
      return aiPicks;
    } catch (e) {
      debugPrint('PlayerSimulation: Error generating AI picks: $e');
      return [];
    }
  }

  /// Generate picks for a specific AI player based on their strategy
  PickModel _generatePicksForPlayer(
    Map<String, dynamic> player, 
    List<Map<String, dynamic>> games, 
    String weekName
  ) {
    final strategy = player['strategy'] as String;
    final favoriteTeams = List<String>.from(player['favoriteTeams'] ?? []);
    
    List<String> picks = [];
    
    for (final game in games) {
      final homeTeam = game['homeTeam']?['abbreviation'] ?? '';
      final awayTeam = game['awayTeam']?['abbreviation'] ?? '';
      
      String pick;
      
      switch (strategy) {
        case 'expert':
          pick = _expertPick(homeTeam, awayTeam, favoriteTeams);
          break;
        case 'contrarian':
          pick = _contrarianPick(homeTeam, awayTeam, favoriteTeams);
          break;
        case 'random':
          pick = _randomPick(homeTeam, awayTeam);
          break;
        case 'home_bias':
          pick = _homeBiasPick(homeTeam, awayTeam, favoriteTeams);
          break;
        default:
          pick = _randomPick(homeTeam, awayTeam);
      }
      
      picks.add(pick);
    }

    // Generate realistic tiebreaker (total points prediction)
    final tiebreaker = _generateTiebreaker(strategy);

    return PickModel(
      pickId: 'ai_${player['uid']}_${weekName}',
      userId: player['uid'],
      displayName: player['displayName'],
      weekName: weekName,
      picks: picks,
      tiebreaker: tiebreaker,
      submittedAt: DateTime.now(),
      paymentStatus: 'verified', // AI players auto-verified
      entryFee: 10.0,
      isActive: true,
      photoURL: player['avatar'],
      isDemoEntry: true,
    );
  }

  /// Expert strategy: Picks strong teams and favorites
  String _expertPick(String homeTeam, String awayTeam, List<String> favoriteTeams) {
    // Strong teams (based on real NFL strength)
    final strongTeams = ['KC', 'BUF', 'SF', 'PHI', 'DAL', 'BAL', 'CIN', 'LAC'];
    
    // Check if either team is in favorites
    if (favoriteTeams.contains(homeTeam)) return homeTeam;
    if (favoriteTeams.contains(awayTeam)) return awayTeam;
    
    // Pick the stronger team
    if (strongTeams.contains(homeTeam) && !strongTeams.contains(awayTeam)) {
      return homeTeam;
    }
    if (strongTeams.contains(awayTeam) && !strongTeams.contains(homeTeam)) {
      return awayTeam;
    }
    
    // If both or neither are strong, slight home field advantage
    return _random.nextDouble() < 0.6 ? homeTeam : awayTeam;
  }

  /// Contrarian strategy: Picks underdogs and upsets
  String _contrarianPick(String homeTeam, String awayTeam, List<String> favoriteTeams) {
    final strongTeams = ['KC', 'BUF', 'SF', 'PHI', 'DAL', 'BAL', 'CIN', 'LAC'];
    
    // Pick underdog if there's a clear favorite
    if (strongTeams.contains(homeTeam) && !strongTeams.contains(awayTeam)) {
      return _random.nextDouble() < 0.7 ? awayTeam : homeTeam; // 70% chance to pick underdog
    }
    if (strongTeams.contains(awayTeam) && !strongTeams.contains(homeTeam)) {
      return _random.nextDouble() < 0.7 ? homeTeam : awayTeam;
    }
    
    // Random if no clear favorite/underdog
    return _random.nextBool() ? homeTeam : awayTeam;
  }

  /// Random strategy: Pure coin flip
  String _randomPick(String homeTeam, String awayTeam) {
    return _random.nextBool() ? homeTeam : awayTeam;
  }

  /// Home bias strategy: Prefers home teams
  String _homeBiasPick(String homeTeam, String awayTeam, List<String> favoriteTeams) {
    // Strong home field teams get extra bias
    final strongHomeTeams = ['GB', 'SEA', 'NO', 'KC', 'BUF'];
    
    if (strongHomeTeams.contains(homeTeam)) {
      return _random.nextDouble() < 0.8 ? homeTeam : awayTeam; // 80% chance
    }
    
    // General home field advantage
    return _random.nextDouble() < 0.65 ? homeTeam : awayTeam; // 65% chance
  }

  /// Generate realistic tiebreaker based on strategy
  int _generateTiebreaker(String strategy) {
    switch (strategy) {
      case 'expert':
        // Experts tend to predict closer to actual averages (45-50 points)
        return 42 + _random.nextInt(16); // 42-57
      case 'contrarian':
        // Contrarians might go for extreme scores
        return _random.nextBool() 
          ? 35 + _random.nextInt(10)  // Low scoring: 35-44
          : 55 + _random.nextInt(15); // High scoring: 55-69
      case 'random':
        // Random wide range
        return 30 + _random.nextInt(40); // 30-69
      case 'home_bias':
        // Home bias players might expect higher scoring home games
        return 48 + _random.nextInt(20); // 48-67
      default:
        return 45 + _random.nextInt(10); // 45-54
    }
  }

  /// Save AI picks to Firestore (or demo storage)
  Future<void> saveAIPicksToFirestore(List<PickModel> aiPicks) async {
    try {
      debugPrint('PlayerSimulation: Saving ${aiPicks.length} AI picks to Firestore');
      
      for (final pick in aiPicks) {
        await FirebaseFirestore.instance.collection('pickrecord').add({
          'uid': pick.uid,
          'displayName': pick.displayName,
          'photoURL': pick.photoURL,
          'week': pick.week,
          'picks': pick.picks,
          'tiebreaker': pick.tiebreaker,
          'submittedAt': FieldValue.serverTimestamp(),
          'paymentStatus': pick.paymentStatus,
          'entryFee': pick.entryFee,
          'isActive': pick.isActive,
          'score': pick.score,
          'rank': pick.rank,
          'tiebreakerDiff': pick.tiebreakerDiff,
          'isDemoEntry': pick.isDemoEntry,
        });
      }
      
      debugPrint('PlayerSimulation: Successfully saved AI picks');
    } catch (e) {
      debugPrint('PlayerSimulation: Error saving AI picks: $e');
      // In demo mode, we might not have Firestore access
      debugPrint('PlayerSimulation: Continuing in demo mode without Firestore');
    }
  }

  /// Get AI player info
  List<Map<String, dynamic>> getAIPlayers() {
    return List.from(_aiPlayers);
  }

  /// Check if simulation is ready (4 AI + 1 user = 5 total)
  Future<bool> isSimulationReady(String weekName) async {
    try {
      final query = await FirebaseFirestore.instance
          .collection('pickrecord')
          .where('week', isEqualTo: weekName)
          .where('paymentStatus', isEqualTo: 'verified')
          .get();
      
      final totalPlayers = query.docs.length;
      debugPrint('PlayerSimulation: Found $totalPlayers players for $weekName');
      
      return totalPlayers >= 5; // 4 AI + 1 user
    } catch (e) {
      debugPrint('PlayerSimulation: Error checking simulation readiness: $e');
      return false; // Assume ready in demo mode
    }
  }

  /// Generate AI picks and save them (called when user submits picks)
  Future<bool> initializeSimulation(String weekName) async {
    try {
      debugPrint('PlayerSimulation: Initializing simulation for $weekName');
      
      // Generate AI picks
      final aiPicks = await generateAIPicksForWeek(weekName);
      if (aiPicks.isEmpty) {
        debugPrint('PlayerSimulation: Failed to generate AI picks');
        return false;
      }
      
      // Save AI picks
      await saveAIPicksToFirestore(aiPicks);
      
      debugPrint('PlayerSimulation: Simulation initialized successfully');
      return true;
    } catch (e) {
      debugPrint('PlayerSimulation: Error initializing simulation: $e');
      return false;
    }
  }
}
