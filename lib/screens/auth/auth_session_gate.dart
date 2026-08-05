import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:poolqapp/Module/Screen/Home/HomePage.dart';
import 'package:poolqapp/Provider/homeProvider.dart';
import 'package:poolqapp/screens/landing_page.dart';
import 'package:poolqapp/services/payment_service.dart';

/// Restores Firebase session (web: IndexedDB / local persistence) and
/// routes signed-in players straight to home — skip login on return.
class AuthSessionGate extends StatefulWidget {
  const AuthSessionGate({super.key});

  @override
  State<AuthSessionGate> createState() => _AuthSessionGateState();
}

class _AuthSessionGateState extends State<AuthSessionGate> {
  Future<int>? _entryFuture;
  String? _warmedUid;
  late final Stream<User?> _authStream;
  bool _authTimedOut = false;
  Timer? _authWaitTimer;

  @override
  void initState() {
    super.initState();
    _authStream = FirebaseAuth.instance.authStateChanges();
    // If authStateChanges never emits (IndexedDB hang), fall back after 6s.
    _authWaitTimer = Timer(const Duration(seconds: 6), () {
      if (!mounted || _authTimedOut) return;
      setState(() => _authTimedOut = true);
    });
  }

  @override
  void dispose() {
    _authWaitTimer?.cancel();
    super.dispose();
  }

  /// Warm schedule, then pick Home (0) vs Leaderboard (1) from entry status.
  Future<int> _warmAndResolveTab() async {
    try {
      final dataProvider = Provider.of<DataProvider>(context, listen: false);
      await dataProvider.getWeek().timeout(const Duration(seconds: 6));
      if (dataProvider.game != null) {
        await dataProvider.getGame().timeout(const Duration(seconds: 8));
      }
      final week = dataProvider.game?['name']?.toString();
      return PaymentService.resolveHomeTabForWeek(week);
    } catch (e) {
      debugPrint('AuthSessionGate: warm/resolve failed: $e');
      return 0;
    }
  }

  Widget _routeForUser(User? user) {
    if (user != null) {
      if (_warmedUid != user.uid || _entryFuture == null) {
        _warmedUid = user.uid;
        _entryFuture = _warmAndResolveTab();
      }
      return FutureBuilder<int>(
        future: _entryFuture,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const _SessionSplash(message: 'Welcome back…');
          }
          final tab = snap.data ?? 0;
          return HomePage(initial: tab);
        },
      );
    }

    _entryFuture = null;
    _warmedUid = null;
    return const LandingPage();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authStream,
      builder: (context, snapshot) {
        final waiting = snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData &&
            !snapshot.hasError;

        if (waiting && !_authTimedOut) {
          return const _SessionSplash();
        }

        // Prefer stream data, but fall back to the SDK's synchronous user:
        // a transient null emission would otherwise drop _entryFuture, tear
        // down HomePage and re-warm the whole schedule a second time.
        final user = snapshot.data ?? FirebaseAuth.instance.currentUser;

        if (waiting && _authTimedOut) {
          debugPrint(
            'AuthSessionGate: auth stream timed out — '
            'currentUser=${user?.email ?? "null"}',
          );
        }

        return _routeForUser(user);
      },
    );
  }
}

class _SessionSplash extends StatelessWidget {
  final String message;
  const _SessionSplash({this.message = 'Loading'});

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
              errorBuilder: (_, __, ___) => const Icon(
                Icons.sports_football,
                size: 80,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2.5,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
