import 'PlayerPickWidget.dart';
import '../../../Widget/reuse.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:poolqapp/constants.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import '../../../Provider/homeProvider.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:poolqapp/Module/Screen/Home/rule.dart';
import 'package:poolqapp/Module/Screen/Home/EditPlay.dart';
import '../../../services/nfl_schedule_service.dart';
import '../../../services/game_state_service.dart';
import 'package:poolqapp/constants/app_theme.dart';
import 'package:poolqapp/services/app_config_service.dart';
import 'package:poolqapp/services/picks_validation_service.dart';
import 'package:poolqapp/services/payment_service.dart';
import 'package:poolqapp/services/game_enforcement_service.dart';
import 'package:poolqapp/widgets/player/player_picks_modal.dart';


class PlayWidget extends StatefulWidget {
  const PlayWidget({Key? key}) : super(key: key);

  @override
  _PlayWidgetState createState() => _PlayWidgetState();
}

class _PlayWidgetState extends State<PlayWidget> {
  // late PlayModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  List? data;
  bool _useMultipageUI = false; // Flag to enable new multipage UI
  bool _hasExistingEntry = false;
  bool _pickingAllowed = true;
  Map<String, dynamic>? _existingEntry;
  String? _forwardMessage;

  TextEditingController tieBreakerController = TextEditingController();
  User? user = FirebaseAuth.instance.currentUser;
  final GameStateService _gameStateService = GameStateService();
  final PaymentService _paymentService = PaymentService();
  
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
        // Use raw games data directly (same as classic view)
        
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

