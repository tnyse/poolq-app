import 'package:flutter/material.dart';

/// Service for managing player eligibility based on payment status
class PlayerEligibilityService {
  static final PlayerEligibilityService _instance = PlayerEligibilityService._internal();
  factory PlayerEligibilityService() => _instance;
  PlayerEligibilityService._internal();

  /// Check if a player is eligible based on payment status
  bool isPlayerEligible(Map<String, dynamic> playerData) {
    final paymentStatus = playerData['paymentStatus'] ?? 'unpaid';
    
    // Only verified payments are eligible
    return paymentStatus == 'verified';
  }

  /// Get eligibility status with reason
  EligibilityStatus getEligibilityStatus(Map<String, dynamic> playerData) {
    final paymentStatus = playerData['paymentStatus'] ?? 'unpaid';
    
    switch (paymentStatus) {
      case 'verified':
        return EligibilityStatus(
          isEligible: true,
          reason: 'Payment verified',
          statusColor: Colors.green,
          icon: Icons.check_circle,
        );
      case 'pending':
        return EligibilityStatus(
          isEligible: false,
          reason: 'Payment pending verification',
          statusColor: Colors.orange,
          icon: Icons.schedule,
        );
      case 'unpaid':
        return EligibilityStatus(
          isEligible: false,
          reason: 'Payment required',
          statusColor: Colors.red,
          icon: Icons.payment,
        );
      default:
        return EligibilityStatus(
          isEligible: false,
          reason: 'Unknown payment status',
          statusColor: Colors.grey,
          icon: Icons.help_outline,
        );
    }
  }

  /// Apply visual styling for ineligible players
  Widget applyEligibilityStyle({
    required Widget child,
    required bool isEligible,
    double opacity = 0.5,
  }) {
    if (isEligible) {
      return child;
    }
    
    return Opacity(
      opacity: opacity,
      child: ColorFiltered(
        colorFilter: ColorFilter.mode(
          Colors.grey,
          BlendMode.saturation,
        ),
        child: child,
      ),
    );
  }

  /// Get eligibility indicator widget
  Widget buildEligibilityIndicator(EligibilityStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: status.statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: status.statusColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            status.icon,
            size: 16,
            color: status.statusColor,
          ),
          const SizedBox(width: 4),
          Text(
            status.isEligible ? 'ELIGIBLE' : 'INELIGIBLE',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: status.statusColor,
            ),
          ),
        ],
      ),
    );
  }

  /// Show eligibility explanation dialog
  void showEligibilityDialog(BuildContext context, EligibilityStatus status, String playerName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(status.icon, color: status.statusColor, size: 24),
              const SizedBox(width: 8),
              Text('Player Eligibility'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                playerName,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Status: ${status.isEligible ? 'Eligible' : 'Ineligible'}',
                style: TextStyle(
                  fontSize: 16,
                  color: status.statusColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Reason: ${status.reason}',
                style: TextStyle(fontSize: 14),
              ),
              if (!status.isEligible) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Ineligible players cannot win prizes even if they have high scores.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Got it'),
            ),
            if (!status.isEligible)
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Navigate to payment or contact admin
                  _showPaymentOptions(context);
                },
                child: Text('Resolve Payment'),
              ),
          ],
        );
      },
    );
  }

  void _showPaymentOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Resolve Payment'),
          content: Text(
            'To become eligible for prizes, please:\n\n'
            '1. Complete your payment via the specified method\n'
            '2. Contact the admin to verify your payment\n'
            '3. Wait for payment verification\n\n'
            'Once verified, you\'ll be eligible for prizes.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // In real app, this would navigate to payment page or contact admin
              },
              child: Text('Contact Admin'),
            ),
          ],
        );
      },
    );
  }

  /// Filter eligible players from a list
  List<Map<String, dynamic>> filterEligiblePlayers(List<Map<String, dynamic>> players) {
    return players.where((player) => isPlayerEligible(player)).toList();
  }

  /// Sort players with eligible players first
  List<Map<String, dynamic>> sortByEligibility(List<Map<String, dynamic>> players) {
    final eligible = <Map<String, dynamic>>[];
    final ineligible = <Map<String, dynamic>>[];
    
    for (final player in players) {
      if (isPlayerEligible(player)) {
        eligible.add(player);
      } else {
        ineligible.add(player);
      }
    }
    
    // Return eligible players first, then ineligible
    return [...eligible, ...ineligible];
  }

  /// Get eligibility summary for a list of players
  EligibilitySummary getEligibilitySummary(List<Map<String, dynamic>> players) {
    int eligible = 0;
    int pending = 0;
    int unpaid = 0;
    
    for (final player in players) {
      final status = player['paymentStatus'] ?? 'unpaid';
      switch (status) {
        case 'verified':
          eligible++;
          break;
        case 'pending':
          pending++;
          break;
        case 'unpaid':
          unpaid++;
          break;
      }
    }
    
    return EligibilitySummary(
      totalPlayers: players.length,
      eligiblePlayers: eligible,
      pendingPlayers: pending,
      unpaidPlayers: unpaid,
    );
  }
}

/// Data class for eligibility status
class EligibilityStatus {
  final bool isEligible;
  final String reason;
  final Color statusColor;
  final IconData icon;

  EligibilityStatus({
    required this.isEligible,
    required this.reason,
    required this.statusColor,
    required this.icon,
  });
}

/// Data class for eligibility summary
class EligibilitySummary {
  final int totalPlayers;
  final int eligiblePlayers;
  final int pendingPlayers;
  final int unpaidPlayers;

  EligibilitySummary({
    required this.totalPlayers,
    required this.eligiblePlayers,
    required this.pendingPlayers,
    required this.unpaidPlayers,
  });

  double get eligibilityRate => totalPlayers > 0 ? eligiblePlayers / totalPlayers : 0.0;
}
