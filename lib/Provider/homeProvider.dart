import 'dart:async';
import 'dart:convert';
import '../Model/games.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';
import 'package:poolqapp/Provider/AuthProviders.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Import Platform class
import 'platform_stub.dart' if (dart.library.io) 'dart:io' as platform;

// //import 'package:admob_flutter/admob_flutter.dart';

class DataProvider with ChangeNotifier {
  List<String>? playerPicks = [];
  bool picked = false;
  int pageIndex = 0;

  setPlayerPicks(List<String> value) {
    playerPicks = value;
    notifyListeners();
  }

  int? tiebreaker;

  setTieBreaker(value) {
    tiebreaker = value;
    notifyListeners();
  }

  int? amount;

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
    playerPicks!.remove(value);
    notifyListeners();
  }

  addToPlayerPicks(value) {
    playerPicks!.add(value);
    playerPicks = playerPicks;
    notifyListeners();
  }

  Map? game;
  Future getWeek() async {
    try {
      var response = await http.get(Uri.parse('${mainUrl}/get_week'), headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Access-Control-Allow-Origin': '*',
      }).timeout(Duration(seconds: 20));
      
      print("game");
      print(response.body);
      
      var body = json.decode(response.body);
      game = body;
      notifyListeners();
      getGame();
      return body;
    } catch (e) {
      debugPrint('Error fetching week data: $e');
      // Use mock data for testing when API is not available
      // Updated to 2025 season
      game = {"name": "REG1", "year": "2025", "mode": "REG"};
      notifyListeners();
      getGame();
      return game;
    }
  }

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
      if (game == null) {
        game = {"name": "REG1", "year": "2025", "mode": "REG"};
      }
      
      print('${mainUrl}/nfl_dates/${checkWeek(game!["name"])}');
      
      var response = await http.get(
          Uri.parse('${mainUrl}/nfl_dates/${checkWeek(game!["name"])}'),
          headers: {
            'Content-Type': 'application/json; charset=UTF-8',
            'Access-Control-Allow-Origin': '*',
          }).timeout(Duration(seconds: 20));
      
      print("dataaaaa");
      print(response.body);
      
      var body = json.decode(response.body);
      List body1 = body["dates"];
      body1.sort((a, b) => formatStringDate(a.toString())
          .compareTo(formatStringDate(b.toString())));
      data = body1;
      notifyListeners();
      return data;
    } catch (e) {
      debugPrint('Error fetching game data: $e');
      // Mock data for the 2025 NFL season
      if (game!["name"] == "REG1") {
        data = [
          "Thursday September 4TH, 2025",
          "Sunday September 7TH, 2025",
          "Monday September 8TH, 2025"
        ];
      } else if (game!["name"] == "REG2") {
        data = [
          "Thursday September 11TH, 2025",
          "Sunday September 14TH, 2025",
          "Monday September 15TH, 2025"
        ];
      } else if (game!["name"] == "REG3") {
        data = [
          "Thursday September 18TH, 2025",
          "Sunday September 21TH, 2025",
          "Monday September 22TH, 2025"
        ];
      } else if (game!["name"] == "REG4") {
        data = [
          "Thursday September 25TH, 2025",
          "Sunday September 28TH, 2025",
          "Monday September 29TH, 2025"
        ];
      } else if (game!["name"] == "REG5") {
        data = [
          "Thursday October 2ND, 2025",
          "Sunday October 5TH, 2025",
          "Monday October 6TH, 2025"
        ];
      } else if (game!["name"] == "REG6") {
        data = [
          "Thursday October 9TH, 2025",
          "Sunday October 12TH, 2025",
          "Monday October 13TH, 2025"
        ];
      } else if (game!["name"] == "REG7") {
        data = [
          "Thursday October 16TH, 2025",
          "Sunday October 19TH, 2025",
          "Monday October 20TH, 2025"
        ];
      } else if (game!["name"] == "REG8") {
        data = [
          "Thursday October 23RD, 2025",
          "Sunday October 26TH, 2025",
          "Monday October 27TH, 2025"
        ];
      } else if (game!["name"] == "REG9") {
        data = [
          "Thursday October 30TH, 2025",
          "Sunday November 2ND, 2025",
          "Monday November 3RD, 2025"
        ];
      } else if (game!["name"] == "REG10") {
        data = [
          "Thursday November 6TH, 2025",
          "Sunday November 9TH, 2025",
          "Monday November 10TH, 2025"
        ];
      } else if (game!["name"] == "REG11") {
        data = [
          "Thursday November 13TH, 2025",
          "Sunday November 16TH, 2025",
          "Monday November 17TH, 2025"
        ];
      } else if (game!["name"] == "REG12") {
        data = [
          "Thursday November 20TH, 2025",
          "Sunday November 23RD, 2025",
          "Monday November 24TH, 2025"
        ];
      } else if (game!["name"] == "REG13") {
        data = [
          "Thursday November 27TH, 2025", // Thanksgiving
          "Sunday November 30TH, 2025",
          "Monday December 1ST, 2025"
        ];
      } else if (game!["name"] == "REG14") {
        data = [
          "Thursday December 4TH, 2025",
          "Sunday December 7TH, 2025",
          "Monday December 8TH, 2025"
        ];
      } else if (game!["name"] == "REG15") {
        data = [
          "Thursday December 11TH, 2025",
          "Sunday December 14TH, 2025",
          "Monday December 15TH, 2025"
        ];
      } else if (game!["name"] == "REG16") {
        data = [
          "Thursday December 18TH, 2025",
          "Sunday December 21ST, 2025",
          "Monday December 22ND, 2025"
        ];
      } else if (game!["name"] == "REG17") {
        data = [
          "Thursday December 25TH, 2025", // Christmas
          "Sunday December 28TH, 2025",
          "Monday December 29TH, 2025"
        ];
      } else if (game!["name"] == "REG18") {
        data = [
          "Sunday January 4TH, 2026"
        ];
      } else {
        // Default fallback
        data = [
          "Sunday September 7TH, 2025",
          "Monday September 8TH, 2025"
        ];
      }
      
      notifyListeners();
      return data;
    }
  }

  DateTime formatStringDate(String unformated_date) {
    try {
      List<String> dateString = unformated_date.split(' ');
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
