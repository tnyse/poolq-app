import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'nfl_game_service.dart';

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

  /// Fetches current NFL week from ESPN
  Future<Map<String, dynamic>?> getCurrentWeek() async {
    try {
      final response = await http.get(
        Uri.parse(_getApiUrl(_espnScoreboardUrl)),
        headers: _getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        return {
          'week': data['week']?['number'] ?? 1,
          'season_type': data['season']?['type'] ?? 2, // 2 = regular season
          'season': data['season']?['year'] ?? 2025,
          'seasonName': _getSeasonTypeName(data['season']?['type'] ?? 2),
        };
      }
      
      // If ESPN API fails, return default values
      debugPrint('ESPN API returned status code: ${response.statusCode}, using default values');
      return {
        'week': 1,
        'season_type': 2,
        'season': 2025,
        'seasonName': 'REG',
      };
    } catch (e) {
      debugPrint('Error fetching current week: $e, using default values');
      return {
        'week': 1,
        'season_type': 2,
        'season': 2025,
        'seasonName': 'REG',
      };
    }
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

  /// Fetches NFL schedule for a specific week with fallback options
  Future<List<Map<String, dynamic>>> getScheduleWithFallback(String weekName) async {
    try {
      // Parse week number from weekName (e.g., "REG1" -> 1)
      final weekMatch = RegExp(r'\d+').firstMatch(weekName);
      final week = weekMatch != null ? int.parse(weekMatch.group(0)!) : 1;
      
      // Try primary schedule endpoint
      final games = await getScheduleForWeek(week);
      if (games.isNotEmpty) {
        return games;
      }

      debugPrint('Primary schedule endpoint returned no games, trying fallback...');
      
      // Try scoreboard endpoint as fallback
      final response = await http.get(
        Uri.parse(_getApiUrl('$_espnScoreboardUrl?week=$week')),
        headers: _getHeaders(),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final fallbackGames = _parseESPNResponse(data);
        if (fallbackGames.isNotEmpty) {
          return fallbackGames;
        }
      }

      // If all external APIs fail, use mock data
      debugPrint('All NFL data sources failed, using mock data');
      final mockService = NFLGameService();
      return mockService.getMockGamesForWeek(weekName);
    } catch (e) {
      debugPrint('Error fetching schedule with fallback: $e, using mock data');
      final mockService = NFLGameService();
      return mockService.getMockGamesForWeek(weekName);
    }
  }

  /// Fetches NFL schedule for a specific week
  Future<List<Map<String, dynamic>>> getScheduleForWeek(int week, {int season = 2025, int seasonType = 2}) async {
    try {
      // First try the scoreboard endpoint for live data
      final response = await http.get(
        Uri.parse(_getApiUrl('$_espnScoreboardUrl?dates=$season&seasontype=$seasonType&week=$week')),
        headers: _getHeaders(),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final games = _parseESPNResponse(data);
        
        if (games.isNotEmpty) {
          debugPrint('Successfully fetched ${games.length} games from ESPN scoreboard');
          return games;
        }
      }

      // If scoreboard fails, try the schedule endpoint
      final scheduleResponse = await http.get(
        Uri.parse(_getApiUrl('$_espnScheduleUrl?dates=$season&seasontype=$seasonType&week=$week')),
        headers: _getHeaders(),
      ).timeout(const Duration(seconds: 15));

      if (scheduleResponse.statusCode == 200) {
        final data = json.decode(scheduleResponse.body);
        final games = _parseESPNScheduleResponse(data);
        
        if (games.isNotEmpty) {
          debugPrint('Successfully fetched ${games.length} games from ESPN schedule');
          return games;
        }
      }

      // If both endpoints fail, use mock data
      debugPrint('ESPN API returned no games for week $week, using mock data');
      final mockService = NFLGameService();
      return mockService.getMockGamesForWeek('REG$week');
    } catch (e) {
      debugPrint('Error fetching schedule from ESPN: $e, using mock data');
      final mockService = NFLGameService();
      return mockService.getMockGamesForWeek('REG$week');
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

  /// Alternative method using NFL.com endpoint (unofficial)
  Future<List<Map<String, dynamic>>> getScheduleFromNFL(String weekName) async {
    try {
      // Convert week format (REG1 -> 1)
      int weekNumber = _parseWeekNumber(weekName);
      
      final response = await http.get(
        Uri.parse('https://www.nfl.com/api/researchExportedJson/mobile/games/2025/REG/$weekNumber'),
        headers: {
          'User-Agent': 'PoolQ-App/1.0',
          'Accept': 'application/json',
          'Referer': 'https://www.nfl.com/',
        },
      ).timeout(Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parseGamesFromNFL(data);
      }
    } catch (e) {
      print('Error fetching from NFL.com API: $e');
    }
    return [];
  }

  /// Parse games from NFL.com API response
  List<Map<String, dynamic>> _parseGamesFromNFL(Map<String, dynamic> data) {
    List<Map<String, dynamic>> games = [];
    
    try {
      if (data['games'] != null) {
        for (var game in data['games']) {
          games.add({
            'date': _formatGameDate(game['gameTime'] ?? ''),
            'home': game['homeTeam']?['fullName'] ?? 'TBD',
            'away': game['awayTeam']?['fullName'] ?? 'TBD',
            'abbreviation': _getTeamAbbreviation(game['homeTeam']?['abbreviation'] ?? ''),
            'abbreviation2': _getTeamAbbreviation(game['awayTeam']?['abbreviation'] ?? ''),
            'picture': 'https://static.www.nfl.com/image/private/f_auto/league/${game['homeTeam']?['logoId'] ?? ''}',
            'picture2': 'https://static.www.nfl.com/image/private/f_auto/league/${game['awayTeam']?['logoId'] ?? ''}',
            'score': game['homeTeam']?['score']?.toString() ?? '0',
            'score2': game['awayTeam']?['score']?.toString() ?? '0',
            'status': game['status']?.toLowerCase() ?? 'scheduled',
            'time': _formatTime(game['gameTime'] ?? ''),
            'venue': game['venue']?['fullName'] ?? '',
            'broadcast': game['broadcast'] ?? '',
          });
        }
      }
      
      return games;
    } catch (e) {
      print('Error parsing NFL.com response: $e');
      return [];
    }
  }

  /// Convert week name (REG1, REG2, etc.) to number
  int _parseWeekNumber(String weekName) {
    final regex = RegExp(r'[A-Za-z]+(\d+)');
    final match = regex.firstMatch(weekName);
    return match != null ? int.parse(match.group(1)!) : 1;
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
} 