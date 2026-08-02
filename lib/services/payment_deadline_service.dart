import 'dart:async';
import 'package:flutter/material.dart';

/// Service for managing payment deadlines and automatic status updates
class PaymentDeadlineService {
  static final PaymentDeadlineService _instance = PaymentDeadlineService._internal();
  factory PaymentDeadlineService() => _instance;
  PaymentDeadlineService._internal();

  Timer? _deadlineTimer;
  final List<Function(String weekName)> _deadlineCallbacks = [];

  /// Start monitoring payment deadline for a week
  void startDeadlineMonitoring(String weekName, DateTime kickoffTime) {
    // Cancel existing timer
    _deadlineTimer?.cancel();
    
    final deadlineTime = kickoffTime.subtract(const Duration(hours: 1));
    final now = DateTime.now();
    
    if (now.isAfter(deadlineTime)) {
      // Deadline already passed, trigger immediately
      _triggerDeadlineActions(weekName);
      return;
    }
    
    final timeUntilDeadline = deadlineTime.difference(now);
    
    print('PaymentDeadlineService: Starting deadline monitoring for $weekName');
    print('PaymentDeadlineService: Deadline in ${timeUntilDeadline.inMinutes} minutes');
    
    _deadlineTimer = Timer(timeUntilDeadline, () {
      _triggerDeadlineActions(weekName);
    });
  }

  /// Add callback to be executed when deadline is reached
  void addDeadlineCallback(Function(String weekName) callback) {
    _deadlineCallbacks.add(callback);
  }

  /// Remove callback
  void removeDeadlineCallback(Function(String weekName) callback) {
    _deadlineCallbacks.remove(callback);
  }

  /// Trigger all deadline actions
  void _triggerDeadlineActions(String weekName) {
    print('PaymentDeadlineService: Payment deadline reached for $weekName');
    
    for (final callback in _deadlineCallbacks) {
      try {
        callback(weekName);
      } catch (e) {
        print('PaymentDeadlineService: Error in deadline callback: $e');
      }
    }
  }

  /// Check if deadline has passed for a week
  bool hasDeadlinePassed(DateTime kickoffTime) {
    final deadlineTime = kickoffTime.subtract(const Duration(hours: 1));
    return DateTime.now().isAfter(deadlineTime);
  }

  /// Get time remaining until deadline
  Duration getTimeUntilDeadline(DateTime kickoffTime) {
    final deadlineTime = kickoffTime.subtract(const Duration(hours: 1));
    final now = DateTime.now();
    
    if (now.isAfter(deadlineTime)) {
      return Duration.zero;
    }
    
    return deadlineTime.difference(now);
  }

  /// Format time remaining as human readable string
  String formatTimeRemaining(Duration timeRemaining) {
    if (timeRemaining.isNegative || timeRemaining == Duration.zero) {
      return 'Deadline passed';
    }
    
    if (timeRemaining.inDays > 0) {
      return '${timeRemaining.inDays}d ${timeRemaining.inHours % 24}h remaining';
    } else if (timeRemaining.inHours > 0) {
      return '${timeRemaining.inHours}h ${timeRemaining.inMinutes % 60}m remaining';
    } else {
      return '${timeRemaining.inMinutes}m remaining';
    }
  }

  /// Default unpaid players to ineligible after deadline
  Map<String, dynamic> applyDeadlineDefaults(
    List<Map<String, dynamic>> players,
    bool deadlinePassed,
  ) {
    if (!deadlinePassed) {
      return {
        'players': players,
        'changedCount': 0,
        'message': 'Deadline not yet reached',
      };
    }

    int changedCount = 0;
    final updatedPlayers = players.map((player) {
      final currentStatus = player['paymentStatus'] ?? 'unpaid';
      
      // Only change unpaid players to ineligible
      if (currentStatus == 'unpaid') {
        changedCount++;
        return {
          ...player,
          'paymentStatus': 'ineligible',
          'statusChangedAt': DateTime.now().toIso8601String(),
          'statusChangedReason': 'Payment deadline passed - defaulted to ineligible',
        };
      }
      
      return player;
    }).toList();

    return {
      'players': updatedPlayers,
      'changedCount': changedCount,
      'message': changedCount > 0 
          ? 'Defaulted $changedCount unpaid players to ineligible'
          : 'No unpaid players to update',
    };
  }

  /// Show deadline notification to admin
  void showDeadlineNotification(BuildContext context, String weekName, int unpaidCount) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.schedule, color: Colors.orange, size: 24),
              const SizedBox(width: 8),
              Text('Payment Deadline Reached'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'The payment deadline for $weekName has been reached.',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              if (unpaidCount > 0) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber, color: Colors.orange, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '$unpaidCount players have unpaid status and will be defaulted to ineligible.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Text(
                'What would you like to do?',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Keep current status - no changes
              },
              child: Text('Keep Current Status'),
            ),
            if (unpaidCount > 0)
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Trigger default to ineligible
                  _applyDeadlineDefaults(context, weekName);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                child: Text('Default to Ineligible'),
              ),
          ],
        );
      },
    );
  }

  /// Apply deadline defaults with confirmation
  void _applyDeadlineDefaults(BuildContext context, String weekName) {
    // In a real app, this would update Firestore
    // For now, just show confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Unpaid players for $weekName defaulted to ineligible'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 3),
      ),
    );
  }

  /// Get deadline status for display
  DeadlineStatus getDeadlineStatus(DateTime kickoffTime) {
    final deadlineTime = kickoffTime.subtract(const Duration(hours: 1));
    final now = DateTime.now();
    final timeRemaining = deadlineTime.difference(now);
    
    if (timeRemaining.isNegative) {
      return DeadlineStatus(
        hasPasssed: true,
        timeRemaining: Duration.zero,
        displayText: 'Deadline Passed',
        statusColor: Colors.red,
        icon: Icons.schedule_outlined,
      );
    } else if (timeRemaining.inHours < 2) {
      return DeadlineStatus(
        hasPasssed: false,
        timeRemaining: timeRemaining,
        displayText: formatTimeRemaining(timeRemaining),
        statusColor: Colors.orange,
        icon: Icons.schedule,
      );
    } else {
      return DeadlineStatus(
        hasPasssed: false,
        timeRemaining: timeRemaining,
        displayText: formatTimeRemaining(timeRemaining),
        statusColor: Colors.green,
        icon: Icons.schedule,
      );
    }
  }

  /// Stop deadline monitoring
  void stopDeadlineMonitoring() {
    _deadlineTimer?.cancel();
    _deadlineTimer = null;
  }

  /// Dispose resources
  void dispose() {
    stopDeadlineMonitoring();
    _deadlineCallbacks.clear();
  }
}

/// Data class for deadline status
class DeadlineStatus {
  final bool hasPasssed;
  final Duration timeRemaining;
  final String displayText;
  final Color statusColor;
  final IconData icon;

  DeadlineStatus({
    required this.hasPasssed,
    required this.timeRemaining,
    required this.displayText,
    required this.statusColor,
    required this.icon,
  });
}
