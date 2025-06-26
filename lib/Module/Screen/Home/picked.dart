import 'dart:convert';
import 'PlayerPickWidget.dart';
import 'LeaderbpardWidget.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../constants.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:poolqapp/Widget/reuse.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:poolqapp/Provider/homeProvider.dart';
import 'package:poolqapp/Provider/AuthProviders.dart';
import '../../../services/nfl_schedule_service.dart';
import 'package:flutter_svg/svg.dart';
import 'package:grouped_list/grouped_list.dart';
//import 'package:admob_flutter/admob_flutter.dart';

// import 'play_model.dart';
// export 'play_model.dart';

class PickedWidget extends StatefulWidget {
  const PickedWidget({this.userId, this.selectedValue});

  final String? userId;
  final String? selectedValue;

  @override
  _PickedWidgetState createState() => _PickedWidgetState();
}

class _PickedWidgetState extends State<PickedWidget> {
  // late PlayModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  List? data;
  List? winners;
  int tiebreaker = 0;
  TextEditingController tieBreakerController = TextEditingController();
  User? user = FirebaseAuth.instance.currentUser;

  Stream<QuerySnapshot>? _pickrecord;
  Stream<QuerySnapshot>? _pickrecordStream;

  @override
  void initState() {
    super.initState();
    DataProvider dataProvider =
        Provider.of<DataProvider>(context, listen: false);
    AuthProviders authProvider =
        Provider.of<AuthProviders>(context, listen: false);

    // Mock data for testing
    if (kDebugMode) {
      _mockPickRecord();
    }

    _pickrecord = FirebaseFirestore.instance
        .collection('pickrecord')
        .where("uid", isEqualTo: user!.uid)
        .where("week", isEqualTo: dataProvider.game!["name"])
        .snapshots();

    _pickrecordStream = FirebaseFirestore.instance
        .collection('pickrecord')
        .where("week",
            isEqualTo: "${dataProvider.game!["mode"]}${widget.selectedValue}")
        .where("uid", isEqualTo: "${widget.userId}")
        .snapshots();
    // _model = createModel(context, () => PlayModel());

    // _model.tieBreakerController ??= TextEditingController();
  }

