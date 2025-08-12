import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'nfl_game_service.dart';
import 'schedule_cache_service.dart';
import 'local_schedule_service.dart';

class NFLScheduleService {
  static final NFLScheduleService _instance = NFLScheduleService._internal();
  
  factory NFLScheduleService() {
    return _instance;
  }
  
  NFLScheduleService._internal();

  // ESPN API endpoints
  static const String _espnBaseUrl = 'https://site.api.espn.com/apis/site/v2/sports/football/nfl';
  static const String _espnScoreboardUrl = '$_espnBaseUrl/scoreboard';
  static const String _espnTeamsUrl = '$_espnBaseUrl/teams';
  static const String _espnScheduleUrl = '$_espnBaseUrl/schedule';
  
  // Team abbreviation mapping to match your app's format
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

  // Get platform-appropriate headers and URL
  Map<String, String> _getHeaders() {
    if (kIsWeb) {
      return {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Origin': 'https://poolq.app',
      };
    }
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'User-Agent': 'PoolQ-App/1.0',
    };
  }

  // Helper method to get appropriate URL based on platform
  String _getApiUrl(String originalUrl) {
    if (kIsWeb) {
      // Use a CORS proxy for web platform
      const corsProxy = 'https://cors-anywhere.herokuapp.com/';
      return '$corsProxy$originalUrl';
    }
    return originalUrl;
  }

  /// Loads the full season schedule from a local asset file
  Future<Map<String, dynamic>?> loadLocalSchedule(int year) async {
    try {
      final jsonString = await rootBundle.loadString('assets/data/nfl_schedule_$year.json');
      return json.decode(jsonString);
    } catch (e) {
      debugPrint('Error loading local schedule: $e');
      return null;
    }
  }

  /// Load schedule data from local file for a specific week
  Future<List<dynamic>> _loadScheduleFromLocalFile(String weekName) async {
    try {
      final currentYear = DateTime.now().year;
      final localSchedule = await loadLocalSchedule(currentYear);
      if (localSchedule != null) {
        String weekType = '';
        if (weekName.startsWith('PRE')) weekType = 'preseason';
        else if (weekName.startsWith('REG')) weekType = 'regular';
        else if (weekName.startsWith('POST')) weekType = 'postseason';
        final weekGames = localSchedule[weekType]?[weekName];
        if (weekGames != null && weekGames is List && weekGames.isNotEmpty) {
          return weekGames;
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error loading local schedule file: $e');
      return [];
    }
  }

  /// Gets the schedule for a specific week, using cached data with periodic updates
  Future<List<Map<String, dynamic>>> getScheduleForWeekWithLocalFallback(String weekName, {int? year}) async {
    try {
      debugPrint('getScheduleForWeekWithLocalFallback called for $weekName');
      
      // Always use local schedule service for consistent data
      debugPrint('Loading schedule from local JSON file');
      
      // Use local schedule service to load from JSON file
      final localService = LocalScheduleService();
      final games = await localService.getScheduleForWeek(weekName);
      
      if (games.isNotEmpty) {
        debugPrint('Successfully loaded ${games.length} games from local JSON for $weekName');
        return games;
      } else {
        debugPrint('No games found in local JSON for $weekName, falling back to cache service');
      }
      
      // Use cache service for all schedule requests as fallback
      final cacheService = ScheduleCacheService();
      return await cacheService.getScheduleForWeek(weekName, year: year);
    } catch (e) {
      debugPrint('Error in getScheduleForWeekWithLocalFallback: $e');
      return [];
    }
  }

  /// Helper to combine date and time strings into ISO8601 for DateTime.parse
  String _combineDateTime(String dateStr, String timeStr) {
    // Example: "Friday September 5TH, 2025" and "6:20 PM" -> "2025-09-05T18:20:00"
    try {
      final dateParts = dateStr.split(' ');
      final month = dateParts[1];
      final day = dateParts[2].replaceAll(RegExp(r'\D'), ''); // Remove "TH", "ST", etc.
      final year = dateParts[3].replaceAll(',', '');
      final timeParts = timeStr.split(' ');
      var hour = int.parse(timeParts[0].split(':')[0]);
      final minute = int.parse(timeParts[0].split(':')[1]);
      final isPM = timeParts[1].toUpperCase() == 'PM';
      if (isPM && hour != 12) hour += 12;
      if (!isPM && hour == 12) hour = 0;
      final monthNum = {
        'January': '01', 'February': '02', 'March': '03', 'April': '04',
        'May': '05', 'June': '06', 'July': '07', 'August': '08',
        'September': '09', 'October': '10', 'November': '11', 'December': '12',
      }[month] ?? '01';
      return '$year-$monthNum-${day.padLeft(2, '0')}T${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}:00';
    } catch (e) {
      debugPrint('Error parsing date/time: $dateStr $timeStr - $e');
      return DateTime.now().toIso8601String();
    }
  }

  /// API fallback for updated results (enable only if needed)
  Future<List<Map<String, dynamic>>> getScheduleForWeekApiFallback(String weekName, {int? year}) async {
    debugPrint('API fallback called for $weekName');
    // You can re-enable your API logic here if needed, or leave as [] for now
    return [];
  }

  // Enable API methods for testing preseason availability
  Future<Map<String, dynamic>?> getCurrentWeek() async {
    debugPrint('Testing API: getCurrentWeek');
    try {
      final response = await http.get(
        Uri.parse(_getApiUrl('$_espnScheduleUrl?year=2025&seasontype=1')),
        headers: _getHeaders(),
      ).timeout(Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('API response received for current week');
        return {
          'week': 1,
          'season_type': 1, // preseason
          'season': 2025,
          'seasonName': 'PRE'
        };
      } else {
        debugPrint('API error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('API error in getCurrentWeek: $e');
      return null;
    }
  }
  
  Future<List<Map<String, dynamic>>> getScheduleWithFallback(String weekName) async {
    debugPrint('Testing API: getScheduleWithFallback for $weekName');
    try {
      // Extract week number from weekName (e.g., "PRE1" -> 1)
      final weekMatch = RegExp(r'(\d+)').firstMatch(weekName);
      final week = weekMatch != null ? int.parse(weekMatch.group(1)!) : 1;
      
      final response = await http.get(
        Uri.parse(_getApiUrl('$_espnScheduleUrl?year=2025&seasontype=1&week=$week')),
        headers: _getHeaders(),
      ).timeout(Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('API response received for schedule');
        return _parseESPNScheduleResponse(data);
      } else {
        debugPrint('API error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('API error in getScheduleWithFallback: $e');
      return [];
    }
  }
  
  Future<List<Map<String, dynamic>>> getScheduleForWeek(int week, {int season = 2025, int seasonType = 1}) async {
    debugPrint('Testing API: getScheduleForWeek week=$week, seasonType=$seasonType');
    try {
      final response = await http.get(
        Uri.parse(_getApiUrl('$_espnScheduleUrl?year=$season&seasontype=$seasonType&week=$week')),
        headers: _getHeaders(),
      ).timeout(Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('API response received for specific week');
        return _parseESPNScheduleResponse(data);
      } else {
        debugPrint('API error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('API error in getScheduleForWeek: $e');
      return [];
    }
  }
  
  Future<List<Map<String, dynamic>>> getScheduleFromNFL(String weekName) async {
    debugPrint('Testing API: getScheduleFromNFL for $weekName');
    return await getScheduleWithFallback(weekName);
  }

  /// Get season type name
  String _getSeasonTypeName(int type) {
    switch (type) {
      case 1: return 'PRE';
      case 2: return 'REG';
      case 3: return 'POST';
      default: return 'REG';
    }
  }

  /// Parse schedule-specific ESPN response
  List<Map<String, dynamic>> _parseESPNScheduleResponse(Map<String, dynamic> data) {
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
                'home': homeTeam['team']['displayName'] ?? 'TBD',
                'away': awayTeam['team']['displayName'] ?? 'TBD',
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
      print('Error parsing ESPN schedule response: $e');
      return [];
    }
  }

  /// Parse games from ESPN API response
  List<Map<String, dynamic>> _parseESPNResponse(Map<String, dynamic> data) {
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
              
              var situation = competition['situation'];
              String gameStatus = competition['status']['type']['name'] ?? 'scheduled';
              String possession = '';
              
              if (situation != null && gameStatus.toLowerCase() == 'in') {
                possession = situation['possession'] ?? '';
              }
              
              games.add({
                'date': formattedDate,
                'home': homeTeam['team']['displayName'] ?? 'TBD',
                'away': awayTeam['team']['displayName'] ?? 'TBD',
                'abbreviation': _getTeamAbbreviation(homeTeam['team']['abbreviation'] ?? ''),
                'abbreviation2': _getTeamAbbreviation(awayTeam['team']['abbreviation'] ?? ''),
                'picture': homeTeam['team']['logo'] ?? '',
                'picture2': awayTeam['team']['logo'] ?? '',
                'score': homeTeam['score']?.toString() ?? '0',
                'score2': awayTeam['score']?.toString() ?? '0',
                'status': gameStatus,
                'time': _formatTime(originalDate),
                'venue': competition['venue']?['fullName'] ?? '',
                'broadcast': competition['broadcasts']?[0]?['names']?.join(', ') ?? '',
                'favorite': favorite,
                'spread': spread,
                'possession': possession,
                'quarter': situation?['period'] ?? 0,
                'clock': situation?['clock'] ?? '',
                'down': situation?['down'] ?? 0,
                'distance': situation?['distance'] ?? 0,
                'yardLine': situation?['yardLine'] ?? 0,
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

  /// Helper method to format dates consistently for the app
  String _formatGameDate(String isoDate) {
    try {
      if (isoDate.isEmpty) return _formatDateForApp(DateTime.now());
      
      // Parse the ISO date
      DateTime dateTime = DateTime.parse(isoDate);
      
      // Format it in the app's expected format: "Thursday September 4TH, 2025"
      return _formatDateForApp(dateTime);
    } catch (e) {
      print('Error formatting date $isoDate: $e');
      return _formatDateForApp(DateTime.now());
    }
  }

  /// Format date in the app's expected format: "Thursday September 4TH, 2025"
  String _formatDateForApp(DateTime dateTime) {
    final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final months = ['January', 'February', 'March', 'April', 'May', 'June', 
                   'July', 'August', 'September', 'October', 'November', 'December'];
    
    String weekday = weekdays[dateTime.weekday - 1];
    String month = months[dateTime.month - 1];
    String day = '${dateTime.day}${_getOrdinalSuffix(dateTime.day).toUpperCase()}';
    String year = '${dateTime.year}';
    
    return '$weekday $month $day, $year';
  }

  /// Get ordinal suffix for a number (1st, 2nd, 3rd, etc)
  String _getOrdinalSuffix(int number) {
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

  /// Format time from ISO date string
  String _formatTime(String isoDate) {
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

  /// Get standardized team abbreviation
  String _getTeamAbbreviation(String espnAbbr) {
    // Handle special cases where ESPN abbreviations differ
    final originalAbbr = espnAbbr.toUpperCase();
    String result;
    
    switch (originalAbbr) {
      case 'WSH': result = 'WAS'; break;
      case 'JAC': result = 'JAX'; break;
      case 'GBP': result = 'GB'; break;
      case 'KCC': result = 'KC'; break;
      case 'SFO': result = 'SF'; break;
      case 'NEP': result = 'NE'; break;
      case 'NOS': result = 'NO'; break;
      case 'TBB': result = 'TB'; break;
      default: result = _teamMapping[originalAbbr] ?? originalAbbr;
    }
    
    print('_getTeamAbbreviation: "$espnAbbr" -> "$result"');
    return result;
  }

  /// Create mock data for testing
  List<Map<String, dynamic>> _createMockData() {
    print('Creating mock NFL schedule data...');
    
    // Get current date and add some days for realistic game dates
    DateTime now = DateTime.now();
    DateTime gameDate1 = now.add(Duration(days: 1));
    DateTime gameDate2 = now.add(Duration(days: 3));
    DateTime gameDate3 = now.add(Duration(days: 7));
    
    return [
      {
        'date': _formatDateForApp(gameDate1),
        'home': 'Kansas City Chiefs',
        'away': 'San Francisco 49ers', 
        'abbreviation': 'KC',
        'abbreviation2': 'SF',
        'picture': 'https://a.espncdn.com/i/teamlogos/nfl/500/kc.png',
        'picture2': 'https://a.espncdn.com/i/teamlogos/nfl/500/sf.png',
        'score': '28',
        'score2': '21',
        'status': 'completed',
        'time': _formatTime(gameDate1.toIso8601String()),
        'venue': 'Arrowhead Stadium',
        'broadcast': 'NBC',
      },
      {
        'date': _formatDateForApp(gameDate2),
        'home': 'Baltimore Ravens',
        'away': 'Buffalo Bills',
        'abbreviation': 'BAL', 
        'abbreviation2': 'BUF',
        'picture': 'https://a.espncdn.com/i/teamlogos/nfl/500/bal.png',
        'picture2': 'https://a.espncdn.com/i/teamlogos/nfl/500/buf.png',
        'score': '24',
        'score2': '17',
        'status': 'completed',
        'time': _formatTime(gameDate2.toIso8601String()),
        'venue': 'M&T Bank Stadium',
        'broadcast': 'CBS',
      },
      {
        'date': _formatDateForApp(gameDate3),
        'home': 'Detroit Lions',
        'away': 'Tampa Bay Buccaneers',
        'abbreviation': 'DET',
        'abbreviation2': 'TB', 
        'picture': 'https://a.espncdn.com/i/teamlogos/nfl/500/det.png',
        'picture2': 'https://a.espncdn.com/i/teamlogos/nfl/500/tb.png',
        'score': '31',
        'score2': '23', 
        'status': 'completed',
        'time': _formatTime(gameDate3.toIso8601String()),
        'venue': 'Ford Field',
        'broadcast': 'FOX',
      }
    ];
  }

  /// Normalize local schedule data to match expected format
  List<Map<String, dynamic>> _normalizeLocalScheduleData(List<dynamic> weekGames) {
    List<Map<String, dynamic>> normalizedGames = [];
    print('Normalizing ${weekGames.length} games from local data...');
    
    for (int i = 0; i < weekGames.length; i++) {
      var game = weekGames[i];
      print('Game $i - Original data:');
      print('  fullname: ${game['fullname']}');
      print('  fullname2: ${game['fullname2']}');
      print('  abbreviation: ${game['abbreviation']}');
      print('  abbreviation2: ${game['abbreviation2']}');
      
      var normalizedGame = {
        'date': game['date'],
        'home': game['fullname'] ?? game['home'] ?? '',
        'away': game['fullname2'] ?? game['away'] ?? '',
        'abbreviation': _getTeamAbbreviation(game['abbreviation'] ?? ''),
        'abbreviation2': _getTeamAbbreviation(game['abbreviation2'] ?? ''),
        'picture': game['picture'] ?? '',
        'picture2': game['picture2'] ?? '',
        'score': game['score'] ?? '0',
        'score2': game['score2'] ?? '0',
        'status': game['status'] ?? 'scheduled',
        'time': game['time'] ?? '',
        'venue': game['venue'] ?? '',
        'broadcast': game['broadcast'] ?? '',
        'favorite': game['favorite'] ?? '',
        'spread': double.tryParse(game['spread']?.toString() ?? '0') ?? 0.0,
        'possession': game['possession'] ?? '',
        'quarter': int.tryParse(game['quarter']?.toString() ?? '0') ?? 0,
        'clock': game['clock'] ?? '',
        'down': int.tryParse(game['down']?.toString() ?? '0') ?? 0,
        'distance': int.tryParse(game['distance']?.toString() ?? '0') ?? 0,
        'yardLine': int.tryParse(game['yardLine']?.toString() ?? '0') ?? 0,
      };
      
      print('Game $i - Normalized data:');
      print('  home: ${normalizedGame['home']}');
      print('  away: ${normalizedGame['away']}');
      print('  abbreviation: ${normalizedGame['abbreviation']}');
      print('  abbreviation2: ${normalizedGame['abbreviation2']}');
      
      normalizedGames.add(normalizedGame);
    }
    
    print('Normalization complete. Returning ${normalizedGames.length} games.');
    return normalizedGames;
  }
} 