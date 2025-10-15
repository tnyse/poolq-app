import 'package:poolqapp/constants.dart';
import 'games.dart';
import 'dart:convert';
import 'EditPlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:poolqapp/Provider/homeProvider.dart';
// import 'package:poolqapp/Provider/AuthProviders.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:poolqapp/Module/Screen/Home/picks.dart';
// import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:poolqapp/Module/Screen/Home/picked.dart';
import 'Play.dart';
import '../../../services/nfl_schedule_service.dart';
// import 'package:poolqapp/Widget/reuse.dart';
// import 'package:google_fonts/google_fonts.dart';
//import 'package:admob_flutter/admob_flutter.dart';

class LeaderboardWidget extends StatefulWidget {
  const LeaderboardWidget({Key? key}) : super(key: key);

  @override
  _LeaderboardWidgetState createState() => _LeaderboardWidgetState();
}

class _LeaderboardWidgetState extends State<LeaderboardWidget> {
  // late LeaderboardModel _model;
  User? user = FirebaseAuth.instance.currentUser;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final _unfocusNode = FocusNode();
  // final Stream<QuerySnapshot> _leaderboard_recordStream =
  //     FirebaseFirestore.instance.collection('leaderboard_record').snapshots();

  List? data;
  List? data2;
  List? normal_data;
  var particularData;
  bool? played;

