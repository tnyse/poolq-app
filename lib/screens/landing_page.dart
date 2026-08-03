import 'package:flutter/material.dart';
import 'package:poolqapp/screens/auth/login_screen.dart';
import 'package:poolqapp/screens/auth/register_screen.dart';
import 'package:poolqapp/widgets/auth/auth_button.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
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
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    // Start animations
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _slideController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/gb.jpeg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.7),
                Colors.black.withOpacity(0.5),
                Colors.black.withOpacity(0.8),
              ],
            ),
          ),
          child: SafeArea(
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
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Hero(
                            tag: 'poolq_logo',
                            child: Image.asset(
                              'assets/images/poolq12.png',
                              width: 300,
                              height: 180,
                              fit: BoxFit.contain,
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Welcome text
                          Text(
                            'Welcome to PoolQ',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          
                          const SizedBox(height: 8),
                          
                          Text(
                            'Your ultimate NFL pick\'em experience',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: Colors.white70,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          
                          const SizedBox(height: 48),
                          
                          // Action buttons with enhanced styling
                          _buildActionButton(
                            context: context,
                            text: 'Sign In',
                            icon: Icons.login_outlined,
                            type: AuthButtonType.primary,
                            onPressed: () {
                              Navigator.push(
                                context,
                                PageRouteBuilder(
                                  pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
                                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                    return SlideTransition(
                                      position: animation.drive(
                                        Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
                                          .chain(CurveTween(curve: Curves.easeInOut)),
                                      ),
                                      child: child,
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                          
                          const SizedBox(height: 16),
                          
                          _buildActionButton(
                            context: context,
                            text: 'Create Account',
                            icon: Icons.person_add_outlined,
                            type: AuthButtonType.outline,
                            onPressed: () {
                              Navigator.push(
                                context,
                                PageRouteBuilder(
                                  pageBuilder: (context, animation, secondaryAnimation) => RegisterScreen(),
                                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                    return SlideTransition(
                                      position: animation.drive(
                                        Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
                                          .chain(CurveTween(curve: Curves.easeInOut)),
                                      ),
                                      child: child,
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                          
                          const SizedBox(height: 32),
                          
                          // Version info
                          Text(
                            'Version 1.0.0',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white.withOpacity(0.4),
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildActionButton({
    required BuildContext context,
    required String text,
    required IconData icon,
    required AuthButtonType type,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: AuthButton(
        text: text,
        icon: icon,
        type: type,
        onPressed: onPressed,
      ),
    );
  }
} 