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
import 'package:poolqapp/Module/Screen/Home/picks.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:poolqapp/Module/Screen/Home/picked.dart';
//import 'package:admob_flutter/admob_flutter.dart';
// import '/flutter_flow/flutter_flow_theme.dart';
// import '/flutter_flow/flutter_flow_util.dart';

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
              child: Text(""),
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              decoration: BoxDecoration(color: Colors.white54),
            ),
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(0, 20, 0, 0),
              child: SingleChildScrollView(
                physics: BouncingScrollPhysics(),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            icon: Icon(Icons.arrow_back_ios_new)),
                        Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(0, 20, 25, 0),
                          child: Image.asset(
                            'assets/images/poolq12.png',
                            width: 67,
                            height: 90,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Text("")
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 15.0, bottom: 15),
                      child: Text(
                        "GAMEPLAY RULES",
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(
                        """
Game Rules:

Each week constitutes a new pool. You may play as many or as few weeks as you like but you are allowed only one entry per week. Each entry costs \$5.00 which goes into the pot paid to that week's winner(s).

To enter, fill in the entry form by making your pick for each game. The goal is to pick the winning team.

You will also be asked to guess the total points scored in the Monday Night Football game (or whatever the last scheduled game of that week is). This will be used as a tiebreaker.

The winner for each week will be the player with the highest score. In the event of a tie, the player who guessed closest to the actual point total of the tiebreaker game without exceeding it will win. Should any players still be tied after applying the tiebreaker, the pot will be divided equally among those players.

Scoring: 

Each game picked correctly is awarded 1 point.

Deadline:  

The deadline  is the scheduled kickoff for the first game of the week.  Once the picks are submitted there are no changes permitted and no refunds.
                              """,
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w400),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
