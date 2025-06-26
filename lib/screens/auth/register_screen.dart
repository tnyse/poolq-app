import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:poolqapp/services/auth_service.dart';
import 'package:poolqapp/Provider/AuthProviders.dart';
import 'package:poolqapp/screens/auth/phone_verification_screen.dart';
import 'package:poolqapp/services/phone_verification_service.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _invitationCodeController = TextEditingController();
  
  bool _isLoading = false;
  String? _errorMessage;
  bool _isInvitationValid = false;
  final _phoneVerificationService = PhoneVerificationService();
  bool _isPhoneVerified = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _displayNameController.dispose();
    _invitationCodeController.dispose();
    super.dispose();
  }

  Future<void> _validateInvitationCode() async {
    if (_invitationCodeController.text.isEmpty) {
      setState(() {
        _isInvitationValid = false;
        _errorMessage = 'Please enter an invitation code';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final invitation = await _authService.validateInvitationCode(
        _invitationCodeController.text,
      );

      setState(() {
        _isInvitationValid = invitation != null;
        _errorMessage = invitation == null
            ? 'Invalid or expired invitation code'
            : null;
      });
    } catch (e) {
      setState(() {
        _isInvitationValid = false;
        _errorMessage = 'Error validating invitation code';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _verifyPhoneNumber() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final formattedPhone = _phoneVerificationService.formatPhoneNumber(
      _phoneController.text,
    );

    if (!_phoneVerificationService.isValidPhoneNumber(formattedPhone)) {
      setState(() {
        _errorMessage = 'Please enter a valid phone number';
      });
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PhoneVerificationScreen(
          phoneNumber: formattedPhone,
          onVerificationComplete: (verifiedPhone) {
            setState(() {
              _isPhoneVerified = true;
              _phoneController.text = verifiedPhone;
            });
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_isInvitationValid) {
      setState(() {
        _errorMessage = 'Please enter a valid invitation code';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await _authService.registerWithInvitation(
        email: _emailController.text,
        password: _passwordController.text,
        phone: _phoneController.text.isNotEmpty ? _phoneController.text : '',
        displayName: _displayNameController.text,
        invitationCode: _invitationCodeController.text,
      );

      if (user != null) {
        // Update auth provider
        final authProvider = Provider.of<AuthProviders>(context, listen: false);
        await authProvider.getUserInfo();
        
        // Navigate to home screen
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Register'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _invitationCodeController,
                decoration: InputDecoration(
                  labelText: 'Invitation Code',
                  suffixIcon: IconButton(
                    icon: Icon(Icons.check_circle,
                        color: _isInvitationValid ? Colors.green : Colors.grey),
                    onPressed: _validateInvitationCode,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an invitation code';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(labelText: 'Confirm Password'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your password';
                  }
                  if (value != _passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone Number (optional)',
                  suffixIcon: _phoneController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            _isPhoneVerified ? Icons.check_circle : Icons.phone,
                            color: _isPhoneVerified ? Colors.green : Colors.grey,
                          ),
                          onPressed: _verifyPhoneNumber,
                        )
                      : null,
                ),
                keyboardType: TextInputType.phone,
                enabled: !_isPhoneVerified,
                validator: (value) {
                  // Phone is optional, so only validate if not empty
                  if (value != null && value.isNotEmpty && !_isPhoneVerified) {
                    return 'Please verify your phone number or leave it blank';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _displayNameController,
                decoration: InputDecoration(labelText: 'Display Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your display name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 24),
              if (_errorMessage != null)
                Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ElevatedButton(
                onPressed: _isLoading || !_isInvitationValid ? null : _register,
                child: _isLoading
                    ? CircularProgressIndicator()
                    : Text('Register'),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 