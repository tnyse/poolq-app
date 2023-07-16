import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../Model/games.dart';


class DataProvider with ChangeNotifier {
    List<String> ?playerPicks= [];
   bool  picked= false;
    int pageIndex = 0;



    setPlayerPicks(List<String> value){
       playerPicks = value;
      notifyListeners();
    }

   int ?tiebreaker;


    setTieBreaker(value){
      tiebreaker = value;
      notifyListeners();
    }

   int ?amount;

   setValue(value){
     pageIndex = value;
     notifyListeners();
   }


    int countGames(List<String>? playerPicks) {
      // return the number of items in a list of playerPicks
      int _c = playerPicks?.length ?? 0;
      return _c;
    }


    removeFromPlayerPicks(value){
      playerPicks!.remove(value);
      notifyListeners();
    }


    addToPlayerPicks(value){
      playerPicks!.add(value);
      playerPicks = playerPicks;
      notifyListeners();
    }



Map ?game;
    Future getWeek() async {
      var response =
      await http.get(Uri.parse('https://poolq.app/get_week'), headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      }).timeout(Duration(seconds: 20));
      var body = json.decode(response.body);
      game = body;
      notifyListeners();
      getGame();
      return body;
    }



    checkWeek(week){
      if(week == "REG1"){
        return "REG1";
      }
     else if(week == "REG2"){
        return "REG2";
      }
      else if(week == "REG3"){
        return "REG3";
      }
      else if(week == "REG4"){
        return "REG4";
      }
      else if(week == "REG5"){
        return "REG5";
      }
      else  if(week == "REG6"){
        return "REG6";
      }
      else if(week == "REG7"){
        return "REG7";
      }
      else  if(week == "REG8"){
        return "REG8";
      }
      else if(week == "REG9"){
        return "REG9";
      }
      else  if(week == "REG10"){
        return "REG10";
      }
      else  if(week == "REG11"){
        return "REG11";
      }
      else  if(week == "REG12"){
        return "REG12";
      }
      else  if(week == "REG13"){
        return "REG13";
      }
      else  if(week == "REG14"){
        return "REG14";
      }
      else  if(week == "REG15"){
        return "REG15";
      }
      else  if(week == "REG16"){
        return "REG16";
      }
      else  if(week == "REG17"){
        return "REG17";
      }
      else  if(week == "REG18"){
        return "REG18";
      }

    }


   List ?data;
    Future getGame() async {
      print('https://poolq.app/nfl_dates/${checkWeek(game!["name"])}');
      var response =
      await http.get(Uri.parse('https://poolq.app/nfl_dates/${checkWeek(game!["name"])}'), headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      }).timeout(Duration(seconds: 20));
      var body = json.decode(response.body);
      List body1 = body["dates"];
      body1.sort((a, b) => formatStringDate(a.toString()).compareTo(formatStringDate(b.toString())));
      data = body1;
      notifyListeners();
    }



    DateTime formatStringDate(String unformated_date){
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

      String day = dateString[2].replaceAll("TH", "").replaceAll("RD", "").replaceAll("ND","").replaceAll("ST", "");
      String month = dateString[1].replaceAll(',', "");
      String formattedDay = int.parse(day).toString().padLeft(2, '0');
      String formattedMonth = int.parse(monthStringToNumber(month).toString()).toString().padLeft(2, '0');
      String year = game!["year"];
      DateTime date = DateTime.parse("${year}-${formattedMonth}-${formattedDay}");
      return date;
    }
}