import 'LeaderbpardWidget.dart';
import 'package:flutter/material.dart';
import '../../../constants.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:poolqapp/Widget/reuse.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:poolqapp/Provider/homeProvider.dart';
import 'package:poolqapp/Provider/AuthProviders.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:poolqapp/services/nfl_schedule_service.dart';
//import 'package:admob_flutter/admob_flutter.dart';

class Picks extends StatefulWidget {
  const Picks({this.userId, this.selectedValue});

  final String? userId;
  final String? selectedValue;

  @override
  _PickstState createState() => _PickstState();
}

class _PickstState extends State<Picks> {
  // late PlayerPicksModel _model;
  User? user = FirebaseAuth.instance.currentUser;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final _unfocusNode = FocusNode();
  late final Stream<QuerySnapshot>? _pickrecordStream;
  List<QueryDocumentSnapshot>? data;

  @override
  void initState() {
    super.initState();
    DataProvider dataProvider =
        Provider.of<DataProvider>(context, listen: false);
    _pickrecordStream = FirebaseFirestore.instance
        .collection('pickrecord')
        .where("week",
            isEqualTo: "${dataProvider.game!["mode"]}${widget.selectedValue}")
        .where("uid", isEqualTo: "${widget.userId}")
        .snapshots();
    // Fetch and update the latest schedule for the selected week
    _fetchLatestSchedule();
    // _model = createModel(context, () => PlayerPicksModel());
  }

  Future<void> _fetchLatestSchedule() async {
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    final scheduleService = NFLScheduleService();
    final weekName = "${dataProvider.game!["mode"]}${widget.selectedValue}";
    final games = await scheduleService.getScheduleForWeekWithLocalFallback(weekName);
    if (games.isNotEmpty) {
      setState(() {
        dataProvider.data = games;
      });
    }
  }

