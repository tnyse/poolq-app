import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:poolqapp/services/navigation_service.dart';
import 'package:poolqapp/Provider/AuthProviders.dart';
import 'package:poolqapp/Provider/homeProvider.dart';
import 'package:poolqapp/widgets/auth/auth_button.dart';
import 'package:poolqapp/widgets/auth/auth_input_field.dart';
import 'package:poolqapp/screens/auth/register_screen.dart';
import 'package:poolqapp/Module/Screen/Home/HomePage.dart';
import 'package:poolqapp/constants/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final NavigationService _navigationService = NavigationService();
  
  bool _isLoading = false;
  String _errorMessage = '';
  int _retryCount = 0;
  static const int _maxRetries = 3;
  
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    // Start animations
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _slideController.forward();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _initializeGameData() async {
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    try {
      await dataProvider.getWeek();
      if (dataProvider.game == null) {
        throw Exception('Failed to initialize game data');
      }
      await dataProvider.getGame();
    } catch (e) {
      debugPrint('Error initializing game data: $e');
      if (_retryCount < _maxRetries) {
        _retryCount++;
        await Future.delayed(Duration(seconds: 1));
        return _initializeGameData();
      }
      throw Exception('Failed to load game data. Please try again.');
    }
  }

  Future<void> _loginUser() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      // Trim whitespace from inputs
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      
      // Validate email format
      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
        throw Exception('Please enter a valid email address');
      }
      
      // Login user
      final result = await Provider.of<AuthProviders>(context, listen: false)
          .loginUser(email, password);
      
      if (!result) {
        throw Exception('Login failed. Please check your credentials.');
      }

      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logging in...'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      
      // Initialize game data
      await _initializeGameData();
      
      // Navigate to home screen
      if (mounted) {
        _navigationService.navigateAndRemoveUntil(context, HomePage());
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message ?? e.code;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
      
      // Show error in snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage),
            backgroundColor: Colors.red,
          ),
        );
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
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.primaryBlue),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: size.width > 600 ? 400 : double.infinity,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Logo with hero animation
                        Hero(
                          tag: 'poolq_logo',
                          child: Container(
                            width: 120,
                            height: 80,
                            margin: const EdgeInsets.only(bottom: 24),
                            child: Image.asset(
                              'assets/images/poolq12.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        
                        // Welcome text
                        Text(
                          'Welcome Back',
                          style: theme.textTheme.headlineLarge?.copyWith(
                            color: AppTheme.primaryBlue,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        
                        const SizedBox(height: 8),
                        
                        Text(
                          'Sign in to continue your PoolQ experience',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: AppTheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        
                        const SizedBox(height: 48),
                        
                        // Email input with enhanced styling
                        AuthInputField(
                          controller: _emailController,
                          hintText: 'Enter your email',
                          labelText: 'Email Address',
                          prefixIcon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofocus: true,
                          validator: (value) {
                            // TESTING MODE: Relaxed validation
                            return null;
                          },
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Password input with enhanced styling
                        AuthInputField(
                          controller: _passwordController,
                          hintText: 'Enter your password',
                          labelText: 'Password',
                          prefixIcon: Icons.lock_outline,
                          isPassword: true,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _loginUser(),
                          validator: (value) {
                            // TESTING MODE: Relaxed validation
                            return null;
                          },
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Forgot password link
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              // Navigate to forgot password screen
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Forgot password feature coming soon!'),
                                  backgroundColor: AppTheme.info,
                                ),
                              );
                            },
                            child: Text(
                              'Forgot Password?',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppTheme.primaryBlue,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Error message with enhanced styling
                        if (_errorMessage.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(bottom: 24),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.error.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppTheme.error.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: AppTheme.error,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _errorMessage,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: AppTheme.error,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        
                        // Login button with enhanced styling
                        AuthButton(
                          text: 'Sign In',
                          isLoading: _isLoading,
                          onPressed: _loginUser,
                          type: AuthButtonType.primary,
                        ),
                        
                        const SizedBox(height: 24),
                        
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Don\'t have an account?',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppTheme.onSurfaceVariant,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                _navigationService.navigateToReplacement(
                                  context,
                                  RegisterScreen(),
                                );
                              },
                              child: Text(
                                'Sign Up',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.primaryBlue,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
} 