  Future<void> _showPaymentModal(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Complete Payment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('Entry fee: \$10.00'),
              SizedBox(height: 8),
              Text('Pay using one of the methods below:'),
              SizedBox(height: 8),
              SelectableText('Venmo: https://venmo.com/u/PoolQPayments'),
              SelectableText('PayPal: poolq.payments@gmail.com'),
              SelectableText('Zelle: poolq.payments@gmail.com'),
              SelectableText('Cash App: \$PoolQPayments'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop(); // Close modal first
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PlayWidget(),
                  ),
                );
              },
              child: const Text('Continue to Entry'),
            ),
          ],
        );
      },
    );
  }

  Future getGame(context, selectedValue) async {
    DataProvider dataProvider = Provider.of<DataProvider>(context, listen: false);
    final scheduleService = NFLScheduleService();
    
    // Check if we're in demo mode
    print('LeaderboardWidget: Checking demo mode for games - user = ${user?.email ?? "null"}');
    if (user == null || user?.email == 'demo@poolq.com') {
      print('LeaderboardWidget: Demo mode detected, using mock game data');
      
      // Use mock games data for demo - actual preseason Week 1 games
      List<Map<String, dynamic>> mockGames = [
        {
          "id": "demo-game-1",
          "date": "2025-08-08T17:00:00Z",
          "homeTeam": "Detroit Lions",
          "awayTeam": "Atlanta Falcons",
          "homeAbbr": "DET",
          "awayAbbr": "ATL",
          "homeScore": null,
          "awayScore": null,
          "status": "scheduled",
        },
        {
          "id": "demo-game-2", 
          "date": "2025-08-08T17:00:00Z",
          "homeTeam": "Cleveland Browns",
          "awayTeam": "Carolina Panthers",
          "homeAbbr": "CLE",
          "awayAbbr": "CAR",
          "homeScore": null,
          "awayScore": null,
          "status": "scheduled",
        },
        {
          "id": "demo-game-3",
          "date": "2025-08-08T17:30:00Z", 
          "homeTeam": "Washington Commanders",
          "awayTeam": "New England Patriots",
          "homeAbbr": "WAS",
          "awayAbbr": "NE",
          "homeScore": null,
          "awayScore": null,
          "status": "scheduled",
        },
      ];
      
      setState(() {
        data2 = mockGames;
      });
      print('Successfully loaded ${mockGames.length} mock games for leaderboard');
      return mockGames;
    }
    
    try {
      print('Fetching games for leaderboard from multiple sources...');
      
      String weekName = "${dataProvider.game!["mode"]}$selectedValue";
      
      // Try the new schedule service with multiple fallback options
      List<Map<String, dynamic>> games = await scheduleService.getScheduleWithFallback(weekName);
      
      // If no games from live APIs, try the original custom API
      if (games.isEmpty) {
        print('Trying original API for leaderboard: ${mainUrl}/getnlf/$weekName');
        
        var response = await http.get(
          Uri.parse('${mainUrl}/getnlf/$weekName'),
          headers: {
            'Content-Type': 'application/json; charset=UTF-8',
            'Access-Control-Allow-Origin': '*',
          },
        ).timeout(Duration(seconds: 20));
        
        if (response.statusCode == 200) {
          var body = json.decode(response.body);
          if (body is List && body.isNotEmpty) {
            setState(() {
              data2 = body;
            });
            return body;
          }
        }
      } else {
        setState(() {
          data2 = games;
        });
        print('Successfully loaded ${games.length} games for leaderboard from NFL APIs');
        return games;
      }
      
    } catch (e) {
      print('Error fetching games for leaderboard: $e');
    }
    
    return [];
  }

  // ${mainUrl}/getnlf/${dataProvider.game!["mode"]}${widget.selectedValue}
  Future getLeaderBoard(context, selectedValue) async {
    DataProvider dataProvider =
        Provider.of<DataProvider>(context, listen: false);
    
    // Check if we're in demo mode
    print('LeaderboardWidget: Checking demo mode - user = ${user?.email ?? "null"}');
    if (user == null || user?.email == 'demo@poolq.com') {
      print('LeaderboardWidget: Demo mode detected, using hardcoded demo data instead of Firestore');
      
      try {
        // Use hardcoded demo leaderboard data to avoid Firestore permission issues
        final weekName = "${dataProvider.game!["mode"]}${selectedValue}";
        
        print('LeaderboardWidget: Creating hardcoded demo leaderboard for week $weekName');
        
        List<Map<String, dynamic>> demoLeaderboard = [];
        
        // Determine if this week is completed (has final scores) or in progress
        final isWeekCompleted = weekName == 'REG1'; // REG1 has completed games with scores
        final isCurrentWeek = weekName == 'REG1'; // REG1 is the current picking week
        
        // Add single demo user entry (the actual user) - only ONE entry
        final currentDemoUser = {
          "uid": "demo_user_current",
          "displayName": "Demo User (Current Session)",
          "photoURL": "",
          "score": isWeekCompleted ? 8 : 0, // Show score only if week is completed
          "picks": isCurrentWeek ? [] : ["DAL", "LAC", "ATL", "NYJ", "IND", "JAX", "WAS", "ARI", "CIN", "SF", "LV", "DEN", "GB", "LAR", "BUF"], // Empty picks for current week
          "tiebreaker": isCurrentWeek ? null : 50,
          "rank": isWeekCompleted ? 5 : 1, // Rank based on completion status
          "week": weekName,
          "hasSubmittedPicks": !isCurrentWeek,
        };
        demoLeaderboard.add(currentDemoUser);
        
        // Add AI players with proper Week 1 2025 picks and scores
        final samplePlayers = [
          {"uid": "demo_mike", "displayName": "Mike Johnson", "score": isWeekCompleted ? 12 : 0, "picks": ["PHI", "KC", "TB", "PIT", "MIA", "CAR", "NYG", "NO", "CLE", "NE", "SEA", "TEN", "DET", "HOU", "BAL"], "tiebreaker": 24},
          {"uid": "demo_jessica", "displayName": "Jessica Chen", "score": isWeekCompleted ? 11 : 0, "picks": ["DAL", "LAC", "ATL", "NYJ", "IND", "JAX", "WAS", "ARI", "CIN", "SF", "LV", "DEN", "GB", "LAR", "BUF"], "tiebreaker": 17},
          {"uid": "demo_alex", "displayName": "Alex Rodriguez", "score": isWeekCompleted ? 10 : 0, "picks": ["PHI", "KC", "TB", "PIT", "MIA", "CAR", "NYG", "NO", "CLE", "NE", "SEA", "TEN", "DET", "HOU", "BAL"], "tiebreaker": 19},
          {"uid": "demo_emma", "displayName": "Emma Thompson", "score": isWeekCompleted ? 9 : 0, "picks": ["DAL", "LAC", "ATL", "NYJ", "IND", "JAX", "WAS", "ARI", "CIN", "SF", "LV", "DEN", "GB", "LAR", "BUF"], "tiebreaker": 22},
        ];
        
        for (int i = 0; i < samplePlayers.length; i++) {
          final player = samplePlayers[i];
          demoLeaderboard.add({
            "uid": player["uid"],
            "displayName": player["displayName"],
            "photoURL": "",
            "score": player["score"],
            "picks": player["picks"],
            "tiebreaker": player["tiebreaker"],
            "rank": i + 2, // Start from rank 2 since current user is rank 1
            "week": weekName,
          });
        }
        
        print('LeaderboardWidget: Created ${demoLeaderboard.length} demo leaderboard entries');

        // Skip Firestore query completely in demo mode to avoid permission issues
        print('LeaderboardWidget: Skipping Firestore query in demo mode to avoid permission errors');

        setState(() {
          data = demoLeaderboard;
          normal_data = [...demoLeaderboard];
          this.played = true;
          particularData = demoLeaderboard.first; // Current demo user is always first
        });
        
        print('Successfully loaded ${demoLeaderboard.length} demo leaderboard entries (no Firestore query in demo mode)');
        return demoLeaderboard;
      } catch (e) {
        print('Error fetching demo entries, using fallback: $e');
        
        // Fallback: Use same logic as above to avoid duplicates
        final fallbackWeekName = "${dataProvider.game!["mode"]}${selectedValue}";
        final isWeekCompletedFallback = fallbackWeekName == 'REG1';
        List<Map<String, dynamic>> fallbackLeaderboard = [
          {
            "uid": "demo_user_current",
            "displayName": "Demo User (Current Session)",
            "photoURL": "",
            "score": isWeekCompletedFallback ? 8 : 0,
            "picks": isWeekCompletedFallback ? ["DAL", "LAC", "ATL", "NYJ", "IND", "JAX", "WAS", "ARI", "CIN", "SF", "LV", "DEN", "GB", "LAR", "BUF"] : [],
            "tiebreaker": isWeekCompletedFallback ? 50 : null,
            "rank": isWeekCompletedFallback ? 5 : 1,
            "week": fallbackWeekName,
            "hasSubmittedPicks": isWeekCompletedFallback,
          },
          {
            "uid": "demo_mike",
            "displayName": "Mike Johnson",
            "photoURL": "",
            "score": isWeekCompletedFallback ? 12 : 0,
            "picks": ["PHI", "KC", "TB", "PIT", "MIA", "CAR", "NYG", "NO", "CLE", "NE", "SEA", "TEN", "DET", "HOU", "BAL"],
            "tiebreaker": 24,
            "rank": isWeekCompletedFallback ? 1 : 2,
            "week": fallbackWeekName,
          },
          {
            "uid": "demo_jessica",
            "displayName": "Jessica Chen",
            "photoURL": "",
            "score": isWeekCompletedFallback ? 11 : 0,
            "picks": ["DAL", "LAC", "ATL", "NYJ", "IND", "JAX", "WAS", "ARI", "CIN", "SF", "LV", "DEN", "GB", "LAR", "BUF"],
            "tiebreaker": 17,
            "rank": isWeekCompletedFallback ? 2 : 3,
            "week": fallbackWeekName,
          },
          {
            "uid": "demo_alex",
            "displayName": "Alex Rodriguez",
            "photoURL": "",
            "score": isWeekCompletedFallback ? 10 : 0,
            "picks": ["PHI", "KC", "TB", "PIT", "MIA", "CAR", "NYG", "NO", "CLE", "NE", "SEA", "TEN", "DET", "HOU", "BAL"],
            "tiebreaker": 19,
            "rank": isWeekCompletedFallback ? 3 : 4,
            "week": fallbackWeekName,
          },
          {
            "uid": "demo_emma",
            "displayName": "Emma Thompson",
            "photoURL": "",
            "score": isWeekCompletedFallback ? 9 : 0,
            "picks": ["DAL", "LAC", "ATL", "NYJ", "IND", "JAX", "WAS", "ARI", "CIN", "SF", "LV", "DEN", "GB", "LAR", "BUF"],
            "tiebreaker": 22,
            "rank": isWeekCompletedFallback ? 4 : 5,
            "week": fallbackWeekName,
          },
        ];
        
        setState(() {
          data = fallbackLeaderboard;
          normal_data = [...fallbackLeaderboard];
          this.played = true;
          particularData = fallbackLeaderboard.first;
        });
        
        return fallbackLeaderboard;
      }
    }
    
    var response = await http.get(
        Uri.parse(
            '${mainUrl}/getleaderboard/${dataProvider.game!["mode"]}${selectedValue}'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Access-Control-Allow-Origin': '*',
        }).timeout(Duration(seconds: 20));
    var body = json.decode(response.body);
    print(response.body);
    print(response.body);

    if (body.length != 0) {
      List body1 = body["leaderboardList"];
      bool played = body["played"];
      setState(() {
        data = body1;
        normal_data = [...body1];
        this.played = played;
        particularData = data!.singleWhere(
            (element) => element['uid'] == (user?.uid ?? 'demo_user'),
            orElse: () => "null");
        if (particularData == "null") {
          print("done");
        } else {
          data!.remove(particularData);
          data = [particularData, ...?data];
        }
        // print(particularData);
        // print(data);
      });
    } else {
      // No data returned from API – avoid indefinite loading by setting safe defaults
      setState(() {
        data = body; // empty list
        normal_data = body; // empty list
        // Mark that we attempted to load and there are no plays yet
        played = false;
        // Ensure UI moves past the loading gate
        particularData = "null";
      });
    }

    return body;
  }

  String? selectedValue;

  @override
  void initState() {
    super.initState();
    print('🌟🌟🌟🌟🌟 LEADERBOARD WIDGET INITSTATE CALLED! 🌟🌟🌟🌟🌟');
    DataProvider dataProvider =
        Provider.of<DataProvider>(context, listen: false);
    
    print('LeaderboardWidget: initState called');
    print('LeaderboardWidget: user = ${user?.email ?? "null"}');
    print('LeaderboardWidget: dataProvider.game = ${dataProvider.game}');

    // Set safe defaults to avoid indefinite loading spinners in demo/web
    setState(() {
      data = [];
      normal_data = [];
      particularData = "null";
      played = false;
    });
    
    // Check if dataProvider.game is null
    if (dataProvider.game != null) {
      selectedValue = dataProvider.game!["name"]
          .toString()
          .replaceAll("REG", "")
          .replaceAll("PRE", "");
      print('LeaderboardWidget: selectedValue = $selectedValue');
      getLeaderBoard(context, selectedValue);
      getGame(context, selectedValue);
    } else {
      print('LeaderboardWidget: dataProvider.game is null, using default PRE1');
      selectedValue = "1"; // Default for PRE1
      getLeaderBoard(context, selectedValue);
      getGame(context, selectedValue);
    }
    // _model = createModel(context, () => LeaderboardModel());
  }

  @override
  void dispose() {
    // _model.dispose();
    _unfocusNode.dispose();
    super.dispose();
  }

  final List<String> items = [
    '1',
    '2',
    '3',
    '5',
    '6',
    '7',
    '8',
    '9',
    '10',
    '11',
    '12',
    '13',
    '14',
    '15',
    '16',
    '17',
  ];

  @override
  Widget build(BuildContext context) {
    print('🎯🎯🎯 MAIN LEADERBOARD WIDGET IS BUILDING NOW! 🎯🎯🎯');
    print('🎯 LeaderboardWidget: BUILD METHOD CALLED - Main leaderboard is displaying');
    print('🎯 LeaderboardWidget: data length = ${data?.length ?? 0}, particularData = ${particularData != null ? "exists" : "null"}');
    
    // context.watch<FFAppState>();
    DataProvider dataProvider =
        Provider.of<DataProvider>(context, listen: true);
    // AuthProviders authProvider =
    //     Provider.of<AuthProviders>(context, listen: true);

    return GestureDetector(
      onTap: () => FocusScope.of(context).requestFocus(_unfocusNode),
      child: Scaffold(
        // bottomNavigationBar: Container(
        //     color: Colors.white,
        //     child: kIsWeb?AdmobBanner(
        //       adUnitId: Provider.of<DataProvider>(context, listen: false)
        //           .getBannerAdUnitId().toString(),
        //       adSize: AdmobBannerSize.BANNER,
        //       listener: (AdmobAdEvent event, Map<String, dynamic> ?args) {},
        //     ):Container()),
        key: scaffoldKey,
        backgroundColor: Color(0xFFF5F5F5),
        body: Stack(
          children: [
            Image.asset(
              "assets/images/gb.jpeg",
              height: MediaQuery.of(context).size.height,
              fit: BoxFit.cover,
              width: MediaQuery.of(context).size.width,
            ),
            Container(
              child: Text(""),
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              decoration: BoxDecoration(color: Colors.white38),
            ),
            Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                Stack(
                  children: [
                    Padding(
                      padding: EdgeInsetsDirectional.fromSTEB(0, 20, 0, 0),
                      child: Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    20, 20, 0, 0),
                                child: Image.asset(
                                  'assets/images/poolq12.png',
                                  width: 67,
                                  height: 90,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                                left: 12.0, right: 12, top: 25),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  width:
                                      MediaQuery.of(context).size.width * 0.5,
                                  child: Text(
                                    'Hello, ${user?.displayName ?? 'Demo User'}!'
                                        .toUpperCase(),
                                    style: TextStyle(
                                      fontFamily: 'Lexend Deca',
                                      color: Color(0xFF090F13),
                                      fontSize: 24,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    softWrap: true,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Spacer(),
                                InkWell(
                                  onTap: () {
                                    if (dataProvider.game!["mode"] == null) {
                                    } else if (dataProvider.game!["mode"] ==
                                        "PRE") {
                                      _showPicker2(context);
                                    } else {
                                      _showPicker(context);
                                    }
                                  },
                                  child: Row(
                                    children: [
                                      dataProvider.game!["mode"] == null
                                          ? Container()
                                          : dataProvider.game!["mode"] == "REG"
                                              ? Padding(
                                                  padding: EdgeInsetsDirectional
                                                      .fromSTEB(0, 0, 0, 0),
                                                  child: Text(
                                                    'Week: ${selectedValue} '
                                                        .toUpperCase(),
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontFamily: 'Poppins',
                                                      fontSize: 15,
                                                    ),
                                                  ),
                                                )
                                              : Padding(
                                                  padding: EdgeInsetsDirectional
                                                      .fromSTEB(0, 0, 0, 0),
                                                  child: Text(
                                                    'PRESEASON: ${selectedValue} '
                                                        .toUpperCase(),
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontFamily: 'Poppins',
                                                      fontSize: 15,
                                                    ),
                                                  ),
                                                ),
                                      Icon(
                                        Icons.arrow_drop_down_rounded,
                                        size: 30,
                                      )
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding:
                                EdgeInsetsDirectional.fromSTEB(20, 23, 0, 0),
                            child: Text(
                              'Leaderboard'.toUpperCase(),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Poppins',
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Padding(
                      padding: EdgeInsetsDirectional.fromSTEB(16, 15, 16, 0),
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(2, 0, 0, 0),
                            child: Text(
                              'Players'.toUpperCase(),
                              style: TextStyle(
                                fontFamily: 'Lexend Deca',
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              Builder(builder: (context) {
                                final currentUserId = user?.uid ?? 'demo_user';
                                // For demo mode, always show "Play Now" to create new unique entrants for testing
                                bool hasEntry = false;
                                if (user != null && user?.email != 'demo@poolq.com') {
                                  // Normal mode: check if user has any entry
                                  hasEntry = (data != null && data!.any((e) => e['uid'] == currentUserId));
                                } else {
                                  // Demo mode: always allow new entries for testing multiple entrants
                                  hasEntry = false;
                                  
                                  // Check if we have local storage data about a recent submission
                                  try {
                                    final timestamp = DateTime.now().millisecondsSinceEpoch;
                                    print('Demo mode: Allowing new entry creation (timestamp: $timestamp)');
                                  } catch (e) {
                                    print('Error checking local storage: $e');
                                  }
                                }
                                final label = hasEntry ? 'Edit Picks' : 'Play Now';
                                return ElevatedButton(
                                  onPressed: () async {
                                    if (!hasEntry) {
                                      await _showPaymentModal(context);
                                    } else {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => EditPlayWidget(),
                                        ),
                                      );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primary,
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Text(
                                    label,
                                    style: TextStyle(
                                      fontFamily: 'Lexend Deca',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                );
                              }),
                              SizedBox(width: 16),
                              Builder(builder: (_) {
                                final allFinal = (data2 != null && data2!.isNotEmpty) && data2!.every((g) {
                                  final s = (g['status'] ?? '').toString().toLowerCase();
                                  return s == 'final' || s == 'completed';
                                });
                                if (!allFinal) return const SizedBox.shrink();
                                return InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => GamePlayWidget(selectedValue: selectedValue),
                                      ),
                                    );
                                  },
                                  child: Padding(
                                    padding: EdgeInsetsDirectional.fromSTEB(2, 0, 0, 0),
                                    child: Text(
                                      'View Game Scores'.toUpperCase(),
                                      style: TextStyle(
                                        fontFamily: 'Lexend Deca',
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                played == false || played == null
                    ? Builder(
                        builder: (BuildContext context) {
                          if (data == null || particularData == null) {
                            return Center(
                                child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: ColorScheme.fromSwatch()
                                          .copyWith(
                                              secondary: Color(0xFF063a73)),
                                    ),
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Color(0xFF063a73)),
                                      strokeWidth: 2,
                                      backgroundColor: Colors.white,
                                      //  valueColor: new AlwaysStoppedAnimation<Color>(color: Color(0xFF9B049B)),
                                    )),
                                SizedBox(
                                  height: 10,
                                ),
                                Text('Loading',
                                    style: TextStyle(
                                        color: Color(0xFF333333),
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ));
                          } else if (data!.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.all(40.0),
                              child: Text(
                                "No Game Play Yet!",
                                style: TextStyle(fontSize: 25),
                              ),
                            );
                          }
                          return Expanded(
                            child: ListView.builder(
                              itemCount: data!.length,
                              itemBuilder: (BuildContext context, int index) {
                                return index == 0
                                    ? InkWell(
                                        onTap: () {
                                          final rowUserId = data![index]["uid"];
                                          final playerName = data![index]["displayName"];
                                          print('🔥🔥🔥 CLICK DETECTED! LeaderboardWidget: ROW CLICKED - User clicked on player at index $index');
                                          print('🔥🔥🔥 CLICK DETECTED! LeaderboardWidget: rowUserId=$rowUserId, currentUser=${user?.uid ?? 'demo_user'}');
                                          print('🔥🔥🔥 CLICK DETECTED! LeaderboardWidget: Player name: $playerName');
                                          
                                          // Show alert dialog to confirm click detection
                                          showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return AlertDialog(
                                                title: Text('🎯 Click Detected!'),
                                                content: Text('You successfully clicked on "$playerName"! \n\nThe click handler is working correctly. \n\nWould you like to view their picks?'),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () {
                                                      Navigator.of(context).pop(); // Close dialog
                                                      
                                                      // Then navigate based on logic
                                                      if (user == null || user?.email == 'demo@poolq.com') {
                                                        print('Opening PlayWidget for demo user - rowUserId=$rowUserId');
                                                        Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder: (context) => PlayWidget(),
                                                          ),
                                                        );
                                                      } else if (rowUserId == (user?.uid ?? 'demo_user')) {
                                                        print('Opening EditPlayWidget for current user');
                                                        Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder: (context) => EditPlayWidget(),
                                                          ),
                                                        );
                                                      } else {
                                                        print('Opening PickedWidget for other user');
                                                        Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder: (context) => PickedWidget(
                                                              userId: rowUserId,
                                                              selectedValue: selectedValue,
                                                            ),
                                                          ),
                                                        );
                                                      }
                                                    },
                                                    child: Text('Yes, View Picks'),
                                                  ),
                                                  TextButton(
                                                    onPressed: () {
                                                      Navigator.of(context).pop(); // Just close dialog
                                                    },
                                                    child: Text('Cancel'),
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        },
                                        child: Column(
                                          children: [
                                            Padding(
                                              padding: EdgeInsetsDirectional
                                                  .fromSTEB(10, 0, 10, 10),
                                              child: Container(
                                                width: MediaQuery.of(context)
                                                    .size
                                                    .width,
                                                height: 75,
                                                decoration: BoxDecoration(
                                                  color: Color(0xFF3474E0),
                                                  // image: DecorationImage(
                                                  //     image: AssetImage("assets/images/winner.png"),
                                                  //   fit: BoxFit.cover
                                                  // ),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Color(0x411D2429),
                                                      offset: Offset(0, 1),
                                                    )
                                                  ],
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Padding(
                                                  padding: EdgeInsetsDirectional
                                                      .fromSTEB(8, 8, 8, 8),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.max,
                                                    children: [
                                                      Padding(
                                                        padding:
                                                            EdgeInsetsDirectional
                                                                .fromSTEB(15, 1,
                                                                    1, 1),
                                                        child: Container(
                                                          height: 50,
                                                          width: 50,
                                                          child: data![index]['photoURL']
                                                                          .toString() ==
                                                                      "" ||
                                                                  data![index][
                                                                          'photoURL'] ==
                                                                      null
                                                              ? Image.asset(
                                                                  "assets/images/user.png",
                                                                  fit: BoxFit
                                                                      .cover)
                                                              : Image.network(
                                                                  data![index][
                                                                          'photoURL']
                                                                      .toString(),
                                                                  fit: BoxFit
                                                                      .cover),
                                                        ),
                                                      ),
                                                      Expanded(
                                                        child: Padding(
                                                          padding:
                                                              EdgeInsetsDirectional
                                                                  .fromSTEB(14,
                                                                      8, 4, 0),
                                                          child: Column(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .max,
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .center,
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Row(
                                                                children: [
                                                                  Text(
                                                                    '${data![index]['displayName']}'
                                                                        .toUpperCase(),
                                                                    style:
                                                                        TextStyle(
                                                                      fontFamily:
                                                                          'Lexend Deca',
                                                                      color: Colors
                                                                          .white,
                                                                      fontSize: 16,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w500,
                                                                    ),
                                                                  ),
                                                                  if (data![index]["uid"] == (user?.uid ?? 'demo_user') && 
                                                                      DateTime.now().isBefore(dataProvider.formatStringDate(data2![0]["date"])))
                                                                    Container(
                                                                      margin: EdgeInsets.only(left: 8),
                                                                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                                      decoration: BoxDecoration(
                                                                        color: Colors.green.withOpacity(0.2),
                                                                        borderRadius: BorderRadius.circular(12),
                                                                        border: Border.all(color: Colors.green, width: 1),
                                                                      ),
                                                                      child: Row(
                                                                        mainAxisSize: MainAxisSize.min,
                                                                        children: [
                                                                          Icon(
                                                                            Icons.edit,
                                                                            color: Colors.green,
                                                                            size: 12,
                                                                          ),
                                                                          SizedBox(width: 4),
                                                                          Text(
                                                                            'Editable',
                                                                            style: TextStyle(
                                                                              color: Colors.green,
                                                                              fontSize: 12,
                                                                              fontWeight: FontWeight.w500,
                                                                            ),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    ),
                                                                ],
                                                              ),
                                                              Expanded(
                                                                child: Padding(
                                                                  padding: EdgeInsetsDirectional
                                                                      .fromSTEB(
                                                                          0,
                                                                          4,
                                                                          8,
                                                                          0),
                                                                  child:
                                                                      AutoSizeText(
                                                                    'week ${selectedValue}'
                                                                        .toUpperCase(),
                                                                    textAlign:
                                                                        TextAlign
                                                                            .start,
                                                                    style:
                                                                        TextStyle(
                                                                      fontFamily:
                                                                          'Lexend Deca',
                                                                      color: Colors
                                                                          .white,
                                                                      fontSize:
                                                                          13,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                      Column(
                                                        mainAxisSize:
                                                            MainAxisSize.max,
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween,
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .end,
                                                        children: [
                                                          Padding(
                                                            padding:
                                                                EdgeInsetsDirectional
                                                                    .fromSTEB(
                                                                        0,
                                                                        0,
                                                                        0,
                                                                        0),
                                                            child: Icon(
                                                              Icons
                                                                  .chevron_right_rounded,
                                                              color:
                                                                  Colors.white,
                                                              size: 35,
                                                            ),
                                                          ),
                                                          Padding(
                                                            padding:
                                                                EdgeInsetsDirectional
                                                                    .fromSTEB(
                                                                        0,
                                                                        0,
                                                                        0,
                                                                        2),
                                                            child: Text(
                                                              'Score  ${'${data![index]['score']}'}'
                                                                  .toUpperCase(),
                                                              textAlign:
                                                                  TextAlign.end,
                                                              style: TextStyle(
                                                                fontFamily:
                                                                    'Lexend Deca',
                                                                color: Colors
                                                                    .white,
                                                                fontSize: 14,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : InkWell(
                                        onTap: () {
                                          final rowUserId = data![index]["uid"];
                                          final playerName = data![index]["displayName"];
                                          print('🔥🔥🔥 CLICK DETECTED! LeaderboardWidget NON-FIRST: ROW CLICKED - User clicked on player at index $index');
                                          print('🔥🔥🔥 CLICK DETECTED! LeaderboardWidget NON-FIRST: rowUserId=$rowUserId, currentUser=${user?.uid ?? 'demo_user'}');
                                          print('🔥🔥🔥 CLICK DETECTED! LeaderboardWidget NON-FIRST: Player name: $playerName');
                                          
                                          // Show alert dialog to confirm click detection
                                          showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return AlertDialog(
                                                title: Text('🎯 Click Detected!'),
                                                content: Text('You successfully clicked on "$playerName"! \n\nThe click handler is working correctly. \n\nWould you like to view their picks?'),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () {
                                                      Navigator.of(context).pop(); // Close dialog
                                                      
                                                      // Then navigate based on original logic
                                                      if (rowUserId == (user?.uid ?? 'demo_user')) {
                                                        Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder: (context) => EditPlayWidget(),
                                                          ),
                                                        );
                                                      } else {
                                                        Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder: (context) => PickedWidget(
                                                              userId: rowUserId,
                                                              selectedValue: selectedValue,
                                                            ),
                                                          ),
                                                        );
                                                      }
                                                    },
                                                    child: Text('Yes, View Picks'),
                                                  ),
                                                  TextButton(
                                                    onPressed: () {
                                                      Navigator.of(context).pop(); // Just close dialog
                                                    },
                                                    child: Text('Cancel'),
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        },
                                        child: Column(
                                          children: [
                                            Padding(
                                              padding: EdgeInsetsDirectional
                                                  .fromSTEB(10, 0, 10, 10),
                                              child: Container(
                                                width: MediaQuery.of(context)
                                                    .size
                                                    .width,
                                                height: 75,
                                                decoration: BoxDecoration(
                                                  color: Color(0xFF3474E0),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Color(0x411D2429),
                                                      offset: Offset(0, 1),
                                                    )
                                                  ],
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Padding(
                                                  padding: EdgeInsetsDirectional
                                                      .fromSTEB(8, 8, 8, 8),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.max,
                                                    children: [
                                                      Padding(
                                                        padding:
                                                            EdgeInsetsDirectional
                                                                .fromSTEB(15, 1,
                                                                    1, 1),
                                                        child: Container(
                                                          height: 50,
                                                          width: 50,
                                                          child: data![index]['photoURL']
                                                                          .toString() ==
                                                                      "" ||
                                                                  data![index][
                                                                          'photoURL'] ==
                                                                      null
                                                              ? Image.asset(
                                                                  "assets/images/user.png",
                                                                  fit: BoxFit
                                                                      .cover)
                                                              : Image.network(
                                                                  data![index][
                                                                          'photoURL']
                                                                      .toString(),
                                                                  fit: BoxFit
                                                                      .cover),
                                                        ),
                                                      ),
                                                      Expanded(
                                                        child: Padding(
                                                          padding:
                                                              EdgeInsetsDirectional
                                                                  .fromSTEB(14,
                                                                      8, 4, 0),
                                                          child: Column(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .max,
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .center,
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Row(
                                                                children: [
                                                                  Text(
                                                                    '${data![index]['displayName']}'
                                                                        .toUpperCase(),
                                                                    style:
                                                                        TextStyle(
                                                                      fontFamily:
                                                                          'Lexend Deca',
                                                                      color: Colors
                                                                          .white,
                                                                      fontSize: 16,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w500,
                                                                    ),
                                                                  ),
                                                                  if (data![index]["uid"] == (user?.uid ?? 'demo_user') && 
                                                                      DateTime.now().isBefore(dataProvider.formatStringDate(data2![0]["date"])))
                                                                    Container(
                                                                      margin: EdgeInsets.only(left: 8),
                                                                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                                      decoration: BoxDecoration(
                                                                        color: Colors.green.withOpacity(0.2),
                                                                        borderRadius: BorderRadius.circular(12),
                                                                        border: Border.all(color: Colors.green, width: 1),
                                                                      ),
                                                                      child: Row(
                                                                        mainAxisSize: MainAxisSize.min,
                                                                        children: [
                                                                          Icon(
                                                                            Icons.edit,
                                                                            color: Colors.green,
                                                                            size: 12,
                                                                          ),
                                                                          SizedBox(width: 4),
                                                                          Text(
                                                                            'Editable',
                                                                            style: TextStyle(
                                                                              color: Colors.green,
                                                                              fontSize: 12,
                                                                              fontWeight: FontWeight.w500,
                                                                            ),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    ),
                                                                ],
                                                              ),
                                                              Expanded(
                                                                child: Padding(
                                                                  padding: EdgeInsetsDirectional
                                                                      .fromSTEB(
                                                                          0,
                                                                          4,
                                                                          8,
                                                                          0),
                                                                  child:
                                                                      AutoSizeText(
                                                                    'week ${selectedValue}'
                                                                        .toUpperCase(),
                                                                    textAlign:
                                                                        TextAlign
                                                                            .start,
                                                                    style:
                                                                        TextStyle(
                                                                      fontFamily:
                                                                          'Lexend Deca',
                                                                      color: Colors
                                                                          .white,
                                                                      fontSize:
                                                                          13,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                      Column(
                                                        mainAxisSize:
                                                            MainAxisSize.max,
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween,
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .end,
                                                        children: [
                                                          Padding(
                                                            padding:
                                                                EdgeInsetsDirectional
                                                                    .fromSTEB(
                                                                        0,
                                                                        0,
                                                                        0,
                                                                        0),
                                                            child: Icon(
                                                              Icons
                                                                  .chevron_right_rounded,
                                                              color:
                                                                  Colors.white,
                                                              size: 35,
                                                            ),
                                                          ),
                                                          Padding(
                                                            padding:
                                                                EdgeInsetsDirectional
                                                                    .fromSTEB(
                                                                        0,
                                                                        0,
                                                                        0,
                                                                        2),
                                                            child: Text(
                                                              'Score  ${'${data![index]['score']}'}'
                                                                  .toUpperCase(),
                                                              textAlign:
                                                                  TextAlign.end,
                                                              style: TextStyle(
                                                                fontFamily:
                                                                    'Lexend Deca',
                                                                color: Colors
                                                                    .white,
                                                                fontSize: 14,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                              },
                            ),
                          );
                        },
                      )
                    : Builder(
                        builder: (BuildContext context) {
                          if (data == null || particularData == null) {
                            return Center(
                                child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: ColorScheme.fromSwatch()
                                          .copyWith(
                                              secondary: Color(0xFF063a73)),
                                    ),
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Color(0xFF063a73)),
                                      strokeWidth: 2,
                                      backgroundColor: Colors.white,
                                      //  valueColor: new AlwaysStoppedAnimation<Color>(color: Color(0xFF9B049B)),
                                    )),
                                SizedBox(
                                  height: 10,
                                ),
                                Text('Loading',
                                    style: TextStyle(
                                        color: Color(0xFF333333),
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ));
                          } else if (data!.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.all(40.0),
                              child: Text(
                                "No Game Play Yet!",
                                style: TextStyle(fontSize: 25),
                              ),
                            );
                          }
                          return Expanded(
                            child: ListView.builder(
                              itemCount: data!.length,
                              itemBuilder: (BuildContext context, int index) {
                                return index == 0
                                    ? InkWell(
                                        onTap: () {
                                          if (data![index]["uid"] ==
                                              (user?.uid ?? 'demo_user')) {
                                            DateTime currentDate =
                                                DateTime.now();
                                            DateTime targetDate =
                                                dataProvider.formatStringDate(
                                                    data2![0]["date"]);

                                            if (currentDate
                                                    .isAfter(targetDate) ||
                                                currentDate.isAtSameMomentAs(
                                                    targetDate)) {
                                              print(
                                                  'Current date is greater than or equal to the target date.');
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (context) =>
                                                        PickedWidget(
                                                            userId: data![index]
                                                                ["uid"],
                                                            selectedValue:
                                                                selectedValue)
                                                    // Picks(userId:data["uid"], selectedValue:selectedValue),
                                                    ),
                                              );
                                            } else {
                                              print(
                                                  'Current date is before the target date.');
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (context) =>
                                                        EditPlayWidget()
                                                    // Picks(userId:data["uid"], selectedValue:selectedValue),
                                                    ),
                                              );
                                            }
                                          } else {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      PickedWidget(
                                                          userId: data![index]
                                                              ["uid"],
                                                          selectedValue:
                                                              selectedValue)
                                                  // Picks(userId:data["uid"], selectedValue:selectedValue),
                                                  ),
                                            );
                                          }
                                        },
                                        child: Column(
                                          children: [
                                            Padding(
                                              padding: EdgeInsetsDirectional
                                                  .fromSTEB(10, 0, 10, 10),
                                              child: Container(
                                                width: MediaQuery.of(context)
                                                    .size
                                                    .width,
                                                height: 75,
                                                decoration: BoxDecoration(
                                                  color: normal_data![0]
                                                              ["uid"] ==
                                                          data![index]["uid"]
                                                      ? null
                                                      : Color(0xFF3474E0),
                                                  // remove winner background in demo/rows
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Color(0x411D2429),
                                                      offset: Offset(0, 1),
                                                    )
                                                  ],
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Padding(
                                                  padding: EdgeInsetsDirectional
                                                      .fromSTEB(8, 8, 8, 8),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.max,
                                                    children: [
                                                      Padding(
                                                        padding:
                                                            EdgeInsetsDirectional
                                                                .fromSTEB(15, 1,
                                                                    1, 1),
                                                        child: Container(
                                                          height: 50,
                                                          width: 50,
                                                          child: data![index]['photoURL']
                                                                          .toString() ==
                                                                      "" ||
                                                                  data![index][
                                                                          'photoURL'] ==
                                                                      null
                                                              ? Image.asset(
                                                                  "assets/images/user.png",
                                                                  fit: BoxFit
                                                                      .cover)
                                                              : Image.network(
                                                                  data![index][
                                                                          'photoURL']
                                                                      .toString(),
                                                                  fit: BoxFit
                                                                      .cover),
                                                        ),
                                                      ),
                                                      Expanded(
                                                        child: Padding(
                                                          padding:
                                                              EdgeInsetsDirectional
                                                                  .fromSTEB(14,
                                                                      8, 4, 0),
                                                          child: Column(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .max,
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .center,
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Row(
                                                                children: [
                                                                  Text(
                                                                    '${data![index]['displayName']}'
                                                                        .toUpperCase(),
                                                                    style:
                                                                        TextStyle(
                                                                      fontFamily:
                                                                          'Lexend Deca',
                                                                      color: Colors
                                                                          .white,
                                                                      fontSize: 16,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w500,
                                                                    ),
                                                                  ),
                                                                  if (data![index]["uid"] == (user?.uid ?? 'demo_user') && 
                                                                      DateTime.now().isBefore(dataProvider.formatStringDate(data2![0]["date"])))
                                                                    Container(
                                                                      margin: EdgeInsets.only(left: 8),
                                                                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                                      decoration: BoxDecoration(
                                                                        color: Colors.green.withOpacity(0.2),
                                                                        borderRadius: BorderRadius.circular(12),
                                                                        border: Border.all(color: Colors.green, width: 1),
                                                                      ),
                                                                      child: Row(
                                                                        mainAxisSize: MainAxisSize.min,
                                                                        children: [
                                                                          Icon(
                                                                            Icons.edit,
                                                                            color: Colors.green,
                                                                            size: 12,
                                                                          ),
                                                                          SizedBox(width: 4),
                                                                          Text(
                                                                            'Editable',
                                                                            style: TextStyle(
                                                                              color: Colors.green,
                                                                              fontSize: 12,
                                                                              fontWeight: FontWeight.w500,
                                                                            ),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    ),
                                                                ],
                                                              ),
                                                              Expanded(
                                                                child: Padding(
                                                                  padding: EdgeInsetsDirectional
                                                                      .fromSTEB(
                                                                          0,
                                                                          4,
                                                                          8,
                                                                          0),
                                                                  child:
                                                                      AutoSizeText(
                                                                    'week ${selectedValue}'
                                                                        .toUpperCase(),
                                                                    textAlign:
                                                                        TextAlign
                                                                            .start,
                                                                    style:
                                                                        TextStyle(
                                                                      fontFamily:
                                                                          'Lexend Deca',
                                                                      color: Colors
                                                                          .white,
                                                                      fontSize:
                                                                          13,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                      Column(
                                                        mainAxisSize:
                                                            MainAxisSize.max,
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween,
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .end,
                                                        children: [
                                                          Padding(
                                                            padding:
                                                                EdgeInsetsDirectional
                                                                    .fromSTEB(
                                                                        0,
                                                                        0,
                                                                        0,
                                                                        0),
                                                            child: Icon(
                                                              Icons
                                                                  .chevron_right_rounded,
                                                              color:
                                                                  Colors.white,
                                                              size: 35,
                                                            ),
                                                          ),
                                                          Padding(
                                                            padding:
                                                                EdgeInsetsDirectional
                                                                    .fromSTEB(
                                                                        0,
                                                                        0,
                                                                        0,
                                                                        2),
                                                            child: Text(
                                                              'Score  ${'${data![index]['score']}'}'
                                                                  .toUpperCase(),
                                                              textAlign:
                                                                  TextAlign.end,
                                                              style: TextStyle(
                                                                fontFamily:
                                                                    'Lexend Deca',
                                                                color: Colors
                                                                    .white,
                                                                fontSize: 14,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : index == 1
                                        ? normal_data![0]["uid"] == (user?.uid ?? 'demo_user')
                                            ? null
                                            : InkWell(
                                                onTap: () {
                                                  if (normal_data![0]["uid"] ==
                                                      (user?.uid ?? 'demo_user')) {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                          builder: (context) =>
                                                              EditPlayWidget()
                                                          // Picks(userId:data["uid"], selectedValue:selectedValue),
                                                          ),
                                                    );
                                                  } else {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                          builder: (context) =>
                                                              PickedWidget(
                                                                  userId:
                                                                      normal_data![
                                                                              0]
                                                                          [
                                                                          "uid"],
                                                                  selectedValue:
                                                                      selectedValue)
                                                          // Picks(userId:data["uid"], selectedValue:selectedValue),
                                                          ),
                                                    );
                                                  }
                                                },
                                                child: Column(
                                                  children: [
                                                    Padding(
                                                      padding:
                                                          EdgeInsetsDirectional
                                                              .fromSTEB(10, 0,
                                                                  10, 10),
                                                      child: Container(
                                                        width: MediaQuery.of(
                                                                context)
                                                            .size
                                                            .width,
                                                        height: 75,
                                                        decoration:
                                                            BoxDecoration(
                                                          boxShadow: [
                                                            BoxShadow(
                                                              color: Color(
                                                                  0x411D2429),
                                                              offset:
                                                                  Offset(0, 1),
                                                            )
                                                          ],
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(8),
                                                        ),
                                                        child: Stack(
                                                          children: [
                                                            Container(
                                                              width:
                                                                  MediaQuery.of(
                                                                          context)
                                                                      .size
                                                                      .width,
                                                              height: 75,
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: Colors
                                                                    .white10,
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            8),
                                                              ),
                                                              child: Text(""),
                                                            ),
                                                            Padding(
                                                              padding:
                                                                  EdgeInsetsDirectional
                                                                      .fromSTEB(
                                                                          8,
                                                                          8,
                                                                          8,
                                                                          8),
                                                              child: Row(
                                                                mainAxisSize:
                                                                    MainAxisSize
                                                                        .max,
                                                                children: [
                                                                  Padding(
                                                                    padding: EdgeInsetsDirectional
                                                                        .fromSTEB(
                                                                            15,
                                                                            1,
                                                                            1,
                                                                            1),
                                                                    child:
                                                                        Container(
                                                                      height:
                                                                          50,
                                                                      width: 50,
                                                                      child: normal_data![0]['photoURL'].toString() == "" ||
                                                                              normal_data![0]['photoURL'] ==
                                                                                  null
                                                                          ? Image.asset(
                                                                              "assets/images/user.png",
                                                                              fit: BoxFit
                                                                                  .cover)
                                                                          : Image.network(
                                                                              normal_data![0]['photoURL'].toString(),
                                                                              fit: BoxFit.cover),
                                                                    ),
                                                                  ),
                                                                  Expanded(
                                                                    child:
                                                                        Padding(
                                                                      padding: EdgeInsetsDirectional
                                                                          .fromSTEB(
                                                                              14,
                                                                              8,
                                                                              4,
                                                                              0),
                                                                      child:
                                                                          Column(
                                                                        mainAxisSize:
                                                                            MainAxisSize.max,
                                                                        mainAxisAlignment:
                                                                            MainAxisAlignment.center,
                                                                        crossAxisAlignment:
                                                                            CrossAxisAlignment.start,
                                                                        children: [
                                                                          Text(
                                                                            '${normal_data![0]['displayName']}'.toUpperCase(),
                                                                            style:
                                                                                TextStyle(
                                                                              fontFamily: 'Lexend Deca',
                                                                              color: Colors.white,
                                                                              fontSize: 16,
                                                                              fontWeight: FontWeight.w500,
                                                                            ),
                                                                          ),
                                                                          Expanded(
                                                                            child:
                                                                                Padding(
                                                                              padding: EdgeInsetsDirectional.fromSTEB(0, 4, 8, 0),
                                                                              child: AutoSizeText(
                                                                                'week ${selectedValue}'.toUpperCase(),
                                                                                textAlign: TextAlign.start,
                                                                                style: TextStyle(
                                                                                  fontFamily: 'Lexend Deca',
                                                                                  color: Colors.white,
                                                                                  fontSize: 13,
                                                                                  fontWeight: FontWeight.bold,
                                                                                ),
                                                                              ),
                                                                            ),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  Column(
                                                                    mainAxisSize:
                                                                        MainAxisSize
                                                                            .max,
                                                                    mainAxisAlignment:
                                                                        MainAxisAlignment
                                                                            .spaceBetween,
                                                                    crossAxisAlignment:
                                                                        CrossAxisAlignment
                                                                            .end,
                                                                    children: [
                                                                      Padding(
                                                                        padding: EdgeInsetsDirectional.fromSTEB(
                                                                            0,
                                                                            0,
                                                                            0,
                                                                            0),
                                                                        child:
                                                                            Icon(
                                                                          Icons
                                                                              .chevron_right_rounded,
                                                                          color:
                                                                              Colors.white,
                                                                          size:
                                                                              35,
                                                                        ),
                                                                      ),
                                                                      Padding(
                                                                        padding: EdgeInsetsDirectional.fromSTEB(
                                                                            0,
                                                                            0,
                                                                            0,
                                                                            2),
                                                                        child:
                                                                            Text(
                                                                          'Score  ${'${normal_data![0]['score']}'}'
                                                                              .toUpperCase(),
                                                                          textAlign:
                                                                              TextAlign.end,
                                                                          style:
                                                                              TextStyle(
                                                                            fontFamily:
                                                                                'Lexend Deca',
                                                                            color:
                                                                                Colors.white,
                                                                            fontSize:
                                                                                14,
                                                                            fontWeight:
                                                                                FontWeight.w500,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ],
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
                                              )
                                        : InkWell(
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (context) =>
                                                        PickedWidget(
                                                            userId: data![index]
                                                                ["uid"],
                                                            selectedValue:
                                                                selectedValue)
                                                    // Picks(userId:data["uid"], selectedValue:selectedValue),
                                                    ),
                                              );
                                            },
                                            child: Column(
                                              children: [
                                                Padding(
                                                  padding: EdgeInsetsDirectional
                                                      .fromSTEB(10, 0, 10, 10),
                                                  child: Container(
                                                    width:
                                                        MediaQuery.of(context)
                                                            .size
                                                            .width,
                                                    height: 75,
                                                    decoration: BoxDecoration(
                                                      color: Color(0xFF3474E0),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color:
                                                              Color(0x411D2429),
                                                          offset: Offset(0, 1),
                                                        )
                                                      ],
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                    ),
                                                    child: Padding(
                                                      padding:
                                                          EdgeInsetsDirectional
                                                              .fromSTEB(
                                                                  8, 8, 8, 8),
                                                      child: Row(
                                                        mainAxisSize:
                                                            MainAxisSize.max,
                                                        children: [
                                                          Padding(
                                                            padding:
                                                                EdgeInsetsDirectional
                                                                    .fromSTEB(15, 1,
                                                                        1, 1),
                                                            child: Container(
                                                              height: 50,
                                                              width: 50,
                                                              child: data![index]['photoURL']
                                                                              .toString() ==
                                                                          "" ||
                                                                      data![index]
                                                                              [
                                                                              'photoURL'] ==
                                                                          null
                                                                  ? Image.asset(
                                                                      "assets/images/user.png",
                                                                      fit: BoxFit
                                                                          .cover)
                                                                  : Image.network(
                                                                      data![index]['photoURL']
                                                                          .toString(),
                                                                      fit: BoxFit
                                                                          .cover),
                                                            ),
                                                          ),
                                                          Expanded(
                                                            child: Padding(
                                                              padding:
                                                                  EdgeInsetsDirectional
                                                                      .fromSTEB(14,
                                                                          8,
                                                                          4,
                                                                          0),
                                                              child: Column(
                                                                mainAxisSize:
                                                                    MainAxisSize
                                                                        .max,
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .center,
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .start,
                                                                children: [
                                                                  Text(
                                                                    '${data![index]['displayName']}'
                                                                        .toUpperCase(),
                                                                    style:
                                                                        TextStyle(
                                                                      fontFamily:
                                                                          'Lexend Deca',
                                                                      color: Colors
                                                                          .white,
                                                                      fontSize: 16,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w500,
                                                                    ),
                                                                  ),
                                                                  Expanded(
                                                                    child:
                                                                        Padding(
                                                                      padding: EdgeInsetsDirectional
                                                                          .fromSTEB(
                                                                              0,
                                                                              4,
                                                                              8,
                                                                              0),
                                                                      child:
                                                                          AutoSizeText(
                                                                        'week ${selectedValue}'
                                                                            .toUpperCase(),
                                                                        textAlign:
                                                                            TextAlign.start,
                                                                        style:
                                                                            TextStyle(
                                                                          fontFamily:
                                                                              'Lexend Deca',
                                                                          color: Colors
                                                                              .white,
                                                                          fontSize:
                                                                              13,
                                                                          fontWeight:
                                                                              FontWeight.bold,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ),
                                                          Column(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .max,
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .spaceBetween,
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .end,
                                                            children: [
                                                              Padding(
                                                                padding:
                                                                    EdgeInsetsDirectional
                                                                        .fromSTEB(
                                                                            0,
                                                                            0,
                                                                            0,
                                                                            0),
                                                                child: Icon(
                                                                  Icons
                                                                      .chevron_right_rounded,
                                                                  color: Colors
                                                                      .white,
                                                                  size: 35,
                                                                ),
                                                              ),
                                                              Padding(
                                                                padding:
                                                                    EdgeInsetsDirectional
                                                                        .fromSTEB(
                                                                            0,
                                                                            0,
                                                                            0,
                                                                            2),
                                                                child: Text(
                                                                  'Score  ${'${data![index]['score']}'}'
                                                                      .toUpperCase(),
                                                                  textAlign:
                                                                      TextAlign
                                                                          .end,
                                                                  style:
                                                                      TextStyle(
                                                                    fontFamily:
                                                                        'Lexend Deca',
                                                                    color: Colors
                                                                        .white,
                                                                    fontSize:
                                                                        14,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w500,
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                              },
                            ),
                          );
                        },
                      )
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showPicker(BuildContext ctx) {
    // var utils = Provider.of<Utils>(context, listen: false);
    showCupertinoModalPopup(
        barrierDismissible: false,
        context: ctx,
        builder: (_) => ClipRRect(
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(16),
                topLeft: Radius.circular(16),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    height: 20,
                    width: MediaQuery.of(context).size.width,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(16),
                          topLeft: Radius.circular(16),
                        )),
                    child: Center(
                      child: Container(
                        margin: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.all(
                              Radius.circular(16),
                            )),
                        width: 100,
                        height: 15,
                      ),
                    ),
                  ),
                  Material(
                    child: Container(
                      color: Colors.white,
                      width: MediaQuery.of(context).size.width,
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Text(
                          "Select Week",
                          style: TextStyle(fontSize: 18, color: Colors.black87),
                          textAlign: TextAlign.start,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.only(
                      topRight: Radius.circular(16),
                      topLeft: Radius.circular(16),
                    )),
                    width: MediaQuery.of(context).size.width,
                    height: 150,
                    child: CupertinoPicker(
                      backgroundColor: Colors.white,
                      itemExtent: 30,
                      scrollController: FixedExtentScrollController(
                          initialItem:
                              (int.parse(selectedValue.toString()) - 1)),
                      children: [
                        Text('Week 1'),
                        Text('Week 2'),
                        Text('Week 3'),
                        Text('Week 4'),
                        Text('Week 5'),
                        Text('Week 6'),
                        Text('Week 7'),
                        Text('Week 8'),
                        Text('Week 9'),
                        Text('Week 10'),
                        Text('Week 11'),
                        Text('Week 12'),
                        Text('Week 13'),
                        Text('Week 14'),
                        Text('Week 15'),
                        Text('Week 16'),
                        Text('Week 17'),
                        Text('Week 18'),
                      ],
                      onSelectedItemChanged: (value) {
                        List<String> busStop = [
                          '1',
                          '2',
                          '3',
                          '5',
                          '6',
                          '7',
                          '8',
                          '9',
                          '10',
                          '11',
                          '12',
                          '13',
                          '14',
                          '15',
                          '16',
                          '17',
                        ];
                        setState(() {
                          selectedValue = busStop[value] as String;
                        });
                      },
                    ),
                  ),
                  Container(
                    color: Colors.white,
                    width: MediaQuery.of(context).size.width,
                    height: 34,
                    child: Align(
                      alignment: Alignment.bottomRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          setState(() {
                            data = null;
                          });
                          getLeaderBoard(context, selectedValue);
                          getGame(context, selectedValue);
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5)),
                          padding: EdgeInsets.all(0.0),
                        ),
                        child: Ink(
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(5)),
                          child: Container(
                            constraints:
                                BoxConstraints(maxWidth: 100, minHeight: 34.0),
                            alignment: Alignment.center,
                            child: Text(
                              "Done",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ));
  }

  void _showPicker2(BuildContext ctx) {
    // var utils = Provider.of<Utils>(context, listen: false);
    showCupertinoModalPopup(
        barrierDismissible: false,
        context: ctx,
        builder: (_) => ClipRRect(
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(16),
                topLeft: Radius.circular(16),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    height: 20,
                    width: MediaQuery.of(context).size.width,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(16),
                          topLeft: Radius.circular(16),
                        )),
                    child: Center(
                      child: Container(
                        margin: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.all(
                              Radius.circular(16),
                            )),
                        width: 100,
                        height: 15,
                      ),
                    ),
                  ),
                  Material(
                    child: Container(
                      color: Colors.white,
                      width: MediaQuery.of(context).size.width,
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Text(
                          "Select Preseason",
                          style: TextStyle(fontSize: 18, color: Colors.black87),
                          textAlign: TextAlign.start,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.only(
                      topRight: Radius.circular(16),
                      topLeft: Radius.circular(16),
                    )),
                    width: MediaQuery.of(context).size.width,
                    height: 150,
                    child: CupertinoPicker(
                      backgroundColor: Colors.white,
                      itemExtent: 30,
                      scrollController: FixedExtentScrollController(
                          initialItem:
                              (int.parse(selectedValue.toString()) - 1)),
                      children: [
                        Text('Preseason 1'),
                        Text('Preseason 2'),
                        Text('Preseason 3'),
                        Text('Preseason 4'),
                        Text('Preseason 5'),
                        Text('Preseason 6'),
                        Text('Preseason 7'),
                        Text('Preseason 8'),
                        Text('Preseason 9'),
                        Text('Preseason 10'),
                      ],
                      onSelectedItemChanged: (value) {
                        List<String> busStop = [
                          '1',
                          '2',
                          '3',
                          '5',
                          '6',
                          '7',
                          '8',
                          '9',
                          '10',
                        ];
                        setState(() {
                          selectedValue = busStop[value] as String;
                        });
                      },
                    ),
                  ),
                  Container(
                    color: Colors.white,
                    width: MediaQuery.of(context).size.width,
                    height: 34,
                    child: Align(
                      alignment: Alignment.bottomRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          setState(() {
                            data = null;
                          });
                          getLeaderBoard(context, selectedValue);
                          getGame(context, selectedValue);
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5)),
                          padding: EdgeInsets.all(0.0),
                        ),
                        child: Ink(
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(5)),
                          child: Container(
                            constraints:
                                BoxConstraints(maxWidth: 100, minHeight: 34.0),
                            alignment: Alignment.center,
                            child: Text(
                              "Done",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ));
  }
}
