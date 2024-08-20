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
import '../../../Provider/AuthProviders.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
      tiebreaker = int.parse(data![(data!.length - 1)]["score"]) +
          int.parse(data![(data!.length - 1)]["score2"]);
    });
    return body;
  }

  Future getGameWinner(context) async {
    DataProvider dataProvider =
        Provider.of<DataProvider>(context, listen: false);
    AuthProviders authProvider =
        Provider.of<AuthProviders>(context, listen: false);
    var response = await http.get(
        Uri.parse(
            '${mainUrl}/get_winners/${dataProvider.game!["mode"]}${widget.selectedValue}'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Access-Control-Allow-Origin': '*',
        }).timeout(Duration(seconds: 20));
    var body = json.decode(response.body);
    // print(body);
    // print(body);
    List body1 = body["winners"];
    setState(() {
      winners = body1;
      // tiebreaker = int.parse(data![(data!.length-1)]["score"])+int.parse(data![(data!.length-1)]["score2"]);
    });
    return body;
  }

  Stream<QuerySnapshot>? _pickrecord;
  Stream<QuerySnapshot>? _pickrecordStream;

  @override
  void initState() {
    super.initState();
    DataProvider dataProvider =
        Provider.of<DataProvider>(context, listen: false);
    AuthProviders authProvider =
        Provider.of<AuthProviders>(context, listen: false);
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
    getGame(context);
    getGameWinner(context);
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
                          for (var document in snapshot2.data!.docs) {
                            new_data = document["picks"];
                            new_data2 = document;
                          }
                          value = true;
                        }

                        !value ? runFunction() : null;
                        // print(new_data);
                        //  print(new_data);

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
                                      // future: getGame(),
                                      builder: (context) {
                                        // Customize what your widget looks like when it's loading.
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
                                        final listViewGetScheduleResponse =
                                            data;
                                        // print(data);
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                              bottom: 70.0),
                                          child: Builder(
                                            builder: (context) {
                                              // dataProvider.formatStringDate(element['date'])
                                              final game =
                                                  listViewGetScheduleResponse;
                                              // game!.sort((a, b) => dataProvider.formatStringDate(a['date']).compareTo(dataProvider.formatStringDate(b["date"])));
                                              return
                                                  // dataProvider.formatStringDate(element['date']).toString(),

                                                  GroupedListView<dynamic,
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
                                                  // final gameItem = game[gameIndex];
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
                                                            color: Color(
                                                                    0x96E87D)
                                                                .withOpacity(
                                                                    0.8),
                                                          ),
                                                          child: Padding(
                                                            padding:
                                                                EdgeInsetsDirectional
                                                                    .fromSTEB(
                                                                        0,
                                                                        5,
                                                                        0,
                                                                        5),
                                                            child: Row(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .max,
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .start,
                                                              children: [
                                                                Expanded(
                                                                  child: Column(
                                                                    mainAxisSize:
                                                                        MainAxisSize
                                                                            .max,
                                                                    crossAxisAlignment:
                                                                        CrossAxisAlignment
                                                                            .center,
                                                                    children: [
                                                                      Row(
                                                                        mainAxisSize:
                                                                            MainAxisSize.max,
                                                                        mainAxisAlignment:
                                                                            MainAxisAlignment.center,
                                                                        children: [
                                                                          Text(
                                                                            'GAME: ',
                                                                            textAlign:
                                                                                TextAlign.center,
                                                                            style:
                                                                                TextStyle(
                                                                              fontFamily: 'Poppins',
                                                                              color: Color(0xFF27512F),
                                                                              fontSize: 10,
                                                                              fontWeight: FontWeight.bold,
                                                                            ),
                                                                          ),
                                                                          Text(
                                                                            (index + 1).toString(),
                                                                            style:
                                                                                TextStyle(
                                                                              fontFamily: 'Poppins',
                                                                              fontSize: 10,
                                                                            ),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                      Row(
                                                                        mainAxisSize:
                                                                            MainAxisSize.max,
                                                                        mainAxisAlignment:
                                                                            MainAxisAlignment.spaceEvenly,
                                                                        children: [
                                                                          SvgPicture.network(
                                                                              gameItem["picture"],
                                                                              width: 40,
                                                                              height: 40,
                                                                              placeholderBuilder: (BuildContext context) => Container()),
                                                                          TextButton(
                                                                            onPressed:
                                                                                () async {
                                                                              print(winners);
                                                                              print(new_data);
                                                                            },
                                                                            child:
                                                                                Row(
                                                                              children: [
                                                                                Text(
                                                                                  gameItem["abbreviation"],
                                                                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                                                                                ),
                                                                                new_data.contains(gameItem["abbreviation"])
                                                                                    ? winners!.contains(gameItem["abbreviation"])
                                                                                        ? Icon(Icons.check, color: Colors.white)
                                                                                        : Icon(Icons.close, color: Colors.red)
                                                                                    : Container()
                                                                              ],
                                                                            ),
                                                                            style:
                                                                                ButtonStyle(
                                                                              padding: MaterialStateProperty.all(EdgeInsetsDirectional.fromSTEB(35, 5, 35, 5)),
                                                                              backgroundColor: MaterialStateProperty.all(Color(0x733474E0)),
                                                                              foregroundColor: MaterialStateProperty.all(Color(0x733474E0)),
                                                                              textStyle: MaterialStateProperty.all(TextStyle(
                                                                                fontFamily: 'Poppins',
                                                                                color: Colors.white,
                                                                              )),
                                                                              elevation: MaterialStateProperty.all(2),
                                                                              shape: MaterialStateProperty.all(RoundedRectangleBorder(
                                                                                side: BorderSide(
                                                                                  color: Colors.transparent,
                                                                                  width: 1,
                                                                                ),
                                                                                borderRadius: BorderRadius.circular(30),
                                                                              )),
                                                                            ),
                                                                          ),
                                                                          Padding(
                                                                            padding: EdgeInsetsDirectional.fromSTEB(
                                                                                5,
                                                                                0,
                                                                                5,
                                                                                0),
                                                                            child:
                                                                                Text(
                                                                              'AT',
                                                                              // style: FlutterFlowTheme
                                                                              //     .of(context)
                                                                              //     .bodyMedium,
                                                                            ),
                                                                          ),
                                                                          TextButton(
                                                                              style: ButtonStyle(
                                                                                padding: MaterialStateProperty.all(EdgeInsetsDirectional.fromSTEB(35, 5, 35, 5)),
                                                                                backgroundColor: MaterialStateProperty.all(Color(0x733474E0)),
                                                                                foregroundColor: MaterialStateProperty.all(Color(0x733474E0)),
                                                                                textStyle: MaterialStateProperty.all(TextStyle(
                                                                                  fontFamily: 'Poppins',
                                                                                  color: Colors.white,
                                                                                )),
                                                                                elevation: MaterialStateProperty.all(2),
                                                                                shape: MaterialStateProperty.all(RoundedRectangleBorder(
                                                                                  side: BorderSide(
                                                                                    color: Colors.transparent,
                                                                                    width: 1,
                                                                                  ),
                                                                                  borderRadius: BorderRadius.circular(30),
                                                                                )),
                                                                              ),
                                                                              onPressed: () async {},
                                                                              child: Center(
                                                                                child: Row(
                                                                                  children: [
                                                                                    Text(
                                                                                      gameItem["abbreviation2"],
                                                                                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                                                                                    ),
                                                                                    // new_data.contains(gameItem["abbreviation2"])
                                                                                    //     ? Icon(Icons.check, color: Colors.white)
                                                                                    //     : Container()

                                                                                    new_data.contains(gameItem["abbreviation2"])
                                                                                        ? winners!.contains(gameItem["abbreviation2"])
                                                                                            ? Icon(Icons.check, color: Colors.white)
                                                                                            : Icon(Icons.close, color: Colors.red)
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
                                                                              gameItem["picture2"],
                                                                              width: 40,
                                                                              height: 40,
                                                                              placeholderBuilder: (BuildContext context) => Container()),
                                                                        ],
                                                                      ),
                                                                      // if (FFAppState().picked !=
                                                                      //     null)
                                                                      Row(
                                                                        mainAxisAlignment:
                                                                            MainAxisAlignment.center,
                                                                        children: [
                                                                          new_data.contains(gameItem["abbreviation"])
                                                                              ? winners!.contains(gameItem["abbreviation"])
                                                                                  ? Text(
                                                                                      'CORRECT',
                                                                                      style: TextStyle(
                                                                                        fontFamily: 'Poppins',
                                                                                        color: Color(0xFF27512F),
                                                                                        fontSize: 10,
                                                                                        fontWeight: FontWeight.bold,
                                                                                      ),
                                                                                    )
                                                                                  : Text(
                                                                                      'INCORRECT',
                                                                                      style: TextStyle(
                                                                                        fontFamily: 'Poppins',
                                                                                        color: Color(0xFF27512F),
                                                                                        fontSize: 10,
                                                                                        fontWeight: FontWeight.bold,
                                                                                      ),
                                                                                    )
                                                                              : Container(),
                                                                          new_data.contains(gameItem["abbreviation2"])
                                                                              ? winners!.contains(gameItem["abbreviation2"])
                                                                                  ? Text(
                                                                                      'CORRECT',
                                                                                      style: TextStyle(
                                                                                        fontFamily: 'Poppins',
                                                                                        color: Color(0xFF27512F),
                                                                                        fontSize: 10,
                                                                                        fontWeight: FontWeight.bold,
                                                                                      ),
                                                                                    )
                                                                                  : Text(
                                                                                      'INCORRECT',
                                                                                      style: TextStyle(
                                                                                        fontFamily: 'Poppins',
                                                                                        color: Color(0xFF27512F),
                                                                                        fontSize: 10,
                                                                                        fontWeight: FontWeight.bold,
                                                                                      ),
                                                                                    )
                                                                              : Container()
                                                                        ],
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
                                                // optional
                                                useStickyGroupSeparators: true,
                                                // optional
                                                floatingHeader: true,
                                                // optional
                                                order: GroupedListOrder
                                                    .ASC, // optional
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
                                                      "${new_data2!["tiebreaker"]}",
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
                                                // style: FlutterFlowTheme.of(context)
                                                //     .bodyMedium
                                                //     .override(
                                                //   fontFamily: 'Poppins',
                                                //   fontSize: 11,
                                                // ),
                                                keyboardType:
                                                    TextInputType.number,
                                                // validator: _model.tieBreakerControllerValidator
                                                //     .asValidator(context),
                                              ),
                                            ),
                                            Text(
                                              'Game Tie Breaker:',
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
                                                // style: FlutterFlowTheme.of(context)
                                                //     .bodyMedium
                                                //     .override(
                                                //   fontFamily: 'Poppins',
                                                //   fontSize: 11,
                                                // ),
                                                keyboardType:
                                                    TextInputType.number,
                                                // validator: _model.tieBreakerControllerValidator
                                                //     .asValidator(context),
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
