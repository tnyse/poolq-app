import 'games.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:poolqapp/Provider/homeProvider.dart';
import 'package:poolqapp/Provider/AuthProviders.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:poolqapp/Module/Screen/Home/picked.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../Constants/value.dart';
//import 'package:admob_flutter/admob_flutter.dart';
// import '/flutter_flow/flutter_flow_theme.dart';
// import '/flutter_flow/flutter_flow_util.dart';

// Color constants
// const Color primary = Color(0xFF1A237E);
// const Color textPrimary = Color(0xFF212121);
// const Color textSecondary = Color(0xFF757575);

//
// import 'leaderboard_model.dart';
// export 'leaderboard_model.dart';

class RulesWidget extends StatefulWidget {
  const RulesWidget({Key? key}) : super(key: key);

  @override
  _RulesWidgetState createState() => _RulesWidgetState();
}

class _RulesWidgetState extends State<RulesWidget> {
  // late LeaderboardModel _model;
  User? user = FirebaseAuth.instance.currentUser;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final _unfocusNode = FocusNode();
  final Stream<QuerySnapshot> _leaderboard_recordStream =
      FirebaseFirestore.instance.collection('leaderboard_record').snapshots();

  List? data;

  Future getLeaderBoard(context, selectedValue) async {
    DataProvider dataProvider =
        Provider.of<DataProvider>(context, listen: false);
    print(
        '${mainUrl}/getleaderboard/${dataProvider.game!["mode"]}${selectedValue}');
    var response = await http.get(
        Uri.parse(
            '${mainUrl}/getleaderboard/${dataProvider.game!["mode"]}${selectedValue}'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Access-Control-Allow-Origin': '*',
        }).timeout(Duration(seconds: 20));
    var body = json.decode(response.body);
    // print(body);
    // print(body);
    List body1 = body;
    setState(() {
      data = body1;
    });
    return body;
  }

  String? selectedValue;

  @override
  void initState() {
    super.initState();
    DataProvider dataProvider =
        Provider.of<DataProvider>(context, listen: false);
    selectedValue = dataProvider.game!["name"]
        .toString()
        .replaceAll("REG", "")
        .replaceAll("PRE", "");
    getLeaderBoard(context, selectedValue);
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
    // context.watch<FFAppState>();
    DataProvider dataProvider =
        Provider.of<DataProvider>(context, listen: true);
    AuthProviders authProvider =
        Provider.of<AuthProviders>(context, listen: true);

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
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                image: DecorationImage(
                  image: AssetImage('assets/images/pattern.png'),
                  repeat: ImageRepeat.repeat,
                  opacity: 0.05,
                ),
              ),
            ),
            SafeArea(
              child: SingleChildScrollView(
                physics: BouncingScrollPhysics(),
                child: Column(
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
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(Icons.arrow_back_ios_new),
                            color: textPrimary,
                          ),
                          Image.asset(
                            'assets/images/poolq12.png',
                            width: 100,
                            height: 120,
                            fit: BoxFit.contain,
                          ),
                          SizedBox(width: 16),
                          Text(
                            "RULES",
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "GAMEPLAY RULES",
                            style: GoogleFonts.poppins(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: primary,
                            ),
                          ),
                          SizedBox(height: 24),
                          _buildRuleSection(
                            title: "Weekly Pools",
                            content: "Each week constitutes a new pool. You may play as many or as few weeks as you like but you are allowed only one entry per week. Each entry costs \$5.00 which goes into the pot paid to that week's winner(s).",
                            icon: Icons.calendar_today,
                          ),
                          SizedBox(height: 16),
                          _buildRuleSection(
                            title: "Making Picks",
                            content: "To enter, fill in the entry form by making your pick for each game. The goal is to pick the winning team.",
                            icon: Icons.sports_football,
                          ),
                          SizedBox(height: 16),
                          _buildRuleSection(
                            title: "Tiebreaker",
                            content: "You will also be asked to guess the total points scored in the Monday Night Football game (or whatever the last scheduled game of that week is). This will be used as a tiebreaker.",
                            icon: Icons.timer,
                          ),
                          SizedBox(height: 16),
                          _buildRuleSection(
                            title: "Winning",
                            content: "The winner for each week will be the player with the highest score. In the event of a tie, the player who guessed closest to the actual point total of the tiebreaker game without exceeding it will win. Should any players still be tied after applying the tiebreaker, the pot will be divided equally among those players.",
                            icon: Icons.emoji_events,
                          ),
                          SizedBox(height: 16),
                          _buildRuleSection(
                            title: "Scoring",
                            content: "Each game picked correctly is awarded 1 point.",
                            icon: Icons.scoreboard,
                          ),
                          SizedBox(height: 16),
                          _buildRuleSection(
                            title: "Deadline",
                            content: "The deadline is the scheduled kickoff for the first game of the week. Once the picks are submitted there are no changes permitted and no refunds.",
                            icon: Icons.access_time,
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
      ),
    );
  }

  Widget _buildRuleSection({
    required String title,
    required String content,
    required IconData icon,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: primary,
              size: 24,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  content,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    height: 1.5,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
