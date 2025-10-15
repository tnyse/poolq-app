import 'LeaderbpardWidget.dart';
import 'ManualPaymentScreen.dart';
import 'package:flutter/material.dart';
import '../../../constants.dart';
import 'package:provider/provider.dart';
import 'package:poolqapp/Widget/reuse.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:poolqapp/Provider/homeProvider.dart';
import '../../../services/simulation_controller.dart';
import '../../../Model/pick_model.dart';
import '../../../screens/results_announcement_page.dart';
import 'package:poolqapp/Provider/AuthProviders.dart';
import 'package:poolqapp/services/payment_service.dart';

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
  DataProvider? dataProvider;

  @override
  void initState() {
    super.initState();
    dataProvider = Provider.of<DataProvider>(context, listen: false);
    
    // Check if we're in demo mode
    if (user == null || user?.email == 'demo@poolq.com') {
      print('PlayerPicksWidget: Demo mode detected, skipping Firebase streams');
      // For demo mode, don't set up Firebase streams
      _pickrecord = Stream.empty();
      paymentMethod = Stream.empty();
    } else {
      // Only set up Firebase streams for real users
      if (user != null && dataProvider?.game != null) {
        _pickrecord = FirebaseFirestore.instance
            .collection('pickrecord')
            .where("uid", isEqualTo: user!.uid)
            .where("week", isEqualTo: dataProvider!.game!["name"])
            .snapshots();

        paymentMethod = FirebaseFirestore.instance
            .collection('paymentMethod')
            .doc(user!.uid)
            .snapshots();
      } else {
        _pickrecord = Stream.empty();
        paymentMethod = Stream.empty();
      }
    }
    // _model = createModel(context, () => PlayerPicksModel());
  }

  @override
  void dispose() {
    // _model.dispose();

    _unfocusNode.dispose();
    super.dispose();
  }

  List? data;
  Future calculateScore(context) async {
    // Removed mainUrl import and API call. Use only ESPN endpoints or mock data.
    // var response =
    //     await http.get(Uri.parse('${mainUrl}/calculate_score'), headers: {
    //   'Content-Type': 'application/json; charset=UTF-8',
    //   'Access-Control-Allow-Origin': '*',
    // }).timeout(Duration(seconds: 20));
    // var body = json.decode(response.body);
    // // print(body);
    // // print(body);
    // // print();
    // if (body.runtimeType.toString() == "_Map<String, dynamic>") {
    //   Map body1 = body;
    //   // setState(() {
    //   //   data = body1;
    //   // });
    //   return body;
    // } else {
    //   List body1 = body;
    //   setState(() {
    //     data = body1;
    //   });
    //   return body;
    // }
    // // if(body.runtimeType.toString() == )
  }

  @override
  Widget build(BuildContext context) {
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
                // Check if we're in demo mode
                if (user == null || user?.email == 'demo@poolq.com') {
                  print('PlayerPicksWidget: Demo mode detected, showing demo content');
                  return _buildDemoContent();
                }
                
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

                      return SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
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
                                          'Your Picks - Week ',
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
                                      'Hello, ${user?.displayName ?? 'Demo User'}',
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
                                        'Review Your Picks',
                                        style: TextStyle(
                                          fontFamily: 'Lexend Deca',
                                          color: Color(0xFF4B39EF),
                                          fontSize: 24,
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
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Color(0xFFEEEEEE),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Picks list
                                  ...((dataProvider?.playerPicks ?? []).asMap().entries.map((e) {
                                    final abbr = e.value;
                                    // Try to find the full team name from the schedule data
                                    String teamName = '';
                                    if (dataProvider?.data != null) {
                                      for (var game in dataProvider!.data!) {
                                        if (game['abbreviation'] == abbr) {
                                          teamName = game['home'] ?? '';
                                          break;
                                        } else if (game['abbreviation2'] == abbr) {
                                          teamName = game['away'] ?? '';
                                          break;
                                        }
                                      }
                                    }
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        children: [
                                          TeamLogo(abbr: abbr, size: 32),
                                          SizedBox(width: 12),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(abbr, style: TextStyle(fontFamily: 'Poppins', fontSize: 18)),
                                              if (teamName.isNotEmpty)
                                                Text(teamName, style: TextStyle(fontFamily: 'Poppins', fontSize: 14, color: Colors.grey[700])),
                                            ],
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList()),
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
                                        (dataProvider?.tiebreaker?.toString() ?? ""),
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
                                        print('Submit button pressed. Edit mode: ${widget.edit}');
                                        print('Snapshot docs count: ${snapshot.data!.docs.length}');
                                        
                                        if (widget.edit == true) {
                                          // Handle edit mode
                                          print('Going to edit mode');
                                          if (dataProvider != null) {
                                            await _saveExistingPicksEdit(context, dataProvider);
                                          }
                                        } else if (!snapshot.data!.docs.isEmpty) {
                                          print('User already has picks for this week');
                                          customSnackbar(context,
                                              'You have already submitted picks for week ${dataProvider?.game!["name"].toString().replaceAll("REG", "").replaceAll("PRE", "")}');
                                        } else {
                                          // Save picks and proceed to payment
                                          print('Going to save picks and proceed to payment');
                                          if (dataProvider != null) {
                                            await _savePicksAndProceedToPayment(context, dataProvider);
                                          } else {
                                            print('DataProvider is null!');
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
                        ),
                      );
                    });
              })),
    );
  }

  Widget _buildImage(String? abbr, {double size = 40}) {
    if (abbr == null || abbr.isEmpty) {
      return Icon(
        Icons.sports_football,
        size: size,
        color: primary,
      );
    }
    return TeamLogo(
      abbr: abbr,
      size: size,
    );
  }

  Future<void> _savePicksAndProceedToPayment(BuildContext context, DataProvider? dataProvider) async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: primary),
                SizedBox(height: 16),
                Text('Saving your picks...', style: TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ),
      );

      // Import payment service
      final PaymentService paymentService = PaymentService();
      
      // Check if dataProvider is null
      if (dataProvider == null) {
        throw Exception('Data provider is null');
      }

      // Save picks with pending payment status
      final pickRecordId = await paymentService.savePicksAndCreatePaymentEntry(
        picks: dataProvider.playerPicks ?? [],
        tiebreaker: dataProvider.tiebreaker?.toString() ?? "",
        weekName: dataProvider.game?['name'] ?? "",
      );

      // Close loading dialog
      Navigator.pop(context);

      // Navigate to manual payment screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ManualPaymentScreen(
            pickRecordId: pickRecordId,
            weekName: dataProvider.game?['name'] ?? "",
            entryFee: PaymentService.ENTRY_FEE,
          ),
        ),
      );
    } catch (e) {
      // Close loading dialog if open
      Navigator.pop(context);
      
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving picks: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildDemoContent() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  blurRadius: 3,
                  color: Color(0x33000000),
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsetsDirectional.fromSTEB(16, 8, 16, 8),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Hello, Demo User',
                    style: TextStyle(
                      fontFamily: 'Lexend Deca',
                      color: Color(0xFF090F13),
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Content
          Padding(
            padding: EdgeInsetsDirectional.fromSTEB(16, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Review Your Picks',
                  style: TextStyle(
                    fontFamily: 'Lexend Deca',
                    color: Color(0xFF4B39EF),
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 20),
                
                // Show picks summary
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 2,
                        color: Color(0x33000000),
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Picks for Week PRE1:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF090F13),
                        ),
                      ),
                      SizedBox(height: 12),
                      ...(dataProvider?.playerPicks ?? []).map((pick) => Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green, size: 20),
                            SizedBox(width: 8),
                            Text(
                              pick,
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      )).toList(),
                      SizedBox(height: 12),
                      Text(
                        'Tiebreaker: ${dataProvider?.tiebreaker ?? 0}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF4B39EF),
                        ),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: 20),
                
                // Demo mode notice
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange, size: 24),
                      SizedBox(height: 8),
                      Text(
                        'Demo Mode',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'This is a demo account. Your picks will be saved to a local file.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: 20),
                
                // Submit button
                Container(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _submitDemoPicks(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Submit Picks',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitDemoPicks(BuildContext context) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: primary),
                SizedBox(height: 16),
                Text('Saving your picks...', style: TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ),
      );

      // Get user and pick data
      final weekName = dataProvider?.game?['name'] ?? "REG1";
      final tiebreaker = dataProvider?.tiebreaker?.toString() ?? "0";
      final picks = dataProvider?.playerPicks?.cast<String>() ?? [];
      
      print('🎯 Starting 5-Player Simulation for $weekName');
      print('User picks: ${picks.length} picks, tiebreaker: $tiebreaker');

      // Create user's pick model
      final userPick = PickModel(
        pickId: 'user_${user?.uid ?? 'demo_user'}_${weekName}',
        userId: user?.uid ?? 'demo_user',
        displayName: user?.displayName ?? 'You',
        weekName: weekName,
        picks: picks,
        tiebreaker: int.tryParse(tiebreaker) ?? 0,
        submittedAt: DateTime.now(),
        paymentStatus: 'verified',
        entryFee: 10.0,
        isActive: true,
        photoURL: user?.photoURL ?? '',
        isDemoEntry: true,
      );

      // Save user picks first
      final paymentService = PaymentService();
      try {
        await paymentService.savePicksAndCreatePaymentEntry(
          picks: picks,
          tiebreaker: tiebreaker,
          weekName: weekName,
        );
        print('✅ User picks saved successfully');
      } catch (e) {
        print('⚠️ Firestore save failed (continuing in demo mode): $e');
      }

      // Start the 5-player simulation
      final simulationController = SimulationController();
      final simulationStarted = await simulationController.startSimulation(weekName, userPick);

      // Close loading dialog
      Navigator.pop(context);

      if (simulationStarted) {
        // Show exciting success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 Simulation Started! Generating AI opponents...'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Wait a moment for drama
        await Future.delayed(Duration(seconds: 2));

        // Navigate to results announcement page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ResultsAnnouncementPage(weekName: weekName),
          ),
        );
      } else {
        // Fallback to regular leaderboard if simulation fails
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Picks submitted! View results on leaderboard.'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 2),
          ),
        );

        await Future.delayed(Duration(seconds: 1));
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => LeaderboardWidget(),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if open
      Navigator.pop(context);
      
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting picks: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveExistingPicksEdit(BuildContext context, DataProvider? dataProvider) async {
    try {
      // Check if dataProvider is null
      if (dataProvider == null) {
        throw Exception('Data provider is null');
      }

      circularCustom(context);
      final picksCreateData = {
        "week": dataProvider.game?['name'],
        "tiebreaker": dataProvider.tiebreaker?.toString() ?? "",
        'date': FieldValue.serverTimestamp(),
        'picks': dataProvider.playerPicks is List ? dataProvider.playerPicks : [],
        'uid': user?.uid ?? 'demo_user',
        "displayName": user?.displayName ?? 'Demo User',
        "photoURL": user?.photoURL ?? '',
        "paymentStatus": "verified", // Keep existing verification status for edits
      };
      CollectionReference pickrecord = FirebaseFirestore.instance.collection('pickrecord');
      
      if (widget.id != null && widget.id!.isNotEmpty) {
        // Use set with merge to create or update the document
        await pickrecord.doc(widget.id).set(picksCreateData, SetOptions(merge: true));
      } else {
        // No ID provided, create new document
        await pickrecord.add(picksCreateData);
      }
      
      await calculateScore(context);
      Navigator.pop(context);
      Navigator.pop(context);
      Navigator.pop(context);
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating picks: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
