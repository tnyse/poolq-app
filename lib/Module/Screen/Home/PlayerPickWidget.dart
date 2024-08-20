import 'dart:convert';
import 'HomePage.dart';
import 'LeaderbpardWidget.dart';
import 'package:flutter/material.dart';
import '../../../Constants/value.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:poolqapp/Widget/reuse.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:poolqapp/Provider/homeProvider.dart';
import 'package:poolqapp/Provider/AuthProviders.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:poolqapp/Module/Screen/Home/webPayment.dart';

class PlayerPicksWidget extends StatefulWidget {
  const PlayerPicksWidget({
    this.edit,
    this.pick,
    this.id,
  });

  final bool? edit;
  final String? id;
  final String? pick;

  @override
  _PlayerPicksWidgetState createState() => _PlayerPicksWidgetState();
}

class _PlayerPicksWidgetState extends State<PlayerPicksWidget> {
  // late PlayerPicksModel _model;
  User? user = FirebaseAuth.instance.currentUser;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final _unfocusNode = FocusNode();
  Stream<QuerySnapshot>? _pickrecord;
  Stream<DocumentSnapshot>? paymentMethod;
  @override
  void initState() {
    DataProvider dataProvider =
        Provider.of<DataProvider>(context, listen: false);
    _pickrecord = FirebaseFirestore.instance
        .collection('pickrecord')
        .where("uid", isEqualTo: user!.uid)
        .where("week", isEqualTo: dataProvider.game!["name"])
        .snapshots();

    paymentMethod = FirebaseFirestore.instance
        .collection('paymentMethod')
        .doc(user!.uid)
        .snapshots();
    super.initState();
    // _model = createModel(context, () => PlayerPicksModel());
  }

  Map<String, dynamic>? paymentIntent;
  @override
  void dispose() {
    // _model.dispose();

    _unfocusNode.dispose();
    super.dispose();
  }

