import 'package:flutter/foundation.dart';

class NFLGameService {
  static final NFLGameService _instance = NFLGameService._internal();
  
  factory NFLGameService() {
    return _instance;
  }
  
  NFLGameService._internal();
  
  // Returns mock NFL game data for the 2025 season
  List<Map<String, dynamic>> getMockGamesForWeek(String weekName) {
    // Standardize week format
    weekName = weekName.toUpperCase();
    
    // Define team data
    final Map<String, Map<String, String>> teams = {
      "ARI": {"fullname": "Arizona Cardinals", "picture": "https://static.www.nfl.com/image/private/f_auto/league/u9fltoslqdsyao8cpm0k"},
      "ATL": {"fullname": "Atlanta Falcons", "picture": "https://static.www.nfl.com/image/private/f_auto/league/d8m7hzpsbrl6pnqht8op"},
      "BAL": {"fullname": "Baltimore Ravens", "picture": "https://static.www.nfl.com/image/private/f_auto/league/ucsdijmddsqcj1i9tddd"},
      "BUF": {"fullname": "Buffalo Bills", "picture": "https://static.www.nfl.com/image/private/f_auto/league/giphcy6ie9mxbnldntsf"},
      "CAR": {"fullname": "Carolina Panthers", "picture": "https://static.www.nfl.com/image/private/f_auto/league/oklgslmdpfeflwppfmpt"},
      "CHI": {"fullname": "Chicago Bears", "picture": "https://static.www.nfl.com/image/private/f_auto/league/ijrplti0kmzsyoaikhv3"},
      "CIN": {"fullname": "Cincinnati Bengals", "picture": "https://static.www.nfl.com/image/private/f_auto/league/uqzgq0qoxvlocdl7bsj0"},
      "CLE": {"fullname": "Cleveland Browns", "picture": "https://static.www.nfl.com/image/private/f_auto/league/grxgjbmmeofkwjl5o3bc"},
      "DAL": {"fullname": "Dallas Cowboys", "picture": "https://static.www.nfl.com/image/private/f_auto/league/ieid8hoygzdlmzo0tnf6"},
      "DEN": {"fullname": "Denver Broncos", "picture": "https://static.www.nfl.com/image/private/f_auto/league/t0p7m5cjdjy18rnzzqbx"},
      "DET": {"fullname": "Detroit Lions", "picture": "https://static.www.nfl.com/image/private/f_auto/league/ocvxwnapdvwevupe4tpr"},
      "GB": {"fullname": "Green Bay Packers", "picture": "https://static.www.nfl.com/image/private/f_auto/league/q4ehayuhlyy57cv2epdm"},
      "HOU": {"fullname": "Houston Texans", "picture": "https://static.www.nfl.com/image/private/f_auto/league/bpx88i8nw4nnabuq0oob"},
      "IND": {"fullname": "Indianapolis Colts", "picture": "https://static.www.nfl.com/image/private/f_auto/league/ketwqeuschqzjsllbid5"},
      "JAX": {"fullname": "Jacksonville Jaguars", "picture": "https://static.www.nfl.com/image/private/f_auto/league/qycbib6ivrm9dqaexryk"},
      "KC": {"fullname": "Kansas City Chiefs", "picture": "https://static.www.nfl.com/image/private/f_auto/league/ujshjqvmnxce8m4obmvs"},
      "LV": {"fullname": "Las Vegas Raiders", "picture": "https://static.www.nfl.com/image/private/f_auto/league/gzcojbzcyjgubsozg2li"},
      "LAC": {"fullname": "Los Angeles Chargers", "picture": "https://static.www.nfl.com/image/private/f_auto/league/dhfidtn8jrumakbogeu4"},
      "LAR": {"fullname": "Los Angeles Rams", "picture": "https://static.www.nfl.com/image/private/f_auto/league/ayvwcmluj2ohkdlbiegi"},
      "MIA": {"fullname": "Miami Dolphins", "picture": "https://static.www.nfl.com/image/private/f_auto/league/lits6p8ycthy9to70bnt"},
      "MIN": {"fullname": "Minnesota Vikings", "picture": "https://static.www.nfl.com/image/private/f_auto/league/teguylrnqqmfcwxvcmmz"},
      "NE": {"fullname": "New England Patriots", "picture": "https://static.www.nfl.com/image/private/f_auto/league/moyfxx3dq5pio4aiftnc"},
      "NO": {"fullname": "New Orleans Saints", "picture": "https://static.www.nfl.com/image/private/f_auto/league/grhjkahghjkl47ov5kqv"},
      "NYG": {"fullname": "New York Giants", "picture": "https://static.www.nfl.com/image/private/f_auto/league/t6mhdmgizi6qhndh8b9p"},
      "NYJ": {"fullname": "New York Jets", "picture": "https://static.www.nfl.com/image/private/f_auto/league/cehudzixdmiegfqvi9cn"},
      "PHI": {"fullname": "Philadelphia Eagles", "picture": "https://static.www.nfl.com/image/private/f_auto/league/puhrqgj71gobgmwb5h3o"},
      "PIT": {"fullname": "Pittsburgh Steelers", "picture": "https://static.www.nfl.com/image/private/f_auto/league/xujik9kbydtri0nwzfle"},
      "SF": {"fullname": "San Francisco 49ers", "picture": "https://static.www.nfl.com/image/private/f_auto/league/dxibuyxbk0b9ua5ih9hn"},
      "SEA": {"fullname": "Seattle Seahawks", "picture": "https://static.www.nfl.com/image/private/f_auto/league/gcytzwpjdzbpwnwxincg"},
      "TB": {"fullname": "Tampa Bay Buccaneers", "picture": "https://static.www.nfl.com/image/private/f_auto/league/v8uqiualryypwqgvwcih"},
      "TEN": {"fullname": "Tennessee Titans", "picture": "https://static.www.nfl.com/image/private/f_auto/league/pln44vuzugjgipyidsre"},
      "WAS": {"fullname": "Washington Commanders", "picture": "https://static.www.nfl.com/image/private/f_auto/league/xymxwrxtyj9fhaemhdyd"},
    };
    
    // Generate games based on week
    List<Map<String, dynamic>> games = [];
    
    switch(weekName) {
      case "REG1":
        games = [
          _createGame("Thursday September 4TH, 2025", "KC", "BAL", "0", "0"),
          _createGame("Sunday September 7TH, 2025", "BUF", "NYJ", "0", "0"),
          _createGame("Sunday September 7TH, 2025", "MIA", "NE", "0", "0"),
          _createGame("Sunday September 7TH, 2025", "ATL", "CAR", "0", "0"),
          _createGame("Sunday September 7TH, 2025", "PHI", "NYG", "0", "0"),
          _createGame("Sunday September 7TH, 2025", "PIT", "CIN", "0", "0"),
          _createGame("Sunday September 7TH, 2025", "DET", "GB", "0", "0"),
          _createGame("Sunday September 7TH, 2025", "NO", "TB", "0", "0"),
          _createGame("Sunday September 7TH, 2025", "HOU", "IND", "0", "0"),
          _createGame("Sunday September 7TH, 2025", "JAX", "TEN", "0", "0"),
          _createGame("Sunday September 7TH, 2025", "CHI", "MIN", "0", "0"),
          _createGame("Sunday September 7TH, 2025", "LV", "LAC", "0", "0"),
          _createGame("Sunday September 7TH, 2025", "SEA", "DEN", "0", "0"),
          _createGame("Sunday September 7TH, 2025", "LAR", "ARI", "0", "0"),
          _createGame("Sunday September 7TH, 2025", "SF", "DAL", "0", "0"),
          _createGame("Monday September 8TH, 2025", "CLE", "WAS", "0", "0"),
        ];
        break;
      case "REG2":
        games = [
          _createGame("Thursday September 11TH, 2025", "BUF", "MIA", "0", "0"),
          _createGame("Sunday September 14TH, 2025", "BAL", "PIT", "0", "0"),
          _createGame("Sunday September 14TH, 2025", "NYJ", "NE", "0", "0"),
          _createGame("Sunday September 14TH, 2025", "CAR", "NO", "0", "0"),
          _createGame("Sunday September 14TH, 2025", "NYG", "WAS", "0", "0"),
          _createGame("Sunday September 14TH, 2025", "CIN", "CLE", "0", "0"),
          _createGame("Sunday September 14TH, 2025", "GB", "CHI", "0", "0"),
          _createGame("Sunday September 14TH, 2025", "TB", "ATL", "0", "0"),
          _createGame("Sunday September 14TH, 2025", "IND", "JAX", "0", "0"),
          _createGame("Sunday September 14TH, 2025", "TEN", "HOU", "0", "0"),
          _createGame("Sunday September 14TH, 2025", "MIN", "DET", "0", "0"),
          _createGame("Sunday September 14TH, 2025", "LAC", "KC", "0", "0"),
          _createGame("Sunday September 14TH, 2025", "DEN", "LV", "0", "0"),
          _createGame("Sunday September 14TH, 2025", "ARI", "SF", "0", "0"),
          _createGame("Sunday September 14TH, 2025", "DAL", "LAR", "0", "0"),
          _createGame("Monday September 15TH, 2025", "PHI", "SEA", "0", "0"),
        ];
        break;
      case "REG3":
        games = [
          _createGame("Thursday September 18TH, 2025", "KC", "DEN", "0", "0"),
          _createGame("Sunday September 21TH, 2025", "BAL", "CLE", "0", "0"),
          _createGame("Sunday September 21TH, 2025", "BUF", "NE", "0", "0"),
          _createGame("Sunday September 21TH, 2025", "MIA", "NYJ", "0", "0"),
          _createGame("Sunday September 21TH, 2025", "CAR", "TB", "0", "0"),
          _createGame("Sunday September 21TH, 2025", "WAS", "NYG", "0", "0"),
          _createGame("Sunday September 21TH, 2025", "PIT", "CIN", "0", "0"),
          _createGame("Sunday September 21TH, 2025", "CHI", "DET", "0", "0"),
          _createGame("Sunday September 21TH, 2025", "ATL", "NO", "0", "0"),
          _createGame("Sunday September 21TH, 2025", "HOU", "JAX", "0", "0"),
          _createGame("Sunday September 21TH, 2025", "IND", "TEN", "0", "0"),
          _createGame("Sunday September 21TH, 2025", "GB", "MIN", "0", "0"),
          _createGame("Sunday September 21TH, 2025", "LV", "LAC", "0", "0"),
          _createGame("Sunday September 21TH, 2025", "SF", "SEA", "0", "0"),
          _createGame("Sunday September 21TH, 2025", "ARI", "DAL", "0", "0"),
          _createGame("Monday September 22TH, 2025", "LAR", "PHI", "0", "0"),
        ];
        break;
      case "REG4":
        games = [
          _createGame("Thursday September 25TH, 2025", "CIN", "BAL", "0", "0"),
          _createGame("Sunday September 28TH, 2025", "NE", "MIA", "0", "0"),
          _createGame("Sunday September 28TH, 2025", "NYJ", "BUF", "0", "0"),
          _createGame("Sunday September 28TH, 2025", "TB", "CAR", "0", "0"),
          _createGame("Sunday September 28TH, 2025", "NYG", "PHI", "0", "0"),
          _createGame("Sunday September 28TH, 2025", "CLE", "PIT", "0", "0"),
          _createGame("Sunday September 28TH, 2025", "DET", "CHI", "0", "0"),
          _createGame("Sunday September 28TH, 2025", "NO", "ATL", "0", "0"),
          _createGame("Sunday September 28TH, 2025", "JAX", "HOU", "0", "0"),
          _createGame("Sunday September 28TH, 2025", "TEN", "IND", "0", "0"),
          _createGame("Sunday September 28TH, 2025", "MIN", "GB", "0", "0"),
          _createGame("Sunday September 28TH, 2025", "KC", "LV", "0", "0"),
          _createGame("Sunday September 28TH, 2025", "SEA", "ARI", "0", "0"),
          _createGame("Sunday September 28TH, 2025", "DAL", "WAS", "0", "0"),
          _createGame("Sunday September 28TH, 2025", "DEN", "LAC", "0", "0"),
          _createGame("Monday September 29TH, 2025", "SF", "LAR", "0", "0"),
        ];
        break;
      // Add cases for REG5 through REG18...
      default:
        // Default game set for any other week
        games = [
          _createGame("Sunday", "KC", "SF", "0", "0"),
          _createGame("Sunday", "BUF", "MIA", "0", "0"),
          _createGame("Sunday", "BAL", "CIN", "0", "0"),
          _createGame("Sunday", "DET", "GB", "0", "0"),
          _createGame("Sunday", "DAL", "PHI", "0", "0"),
          _createGame("Sunday", "LAR", "SEA", "0", "0"),
          _createGame("Sunday", "NO", "TB", "0", "0"),
          _createGame("Monday", "NYJ", "NE", "0", "0"),
        ];
        break;
    }
    
    // Fill in team data from our teams map
    for (var game in games) {
      String abbreviation = game["abbreviation"];
      String abbreviation2 = game["abbreviation2"];
      
      if (teams.containsKey(abbreviation)) {
        game["fullname"] = teams[abbreviation]!["fullname"];
        game["picture"] = teams[abbreviation]!["picture"];
      }
      
      if (teams.containsKey(abbreviation2)) {
        game["fullname2"] = teams[abbreviation2]!["fullname"];
        game["picture2"] = teams[abbreviation2]!["picture"];
      }
    }
    
    return games;
  }
  
  // Helper method to create a game entry
  Map<String, dynamic> _createGame(
      String date, 
      String team1, 
      String team2, 
      String score1, 
      String score2) {
    return {
      "_id": "${team1}_${team2}_2025",
      "date": date,
      "year": "2025",
      "week": "REG1",
      "abbreviation": team1,
      "abbreviation2": team2,
      "score": score1,
      "score2": score2,
      "fullname": "",  // Will be filled from teams map
      "fullname2": "", // Will be filled from teams map
      "picture": "",   // Will be filled from teams map
      "picture2": "",  // Will be filled from teams map
    };
  }
  
  // Returns winners for a specific week (mock data)
  List<String> getWinnersForWeek(String weekName) {
    // For testing, we'll just return some fixed winners
    switch(weekName) {
      case "REG1":
        return ["KC", "BUF", "MIA", "ATL", "PHI", "PIT", "DET", "TB", "HOU", "JAX", "MIN", "LAC", "SEA", "LAR", "SF", "CLE"];
      default:
        return [];
    }
  }
} 