  // Removed unused _pickrecord field
  @override
  void initState() {
    super.initState();
    DataProvider dataProvider =
        Provider.of<DataProvider>(context, listen: false);
    
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      var weekName = dataProvider.game?['name']?.toString() ?? 'PRE1';
      final resolved =
          await GameEnforcementService().resolveEntryWeekOrForward(weekName);

      if (!mounted) return;

      if (resolved.redirected) {
        if (resolved.week == null) {
          setState(() {
            _pickingAllowed = false;
            _hasExistingEntry = false;
            _forwardMessage =
                '${resolved.lockedWeek} is locked and no later weeks are open yet.';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_forwardMessage!),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }

        dataProvider.setActiveWeek(resolved.week!);
        weekName = resolved.week!;
        await getGame(context);
        if (!mounted) return;
        setState(() {
          _forwardMessage =
              '${resolved.lockedWeek} started - no late entries. Showing ${resolved.week} instead.';
          _pickingAllowed = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_forwardMessage!),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
          ),
        );
      }

      final allowed =
          await GameEnforcementService().isPickingAllowed(weekName);
      final entry = await _paymentService.getUserEntryForWeek(weekName);

      if (!mounted) return;

      if (entry != null) {
        // Already entered - don't let them re-run the pick form.
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "You're already entered for $weekName. Showing the leaderboard.",
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        return;
      }

      dataProvider.clearPlayerPicks();
      tieBreakerController.clear();
      setState(() {
        _hasExistingEntry = false;
        _existingEntry = null;
        _pickingAllowed = allowed;
      });
    });
    
    // Check if we're in demo mode
    if (user == null || user?.email == 'demo@poolq.com') {
      print('Play: Demo mode detected');
    } else {
      print('Play: Real user mode');
    }
    getGame(context);
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

    // Use new multipage UI if enabled
    if (_useMultipageUI) {
      return _buildModernPicksScreen(context, dataProvider);
    }

    final weekName = dataProvider.game?['name']?.toString() ?? '';
    final showPreBanner = weekName.startsWith('PRE') &&
        (AppConfigService().preseasonFree ||
            AppConfigService().isPreseasonFreeWeek);

    return Scaffold(
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
              if (showPreBanner)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 12,
                  right: 12,
                  child: Material(
                    elevation: 2,
                    borderRadius: BorderRadius.circular(10),
                    color: AppTheme.primaryBlue,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Text(
                        'Preseason - picks are free to enter. Play and learn how the pool works!',
                        style: TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ),
                  ),
                ),
              if (_hasExistingEntry)
                Positioned(
                  top: MediaQuery.of(context).padding.top +
                      (showPreBanner ? 64 : 8),
                  left: 12,
                  right: 12,
                  child: Material(
                    elevation: 3,
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle,
                              color: Colors.green, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _pickingAllowed
                                  ? 'You already entered this week (1 entry). Review or edit before kickoff.'
                                  : 'You entered this week. Entries are locked - review your picks.',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              if (_pickingAllowed) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const EditPlayWidget(),
                                  ),
                                );
                              } else if (_existingEntry != null) {
                                showDialog(
                                  context: context,
                                  builder: (_) => PlayerPicksModal(
                                    playerData: {
                                      ..._existingEntry!,
                                      'displayName':
                                          user?.displayName ?? 'You',
                                    },
                                    games:
                                        data?.cast<Map<String, dynamic>>() ??
                                            const [],
                                    weekName: weekName,
                                  ),
                                );
                              }
                            },
                            child: Text(
                              _pickingAllowed ? 'Edit' : 'Review',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              Container(
                width: MediaQuery.of(context).size.width,
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top +
                      (showPreBanner ? 56 : 12) +
                      (_hasExistingEntry ? 56 : 0),
                  bottom: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.28),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/poolq12.png',
                      width: 100,
                      height: 72,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Welcome to week '.toUpperCase(),
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '${dataProvider.game!["name"].toString().replaceAll("REG", "").replaceAll("PRE", "")}',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(
                  0,
                  MediaQuery.of(context).padding.top +
                      (showPreBanner ? 56 : 12) +
                      (_hasExistingEntry ? 56 : 0) +
                      100,
                  0,
                  0,
                ),
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                  ),
                  child: Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(1, 12, 1, 1),
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
                                    Padding(
                                  padding: const EdgeInsets.fromLTRB(10, 4, 10, 8),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF063a73)
                                          .withOpacity(0.88),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                          color: Colors.white.withOpacity(0.18)),
                                    ),
                                    child: Text(
                                      formateDate(value),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
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
                                        CrossAxisAlignment.center,
                                    children: [
                                      Padding(
                                        padding: EdgeInsetsDirectional.fromSTEB(
                                            10, 0, 10, 12),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: AppTheme.glassBlue
                                                .withOpacity(0.92),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            border: Border.all(
                                              color: Colors.white
                                                  .withOpacity(0.22),
                                            ),
                                          ),
                                          child: Padding(
                                            padding:
                                                EdgeInsetsDirectional.fromSTEB(
                                                    8, 8, 8, 8),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.max,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Expanded(
                                                  child: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.max,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .center,
                                                    children: [
                                                      Text(
                                                        'GAME: ${index + 1}',
                                                        textAlign:
                                                            TextAlign.center,
                                                        style: TextStyle(
                                                          fontFamily: 'Lexend Deca',
                                                          color: Colors.white
                                                              .withOpacity(
                                                                  0.9),
                                                          fontSize: 11,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Row(
                                                        mainAxisSize:
                                                            MainAxisSize.max,
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          Expanded(
                                                            flex: 2,
                                                            child: Column(
                                                              children: [
                                                                TeamLogo(
                                                                  abbr: gameItem["abbreviation2"] ?? '',
                                                                  size: 80,
                                                                ),
                                                                SizedBox(height: 8),
                                                                Text(
                                                                  gameItem["away"] ?? gameItem["abbreviation2"] ?? '',
                                                                  textAlign: TextAlign.center,
                                                                  style: TextStyle(
                                                                    fontSize: 12,
                                                                    fontWeight: FontWeight.w500,
                                                                    color: Colors.white,
                                                                  ),
                                                                ),
                                                                SizedBox(height: 4),
                                                                TeamPickAbbrButton(
                                                                  abbr: (gameItem["abbreviation2"] ?? '').toString(),
                                                                  selected: dataProvider.playerPicks!.contains(gameItem["abbreviation2"]),
                                                                  checkOnLeading: true,
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
                                                                      // Remove both teams first to ensure clean selection
                                                                      dataProvider.removeFromPlayerPicks(gameItem["abbreviation"]);
                                                                      dataProvider.removeFromPlayerPicks(gameItem["abbreviation2"]);
                                                                      // Then add the selected team
                                                                      dataProvider.addToPlayerPicks(gameItem["abbreviation2"]);
                                                                  },
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
                                                                    color: Colors.white,
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
                                                                          10,
                                                                      color: Colors.white70),
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
                                                                  size: 80,
                                                                ),
                                                                SizedBox(height: 8),
                                                                Text(
                                                                  gameItem["home"] ?? gameItem["abbreviation"] ?? '',
                                                                  textAlign: TextAlign.center,
                                                                  style: TextStyle(
                                                                    fontSize: 12,
                                                                    fontWeight: FontWeight.w500,
                                                                    color: Colors.white,
                                                                  ),
                                                                ),
                                                                SizedBox(height: 4),
                                                                TeamPickAbbrButton(
                                                                  abbr: (gameItem["abbreviation"] ?? '').toString(),
                                                                  selected: dataProvider.playerPicks!.contains(gameItem["abbreviation"]),
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
                                                                      // Remove both teams first to ensure clean selection
                                                                      dataProvider.removeFromPlayerPicks(gameItem["abbreviation"]);
                                                                      dataProvider.removeFromPlayerPicks(gameItem["abbreviation2"]);
                                                                      // Then add the selected team
                                                                      dataProvider.addToPlayerPicks(gameItem["abbreviation"]);
                                                                  },
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
                                                                  ? const Color(0xFF69F0AE)
                                                                  : Colors.white,
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
                alignment: Alignment.bottomCenter,
                child: SafeArea(
                  top: false,
                  child: Container(
                  width: MediaQuery.of(context).size.width,
                  height: 75,
                  decoration: const BoxDecoration(
                    color: AppTheme.playActionBar,
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
                                    "assets/images/rulebook.png",
                                    color: Colors.white,
                                    colorBlendMode: BlendMode.srcIn,
                                  )),
                            ),
                            Container(
                              width: 52,
                              decoration: BoxDecoration(),
                              child: TextFormField(
                                controller: tieBreakerController,
                                obscureText: false,
                                style: const TextStyle(color: Colors.white),
                                maxLength: 2,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(2),
                                ],
                                decoration: InputDecoration(
                                  hintText: '##',
                                  counterText: '',
                                  hintStyle: const TextStyle(color: Colors.white70),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Colors.white54,
                                      width: 1,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Colors.white,
                                      width: 1.5,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Colors.white,
                                      width: 0.5,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Colors.white,
                                      width: 0.5,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.15),
                                  contentPadding:
                                      EdgeInsetsDirectional.fromSTEB(
                                          8, 0, 8, 0),
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
                                if (tieBreakerController.text.isEmpty) {
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
                                  // Use enhanced validation service for better UX
                                  final validationService = PicksValidationService();
                                  
                                  // playerPicks is a flat list of team abbreviations
                                  final gamesForValidation =
                                      List<Map<String, dynamic>>.from(
                                    data!.whereType<Map>().map(
                                          (g) => Map<String, dynamic>.from(g),
                                        ),
                                  );
                                  final userPicksMap =
                                      PicksValidationService.mapFromAbbreviationPicks(
                                    gamesForValidation,
                                    dataProvider.playerPicks ?? const [],
                                  );
                                  
                                  await validationService.validateAndShowAlert(
                                    context: context,
                                    games: gamesForValidation,
                                    userPicks: userPicksMap,
                                    tiebreakerValue: tieBreakerController.text,
                                    onFixPicks: () {
                                      // Scroll to top to help user find missing picks
                                      // Could enhance this further by highlighting missing games
                                    },
                                  );
                                } else {
                                  // Block late entries; forward to next open week.
                                  final weekName =
                                      dataProvider.game?['name']?.toString() ??
                                          '';
                                  final resolved =
                                      await GameEnforcementService()
                                          .resolveEntryWeekOrForward(weekName);
                                  if (resolved.redirected) {
                                    if (!mounted) return;
                                    if (resolved.week == null) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            '${resolved.lockedWeek} is locked - no late entries.',
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                      return;
                                    }
                                    dataProvider
                                        .setActiveWeek(resolved.week!);
                                    await getGame(context);
                                    if (!mounted) return;
                                    setState(() {
                                      _pickingAllowed = true;
                                      _hasExistingEntry = false;
                                      _forwardMessage =
                                          '${resolved.lockedWeek} started - switched to ${resolved.week}.';
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(_forwardMessage!),
                                        backgroundColor: Colors.orange,
                                      ),
                                    );
                                    return;
                                  }

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
              ),
            ],
          ),
        ));
  }

  bool _validateAllGamesPicked() {
    DataProvider dataProvider = Provider.of<DataProvider>(context, listen: false);
    final picks = (dataProvider.playerPicks ?? [])
        .map((p) => p.toString().trim())
        .toSet();

    print('Validating picks: $picks');
    print('Total picks: ${picks.length}');
    print('Expected games: ${data?.length}');

    if (data == null || data!.isEmpty || picks.isEmpty) {
      print('No picks or games found');
      return false;
    }

    // One pick per game: home OR away abbreviation must be in picks
    int pickedGames = 0;
    final missing = <String>[];
    for (final raw in data!) {
      if (raw is! Map) continue;
      final home = raw['abbreviation']?.toString().trim() ?? '';
      final away = raw['abbreviation2']?.toString().trim() ?? '';
      final hasPick =
          (home.isNotEmpty && picks.contains(home)) ||
          (away.isNotEmpty && picks.contains(away));
      if (hasPick) {
        pickedGames++;
      } else {
        missing.add('$away @ $home');
      }
    }

    final gameCount = data!.whereType<Map>().length;
    final isValid = pickedGames == gameCount && missing.isEmpty;
    print('Picked games: $pickedGames / $gameCount');
    if (missing.isNotEmpty) print('Missing: $missing');
    print('Validation result: $isValid');
    return isValid;
  }

  /// Classic picks screen with multipage UI and original styling
  Widget _buildModernPicksScreen(BuildContext context, DataProvider dataProvider) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: Colors.white,
      body: data == null
          ? const Center(
              child: CircularProgressIndicator(color: Colors.blue),
            )
          : data!.isEmpty
              ? _buildEmptyState()
              : Container(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height * 1,
                  child: Stack(
                    children: [
                      // Original background image
                      Align(
                        alignment: AlignmentDirectional(0, 0),
                        child: Image.asset(
                          'assets/images/assets.aboutamazon.jpg',
                          width: MediaQuery.of(context).size.width,
                          height: MediaQuery.of(context).size.height * 1,
                          fit: BoxFit.cover,
                        ),
                      ),
                      // Header with original styling
                      Container(
                        width: MediaQuery.of(context).size.width,
                        height: 150,
                        decoration: BoxDecoration(
                          color: Color(0x43EEEEEE),
                        ),
                        child: Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(0, 12, 0, 0),
                          child: Column(
                            mainAxisSize: MainAxisSize.max,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Padding(
                                    padding: EdgeInsetsDirectional.fromSTEB(20, 20, 120, 0),
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
                                          child: Icon(Icons.sports_football, color: Colors.white, size: 40),
                                        );
                                      },
                                    ),
                                  ),
                                  // Back button
                                  Padding(
                                    padding: EdgeInsetsDirectional.fromSTEB(0, 20, 0, 0),
                                    child: IconButton(
                                      icon: Icon(Icons.arrow_back, color: Colors.white, size: 30),
                                      onPressed: () => Navigator.of(context).pop(),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Multipage content with original styling
                      Positioned(
                        top: 150,
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'Classic UI Mode Active',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sports_football,
              size: 64,
              color: AppTheme.onSurfaceVariant.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No Games Available',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: AppTheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'There are no games scheduled for this week.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _handlePicksSubmission() async {
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    
    // Use classic validation logic
    if (tieBreakerController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a tiebreaker score'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (!_validateAllGamesPicked()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please make picks for all games'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Proceed with submission using classic logic
    dataProvider.tiebreaker = int.parse(tieBreakerController.text);
    dataProvider.amount = await dataProvider.countGames(
      dataProvider.playerPicks!.toList(),
    );
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlayerPicksWidget(),
      ),
    );
  }
}
