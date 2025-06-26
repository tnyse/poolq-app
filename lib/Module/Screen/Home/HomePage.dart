import 'LeaderbpardWidget.dart';
import 'package:flutter_svg/svg.dart';
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
  Stream<QuerySnapshot>? _pickrecord;
  bool _isLoading = true;
  String? _error;
  int _retryCount = 0;
  static const int _maxRetries = 3;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = PageController(
      viewportFraction: 1,
      initialPage: widget.initial ?? 0
    );
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
      
      // Check if user is authenticated
      if (user == null) {
        throw Exception('User not authenticated');
      }
      
      // Initialize game data if not already initialized with timeout
      if (dataProvider.game == null) {
        debugPrint('HomePage: dataProvider.game is null, calling getWeek()');
        await dataProvider.getWeek().timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            debugPrint('HomePage: getWeek() timed out, using default values');
            dataProvider.game = {"name": "REG1", "year": "2025", "mode": "REG"};
            dataProvider.notifyListeners();
          },
        );
      }
      
      // Initialize user info with timeout
      await authProvider.getUserInfo().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint('HomePage: getUserInfo() timed out');
          throw Exception('User info fetch timed out');
        },
      );
      
      // Initialize pick record stream
      if (mounted) {
        _pickrecord = FirebaseFirestore.instance
            .collection("Pick")
            .where("week", isEqualTo: dataProvider.game!['name'])
            .where("user", isEqualTo: user.email)
            .snapshots();
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

  @override
  Widget build(BuildContext context) {
    final dataProvider = Provider.of<DataProvider>(context, listen: true);

    if (_isLoading) {
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

    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: _pickrecord,
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong'));
          }

          if (snapshot.connectionState == ConnectionState.waiting ||
              snapshot.data == null) {
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
                isEmpty: snapshot.data!.docs.isEmpty
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
