import 'dart:convert';
import 'PlayerPickWidget.dart';
import 'LeaderbpardWidget.dart';
import '../../../Widget/reuse.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter/material.dart';
import '../../../Constants/value.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import '../../../Provider/homeProvider.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:poolqapp/Provider/AuthProviders.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
//import 'package:admob_flutter/admob_flutter.dart';

// import 'play_model.dart';
// export 'play_model.dart';

class GamePlayWidget extends StatefulWidget {
  final selectedValue;
  GamePlayWidget({this.selectedValue});

  @override
  _GamePlayWidgetState createState() => _GamePlayWidgetState();
}

class _GamePlayWidgetState extends State<GamePlayWidget> {
  // late PlayModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  List? data;

  TextEditingController tieBreakerController = TextEditingController();
  User? user = FirebaseAuth.instance.currentUser;
  Future getGame(context) async {
    DataProvider dataProvider =
        Provider.of<DataProvider>(context, listen: false);
    AuthProviders authProvider =
        Provider.of<AuthProviders>(context, listen: false);
    var response = await http.get(
        Uri.parse(
            '${mainUrl}/getnlf/${dataProvider.game!["mode"]}${widget.selectedValue}'),
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
    // List<Agents> AgentLists = body1.map((data) {
    //   return Agents.fromJson(data);
    // }).toList();
    // if (response.statusCode == 200 ||
    //     response.statusCode == 201 ||
    //     response.statusCode == 202) {
    //
    // } else {
    //   print('failed');
    // }
    return body;
  }

  Stream<QuerySnapshot>? _pickrecord;
  @override
  void initState() {
    super.initState();
    DataProvider dataProvider =
        Provider.of<DataProvider>(context, listen: false);
    _pickrecord = FirebaseFirestore.instance
        .collection('pickrecord')
        .where("uid", isEqualTo: user!.uid)
        .where("week", isEqualTo: dataProvider.game!["name"])
        .snapshots();
    getGame(context);
    // _model = createModel(context, () => PlayModel());

    // _model.tieBreakerController ??= TextEditingController();
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
        backgroundColor: Color(0xFF3F3E3E),
        body: Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height * 1,
          child: Stack(
            children: [
              Align(
                alignment: AlignmentDirectional(0, 0),
                child: Image.asset(
                  'assets/images/assets.aboutamazon.jpg',
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height * 1,
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
                  padding: EdgeInsetsDirectional.fromSTEB(0, 12, 0, 0),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Padding(
                              padding:
                                  EdgeInsetsDirectional.fromSTEB(15, 20, 20, 0),
                              child: IconButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                icon: Icon(Icons.arrow_back_ios_new),
                              ),
                            ),
                            Spacer(),
                            Padding(
                              padding:
                                  EdgeInsetsDirectional.fromSTEB(20, 20, 10, 0),
                              child: Text(
                                'Welcome \nto week'.toUpperCase(),
                                textAlign: TextAlign.end,
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 20,
                                  height: 0.9,
                                ),
                              ),
                            ),
                            Padding(
                              padding:
                                  EdgeInsetsDirectional.fromSTEB(5, 20, 25, 0),
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
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(0, 80, 0, 0),
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  decoration: BoxDecoration(
                    color: Color(0x85C5C5C5),
                  ),
                  child: Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(1, 20, 1, 1),
                    child: Builder(
                      // future: getGame(),
                      builder: (context) {
                        // Customize what your widget looks like when it's loading.
                        if (data == null) {
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
                        final listViewGetScheduleResponse = data;
                        // print(data);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 0.0),
                          child: Builder(
                            builder: (context) {
                              final game = listViewGetScheduleResponse;
                              // game!.sort((a, b) => dataProvider.formatStringDate(b['date'], context).compareTo(dataProvider.formatStringDate(a["date"], context)));
                              return GroupedListView<dynamic, String>(
                                elements: game!,
                                // groupBy: (element) => element['date'],
                                groupBy: (element) => dataProvider
                                    .formatStringDate(element["date"])
                                    .toString(),
                                groupSeparatorBuilder: (String value) =>
                                    ClipRRect(
                                  borderRadius: BorderRadius.only(
                                      topRight: Radius.circular(20),
                                      topLeft: Radius.circular(20)),
                                  child: Container(
                                    width: 200,
                                    color: Colors.white,
                                    child: Padding(
                                      padding: const EdgeInsets.all(4.0),
                                      child: Text(
                                        formateDate(value),
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                ),
                                physics: BouncingScrollPhysics(),
                                indexedItemBuilder:
                                    (context, dynamic gameItem, index) {
                                  // final gameItem = game[gameIndex];
                                  return Column(
                                    mainAxisSize: MainAxisSize.max,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: EdgeInsetsDirectional.fromSTEB(
                                            0, 0, 0, 20),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Color(0x96E87D)
                                                .withOpacity(0.8),
                                          ),
                                          child: Padding(
                                            padding:
                                                EdgeInsetsDirectional.fromSTEB(
                                                    0, 5, 0, 5),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.max,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              children: [
                                                Expanded(
                                                  child: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.max,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .center,
                                                    children: [
                                                      Row(
                                                        mainAxisSize:
                                                            MainAxisSize.max,
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          Text(
                                                            'GAME: ',
                                                            textAlign: TextAlign
                                                                .center,
                                                            style: TextStyle(
                                                              fontFamily:
                                                                  'Poppins',
                                                              color: Color(
                                                                  0xFF27512F),
                                                              fontSize: 10,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                          Text(
                                                            (index + 1)
                                                                .toString(),
                                                            style: TextStyle(
                                                              fontFamily:
                                                                  'Poppins',
                                                              fontSize: 10,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      Row(
                                                        mainAxisSize:
                                                            MainAxisSize.max,
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceEvenly,
                                                        children: [
                                                          SvgPicture.network(
                                                              gameItem[
                                                                  "picture"],
                                                              width: 40,
                                                              height: 40,
                                                              placeholderBuilder:
                                                                  (BuildContext
                                                                          context) =>
                                                                      Container()),
                                                          TextButton(
                                                            onPressed:
                                                                () async {},
                                                            child: Row(
                                                              children: [
                                                                Text(
                                                                  gameItem[
                                                                      "abbreviation"],
                                                                  style: TextStyle(
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                      color: Colors
                                                                          .white),
                                                                ),
                                                                dataProvider
                                                                        .playerPicks!
                                                                        .contains(gameItem[
                                                                            "abbreviation"])
                                                                    ? Icon(
                                                                        Icons
                                                                            .check,
                                                                        color: Colors
                                                                            .white)
                                                                    : Container()
                                                              ],
                                                            ),
                                                            style: ButtonStyle(
                                                              padding: MaterialStateProperty.all(
                                                                  EdgeInsetsDirectional
                                                                      .fromSTEB(
                                                                          35,
                                                                          5,
                                                                          35,
                                                                          5)),
                                                              backgroundColor:
                                                                  MaterialStateProperty
                                                                      .all(Color(
                                                                          0x733474E0)),
                                                              foregroundColor:
                                                                  MaterialStateProperty
                                                                      .all(Color(
                                                                          0x733474E0)),
                                                              textStyle:
                                                                  MaterialStateProperty
                                                                      .all(
                                                                          TextStyle(
                                                                fontFamily:
                                                                    'Poppins',
                                                                color: Colors
                                                                    .white,
                                                              )),
                                                              elevation:
                                                                  MaterialStateProperty
                                                                      .all(2),
                                                              shape: MaterialStateProperty
                                                                  .all(
                                                                      RoundedRectangleBorder(
                                                                side:
                                                                    BorderSide(
                                                                  color: Colors
                                                                      .transparent,
                                                                  width: 1,
                                                                ),
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            30),
                                                              )),
                                                            ),
                                                          ),
                                                          Padding(
                                                            padding:
                                                                EdgeInsetsDirectional
                                                                    .fromSTEB(
                                                                        5,
                                                                        0,
                                                                        5,
                                                                        0),
                                                            child: Text(
                                                                "${gameItem["score"]} : ${gameItem["score2"]}",
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        16,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold)),
                                                          ),
                                                          TextButton(
                                                              style:
                                                                  ButtonStyle(
                                                                padding: MaterialStateProperty.all(
                                                                    EdgeInsetsDirectional
                                                                        .fromSTEB(
                                                                            35,
                                                                            5,
                                                                            35,
                                                                            5)),
                                                                backgroundColor:
                                                                    MaterialStateProperty
                                                                        .all(Color(
                                                                            0x733474E0)),
                                                                foregroundColor:
                                                                    MaterialStateProperty
                                                                        .all(Color(
                                                                            0x733474E0)),
                                                                textStyle:
                                                                    MaterialStateProperty
                                                                        .all(
                                                                            TextStyle(
                                                                  fontFamily:
                                                                      'Poppins',
                                                                  color: Colors
                                                                      .white,
                                                                )),
                                                                elevation:
                                                                    MaterialStateProperty
                                                                        .all(2),
                                                                shape: MaterialStateProperty
                                                                    .all(
                                                                        RoundedRectangleBorder(
                                                                  side:
                                                                      BorderSide(
                                                                    color: Colors
                                                                        .transparent,
                                                                    width: 1,
                                                                  ),
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              30),
                                                                )),
                                                              ),
                                                              onPressed:
                                                                  () async {},
                                                              child: Center(
                                                                child: Row(
                                                                  children: [
                                                                    Text(
                                                                      gameItem[
                                                                          "abbreviation2"],
                                                                      style: TextStyle(
                                                                          fontWeight: FontWeight
                                                                              .bold,
                                                                          color:
                                                                              Colors.white),
                                                                    ),
                                                                    dataProvider
                                                                            .playerPicks!
                                                                            .contains(gameItem[
                                                                                "abbreviation2"])
                                                                        ? Icon(
                                                                            Icons
                                                                                .check,
                                                                            color:
                                                                                Colors.white)
                                                                        : Container()
                                                                  ],
                                                                ),
                                                              )
                                                              // getJsonField(
                                                              //   gameItem,
                                                              //   r'''$.home''',
                                                              // ).toString(),
                                                              // options:

                                                              ),
                                                          SvgPicture.network(
                                                              gameItem[
                                                                  "picture2"],
                                                              width: 40,
                                                              height: 40,
                                                              placeholderBuilder:
                                                                  (BuildContext
                                                                          context) =>
                                                                      Container()),
                                                        ],
                                                      ),
                                                      // if (FFAppState().picked !=
                                                      //     null)
                                                      // Text(
                                                      //   'MAKE THE PICK!',
                                                      //   // style:
                                                      //   // FlutterFlowTheme.of(
                                                      //   //     context)
                                                      //   //     .bodyMedium
                                                      //   //     .override(
                                                      //   //   fontFamily:
                                                      //   //   'Poppins',
                                                      //   //   fontSize: 12,
                                                      //   // ),
                                                      // ),
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
                                itemComparator: (item1, item2) =>
                                    item1['date'].compareTo(item2['date']),
                                // optional
                                useStickyGroupSeparators: true,
                                // optional
                                floatingHeader: true,
                                // optional
                                order: GroupedListOrder.ASC, // optional
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ));
  }
}
