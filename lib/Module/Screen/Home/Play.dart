import 'dart:convert';
import 'PlayerPickWidget.dart';
import 'LeaderbpardWidget.dart';
import '../../../Widget/reuse.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter/material.dart';
import 'package:poolqapp/constants.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import '../../../Provider/homeProvider.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:poolqapp/Provider/AuthProviders.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:poolqapp/Module/Screen/Home/rule.dart';
import '../../../services/nfl_schedule_service.dart';


class PlayWidget extends StatefulWidget {
  const PlayWidget({Key? key}) : super(key: key);

  @override
  _PlayWidgetState createState() => _PlayWidgetState();
}

class _PlayWidgetState extends State<PlayWidget> {
  // late PlayModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  List? data;

  TextEditingController tieBreakerController = TextEditingController();
  User? user = FirebaseAuth.instance.currentUser;
  Future getGame(context) async {
    DataProvider dataProvider = Provider.of<DataProvider>(context, listen: false);
    final scheduleService = NFLScheduleService();
    
    try {
      print('Fetching games from multiple sources...');
      
      // Only use local file for schedule display
      List<Map<String, dynamic>> games = await scheduleService.getScheduleForWeekWithLocalFallback(
        dataProvider.game!["name"]
      );
      if (games.isNotEmpty) {
        setState(() {
          data = games;
        });
        print("Successfully loaded [32m${games.length}[0m games from local file");
        return games;
      } else {
        throw Exception('No games data available from local file');
      }
      
    } catch (e) {
      print('Error fetching games: $e');
      // Show error to user but still try to continue with empty data
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading games: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Stream<QuerySnapshot>? _pickrecord;
  @override
  void initState() {
    super.initState();
    DataProvider dataProvider =
        Provider.of<DataProvider>(context, listen: false);
    // Check if we're in demo mode
    if (user == null || user?.email == 'demo@poolq.com') {
      print('Play: Demo mode detected, using empty stream');
      _pickrecord = Stream.empty();
    } else {
      _pickrecord = FirebaseFirestore.instance
          .collection('pickrecord')
          .where("uid", isEqualTo: user!.uid)
          .where("week", isEqualTo: dataProvider.game!["name"])
          .snapshots();
    }
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
        backgroundColor: Colors.white,
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
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  20, 20, 120, 0),
                              child: Image.asset(
                                'assets/images/poolq12.png',
                                width: 67,
                                height: 90,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  print('Error loading logo: $error');
                                  return Container(
                                    width: 67,
                                    height: 90,
                                    decoration: BoxDecoration(
                                      color: Colors.blue,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'PQ',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            Padding(
                              padding:
                                  EdgeInsetsDirectional.fromSTEB(20, 20, 0, 0),
                              child: Text(
                                'Welcome \nto week '.toUpperCase(),
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
                                  EdgeInsetsDirectional.fromSTEB(5, 20, 0, 0),
                              child: Text(
                                '${dataProvider.game!["name"].toString().replaceAll("REG", "").replaceAll("PRE", "")}',
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
                padding: EdgeInsetsDirectional.fromSTEB(0, 120, 0, 0),
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
                          padding: const EdgeInsets.only(bottom: 100.0),
                          child: Builder(
                            builder: (context) {
                              final game = listViewGetScheduleResponse;
                              return GroupedListView<dynamic, String>(
                                elements: game!,
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
                                                          Expanded(
                                                            flex: 2,
                                                            child: Column(
                                                              children: [
                                                                TeamLogo(
                                                                  abbr: gameItem["abbreviation2"] ?? '',
                                                                  size: 40,
                                                                ),
                                                                SizedBox(height: 8),
                                                                Text(
                                                                  gameItem["away"] ?? gameItem["abbreviation2"] ?? '',
                                                                  textAlign: TextAlign.center,
                                                                  style: TextStyle(
                                                                    fontSize: 12,
                                                                    fontWeight: FontWeight.w500,
                                                                  ),
                                                                ),
                                                                SizedBox(height: 4),
                                                                Container(
                                                                  width: 90,
                                                                  child: TextButton(
                                                                    onPressed: () async {
                                                                      if (dataProvider
                                                                          .playerPicks!
                                                                          .contains(
                                                                              gameItem[
                                                                                  "abbreviation2"])) {
                                                                        await showDialog(
                                                                          context:
                                                                              context,
                                                                          builder:
                                                                              (alertDialogContext) {
                                                                            return AlertDialog(
                                                                              title: Text(
                                                                                  'already picked!'),
                                                                              actions: [
                                                                                TextButton(
                                                                                  onPressed: () =>
                                                                                      Navigator.pop(alertDialogContext),
                                                                                  child:
                                                                                      Text('Ok'),
                                                                                ),
                                                                              ],
                                                                            );
                                                                          },
                                                                        );
                                                                        return;
                                                                      } else {
                                                                        ScaffoldMessenger.of(
                                                                                context)
                                                                            .showSnackBar(
                                                                          SnackBar(
                                                                            content:
                                                                                Text(
                                                                              gameItem[
                                                                                  "abbreviation2"],
                                                                              style:
                                                                                  TextStyle(
                                                                                color: Colors
                                                                                    .white,
                                                                                fontSize:
                                                                                    24,
                                                                              ),
                                                                            ),
                                                                            duration: Duration(
                                                                                milliseconds:
                                                                                    500),
                                                                            backgroundColor:
                                                                                Color(
                                                                                    0x85114802),
                                                                          ),
                                                                        );
                                                                      }
                                                                      dataProvider
                                                                          .removeFromPlayerPicks(
                                                                              gameItem[
                                                                                  "abbreviation"]);
                                                                      dataProvider
                                                                          .addToPlayerPicks(
                                                                              gameItem[
                                                                                  "abbreviation2"]);
                                                                    },
                                                                    child: Row(
                                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                                      mainAxisSize: MainAxisSize.min,
                                                                      children: [
                                                                        Text(
                                                                          gameItem[
                                                                              "abbreviation2"],
                                                                          style: TextStyle(
                                                                              fontWeight:
                                                                                  FontWeight
                                                                                      .bold,
                                                                              color: Colors
                                                                                  .white),
                                                                        ),
                                                                        if (dataProvider
                                                                                .playerPicks!
                                                                                .contains(gameItem[
                                                                                    "abbreviation2"]))
                                                                          Padding(
                                                                            padding: EdgeInsets.only(left: 4),
                                                                            child: Icon(
                                                                                Icons
                                                                                    .check,
                                                                                color: Colors
                                                                                    .white,
                                                                                size: 16),
                                                                          ),
                                                                      ],
                                                                    ),
                                                                    style: ButtonStyle(
                                                                      padding: MaterialStateProperty.all(
                                                                          EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
                                                                      backgroundColor:
                                                                          MaterialStateProperty
                                                                              .all(Color(
                                                                                  0x733474E0)),
                                                                      foregroundColor:
                                                                          MaterialStateProperty
                                                                              .all(Color(
                                                                                  0xFFFFFFFF)),
                                                                      textStyle:
                                                                          MaterialStateProperty
                                                                              .all(
                                                                                  TextStyle(
                                                                        fontFamily:
                                                                            'Poppins',
                                                                        color: Colors
                                                                            .white,
                                                                        fontSize: 12,
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
                                                                                    20),
                                                                      )),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                          Expanded(
                                                            flex: 1,
                                                            child: Column(
                                                              mainAxisAlignment: MainAxisAlignment.center,
                                                              children: [
                                                                Text(
                                                                  'AT',
                                                                  textAlign: TextAlign.center,
                                                                  style: TextStyle(
                                                                    fontWeight: FontWeight.bold,
                                                                    fontSize: 12,
                                                                  ),
                                                                ),
                                                                SizedBox(height: 4),
                                                                Text(
                                                                  gameItem["time"] ?? 'TBD',
                                                                  textAlign: TextAlign.center,
                                                                  style: TextStyle(
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                      fontSize:
                                                                          10),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                          Expanded(
                                                            flex: 2,
                                                            child: Column(
                                                              children: [
                                                                TeamLogo(
                                                                  abbr: gameItem["abbreviation"] ?? '',
                                                                  size: 40,
                                                                ),
                                                                SizedBox(height: 8),
                                                                Text(
                                                                  gameItem["home"] ?? gameItem["abbreviation"] ?? '',
                                                                  textAlign: TextAlign.center,
                                                                  style: TextStyle(
                                                                    fontSize: 12,
                                                                    fontWeight: FontWeight.w500,
                                                                  ),
                                                                ),
                                                                SizedBox(height: 4),
                                                                Container(
                                                                  width: 90,
                                                                  child: TextButton(
                                                                    onPressed: () async {
                                                                      if (dataProvider
                                                                          .playerPicks!
                                                                          .contains(
                                                                              gameItem[
                                                                                  "abbreviation"])) {
                                                                        await showDialog(
                                                                          context:
                                                                              context,
                                                                          builder:
                                                                              (alertDialogContext) {
                                                                            return AlertDialog(
                                                                              title: Text(
                                                                                  'already picked!'),
                                                                              actions: [
                                                                                TextButton(
                                                                                  onPressed: () =>
                                                                                      Navigator.pop(alertDialogContext),
                                                                                  child:
                                                                                      Text('Ok'),
                                                                                ),
                                                                              ],
                                                                            );
                                                                          },
                                                                        );
                                                                        return;
                                                                      } else {
                                                                        ScaffoldMessenger.of(
                                                                                context)
                                                                            .showSnackBar(
                                                                          SnackBar(
                                                                            content:
                                                                                Text(
                                                                              gameItem[
                                                                                  "abbreviation"],
                                                                              style:
                                                                                  TextStyle(
                                                                                color: Colors
                                                                                    .white,
                                                                                fontSize:
                                                                                    24,
                                                                              ),
                                                                            ),
                                                                            duration: Duration(
                                                                                milliseconds:
                                                                                    500),
                                                                            backgroundColor:
                                                                                Color(
                                                                                    0x85114802),
                                                                          ),
                                                                        );
                                                                      }
                                                                      dataProvider
                                                                          .removeFromPlayerPicks(
                                                                              gameItem[
                                                                                  "abbreviation2"]);
                                                                      dataProvider
                                                                          .addToPlayerPicks(
                                                                              gameItem[
                                                                                  "abbreviation"]);
                                                                    },
                                                                    child: Row(
                                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                                      mainAxisSize: MainAxisSize.min,
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
                                                                        if (dataProvider
                                                                                .playerPicks!
                                                                                .contains(gameItem[
                                                                                    "abbreviation"]))
                                                                          Padding(
                                                                            padding: EdgeInsets.only(left: 4),
                                                                            child: Icon(
                                                                                Icons
                                                                                    .check,
                                                                                color: Colors
                                                                                    .white,
                                                                                size: 16),
                                                                          ),
                                                                      ],
                                                                    ),
                                                                    style: ButtonStyle(
                                                                      padding: MaterialStateProperty.all(
                                                                          EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
                                                                      backgroundColor:
                                                                          MaterialStateProperty
                                                                              .all(Color(
                                                                                  0x733474E0)),
                                                                      foregroundColor:
                                                                          MaterialStateProperty
                                                                              .all(Color(
                                                                                  0xFFFFFFFF)),
                                                                      textStyle:
                                                                          MaterialStateProperty
                                                                              .all(
                                                                                  TextStyle(
                                                                        fontFamily:
                                                                            'Poppins',
                                                                        color: Colors
                                                                            .white,
                                                                        fontSize: 12,
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
                                                                                    20),
                                                                      )),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ],
                                                       ),
                                                       SizedBox(height: 8),
                                                       Text(
                                                         () {
                                                           // Check if any team from this game is picked
                                                           if (dataProvider.playerPicks!.contains(gameItem["abbreviation"])) {
                                                             return 'PICKED: ${gameItem["home"] ?? gameItem["abbreviation"]}';
                                                           } else if (dataProvider.playerPicks!.contains(gameItem["abbreviation2"])) {
                                                             return 'PICKED: ${gameItem["away"] ?? gameItem["abbreviation2"]}';
                                                           } else {
                                                             return 'MAKE THE PICK!';
                                                           }
                                                         }(),
                                                         textAlign: TextAlign.center,
                                                         style: TextStyle(
                                                           fontWeight: FontWeight.bold,
                                                           fontSize: 12,
                                                           color: (dataProvider.playerPicks!.contains(gameItem["abbreviation"]) || 
                                                                  dataProvider.playerPicks!.contains(gameItem["abbreviation2"])) 
                                                                  ? Color(0xFF27512F) 
                                                                  : Colors.black,
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
              Align(
                alignment: AlignmentDirectional(0, 0.9),
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  height: 75,
                  decoration: BoxDecoration(
                    color: Color(0xDD92EF7B),
                  ),
                  child: Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(0, 5, 0, 0),
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            InkWell(
                              onTap: () {
                                // scaffoldKey.currentState!
                                //     .showBottomSheet((context) {
                                //   return  RulesWidget();
                                // });
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => RulesWidget(),
                                  ),
                                );
                              },
                              child: Container(
                                  height: 50,
                                  width: 50,
                                  child: Image.asset(
                                      "assets/images/rulebook.png")),
                            ),
                            Container(
                              width: 110,
                              decoration: BoxDecoration(),
                              child: TextFormField(
                                controller: tieBreakerController,
                                obscureText: false,
                                decoration: InputDecoration(
                                  hintText: 'Tie Breaker',
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Colors.white,
                                      width: 0.5,
                                    ),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Colors.white,
                                      width: 0.5,
                                    ),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Colors.white,
                                      width: 0.5,
                                    ),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Colors.white,
                                      width: 0.5,
                                    ),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  filled: true,
                                  fillColor: Color(0xC8DADADA),
                                  contentPadding:
                                      EdgeInsetsDirectional.fromSTEB(
                                          10, 0, 0, 0),
                                ),
                                // style: FlutterFlowTheme.of(context)
                                //     .bodyMedium
                                //     .override(
                                //   fontFamily: 'Poppins',
                                //   fontSize: 11,
                                // ),
                                keyboardType: TextInputType.number,
                                // validator: _model.tieBreakerControllerValidator
                                //     .asValidator(context),
                              ),
                            ),
                            TextButton(
                              // borderColor: Colors.transparent,
                              // borderRadius: 30,
                              // borderWidth: 1,
                              // buttonSize: 60,
                              // fillColor: Color(0xFF02B902),
                              child: Container(
                                  height: 50,
                                  width: 50,
                                  child:
                                      Image.asset("assets/images/checked.png")),
                              onPressed: () async {
                                var _shouldSetState = false;
                                if (tieBreakerController.text == null ||
                                    tieBreakerController.text == '') {
                                  await showDialog(
                                    context: context,
                                    builder: (alertDialogContext) {
                                      return AlertDialog(
                                        content:
                                            Text('enter tie breaker score'),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            child: Text('Ok'),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                  // if (_shouldSetState) setState(() {});
                                  // return;
                                } else if (!_validateAllGamesPicked()) {
                                  await showDialog(
                                    context: context,
                                    builder: (alertDialogContext) {
                                      return AlertDialog(
                                        content: Text(
                                            'some games have not been picked'),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            child: Text('Ok'),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                } else {
                                  // FFAppState().update(() {
                                  dataProvider.tiebreaker =
                                      int.parse(tieBreakerController.text);
                                  // });
                                  dataProvider.amount =
                                      await dataProvider.countGames(
                                    dataProvider.playerPicks!.toList(),
                                  );
                                  _shouldSetState = true;

                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => PlayerPicksWidget(),
                                    ),
                                  );
                                  if (_shouldSetState) setState(() {});
                                }
                              },
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
        ));
  }

  bool _validateAllGamesPicked() {
    DataProvider dataProvider = Provider.of<DataProvider>(context, listen: false);
    
    // Debug logging
    print('Validating picks: ${dataProvider.playerPicks}');
    print('Total picks: ${dataProvider.playerPicks!.length}');
    print('Expected games: ${data!.length}');
    
    if (dataProvider.playerPicks == null || dataProvider.playerPicks!.isEmpty) {
      print('No picks found');
      return false;
    }
    
    // Get all valid team names from the actual game data
    Set<String> allValidTeams = {};
    for (var game in data!) {
      // Add both abbreviations and full team names from the game data
      if (game['abbreviation'] != null) allValidTeams.add(game['abbreviation'].toString().trim());
      if (game['abbreviation2'] != null) allValidTeams.add(game['abbreviation2'].toString().trim());
      if (game['home'] != null) allValidTeams.add(game['home'].toString().trim());
      if (game['away'] != null) allValidTeams.add(game['away'].toString().trim());
    }
    
    print('All valid teams from game data: ${allValidTeams.toList()}');
    
    // Remove duplicates and clean up the picks list
    Set<String> uniquePicks = {};
    for (String pick in dataProvider.playerPicks!) {
      String cleanPick = pick.trim();
      // Only add if this team is actually in the valid teams
      if (allValidTeams.contains(cleanPick)) {
        uniquePicks.add(cleanPick);
      }
    }
    
    print('Valid unique picks: ${uniquePicks.toList()}');
    print('Unique picks count: ${uniquePicks.length}');
    print('Games to pick: ${data!.length}');
    
    // Check if we have exactly one pick per game
    bool isValid = uniquePicks.length == data!.length;
    
    print('Validation result: $isValid');
    
    return isValid;
  }
}
