import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:poolqapp/constants/app_theme.dart';
import 'package:poolqapp/services/auth_service.dart';
import 'package:poolqapp/Provider/AuthProviders.dart';
import 'package:poolqapp/screens/auth/phone_verification_screen.dart';
import 'package:poolqapp/services/phone_verification_service.dart';
import 'package:poolqapp/widgets/auth/auth_button.dart';
import 'package:poolqapp/widgets/auth/auth_input_field.dart';

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
        _errorMessage =
            invitation == null ? 'Invalid or expired invitation code' : null;
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
    if (!_formKey.currentState!.validate()) return;

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
        builder: (_) => PhoneVerificationScreen(
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
    if (!_formKey.currentState!.validate()) return;

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
        phone:
            _phoneController.text.isNotEmpty ? _phoneController.text : '',
        displayName: _displayNameController.text,
        invitationCode: _invitationCodeController.text,
      );

      if (user != null) {
        final authProvider =
            Provider.of<AuthProviders>(context, listen: false);
        await authProvider.getUserInfo();
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
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('Create Account'),
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _BrandHeader(),
                const SizedBox(height: 32),
                AuthInputField(
                  controller: _invitationCodeController,
                  hintText: 'Enter your invite code',
                  labelText: 'Invitation Code',
                  prefixIcon: Icons.confirmation_number_outlined,
                  suffixIcon: IconButton(
                    icon: Icon(
                      Icons.check_circle,
                      color: _isInvitationValid
                          ? AppTheme.success
                          : AppTheme.onSurfaceVariant,
                    ),
                    onPressed: _validateInvitationCode,
                    tooltip: 'Validate code',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an invitation code';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                AuthInputField(
                  controller: _displayNameController,
                  hintText: 'Your name in the pool',
                  labelText: 'Display Name',
                  prefixIcon: Icons.person_outline,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your display name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                AuthInputField(
                  controller: _emailController,
                  hintText: 'you@example.com',
                  labelText: 'Email',
                  prefixIcon: Icons.email_outlined,
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
                const SizedBox(height: 16),
                AuthInputField(
                  controller: _passwordController,
                  hintText: 'Min. 6 characters',
                  labelText: 'Password',
                  prefixIcon: Icons.lock_outline,
                  isPassword: true,
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
                const SizedBox(height: 16),
                AuthInputField(
                  controller: _confirmPasswordController,
                  hintText: 'Re-enter your password',
                  labelText: 'Confirm Password',
                  prefixIcon: Icons.lock_outline,
                  isPassword: true,
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
                const SizedBox(height: 16),
                // Phone is optional — show verify button once user types something
                AuthInputField(
                  controller: _phoneController,
                  hintText: 'Optional',
                  labelText: 'Phone Number',
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  enabled: !_isPhoneVerified,
                  suffixIcon: _phoneController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            _isPhoneVerified
                                ? Icons.check_circle
                                : Icons.phone_forwarded_outlined,
                            color: _isPhoneVerified
                                ? AppTheme.success
                                : AppTheme.onSurfaceVariant,
                          ),
                          onPressed: _verifyPhoneNumber,
                          tooltip: 'Verify phone',
                        )
                      : null,
                  validator: (value) {
                    if (value != null &&
                        value.isNotEmpty &&
                        !_isPhoneVerified) {
                      return 'Please verify your phone number or leave it blank';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppTheme.error.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline,
                            color: AppTheme.error, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: AppTheme.error,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                AuthButton(
                  text: 'Create Account',
                  isLoading: _isLoading,
                  onPressed:
                      _isLoading || !_isInvitationValid ? null : _register,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.onSurfaceVariant,
                          ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Sign In'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.sports_football,
            color: Colors.white,
            size: 36,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Join PoolQ',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppTheme.onSurface,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          'Enter your invitation code to get started',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.onSurfaceVariant,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
