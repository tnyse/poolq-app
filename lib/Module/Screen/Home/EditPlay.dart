import 'PlayerPickWidget.dart';
import 'HomePage.dart';
import '../../../Widget/reuse.dart';
import 'package:flutter/material.dart';
import '../../../constants.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import '../../../Provider/homeProvider.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:poolqapp/Module/Screen/Home/rule.dart';
import '../../../services/nfl_schedule_service.dart';
import '../../../services/game_state_service.dart';
import 'package:poolqapp/services/game_enforcement_service.dart';

class EditPlayWidget extends StatefulWidget {
  const EditPlayWidget({Key? key}) : super(key: key);

  @override
  _EditPlayWidgetState createState() => _EditPlayWidgetState();
}

class _EditPlayWidgetState extends State<EditPlayWidget> {
  String? id;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  List? data;
  bool isLoading = true;
  String? errorMessage;

  TextEditingController tieBreakerController = TextEditingController();
  User? user = FirebaseAuth.instance.currentUser;
  final GameStateService _gameStateService = GameStateService();
  
  Future getGame(context) async {
    DataProvider dataProvider = Provider.of<DataProvider>(context, listen: false);
    final scheduleService = NFLScheduleService();
    
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      print('EditPlay: Starting getGame()');
      
      // Check if game data is available
      if (dataProvider.game == null) {
        print('EditPlay: Game data is null, using default values');
        setState(() {
          isLoading = false;
          errorMessage = 'Game data not available';
        });
        return;
      }
      
      print('EditPlay: Game name: ${dataProvider.game!["name"]}');
      
      // Always load real schedule data (even in demo mode)
      print('EditPlay: Loading real schedule from local file for ${dataProvider.game!["name"]}');
      
      // Only use local file for schedule display
      List<Map<String, dynamic>> games = await scheduleService.getScheduleForWeekWithLocalFallback(
        dataProvider.game!["name"]
      );
      if (games.isNotEmpty) {
        // CRITICAL: Hide scores during editing phase
        List<Map<String, dynamic>> sanitizedGames = _gameStateService.sanitizeGamesList(
          games,
          screenContext: 'editplay',
          isPickingPhase: true,
        );
        
        setState(() {
          data = sanitizedGames;
          isLoading = false;
          errorMessage = null;
        });
        print('🏈 EDIT PLAY: Successfully loaded ${sanitizedGames.length} games for editing (scores hidden)');
        return sanitizedGames;
      } else {
        throw Exception('No games data available from local file');
      }
      
    } catch (e) {
      print('Error fetching games for edit: $e');
      setState(() {
        errorMessage = 'Failed to load games: $e';
        isLoading = false;
      });
      
      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading games: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => getGame(context),
            ),
          ),
        );
      }
    }
  }

  Future<QuerySnapshot<Map<String, dynamic>>>? _pickrecord;
  
  @override
  void initState() {
    super.initState();
    
    // Schedule state changes for after the build phase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      DataProvider dataProvider = Provider.of<DataProvider>(context, listen: false);
      
      // Reset player picks to current selections
      dataProvider.setPlayerPicks([]);

      // Load existing picks data (including demo mode from provider)
      if (dataProvider.game != null) {
        // For demo mode, load from mock data stored in provider
        if (user == null || user?.email == 'demo@poolq.com') {
          // Load demo picks from the provider's mock data
          // const demoUserId = 'demo_user';
          // Demo picks: all away teams from PRE1 games with tiebreaker 55
          List<String> demoPicks = [
            "IND", "CIN", "LV", "CLE", "DET", "WAS", "NYG", "KC", 
            "DAL", "HOU", "NYJ", "PIT", "TEN", "DEN", "MIA", "NO"
          ];
          dataProvider.setPlayerPicks(demoPicks);
          dataProvider.setTieBreaker(55);
          tieBreakerController.text = "55";
          print('Loaded demo picks for all 16 PRE1 games: $demoPicks with tiebreaker 55');
        } else {
          _pickrecord = FirebaseFirestore.instance
              .collection('pickrecord')
              .where("uid", isEqualTo: user!.uid)
              .where("week", isEqualTo: dataProvider.game!["name"])
              .get();
        }
      }

      if (_pickrecord != null) {
        _pickrecord!.then((value) {
          if (value.docs.isNotEmpty) {
            List<String> existingPicks = [...value.docs[0].get("picks")];
            dataProvider.setPlayerPicks(existingPicks);
            dataProvider.setTieBreaker(int.parse(value.docs[0].get("tiebreaker")));
            tieBreakerController.text = dataProvider.tiebreaker.toString();
            id = value.docs[0].id;
            print('Loaded existing picks: $existingPicks');
          }
        }).catchError((error) {
          print('Error loading existing picks: $error');
        });
      }
    });

    print("Initializing EditPlay widget");
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
        Provider.of<DataProvider>(context, listen: false);

    return Scaffold(
        // bottomNavigationBar: Container(
        //     color: Colors.white,
        //     child: kIsWeb?kIsWeb?AdmobBanner(
        //       adUnitId: Provider.of<DataProvider>(context, listen: false)
        //           .getBannerAdUnitId().toString(),
        //       adSize: AdmobBannerSize.BANNER,
        //       listener: (AdmobAdEvent event, Map<String, dynamic> ?args) {},
        //     ):Container():Container()),
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
              Positioned(
                top: MediaQuery.of(context).padding.top,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new,
                                color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const Spacer(),
                        ],
                      ),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.asset(
                          'assets/images/app_icon.png',
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Image.asset(
                            'assets/images/poolq12.png',
                            width: 56,
                            height: 56,
                            fit: BoxFit.contain,
                          ),
                        ),
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
                            '${dataProvider.game != null ? dataProvider.game!["name"].toString().replaceAll("REG", "").replaceAll("PRE", "") : "1"}',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      if (dataProvider.game != null &&
                          dataProvider.game!["name"]
                              .toString()
                              .startsWith('PRE'))
                        const Text(
                          'PRESEASON',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            color: Color(0xFFFF8F00),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(
                    0, MediaQuery.of(context).padding.top + 140, 0, 0),
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
                        // Show loading state
                        if (isLoading) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 50,
                                  height: 50,
                                  child: CircularProgressIndicator(
                                    color: primary,
                                  ),
                                ),
                                SizedBox(height: 20),
                                Text(
                                  'Loading games for editing...',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        
                        // Show error state
                        if (errorMessage != null) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 64,
                                  color: Colors.red,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Error Loading Games',
                                  style: GoogleFonts.poppins(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  errorMessage!,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.white70,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 20),
                                ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      isLoading = true;
                                      errorMessage = null;
                                    });
                                    getGame(context);
                                  },
                                  child: Text('Retry'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primary,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        
                        // Show empty state
                        if (data == null || data!.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.sports_football,
                                  size: 64,
                                  color: Colors.white70,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'No Games Available',
                                  style: GoogleFonts.poppins(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'No games found for this week.',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        
                        final listViewGetScheduleResponse = data;
                        print('Rendering ${data!.length} games for editing');
                        
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
                                  padding:
                                      const EdgeInsets.fromLTRB(10, 4, 10, 8),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF063a73)
                                          .withOpacity(0.55),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                          color:
                                              Colors.white.withOpacity(0.18)),
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
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: EdgeInsetsDirectional.fromSTEB(
                                            10, 0, 10, 12),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF3474E0)
                                                .withOpacity(0.78),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            border: Border.all(
                                              color: Colors.white
                                                  .withOpacity(0.18),
                                            ),
                                          ),
                                          child: Padding(
                                            padding:
                                                EdgeInsetsDirectional.fromSTEB(
                                                    8, 8, 8, 8),
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
                                                              color: Colors
                                                                  .white
                                                                  .withOpacity(
                                                                      0.85),
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
                                                              color:
                                                                  Colors.white,
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
                                                          TeamLogo(
                                                            abbr: _getTeamAbbreviationWithFallback(gameItem, true),
                                                            size: 80,
                                                          ),
                                                          TextButton(
                                                            onPressed:
                                                                () async {
                                                              print('Team 1 button pressed: ${gameItem["abbreviation"]}');
                                                              print('Current picks: ${dataProvider.playerPicks}');
                                                              
                                                              // Check if this team is already picked
                                                              bool hasTeam1 = dataProvider.playerPicks!.contains(gameItem["abbreviation"]);
                                                              
                                                              if (hasTeam1) {
                                                                // User is trying to pick the same team again
                                                                await showDialog(
                                                                  context: context,
                                                                  builder: (alertDialogContext) {
                                                                    return AlertDialog(
                                                                      title: Text('Already picked!'),
                                                                      content: Text('You have already picked ${gameItem["abbreviation"]} for this game.'),
                                                                      actions: [
                                                                        TextButton(
                                                                          onPressed: () => Navigator.pop(alertDialogContext),
                                                                          child: Text('OK'),
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
                                                                      'Selected: ${gameItem["abbreviation"]}',
                                                                      style:
                                                                          TextStyle(
                                                                        color: Colors
                                                                            .white,
                                                                        fontSize:
                                                                            16,
                                                                      ),
                                                                    ),
                                                                    duration: Duration(
                                                                        milliseconds:
                                                                            1000),
                                                                    backgroundColor:
                                                                        Colors.green,
                                                                  ),
                                                                );
                                                              }
                                                              
                                                              // Remove opposing team and add selected team
                                                              dataProvider
                                                                  .removeFromPlayerPicks(
                                                                      gameItem[
                                                                          "abbreviation2"]);
                                                              dataProvider
                                                                  .addToPlayerPicks(
                                                                      gameItem[
                                                                          "abbreviation"]);
                                                              print('Updated picks: ${dataProvider.playerPicks}');
                                                              
                                                              // Force rebuild to update visual state
                                                              setState(() {});
                                                            },
                                                            child: Container(
                                                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                              decoration: BoxDecoration(
                                                                color: dataProvider
                                                                        .playerPicks!
                                                                        .contains(gameItem[
                                                                            "abbreviation"])
                                                                    ? const Color(0xFF063a73).withOpacity(0.95)
                                                                    : Colors.white.withOpacity(0.22),
                                                                borderRadius: BorderRadius.circular(25),
                                                                border: Border.all(
                                                                  color: Colors.white.withOpacity(0.25),
                                                                  width: 1,
                                                                ),
                                                              ),
                                                              child: Row(
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
                                                                            .white,
                                                                        fontSize: 16),
                                                                  ),
                                                                  if (dataProvider
                                                                      .playerPicks!
                                                                      .contains(gameItem[
                                                                          "abbreviation"]))
                                                                    Container(
                                                                      margin: EdgeInsets.only(left: 8),
                                                                      child: Icon(
                                                                        Icons
                                                                            .check_circle,
                                                                        color: Colors
                                                                            .white,
                                                                        size: 20,
                                                                      ),
                                                                    )
                                                                ],
                                                              ),
                                                            ),
                                                          ),
                                                          Column(
                                                            children: [
                                                              Padding(
                                                                padding:
                                                                    EdgeInsetsDirectional
                                                                        .fromSTEB(
                                                                            5,
                                                                            0,
                                                                            5,
                                                                            0),
                                                                child: Text(
                                                                  'AT',
                                                                  style: TextStyle(
                                                                    color: Colors.white,
                                                                    fontWeight: FontWeight.bold,
                                                                    fontSize: 12,
                                                                  ),
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
                                                                  '${gameItem["time"]}',
                                                                  style: TextStyle(
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                      fontSize:
                                                                          11,
                                                                      color: Colors.white70),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          TextButton(
                                                              style:
                                                                  ButtonStyle(
                                                                padding: MaterialStateProperty.all(
                                                                    EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
                                                                backgroundColor:
                                                                    MaterialStateProperty
                                                                        .all(Colors.transparent),
                                                                foregroundColor:
                                                                    MaterialStateProperty
                                                                        .all(Colors.white),
                                                                textStyle:
                                                                    MaterialStateProperty
                                                                        .all(
                                                                            TextStyle(
                                                                  fontFamily:
                                                                      'Poppins',
                                                                  color: Colors
                                                                      .white,
                                                                  fontSize: 16,
                                                                  fontWeight: FontWeight.bold,
                                                                )),
                                                                elevation:
                                                                    MaterialStateProperty
                                                                        .all(0),
                                                              ),
                                                              onPressed:
                                                                  () async {
                                                                print('Team 2 button pressed: ${gameItem["abbreviation2"]}');
                                                                print('Current picks: ${dataProvider.playerPicks}');
                                                                
                                                                // Check if this team is already picked
                                                                bool hasTeam2 = dataProvider.playerPicks!.contains(gameItem["abbreviation2"]);
                                                                
                                                                if (hasTeam2) {
                                                                  // User is trying to pick the same team again
                                                                  await showDialog(
                                                                    context: context,
                                                                    builder: (alertDialogContext) {
                                                                      return AlertDialog(
                                                                        title: Text('Already picked!'),
                                                                        content: Text('You have already picked ${gameItem["abbreviation2"]} for this game.'),
                                                                        actions: [
                                                                          TextButton(
                                                                            onPressed: () => Navigator.pop(alertDialogContext),
                                                                            child: Text('OK'),
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
                                                                        'Selected: ${gameItem["abbreviation2"]}',
                                                                        style:
                                                                            TextStyle(
                                                                          color:
                                                                              Colors.white,
                                                                          fontSize:
                                                                              16,
                                                                        ),
                                                                      ),
                                                                      duration: Duration(
                                                                          milliseconds:
                                                                              1000),
                                                                      backgroundColor:
                                                                          Colors.green,
                                                                    ),
                                                                  );
                                                                  dataProvider
                                                                          .picked =
                                                                      true;
                                                                }

                                                                // Remove opposing team and add selected team
                                                                dataProvider
                                                                    .removeFromPlayerPicks(
                                                                        gameItem[
                                                                            "abbreviation"]);
                                                                dataProvider
                                                                    .addToPlayerPicks(
                                                                        gameItem[
                                                                            "abbreviation2"]);
                                                                print('Updated picks: ${dataProvider.playerPicks}');
                                                                
                                                                // Force rebuild to update visual state
                                                                setState(() {});
                                                              },
                                                              child: Container(
                                                                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                                decoration: BoxDecoration(
                                                                  color: dataProvider
                                                                          .playerPicks!
                                                                          .contains(gameItem[
                                                                              "abbreviation2"])
                                                                      ? const Color(0xFF063a73).withOpacity(0.95)
                                                                      : Colors.white.withOpacity(0.22),
                                                                  borderRadius: BorderRadius.circular(25),
                                                                  border: Border.all(
                                                                    color: Colors.white.withOpacity(0.25),
                                                                    width: 1,
                                                                  ),
                                                                ),
                                                                child: Row(
                                                                  mainAxisSize: MainAxisSize.min,
                                                                  children: [
                                                                    Text(
                                                                      gameItem[
                                                                          "abbreviation2"],
                                                                      style: TextStyle(
                                                                          fontWeight: FontWeight.bold,
                                                                          color: Colors.white,
                                                                          fontSize: 16),
                                                                    ),
                                                                    if (dataProvider
                                                                        .playerPicks!
                                                                        .contains(gameItem[
                                                                            "abbreviation2"]))
                                                                      Container(
                                                                        margin: EdgeInsets.only(left: 8),
                                                                        child: Icon(
                                                                          Icons.check_circle,
                                                                          color: Colors.white,
                                                                          size: 20,
                                                                        ),
                                                                      )
                                                                  ],
                                                                ),
                                                              )

                                                              ),
                                                          TeamLogo(
                                                            abbr: _getTeamAbbreviationWithFallback(gameItem, false),
                                                            size: 80,
                                                          ),
                                                        ],
                                                      ),
                                                      // if (FFAppState().picked !=
                                                      //     null)
                                                      Text(
                                                        _getPickText(gameItem, dataProvider),
                                                        style: TextStyle(
                                                          fontFamily: 'Poppins',
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.bold,
                                                          color: _getPickTextColor(gameItem, dataProvider),
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
                                var shouldSetState = false;
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
                                  return;
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
                                            '${resolved.lockedWeek} is locked — edits closed, no later week open.',
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                      return;
                                    }
                                    dataProvider
                                        .setActiveWeek(resolved.week!);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '${resolved.lockedWeek} locked — opening ${resolved.week} entry form.',
                                        ),
                                        backgroundColor: Colors.orange,
                                      ),
                                    );
                                    Navigator.pushAndRemoveUntil(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const HomePage(initial: 0),
                                      ),
                                      (route) => false,
                                    );
                                    return;
                                  }

                                  dataProvider.tiebreaker =
                                      int.parse(tieBreakerController.text);
                                  dataProvider.amount =
                                      dataProvider.countGames(
                                    dataProvider.playerPicks!.toList(),
                                  );
                                  shouldSetState = true;

                                  if (mounted) {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => PlayerPicksWidget(
                                          edit: true,
                                          id: id,
                                        ),
                                      ),
                                    );
                                  }
                                  if (shouldSetState && mounted) setState(() {});
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

  String _deriveAbbreviationFromName(String name) {
    final teamNameToAbbr = {
      'Philadelphia Eagles': 'PHI',
      'Dallas Cowboys': 'DAL',
      'Los Angeles Chargers': 'LAC',
      'Kansas City Chiefs': 'KC',
      'Atlanta Falcons': 'ATL',
      'Tampa Bay Buccaneers': 'TB',
      'Cleveland Browns': 'CLE',
      'Cincinnati Bengals': 'CIN',
      'Indianapolis Colts': 'IND',
      'Miami Dolphins': 'MIA',
      'New England Patriots': 'NE',
      'Las Vegas Raiders': 'LV',
      'New Orleans Saints': 'NO',
      'Arizona Cardinals': 'ARI',
      'New York Jets': 'NYJ',
      'Pittsburgh Steelers': 'PIT',
      'Washington Commanders': 'WAS',
      'New York Giants': 'NYG',
      'Buffalo Bills': 'BUF',
      'Baltimore Ravens': 'BAL',
      'Carolina Panthers': 'CAR',
      'Chicago Bears': 'CHI',
      'Denver Broncos': 'DEN',
      'Detroit Lions': 'DET',
      'Green Bay Packers': 'GB',
      'Houston Texans': 'HOU',
      'Jacksonville Jaguars': 'JAX',
      'Los Angeles Rams': 'LAR',
      'Minnesota Vikings': 'MIN',
      'San Francisco 49ers': 'SF',
      'Seattle Seahawks': 'SEA',
      'Tennessee Titans': 'TEN',
    };
    return teamNameToAbbr[name] ?? name.substring(0, 3).toUpperCase();
  }

  String _getPickText(Map<String, dynamic> gameItem, DataProvider dataProvider) {
    bool hasTeam1 = dataProvider.playerPicks!.contains(gameItem["abbreviation"]);
    bool hasTeam2 = dataProvider.playerPicks!.contains(gameItem["abbreviation2"]);
    
    if (hasTeam1) {
      return 'PICKED: ${gameItem["abbreviation"]}';
    } else if (hasTeam2) {
      return 'PICKED: ${gameItem["abbreviation2"]}';
    } else {
      return 'MAKE THE PICK!';
    }
  }

  Color _getPickTextColor(Map<String, dynamic> gameItem, DataProvider dataProvider) {
    bool hasTeam1 = dataProvider.playerPicks!.contains(gameItem["abbreviation"]);
    bool hasTeam2 = dataProvider.playerPicks!.contains(gameItem["abbreviation2"]);
    
    if (hasTeam1 || hasTeam2) {
      return const Color(0xFF69F0AE);
    } else {
      return Colors.white;
    }
  }

  String _getTeamAbbreviationWithFallback(Map<String, dynamic> gameItem, bool isHome) {
    final homeAbbr = gameItem["abbreviation"] ?? '';
    final awayAbbr = gameItem["abbreviation2"] ?? '';
    final homeName = gameItem["fullname"] ?? gameItem["home"] ?? '';
    final awayName = gameItem["fullname2"] ?? gameItem["away"] ?? '';
    
    if (isHome) {
      // Fallback: If abbreviations are the same or empty, derive from team name
      return (homeAbbr == awayAbbr || homeAbbr.isEmpty) && homeName.isNotEmpty 
          ? _deriveAbbreviationFromName(homeName)
          : homeAbbr;
    } else {
      // Fallback: If abbreviations are the same or empty, derive from team name
      return (homeAbbr == awayAbbr || awayAbbr.isEmpty) && awayName.isNotEmpty 
          ? _deriveAbbreviationFromName(awayName)
          : awayAbbr;
    }
  }
}
