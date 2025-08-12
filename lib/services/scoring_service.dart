import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../Model/pick_model.dart';
import '../Model/game_result_model.dart';
import '../services/local_schedule_service.dart';

class ScoringService {
  static final ScoringService _instance = ScoringService._internal();
  factory ScoringService() => _instance;
  ScoringService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Calculate score for a single pick entry
  Future<Map<String, dynamic>> calculatePickScore(PickModel pick) async {
    try {
      debugPrint('Calculating score for pick: ${pick.pickId}');
      
      // Get game results for the week
      final gameResults = await _getGameResultsForWeek(pick.weekName);
      if (gameResults.isEmpty) {
        debugPrint('No game results found for week: ${pick.weekName}');
        return {
          'score': 0,
          'correctPicks': 0,
          'totalGames': 0,
          'tiebreakerDiff': null,
          'isComplete': false,
        };
      }

      int correctPicks = 0;
      int totalGames = 0;
      int? tiebreakerDiff;

      // Calculate correct picks
      for (int i = 0; i < pick.picks.length && i < gameResults.length; i++) {
        final gameResult = gameResults[i];
        if (gameResult.isFinal) {
          totalGames++;
          final userPick = pick.picks[i];
          final actualWinner = gameResult.winnerAbbr;
          
          if (userPick == actualWinner) {
            correctPicks++;
          }
        }
      }

      // Calculate tiebreaker difference (closest to actual total score)
      if (gameResults.isNotEmpty) {
        final mondayNightGame = gameResults.last; // Assuming last game is MNF
        if (mondayNightGame.isFinal) {
          final actualTotal = mondayNightGame.totalScore;
          tiebreakerDiff = (pick.tiebreaker - actualTotal).abs();
        }
      }

      final score = correctPicks;
      final isComplete = totalGames == gameResults.length;

      debugPrint('Score calculation complete: $score correct out of $totalGames games');

      return {
        'score': score,
        'correctPicks': correctPicks,
        'totalGames': totalGames,
        'tiebreakerDiff': tiebreakerDiff,
        'isComplete': isComplete,
      };
    } catch (e) {
      debugPrint('Error calculating pick score: $e');
      return {
        'score': 0,
        'correctPicks': 0,
        'totalGames': 0,
        'tiebreakerDiff': null,
        'isComplete': false,
      };
    }
  }