  List? data;
  Future calculateScore(context) async {
    var response =
        await http.get(Uri.parse('${mainUrl}/calculate_score'), headers: {
      'Content-Type': 'application/json; charset=UTF-8',
      'Access-Control-Allow-Origin': '*',
    }).timeout(Duration(seconds: 20));
    var body = json.decode(response.body);
    // print(body);
    // print(body);
    // print();
    if (body.runtimeType.toString() == "_Map<String, dynamic>") {
      Map body1 = body;
      // setState(() {
      //   data = body1;
      // });
      return body;
    } else {
      List body1 = body;
      setState(() {
        data = body1;
      });
      return body;
    }
    // if(body.runtimeType.toString() == )
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
          key: scaffoldKey,
          backgroundColor: Color(0xFFF5F5F5),
          appBar: AppBar(
            backgroundColor: primary,
            automaticallyImplyLeading: true,
            actions: [],
            centerTitle: true,
            elevation: 4,
          ),
          body: StreamBuilder<QuerySnapshot>(
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

                return StreamBuilder<DocumentSnapshot>(
                    stream: paymentMethod,
                    builder: (BuildContext context,
                        AsyncSnapshot<DocumentSnapshot> snapshot2) {
                      if (snapshot2.hasError) {
                        return Center(child: Text('Something went wrong'));
                      }

                      if (snapshot2.connectionState ==
                              ConnectionState.waiting ||
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

                      return Column(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Stack(
                            children: [
                              Padding(
                                padding:
                                    EdgeInsetsDirectional.fromSTEB(0, 20, 0, 0),
                                child: Row(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          0, 20, 0, 0),
                                      child: Image.asset(
                                        'assets/images/poolq12.png',
                                        width: 67,
                                        height: 90,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          20, 20, 0, 0),
                                      child: Text(
                                        'Leaderboard week ',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 18,
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          5, 20, 0, 0),
                                      child: Text(
                                        '1',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 30,
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
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    16, 0, 16, 20),
                                child: Row(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Hello, ${user!.displayName}',
                                      style: TextStyle(
                                        fontFamily: 'Lexend Deca',
                                        color: Color(0xFF090F13),
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    InkWell(
                                      splashColor: Colors.transparent,
                                      focusColor: Colors.transparent,
                                      hoverColor: Colors.transparent,
                                      highlightColor: Colors.transparent,
                                      onTap: () async {
                                        scaffoldKey.currentState!.openDrawer();
                                      },
                                      child: Container(
                                        width: 50,
                                        height: 50,
                                        clipBehavior: Clip.antiAlias,
                                        decoration: BoxDecoration(
                                          border:
                                              Border.all(color: Colors.black45),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: CircleAvatar(
                                            foregroundColor: Colors.white,
                                            backgroundColor: Colors.white,
                                            radius: 47,
                                            backgroundImage: authProvider.image
                                                        .toString() ==
                                                    ""
                                                ? AssetImage(
                                                    "assets/images/user.png")
                                                : NetworkImage(authProvider
                                                        .image
                                                        .toString())
                                                    as ImageProvider,
                                          ),
                                        ),
                                      ),
                                    ),
                                    // SizedBox(
                                    //   // borderWidth: 1,
                                    //   // buttonSize: 60,
                                    //   child: TextButton(
                                    //     style: ButtonStyle(
                                    //       // borderColor: Colors.transparent,
                                    //       // borderRadius: 30,
                                    //     ),
                                    //
                                    //     child: Icon(
                                    //       Icons.check,
                                    //       color: Color(0xFF049304),
                                    //       size: 30,
                                    //     ),
                                    //     onPressed: () async {
                                    //       await Navigator.push(
                                    //         context,
                                    //         MaterialPageRoute(
                                    //           builder: (context) => LeaderboardWidget(),
                                    //         ),
                                    //       );
                                    //     },
                                    //   ),
                                    // ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    16, 0, 16, 0),
                                child: Row(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          2, 0, 0, 0),
                                      child: Text(
                                        'Picks',
                                        style: TextStyle(
                                          fontFamily: 'Lexend Deca',
                                          color: Color(0xFF4B39EF),
                                          fontSize: 32,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding:
                                    EdgeInsetsDirectional.fromSTEB(0, 0, 0, 20),
                                child: Text(
                                  '',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    // color: Color(0xFFD30909),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Container(
                            width: MediaQuery.of(context).size.width,
                            decoration: BoxDecoration(
                              color: Color(0xFFEEEEEE),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Wrap(
                                    children: dataProvider.playerPicks!
                                        .asMap()
                                        .entries
                                        .map((e) => Container(
                                              decoration: BoxDecoration(
                                                  // color: FlutterFlowTheme.of(context)
                                                  //     .secondaryBackground,
                                                  ),
                                              child: Text(
                                                e.value,
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontFamily: 'Poppins',
                                                  fontSize: 18,
                                                ),
                                              ),
                                            ))
                                        .toList()),
                                // Builder(
                                //   builder: (context) {
                                //     final pickList =
                                //     dataProvider.playerPicks!.map((e) => e).toList();
                                //     return ListView.builder(
                                //       padding: EdgeInsets.zero,
                                //       shrinkWrap: true,
                                //       scrollDirection: Axis.vertical,
                                //       itemCount: pickList.length,
                                //       itemBuilder: (context, pickListIndex) {
                                //         final pickListItem = pickList[pickListIndex];
                                //         return Container(
                                //           decoration: BoxDecoration(
                                //             // color: FlutterFlowTheme.of(context)
                                //             //     .secondaryBackground,
                                //           ),
                                //           child: Text(
                                //             pickListItem,
                                //             textAlign: TextAlign.center,
                                //             style:TextStyle(
                                //               fontFamily: 'Poppins',
                                //               fontSize: 18,
                                //             ),
                                //           ),
                                //         );
                                //       },
                                //     );
                                //   },
                                // ),
                                Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      0, 20, 0, 0),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.max,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Tie Breaker total - ',
                                        // style: FlutterFlowTheme.of(context).bodyMedium,
                                      ),
                                      Text(
                                        dataProvider.tiebreaker.toString(),
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 18,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      0, 40, 0, 0),
                                  child: SizedBox(
                                    width: 130,
                                    height: 40,
                                    child: TextButton(
                                      onPressed: () async {
                                        if (snapshot2.data!.data().toString() ==
                                            "null") {
                                          // customSnackbar(context, 'Setup payment method in your profile.');
                                          showModalBottomSheet(
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.only(
                                                  topLeft: Radius.circular(10),
                                                  topRight:
                                                      Radius.circular(10)),
                                            ),
                                            backgroundColor: Colors.white,
                                            context: context,
                                            builder: (BuildContext context) {
                                              return Padding(
                                                padding: EdgeInsets.only(
                                                    bottom:
                                                        MediaQuery.of(context)
                                                            .viewInsets
                                                            .bottom),
                                                child: Container(
                                                  width: MediaQuery.of(context)
                                                      .size
                                                      .width,
                                                  height: 220,
                                                  child: Column(
                                                    children: [
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(8.0),
                                                        child: Align(
                                                          alignment: Alignment
                                                              .topCenter,
                                                          child: Container(
                                                            width: 60,
                                                            height: 5,
                                                            decoration: BoxDecoration(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            5),
                                                                color: Colors
                                                                    .black12),
                                                          ),
                                                        ),
                                                      ),
                                                      Padding(
                                                        padding:
                                                            EdgeInsetsDirectional
                                                                .fromSTEB(10,
                                                                    30, 10, 16),
                                                        child: Container(
                                                          width:
                                                              double.infinity,
                                                          child: Center(
                                                              child: Text(
                                                            "Setup payment method in your profile.",
                                                            style: TextStyle(
                                                                fontSize: 18,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold),
                                                            textAlign: TextAlign
                                                                .center,
                                                          )),
                                                        ),
                                                      ),
                                                      Align(
                                                        alignment:
                                                            Alignment.center,
                                                        child: Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .only(
                                                                  top: 10.0,
                                                                  bottom: 0,
                                                                  right: 0),
                                                          child: ElevatedButton(
                                                            style: ButtonStyle(
                                                                elevation:
                                                                    MaterialStateProperty
                                                                        .all(0),
                                                                backgroundColor:
                                                                    MaterialStateProperty
                                                                        .all(Color(
                                                                            0xFF063a73)),
                                                                shape: MaterialStateProperty.all<
                                                                        RoundedRectangleBorder>(
                                                                    RoundedRectangleBorder(
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              50.0),
                                                                ))),
                                                            child: Container(
                                                              width: MediaQuery.of(
                                                                          context)
                                                                      .size
                                                                      .width *
                                                                  0.7,
                                                              height: 45,
                                                              alignment:
                                                                  Alignment
                                                                      .center,
                                                              decoration: BoxDecoration(
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              50)),
                                                              child: Text(
                                                                'Continue',
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        14,
                                                                    color: Colors
                                                                        .white),
                                                              ),
                                                            ),
                                                            onPressed:
                                                                () async {
                                                              Navigator.pop(
                                                                  context);
                                                              Navigator.push(
                                                                  context,
                                                                  MaterialPageRoute(
                                                                    builder: (context) =>
                                                                        HomePage(
                                                                            initial:
                                                                                2),
                                                                  ));
                                                            },
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            },
                                          );
                                        } else {
                                          if (widget.edit == true) {
                                            circularCustom(context);
                                            final picksCreateData = {
                                              "week":
                                                  dataProvider.game!["name"],
                                              "tiebreaker": dataProvider
                                                  .tiebreaker
                                                  .toString(),
                                              'date':
                                                  FieldValue.serverTimestamp(),
                                              'picks': dataProvider.playerPicks,
                                              'uid': user!.uid,
                                              "displayName": user!.displayName,
                                              "photoURL": user!.photoURL,
                                            };
                                            CollectionReference pickrecord =
                                                FirebaseFirestore.instance
                                                    .collection('pickrecord');
                                            await pickrecord
                                                .doc(widget.id)
                                                .update(picksCreateData);
                                            await calculateScore(context);
                                            // ${mainUrl}/calculate_score
                                            Navigator.pop(context);
                                            Navigator.pop(context);
                                            Navigator.pop(context);
                                          } else if (!snapshot
                                              .data!.docs.isEmpty) {
                                            customSnackbar(context,
                                                'You have already submited picks for week ${dataProvider.game!["name"].toString().replaceAll("REG", "").replaceAll("PRE", "")}');
                                          } else {
                                            if (dataProvider.game != null) {
                                              circularCustom(context);
                                              await makePayment();
                                              // Navigator.push(
                                              //   context,
                                              //   PageRouteBuilder(
                                              //     pageBuilder: (context, animation, secondaryAnimation) {
                                              //       return WebViewExample();
                                              //       // HomePageWidget();
                                              //     },
                                              //     transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                              //       return FadeTransition(
                                              //         opacity: animation,
                                              //         child: child,
                                              //       );
                                              //     },
                                              //   ),
                                              //       // (route) => false,
                                              // );
                                            }
                                          }
                                        }
                                      },
                                      child: Text(
                                        "${widget.edit == true ? "save" : "submit"}",
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      style: ButtonStyle(
                                          padding: MaterialStateProperty.all(
                                              EdgeInsetsDirectional.fromSTEB(
                                                  0, 0, 0, 0)),
                                          // iconPadding: EdgeInsetsDirectional.fromSTEB(0, 0, 0, 0),
                                          backgroundColor:
                                              MaterialStateProperty.all(
                                                  primary),
                                          textStyle: MaterialStateProperty.all(
                                              TextStyle(
                                            fontFamily: 'Poppins',
                                            color: Colors.white,
                                          )),
                                          elevation:
                                              MaterialStateProperty.all(2),
                                          shape: MaterialStateProperty.all(
                                              RoundedRectangleBorder(
                                            side: BorderSide(
                                              color: Colors.transparent,
                                              width: 1,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(30),
                                          ))),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    });
              })),
    );
  }

  Future<void> makePayment() async {
    try {
      paymentIntent = await createPaymentIntent('5', 'USD');

      //STEP 2: Initialize Payment Sheet
      await Stripe.instance
          .initPaymentSheet(
              paymentSheetParameters: SetupPaymentSheetParameters(
                  paymentIntentClientSecret: paymentIntent![
                      'client_secret'], //Gotten from payment intent
                  style: ThemeMode.dark,
                  merchantDisplayName: 'Ikay'))
          .then((value) {});
      Navigator.pop(context);
      //STEP 3: Display Payment sheet
      displayPaymentSheet();
    } catch (err) {
      throw Exception(err);
    }
  }

  displayPaymentSheet() async {
    DataProvider dataProvider =
        Provider.of<DataProvider>(context, listen: false);
    try {
      await Stripe.instance.presentPaymentSheet().then((value) async {
        circularCustom(context);
        final picksCreateData = {
          "week": dataProvider.game!["name"],
          "tiebreaker": dataProvider.tiebreaker.toString(),
          'date': FieldValue.serverTimestamp(),
          'picks': dataProvider.playerPicks,
          'uid': user!.uid,
          "displayName": user!.displayName,
          "photoURL": user!.photoURL,
        };
        CollectionReference pickrecord =
            FirebaseFirestore.instance.collection('pickrecord');
        await pickrecord.add(picksCreateData);
        await calculateScore(context);
        // ${mainUrl}/calculate_score
        Navigator.pop(context);
        Navigator.pop(context);
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LeaderboardWidget(),
          ),
        );

        paymentIntent = null;
      }).onError((error, stackTrace) {
        throw Exception(error);
      });
    } on StripeException catch (e) {
      print('Error is:---> $e');
      AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: const [
                Icon(
                  Icons.cancel,
                  color: Colors.red,
                ),
                Text("Payment Failed"),
              ],
            ),
          ],
        ),
      );
    } catch (e) {
      print('$e');
    }
  }

  createPaymentIntent(String amount, String currency) async {
    try {
      //Request body
      Map<String, dynamic> body = {
        'amount': calculateAmount(amount),
        'currency': currency,
      };

      //Make post request to Stripe
      var response = await http.post(
        Uri.parse('https://api.stripe.com/v1/payment_intents'),
        headers: {
          'Authorization': 'Bearer ',
          'Content-Type': 'application/x-www-form-urlencoded'
        },
        body: body,
      );
      return json.decode(response.body);
    } catch (err) {
      throw Exception(err.toString());
    }
  }

  calculateAmount(String amount) {
    final calculatedAmout = (int.parse(amount)) * 100;
    return calculatedAmout.toString();
  }
}
