import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class NFLScheduleFetcher {
  static const String _espnBaseUrl = 'https://site.api.espn.com/apis/site/v2/sports/football/nfl';
  static const String _espnScoreboardUrl = '$_espnBaseUrl/scoreboard';
  static const String _espnScheduleUrl = '$_espnBaseUrl/schedule';
  
  // Team abbreviation mapping
  static const Map<String, String> _teamMapping = {
    'ARI': 'ARI', 'ATL': 'ATL', 'BAL': 'BAL', 'BUF': 'BUF',
    'CAR': 'CAR', 'CHI': 'CHI', 'CIN': 'CIN', 'CLE': 'CLE',
    'DAL': 'DAL', 'DEN': 'DEN', 'DET': 'DET', 'GB': 'GB',
    'HOU': 'HOU', 'IND': 'IND', 'JAX': 'JAX', 'KC': 'KC',
    'LV': 'LV', 'LAC': 'LAC', 'LAR': 'LAR', 'MIA': 'MIA',
    'MIN': 'MIN', 'NE': 'NE', 'NO': 'NO', 'NYG': 'NYG',
    'NYJ': 'NYJ', 'PHI': 'PHI', 'PIT': 'PIT', 'SF': 'SF',
    'SEA': 'SEA', 'TB': 'TB', 'TEN': 'TEN', 'WAS': 'WAS'
  };

  static const Map<String, String> _headers = {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    'User-Agent': 'PoolQ-Schedule-Fetcher/1.0',
  };

  static String _getTeamAbbreviation(String espnAbbr) {
    switch (espnAbbr.toUpperCase()) {
      case 'WSH': return 'WAS';
      case 'JAC': return 'JAX';
      case 'GBP': return 'GB';
      case 'KCC': return 'KC';
      case 'SFO': return 'SF';
      case 'NEP': return 'NE';
      case 'NOS': return 'NO';
      case 'TBB': return 'TB';
      default: return _teamMapping[espnAbbr.toUpperCase()] ?? espnAbbr.toUpperCase();
    }
  }

  static String _formatGameDate(String isoDate) {
    try {
      if (isoDate.isEmpty) return '';
      
      DateTime dateTime = DateTime.parse(isoDate);
      final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      final months = ['January', 'February', 'March', 'April', 'May', 'June', 
                     'July', 'August', 'September', 'October', 'November', 'December'];
      
      String weekday = weekdays[dateTime.weekday - 1];
      String month = months[dateTime.month - 1];
      String day = '${dateTime.day}${_getOrdinalSuffix(dateTime.day).toUpperCase()}';
      String year = '${dateTime.year}';
      
      return '$weekday $month $day, $year';
    } catch (e) {
      print('Error formatting date $isoDate: $e');
      return '';
    }
  }

  static String _getOrdinalSuffix(int number) {
    if (number >= 11 && number <= 13) {
      return 'th';
    }
    switch (number % 10) {
      case 1: return 'st';
      case 2: return 'nd';
      case 3: return 'rd';
      default: return 'th';
    }
  }

  static String _formatTime(String isoDate) {
    try {
      if (isoDate.isEmpty) return '';
      
      DateTime dateTime = DateTime.parse(isoDate).toLocal();
      String period = dateTime.hour >= 12 ? 'PM' : 'AM';
      int hour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
      hour = hour == 0 ? 12 : hour;
      String minute = dateTime.minute.toString().padLeft(2, '0');
      
      return '$hour:$minute $period';
    } catch (e) {
      print('Error formatting time $isoDate: $e');
      return '';
    }
  }

  static List<Map<String, dynamic>> _parseESPNResponse(Map<String, dynamic> data) {
    List<Map<String, dynamic>> games = [];
    
    try {
      if (data['events'] != null) {
        for (var event in data['events']) {
          var competition = event['competitions']?[0];
          if (competition != null) {
            var competitors = competition['competitors'];
            if (competitors != null && competitors.length >= 2) {
              String originalDate = event['date'] ?? '';
              String formattedDate = _formatGameDate(originalDate);
              
              var homeTeam = competitors.firstWhere((c) => c['homeAway'] == 'home', orElse: () => competitors[0]);
              var awayTeam = competitors.firstWhere((c) => c['homeAway'] == 'away', orElse: () => competitors[1]);
              
              var odds = competition['odds']?[0];
              String favorite = '';
              double spread = 0.0;
              
              if (odds != null) {
                favorite = odds['favorite'] ?? '';
                spread = double.tryParse(odds['spread']?.toString() ?? '0') ?? 0.0;
              }
              
              games.add({
                'date': formattedDate,
                'fullname': homeTeam['team']['displayName'] ?? 'TBD',
                'fullname2': awayTeam['team']['displayName'] ?? 'TBD',
                'abbreviation': _getTeamAbbreviation(homeTeam['team']['abbreviation'] ?? ''),
                'abbreviation2': _getTeamAbbreviation(awayTeam['team']['abbreviation'] ?? ''),
                'picture': homeTeam['team']['logo'] ?? '',
                'picture2': awayTeam['team']['logo'] ?? '',
                'score': homeTeam['score']?.toString() ?? '0',
                'score2': awayTeam['score']?.toString() ?? '0',
                'status': competition['status']['type']['name'] ?? 'scheduled',
                'time': _formatTime(originalDate),
                'venue': competition['venue']?['fullName'] ?? '',
                'broadcast': competition['broadcasts']?[0]?['names']?.join(', ') ?? '',
                'favorite': favorite,
                'spread': spread,
              });
            }
          }
        }
      }
      
      return games;
    } catch (e) {
      print('Error parsing ESPN response: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> _fetchWeekSchedule(int week, int season, int seasonType) async {
    try {
      print('Fetching week $week, season $season, type $seasonType...');
      
      // Try scoreboard endpoint first
      final response = await http.get(
        Uri.parse('$_espnScoreboardUrl?dates=$season&seasontype=$seasonType&week=$week'),
        headers: _headers,
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final games = _parseESPNResponse(data);
        
        if (games.isNotEmpty) {
          print('Successfully fetched ${games.length} games for week $week');
          return games;
        }
      }

      // Try schedule endpoint as fallback
      final scheduleResponse = await http.get(
        Uri.parse('$_espnScheduleUrl?dates=$season&seasontype=$seasonType&week=$week'),
        headers: _headers,
      ).timeout(const Duration(seconds: 15));

      if (scheduleResponse.statusCode == 200) {
        final data = json.decode(scheduleResponse.body);
        final games = _parseESPNResponse(data);
        
        if (games.isNotEmpty) {
          print('Successfully fetched ${games.length} games for week $week (schedule endpoint)');
          return games;
        }
      }

      print('No games found for week $week');
      return [];
    } catch (e) {
      print('Error fetching week $week: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> fetchFullSeasonSchedule(int year) async {
    print('Fetching full NFL schedule for $year...');
    
    Map<String, dynamic> fullSchedule = {
      'year': year,
      'fetchedAt': DateTime.now().toIso8601String(),
      'preseason': {},
      'regular': {},
      'postseason': {},
    };

    // Fetch Preseason (3 weeks)
    print('\n=== FETCHING PRESEASON ===');
    for (int week = 1; week <= 3; week++) {
      final games = await _fetchWeekSchedule(week, year, 1); // 1 = preseason
      if (games.isNotEmpty) {
        fullSchedule['preseason']['PRE$week'] = games;
      }
      await Future.delayed(Duration(milliseconds: 500)); // Rate limiting
    }

    // Fetch Regular Season (18 weeks)
    print('\n=== FETCHING REGULAR SEASON ===');
    for (int week = 1; week <= 18; week++) {
      final games = await _fetchWeekSchedule(week, year, 2); // 2 = regular season
      if (games.isNotEmpty) {
        fullSchedule['regular']['REG$week'] = games;
      }
      await Future.delayed(Duration(milliseconds: 500)); // Rate limiting
    }

    // Fetch Postseason (4 weeks)
    print('\n=== FETCHING POSTSEASON ===');
    for (int week = 1; week <= 4; week++) {
      final games = await _fetchWeekSchedule(week, year, 3); // 3 = postseason
      if (games.isNotEmpty) {
        fullSchedule['postseason']['POST$week'] = games;
      }
      await Future.delayed(Duration(milliseconds: 500)); // Rate limiting
    }

    return fullSchedule;
  }

  static Future<void> saveScheduleToFile(Map<String, dynamic> schedule, String filename) async {
    try {
      final file = File(filename);
      final jsonString = JsonEncoder.withIndent('  ').convert(schedule);
      await file.writeAsString(jsonString);
      print('\nSchedule saved to: $filename');
    } catch (e) {
      print('Error saving schedule to file: $e');
    }
  }

  static Future<Map<String, dynamic>?> loadScheduleFromFile(String filename) async {
    try {
      final file = File(filename);
      if (await file.exists()) {
        final jsonString = await file.readAsString();
        return json.decode(jsonString);
      }
      return null;
    } catch (e) {
      print('Error loading schedule from file: $e');
      return null;
    }
  }
}

void main() async {
  final currentYear = DateTime.now().year;
  final filename = 'assets/data/nfl_schedule_$currentYear.json';
  
  print('NFL Schedule Fetcher');
  print('===================');
  print('Current year: $currentYear');
  print('Output file: $filename');
  
  // Create assets/data directory if it doesn't exist
  final directory = Directory('assets/data');
  if (!await directory.exists()) {
    await directory.create(recursive: true);
    print('Created directory: assets/data');
  }
  
  // Check if we already have a recent schedule file
  final existingSchedule = await NFLScheduleFetcher.loadScheduleFromFile(filename);
  if (existingSchedule != null) {
    final fetchedAt = DateTime.parse(existingSchedule['fetchedAt']);
    final daysSinceFetch = DateTime.now().difference(fetchedAt).inDays;
    
    print('\nFound existing schedule file:');
    print('- Fetched: ${fetchedAt.toString()}');
    print('- Days since fetch: $daysSinceFetch');
    
    if (daysSinceFetch < 7) {
      print('\nSchedule is recent (less than 7 days old).');
      print('To force refresh, delete the file and run again.');
      return;
    } else {
      print('\nSchedule is outdated. Fetching new data...');
    }
  }
  
  // Fetch the full schedule
  final schedule = await NFLScheduleFetcher.fetchFullSeasonSchedule(currentYear);
  
  // Save to file
  await NFLScheduleFetcher.saveScheduleToFile(schedule, filename);
  
  // Print summary
  print('\n=== SCHEDULE SUMMARY ===');
  print('Preseason weeks: ${schedule['preseason'].length}');
  print('Regular season weeks: ${schedule['regular'].length}');
  print('Postseason weeks: ${schedule['postseason'].length}');
  
  int totalGames = 0;
  schedule['preseason'].forEach((week, games) => totalGames += (games as List).length);
  schedule['regular'].forEach((week, games) => totalGames += (games as List).length);
  schedule['postseason'].forEach((week, games) => totalGames += (games as List).length);
  
  print('Total games: $totalGames');
  print('\nSchedule fetch completed successfully!');
} 