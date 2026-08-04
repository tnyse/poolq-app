import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:poolqapp/services/payment_service.dart';
import 'package:poolqapp/constants.dart';
import 'package:poolqapp/constants/app_theme.dart';
import 'package:poolqapp/constants/payment_bundles.dart';
import 'package:google_fonts/google_fonts.dart';
import 'HomePage.dart';

class ManualPaymentScreen extends StatefulWidget {
  final String pickRecordId;
  final String weekName;
  final double entryFee;

  const ManualPaymentScreen({
    Key? key,
    required this.pickRecordId,
    required this.weekName,
    required this.entryFee,
  }) : super(key: key);

  @override
  _ManualPaymentScreenState createState() => _ManualPaymentScreenState();
}

class _ManualPaymentScreenState extends State<ManualPaymentScreen> {
  final PaymentService _paymentService = PaymentService();
  bool _isLoading = false;
  PaymentBundle _selectedBundle = PaymentBundle.single;

  @override
  Widget build(BuildContext context) {
    final paymentMethods = _paymentService.getPaymentMethods();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Pay later',
          onPressed: () => _showSkipPaymentDialog(context),
        ),
        title: Text(
          'Complete Payment',
          style: GoogleFonts.lexendDeca(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: primary.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      color: primary,
                      size: 48,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Picks Saved Successfully!',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: primary,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Week ${widget.weekName}',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24),

              Text(
                'Choose a plan',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Pay for multiple weeks upfront, or just this week.',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 12),
              ...PaymentBundle.all.map((bundle) {
                final selected = _selectedBundle.id == bundle.id;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    onTap: () => setState(() => _selectedBundle = bundle),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: selected
                            ? primary.withOpacity(0.08)
                            : Colors.grey[50],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selected ? primary : Colors.grey[300]!,
                          width: selected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            selected
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
                            color: selected ? primary : Colors.grey,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  bundle.label,
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  bundle.description,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '\$${bundle.price.toStringAsFixed(0)}',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),

              SizedBox(height: 8),

              // Payment Amount
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Amount due:',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '\$${_selectedBundle.price.toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: primary,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24),

              Text(
                'Choose Payment Method',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),

              SizedBox(height: 16),

              // Payment Methods
              ...paymentMethods.entries.map((entry) {
                final method = entry.key;
                final data = entry.value as Map<String, dynamic>;
                
                return Container(
                  margin: EdgeInsets.only(bottom: 16),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _getPaymentIcon(method),
                          SizedBox(width: 12),
                          Text(
                            data['name'],
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Spacer(),
                          TextButton.icon(
                            onPressed: () => _copyToClipboard(data['identifier']),
                            icon: Icon(Icons.copy, size: 16),
                            label: Text('Copy'),
                            style: TextButton.styleFrom(
                              foregroundColor: primary,
                              textStyle: GoogleFonts.poppins(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Send to: ${data['identifier']}',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: primary,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              data['instructions'],
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _launchPaymentApp(method),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Open ${data['name']}',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),

              SizedBox(height: 24),

              // Important Notice
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.orange[700]),
                        SizedBox(width: 8),
                        Text(
                          'Important',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange[700],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• Your picks are saved but not active until payment is verified\n'
                      '• An admin will verify your payment within 24 hours\n'
                      '• You\'ll receive confirmation once payment is verified\n'
                      '• Include your name in the payment note for faster processing',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[700],
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24),

              // Continue Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'I\'ve Sent the Payment',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),

              SizedBox(height: 12),

              // Pay later — picks stay saved until deadline
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _showSkipPaymentDialog(context),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: Colors.orange),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Pay Later',
                    style: GoogleFonts.poppins(
                      color: Colors.orange,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getPaymentIcon(String method) {
    switch (method) {
      case 'paypal':
        return Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.account_balance_wallet, color: Colors.blue[700]),
        );
      case 'zelle':
        return Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.purple[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.mobile_friendly, color: Colors.purple[700]),
        );
      case 'cashapp':
        return Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.money, color: Colors.green[700]),
        );
      default:
        return Icon(Icons.payment);
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied to clipboard: $text'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _launchPaymentApp(String method) async {
    try {
      await _paymentService.launchPaymentApp(method);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open ${method}. Please pay manually.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _handleContinue() async {
    setState(() => _isLoading = true);
    try {
      await _paymentService.reportPaymentSent(
        widget.pickRecordId,
        bundleId: _selectedBundle.id,
        amount: _selectedBundle.price,
        weeksCovered: _selectedBundle.weekCount,
      );
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => HomePage(initial: 1),
        ),
        (route) => false,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _selectedBundle.id == PaymentBundle.single.id
                ? 'Payment reported — we\'ll verify within 24 hours.'
                : 'Payment reported for ${_selectedBundle.label} '
                    '(\$${_selectedBundle.price.toStringAsFixed(0)}). '
                    'We\'ll verify within 24 hours.',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not report payment. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSkipPaymentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.orange),
              SizedBox(width: 8),
              Text(
                'Important Warning',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your picks are saved but NOT officially entered until payment is verified.',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.red[700],
                ),
              ),
              SizedBox(height: 12),
              Text(
                '⚠️ CRITICAL: Once NFL games begin for this week, all unpaid entries will be DISQUALIFIED and removed from the competition.',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.red[800],
                ),
              ),
              SizedBox(height: 12),
              Text(
                'To ensure your entry is valid:',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '• Pay before the first game starts\n'
                '• Admin verification takes up to 24 hours\n'
                '• No refunds for late payments',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Go Back & Pay',
                style: GoogleFonts.poppins(
                  color: primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                _handleSkipForNow();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
              ),
              child: Text(
                'Pay Later',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _handleSkipForNow() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => HomePage(initial: 0), // Go to home tab
      ),
      (route) => false,
    );
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('⚠️ Reminder: Complete payment BEFORE games start to activate your picks!'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 5),
        action: SnackBarAction(
          label: 'PAY NOW',
          textColor: Colors.white,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ManualPaymentScreen(
                  pickRecordId: widget.pickRecordId,
                  weekName: widget.weekName,
                  entryFee: widget.entryFee,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
} 