  // Mock data function
  Future<void> _mockPickRecord() async {
    try {
      // Mock user data
      final mockUserData = {
        'uid': widget.userId ?? 'mock_user_1',
        'week': 'NFL1', // Adjust based on your game mode
        'tiebreaker': 45,
        'picks': [
          {
            'gameId': '1',
            'selected': 'Kansas City Chiefs',
            'date': '2024-03-20',
            'home': 'Kansas City Chiefs',
            'away': 'San Francisco 49ers',
            'picture': 'https://upload.wikimedia.org/wikipedia/en/thumb/e/e1/Kansas_City_Chiefs_logo.svg/1200px-Kansas_City_Chiefs_logo.svg.png',
            'picture2': 'https://upload.wikimedia.org/wikipedia/commons/thumb/3/3a/San_Francisco_49ers_logo.svg/1200px-San_Francisco_49ers_logo.svg.png',
            'score': '25',
            'score2': '22'
          },
          {
            'gameId': '2',
            'selected': 'Baltimore Ravens',
            'date': '2024-03-21',
            'home': 'Baltimore Ravens',
            'away': 'Buffalo Bills',
            'picture': 'https://upload.wikimedia.org/wikipedia/en/thumb/1/16/Baltimore_Ravens_logo.svg/1200px-Baltimore_Ravens_logo.svg.png',
            'picture2': 'https://upload.wikimedia.org/wikipedia/en/thumb/7/77/Buffalo_Bills_logo.svg/1200px-Buffalo_Bills_logo.svg.png',
            'score': '17',
            'score2': '10'
          },
          {
            'gameId': '3',
            'selected': 'Detroit Lions',
            'date': '2024-03-22',
            'home': 'Detroit Lions',
            'away': 'Tampa Bay Buccaneers',
            'picture': 'https://upload.wikimedia.org/wikipedia/en/thumb/7/71/Detroit_Lions_logo.svg/1200px-Detroit_Lions_logo.svg.png',
            'picture2': 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a2/Tampa_Bay_Buccaneers_logo.svg/1200px-Tampa_Bay_Buccaneers_logo.svg.png',
            'score': '31',
            'score2': '23'
          }
        ]
      };

      // Add mock data to Firestore
      await FirebaseFirestore.instance
          .collection('pickrecord')
          .doc('mock_pick_${widget.userId}')
          .set(mockUserData);

      print('Mock data added successfully');
    } catch (e) {
      print('Error adding mock data: $e');
    }
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
        //     child: kIsWeb?AdmobBanner(
        //       adUnitId: Provider.of<DataProvider>(context, listen: false)
        //           .getBannerAdUnitId().toString(),
        //       adSize: AdmobBannerSize.BANNER,
        //       listener: (AdmobAdEvent event, Map<String, dynamic> ?args) {},
        //     ):Container()),
        key: scaffoldKey,
        backgroundColor: Colors.white,
        body: StreamBuilder<QuerySnapshot>(
            stream: _pickrecordStream,
            builder:
                (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot2) {
              if (snapshot2.hasError) {
                return Center(child: Text('Something went wrong'));
              }

              if (snapshot2.connectionState == ConnectionState.waiting ||
                  snapshot2.data == null) {
                return Center(
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
                            color: Color(0xFF333333),
                            fontSize: 18,
                            fontWeight: FontWeight.w600)),
                  ],
                ));
              }

              return Builder(builder: (context) {
                return StreamBuilder<QuerySnapshot>(
                    stream: _pickrecord,
                    builder: (BuildContext context,
                        AsyncSnapshot<QuerySnapshot> snapshot) {
                      if (snapshot.hasError) {
                        return Center(child: Text('Something went wrong'));
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
                                      .copyWith(secondary: Color(0xFF063a73)),
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
                      }

                      return Builder(builder: (context) {
                        bool value = false;
                        List new_data = [];
                        QueryDocumentSnapshot? new_data2;

                        runFunction() {
                          if (snapshot2.data != null && snapshot2.data!.docs.isNotEmpty) {
                            for (var document in snapshot2.data!.docs) {
                              if (document.data() != null) {
                                Map<String, dynamic> data = document.data() as Map<String, dynamic>;
                                new_data = data["picks"] ?? [];
                                new_data2 = document;
                              }
                            }
                          }
                          value = true;
                        }

                        !value ? runFunction() : null;

                        return Container(
                          width: MediaQuery.of(context).size.width,
                          height: MediaQuery.of(context).size.height * 1,
                          child: Stack(
                            children: [
                              Align(
                                alignment: AlignmentDirectional(0, 0),
                                child: Image.asset(
                                  'assets/images/assets.aboutamazon.jpg',
                                  width: MediaQuery.of(context).size.width,
                                  height:
                                      MediaQuery.of(context).size.height * 1,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Container(
                                width: MediaQuery.of(context).size.width,
                                height: 150,
                                decoration: BoxDecoration(
                                  color: Color(0x43EEEEEE),
                                ),
                                child: Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      0, 12, 0, 0),
                                  child: SingleChildScrollView(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.max,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Row(
                                          mainAxisSize: MainAxisSize.max,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Padding(
                                              padding: EdgeInsetsDirectional
                                                  .fromSTEB(20, 20, 20, 0),
                                              child: IconButton(
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                },
                                                icon: Icon(
                                                    Icons.arrow_back_ios_new),
                                              ),
                                            ),
                                            Spacer(),
                                            Padding(
                                              padding: EdgeInsetsDirectional
                                                  .fromSTEB(20, 20, 10, 0),
                                              child: Text(
                                                'Welcome \nto week'
                                                    .toUpperCase(),
                                                textAlign: TextAlign.end,
                                                style: TextStyle(
                                                  fontFamily: 'Poppins',
                                                  fontSize: 20,
                                                  height: 0.9,
                                                ),
                                              ),
                                            ),
                                            Padding(
                                              padding: EdgeInsetsDirectional
                                                  .fromSTEB(5, 20, 20, 0),
                                              child: Text(
                                                '${widget.selectedValue}',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontFamily: 'Poppins',
                                                  fontSize: 30,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          mainAxisSize: MainAxisSize.max,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Padding(
                                              padding: EdgeInsetsDirectional
                                                  .fromSTEB(5, 20, 20, 0),
                                              child: Column(
                                                children: [
                                                  Text(
                                                    '${widget.userId == user!.uid ? "Your" : "Player\'s"} Picks',
                                                    textAlign: TextAlign.center,
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 24,
                                                      fontWeight: FontWeight.bold,
                                                      color: Color(0xFF27512F),
                                                    ),
                                                  ),
                                                  Text(
                                                    'Week ${widget.selectedValue}',
                                                    textAlign: TextAlign.center,
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 18,
                                                      color: Color(0xFF27512F),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding:
                                    EdgeInsetsDirectional.fromSTEB(0, 80, 0, 0),
                                child: Container(
                                  width: MediaQuery.of(context).size.width,
                                  decoration: BoxDecoration(
                                    color: Color(0x85C5C5C5),
                                  ),
                                  child: Padding(
                                    padding: EdgeInsetsDirectional.fromSTEB(
                                        1, 20, 1, 1),
                                    child: Builder(
                                      builder: (context) {
                                        if (data == null || winners == null) {
                                          return Center(
                                            child: SizedBox(
                                              width: 50,
                                              height: 50,
                                              child: CircularProgressIndicator(
                                                color: primary,
                                              ),
                                            ),
                                          );
                                        }

                                        if (data!.isEmpty) {
                                          return Center(
                                            child: Text(
                                              'No picks available for this week',
                                              style: GoogleFonts.poppins(
                                                fontSize: 18,
                                                color: Color(0xFF27512F),
                                              ),
                                            ),
                                          );
                                        }

                                        final listViewGetScheduleResponse =
                                            data;
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                              bottom: 70.0),
                                          child: Builder(
                                            builder: (context) {
                                              final game =
                                                  listViewGetScheduleResponse;
                                              return GroupedListView<dynamic,
                                                  String>(
                                                elements: game!,
                                                groupBy: (element) =>
                                                    dataProvider
                                                        .formatStringDate(
                                                            element["date"])
                                                        .toString(),
                                                groupSeparatorBuilder:
                                                    (String value) => ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.only(
                                                          topRight:
                                                              Radius.circular(
                                                                  20),
                                                          topLeft:
                                                              Radius.circular(
                                                                  20)),
                                                  child: Container(
                                                    width: 200,
                                                    color: Colors.white,
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              4.0),
                                                      child: Text(
                                                        formateDate(value),
                                                        textAlign:
                                                            TextAlign.center,
                                                        style: const TextStyle(
                                                            fontSize: 12,
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                physics:
                                                    BouncingScrollPhysics(),
                                                indexedItemBuilder: (context,
                                                    dynamic gameItem, index) {
                                                  return Column(
                                                    mainAxisSize:
                                                        MainAxisSize.max,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Padding(
                                                        padding:
                                                            EdgeInsetsDirectional
                                                                .fromSTEB(0, 0,
                                                                    0, 20),
                                                        child: Container(
                                                          decoration:
                                                              BoxDecoration(
                                                            color: Color(0x96E87D)
                                                                .withOpacity(0.8),
                                                            borderRadius: BorderRadius.circular(12),
                                                            boxShadow: [
                                                              BoxShadow(
                                                                color: Colors.black.withOpacity(0.1),
                                                                blurRadius: 4,
                                                                offset: Offset(0, 2),
                                                              ),
                                                            ],
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
                                                                        fontSize: 16,
                                                                        fontWeight: FontWeight.bold,
                                                                        color: Color(0xFF27512F),
                                                                      ),
                                                                    ),
                                                                    Container(
                                                                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                                                      decoration: BoxDecoration(
                                                                        color: Color(0xFF27512F).withOpacity(0.1),
                                                                        borderRadius: BorderRadius.circular(12),
                                                                      ),
                                                                      child: Text(
                                                                        '${gameItem["date"]}',
                                                                        style: GoogleFonts.poppins(
                                                                          fontSize: 12,
                                                                          color: Color(0xFF27512F),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                                SizedBox(height: 16),
                                                                Row(
                                                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                                  children: [
                                                                    Column(
                                                                      children: [
                                                                        SvgPicture.network(
                                                                          gameItem["picture"] ?? '',
                                                                          width: 60,
                                                                          height: 60,
                                                                          placeholderBuilder: (BuildContext context) => Container(
                                                                            width: 60,
                                                                            height: 60,
                                                                            color: Colors.grey[200],
                                                                            child: Icon(Icons.sports_football, color: Colors.grey[400]),
                                                                          ),
                                                                        ),
                                                                        SizedBox(height: 8),
                                                                        Text(
                                                                          gameItem["home"] ?? 'Unknown',
                                                                          style: GoogleFonts.poppins(
                                                                            fontSize: 14,
                                                                            fontWeight: FontWeight.w500,
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                    Container(
                                                                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                                      decoration: BoxDecoration(
                                                                        color: Colors.white,
                                                                        borderRadius: BorderRadius.circular(8),
                                                                        boxShadow: [
                                                                          BoxShadow(
                                                                            color: Colors.black.withOpacity(0.1),
                                                                            blurRadius: 4,
                                                                            offset: Offset(0, 2),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                      child: Text(
                                                                        'VS',
                                                                        style: GoogleFonts.poppins(
                                                                          fontSize: 16,
                                                                          fontWeight: FontWeight.bold,
                                                                          color: Color(0xFF27512F),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    Column(
                                                                      children: [
                                                                        SvgPicture.network(
                                                                          gameItem["picture2"] ?? '',
                                                                          width: 60,
                                                                          height: 60,
                                                                          placeholderBuilder: (BuildContext context) => Container(
                                                                            width: 60,
                                                                            height: 60,
                                                                            color: Colors.grey[200],
                                                                            child: Icon(Icons.sports_football, color: Colors.grey[400]),
                                                                          ),
                                                                        ),
                                                                        SizedBox(height: 8),
                                                                        Text(
                                                                          gameItem["away"] ?? 'Unknown',
                                                                          style: GoogleFonts.poppins(
                                                                            fontSize: 14,
                                                                            fontWeight: FontWeight.w500,
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ],
                                                                ),
                                                                SizedBox(height: 16),
                                                                Container(
                                                                  width: double.infinity,
                                                                  padding: EdgeInsets.all(12),
                                                                  decoration: BoxDecoration(
                                                                    color: Colors.white,
                                                                    borderRadius: BorderRadius.circular(8),
                                                                    border: Border.all(
                                                                      color: Color(0xFF27512F).withOpacity(0.2),
                                                                    ),
                                                                  ),
                                                                  child: Row(
                                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                                    children: [
                                                                      Icon(
                                                                        Icons.sports_football,
                                                                        color: Color(0xFF27512F),
                                                                        size: 20,
                                                                      ),
                                                                      SizedBox(width: 8),
                                                                      Text(
                                                                        'Selected: ${gameItem["selected"] ?? "Not picked"}',
                                                                        style: GoogleFonts.poppins(
                                                                          fontSize: 14,
                                                                          fontWeight: FontWeight.w500,
                                                                          color: Color(0xFF27512F),
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  );
                                                },
                                                itemComparator:
                                                    (item1, item2) =>
                                                        item1['date'].compareTo(
                                                            item2['date']),
                                                useStickyGroupSeparators: true,
                                                floatingHeader: true,
                                                order: GroupedListOrder
                                                    .ASC,
                                              );
                                            },
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                              Align(
                                alignment: Alignment.bottomCenter,
                                child: Container(
                                  width: MediaQuery.of(context).size.width,
                                  height: 75,
                                  decoration: BoxDecoration(
                                    color: Color(0xDD92EF7B),
                                  ),
                                  child: Padding(
                                    padding: EdgeInsetsDirectional.fromSTEB(
                                        0, 15, 0, 0),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.max,
                                      children: [
                                        Row(
                                          mainAxisSize: MainAxisSize.max,
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          children: [
                                            Text(
                                              'Tie Breaker:',
                                              style: GoogleFonts.poppins(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            Container(
                                              width: 60,
                                              decoration: BoxDecoration(),
                                              child: TextFormField(
                                                enabled: false,
                                                controller:
                                                    tieBreakerController,
                                                obscureText: false,
                                                decoration: InputDecoration(
                                                  hintText:
                                                      new_data2 != null ? "${new_data2!["tiebreaker"] ?? 0}" : "0",
                                                  hintStyle: TextStyle(
                                                      fontSize: 20,
                                                      color: Colors.black),
                                                  enabledBorder:
                                                      UnderlineInputBorder(
                                                    borderSide: BorderSide(
                                                      color: Color(0x00000000),
                                                      width: 1,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            30),
                                                  ),
                                                  focusedBorder:
                                                      UnderlineInputBorder(
                                                    borderSide: BorderSide(
                                                      color: Color(0x00000000),
                                                      width: 1,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            30),
                                                  ),
                                                  errorBorder:
                                                      UnderlineInputBorder(
                                                    borderSide: BorderSide(
                                                      color: Color(0x00000000),
                                                      width: 1,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            30),
                                                  ),
                                                  focusedErrorBorder:
                                                      UnderlineInputBorder(
                                                    borderSide: BorderSide(
                                                      color: Color(0x00000000),
                                                      width: 1,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            30),
                                                  ),
                                                  filled: true,
                                                  fillColor: Color(0xC8DADADA),
                                                  contentPadding:
                                                      EdgeInsetsDirectional
                                                          .fromSTEB(
                                                              10, 0, 0, 0),
                                                ),
                                                keyboardType:
                                                    TextInputType.number,
                                              ),
                                            ),
                                            Text(
                                              'Game Tie Breaker:',
                                              style: GoogleFonts.poppins(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            Container(
                                              width: 60,
                                              decoration: BoxDecoration(),
                                              child: TextFormField(
                                                enabled: false,
                                                controller:
                                                    tieBreakerController,
                                                obscureText: false,
                                                decoration: InputDecoration(
                                                  hintText: "${tiebreaker}",
                                                  hintStyle: TextStyle(
                                                      fontSize: 20,
                                                      color: Colors.black),
                                                  enabledBorder:
                                                      UnderlineInputBorder(
                                                    borderSide: BorderSide(
                                                      color: Color(0x00000000),
                                                      width: 1,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            30),
                                                  ),
                                                  focusedBorder:
                                                      UnderlineInputBorder(
                                                    borderSide: BorderSide(
                                                      color: Color(0x00000000),
                                                      width: 1,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            30),
                                                  ),
                                                  errorBorder:
                                                      UnderlineInputBorder(
                                                    borderSide: BorderSide(
                                                      color: Color(0x00000000),
                                                      width: 1,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            30),
                                                  ),
                                                  focusedErrorBorder:
                                                      UnderlineInputBorder(
                                                    borderSide: BorderSide(
                                                      color: Color(0x00000000),
                                                      width: 1,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            30),
                                                  ),
                                                  filled: true,
                                                  fillColor: Color(0xC8DADADA),
                                                  contentPadding:
                                                      EdgeInsetsDirectional
                                                          .fromSTEB(
                                                              10, 0, 0, 0),
                                                ),
                                                keyboardType:
                                                    TextInputType.number,
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
                      });
                    });
              });
            }));
  }
}
