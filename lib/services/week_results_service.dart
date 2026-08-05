import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:poolqapp/Model/pick_model.dart';
import 'package:poolqapp/constants/season_config.dart';
import 'package:poolqapp/services/payment_service.dart';
import 'package:poolqapp/services/scoring_service.dart';

/// Persists weekly crowning + rolls season stats on [users] documents.
class WeekResultsService {
  static final WeekResultsService _instance = WeekResultsService._internal();
  factory WeekResultsService() => _instance;
  WeekResultsService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ScoringService _scoring = ScoringService();

  static String docId(String weekName, {int? seasonYear}) {
    final year = seasonYear ?? SeasonConfig.currentSeasonYear();
    return '${year}_$weekName';
  }

  /// Score the week, write [week_results], and update player career stats.
  Future<Map<String, dynamic>?> declareWeek(
    String weekName, {
    int? seasonYear,
    double? potAmount,
  }) async {
    try {
      await _scoring.updateWeekScores(weekName);

      final leaderboard = await _scoring.getLeaderboard(weekName, limit: 50);
      if (leaderboard.isEmpty) {
        debugPrint('WeekResultsService: no scored picks for $weekName');
        return null;
      }

      final top3 = leaderboard.take(3).map(_pickToStanding).toList();
      final topScore = leaderboard.first.score ?? 0;
      final winners = leaderboard
          .where((p) => (p.score ?? 0) == topScore && topScore > 0)
          .map(_pickToStanding)
          .toList();

      final gamesPlayed = await _gamesPlayedForWeek(weekName);
      final year = seasonYear ?? SeasonConfig.currentSeasonYear();
      final id = docId(weekName, seasonYear: year);

      final payload = {
        'weekName': weekName,
        'seasonYear': year,
        'status': 'declared',
        'declaredAt': FieldValue.serverTimestamp(),
        'gamesPlayed': gamesPlayed,
        'potAmount': potAmount ??
            (leaderboard.length * PaymentService.ENTRY_FEE),
        'entrantCount': leaderboard.length,
        'top3': top3,
        'winners': winners,
        'payoutStatus': 'pending',
      };

      await _firestore.collection('week_results').doc(id).set(payload);
      invalidateLatestDeclared();

      // Clear previous "reigning" flag, then set winners as current champions.
      await _clearReigningChampions();
      for (final w in winners) {
        final uid = w['uid']?.toString();
        if (uid == null || uid.isEmpty) continue;
        await _firestore.collection('users').doc(uid).set({
          'statistics.isReigningChampion': true,
          'statistics.lastCrownWeek': weekName,
          'statistics.lastCrownSeason': year,
        }, SetOptions(merge: true));
      }

      // Roll season stats for everyone who played this week.
      for (final pick in leaderboard) {
        await _applySeasonStats(
          pick: pick,
          gamesPlayed: gamesPlayed,
          weekName: weekName,
          seasonYear: year,
        );
      }

      debugPrint(
        'WeekResultsService: declared $weekName — '
        '${winners.length} winner(s), top3=${top3.length}',
      );
      return {
        ...payload,
        'declaredAt': DateTime.now().toIso8601String(),
      };
    } catch (e, st) {
      debugPrint('WeekResultsService.declareWeek error: $e\n$st');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getWeekResult(String weekName,
      {int? seasonYear}) async {
    try {
      final id = docId(weekName, seasonYear: seasonYear);
      final snap = await _firestore.collection('week_results').doc(id).get();
      if (!snap.exists) return null;
      final data = snap.data()!;
      data['id'] = snap.id;
      return data;
    } catch (e) {
      debugPrint('WeekResultsService.getWeekResult: $e');
      return null;
    }
  }

  /// Most recent declared week result (for home podium / crowns).
  ///
  /// Shared across callers for the life of a screen session: without the
  /// `status`+`declaredAt` composite index the fallback costs one read per
  /// pool week, and the home podium asks for this twice on every mount.
  Future<Map<String, dynamic>?> getLatestDeclaredResult() {
    return _latestDeclared ??= _fetchLatestDeclaredResult();
  }

  Future<Map<String, dynamic>?>? _latestDeclared;

  /// Drop the memoized podium so a freshly declared week shows immediately.
  void invalidateLatestDeclared() => _latestDeclared = null;

  Future<Map<String, dynamic>?> _fetchLatestDeclaredResult() async {
    try {
      final q = await _firestore
          .collection('week_results')
          .where('status', isEqualTo: 'declared')
          .orderBy('declaredAt', descending: true)
          .limit(1)
          .get();
      if (q.docs.isEmpty) return null;
      final data = q.docs.first.data();
      data['id'] = q.docs.first.id;
      return data;
    } catch (e) {
      // Fallback without composite index: scan recent weeks backward.
      debugPrint('WeekResultsService.getLatestDeclaredResult query: $e');
      final weeks = SeasonConfig.entryWeekSequence.reversed;
      for (final w in weeks) {
        final r = await getWeekResult(w);
        if (r != null) return r;
      }
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getTop3ForWeek(String weekName) async {
    final declared = await getWeekResult(weekName);
    if (declared != null && declared['top3'] is List) {
      return List<Map<String, dynamic>>.from(
        (declared['top3'] as List).map((e) => Map<String, dynamic>.from(e as Map)),
      );
    }
    // Live fallback from pickrecord ranks/scores
    final board = await _scoring.getLeaderboard(weekName, limit: 3);
    return board.map(_pickToStanding).toList();
  }

  Future<Set<String>> getReigningChampionUids() async {
    try {
      final latest = await getLatestDeclaredResult();
      if (latest == null) return {};
      final winners = latest['winners'];
      if (winners is! List) return {};
      return winners
          .map((w) => (w is Map ? w['uid'] : null)?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toSet();
    } catch (e) {
      debugPrint('WeekResultsService.getReigningChampionUids: $e');
      return {};
    }
  }

  Map<String, dynamic> _pickToStanding(PickModel pick) {
    return {
      'uid': pick.userId,
      'displayName': pick.displayName,
      'photoURL': pick.photoURL ?? '',
      'score': pick.score ?? 0,
      'rank': pick.rank ?? 0,
      'tiebreakerDiff': pick.tiebreakerDiff,
    };
  }

  Future<int> _gamesPlayedForWeek(String weekName) async {
    try {
      final complete = await _scoring.isWeekComplete(weekName);
      final results = await _firestore
          .collection('game_results')
          .where('weekName', isEqualTo: weekName)
          .get();
      if (results.docs.isEmpty) return 0;
      if (complete) return results.docs.length;
      return results.docs
          .where((d) => (d.data()['status'] ?? '') == 'final')
          .length;
    } catch (_) {
      return 0;
    }
  }

  Future<void> _clearReigningChampions() async {
    try {
      final q = await _firestore
          .collection('users')
          .where('statistics.isReigningChampion', isEqualTo: true)
          .get();
      for (final doc in q.docs) {
        await doc.reference.set({
          'statistics.isReigningChampion': false,
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('WeekResultsService._clearReigningChampions: $e');
    }
  }

  Future<void> _applySeasonStats({
    required PickModel pick,
    required int gamesPlayed,
    required String weekName,
    required int seasonYear,
  }) async {
    final uid = pick.userId;
    if (uid.isEmpty) return;

    final ref = _firestore.collection('users').doc(uid);
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final stats = Map<String, dynamic>.from(
        (snap.data()?['statistics'] as Map?) ?? {},
      );

      final poolsPlayed = (stats['poolsPlayed'] as num?)?.toInt() ?? 0;
      final crowns = (stats['crowns'] as num?)?.toInt() ?? 0;
      final runnerUps = (stats['runnerUps'] as num?)?.toInt() ?? 0;
      final thirds = (stats['thirds'] as num?)?.toInt() ?? 0;
      final correct = (stats['correctPicks'] as num?)?.toInt() ?? 0;
      final totalPicks = (stats['totalPicks'] as num?)?.toInt() ?? 0;

      final rank = pick.rank ?? 0;
      final score = pick.score ?? 0;
      final played = gamesPlayed > 0 ? gamesPlayed : score;

      final nextPools = poolsPlayed + 1;
      final nextCrowns = crowns + (rank == 1 ? 1 : 0);
      final nextSeconds = runnerUps + (rank == 2 ? 1 : 0);
      final nextThirds = thirds + (rank == 3 ? 1 : 0);
      final nextCorrect = correct + score;
      final nextTotal = totalPicks + played;

      final winRate = nextPools == 0 ? 0.0 : nextCrowns / nextPools;
      final pickPct = nextTotal == 0 ? 0.0 : nextCorrect / nextTotal;
      final podiumRate =
          nextPools == 0 ? 0.0 : (nextCrowns + nextSeconds + nextThirds) / nextPools;

      tx.set(
        ref,
        {
          'statistics': {
            ...stats,
            'poolsPlayed': nextPools,
            'crowns': nextCrowns,
            'runnerUps': nextSeconds,
            'thirds': nextThirds,
            'correctPicks': nextCorrect,
            'totalPicks': nextTotal,
            'winRate': winRate,
            'pickPct': pickPct,
            'podiumRate': podiumRate,
            'totalWinnings': stats['totalWinnings'] ?? 0,
            'lastPlayedWeek': weekName,
            'lastPlayedSeason': seasonYear,
            if (rank == 1) 'lastCrownWeek': weekName,
            if (rank == 1) 'lastCrownSeason': seasonYear,
          },
        },
        SetOptions(merge: true),
      );
    });
  }
}
