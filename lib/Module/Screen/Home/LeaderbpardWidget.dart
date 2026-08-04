import 'package:poolqapp/constants.dart';
import 'games.dart';
import 'dart:convert';
import 'EditPlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:poolqapp/Provider/homeProvider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'Play.dart';
import '../../../services/nfl_schedule_service.dart';
import '../../../services/leaderboard_privacy_service.dart';
import '../../../services/payment_service.dart';
import '../../../services/app_config_service.dart';
import '../../../services/week_results_service.dart';
import '../../../constants/payment_status.dart';
import '../../../widgets/player/player_picks_modal.dart';
import '../../../widgets/leaderboard/leaderboard_podium.dart';
import '../../../utils/avatar_url.dart';

class LeaderboardWidget extends StatefulWidget {
  const LeaderboardWidget({Key? key}) : super(key: key);

  @override
  _LeaderboardWidgetState createState() => _LeaderboardWidgetState();
}

class _LeaderboardWidgetState extends State<LeaderboardWidget> {
  // late LeaderboardModel _model;
  User? user;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final _unfocusNode = FocusNode();
  // final Stream<QuerySnapshot> _leaderboard_recordStream =
  //     FirebaseFirestore.instance.collection('leaderboard_record').snapshots();

  List? data;
  List? data2;
  List? normal_data;
  var particularData;
  bool? played;
  bool _loadingLeaderboard = true;
  bool _entriesLocked = false;
  String _activeWeekName = 'PRE1';
  final LeaderboardPrivacyService _privacyService = LeaderboardPrivacyService();
  final WeekResultsService _weekResults = WeekResultsService();
  Set<String> _reigningChampionUids = {};
  int _gamesPlayedForWeek = 0;

