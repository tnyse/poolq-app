import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/schedule_cache_service.dart';

// Import Platform class
import 'platform_stub.dart' if (dart.library.io) 'dart:io' as platform;

// //import 'package:admob_flutter/admob_flutter.dart';

class DataProvider with ChangeNotifier {
  List<String>? playerPicks = [];
  bool picked = false;
  int pageIndex = 0;

  setPlayerPicks(List<String> value) {
    print('DataProvider: setPlayerPicks() called with: $value');
    playerPicks = value;
    notifyListeners();
  }

  clearPlayerPicks() {
    print('DataProvider: clearPlayerPicks() called - before: picks=${playerPicks}, tiebreaker=${tiebreaker}');
    playerPicks = [];
    tiebreaker = null;
    print('DataProvider: clearPlayerPicks() called - after: picks=${playerPicks}, tiebreaker=${tiebreaker}');
    notifyListeners();
  }

  int? tiebreaker;

  setTieBreaker(value) {
    tiebreaker = value;
    notifyListeners();
  }

  int? amount;

  /// Switch the active pick week (e.g. late entrant forwarded past a locked week).
  void setActiveWeek(String weekName, {String? year}) {
    final mode = weekName.startsWith('PRE')
        ? 'PRE'
        : weekName.startsWith('POST')
            ? 'POST'
            : 'REG';
    game = {
      'name': weekName,
      'year': year ?? game?['year']?.toString() ?? DateTime.now().year.toString(),
      'mode': mode,
    };
    clearPlayerPicks();
    debugPrint('DataProvider: setActiveWeek => $game');
    notifyListeners();
  }

  setValue(value) {
    pageIndex = value;
    notifyListeners();
  }

  int countGames(List<String>? playerPicks) {
    // return the number of items in a list of playerPicks
    int _c = playerPicks?.length ?? 0;
    return _c;
  }

  removeFromPlayerPicks(value) {
    final team = value?.toString().trim() ?? '';
    if (team.isEmpty || playerPicks == null) return;
    playerPicks!.removeWhere((p) => p.toString().trim() == team);
    notifyListeners();
  }

  addToPlayerPicks(value) {
    final team = value?.toString().trim() ?? '';
    if (team.isEmpty) return;
    playerPicks ??= [];
    if (!playerPicks!.contains(team)) {
      playerPicks!.add(team);
    }
    notifyListeners();
  }

  Map? game;
  // Commented out external API fetch for getWeek
  //   var response = await http.get(Uri.parse('24{mainUrl}/get_week'), headers: {
  //     'Content-Type': 'application/json; charset=UTF-8',
  //     'Access-Control-Allow-Origin': '*',
  //   }).timeout(Duration(seconds: 20));

  // Simplified checkWeek method to avoid long if-else chain
  checkWeek(week) {
    if (week == null) return "REG1";
    
    // Regular season weeks
    for (int i = 1; i <= 18; i++) {
      if (week == "REG$i") return "REG$i";
    }
    
    // Preseason weeks
    for (int i = 1; i <= 10; i++) {
      if (week == "PRE$i") return "PRE$i";
    }
    
    return week; // Default fallback
  }

  // AdmobBannerSize ?bannerSize;
  // AdmobInterstitial ?instatitialAd;

  String? getBannerAdUnitId() {
    if (kIsWeb) {
      return 'ca-app-pub-1065880110189655/6603671564'; // Web ad unit
    } else {
      if (platform.Platform.isIOS) {
        return 'ca-app-pub-1065880110189655/6603671564';
      } else if (platform.Platform.isAndroid) {
        return 'ca-app-pub-1065880110189655/6603671564';
      }
    }
    return null;
  }

  String? getInterstitialAdUnitId() {
    if (kIsWeb) {
      return 'ca-app-pub-1065880110189655/4709728289'; // Web ad unit
    } else {
      if (platform.Platform.isIOS) {
        return 'ca-app-pub-1065880110189655/4709728289';
      } else if (platform.Platform.isAndroid) {
        return 'ca-app-pub-1065880110189655/4709728289';
      }
    }
    return null;
  }

  List? data;

  Future getGame() async {
    try {
      // Do NOT overwrite week from getWeek() — only refresh countdown date labels.
      if (game == null) {
        await getWeek();
      }
      final weekName = game?['name']?.toString() ?? 'PRE1';
      final isPreseason = weekName.startsWith('PRE');
      debugPrint('DataProvider: getGame() for $weekName (preserving week)');
      data = isPreseason ? [
        "Thursday August 13TH, 2026",
        "Friday August 14TH, 2026",
        "Saturday August 15TH, 2026",
        "Sunday August 16TH, 2026"
      ] : [
        "Thursday September 10TH, 2026",
        "Sunday September 13TH, 2026",
        "Monday September 14TH, 2026"
      ];
      notifyListeners();
      return data;
    } catch (e) {
      debugPrint('Error fetching game data: $e');
      data = [
        "Thursday August 13TH, 2026",
        "Friday August 14TH, 2026",
        "Saturday August 15TH, 2026"
      ];
      notifyListeners();
      return data;
    }
  }

