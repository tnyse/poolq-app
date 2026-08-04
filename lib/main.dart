import 'package:rive/rive.dart' hide Image;  // Hide Image class from rive to avoid naming conflict
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get_storage/get_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:poolqapp/providers/app_providers.dart';
import 'package:poolqapp/services/navigation_service.dart';
import 'package:poolqapp/Module/Screen/Home/HomePage.dart';
import 'package:poolqapp/screens/auth/register_screen.dart';
import 'package:poolqapp/Provider/homeProvider.dart';
import 'package:poolqapp/Module/Screen/Admin/AdminLogin.dart';
import 'package:poolqapp/Module/Screen/Admin/AdminDashboard.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:poolqapp/Provider/AuthProviders.dart';
import 'package:poolqapp/firebase_options.dart';
import 'package:poolqapp/screens/auth/login_screen.dart';
import 'screens/admin/admin_players_page.dart';
import 'package:poolqapp/screens/invite_friends_page.dart';
import 'package:poolqapp/constants/app_theme.dart';
import 'package:poolqapp/services/app_config_service.dart';
import 'package:poolqapp/screens/auth/auth_session_gate.dart';
import 'package:poolqapp/widgets/pwa_install_banner.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize all services
  await initializeServices();
  
  // Run app with providers
  runApp(
    AppProviders(
      child: MyApp(),
    ),
  );
}

Future<void> initializeServices() async {
  try {
    // Load environment variables first
    try {
      await dotenv.load(fileName: "assets/.env");
    } catch (e) {
      debugPrint("Warning: Error loading .env file (non-fatal): $e");
    }
    
    // Initialize Firebase with timeout
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ).timeout(Duration(seconds: 5));
    } catch (e) {
      debugPrint('Error initializing Firebase: $e');
      // Continue without Firebase for demo mode
    }

    // Load remote app config (week / preseason free flag)
    try {
      await AppConfigService().load().timeout(Duration(seconds: 3));
    } catch (e) {
      debugPrint('Error loading AppConfigService: $e');
    }
    
    // Initialize GetStorage
    try {
      await GetStorage.init();
    } catch (e) {
      debugPrint('Error initializing GetStorage: $e');
    }

    // Keep Firebase Auth session across browser visits (web IndexedDB / local).
    try {
      if (kIsWeb) {
        await FirebaseAuth.instance
            .setPersistence(Persistence.LOCAL)
            .timeout(const Duration(seconds: 3));
      }
      final authProvider = AuthProviders();
      await authProvider.initializePersistence().timeout(Duration(seconds: 3));
    } catch (e) {
      debugPrint('Error initializing auth persistence: $e');
    }
  } catch (e) {
    debugPrint('Error during service initialization: $e');
    // Continue with app initialization even if some services fail
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProviders()),
        ChangeNotifierProvider(create: (_) => DataProvider()),
      ],
      child: MaterialApp(
        title: 'PoolQ',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        builder: (context, child) {
          return Stack(
            fit: StackFit.expand,
            children: [
              child ?? const SizedBox.shrink(),
              const PwaInstallBanner(),
            ],
          );
        },
        home: const AuthSessionGate(),
        routes: {
          '/home': (context) => const HomePage(initial: 1),
          '/front': (context) => const InviteFriendsPage(),
        '/admin-players': (context) => const AdminPlayersPage(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => RegisterScreen(),
          '/admin': (context) => const AdminLogin(),
          '/admin-dashboard': (context) => const AdminDashboard(),
        },
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final NavigationService _navigationService = NavigationService();
  bool _riveAssetExists = true;
  
  @override
  void initState() {
    super.initState();
    
    // Get data from provider
    try {
      Provider.of<DataProvider>(context, listen: false).getWeek();
    } catch (e) {
      debugPrint("Error getting week data: $e");
    }
    
    // Navigate to first screen after delay
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(Duration(seconds: 3), () async {
        return _navigateToFirstScreen();
      });
    });
  }

  Future<void> _navigateToFirstScreen() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // Navigate to register screen
      Navigator.pushReplacementNamed(context, '/login');
    } else {
      // Navigate to home screen
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Container(
        color: Colors.blue,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.sports_football,
                size: 150,
                color: Colors.white,
              ),
              SizedBox(height: 20),
              Text(
                'PoolQ',
                style: TextStyle(
                  fontSize: 32, 
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 40),
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
