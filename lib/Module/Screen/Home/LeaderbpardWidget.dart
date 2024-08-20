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
import 'package:poolqapp/Provider/AuthProviders.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:poolqapp/Module/Screen/Home/picks.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:poolqapp/Module/Screen/Home/picked.dart';
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
  final Stream<QuerySnapshot> _leaderboard_recordStream =
      FirebaseFirestore.instance.collection('leaderboard_record').snapshots();

  List? data;
  List? data2;
  List? normal_data;
  var particularData;
  bool? played;

  Future getGame(context, selectedValue) async {
    DataProvider dataProvider =
        Provider.of<DataProvider>(context, listen: false);
    AuthProviders authProvider =
        Provider.of<AuthProviders>(context, listen: false);
    var response = await http.get(
        Uri.parse(
            '${mainUrl}/getnlf/${dataProvider.game!["mode"]}${selectedValue}'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Access-Control-Allow-Origin': '*',
        }).timeout(Duration(seconds: 20));
    // print(response.body);
    // print(response.body);
    var body = json.decode(response.body);
    // print(body);
    // print(body);
    List body1 = body;
    setState(() {
      data2 = body1;
    });

    return body;
  }

  // ${mainUrl}/getnlf/${dataProvider.game!["mode"]}${widget.selectedValue}
  Future getLeaderBoard(context, selectedValue) async {
    DataProvider dataProvider =
        Provider.of<DataProvider>(context, listen: false);
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
            (element) => element['uid'] == user!.uid,
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
      setState(() {
        data = body;
        normal_data = body;
      });
    }

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
    getGame(context, selectedValue);
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
                                    'Hello, ${user!.displayName}!'
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
                        mainAxisAlignment: MainAxisAlignment.start,
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
                          Spacer(),
                          InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => GamePlayWidget(
                                      selectedValue: selectedValue),
                                ),
                              );
                            },
                            child: Padding(
                              padding:
                                  EdgeInsetsDirectional.fromSTEB(2, 0, 0, 0),
                              child: Text(
                                'View Game Scores'.toUpperCase(),
                                style: TextStyle(
                                  fontFamily: 'Lexend Deca',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
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
                                          if (data![index]["uid"] ==
                                              user!.uid) {
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
                                                height: 70,
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
                                                width: MediaQuery.of(context)
                                                    .size
                                                    .width,
                                                height: 70,
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
                                              user!.uid) {
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
                                                height: 70,
                                                decoration: BoxDecoration(
                                                  color: normal_data![0]
                                                              ["uid"] ==
                                                          data![index]["uid"]
                                                      ? null
                                                      : Color(0xFF3474E0),
                                                  image: normal_data![0]
                                                              ["uid"] ==
                                                          data![index]["uid"]
                                                      ? DecorationImage(
                                                          image: AssetImage(
                                                              "assets/images/winner.png"),
                                                          fit: BoxFit.cover)
                                                      : null,
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
                                        ? normal_data![0]["uid"] == user!.uid
                                            ? null
                                            : InkWell(
                                                onTap: () {
                                                  if (normal_data![0]["uid"] ==
                                                      user!.uid) {
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
                                                        height: 70,
                                                        decoration:
                                                            BoxDecoration(
                                                          image: DecorationImage(
                                                              image: AssetImage(
                                                                  "assets/images/winner.png"),
                                                              fit:
                                                                  BoxFit.cover),
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
                                                              height: 70,
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
                                                    height: 70,
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
                                                                    .fromSTEB(
                                                                        15,
                                                                        1,
                                                                        1,
                                                                        1),
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
                                                                      .fromSTEB(
                                                                          14,
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
                                                                      fontSize:
                                                                          16,
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
                                                                          color:
                                                                              Colors.white,
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
