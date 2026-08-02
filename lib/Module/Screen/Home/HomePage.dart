import 'LeaderbpardWidget.dart';
import 'package:flutter_svg/svg.dart';
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

// import 'package:phosphor_flutter/phosphor_flutter.dart';

class HomePage extends StatefulWidget {
  final int? initial;
  const HomePage({Key? key, this.initial}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late PageController _controller;
  User? user = FirebaseAuth.instance.currentUser;
  Stream<QuerySnapshot?>? _pickrecord;
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
      initialPage: widget.initial ?? 0
    );
    debugPrint('HomePage: PageController created, calling _initializeData');
    _initializeData(user);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
    // Initialize pick record stream - handle demo mode
    if (mounted) {
      final dataProvider = Provider.of<DataProvider>(context, listen: false);
      if (user?.email == 'demo@poolq.com' || user == null) {
        // Demo mode - use Stream.empty() to avoid hanging
        debugPrint('HomePage: Demo mode - using Stream.empty() for pick stream');
        _pickrecord = Stream.empty();
      } else {
        // Real user - use Firebase stream
        _pickrecord = FirebaseFirestore.instance
            .collection("Pick")
            .where("week", isEqualTo: dataProvider.game!['name'])
            .where("user", isEqualTo: user.email)
            .snapshots();
      }
    }
    debugPrint('HomePage: _initializePickStream completed');
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('HomePage: build method called');
    debugPrint('HomePage: _isLoading: $_isLoading, _isInitialized: $_isInitialized, _error: $_error');
    
    final dataProvider = Provider.of<DataProvider>(context, listen: true);

    if (_isLoading) {
      debugPrint('HomePage: Showing loading screen');
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF063a73)),
              ),
              SizedBox(height: 16),
              Text('Loading...'),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      debugPrint('HomePage: Showing error screen: $_error');
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
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
      appBar: AppBar(
        title: Row(
          children: [
            Text('PoolQ'),
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
        backgroundColor: Color(0xFF063a73),
        foregroundColor: Colors.white,
        actions: [
          Container(
            margin: EdgeInsets.only(right: 8),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/front');
              },
              icon: Icon(Icons.article_outlined, size: 18),
              label: Text('NFL News'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Color(0xFF063a73),
                elevation: 2,
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.info_outline),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('You are in demo mode. All features are available for testing.'),
                  duration: Duration(seconds: 3),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot?>(
        stream: _pickrecord,
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot?> snapshot) {
          debugPrint('HomePage: StreamBuilder state: ${snapshot.connectionState}, hasData: ${snapshot.hasData}, hasError: ${snapshot.hasError}');
          debugPrint('HomePage: User is: ${user?.email ?? "null"}');
          
          if (snapshot.hasError) {
            debugPrint('HomePage: StreamBuilder error: ${snapshot.error}');
            return const Center(child: Text('Something went wrong'));
          }

          // For demo mode, always show the content regardless of stream state
          if (user == null || user?.email == 'demo@poolq.com') {
            debugPrint('HomePage: Demo mode detected, showing content directly');
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
                  isEmpty: true // Demo mode - always show as empty for fresh start
                ),
                const LeaderboardWidget(),
                const UserProfile()
              ],
            );
          }

          // For real users, show loading while waiting for data
          if (snapshot.connectionState == ConnectionState.waiting || 
              (snapshot.connectionState == ConnectionState.done && !snapshot.hasData)) {
            debugPrint('HomePage: Real user mode - showing loading screen');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: ColorScheme.fromSwatch()
                          .copyWith(secondary: const Color(0xFF063a73)),
                    ),
                    child: const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF063a73)),
                      strokeWidth: 2,
                      backgroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Loading',
                    style: TextStyle(
                      color: Color(0xFF333333),
                      fontSize: 18,
                      fontWeight: FontWeight.w600
                    ),
                  ),
                ],
              ),
            );
          }

          debugPrint('HomePage: Real user mode - showing content with data');
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
                isEmpty: false
              ),
              const LeaderboardWidget(),
              const UserProfile()
            ],
          );
        }
      ),
      bottomNavigationBar: buildMyNavBar(context, dataProvider),
    );
  }

  Container buildMyNavBar(BuildContext context, DataProvider dataProvider) {
    return Container(
      height: 60,
      decoration: const BoxDecoration(
        color: Color(0xFF063A73),
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
