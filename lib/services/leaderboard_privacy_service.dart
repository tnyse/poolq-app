import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service for managing leaderboard privacy and visibility controls
class LeaderboardPrivacyService {
  static final LeaderboardPrivacyService _instance = LeaderboardPrivacyService._internal();
  factory LeaderboardPrivacyService() => _instance;
  LeaderboardPrivacyService._internal();

  /// Check if current user has submitted picks for the week
  bool hasCurrentUserSubmittedPicks(List<Map<String, dynamic>> leaderboardData) {
    final user = FirebaseAuth.instance.currentUser;
    final currentUserId = user?.uid ?? 'demo_user';
    
    try {
      final currentUserEntry = leaderboardData.firstWhere(
        (entry) => entry['uid'] == currentUserId,
        orElse: () => {},
      );
      
      return currentUserEntry['hasSubmittedPicks'] == true;
    } catch (e) {
      return false;
    }
  }

  /// Sanitize leaderboard data based on privacy rules
  List<Map<String, dynamic>> sanitizeLeaderboardData(
    List<Map<String, dynamic>> originalData,
    bool currentUserHasSubmitted,
  ) {
    return originalData.map((entry) {
      final sanitizedEntry = Map<String, dynamic>.from(entry);
      
      // If current user hasn't submitted, hide other players' scores and picks
      if (!currentUserHasSubmitted) {
        final user = FirebaseAuth.instance.currentUser;
        final currentUserId = user?.uid ?? 'demo_user';
        final isCurrentUser = entry['uid'] == currentUserId;
        
        if (!isCurrentUser) {
          sanitizedEntry['score'] = null; // Hide score
          sanitizedEntry['picks'] = []; // Hide picks
          sanitizedEntry['tiebreaker'] = null; // Hide tiebreaker
        }
      }
      
      return sanitizedEntry;
    }).toList();
  }

  /// Get display text for score based on privacy rules
  String getScoreDisplayText(
    Map<String, dynamic> playerData,
    bool currentUserHasSubmitted,
    bool isCurrentUser,
  ) {
    // Always show current user's score
    if (isCurrentUser) {
      return 'Score ${playerData['score'] ?? 0}';
    }
    
    // If current user hasn't submitted, hide other players' scores
    if (!currentUserHasSubmitted) {
      return 'Score Hidden';
    }
    
    // Show score if current user has submitted
    return 'Score ${playerData['score'] ?? 0}';
  }

  /// Check if picks should be visible for a player
  bool shouldShowPicks(
    Map<String, dynamic> playerData,
    bool currentUserHasSubmitted,
    bool isCurrentUser,
  ) {
    // Always show current user's picks
    if (isCurrentUser) {
      return true;
    }
    
    // Hide other players' picks if current user hasn't submitted
    return currentUserHasSubmitted;
  }

  /// Get privacy status message for leaderboard
  String getPrivacyStatusMessage(bool currentUserHasSubmitted) {
    if (currentUserHasSubmitted) {
      return 'All scores and picks are visible';
    } else {
      return 'Submit your picks to see other players\' scores';
    }
  }

  /// Check if user can view another player's picks
  bool canViewPlayerPicks(
    String targetPlayerId,
    bool currentUserHasSubmitted,
  ) {
    final user = FirebaseAuth.instance.currentUser;
    final currentUserId = user?.uid ?? 'demo_user';
    
    // Always allow viewing own picks
    if (targetPlayerId == currentUserId) {
      return true;
    }
    
    // Only allow viewing other players' picks if current user has submitted
    return currentUserHasSubmitted;
  }

  /// Show restricted access dialog
  void showRestrictedAccessDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.lock_outline, color: Colors.orange, size: 24),
              const SizedBox(width: 8),
              Text('Access Restricted'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Picks must be submitted before you can view other players picks',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 12),
              Text(
                'This ensures fair play for everyone! 🏈',
                style: TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Got it'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Navigate to picks page
                Navigator.pushNamed(context, '/play');
              },
              child: Text('Make Picks'),
            ),
          ],
        );
      },
    );
  }
}
