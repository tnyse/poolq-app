import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:poolqapp/services/game_enforcement_service.dart';

/// Leaderboard privacy: own picks always visible; other players' picks
/// only after the week's first kickoff (entries locked).
class LeaderboardPrivacyService {
  static final LeaderboardPrivacyService _instance =
      LeaderboardPrivacyService._internal();
  factory LeaderboardPrivacyService() => _instance;
  LeaderboardPrivacyService._internal();

  final GameEnforcementService _enforcement = GameEnforcementService();

  /// True once the first game of [weekName] has started.
  Future<bool> areEntriesLocked(String weekName) =>
      _enforcement.areEntriesLocked(weekName);

  bool isCurrentUser(Map<String, dynamic> entry) {
    final user = FirebaseAuth.instance.currentUser;
    final currentUserId = user?.uid ?? 'demo_user';
    return entry['uid'] == currentUserId;
  }

  bool hasCurrentUserSubmittedPicks(List<Map<String, dynamic>> leaderboardData) {
    final user = FirebaseAuth.instance.currentUser;
    final currentUserId = user?.uid ?? 'demo_user';
    return leaderboardData.any((entry) => entry['uid'] == currentUserId);
  }

  /// Hide other players' picks/scores until entries are locked.
  List<Map<String, dynamic>> sanitizeLeaderboardData(
    List<Map<String, dynamic>> originalData, {
    required bool entriesLocked,
  }) {
    return originalData.map((entry) {
      final sanitized = Map<String, dynamic>.from(entry);
      final mine = isCurrentUser(entry);

      if (!entriesLocked && !mine) {
        sanitized['picks'] = <String>[];
        sanitized['tiebreaker'] = null;
        // Keep score null/hidden until lock; rank/name stay visible.
        sanitized['score'] = null;
        sanitized['picksHidden'] = true;
      } else {
        sanitized['picksHidden'] = false;
      }

      sanitized['hasSubmittedPicks'] = true;
      return sanitized;
    }).toList();
  }

  String getScoreDisplayText(
    Map<String, dynamic> playerData, {
    required bool entriesLocked,
    required bool isCurrentUser,
  }) {
    if (isCurrentUser) {
      final score = playerData['score'];
      return score == null ? 'Entered' : 'Score $score';
    }
    if (!entriesLocked) {
      return 'Locked';
    }
    final score = playerData['score'];
    return score == null ? '—' : 'Score $score';
  }

  bool shouldShowPicks({
    required bool entriesLocked,
    required bool isCurrentUser,
  }) {
    if (isCurrentUser) return true;
    return entriesLocked;
  }

  bool canViewPlayerPicks({
    required String targetPlayerId,
    required bool entriesLocked,
  }) {
    final user = FirebaseAuth.instance.currentUser;
    final currentUserId = user?.uid ?? 'demo_user';
    if (targetPlayerId == currentUserId) return true;
    return entriesLocked;
  }

  String getPrivacyStatusMessage({required bool entriesLocked}) {
    if (entriesLocked) {
      return 'Week locked — all entrants\' picks are visible';
    }
    return 'Picks stay private until the first game starts';
  }

  void showRestrictedAccessDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.lock_outline, color: Colors.orange, size: 24),
              SizedBox(width: 8),
              Text('Picks Locked'),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Other players\' picks are hidden until the first game of the week kicks off and entries are locked.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 12),
              Text(
                'You can always tap your own name to review your picks.',
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Got it'),
            ),
          ],
        );
      },
    );
  }
}