  /// Expected pot (entrants × entry fee) | sum of confirmed payment fees.
  Widget _buildPotBadge() {
    final entrants = data?.length ?? 0;
    final expected = entrants * PaymentService.ENTRY_FEE;

    double confirmed = 0;
    if (data != null) {
      for (final row in data!) {
        if (row is! Map) continue;
        final status = (row['paymentStatus'] ?? '').toString();
        if (!PaymentStatus.isEligible(status)) continue;
        final fee = row['entryFee'];
        if (fee is num) {
          confirmed += fee.toDouble();
        } else {
          confirmed += PaymentService.ENTRY_FEE;
        }
      }
    }

    String money(double v) =>
        '\$${v.toStringAsFixed(v == v.roundToDouble() ? 0 : 2)}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Pot ',
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            money(expected),
            style: const TextStyle(
              color: Color(0xFFFFD54F), // expected total
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            ' | ',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            money(confirmed),
            style: TextStyle(
              color: confirmed >= expected && expected > 0
                  ? const Color(0xFF69F0AE) // fully confirmed
                  : const Color(0xFFFFAB40), // pending confirmations
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerTile(Map<String, dynamic> player, int index) {
    final uid = (player['uid'] ?? '').toString();
    final isMe = uid == (user?.uid ?? 'demo_user');
    final displayName = (player['displayName'] ?? 'Player').toString();
    final photoURL = (player['photoURL'] ?? '').toString();
    final email = (player['email'] ?? (isMe ? (user?.email ?? '') : '')).toString();
    final scoreText = _privacyService.getScoreDisplayText(
      player,
      entriesLocked: _entriesLocked,
      isCurrentUser: isMe,
    );
    final rawScore = player['score'];
    final scoreNum = rawScore is num ? rawScore.toInt() : null;
    final winPct = (_entriesLocked || isMe) &&
            scoreNum != null &&
            _gamesPlayedForWeek > 0
        ? ((scoreNum / _gamesPlayedForWeek) * 100).round()
        : null;
    final isChampion = _reigningChampionUids.contains(uid);
    final bg = (isMe ? const Color(0xFF063a73) : const Color(0xFF3474E0))
        .withOpacity(0.78);

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(10, 0, 10, 10),
      child: Material(
        color: Colors.transparent,
        elevation: 0,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _handlePlayerTap(Map<String, dynamic>.from(player)),
          child: Ink(
            height: 75,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isChampion
                    ? const Color(0xFFFFD54F)
                    : Colors.white.withOpacity(0.18),
                width: isChampion ? 1.5 : 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(15, 1, 1, 1),
                    child: SizedBox(
                      width: 54,
                      height: 54,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned(
                            top: 4,
                            left: 2,
                            child: ClipOval(
                              child: SizedBox(
                                height: 50,
                                width: 50,
                                child: Image(
                                  image: resolveAvatarImage(
                                    photoUrl: photoURL,
                                    email: email,
                                    size: 100,
                                  ),
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Image.asset(
                                    'assets/images/user.png',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (isChampion)
                            const Positioned(
                              top: -4,
                              right: -2,
                              child: Text('👑', style: TextStyle(fontSize: 16)),
                            ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(14, 8, 4, 0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  displayName.toUpperCase(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontFamily: 'Lexend Deca',
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              if (isMe) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.25),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.green),
                                  ),
                                  child: Text(
                                    _entriesLocked ? 'YOU' : 'EDIT',
                                    style: const TextStyle(
                                      color: Colors.greenAccent,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          Text(
                            'WEEK ${selectedValue ?? ''} · #${player['rank'] ?? (index + 1)}'
                                .toUpperCase(),
                            style: const TextStyle(
                              fontFamily: 'Lexend Deca',
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        winPct != null
                            ? '$scoreNum · $winPct%'
                            : scoreText.toUpperCase(),
                        style: const TextStyle(
                          fontFamily: 'Lexend Deca',
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded,
                          color: Colors.white70, size: 28),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handlePlayerTap(Map<String, dynamic> player) {
    final rowUserId = (player['uid'] ?? '').toString();
    final isMe = rowUserId == (user?.uid ?? 'demo_user');
    final weekName = _activeWeekName;

    if (!isMe &&
        !_privacyService.canViewPlayerPicks(
          targetPlayerId: rowUserId,
          entriesLocked: _entriesLocked,
        )) {
      _privacyService.showRestrictedAccessDialog(context);
      return;
    }

    if (isMe && !_entriesLocked) {
      // Own picks before lock — review/edit
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => EditPlayWidget()),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (_) => PlayerPicksModal(
        playerData: player,
        games: data2?.cast<Map<String, dynamic>>() ?? const [],
        weekName: weekName,
        hidePrivateInfo: !isMe && !_entriesLocked,
      ),
    );
  }

  Future<void> _showPaymentModal(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Complete Payment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('Entry fee: \$10.00'),
              SizedBox(height: 8),
              Text('Pay using one of the methods below:'),
              SizedBox(height: 8),
              SelectableText('Venmo: https://venmo.com/u/PoolQPayments'),
              SelectableText('PayPal: poolq.payments@gmail.com'),
              SelectableText('Zelle: poolq.payments@gmail.com'),
              SelectableText('Cash App: \$PoolQPayments'),
              SizedBox(height: 12),
              Text(
                'Your picks will be submitted but will be ineligible if payment is not received before kickoff',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.orange,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop(); // Close modal first
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PlayWidget(),
                  ),
                );
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  Future getGame(context, selectedValue) async {
    DataProvider dataProvider = Provider.of<DataProvider>(context, listen: false);
    final scheduleService = NFLScheduleService();
    
    // Check if we're in demo mode
    print('LeaderboardWidget: Checking demo mode for games - user = ${user?.email ?? "null"}');
    if (user == null || user?.email == 'demo@poolq.com') {
      print('LeaderboardWidget: Demo mode detected, using mock game data');
      
      // Use mock games data for demo - actual preseason Week 1 games
      List<Map<String, dynamic>> mockGames = [
        {
          "id": "demo-game-1",
          "date": "2025-08-08T17:00:00Z",
          "homeTeam": "Detroit Lions",
          "awayTeam": "Atlanta Falcons",
          "homeAbbr": "DET",
          "awayAbbr": "ATL",
          "homeScore": null,
          "awayScore": null,
          "status": "scheduled",
        },
        {
          "id": "demo-game-2", 
          "date": "2025-08-08T17:00:00Z",
          "homeTeam": "Cleveland Browns",
          "awayTeam": "Carolina Panthers",
          "homeAbbr": "CLE",
          "awayAbbr": "CAR",
          "homeScore": null,
          "awayScore": null,
          "status": "scheduled",
        },
        {
          "id": "demo-game-3",
          "date": "2025-08-08T17:30:00Z", 
          "homeTeam": "Washington Commanders",
          "awayTeam": "New England Patriots",
          "homeAbbr": "WAS",
          "awayAbbr": "NE",
          "homeScore": null,
          "awayScore": null,
          "status": "scheduled",
        },
      ];
      
      setState(() {
        data2 = mockGames;
      });
      print('Successfully loaded ${mockGames.length} mock games for leaderboard');
      return mockGames;
    }
    
    try {
      print('Fetching games for leaderboard...');
      final mode = dataProvider.game?["mode"]?.toString() ?? 'PRE';
      final weekName = "$mode$selectedValue";

      // Prefer local 2026 schedule for stable matchups display.
      List<Map<String, dynamic>> games =
          await scheduleService.getScheduleForWeekWithLocalFallback(weekName);
      if (games.isEmpty) {
        games = await scheduleService.getScheduleWithFallback(weekName);
      }

      if (games.isNotEmpty) {
        if (mounted) {
          setState(() {
            data2 = games;
          });
        }
        print('Loaded ${games.length} games for $weekName');
        return games;
      }

      print('Trying original API for leaderboard: ${mainUrl}/getnlf/$weekName');
      var response = await http.get(
        Uri.parse('${mainUrl}/getnlf/$weekName'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Access-Control-Allow-Origin': '*',
        },
      ).timeout(Duration(seconds: 20));

      if (response.statusCode == 200) {
        var body = json.decode(response.body);
        if (body is List && body.isNotEmpty) {
          if (mounted) setState(() => data2 = body);
          return body;
        }
      }
    } catch (e) {
      print('Error fetching games for leaderboard: $e');
    }

    if (mounted) setState(() => data2 = []);
    return [];
  }

  // ${mainUrl}/getnlf/${dataProvider.game!["mode"]}${widget.selectedValue}
  Future getLeaderBoard(context, selectedValue) async {
    if (mounted) {
      setState(() => _loadingLeaderboard = true);
    }
    DataProvider dataProvider =
        Provider.of<DataProvider>(context, listen: false);

    final mode = dataProvider.game?["mode"]?.toString() ?? 'PRE';
    // Always honor the week picker selection (do not reuse stale game.name).
    final weekName = "$mode$selectedValue";
    if (dataProvider.game?['name']?.toString() != weekName) {
      dataProvider.setActiveWeek(weekName);
    }

    final entriesLocked =
        await _privacyService.areEntriesLocked(weekName);
    if (mounted) {
      setState(() {
        _entriesLocked = entriesLocked;
        _activeWeekName = weekName;
      });
    }

    // Authenticated players: load week entrants from Firestore pickrecord.
    if (user != null && user?.email != 'demo@poolq.com') {
      try {
        final snap = await FirebaseFirestore.instance
            .collection('pickrecord')
            .where('week', isEqualTo: weekName)
            .get();

        List<Map<String, dynamic>> rows = snap.docs.map((doc) {
          final d = doc.data();
          return <String, dynamic>{
            'id': doc.id,
            'uid': d['uid'] ?? '',
            'displayName': (d['displayName'] ?? 'Player').toString(),
            'photoURL': d['photoURL'] ?? '',
            'email': (d['email'] ?? '').toString(),
            'score': d['score'],
            'picks': List<String>.from(d['picks'] ?? const []),
            'tiebreaker': d['tiebreaker'],
            'week': d['week'] ?? weekName,
            'paymentStatus': d['paymentStatus'] ?? 'pending',
            'entryFee': () {
              final fee = d['entryFee'];
              if (fee is num) return fee.toDouble();
              final freePre = AppConfigService().preseasonFree &&
                  weekName.toUpperCase().startsWith('PRE');
              return freePre ? 0.0 : PaymentService.ENTRY_FEE;
            }(),
            'isActive': d['isActive'] ?? true,
            'rank': d['rank'],
            'hasSubmittedPicks': true,
          };
        }).where((e) => e['isActive'] != false).toList();

        // Backfill emails for older pickrecords (needed for Gravatar).
        final missingEmailUids = rows
            .where((e) => (e['email'] as String).isEmpty &&
                (e['uid'] as String).isNotEmpty)
            .map((e) => e['uid'] as String)
            .toSet()
            .toList();
        if (missingEmailUids.isNotEmpty) {
          try {
            // Firestore whereIn limit is 10 — chunk if needed.
            for (var i = 0; i < missingEmailUids.length; i += 10) {
              final chunk = missingEmailUids.sublist(
                i,
                (i + 10 > missingEmailUids.length)
                    ? missingEmailUids.length
                    : i + 10,
              );
              final usersSnap = await FirebaseFirestore.instance
                  .collection('users')
                  .where(FieldPath.documentId, whereIn: chunk)
                  .get();
              final byId = {
                for (final u in usersSnap.docs)
                  u.id: (u.data()['email'] ?? '').toString(),
              };
              for (final row in rows) {
                final uid = row['uid'] as String;
                if ((row['email'] as String).isEmpty &&
                    byId[uid]?.isNotEmpty == true) {
                  row['email'] = byId[uid];
                }
              }
            }
          } catch (e) {
            print('LeaderboardWidget: email backfill failed: $e');
          }
        }

        // Current user always gets their Auth email for avatar.
        if (user?.email != null && user!.email!.isNotEmpty) {
          for (final row in rows) {
            if (row['uid'] == user!.uid) {
              row['email'] = user!.email;
              if ((row['photoURL'] as String).isEmpty &&
                  (user!.photoURL?.isNotEmpty ?? false)) {
                row['photoURL'] = user!.photoURL;
              }
            }
          }
        }

        rows.sort((a, b) {
          final as = a['score'];
          final bs = b['score'];
          if (as == null && bs == null) {
            return (a['displayName'] as String)
                .compareTo(b['displayName'] as String);
          }
          if (as == null) return 1;
          if (bs == null) return -1;
          final cmp = (bs as num).compareTo(as as num);
          if (cmp != 0) return cmp;
          return (a['displayName'] as String)
              .compareTo(b['displayName'] as String);
        });

        for (var i = 0; i < rows.length; i++) {
          rows[i]['rank'] = i + 1;
        }

        rows = _privacyService.sanitizeLeaderboardData(
          rows,
          entriesLocked: entriesLocked,
        );

        final rankedForPodium = List<Map<String, dynamic>>.from(rows);

        // Pin current user to top for easy access to "my picks".
        Map<String, dynamic>? mine;
        final uid = user?.uid;
        if (uid != null) {
          final idx = rows.indexWhere((e) => e['uid'] == uid);
          if (idx >= 0) {
            mine = rows.removeAt(idx);
            rows = [mine, ...rows];
          }
        }

        final champs = await _weekResults.getReigningChampionUids();
        final weekResult = await _weekResults.getWeekResult(weekName);
        var gamesPlayed = (weekResult?['gamesPlayed'] as num?)?.toInt() ?? 0;
        if (gamesPlayed <= 0 && data2 is List && data2!.isNotEmpty) {
          gamesPlayed = data2!.length;
        }
        if (gamesPlayed <= 0) {
          final maxScore = rankedForPodium
              .map((e) => (e['score'] as num?)?.toInt() ?? 0)
              .fold<int>(0, (a, b) => a > b ? a : b);
          gamesPlayed = maxScore;
        }

        if (!mounted) return rows;
        setState(() {
          data = rows;
          normal_data = rankedForPodium;
          played = rows.isNotEmpty;
          particularData = mine ?? (rows.isNotEmpty ? rows.first : 'null');
          _loadingLeaderboard = false;
          _reigningChampionUids = champs;
          _gamesPlayedForWeek = gamesPlayed;
        });
        return rows;
      } catch (e) {
        print('LeaderboardWidget: Firestore leaderboard error: $e');
        if (mounted) {
          setState(() {
            data = [];
            normal_data = [];
            played = false;
            particularData = 'null';
            _loadingLeaderboard = false;
          });
        }
        return [];
      }
    }

    // Demo / unauthenticated fallback (local mock only)
    print('LeaderboardWidget: Checking demo mode - user = ${user?.email ?? "null"}');
    if (user == null || user?.email == 'demo@poolq.com') {
      print('LeaderboardWidget: Demo mode detected, using hardcoded demo data instead of Firestore');
      
      // Define weekName outside try block so it's accessible in catch block
      // (weekName already computed above)
      
      try {
        // Use hardcoded demo leaderboard data to avoid Firestore permission issues
        
        print('LeaderboardWidget: Creating hardcoded demo leaderboard for week $weekName');
        
        List<Map<String, dynamic>> demoLeaderboard = [];
        
        // Determine if this week is completed (has final scores) or in progress
        final isWeekCompleted = false; // No weeks are completed yet - scores should be hidden
        final isCurrentWeek = weekName == 'REG1' || weekName == 'PRE1';
        
        // Add single demo user entry (the actual user) - only ONE entry
        final currentDemoUser = {
          "uid": "demo_user_current",
          "displayName": "Demo User (Current Session)",
          "photoURL": "",
          "score": isWeekCompleted ? 8 : 0, // Show score only if week is completed
          "picks": isCurrentWeek ? [] : ["DAL", "LAC", "ATL", "NYJ", "IND", "JAX", "WAS", "ARI", "CIN", "SF", "LV", "DEN", "GB", "LAR", "BUF"], // Empty picks for current week
          "tiebreaker": isCurrentWeek ? null : 50,
          "rank": isWeekCompleted ? 5 : 1, // Rank based on completion status
          "week": weekName,
          "hasSubmittedPicks": !isCurrentWeek,
          "paymentStatus": "verified", // Demo user is always verified
        };
        demoLeaderboard.add(currentDemoUser);
        
        // Add AI players with proper Week 1 2025 picks and scores
        final samplePlayers = [
          {"uid": "demo_mike", "displayName": "Mike Johnson", "score": isWeekCompleted ? 12 : 0, "picks": ["PHI", "KC", "TB", "PIT", "MIA", "CAR", "NYG", "NO", "CLE", "NE", "SEA", "TEN", "DET", "HOU", "BAL"], "tiebreaker": 24, "paymentStatus": "verified"},
          {"uid": "demo_jessica", "displayName": "Jessica Chen", "score": isWeekCompleted ? 11 : 0, "picks": ["DAL", "LAC", "ATL", "NYJ", "IND", "JAX", "WAS", "ARI", "CIN", "SF", "LV", "DEN", "GB", "LAR", "BUF"], "tiebreaker": 17, "paymentStatus": "pending"},
          {"uid": "demo_alex", "displayName": "Alex Rodriguez", "score": isWeekCompleted ? 10 : 0, "picks": ["PHI", "KC", "TB", "PIT", "MIA", "CAR", "NYG", "NO", "CLE", "NE", "SEA", "TEN", "DET", "HOU", "BAL"], "tiebreaker": 19, "paymentStatus": "verified"},
          {"uid": "demo_emma", "displayName": "Emma Thompson", "score": isWeekCompleted ? 9 : 0, "picks": ["DAL", "LAC", "ATL", "NYJ", "IND", "JAX", "WAS", "ARI", "CIN", "SF", "LV", "DEN", "GB", "LAR", "BUF"], "tiebreaker": 22, "paymentStatus": "unpaid"},
        ];
        
        for (int i = 0; i < samplePlayers.length; i++) {
          final player = samplePlayers[i];
          demoLeaderboard.add({
            "uid": player["uid"],
            "displayName": player["displayName"],
            "photoURL": "",
            "score": player["score"],
            "picks": player["picks"],
            "tiebreaker": player["tiebreaker"],
            "rank": i + 2, // Start from rank 2 since current user is rank 1
            "week": weekName,
            "paymentStatus": player["paymentStatus"],
          });
        }
        
        print('LeaderboardWidget: Created ${demoLeaderboard.length} demo leaderboard entries');

        // Skip Firestore query completely in demo mode to avoid permission issues
        print('LeaderboardWidget: Skipping Firestore query in demo mode to avoid permission errors');

        setState(() {
          data = demoLeaderboard;
          normal_data = [...demoLeaderboard];
          this.played = true;
          particularData = demoLeaderboard.first; // Current demo user is always first
          _loadingLeaderboard = false;
        });
        
        print('Successfully loaded ${demoLeaderboard.length} demo leaderboard entries (no Firestore query in demo mode)');
        print('Demo leaderboard entries: ${demoLeaderboard.map((e) => e['displayName']).toList()}');
        return demoLeaderboard;
      } catch (e) {
        print('Error fetching demo entries, using fallback: $e');
        
        // Fallback: Use same logic as above to avoid duplicates
        final isWeekCompletedFallback = false; // No weeks are completed yet - scores should be hidden
        List<Map<String, dynamic>> fallbackLeaderboard = [
          {
            "uid": "demo_user_current",
            "displayName": "Demo User (Current Session)",
            "photoURL": "",
            "score": isWeekCompletedFallback ? 8 : 0,
            "picks": isWeekCompletedFallback ? ["DAL", "LAC", "ATL", "NYJ", "IND", "JAX", "WAS", "ARI", "CIN", "SF", "LV", "DEN", "GB", "LAR", "BUF"] : [],
            "tiebreaker": isWeekCompletedFallback ? 50 : null,
            "rank": isWeekCompletedFallback ? 5 : 1,
            "week": weekName,
            "hasSubmittedPicks": isWeekCompletedFallback,
          },
          {
            "uid": "demo_mike",
            "displayName": "Mike Johnson",
            "photoURL": "",
            "score": isWeekCompletedFallback ? 12 : 0,
            "picks": ["PHI", "KC", "TB", "PIT", "MIA", "CAR", "NYG", "NO", "CLE", "NE", "SEA", "TEN", "DET", "HOU", "BAL"],
            "tiebreaker": 24,
            "rank": isWeekCompletedFallback ? 1 : 2,
            "week": weekName,
          },
          {
            "uid": "demo_jessica",
            "displayName": "Jessica Chen",
            "photoURL": "",
            "score": isWeekCompletedFallback ? 11 : 0,
            "picks": ["DAL", "LAC", "ATL", "NYJ", "IND", "JAX", "WAS", "ARI", "CIN", "SF", "LV", "DEN", "GB", "LAR", "BUF"],
            "tiebreaker": 17,
            "rank": isWeekCompletedFallback ? 2 : 3,
            "week": weekName,
          },
          {
            "uid": "demo_alex",
            "displayName": "Alex Rodriguez",
            "photoURL": "",
            "score": isWeekCompletedFallback ? 10 : 0,
            "picks": ["PHI", "KC", "TB", "PIT", "MIA", "CAR", "NYG", "NO", "CLE", "NE", "SEA", "TEN", "DET", "HOU", "BAL"],
            "tiebreaker": 19,
            "rank": isWeekCompletedFallback ? 3 : 4,
            "week": weekName,
          },
          {
            "uid": "demo_emma",
            "displayName": "Emma Thompson",
            "photoURL": "",
            "score": isWeekCompletedFallback ? 9 : 0,
            "picks": ["DAL", "LAC", "ATL", "NYJ", "IND", "JAX", "WAS", "ARI", "CIN", "SF", "LV", "DEN", "GB", "LAR", "BUF"],
            "tiebreaker": 22,
            "rank": isWeekCompletedFallback ? 4 : 5,
            "week": weekName,
          },
        ];
        
        setState(() {
          data = fallbackLeaderboard;
          normal_data = [...fallbackLeaderboard];
          this.played = true;
          particularData = fallbackLeaderboard.first;
          _loadingLeaderboard = false;
        });
        
        return fallbackLeaderboard;
      }
    }
    
    // Should not reach here for normal users
    if (mounted) {
      setState(() {
        data = [];
        normal_data = [];
        played = false;
        particularData = "null";
        _loadingLeaderboard = false;
      });
    }
    return [];
  }

  String? selectedValue;

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
    print('🌟🌟🌟🌟🌟 LEADERBOARD WIDGET INITSTATE CALLED! 🌟🌟🌟🌟🌟');
    DataProvider dataProvider =
        Provider.of<DataProvider>(context, listen: false);
    
    print('LeaderboardWidget: initState called');
    print('LeaderboardWidget: user = ${user?.email ?? "null"}');
    print('LeaderboardWidget: dataProvider.game = ${dataProvider.game}');

    // Start empty; show spinner until getLeaderBoard finishes.
    setState(() {
      data = [];
      normal_data = [];
      particularData = "null";
      played = false;
      _loadingLeaderboard = true;
    });
    
    // Check if dataProvider.game is null
    if (dataProvider.game != null) {
      selectedValue = dataProvider.game!["name"]
          .toString()
          .replaceAll("REG", "")
          .replaceAll("PRE", "");
      print('LeaderboardWidget: selectedValue = $selectedValue');
      getLeaderBoard(context, selectedValue);
      getGame(context, selectedValue);
    } else {
      print('LeaderboardWidget: dataProvider.game is null, using default PRE1');
      selectedValue = "1"; // Default for PRE1
      getLeaderBoard(context, selectedValue);
      getGame(context, selectedValue);
    }
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
    print('🎯🎯🎯 MAIN LEADERBOARD WIDGET IS BUILDING NOW! 🎯🎯🎯');
    print('🎯 LeaderboardWidget: BUILD METHOD CALLED - Main leaderboard is displaying');
    print('🎯 LeaderboardWidget: data length = ${data?.length ?? 0}, particularData = ${particularData != null ? "exists" : "null"}');
    
    // context.watch<FFAppState>();
    DataProvider dataProvider =
        Provider.of<DataProvider>(context, listen: true);
    // AuthProviders authProvider =
    //     Provider.of<AuthProviders>(context, listen: true);

    return GestureDetector(
      onTap: () => FocusScope.of(context).requestFocus(_unfocusNode),
      child: Scaffold(
        // bottomNavigationBar: Container(
        //     color: Colors.white,
        //     child: kIsWeb?AdmobBanner(
        //       adUnitId: Provider.of<DataProvider>(context, listen: false)
        //           .getBannerAdUnitId().toString(),
        //       adSize: AdmobBannerSize.BANNER,
        //       listener: (AdmobAdEvent event, Map<String, dynamic> ?args) {},
        //     ):Container()),
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
                Material(
                  color: _entriesLocked
                      ? const Color(0xFF2E7D32)
                      : const Color(0xFF063a73),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Row(
                      children: [
                        Icon(
                          _entriesLocked ? Icons.lock_open : Icons.lock_outline,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '$_activeWeekName · ${data?.length ?? 0} entrants · '
                            '${_privacyService.getPrivacyStatusMessage(entriesLocked: _entriesLocked)}'
                            '${_entriesLocked ? '' : ' Tap your name to review picks.'}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildPotBadge(),
                      ],
                    ),
                  ),
                ),
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
                                  'assets/images/poolq12.png',
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
                                    'Hello, ${user?.displayName ?? 'Demo User'}!'
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
                                    if (dataProvider.game!["mode"] == null) {
                                    } else if (dataProvider.game!["mode"] ==
                                        "PRE") {
                                      _showPicker2(context);
                                    } else {
                                      _showPicker(context);
                                    }
                                  },
                                  child: Row(
                                    children: [
                                      dataProvider.game!["mode"] == null
                                          ? Container()
                                          : dataProvider.game!["mode"] == "REG"
                                              ? Padding(
                                                  padding: EdgeInsetsDirectional
                                                      .fromSTEB(0, 0, 0, 0),
                                                  child: Text(
                                                    'Week: ${selectedValue} '
                                                        .toUpperCase(),
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontFamily: 'Poppins',
                                                      fontSize: 15,
                                                    ),
                                                  ),
                                                )
                                              : Padding(
                                                  padding: EdgeInsetsDirectional
                                                      .fromSTEB(0, 0, 0, 0),
                                                  child: Text(
                                                    'PRESEASON: ${selectedValue} '
                                                        .toUpperCase(),
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                          Row(
                            children: [
                              Builder(builder: (context) {
                                final currentUserId = user?.uid ?? 'demo_user';
                                // For demo mode, always show "Play Now" to create new unique entrants for testing
                                bool hasEntry = false;
                                if (user != null && user?.email != 'demo@poolq.com') {
                                  // Normal mode: check if user has any entry
                                  hasEntry = (data != null && data!.any((e) => e['uid'] == currentUserId));
                                } else {
                                  // Demo mode: always allow new entries for testing multiple entrants
                                  hasEntry = false;
                                  
                                  // Check if we have local storage data about a recent submission
                                  try {
                                    final timestamp = DateTime.now().millisecondsSinceEpoch;
                                    print('Demo mode: Allowing new entry creation (timestamp: $timestamp)');
                                  } catch (e) {
                                    print('Error checking local storage: $e');
                                  }
                                }
                                final label = hasEntry ? 'Edit Picks' : 'Confirm';
                                return ElevatedButton(
                                  onPressed: () async {
                                    if (!hasEntry) {
                                      await _showPaymentModal(context);
                                    } else {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => EditPlayWidget(),
                                        ),
                                      );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primary,
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Text(
                                    label,
                                    style: TextStyle(
                                      fontFamily: 'Lexend Deca',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                );
                              }),
                              SizedBox(width: 16),
                              Builder(builder: (_) {
                                final allFinal = (data2 != null && data2!.isNotEmpty) && data2!.every((g) {
                                  final s = (g['status'] ?? '').toString().toLowerCase();
                                  return s == 'final' || s == 'completed';
                                });
                                if (!allFinal) return const SizedBox.shrink();
                                return InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => GamePlayWidget(selectedValue: selectedValue),
                                      ),
                                    );
                                  },
                                  child: Padding(
                                    padding: EdgeInsetsDirectional.fromSTEB(2, 0, 0, 0),
                                    child: Text(
                                      'View Game Scores'.toUpperCase(),
                                      style: TextStyle(
                                        fontFamily: 'Lexend Deca',
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (_loadingLeaderboard)
                  const Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xFF063a73)),
                        strokeWidth: 2,
                        backgroundColor: Colors.white,
                      ),
                    ),
                  )
                else if (data == null || data!.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(40.0),
                    child: Text(
                      "No entrants for this week yet",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.only(top: 8, bottom: 24),
                      itemCount: () {
                        final ranked = (normal_data ?? data)!;
                        final showPodium = _entriesLocked &&
                            ranked.any((e) =>
                                e is Map && (e['score'] as num?) != null);
                        final restCount = showPodium
                            ? (data!.length > 3 ? data!.length - 3 : 0)
                            : data!.length;
                        return (showPodium ? 1 : 0) + restCount;
                      }(),
                      itemBuilder: (BuildContext context, int index) {
                        final ranked = List<Map<String, dynamic>>.from(
                          (normal_data ?? data)!
                              .whereType<Map>()
                              .map((e) => Map<String, dynamic>.from(e)),
                        );
                        final showPodium = _entriesLocked &&
                            ranked.any((e) => (e['score'] as num?) != null);
                        final podiumPlayers = ranked.take(3).toList();

                        if (showPodium && index == 0) {
                          return LeaderboardPodium(
                            top3: podiumPlayers,
                            reigningChampionUids: _reigningChampionUids,
                            gamesPlayed: _gamesPlayedForWeek > 0
                                ? _gamesPlayedForWeek
                                : null,
                            subtitle: '$_activeWeekName TOP 3',
                            onTap: (p) => _handlePlayerTap(p),
                          );
                        }

                        // List remaining players (or full list if no podium).
                        final listSource = showPodium
                            ? data!
                                .whereType<Map>()
                                .map((e) => Map<String, dynamic>.from(e))
                                .where((e) {
                                  final uid = '${e['uid']}';
                                  return !podiumPlayers
                                      .any((p) => '${p['uid']}' == uid);
                                })
                                .toList()
                            : data!
                                .whereType<Map>()
                                .map((e) => Map<String, dynamic>.from(e))
                                .toList();
                        final rowIndex = showPodium ? index - 1 : index;
                        if (rowIndex < 0 || rowIndex >= listSource.length) {
                          return const SizedBox.shrink();
                        }
                        final row = listSource[rowIndex];
                        final displayIndex = showPodium ? rowIndex + 3 : rowIndex;
                        return _buildPlayerTile(row, displayIndex);
                      },
                    ),
                  )

              ],
            ),
          ],
        ),
      ),
    );
  }

  void _applyWeekSelection(BuildContext context, String weekNumber) {
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    final mode = dataProvider.game?["mode"]?.toString() ?? 'PRE';
    final weekName = "$mode$weekNumber";
    dataProvider.setActiveWeek(weekName);
    setState(() {
      selectedValue = weekNumber;
      data = null;
      data2 = null;
      _loadingLeaderboard = true;
      _activeWeekName = weekName;
    });
    getLeaderBoard(context, weekNumber);
    getGame(context, weekNumber);
  }

  void _showWeekPicker(
    BuildContext ctx, {
    required String title,
    required List<String> weekNumbers,
    required String labelPrefix,
  }) {
    var temp = selectedValue?.toString() ?? weekNumbers.first;
    if (!weekNumbers.contains(temp)) temp = weekNumbers.first;
    final initial = weekNumbers.indexOf(temp).clamp(0, weekNumbers.length - 1);

    showCupertinoModalPopup(
      barrierDismissible: true,
      context: ctx,
      builder: (_) => ClipRRect(
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(16),
          topLeft: Radius.circular(16),
        ),
        child: Material(
          color: Colors.white,
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _applyWeekSelection(context, temp);
                        },
                        child: const Text(
                          "Done",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 160,
                  width: MediaQuery.of(context).size.width,
                  child: CupertinoPicker(
                    backgroundColor: Colors.white,
                    itemExtent: 32,
                    scrollController:
                        FixedExtentScrollController(initialItem: initial),
                    onSelectedItemChanged: (value) {
                      temp = weekNumbers[value];
                    },
                    children: [
                      for (final n in weekNumbers)
                        Center(child: Text('$labelPrefix $n')),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPicker(BuildContext ctx) {
    _showWeekPicker(
      ctx,
      title: "Select week",
      weekNumbers: [for (var i = 1; i <= 18; i++) '$i'],
      labelPrefix: "Week",
    );
  }

  void _showPicker2(BuildContext ctx) {
    // NFL preseason pool weeks only (PRE1–PRE3). HoF is PRE0, not a pool week.
    _showWeekPicker(
      ctx,
      title: "Select preseason week",
      weekNumbers: const ['1', '2', '3'],
      labelPrefix: "Preseason",
    );
  }

}
