import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:poolqapp/services/auth_service.dart';
import 'package:poolqapp/services/navigation_service.dart';
import 'package:poolqapp/Provider/AuthProviders.dart';
import 'package:poolqapp/Provider/homeProvider.dart';
import 'package:poolqapp/widgets/auth/auth_button.dart';
import 'package:poolqapp/widgets/auth/auth_input_field.dart';
import 'package:poolqapp/screens/auth/register_screen.dart';
import 'package:poolqapp/Module/Screen/Home/HomePage.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  final NavigationService _navigationService = NavigationService();
  
  bool _isLoading = false;
  String _errorMessage = '';
  int _retryCount = 0;
  static const int _maxRetries = 3;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // App logo or title
                const Text(
                  'Welcome Back',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                
                // Email input
                AuthInputField(
                  controller: _emailController,
                  hintText: 'Email',
                  icon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Password input
                AuthInputField(
                  controller: _passwordController,
                  hintText: 'Password',
                  icon: Icons.lock,
                  isPassword: true,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _loginUser(),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                
                // Forgot password link
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      // Navigate to forgot password screen
                    },
                    child: const Text('Forgot Password?'),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Error message
                if (_errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      _errorMessage,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                
                // Login button
                AuthButton(
                  text: 'Login',
                  isLoading: _isLoading,
                  onPressed: _loginUser,
                ),
                const SizedBox(height: 16),
                
                // Sign up link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Don\'t have an account?'),
                    TextButton(
                      onPressed: () {
                        _navigationService.navigateToReplacement(
                          context,
                          RegisterScreen(),
                        );
                      },
                      child: const Text('Sign Up'),
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