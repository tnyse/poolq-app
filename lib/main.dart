import 'dart:io';
import 'package:rive/rive.dart' hide Image;  // Hide Image class from rive to avoid naming conflict
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get_storage/get_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:poolqapp/providers/app_providers.dart';
import 'package:poolqapp/services/payment_service.dart';
import 'package:poolqapp/services/navigation_service.dart';
import 'package:poolqapp/Module/Screen/Home/HomePage.dart';
import 'package:poolqapp/screens/auth/register_screen.dart';
import 'package:poolqapp/Provider/homeProvider.dart';
import 'package:poolqapp/Module/Screen/Admin/AdminLogin.dart';
import 'package:poolqapp/Module/Screen/Admin/AdminDashboard.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:poolqapp/Provider/AuthProviders.dart';  // Fixed import path

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: kIsWeb
        ? const FirebaseOptions(
            apiKey: "AIzaSyB_8GwxAp1O-4lW0bLSHHD8ORhrDD2rj2U",
            authDomain: "poolr-b5392.firebaseapp.com",
            projectId: "poolr-b5392",
            storageBucket: "poolr-b5392.appspot.com",
            messagingSenderId: "841410602650",
            appId: "1:841410602650:web:86f41c34cc3356c0602123",
          )
        : null,
  );
  
  // Initialize GetStorage
  await GetStorage.init();

  // Initialize auth persistence
  final authProvider = AuthProviders();
  await authProvider.initializePersistence();

  // Load environment variables
  try {
    await dotenv.load(fileName: "assets/.env");
  } catch (e) {
    debugPrint("Error loading .env file: $e");
    // Continue without .env file
  }
  
  // Initialize Stripe
  try {
    await PaymentService().initializeStripe();
  } catch (e) {
    debugPrint("Error initializing Stripe: $e");
    // Continue without Stripe
  }
  
  // Run app with providers
  runApp(
    AppProviders(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PoolQ',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => SplashScreen(),
        '/home': (context) => HomePage(),
        '/login': (context) => RegisterScreen(),
        '/admin': (context) => AdminLogin(),
        '/admin-dashboard': (context) => AdminDashboard(),
      },
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
              // Image.asset(
              //   'assets/images/logo.png',
              //   width: 150,
              //   height: 150,
              //   errorBuilder: (context, error, stackTrace) {
              //     return Icon(
              //       Icons.sports_football,
              //       size: 150,
              //       color: Colors.white,
              //     );
              //   },
              // ),
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
