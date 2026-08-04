import 'Play.dart';
import '../Auth/Signup.dart';
import '../../../Widget/reuse.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../Widget/countDown.dart';
import '../../../Provider/homeProvider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:poolqapp/Module/Screen/Home/LeaderbpardWidget.dart';
import 'package:poolqapp/Model/games.dart';
import 'package:poolqapp/widgets/home/home_welcome_cards.dart';
import 'package:poolqapp/constants/app_theme.dart';

class HomePageWidget extends StatefulWidget {
  PageController? controller;
  bool? isEmpty;

  HomePageWidget({required this.controller, this.isEmpty});

  @override
  _HomePageWidgetState createState() => _HomePageWidgetState();
}

class _HomePageWidgetState extends State<HomePageWidget> {
  User? user = FirebaseAuth.instance.currentUser;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  List<GamesModel>? data;

  Future getGame(context) async {
    try {
      setState(() {
        data = [
          GamesModel(
            date: "Thursday September 4TH, 2025",
            fullname: "Philadelphia Eagles",
            fullname2: "Dallas Cowboys",
            abbreviation: "PHI",
            abbreviation2: "DAL",
            picture:
                "https://a.espncdn.com/i/teamlogos/nfl/500/scoreboard/phi.png",
            picture2:
                "https://a.espncdn.com/i/teamlogos/nfl/500/scoreboard/dal.png",
            score: "0",
            score2: "0",
          ),
        ];
      });
      return data;
    } catch (e) {
      setState(() => data = []);
      return [];
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dataProvider = Provider.of<DataProvider>(context, listen: false);
      if (dataProvider.game != null) {
        getGame(context);
      }
    });
  }

  String _deadlineRaw(DataProvider dataProvider) {
    if (dataProvider.data == null || dataProvider.data!.isEmpty) return '';
    final first = dataProvider.data![0];
    if (first is String) return first;
    return (first['date'] ?? '').toString();
  }

  Future<void> _onLetsPlay(DataProvider dataProvider) async {
    if (dataProvider.data == null || dataProvider.game == null) {
      customSnackbar(context, 'loading games');
      return;
    }
    final alreadyEntered = widget.isEmpty == false;
    if (alreadyEntered) {
      if (widget.controller != null) {
        widget.controller!.jumpToPage(1);
        dataProvider.setValue(1);
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LeaderboardWidget()),
        );
      }
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PlayWidget()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dataProvider = Provider.of<DataProvider>(context, listen: true);
    final alreadyEntered = widget.isEmpty == false;
    final loading =
        dataProvider.data == null || dataProvider.game == null;

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: const Color(0xFFF5F5F5),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/gb.jpeg', fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: Container(color: Colors.white38),
          ),
          if (loading)
            const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF063a73)),
              ),
            )
          else
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: IconButton(
                        onPressed: () async {
                          await FirebaseAuth.instance.signOut();
                          if (!mounted) return;
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RegisterWidget(),
                            ),
                            (route) => false,
                          );
                        },
                        icon: const Icon(
                          Icons.logout,
                          size: 28,
                          color: Color.fromRGBO(6, 58, 115, 1),
                        ),
                      ),
                    ),
                    Image.asset(
                      'assets/images/poolq12.png',
                      width: 140,
                      height: 150,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 8),
                    HomeWelcomeCards(
                      alreadyEntered: alreadyEntered,
                      onLetsPlay: () => _onLetsPlay(dataProvider),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withOpacity(0.92),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'ENTRY DEADLINE: ${_deadlineRaw(dataProvider)}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 6),
                          CountdownTimerDemo(
                            dataProvider.formatStringDate(
                              _deadlineRaw(dataProvider),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
