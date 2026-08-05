import 'dart:async';

import 'LeaderbpardWidget.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../Provider/homeProvider.dart';
import '../../../Provider/AuthProviders.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:poolqapp/Module/Screen/Home/landingPage.dart';
import 'package:poolqapp/Module/Screen/Profile/UserProfile.dart';
import 'package:flutter_phosphor_icons/flutter_phosphor_icons.dart';
import 'package:poolqapp/constants/app_theme.dart';
import 'package:poolqapp/screens/invite_friends_page.dart';
import 'package:poolqapp/services/game_enforcement_service.dart';
import 'package:poolqapp/services/payment_reminder_service.dart';
import 'package:poolqapp/services/payment_service.dart';
import 'package:poolqapp/services/app_config_service.dart';
import 'package:poolqapp/constants/season_config.dart';

// import 'package:phosphor_flutter/phosphor_flutter.dart';

class HomePage extends StatefulWidget {
  final int? initial;
  const HomePage({Key? key, this.initial = 1}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late PageController _controller;
  User? user = FirebaseAuth.instance.currentUser;
  /// Never null — null streams leave StreamBuilder stuck on waiting forever.
  Stream<DocumentSnapshot?> _pickDoc = Stream.value(null);
  bool _isLoading = true;
  String? _error;
  int _retryCount = 0;
  static const int _maxRetries = 3;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    debugPrint('HomePage: initState called');
    debugPrint('HomePage: User in initState: ${user?.email ?? "null"}');
    _controller = PageController(
      viewportFraction: 1,
      initialPage: widget.initial ?? 0,
    );
    // Sync bottom-nav with starting tab (0=Home/Play, 1=Leaderboard).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final dataProvider = Provider.of<DataProvider>(context, listen: false);
      dataProvider.setValue(widget.initial ?? 0);
    });
    debugPrint('HomePage: PageController created, calling _initializeData');
    _initializeData(user);
  }

  @override
  void dispose() {
    PaymentReminderService().stopMonitoring();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _startPaymentReminders() async {
    if (!mounted) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == 'demo@poolq.com') return;

    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    final week = dataProvider.game?['name']?.toString();
    if (week == null || week.isEmpty) return;

    try {
      final kickoff = await GameEnforcementService().getFirstKickoff(week);
      if (kickoff == null || !mounted) return;
      await PaymentReminderService().startMonitoring(
        context: context,
        weekName: week,
        kickoff: kickoff,
      );
    } catch (e) {
      debugPrint('HomePage: payment reminders failed to start: $e');
    }
  }

    Future<void> _initializeData(User? user) async {
    if (!mounted || _isInitialized) return;

    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _error = null;
        });
      }

      final dataProvider = Provider.of<DataProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProviders>(context, listen: false);
      debugPrint('HomePage: _initializeData called with user: ${user?.email ?? "null"}');
      
      // For demo mode, use simplified initialization
      if (user == null || user.email == 'demo@poolq.com') {
        debugPrint('HomePage: Demo mode - using simplified initialization');
        await _initializeGameData(dataProvider);
        await _initializePickStream(user);
        
        if (mounted) {
          setState(() {
            _isInitialized = true;
            _isLoading = false;
          });
        }
        return;
      }
      
      // For real users, use full initialization with timeout
      try {
        await Future.wait([
          _initializeGameData(dataProvider),
          _initializeUserData(authProvider, user),
          _initializePickStream(user),
        ]).timeout(Duration(seconds: 10), onTimeout: () {
          debugPrint('HomePage: Initialization timed out, proceeding with available data');
          return <void>[];
        });
      } catch (e) {
        debugPrint('HomePage: Initialization timed out, proceeding with available data: $e');
      }
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
          _isLoading = false;
        });
        unawaited(_startPaymentReminders());
      }
      
    } catch (e, stack) {
      debugPrint('Error in _initializeData: $e');
      debugPrint('Stack trace: $stack');
      if (_retryCount < _maxRetries) {
        _retryCount++;
        await Future.delayed(Duration(seconds: 1));
        if (mounted) {
          return _initializeData(user);
        }
      }
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Error initializing data: ${e.toString()}';
        });
      }
    }
  }

  Future<void> _initializeGameData(DataProvider dataProvider) async {
    // Check if user is authenticated (allow demo mode)
    if (user == null) {
      // In demo mode, we can proceed without a real user
      debugPrint('HomePage: Demo mode - no user authenticated, proceeding with demo data');
    }
    
    // Initialize game data if not already initialized
    if (dataProvider.game == null) {
      debugPrint('HomePage: dataProvider.game is null, calling getWeek()');
      await dataProvider.getWeek();
      debugPrint('HomePage: getWeek() completed');
    }
    
    // Also load game data if not already loaded
    if (dataProvider.data == null) {
      debugPrint('HomePage: dataProvider.data is null, calling getGame()');
      await dataProvider.getGame();
      debugPrint('HomePage: getGame() completed');
    }
    
    debugPrint('HomePage: _initializeGameData completed');
  }

  Future<void> _initializeUserData(AuthProviders authProvider, User? user) async {
    // Initialize user info with timeout (skip for demo mode)
    if (user != null) {
      await authProvider.getUserInfo().timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          debugPrint('HomePage: getUserInfo() timed out');
          throw Exception('User info fetch timed out');
        },
      );
    } else {
      debugPrint('HomePage: Demo mode - skipping user info fetch');
    }
    debugPrint('HomePage: _initializeUserData completed');
  }

  Future<void> _initializePickStream(User? user) async {
    if (!mounted) return;
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    if (user?.email == 'demo@poolq.com' || user == null) {
      debugPrint('HomePage: Demo mode - no pick doc stream');
      _pickDoc = Stream.value(null);
      return;
    }

    final config = AppConfigService();
    final weekName = dataProvider.game?['name']?.toString().isNotEmpty == true
        ? dataProvider.game!['name'].toString()
        : (config.isLoaded
            ? config.activeWeek
            : SeasonConfig.defaultWeekName());

    final docId = PaymentService.pickDocumentId(user.uid, weekName);
    debugPrint('HomePage: pick stream → pickrecord/$docId');
    // Doc listen needs no composite index and always emits (exists or not).
    _pickDoc = FirebaseFirestore.instance
        .collection('pickrecord')
        .doc(docId)
        .snapshots()
        .map((snap) => snap);
    debugPrint('HomePage: _initializePickStream completed');
  }

  bool _hasSubmittedPicks(AsyncSnapshot<DocumentSnapshot?> snapshot) {
    final doc = snapshot.data;
    return doc != null && doc.exists;
  }

  Widget _buildLoadingSplash({String message = 'Loading'}) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBlue,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2.5,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('HomePage: build method called');
    debugPrint('HomePage: _isLoading: $_isLoading, _isInitialized: $_isInitialized, _error: $_error');
    
    final dataProvider = Provider.of<DataProvider>(context, listen: true);

    if (_isLoading) {
      debugPrint('HomePage: Showing loading screen');
      return _buildLoadingSplash();
    }

    if (_error != null) {
      debugPrint('HomePage: Showing error screen: $_error');
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: AppTheme.error),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                style: AppTheme.primaryButtonStyle,
                onPressed: () {
                  setState(() {
                    _error = null;
                    _isLoading = true;
                    _retryCount = 0;
                  });
                  _initializeData(user);
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    debugPrint('HomePage: Showing main scaffold');
    return Scaffold(
      backgroundColor: AppTheme.primaryBlue,
      appBar: AppBar(
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset(
                'assets/images/app_icon.png',
                width: 28,
                height: 28,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Image.asset(
                  'assets/images/poolq12.png',
                  width: 28,
                  height: 28,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            if (kDebugMode) ...[
              SizedBox(width: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'DEBUG',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        actionsIconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(
              PhosphorIcons.user_plus,
              color: Colors.white,
            ),
            tooltip: 'Invite friends',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const InviteFriendsPage()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot?>(
        stream: _pickDoc,
        builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot?> snapshot) {
          debugPrint(
            'HomePage: StreamBuilder state: ${snapshot.connectionState}, '
            'hasData: ${snapshot.hasData}, hasError: ${snapshot.hasError}',
          );

          // Never block the shell on picks stream — empty / error / waiting
          // all still show tabs (Play Now vs review based on doc existence).
          final isDemo = user == null || user?.email == 'demo@poolq.com';
          final isEmpty = isDemo ? true : !_hasSubmittedPicks(snapshot);

          if (snapshot.hasError) {
            debugPrint('HomePage: StreamBuilder error: ${snapshot.error}');
          }

          return PageView(
            controller: _controller,
            onPageChanged: (index) {
              if (mounted) {
                dataProvider.setValue(index);
              }
            },
            children: [
              HomePageWidget(
                controller: _controller,
                isEmpty: isEmpty,
              ),
              const LeaderboardWidget(),
              const UserProfile(),
            ],
          );
        },
      ),
      bottomNavigationBar: buildMyNavBar(context, dataProvider),
    );
  }

  Container buildMyNavBar(BuildContext context, DataProvider dataProvider) {
    return Container(
      height: 60,
      decoration: const BoxDecoration(
        color: AppTheme.primaryBlue,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            enableFeedback: false,
            onPressed: () {
              if (mounted) {
                setState(() {
                  dataProvider.setValue(0);
                });
                _controller.jumpToPage(0);
              }
            },
            icon: Icon(
              dataProvider.pageIndex == 0
                  ? PhosphorIcons.house_fill
                  : PhosphorIcons.house,
              color: Colors.white,
            ),
          ),
          IconButton(
            enableFeedback: false,
            onPressed: () {
              if (mounted) {
                setState(() {
                  dataProvider.setValue(1);
                });
                _controller.jumpToPage(1);
              }
            },
            icon: Icon(
              dataProvider.pageIndex == 1
                  ? PhosphorIcons.trophy_fill
                  : PhosphorIcons.trophy,
              color: Colors.white,
            ),
          ),
          IconButton(
            enableFeedback: false,
            onPressed: () {
              if (mounted) {
                setState(() {
                  dataProvider.setValue(2);
                });
                _controller.jumpToPage(2);
              }
            },
            icon: Icon(
              dataProvider.pageIndex == 2
                  ? PhosphorIcons.user_fill
                  : PhosphorIcons.user,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
