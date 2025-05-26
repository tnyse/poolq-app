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
        return _parseGamesFromESPN(data);
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
    return _getMockGamesForWeek(weekName);
  }

  /// Parse games from ESPN API response
  List<Map<String, dynamic>> _parseGamesFromESPN(Map<String, dynamic> data) {
    List<Map<String, dynamic>> games = [];
    
    final events = data['events'] as List?;
    if (events == null) return games;

    for (var event in events) {
      try {
        final competitions = event['competitions'] as List?;
        if (competitions == null || competitions.isEmpty) continue;
        
        final competition = competitions[0];
        final competitors = competition['competitors'] as List?;
        if (competitors == null || competitors.length < 2) continue;

        final homeTeam = competitors.firstWhere((c) => c['homeAway'] == 'home');
        final awayTeam = competitors.firstWhere((c) => c['homeAway'] == 'away');

        final game = {
          '_id': event['id'],
          'date': _formatDate(event['date']),
          'time': _formatTime(event['date']),
          'year': '2025',
          'week': data['week']?['number']?.toString() ?? '1',
          'abbreviation': _getTeamAbbreviation(awayTeam['team']['abbreviation']),
          'abbreviation2': _getTeamAbbreviation(homeTeam['team']['abbreviation']),
          'fullname': awayTeam['team']['displayName'],
          'fullname2': homeTeam['team']['displayName'],
          'picture': awayTeam['team']['logo'],
          'picture2': homeTeam['team']['logo'],
          'score': awayTeam['score']?.toString() ?? '0',
          'score2': homeTeam['score']?.toString() ?? '0',
          'status': competition['status']['type']['description'] ?? 'Scheduled',
        };

        games.add(game);
      } catch (e) {
        print('Error parsing game from ESPN: $e');
      }
    }

    return games;
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

  /// Mock data fallback
  List<Map<String, dynamic>> _getMockGamesForWeek(String weekName) {
    // Return basic mock data structure
    return [
      {
        '_id': 'mock_game_1',
        'date': 'Sunday September 7th, 2025',
        'time': '1:00 PM',
        'year': '2025',
        'week': '1',
        'abbreviation': 'KC',
        'abbreviation2': 'SF',
        'fullname': 'Kansas City Chiefs',
        'fullname2': 'San Francisco 49ers',
        'picture': 'https://static.www.nfl.com/image/private/f_auto/league/ujshjqvmnxce8m4obmvs',
        'picture2': 'https://static.www.nfl.com/image/private/f_auto/league/dxibuyxbk0b9ua5ih9hn',
        'score': '0',
        'score2': '0',
        'status': 'Scheduled',
      }
    ];
  }
} 