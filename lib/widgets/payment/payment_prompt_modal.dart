import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:poolqapp/constants/app_theme.dart';
import 'package:poolqapp/services/payment_service.dart';

/// Payment prompt modal with methods and deadline information
class PaymentPromptModal extends StatelessWidget {
  final String weekName;
  final DateTime? kickoffTime;
  final VoidCallback onPaymentComplete;
  final VoidCallback onSkipPayment;

  const PaymentPromptModal({
    Key? key,
    required this.weekName,
    this.kickoffTime,
    required this.onPaymentComplete,
    required this.onSkipPayment,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final weekNumber = weekName.replaceAll('REG', '').replaceAll('PRE', '');
    final timeUntilKickoff = _getTimeUntilKickoff();
    final isDeadlineApproaching = _isDeadlineApproaching();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryBlue,
              AppTheme.primaryBlue.withOpacity(0.8),
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Payment icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(
                Icons.payment,
                size: 50,
                color: Colors.white,
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Title
            Text(
              'Payment Required',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Week info
            Text(
              'Week $weekNumber Entry Fee: \$10.00',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white.withOpacity(0.9),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Deadline warning
            if (isDeadlineApproaching) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Payment deadline: $timeUntilKickoff',
                        style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Payment methods
            Text(
              'Choose Payment Method:',
              style: theme.textTheme.titleSmall?.copyWith(
                color: Colors.white.withOpacity(0.9),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Payment buttons
            Column(
              children: [
                _buildPaymentButton(
                  context,
                  'Venmo',
                  Icons.account_balance_wallet,
                  Colors.blue,
                  () => _handlePayment(context, 'Venmo'),
                ),
                const SizedBox(height: 8),
                _buildPaymentButton(
                  context,
                  'Cash App',
                  Icons.attach_money,
                  Colors.green,
                  () => _handlePayment(context, 'Cash App'),
                ),
                const SizedBox(height: 8),
                _buildPaymentButton(
                  context,
                  'PayPal',
                  Icons.payment,
                  Colors.indigo,
                  () => _handlePayment(context, 'PayPal'),
                ),
              ],
            ),
            
            if (kDebugMode) ...[
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onSkipPayment();
                },
                child: Text(
                  'Skip Payment (Debug)',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentButton(
    BuildContext context,
    String method,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 20),
        label: Text(
          'Pay with $method',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  void _handlePayment(BuildContext context, String method) {
    // Show payment instructions
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('$method Payment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Send \$10.00 to:'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getPaymentInfo(method),
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Include "Week ${weekName.replaceAll('REG', '').replaceAll('PRE', '')} Entry" in the memo.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close payment dialog
                Navigator.of(context).pop(); // Close payment prompt
                onPaymentComplete();
              },
              child: Text('Payment Sent'),
            ),
          ],
        );
      },
    );
  }

  String _getPaymentInfo(String method) {
    final methods = PaymentService().getPaymentMethods();
    switch (method) {
      case 'Venmo':
        return methods['venmo']?['identifier'] as String? ??
            PaymentService.VENMO_URL;
      case 'Cash App':
        return methods['cashapp']?['identifier'] as String? ??
            PaymentService.CASHAPP_HANDLE;
      case 'PayPal':
        return methods['paypal']?['identifier'] as String? ??
            PaymentService.PAYPAL_EMAIL;
      case 'Zelle':
        return methods['zelle']?['identifier'] as String? ??
            PaymentService.ZELLE_EMAIL;
      default:
        return 'Contact admin for payment info';
    }
  }

  String _getTimeUntilKickoff() {
    if (kickoffTime == null) return '1 hour before first game';
    
    final now = DateTime.now();
    final deadline = kickoffTime!.subtract(Duration(hours: 1));
    final difference = deadline.difference(now);
    
    if (difference.isNegative) {
      return 'Payment deadline passed';
    } else if (difference.inHours > 24) {
      return '${difference.inDays} days remaining';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours remaining';
    } else {
      return '${difference.inMinutes} minutes remaining';
    }
  }

  bool _isDeadlineApproaching() {
    if (kickoffTime == null) return false;
    
    final now = DateTime.now();
    final deadline = kickoffTime!.subtract(Duration(hours: 1));
    final difference = deadline.difference(now);
    
    // Show warning if less than 24 hours remaining
    return difference.inHours < 24 && !difference.isNegative;
  }
}
