import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class NFLScheduleService {
  static final NFLScheduleService _instance = NFLScheduleService._internal();
  
  factory NFLScheduleService() {
    return _instance;
  }
  
  NFLScheduleService._internal();

  // ESPN API endpoints
  static const String _espnBaseUrl = 'https://site.api.espn.com/apis/site/v2/sports/football/nfl';
  
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

  /// Fetches current NFL week from ESPN
  Future<Map<String, dynamic>?> getCurrentWeek() async {
    try {
      final response = await http.get(
        Uri.parse('$_espnBaseUrl/scoreboard'),
        headers: {
          'User-Agent': 'PoolQ-App/1.0',
          'Accept': 'application/json',
        },
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        return {
          'week': data['week']?['number'] ?? 1,
          'season_type': data['season']?['type'] ?? 2, // 2 = regular season
          'season': data['season']?['year'] ?? 2025,
        };
      }
    } catch (e) {
      print('Error fetching current week: $e');
    }
    return null;
  }

  /// Fetches NFL schedule for a specific week
  Future<List<Map<String, dynamic>>> getScheduleForWeek(int week, {int season = 2025, int seasonType = 2}) async {
    try {
      final response = await http.get(
        Uri.parse('$_espnBaseUrl/scoreboard?dates=${season}&seasontype=$seasonType&week=$week'),
        headers: {
          'User-Agent': 'PoolQ-App/1.0',
          'Accept': 'application/json',
        },
      ).timeout(Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parseESPNResponse(data);
      } else {
        print('ESPN API returned status: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error fetching schedule from ESPN: $e');
      return [];
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

  /// Fetches schedule with fallback mechanism
  Future<List<Map<String, dynamic>>> getScheduleWithFallback(String weekName) async {
    int weekNumber = _parseWeekNumber(weekName);
    
    // Try ESPN first
    List<Map<String, dynamic>> games = await getScheduleForWeek(weekNumber);
    
    if (games.isNotEmpty) {
      print('Successfully fetched ${games.length} games from ESPN API');
      return games;
    }

    // Try NFL.com as fallback
    games = await getScheduleFromNFL(weekName);
    
    if (games.isNotEmpty) {
      print('Successfully fetched ${games.length} games from NFL.com API');
      return games;
    }

    // Use mock data as last resort
    print('Using mock data for week $weekName');
    return _createMockData();
  }

  /// Parse games from ESPN API response
  List<Map<String, dynamic>> _parseESPNResponse(Map<String, dynamic> data) {
    try {
      List<Map<String, dynamic>> games = [];
      
      if (data['events'] != null) {
        for (var event in data['events']) {
          var competition = event['competitions']?[0];
          if (competition != null) {
            var competitors = competition['competitors'];
            if (competitors != null && competitors.length >= 2) {
              // Parse the ISO date and format it consistently
              String originalDate = event['date'] ?? '';
              String formattedDate = _formatGameDate(originalDate);
              
              var homeTeam = competitors.firstWhere((c) => c['homeAway'] == 'home', orElse: () => competitors[0]);
              var awayTeam = competitors.firstWhere((c) => c['homeAway'] == 'away', orElse: () => competitors[1]);
              
              games.add({
                'date': formattedDate, // Use consistently formatted date
                'home': homeTeam['team']['displayName'] ?? 'TBD',
                'away': awayTeam['team']['displayName'] ?? 'TBD',
                'abbreviation': _getTeamAbbreviation(homeTeam['team']['displayName'] ?? ''),
                'abbreviation2': _getTeamAbbreviation(awayTeam['team']['displayName'] ?? ''),
                'picture': homeTeam['team']['logo'] ?? '',
                'picture2': awayTeam['team']['logo'] ?? '',
                'score': homeTeam['score']?.toString() ?? '0',
                'score2': awayTeam['score']?.toString() ?? '0',
                'status': competition['status']['type']['name'] ?? 'scheduled',
              });
            }
          }
        }
      }
      
      print('Successfully parsed ${games.length} games from ESPN API');
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
    String day = '${dateTime.day}${_getOrdinalSuffix(dateTime.day)}';
    String year = '${dateTime.year}';
    
    return '$weekday $month $day, $year';
  }

  /// Parse games from NFL.com API response
  List<Map<String, dynamic>> _parseGamesFromNFL(Map<String, dynamic> data) {
    List<Map<String, dynamic>> games = [];
    
    // NFL.com API structure may vary, implement based on actual response
    // This is a placeholder implementation
    
    return games;
  }

  /// Convert week name (REG1, REG2, etc.) to number
  int _parseWeekNumber(String weekName) {
    final regex = RegExp(r'REG(\d+)');
    final match = regex.firstMatch(weekName.toUpperCase());
    return match != null ? int.parse(match.group(1)!) : 1;
  }

  /// Get standardized team abbreviation
  String _getTeamAbbreviation(String espnAbbr) {
    // Handle special cases where ESPN abbreviations differ
    switch (espnAbbr) {
      case 'WSH': return 'WAS';
      default: return _teamMapping[espnAbbr] ?? espnAbbr;
    }
  }

  /// Format date for display
  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      final weekday = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'][date.weekday - 1];
      final month = ['January', 'February', 'March', 'April', 'May', 'June', 
                    'July', 'August', 'September', 'October', 'November', 'December'][date.month - 1];
      return '$weekday ${month} ${date.day}${_getOrdinalSuffix(date.day)}, ${date.year}';
    } catch (e) {
      return 'TBD';
    }
  }

  /// Format time for display
  String _formatTime(String isoDate) {
    try {
      final date = DateTime.parse(isoDate).toLocal();
      final hour = date.hour == 0 ? 12 : (date.hour > 12 ? date.hour - 12 : date.hour);
      final minute = date.minute.toString().padLeft(2, '0');
      final period = date.hour >= 12 ? 'PM' : 'AM';
      return '$hour:$minute $period';
    } catch (e) {
      return 'TBD';
    }
  }

  /// Get ordinal suffix for day (1st, 2nd, 3rd, etc.)
  String _getOrdinalSuffix(int day) {
    if (day >= 11 && day <= 13) return 'th';
    switch (day % 10) {
      case 1: return 'st';
      case 2: return 'nd';
      case 3: return 'rd';
      default: return 'th';
    }
  }

  List<Map<String, dynamic>> _createMockData() {
    print('Creating mock NFL schedule data...');
    
    // Get current date and add some days for realistic game dates
    DateTime now = DateTime.now();
    DateTime gameDate1 = now.add(Duration(days: 1));
    DateTime gameDate2 = now.add(Duration(days: 3));
    DateTime gameDate3 = now.add(Duration(days: 7));
    
    return [
      {
        'date': _formatDateForApp(gameDate1), // Use consistent app format
        'home': 'Kansas City Chiefs',
        'away': 'San Francisco 49ers', 
        'abbreviation': 'KC',
        'abbreviation2': 'SF',
        'picture': 'https://a.espncdn.com/i/teamlogos/nfl/500/kc.png',
        'picture2': 'https://a.espncdn.com/i/teamlogos/nfl/500/sf.png',
        'score': '28',
        'score2': '21',
        'status': 'completed'
      },
      {
        'date': _formatDateForApp(gameDate2), // Use consistent app format
        'home': 'Baltimore Ravens',
        'away': 'Buffalo Bills',
        'abbreviation': 'BAL', 
        'abbreviation2': 'BUF',
        'picture': 'https://a.espncdn.com/i/teamlogos/nfl/500/bal.png',
        'picture2': 'https://a.espncdn.com/i/teamlogos/nfl/500/buf.png',
        'score': '24',
        'score2': '17',
        'status': 'completed'
      },
      {
        'date': _formatDateForApp(gameDate3), // Use consistent app format  
        'home': 'Detroit Lions',
        'away': 'Tampa Bay Buccaneers',
        'abbreviation': 'DET',
        'abbreviation2': 'TB', 
        'picture': 'https://a.espncdn.com/i/teamlogos/nfl/500/det.png',
        'picture2': 'https://a.espncdn.com/i/teamlogos/nfl/500/tb.png',
        'score': '31',
        'score2': '23', 
        'status': 'completed'
      }
    ];
  }
} 