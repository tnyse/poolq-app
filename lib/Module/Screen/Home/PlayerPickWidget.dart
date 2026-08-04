import 'HomePage.dart';
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
import 'package:poolqapp/services/app_config_service.dart';
import 'package:poolqapp/services/game_enforcement_service.dart';
import 'package:poolqapp/services/payment_service.dart';
import 'package:poolqapp/constants/app_theme.dart';
import 'package:poolqapp/utils/avatar_url.dart';
import '../../../widgets/payment/payment_prompt_modal.dart';

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
            backgroundColor: AppTheme.primaryBlue,
            foregroundColor: Colors.white,
            iconTheme: const IconThemeData(color: Colors.white),
            actionsIconTheme: const IconThemeData(color: Colors.white),
            automaticallyImplyLeading: true,
            title: Consumer<DataProvider>(
              builder: (context, dp, _) {
                final weekLabel = dp.game?['name']
                    ?.toString()
                    .replaceAll('REG', '')
                    .replaceAll('PRE', '') ?? '';
                return Text(
                  weekLabel.isNotEmpty ? 'Week $weekLabel Picks' : 'Your Picks',
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                );
              },
            ),
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
                              color: Colors.white,
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
                        debugPrint(
                          'PlayerPicksWidget: paymentMethod stream error: ${snapshot2.error}',
                        );
                        // Continue — payment method doc is optional for review UI.
                      }

                      // Only block on first wait; missing paymentMethod doc is OK.
                      if (snapshot2.connectionState ==
                              ConnectionState.waiting &&
                          !snapshot2.hasData) {
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
                        ));
                      }

                      return SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                              child: Column(
                                children: [
                                  Center(
                                    child: Image.asset(
                                      'assets/images/poolq12.png',
                                      width: 72,
                                      height: 96,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Hello, ${user?.displayName ?? 'Demo User'}',
                                        style: const TextStyle(
                                          fontFamily: 'Lexend Deca',
                                          color: Color(0xFF090F13),
                                          fontSize: 20,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      CircleAvatar(
                                        radius: 24,
                                        backgroundColor: Colors.white,
                                        backgroundImage: resolveAvatarImage(
                                          photoUrl: authProvider.image
                                                  .toString()
                                                  .isNotEmpty
                                              ? authProvider.image.toString()
                                              : (user?.photoURL ?? ''),
                                          email: user?.email,
                                          size: 96,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  const Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      'Review Your Picks',
                                      style: TextStyle(
                                        fontFamily: 'Lexend Deca',
                                        color: Color(0xFF063a73),
                                        fontSize: 24,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
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
                                  PicksLogoGrid(
                                    picks: (dataProvider?.playerPicks ?? [])
                                        .map((e) => e?.toString() ?? '')
                                        .where((e) => e.isNotEmpty)
                                        .toList(),
                                    logoSize: 44,
                                  ),
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
                                    width: double.infinity,
                                    height: 52,
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        print('Submit button pressed. Edit mode: ${widget.edit}');
                                        print('Snapshot docs count: ${snapshot.data!.docs.length}');
                                        
                                        if (widget.edit == true) {
                                          print('Going to edit mode');
                                          if (dataProvider != null) {
                                            await _saveExistingPicksEdit(context, dataProvider);
                                          }
                                        } else if (!snapshot.data!.docs.isEmpty) {
                                          print('User already has picks for this week');
                                          customSnackbar(
                                            context,
                                            "You're already entered for this week",
                                          );
                                          Navigator.pushAndRemoveUntil(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  const HomePage(initial: 1),
                                            ),
                                            (route) => false,
                                          );
                                        } else {
                                          print('Going to save picks and proceed to payment');
                                          if (dataProvider != null) {
                                            await _savePicksAndProceedToPayment(context, dataProvider);
                                          } else {
                                            print('DataProvider is null!');
                                          }
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: primary,
                                        foregroundColor: Colors.white,
                                        textStyle: const TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        elevation: 2,
                                      ),
                                      child: Text(
                                        "${widget.edit == true ? "Save Picks" : "Submit Picks"}",
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
                    });
              })),
    );
  }

  Future<void> _savePicksAndProceedToPayment(BuildContext context, DataProvider? dataProvider) async {
    try {
      // Validate picks before submission
      if (dataProvider == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: Data provider not available'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final weekForGate = dataProvider.game?['name']?.toString() ?? '';
      if (weekForGate.isNotEmpty) {
        final resolved = await GameEnforcementService()
            .resolveEntryWeekOrForward(weekForGate);
        if (resolved.redirected) {
          if (!mounted) return;
          if (resolved.week == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '${resolved.lockedWeek} is locked — no late entries, and no later week is open yet.',
                ),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }
          dataProvider.setActiveWeek(resolved.week!);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${resolved.lockedWeek} already started — no late entries. Switched to ${resolved.week}. Tap Play to enter.',
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 5),
            ),
          );
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const HomePage(initial: 0)),
            (route) => false,
          );
          return;
        }
      }
      
      // Check if tiebreaker is provided
      if (dataProvider.tiebreaker == null || dataProvider.tiebreaker == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a tiebreaker score'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      // Check if all games are picked
      final userPicks = dataProvider.playerPicks?.cast<String>() ?? [];
      if (userPicks.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please make picks for all games'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
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
      
      // Validation: Check if all games are picked and tiebreaker is provided
      final submissionPicks = dataProvider.playerPicks ?? [];
      final tiebreaker = dataProvider.tiebreaker?.toString() ?? "";
      
      if (submissionPicks.isEmpty) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please make picks for all games before submitting.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      if (tiebreaker.isEmpty || tiebreaker == "0") {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please enter a tiebreaker score before submitting.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final weekName = dataProvider.game?['name'] ?? "";
      final pickRecordId = await paymentService.savePicksAndCreatePaymentEntry(
        picks: dataProvider.playerPicks ?? [],
        tiebreaker: dataProvider.tiebreaker?.toString() ?? "",
        weekName: weekName,
      );

      // Close loading dialog
      Navigator.pop(context);

      // PRE/MOCK free / auto-verify: skip payment screen
      final config = AppConfigService();
      if (!config.isLoaded) await config.load();
      if (config.preseasonFree &&
          (weekName.startsWith('PRE') || weekName.startsWith('MOCK'))) {
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => HomePage(initial: 1)),
          (route) => false,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              weekName.startsWith('MOCK')
                  ? 'You\'re in! Mock week entry is free.'
                  : 'You\'re in! Preseason entry is free.',
            ),
            backgroundColor: Colors.green,
          ),
        );
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ManualPaymentScreen(
            pickRecordId: pickRecordId,
            weekName: weekName,
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
                    color: Color(0xFF063a73),
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
                        'Your Picks for Week ${dataProvider?.game?["name"]?.toString().replaceAll("REG", "").replaceAll("PRE", "") ?? "1"}:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF090F13),
                        ),
                      ),
                      SizedBox(height: 12),
                      PicksLogoGrid(
                        picks: (dataProvider?.playerPicks ?? [])
                            .map((e) => e.toString())
                            .where((e) => e.isNotEmpty)
                            .toList(),
                        logoSize: 40,
                      ),
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
                
                // Demo mode notice (only show for demo users)
                if (user?.email == 'demo@poolq.com' || user == null)
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
                          'This is a demo account. Your picks will be saved locally for testing.',
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
      // Validate picks before submission
      final dataProvider = Provider.of<DataProvider>(context, listen: false);
      
      // Check if tiebreaker is provided
      if (dataProvider?.tiebreaker == null || dataProvider?.tiebreaker == 0) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a tiebreaker score'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      // Check if all games are picked
      final demoPicks = dataProvider?.playerPicks?.cast<String>() ?? [];
      if (demoPicks.isEmpty) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please make picks for all games'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
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
      final demoSubmissionPicks = dataProvider?.playerPicks?.cast<String>() ?? [];
      
      // Validation: Check if all games are picked and tiebreaker is provided
      if (demoSubmissionPicks.isEmpty) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please make picks for all games before submitting.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      if (tiebreaker == "0" || tiebreaker.isEmpty) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please enter a tiebreaker score before submitting.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      print('🎯 Starting 5-Player Simulation for $weekName');
      print('User picks: ${demoSubmissionPicks.length} picks, tiebreaker: $tiebreaker');

      // Create user's pick model
      final userPick = PickModel(
        pickId: 'user_${user?.uid ?? 'demo_user'}_${weekName}',
        userId: user?.uid ?? 'demo_user',
        displayName: user?.displayName ?? 'You',
        weekName: weekName,
        picks: demoSubmissionPicks,
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
          picks: demoSubmissionPicks,
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
        "email": user?.email ?? '',
        "paymentStatus": "verified", // Keep existing verification status for edits
      };
      CollectionReference pickrecord = FirebaseFirestore.instance.collection('pickrecord');
      final weekName = dataProvider.game?['name']?.toString() ?? '';
      final uid = user?.uid ?? 'demo_user';

      // Always one doc per user/week — never .add() (creates duplicates).
      final docId = (widget.id != null && widget.id!.isNotEmpty)
          ? widget.id!
          : PaymentService.pickDocumentId(uid, weekName);

      final allowed = await GameEnforcementService().isPickingAllowed(weekName);
      if (!allowed) {
        Navigator.pop(context);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$weekName is locked — edits closed after kickoff.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      await pickrecord.doc(docId).set(picksCreateData, SetOptions(merge: true));
      
      await calculateScore(context);
      
      // Show payment prompt first (skip for demo users)
      if (user?.email != 'demo@poolq.com' && user != null) {
        await _showPaymentPrompt(context);
      }
      
      // Show confirmation modal before navigating
      await _showEntryConfirmationModal(context);
      
      // Navigate to leaderboard
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
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

  Future<void> _showEntryConfirmationModal(BuildContext context) async {
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    final weekNumber = dataProvider.game?['name']?.toString().replaceAll('REG', '').replaceAll('PRE', '') ?? '1';
    
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF4CAF50),
                  Color(0xFF45A049),
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Success icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: Icon(
                    Icons.check_circle_outline,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Title
                Text(
                  'Good Luck!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Message
                Text(
                  'Your picks for Week $weekNumber have been submitted successfully!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  'May the best picks win! 🏆',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                    fontStyle: FontStyle.italic,
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Close button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Color(0xFF4CAF50),
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: Text(
                      'View Leaderboard',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showPaymentPrompt(BuildContext context) async {
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    final weekName = dataProvider.game?['name'] ?? 'PRE1';
    final kickoff =
        await GameEnforcementService().getFirstKickoff(weekName);

    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return PaymentPromptModal(
          weekName: weekName,
          kickoffTime: kickoff,
          onPaymentComplete: () {
            debugPrint('Payment completed for $weekName');
          },
          onSkipPayment: () {
            debugPrint('Payment skipped for $weekName');
          },
        );
      },
    );
  }
}