  Future<void> getWeek() async {
    try {
      debugPrint('DataProvider: Starting getWeek()');
      
      // Use cache service for current week
      final cacheService = ScheduleCacheService();
      final currentWeek = await cacheService.getCurrentWeek().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint('DataProvider: getCurrentWeek() timed out, using default values');
          return {
            'week': 'PRE1',
            'season_type': 1, // preseason
            'season': DateTime.now().year,
            'seasonName': 'PRE',
            'mode': 'PRE',
            'year': DateTime.now().year,
          };
        },
      );
      
      debugPrint('DataProvider: currentWeek from cache: $currentWeek');
      if (currentWeek != null) {
        // Handle the case where 'week' already includes the mode (e.g., 'PRE1')
        String weekName = currentWeek['week']?.toString() ?? 'PRE1';
        String mode = currentWeek['mode']?.toString() ?? 'PRE';
        String year = currentWeek['year']?.toString() ?? DateTime.now().year.toString();
        
        game = {
          "name": weekName,
          "year": year,
          "mode": mode
        };
      } else {
        debugPrint('DataProvider: currentWeek is null, using default PRE1');
        game = {"name": "PRE1", "year": "2026", "mode": "PRE"};
      }
      debugPrint('DataProvider: game set to: $game');
      notifyListeners();
      
    } catch (e) {
      debugPrint('DataProvider: Error getting current week: $e');
      // Default to PRE1 if there's an error
      game = {"name": "PRE1", "year": "2026", "mode": "PRE"};
      debugPrint('DataProvider: exception, game set to: $game');
      notifyListeners();
    }
  }

  DateTime formatStringDate(String unformated_date) {
    try {
      debugPrint('Formatting date: "$unformated_date"');
      List<String> dateString = unformated_date.split(' ');
      
      // Check if we have enough parts
      if (dateString.length < 3) {
        debugPrint('Error: Date string has insufficient parts: ${dateString.length}');
        return DateTime.now();
      }
      
      monthStringToNumber(String month) {
        final monthsMap = {
          'january': 1,
          'february': 2,
          'march': 3,
          'april': 4,
          'may': 5,
          'june': 6,
          'july': 7,
          'august': 8,
          'september': 9,
          'october': 10,
          'november': 11,
          'december': 12,
        };
        return monthsMap[month.toLowerCase()];
      }

      String day = dateString[2]
          .replaceAll("TH", "")
          .replaceAll("th", "")
          .replaceAll("RD", "")
          .replaceAll("rd", "")
          .replaceAll("ND", "")
          .replaceAll("nd", "")
          .replaceAll("ST", "")
          .replaceAll("st", "")
          .replaceAll(",", "");
      String month = dateString[1].replaceAll(',', "");
      String formattedDay = int.parse(day).toString().padLeft(2, '0');
      String formattedMonth = int.parse(monthStringToNumber(month).toString())
          .toString()
          .padLeft(2, '0');
      String year = game?["year"] ?? "2025";
      DateTime date = DateTime.parse("${year}-${formattedMonth}-${formattedDay}");
      debugPrint('Successfully formatted date: $date');
      return date;
    } catch (e) {
      debugPrint('Error formatting date: $e');
      return DateTime.now();
    }
  }

  final box = GetStorage();
  // Obtain shared preferences.

  Future<dynamic> initPayment(
    context, {
    data,
  }) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    print("ooo");
    print("ooo");
    print("ooo");
    print(data);
    print(data);
    print(data);

    // {
    //   "week": "REG1",
    // "tiebreaker": "10",
    // 'date': FieldValue.serverTimestamp(),
    // 'picks': ["NEW", "ERE"],
    // 'uid': "10",
    // "displayName": "frank",
    // "photoURL": ""
    // }
// Obtain shared preferences.

    // var value =  FieldValue.serverTimestamp().toString();
    // await prefs.setString('date', value);
    await prefs.setString('week', data["week"]);
    await prefs.setString('uid', data["uid"]);
    await prefs.setString('displayName', data["displayName"]);
    await prefs.setString('photoURL', data["photoURL"]);
    await prefs.setString('tiebreaker', data["tiebreaker"]);
    await prefs.setStringList('picks', data["picks"]);

    // box.write("week", data["week"]);
    // box.write("tiebreaker", data["tiebreaker"]);
    // box.write("date", data["date"]);
    // box.write("picks", data["picks"]);
    // box.write("uid", data["uid"]);
    // box.write("displayName", data["displayName"]);
    // box.write("photoURL", data["photoURL"]);
  }
}