  @override
  void dispose() {
    // _model.dispose();

    _unfocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    DataProvider dataProvider = Provider.of<DataProvider>(context);
    AuthProviders authProvider =
        Provider.of<AuthProviders>(context, listen: true);
    // context.watch<FFAppState>();

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
        appBar: AppBar(
          backgroundColor: primary,
          automaticallyImplyLeading: true,
          actions: [],
          centerTitle: true,
          elevation: 4,
        ),
        body: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            Container(
              padding: EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/poolq12.png',
                    width: 100,
                    height: 120,
                    fit: BoxFit.contain,
                  ),
                  SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Leaderboard',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      Text(
                        'Week ${widget.selectedValue}',
                        style: GoogleFonts.poppins(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: Consumer<DataProvider>(
                builder: (context, dataProvider, _) {
                  final scheduleData = dataProvider.data ?? [];
                  final playerPicks = dataProvider.playerPicks ?? [];
                  if (scheduleData.isEmpty) {
                    return Center(child: Text('No schedule data available'));
                  }
                  return ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: scheduleData.length,
                    itemBuilder: (context, index) {
                      final game = scheduleData[index];
                      // Use the local data field names directly to ensure correct team logos
                      final homeAbbr = game['abbreviation'] ?? '';
                      final awayAbbr = game['abbreviation2'] ?? '';
                      final homeName = game['fullname'] ?? game['home'] ?? '';
                      final awayName = game['fullname2'] ?? game['away'] ?? '';
                      
                      // Fallback: If abbreviations are the same or empty, derive from team names
                      final finalHomeAbbr = (homeAbbr == awayAbbr || homeAbbr.isEmpty) && homeName.isNotEmpty 
                          ? _deriveAbbreviationFromName(homeName) 
                          : homeAbbr;
                      final finalAwayAbbr = (homeAbbr == awayAbbr || awayAbbr.isEmpty) && awayName.isNotEmpty 
                          ? _deriveAbbreviationFromName(awayName) 
                          : awayAbbr;
                      
                      // Debug: Print the actual game data to see what we're working with
                      print('Game ${index + 1} Debug:');
                      print('  homeName: $homeName');
                      print('  awayName: $awayName');
                      print('  abbreviation: ${game['abbreviation']}');
                      print('  abbreviation2: ${game['abbreviation2']}');
                      print('  homeAbbr: $homeAbbr');
                      print('  awayAbbr: $awayAbbr');
                      print('  finalHomeAbbr: $finalHomeAbbr');
                      print('  finalAwayAbbr: $finalAwayAbbr');
                      print('  Raw game data keys: ${game.keys.toList()}');
                      print('  Raw game data: $game');
                      
                      final homePicked = playerPicks.contains(finalHomeAbbr);
                      final awayPicked = playerPicks.contains(finalAwayAbbr);
                      return Card(
                        elevation: 2,
                        margin: EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white,
                                Colors.grey.shade50,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Game ${index + 1}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: textPrimary,
                                      ),
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        game['gameTime'] ?? 'TBD',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          color: primary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        children: [
                                          Container(
                                            padding: EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.1),
                                                  blurRadius: 4,
                                                  offset: Offset(0, 2),
                                                ),
                                              ],
                                              border: homePicked
                                                  ? Border.all(color: Colors.green, width: 4)
                                                  : null,
                                            ),
                                            child: TeamLogo(
                                              abbr: finalHomeAbbr,
                                              size: 80,
                                            ),
                                          ),
                                          SizedBox(height: 12),
                                          Text(
                                            homeName.isNotEmpty ? homeName : finalHomeAbbr,
                                            style: GoogleFonts.poppins(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: primary.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        'VS',
                                        style: GoogleFonts.poppins(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: primary,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Column(
                                        children: [
                                          Container(
                                            padding: EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.1),
                                                  blurRadius: 4,
                                                  offset: Offset(0, 2),
                                                ),
                                              ],
                                              border: awayPicked
                                                  ? Border.all(color: Colors.green, width: 4)
                                                  : null,
                                            ),
                                            child: TeamLogo(
                                              abbr: finalAwayAbbr,
                                              size: 80,
                                            ),
                                          ),
                                          SizedBox(height: 12),
                                          Text(
                                            awayName.isNotEmpty ? awayName : finalAwayAbbr,
                                            style: GoogleFonts.poppins(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 16),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        color: primary,
                                        size: 20,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Picked: ${playerPicks.contains(finalHomeAbbr) ? finalHomeAbbr : playerPicks.contains(finalAwayAbbr) ? finalAwayAbbr : 'Not picked'}',
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            if (data != null && data!.isNotEmpty)
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tiebreaker',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.timer,
                            color: primary,
                            size: 24,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total Points Prediction',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: textPrimary,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  '${data![0]['tiebreaker'] ?? 'Not set'} points',
                                  style: GoogleFonts.poppins(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _deriveAbbreviationFromName(String name) {
    final teamNameToAbbr = {
      'Philadelphia Eagles': 'PHI',
      'Dallas Cowboys': 'DAL',
      'Los Angeles Chargers': 'LAC',
      'Kansas City Chiefs': 'KC',
      'Atlanta Falcons': 'ATL',
      'Tampa Bay Buccaneers': 'TB',
      'Cleveland Browns': 'CLE',
      'Cincinnati Bengals': 'CIN',
      'Indianapolis Colts': 'IND',
      'Miami Dolphins': 'MIA',
      'New England Patriots': 'NE',
      'Las Vegas Raiders': 'LV',
      'New Orleans Saints': 'NO',
      'Arizona Cardinals': 'ARI',
      'New York Jets': 'NYJ',
      'Pittsburgh Steelers': 'PIT',
      'Washington Commanders': 'WAS',
      'New York Giants': 'NYG',
      'Jacksonville Jaguars': 'JAX',
      'Carolina Panthers': 'CAR',
      'Denver Broncos': 'DEN',
      'Tennessee Titans': 'TEN',
      'Seattle Seahawks': 'SEA',
      'San Francisco 49ers': 'SF',
      'Detroit Lions': 'DET',
      'Buffalo Bills': 'BUF',
      'Baltimore Ravens': 'BAL',
      'Chicago Bears': 'CHI',
      'Green Bay Packers': 'GB',
      'Houston Texans': 'HOU',
      'Minnesota Vikings': 'MIN',
      'Los Angeles Rams': 'LAR',
    };
    return teamNameToAbbr[name] ?? name.substring(0, 3).toUpperCase();
  }
}
