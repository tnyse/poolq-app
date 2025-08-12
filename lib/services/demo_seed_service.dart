import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'local_schedule_service.dart';

class DemoSeedService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<int> seedPicksForEmails({
    required List<String> emails,
    required String weekName, // e.g. PRE1 or REG1
    int baseTiebreaker = 50,
  }) async {
    try {
      final usersSnap = await _firestore
          .collection('users')
          .where('email', whereIn: emails)
          .get();

      if (usersSnap.docs.isEmpty) return 0;

      // Determine number of games from local schedule
      final local = LocalScheduleService();
      final schedule = await local.getScheduleForWeek(weekName);
      final gamesCount = schedule.length;

      int seeded = 0;
      for (int i = 0; i < usersSnap.docs.length; i++) {
        final userDoc = usersSnap.docs[i];
        final email = userDoc['email'] as String? ?? '';
        final uid = userDoc.id;

        // Alternate picks deterministically (home vs away) by user index
        final bool pickHome = i % 2 == 0;
        final List<String> picks = List<String>.generate(gamesCount, (idx) {
          final game = schedule[idx];
          final home = (game['abbreviation'] ?? '').toString();
          final away = (game['abbreviation2'] ?? '').toString();
          return pickHome ? home : away;
        });

        // Upsert: remove prior week entries for user
        final existing = await _firestore
            .collection('pickrecord')
            .where('uid', isEqualTo: uid)
            .where('week', isEqualTo: weekName)
            .get();
        for (final d in existing.docs) {
          await d.reference.delete();
        }

        // Create verified pickrecord
        await _firestore.collection('pickrecord').add({
          'uid': uid,
          'displayName': userDoc['displayName'] ?? email.split('@').first,
          'photoURL': userDoc['avatar'] ?? '',
          'week': weekName,
          'picks': picks,
          'tiebreaker': baseTiebreaker + i,
          'submittedAt': FieldValue.serverTimestamp(),
          'paymentStatus': 'verified',
          'entryFee': 10.0,
          'isActive': true,
          'score': null,
          'rank': null,
          'tiebreakerDiff': null,
        });

        debugPrint('Seeded picks for $email');
        seeded++;
      }
      return seeded;
    } catch (e) {
      debugPrint('DemoSeedService error: $e');
      return 0;
    }
  }
}

