// import '/flutter_flow/flutter_flow_theme.dart';
// import '/flutter_flow/flutter_flow_util.dart';
import 'dart:convert';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pollapp/Module/Screen/Home/picked.dart';
import 'package:pollapp/Module/Screen/Home/picks.dart';
import 'package:pollapp/Provider/AuthProvider.dart';
import 'package:pollapp/Provider/homeProvider.dart';
import 'package:provider/provider.dart';
import 'games.dart';

//
// import 'leaderboard_model.dart';
// export 'leaderboard_model.dart';

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

  Future getLeaderBoard(context, selectedValue) async {
    print('https://poolq.app/getleaderboard/REG${selectedValue}');
    var response = await http.get(
        Uri.parse('https://poolq.app/getleaderboard/REG${selectedValue}'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
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
    selectedValue = dataProvider.game!["name"].toString().replaceAll("REG", "");
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
    AuthProvider authProvider =
        Provider.of<AuthProvider>(context, listen: true);

    return GestureDetector(
      onTap: () => FocusScope.of(context).requestFocus(_unfocusNode),
      child: Scaffold(
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
                                  'assets/images/poolq.png',
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
                                    _showPicker(context);
                                  },
                                  child: Row(
                                    children: [
                                      Padding(
                                        padding: EdgeInsetsDirectional.fromSTEB(
                                            0, 0, 0, 0),
                                        child: Text(
                                          'Week: ${selectedValue} '.toUpperCase(),
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
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

                                // Padding(
                                //   padding: const EdgeInsets.only(top: 0.0),
                                //   child: Center(
                                //     child: DropdownButtonHideUnderline(
                                //       child: DropdownButton2(
                                //         items: items
                                //             .map((item) => DropdownMenuItem<String>(
                                //           value: item,
                                //           child: Text(
                                //             item,
                                //             textAlign: TextAlign.center,
                                //             style: TextStyle(
                                //               fontWeight: FontWeight.bold,
                                //               fontFamily: 'Poppins',
                                //               fontSize: 16,
                                //             ),
                                //           ),
                                //         ))
                                //             .toList(),
                                //         value: selectedValue,
                                //         onChanged: (value) {
                                //           setState(() {
                                //             selectedValue = value as String;
                                //             setState(() {
                                //               data = null;
                                //             });
                                //             getLeaderBoard(context, selectedValue);
                                //           });
                                //         },
                                //         buttonStyleData: const ButtonStyleData(
                                //           height: 40,
                                //           width: 60,
                                //         ),
                                //         menuItemStyleData: const MenuItemStyleData(
                                //           // height: 40,
                                //         ),
                                //       ),
                                //     ),
                                //   ),
                                // ),
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
                Builder(
                  builder: (BuildContext context) {
                    if (data == null) {
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
                    } else if (data!.isEmpty) {
                      return Text("No Data");
                    }
                    return Expanded(
                      child: ListView(
                        children: data!.map((document) {
                          Map<String, dynamic> data =
                              document as Map<String, dynamic>;
                          return InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => PickedWidget(
                                        userId: data["uid"],
                                        selectedValue: selectedValue)
                                    // Picks(userId:data["uid"], selectedValue:selectedValue),
                                    ),
                              );
                            },
                            child: Column(
                              children: [
                                // ListTile(
                                //   title: Text(
                                //     'Player name',
                                //     // style: FlutterFlowTheme.of(context).headlineSmall,
                                //   ),
                                //   subtitle: Text(
                                //     'score 12',
                                //     // style: FlutterFlowTheme.of(context).titleSmall,
                                //   ),
                                //   trailing: Icon(
                                //     Icons.arrow_forward_ios,
                                //     color: Color(0xFF303030),
                                //     size: 20,
                                //   ),
                                //   tileColor: Color(0xFFF5F5F5),
                                //   dense: false,
                                // ),
                                Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      10, 0, 10, 10),
                                  child: Container(
                                    width: MediaQuery.of(context).size.width,
                                    height: 70,
                                    decoration: BoxDecoration(
                                      color: Color(0xFFD5D6D8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Color(0x411D2429),
                                          offset: Offset(0, 1),
                                        )
                                      ],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          8, 8, 8, 8),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.max,
                                        children: [
                                          Padding(
                                            padding:
                                                EdgeInsetsDirectional.fromSTEB(
                                                    0, 1, 1, 1),
                                            child: CircleAvatar(
                                              foregroundColor: Colors.white,
                                              backgroundColor: Colors.white,
                                              radius: 47,
                                              backgroundImage: data['photoURL']
                                                              .toString() ==
                                                          "" ||
                                                      data['photoURL'] == null
                                                  ? AssetImage(
                                                      "assets/images/user.png")
                                                  : NetworkImage(
                                                          data['photoURL']
                                                              .toString())
                                                      as ImageProvider,
                                            ),

                                            // ClipRRect(
                                            //   borderRadius: BorderRadius.circular(12),
                                            //   child: Image.network(
                                            //     '${data['photoURL']}',
                                            //     width: 50,
                                            //     height: 50,
                                            //     fit: BoxFit.cover,
                                            //   ),
                                            // ),
                                          ),
                                          Expanded(
                                            child: Padding(
                                              padding: EdgeInsetsDirectional
                                                  .fromSTEB(8, 8, 4, 0),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.max,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    '${data['displayName']}',
                                                    style: TextStyle(
                                                      fontFamily: 'Lexend Deca',
                                                      color: Color(0xFF090F13),
                                                      fontSize: 20,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                  Expanded(
                                                    child: Padding(
                                                      padding:
                                                          EdgeInsetsDirectional
                                                              .fromSTEB(
                                                                  0, 4, 8, 0),
                                                      child: AutoSizeText(
                                                        'week ${selectedValue}',
                                                        textAlign:
                                                            TextAlign.start,
                                                        style: TextStyle(
                                                          fontFamily:
                                                              'Lexend Deca',
                                                          color:
                                                              Color(0xFF57636C),
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.normal,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          Column(
                                            mainAxisSize: MainAxisSize.max,
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              Padding(
                                                padding: EdgeInsetsDirectional
                                                    .fromSTEB(0, 4, 0, 0),
                                                child: Icon(
                                                  Icons.chevron_right_rounded,
                                                  color: Color(0xFF57636C),
                                                  size: 24,
                                                ),
                                              ),
                                              Padding(
                                                padding: EdgeInsetsDirectional
                                                    .fromSTEB(0, 0, 4, 8),
                                                child: Text(
                                                  'Score  ${'${data['score']}'}',
                                                  textAlign: TextAlign.end,
                                                  style: TextStyle(
                                                    fontFamily: 'Lexend Deca',
                                                    color: Color(0xFF4B39EF),
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
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
                        }).toList(),
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
                      scrollController:
                          FixedExtentScrollController(initialItem: 0),
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
