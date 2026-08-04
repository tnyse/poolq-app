import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:poolqapp/Widget/reuse.dart';
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

  String get _normalizedInviteCode =>
      _invitationCodeController.text.trim();

  void _showError(String message) {
    if (!mounted) return;
    showErrorToast(context, message);
  }

  Future<bool> _validateInvitationCode({bool showLoading = true}) async {
    final code = _normalizedInviteCode;
    if (code.isEmpty) {
      _showError('Please enter an invitation code');
      setState(() => _isInvitationValid = false);
      return false;
    }

    if (showLoading) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final invitation = await _authService.validateInvitationCode(code);

      setState(() {
        _isInvitationValid = invitation != null;
        if (invitation != null) {
          _invitationCodeController.text = invitation.code;
        }
      });
      if (invitation == null) {
        _showError('Invalid or expired invitation code');
      }
      return invitation != null;
    } catch (e) {
      setState(() => _isInvitationValid = false);
      _showError('Error validating invitation code');
      return false;
    } finally {
      if (showLoading) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _verifyPhoneNumber() async {
    final formattedPhone = _phoneVerificationService.formatPhoneNumber(
      _phoneController.text,
    );

    if (!_phoneVerificationService.isValidPhoneNumber(formattedPhone)) {
      _showError('Please enter a valid phone number');
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
    // Invite code requirement — toast, not inline field error
    if (_normalizedInviteCode.isEmpty) {
      _showError('Invitation code is required');
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final inviteOk = _isInvitationValid
          ? true
          : await _validateInvitationCode(showLoading: false);
      if (!inviteOk) {
        return;
      }

      final user = await _authService.registerWithInvitation(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        phone: _phoneController.text.trim(),
        displayName: _displayNameController.text.trim(),
        invitationCode: _normalizedInviteCode,
      );

      if (user != null && mounted) {
        final authProvider =
            Provider.of<AuthProviders>(context, listen: false);
        await authProvider.getUserInfo();
        Navigator.pushReplacementNamed(context, '/home');
      } else if (mounted) {
        _showError('Account creation failed. Please try again.');
      }
    } catch (e) {
      if (mounted) {
        _showError(e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
                  helperText: 'Use invite code: fitz',
                  prefixIcon: Icons.confirmation_number_outlined,
                  suffixIcon: IconButton(
                    icon: Icon(
                      Icons.check_circle,
                      color: _isInvitationValid
                          ? AppTheme.success
                          : AppTheme.onSurfaceVariant,
                    ),
                    onPressed: () => _validateInvitationCode(),
                    tooltip: 'Validate code',
                  ),
                  onChanged: (_) {
                    if (_isInvitationValid) {
                      setState(() {
                        _isInvitationValid = false;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                AuthInputField(
                  controller: _displayNameController,
                  hintText: 'Your name in the pool',
                  labelText: 'Display Name',
                  prefixIcon: Icons.person_outline,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
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
                    if (value == null || value.trim().isEmpty) {
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
                // Phone is optional for PRE testing — verification is optional too.
                AuthInputField(
                  controller: _phoneController,
                  hintText: 'Optional',
                  labelText: 'Phone Number',
                  helperText: 'Optional — leave blank if you prefer',
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  enabled: !_isPhoneVerified,
                  onChanged: (_) => setState(() {}),
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
                          tooltip: 'Verify phone (optional)',
                        )
                      : null,
                ),
                const SizedBox(height: 24),
                AuthButton(
                  text: 'Create Account',
                  isLoading: _isLoading,
                  onPressed: _isLoading ? null : _register,
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
        Hero(
          tag: 'poolq_logo',
          child: SizedBox(
            width: 120,
            height: 80,
            child: Image.asset(
              'assets/images/poolq12.png',
              fit: BoxFit.contain,
            ),
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
