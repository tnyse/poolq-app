import 'package:flutter/material.dart';
import 'package:poolqapp/services/phone_verification_service.dart';

class PhoneVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final Function(String) onVerificationComplete;

  const PhoneVerificationScreen({
    Key? key,
    required this.phoneNumber,
    required this.onVerificationComplete,
  }) : super(key: key);

  @override
  _PhoneVerificationScreenState createState() => _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState extends State<PhoneVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _phoneVerificationService = PhoneVerificationService();
  
  bool _isLoading = false;
  String? _errorMessage;
  bool _codeSent = false;
  int _resendCountdown = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startVerification();
    _startResendCountdown();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _startResendCountdown() {
    Future.delayed(Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          if (_resendCountdown > 0) {
            _resendCountdown--;
            _startResendCountdown();
          } else {
            _canResend = true;
          }
        });
      }
    });
  }

  Future<void> _startVerification() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _phoneVerificationService.verifyPhoneNumber(
        phoneNumber: widget.phoneNumber,
        onCodeSent: (verificationId) {
          setState(() {
            _codeSent = true;
            _isLoading = false;
          });
        },
        onError: (error) {
          setState(() {
            _errorMessage = error;
            _isLoading = false;
          });
        },
        onVerificationCompleted: () {
          // Auto-verification completed (Android only)
          widget.onVerificationComplete(widget.phoneNumber);
        },
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _verifyCode() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userCredential = await _phoneVerificationService.verifyCode(
        _codeController.text,
      );

      if (userCredential != null) {
        widget.onVerificationComplete(widget.phoneNumber);
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _resendCode() async {
    if (!_canResend) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _canResend = false;
      _resendCountdown = 60;
    });

    try {
      await _phoneVerificationService.resendCode(
        phoneNumber: widget.phoneNumber,
        onCodeSent: (verificationId) {
          setState(() {
            _isLoading = false;
          });
          _startResendCountdown();
        },
        onError: (error) {
          setState(() {
            _errorMessage = error;
            _isLoading = false;
            _canResend = true;
          });
        },
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
        _canResend = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Verify Phone Number'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Enter the verification code sent to:',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              SizedBox(height: 8),
              Text(
                widget.phoneNumber,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              SizedBox(height: 24),
              TextFormField(
                controller: _codeController,
                decoration: InputDecoration(
                  labelText: 'Verification Code',
                  hintText: 'Enter 6-digit code',
                ),
                keyboardType: TextInputType.number,
                maxLength: 6,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the verification code';
                  }
                  if (value.length != 6) {
                    return 'Code must be 6 digits';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              if (_errorMessage != null)
                Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ElevatedButton(
                onPressed: _isLoading ? null : _verifyCode,
                child: _isLoading
                    ? CircularProgressIndicator()
                    : Text('Verify Code'),
              ),
              SizedBox(height: 16),
              TextButton(
                onPressed: _canResend ? _resendCode : null,
                child: Text(
                  _canResend
                      ? 'Resend Code'
                      : 'Resend Code in $_resendCountdown seconds',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 