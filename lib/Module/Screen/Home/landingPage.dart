import 'Play.dart';
import 'EditPlay.dart';
import 'dart:convert';
import '../Auth/Forget.dart';
import '../Auth/Signup.dart';
import '../../../Widget/reuse.dart';
import 'package:flutter/material.dart';
import '../../../constants.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../../Widget/countDown.dart';
import 'package:poolqapp/Model/games.dart';
import '../../../Provider/homeProvider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:poolqapp/Provider/AuthProviders.dart';
import 'package:poolqapp/Module/Screen/Home/LeaderbpardWidget.dart';
import '../../../services/nfl_schedule_service.dart';
import 'PlayerPickWidget.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:poolqapp/constants.dart';

// import '/auth/firebase_auth/auth_util.dart';
//import 'package:admob_flutter/admob_flutter.dart';

class HomePageWidget extends StatefulWidget {
  PageController? controller;
  bool? isEmpty;

  HomePageWidget({required this.controller, this.isEmpty});

  @override
  _HomePageWidgetState createState() => _HomePageWidgetState();
}

class _HomePageWidgetState extends State<HomePageWidget> {
  // late HomePageModel _model;
  User? user = FirebaseAuth.instance.currentUser;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  List<GamesModel>? data;

  Future getGame(context) async {
    DataProvider dataProvider = Provider.of<DataProvider>(context, listen: false);
    final scheduleService = NFLScheduleService();
    
    try {
      print('Fetching games for home page from multiple sources...');
      
      // Only use local file for schedule display
      List<Map<String, dynamic>> games = await scheduleService.getScheduleForWeekWithLocalFallback(
        dataProvider.game!["name"]
      );
      if (games.isNotEmpty) {
        setState(() {
          data = games.map((g) => GamesModel.fromJson(g)).toList();
        });
        print('Loaded ${data!.length} games from local file');
        return games;
      } else {
        throw Exception('No games data available from local file');
      }
      
    } catch (e) {
      print('Error fetching games for home page: $e');
      // Provide fallback mock data
      setState(() {
        data = [];
      });
    }
  }

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      DataProvider dataProvider =
          Provider.of<DataProvider>(context, listen: false);
      if (dataProvider.game == null) {
        print("dd");
      } else {
        print("zz");
        getGame(context);
      }
      // check(); // BYPASSED FOR TESTING - REMEMBER TO RE-ENABLE FOR PRODUCTION
    });
    super.initState();

    // _model = createModel(context, () => HomePageModel());
  }

  // BYPASSED FOR TESTING - REMEMBER TO RE-ENABLE FOR PRODUCTION
  void check() {
    // if (!user!.emailVerified) {
    //   Navigator.pushAndRemoveUntil(
    //     context,
    //     MaterialPageRoute(
    //       builder: (context) => ForgetWidget(),
    //     ),
    //     (r) => false,
    //   );
    // }
  }

  @override
  void dispose() {
    // _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // context.watch<FFAppState>();
    DataProvider dataProvider =
        Provider.of<DataProvider>(context, listen: true);

    return Scaffold(
      // bottomNavigationBar: Container(
      //     color: Colors.white,
      //     child: AdmobBanner(
      //       adUnitId: Provider.of<DataProvider>(context, listen: false)
      //           .getBannerAdUnitId().toString(),
      //       adSize: AdmobBannerSize.BANNER,
      //       listener: (AdmobAdEvent event, Map<String, dynamic> ?args) {},
      //     )),
      key: scaffoldKey,
      backgroundColor: Color(0xFFF5F5F5),
      body: Stack(
        children: [
          Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height * 1,
            decoration: BoxDecoration(
              color: Color(0x90FFFFFF),
            ),
            child: Align(
              alignment: AlignmentDirectional(0, 0),
              child: Image.asset(
                'assets/images/gb.jpeg',
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height * 1,
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(
            child: Text(""),
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            decoration: BoxDecoration(color: Colors.white38),
          ),
          Align(
            alignment: AlignmentDirectional(0, -0.9),
            child: Text(
              'POOL Q',
              style: TextStyle(
                fontFamily: 'Poppins',
                color: Colors.white,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 20.0, right: 20),
            child: Align(
              alignment: Alignment.topRight,
              child: IconButton(
                onPressed: () async {
                  FirebaseAuth auth = FirebaseAuth.instance;
                  await auth.signOut();
                  Navigator.pushAndRemoveUntil(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) {
                        return RegisterWidget();
                      },
                      transitionsBuilder:
                          (context, animation, secondaryAnimation, child) {
                        return FadeTransition(
                          opacity: animation,
                          child: child,
                        );
                      },
                    ),
                    (route) => false,
                  );
                },
                icon: Icon(
                  Icons.logout,
                  size: 30,
                  color: Color.fromRGBO(6, 58, 115, 1),
                ),
              ),
            ),
          ),
          Padding(
            padding:
                EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.1),
            child: Align(
              alignment: Alignment.topCenter,
              child: Image.asset(
                'assets/images/poolq12.png',
                width: 200,
                height: 300,
                fit: BoxFit.contain,
              ),
            ),
          ),
          Align(
            alignment: AlignmentDirectional(0, 0),
            child: Padding(
              padding: EdgeInsetsDirectional.fromSTEB(
                  0, 0, 0, MediaQuery.of(context).size.height * 0.21),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(0, 0, 10, 10),
                    child: Align(
                        alignment: AlignmentDirectional(0, 0.58),
                        child: SizedBox(
                          width: 150,
                          height: 40,
                          child: TextButton(
                            onPressed: () async {
                              if (dataProvider.data == null ||
                                  dataProvider.game == null) {
                                customSnackbar(context, 'loading games');
                              } else {
                                // Navigate to EditPlayWidget for entry form (same as leaderboard Play Now)
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditPlayWidget(),
                                  ),
                                );
                              }
                            },
                            child: Text(
                              'Let\'s Play!',
                              style: TextStyle(color: Colors.white),
                            ),
                            style: ButtonStyle(
                              elevation: MaterialStateProperty.all<double>(2),
                              shape: MaterialStateProperty.all<
                                      RoundedRectangleBorder>(
                                  RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30.0),
                                      side: BorderSide(
                                        color: Colors.transparent,
                                        width: 1,
                                      ))),
                              backgroundColor:
                                  MaterialStateProperty.all<Color>(primary),
                              textStyle: MaterialStateProperty.all<TextStyle>(
                                  TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ),
                        )),
                  ),
                  widget.isEmpty == true
                      ? Text(
                          "Enter your picks for this week prior to the deadline",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        )
                      : Container(),
                ],
              ),
            ),
          ),
          dataProvider.data == null || dataProvider.game == null
              ? Container()
              : Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    height: 55,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(3.0),
                          child: Center(
                              child: Text(
                            "ENTRY DEADLINE: "+
                              (dataProvider.data != null && dataProvider.data!.isNotEmpty
                                ? (dataProvider.data![0] is String
                                    ? dataProvider.data![0]
                                    : (dataProvider.data![0]['date'] ?? ''))
                                : ''),
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          )),
                        ),
                        // Text("${dataProvider.formatStringDate(dataProvider.data?[0]!)}")
                        Padding(
                          padding: const EdgeInsets.all(2.0),
                          child: CountdownTimerDemo(
                            dataProvider.formatStringDate(
                              dataProvider.data != null && dataProvider.data!.isNotEmpty
                                ? (dataProvider.data![0] is String
                                    ? dataProvider.data![0]
                                    : (dataProvider.data![0]['date'] ?? ''))
                                : ''
                            ),
                          ),
                        )
                      ],
                    ),
                    color: primary,
                  ),
                ),
          dataProvider.data == null || dataProvider.game == null
              ? Center(
                  child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: ColorScheme.fromSwatch()
                              .copyWith(secondary: Color(0xFF063a73)),
                        ),
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Color(0xFF063a73)),
                          strokeWidth: 2,
                          backgroundColor: Colors.white,
                          //  valueColor: new AlwaysStoppedAnimation<Color>(color: Color(0xFF9B049B)),
                        )),
                    SizedBox(
                      height: 10,
                    ),
                    Text('Loading',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600)),
                  ],
                ))
              : Container()
        ],
      ),
    );
  }
}
