import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class GameEnforcementService {
  static final GameEnforcementService _instance = GameEnforcementService._internal();
  factory GameEnforcementService() => _instance;
  GameEnforcementService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Check and disqualify unpaid entrants for weeks where games have started
  Future<void> enforcePaymentDeadlines() async {
    try {
      print('Starting payment deadline enforcement...');
      
      // Get all pending payment entries
      final pendingEntries = await _firestore
          .collection('pickrecord')
          .where('paymentStatus', isEqualTo: 'pending')
          .get();

      if (pendingEntries.docs.isEmpty) {
        print('No pending payment entries found.');
        return;
      }

      print('Found ${pendingEntries.docs.length} pending payment entries to check.');

      // Group by week to check game start times
      Map<String, List<DocumentSnapshot>> entriesByWeek = {};
      for (var doc in pendingEntries.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final week = data['week'] as String;
        if (!entriesByWeek.containsKey(week)) {
          entriesByWeek[week] = [];
        }
        entriesByWeek[week]!.add(doc);
      }

      // Check each week
      for (String week in entriesByWeek.keys) {
        final hasStarted = await _hasWeekStarted(week);
        if (hasStarted) {
          print('Week $week has started. Disqualifying ${entriesByWeek[week]!.length} unpaid entries.');
          await _disqualifyEntries(entriesByWeek[week]!, week);
        } else {
          print('Week $week has not started yet. Keeping ${entriesByWeek[week]!.length} pending entries.');
        }
      }

      print('Payment deadline enforcement completed.');
    } catch (e) {
      print('Error in payment deadline enforcement: $e');
    }
  }

  /// Check if any game in the given week has started
  Future<bool> _hasWeekStarted(String week) async {
    try {
      // First check local schedule file
      final hasStartedLocally = await _checkLocalSchedule(week);
      if (hasStartedLocally != null) return hasStartedLocally;

      // Fallback to ESPN API
      return await _checkESPNSchedule(week);
    } catch (e) {
      print('Error checking if week $week has started: $e');
      // Default to false to avoid accidentally disqualifying entries
      return false;
    }
  }

  /// Check local schedule file for game start times
  Future<bool?> _checkLocalSchedule(String week) async {
    try {
      // This would need to load the local JSON file
      // For now, return null to indicate we should check ESPN
      return null;
    } catch (e) {
      print('Error checking local schedule: $e');
      return null;
    }
  }

  /// Check ESPN API for game start times
  Future<bool> _checkESPNSchedule(String week) async {
    try {
      // Extract year and week number from week string (e.g., "REG1" -> 2025, week 1)
      final year = DateTime.now().year;
      int weekNumber = int.parse(week.replaceAll(RegExp(r'[^0-9]'), ''));
      String seasonType = week.startsWith('PRE') ? '1' : '2'; // 1 = preseason, 2 = regular season

      final url = 'https://site.api.espn.com/apis/site/v2/sports/football/nfl/scoreboard?'
          'dates=${year}&seasontype=${seasonType}&week=${weekNumber}';

      final response = await http.get(Uri.parse(url)).timeout(Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final events = data['events'] as List?;
        
        if (events != null && events.isNotEmpty) {
          final now = DateTime.now();
          
          for (var event in events) {
            final dateStr = event['date'] as String?;
            if (dateStr != null) {
              final gameDate = DateTime.parse(dateStr);
              if (gameDate.isBefore(now)) {
                print('Found started game in week $week: ${event['name']} at $gameDate');
                return true;
              }
            }
          }
        }
      }

      return false;
    } catch (e) {
      print('Error checking ESPN schedule for week $week: $e');
      return false;
    }
  }

  /// Disqualify entries by moving them to a disqualified collection
  Future<void> _disqualifyEntries(List<DocumentSnapshot> entries, String week) async {
    try {
      final batch = _firestore.batch();
      
      for (var entry in entries) {
        final data = entry.data() as Map<String, dynamic>;
        
        // Add disqualification info
        final disqualifiedData = {
          ...data,
          'disqualifiedAt': FieldValue.serverTimestamp(),
          'disqualificationReason': 'Payment not received before games started',
          'originalPaymentStatus': data['paymentStatus'],
          'paymentStatus': 'disqualified',
        };

        // Move to disqualified collection
        batch.set(
          _firestore.collection('disqualified_entries').doc(entry.id),
          disqualifiedData,
        );

        // Update original document
        batch.update(entry.reference, {
          'paymentStatus': 'disqualified',
          'disqualifiedAt': FieldValue.serverTimestamp(),
          'disqualificationReason': 'Payment not received before games started',
        });

        // Remove from payment tracking
        batch.delete(_firestore.collection('payment_tracking').doc(entry.id));
      }

      await batch.commit();
      print('Successfully disqualified ${entries.length} entries for week $week');

      // Send notifications to affected users
      await _notifyDisqualifiedUsers(entries, week);
    } catch (e) {
      print('Error disqualifying entries: $e');
    }
  }

  /// Send notifications to disqualified users
  Future<void> _notifyDisqualifiedUsers(List<DocumentSnapshot> entries, String week) async {
    try {
      for (var entry in entries) {
        final data = entry.data() as Map<String, dynamic>;
        final uid = data['uid'] as String;
        final displayName = data['displayName'] as String;

        // Create notification document
        await _firestore.collection('user_notifications').add({
          'uid': uid,
          'type': 'disqualification',
          'title': 'Entry Disqualified',
          'message': 'Your picks for week $week were disqualified due to unpaid entry fee. Payment must be completed before games start.',
          'week': week,
          'timestamp': FieldValue.serverTimestamp(),
          'read': false,
        });

        print('Notification sent to user $displayName ($uid) for week $week disqualification');
      }
    } catch (e) {
      print('Error sending disqualification notifications: $e');
    }
  }

  /// Get disqualified entries for admin review
  Future<List<Map<String, dynamic>>> getDisqualifiedEntries({String? week}) async {
    try {
      Query query = _firestore.collection('disqualified_entries');
      
      if (week != null) {
        query = query.where('week', isEqualTo: week);
      }
      
      final snapshot = await query.orderBy('disqualifiedAt', descending: true).get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    } catch (e) {
      print('Error getting disqualified entries: $e');
      return [];
    }
  }

  /// Manual trigger for admin to run enforcement
  Future<void> manualEnforcement() async {
    await enforcePaymentDeadlines();
  }
} 