  /// Update scores for all picks in a week
  Future<void> updateWeekScores(String weekName) async {
    try {
      debugPrint('Updating scores for week: $weekName');
      
      // Get all valid picks for the week
      final picksQuery = await _firestore
          .collection('pickrecord')
          .where('week', isEqualTo: weekName)
          .where('paymentStatus', isEqualTo: 'verified')
          .get();

      if (picksQuery.docs.isEmpty) {
        debugPrint('No verified picks found for week: $weekName');
        return;
      }

      List<Map<String, dynamic>> scoredPicks = [];

      // Calculate scores for all picks
      for (var doc in picksQuery.docs) {
        final pick = PickModel.fromFirestore(doc);
        final scoreData = await calculatePickScore(pick);
        
        scoredPicks.add({
          'pickId': pick.pickId,
          'score': scoreData['score'],
          'tiebreakerDiff': scoreData['tiebreakerDiff'],
          'isComplete': scoreData['isComplete'],
        });
      }

      // Sort by score (descending) and tiebreaker (ascending)
      scoredPicks.sort((a, b) {
        if (a['score'] != b['score']) {
          return b['score'].compareTo(a['score']);
        }
        // If scores are equal, sort by tiebreaker difference (closest wins)
        final aTiebreaker = a['tiebreakerDiff'] ?? double.infinity;
        final bTiebreaker = b['tiebreakerDiff'] ?? double.infinity;
        return aTiebreaker.compareTo(bTiebreaker);
      });

      // Update ranks and scores in Firestore
      for (int i = 0; i < scoredPicks.length; i++) {
        final pickData = scoredPicks[i];
        await _firestore
            .collection('pickrecord')
            .doc(pickData['pickId'])
            .update({
          'score': pickData['score'],
          'rank': i + 1,
          'tiebreakerDiff': pickData['tiebreakerDiff'],
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }

      debugPrint('Updated scores for ${scoredPicks.length} picks in week: $weekName');
    } catch (e) {
      debugPrint('Error updating week scores: $e');
    }
  }

  /// Get leaderboard for a specific week
  Future<List<PickModel>> getLeaderboard(String weekName, {int limit = 50}) async {
    try {
      final query = await _firestore
          .collection('pickrecord')
          .where('week', isEqualTo: weekName)
          .where('paymentStatus', isEqualTo: 'verified')
          .orderBy('score', descending: true)
          .orderBy('tiebreakerDiff', descending: false)
          .limit(limit)
          .get();

      return query.docs.map((doc) => PickModel.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error getting leaderboard: $e');
      return [];
    }
  }

  /// Get user's pick for a specific week
  Future<PickModel?> getUserPick(String userId, String weekName) async {
    try {
      final query = await _firestore
          .collection('pickrecord')
          .where('uid', isEqualTo: userId)
          .where('week', isEqualTo: weekName)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return PickModel.fromFirestore(query.docs.first);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user pick: $e');
      return null;
    }
  }

  /// Validate if picks are complete for a week
  Future<bool> validatePicks(List<String> picks, String weekName) async {
    try {
      final gameResults = await _getGameResultsForWeek(weekName);

      // Fallback: if no Firestore results (e.g., demo/web/offline), use local schedule file
      if (gameResults.isEmpty) {
        debugPrint('No Firestore game results for $weekName, falling back to local schedule');
        final local = LocalScheduleService();
        final localGames = await local.getScheduleForWeek(weekName);

        if (localGames.isEmpty) {
          debugPrint('No local games found for $weekName');
          return false;
        }

        // Check count
        if (picks.length != localGames.length) {
          debugPrint('Pick count mismatch (local): ${picks.length} vs ${localGames.length}');
          return false;
        }

        // Validate teams from local schedule
        final validTeams = <String>{};
        for (final g in localGames) {
          final a = (g['abbreviation'] ?? '').toString();
          final b = (g['abbreviation2'] ?? '').toString();
          if (a.isNotEmpty) validTeams.add(a);
          if (b.isNotEmpty) validTeams.add(b);
        }
        for (final pick in picks) {
          if (!validTeams.contains(pick)) {
            debugPrint('Invalid pick (local validation): $pick');
            return false;
          }
        }
        return true;
      }

      // Check if we have exactly one pick per game
      if (picks.length != gameResults.length) {
        debugPrint('Pick count mismatch: ${picks.length} picks for ${gameResults.length} games');
        return false;
      }

      // Check if all picks are valid team abbreviations
      final validTeams = <String>{};
      for (var game in gameResults) {
        validTeams.add(game.homeTeamAbbr);
        validTeams.add(game.awayTeamAbbr);
      }

      for (String pick in picks) {
        if (!validTeams.contains(pick)) {
          debugPrint('Invalid pick: $pick');
          return false;
        }
      }

      return true;
    } catch (e) {
      debugPrint('Error validating picks: $e');
      return false;
    }
  }

  /// Get game results for a specific week
  Future<List<GameResultModel>> _getGameResultsForWeek(String weekName) async {
    try {
      final query = await _firestore
          .collection('game_results')
          .where('weekName', isEqualTo: weekName)
          .orderBy('gameDate', descending: false)
          .get()
          .timeout(const Duration(seconds: 5));

      return query.docs.map((doc) => GameResultModel.fromFirestore(doc)).toList();
    } on TimeoutException {
      debugPrint('Timeout getting game results for $weekName');
      return [];
    } catch (e) {
      debugPrint('Error getting game results: $e');
      return [];
    }
  }

  /// Check if a week is complete (all games finished)
  Future<bool> isWeekComplete(String weekName) async {
    try {
      final gameResults = await _getGameResultsForWeek(weekName);
      if (gameResults.isEmpty) return false;
      
      return gameResults.every((game) => game.isFinal);
    } catch (e) {
      debugPrint('Error checking week completion: $e');
      return false;
    }
  }

  /// Get winners for a specific week
  Future<List<PickModel>> getWeekWinners(String weekName) async {
    try {
      final leaderboard = await getLeaderboard(weekName);
      if (leaderboard.isEmpty) return [];

      final topScore = leaderboard.first.score ?? 0;
      return leaderboard.where((pick) => (pick.score ?? 0) == topScore).toList();
    } catch (e) {
      debugPrint('Error getting week winners: $e');
      return [];
    }
  }
} 