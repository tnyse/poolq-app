import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:poolqapp/Module/Screen/Home/HomePage.dart';
import 'package:poolqapp/Provider/homeProvider.dart';
import 'package:poolqapp/screens/landing_page.dart';

/// Restores Firebase session (web: IndexedDB / local persistence) and
/// routes signed-in players straight to home — skip login on return.
class AuthSessionGate extends StatefulWidget {
  const AuthSessionGate({super.key});

  @override
  State<AuthSessionGate> createState() => _AuthSessionGateState();
}

class _AuthSessionGateState extends State<AuthSessionGate> {
  Future<void>? _warmFuture;
  String? _warmedUid;

  Future<void> _warmGameData() async {
    try {
      final dataProvider = Provider.of<DataProvider>(context, listen: false);
      await dataProvider.getWeek();
      if (dataProvider.game != null) {
        await dataProvider.getGame();
      }
    } catch (e) {
      debugPrint('AuthSessionGate: game warm-up failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _SessionSplash();
        }

        final user = snapshot.data;
        if (user != null) {
          if (_warmedUid != user.uid || _warmFuture == null) {
            _warmedUid = user.uid;
            _warmFuture = _warmGameData();
          }
          return FutureBuilder<void>(
            future: _warmFuture,
            builder: (context, warm) {
              if (warm.connectionState != ConnectionState.done) {
                return const _SessionSplash(message: 'Welcome back…');
              }
              return const HomePage(initial: 1);
            },
          );
        }

        _warmFuture = null;
        _warmedUid = null;
        return const LandingPage();
      },
    );
  }
}

class _SessionSplash extends StatelessWidget {
  final String message;
  const _SessionSplash({this.message = 'Loading…'});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF063a73),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/poolq12.png',
              width: 120,
              height: 120,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
