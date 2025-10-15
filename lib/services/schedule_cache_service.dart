import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'nfl_schedule_service.dart';
import 'time_simulation_service.dart';

class ScheduleCacheService {
  static final ScheduleCacheService _instance = ScheduleCacheService._internal();
  factory ScheduleCacheService() => _instance;
  ScheduleCacheService._internal();

  static const String _cacheKey = 'nfl_schedule_cache';
  static const String _lastUpdateKey = 'nfl_schedule_last_update';
  static const Duration _cacheValidityDuration = Duration(hours: 6); // Check for updates every 6 hours
  static const Duration _forceUpdateDuration = Duration(days: 1); // Force update every 24 hours

  final NFLScheduleService _scheduleService = NFLScheduleService();
  final TimeSimulationService _timeSimulation = TimeSimulationService();

  /// Get schedule for a specific week, using cached data if available
  Future<List<Map<String, dynamic>>> getScheduleForWeek(String weekName, {int? year}) async {
    try {
      debugPrint('ScheduleCacheService: Getting schedule for $weekName');
      
      // Check if we're in demo mode
      if (kIsWeb) {
        debugPrint('ScheduleCacheService: Web platform detected, using local fallback');
        return await _scheduleService.getScheduleForWeekWithLocalFallback(weekName, year: year);
      }
      
      // Check if we have valid cached data
      final cachedData = await _getCachedSchedule();
      if (cachedData != null && await _isCacheValid()) {
        debugPrint('ScheduleCacheService: Using cached data for $weekName');
        return _extractWeekFromCache(cachedData, weekName);
      }
      
      // Cache is invalid or doesn't exist, fetch fresh data
      debugPrint('ScheduleCacheService: Cache invalid or missing, fetching fresh data');
      return await _fetchAndCacheSchedule(weekName, year: year);
      
    } catch (e) {
      debugPrint('ScheduleCacheService: Error getting schedule: $e');
      // Fallback to local file data
      return await _scheduleService.getScheduleForWeekWithLocalFallback(weekName, year: year);
    }
  }

  /// Get current week information, using cached data if available
  Future<Map<String, dynamic>?> getCurrentWeek() async {
    try {
      debugPrint('ScheduleCacheService: Getting current week');
      
      // Check if time simulation is enabled for testing
      if (_timeSimulation.isSimulationEnabled) {
        final simulatedWeekInfo = _timeSimulation.getSimulatedWeekInfo();
        if (simulatedWeekInfo != null) {
          debugPrint('ScheduleCacheService: Using simulated week: ${simulatedWeekInfo['week']}');
          return simulatedWeekInfo;
        }
      }
      
      // Check if we're in demo mode - use real 2025 season data
      if (kIsWeb) {
        debugPrint('ScheduleCacheService: Web platform detected, using real 2025 season data');
        // Use REG1 (Regular Season Week 1) - for testing with completed games
        return {
          'week': 'REG1', 
          'weekNumber': 1,
          'year': 2025,
          'mode': 'REG',
          'seasonType': 2, // Regular season
        };
      }
      
      // Check if we have valid cached data
      if (await _isCacheValid()) {
        debugPrint('ScheduleCacheService: Using cached current week data');
        return await _getCachedCurrentWeek();
      }
      
      // Cache is invalid, fetch fresh data
      debugPrint('ScheduleCacheService: Cache invalid, fetching fresh current week data');
      return await _fetchAndCacheCurrentWeek();
      
    } catch (e) {
      debugPrint('ScheduleCacheService: Error getting current week: $e');
      return null;
    }
  }

  /// Check if cache is still valid
  Future<bool> _isCacheValid() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastUpdate = prefs.getString(_lastUpdateKey);
      
      if (lastUpdate == null) {
        debugPrint('ScheduleCacheService: No cache timestamp found');
        return false;
      }
      
      final lastUpdateTime = DateTime.parse(lastUpdate);
      final now = DateTime.now();
      final timeSinceUpdate = now.difference(lastUpdateTime);
      
      debugPrint('ScheduleCacheService: Cache age: ${timeSinceUpdate.inHours} hours');
      
      // Check if we need to force an update (every 24 hours)
      if (timeSinceUpdate > _forceUpdateDuration) {
        debugPrint('ScheduleCacheService: Cache expired (force update)');
        return false;
      }
      
      // Check if we should check for updates (every 6 hours)
      if (timeSinceUpdate > _cacheValidityDuration) {
        debugPrint('ScheduleCacheService: Cache needs update check');
        // Try to fetch updates in background, but return cached data immediately
        _checkForUpdatesInBackground();
        return true; // Still return cached data while checking for updates
      }
      
      debugPrint('ScheduleCacheService: Cache is valid');
      return true;
    } catch (e) {
      debugPrint('ScheduleCacheService: Error checking cache validity: $e');
      return false;
    }
  }

  /// Get cached schedule data
  Future<Map<String, dynamic>?> _getCachedSchedule() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_cacheKey);
      
      if (cachedData != null) {
        return json.decode(cachedData);
      }
      
      return null;
    } catch (e) {
      debugPrint('ScheduleCacheService: Error getting cached schedule: $e');
      return null;
    }
  }

  /// Extract specific week data from cached schedule
  List<Map<String, dynamic>> _extractWeekFromCache(Map<String, dynamic> cachedData, String weekName) {
    try {
      String weekType = '';
      if (weekName.startsWith('PRE')) weekType = 'preseason';
      else if (weekName.startsWith('REG')) weekType = 'regular';
      else if (weekName.startsWith('POST')) weekType = 'postseason';
      
      final weekGames = cachedData[weekType]?[weekName];
      if (weekGames != null && weekGames is List && weekGames.isNotEmpty) {
        debugPrint('ScheduleCacheService: Found ${weekGames.length} games for $weekName in cache');
        return _normalizeLocalScheduleData(weekGames);
      }
      
      debugPrint('ScheduleCacheService: No games found for $weekName in cache');
      return [];
    } catch (e) {
      debugPrint('ScheduleCacheService: Error extracting week from cache: $e');
      return [];
    }
  }

  /// Fetch fresh schedule data and cache it
  Future<List<Map<String, dynamic>>> _fetchAndCacheSchedule(String weekName, {int? year}) async {
    try {
      debugPrint('ScheduleCacheService: Fetching fresh schedule data');
      
      // Try to fetch from API first
      final apiData = await _fetchScheduleFromAPI();
      if (apiData.isNotEmpty) {
        debugPrint('ScheduleCacheService: Successfully fetched ${apiData.length} games from API');
        await _cacheScheduleData(apiData);
        return _extractWeekFromCache(apiData, weekName);
      }
      
      // Fallback to local file data
      debugPrint('ScheduleCacheService: API failed, using local file data');
      final localData = await _scheduleService.getScheduleForWeekWithLocalFallback(weekName, year: year);
      if (localData.isNotEmpty) {
        // Cache the local data structure
        await _cacheLocalDataStructure();
      }
      return localData;
      
    } catch (e) {
      debugPrint('ScheduleCacheService: Error fetching and caching schedule: $e');
      return await _scheduleService.getScheduleForWeekWithLocalFallback(weekName, year: year);
    }
  }

  /// Fetch schedule data from API
  Future<Map<String, dynamic>> _fetchScheduleFromAPI() async {
    try {
      // Try to fetch preseason first (since that's what we're testing)
      final preseasonResponse = await http.get(
        Uri.parse('https://site.api.espn.com/apis/site/v2/sports/football/nfl/schedule?year=2025&seasontype=1'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ).timeout(Duration(seconds: 10));
      
      if (preseasonResponse.statusCode == 200) {
        final data = json.decode(preseasonResponse.body);
        return _parseAPIScheduleData(data, 'preseason');
      }
      
      debugPrint('ScheduleCacheService: API returned status ${preseasonResponse.statusCode}');
      return {};
      
    } catch (e) {
      debugPrint('ScheduleCacheService: Error fetching from API: $e');
      return {};
    }
  }

  /// Parse API schedule data into our format
  Map<String, dynamic> _parseAPIScheduleData(Map<String, dynamic> apiData, String seasonType) {
    try {
      final Map<String, dynamic> parsedData = {
        seasonType: {},
      };
      
      if (apiData['events'] != null) {
        // Group events by week
        final Map<String, List<dynamic>> weekGroups = {};
        
        for (var event in apiData['events']) {
          final week = event['week']?['number']?.toString() ?? '1';
          final weekKey = '${seasonType.toUpperCase()}$week';
          
          if (!weekGroups.containsKey(weekKey)) {
            weekGroups[weekKey] = [];
          }
          
          // Parse event into our format
          final parsedEvent = _parseEventToLocalFormat(event);
          if (parsedEvent != null) {
            weekGroups[weekKey]!.add(parsedEvent);
          }
        }
        
        parsedData[seasonType] = weekGroups;
      }
      
      debugPrint('ScheduleCacheService: Parsed ${parsedData[seasonType].length} weeks from API');
      return parsedData;
      
    } catch (e) {
      debugPrint('ScheduleCacheService: Error parsing API data: $e');
      return {};
    }
  }

  /// Parse individual event to local format
  Map<String, dynamic>? _parseEventToLocalFormat(Map<String, dynamic> event) {
    try {
      var competition = event['competitions']?[0];
      if (competition == null) return null;
      
      var competitors = competition['competitors'];
      if (competitors == null || competitors.length < 2) return null;
      
      var homeTeam = competitors.firstWhere((c) => c['homeAway'] == 'home', orElse: () => competitors[0]);
      var awayTeam = competitors.firstWhere((c) => c['homeAway'] == 'away', orElse: () => competitors[1]);
      
      return {
        'date': _formatGameDate(event['date'] ?? ''),
        'fullname': homeTeam['team']['displayName'] ?? 'TBD',
        'fullname2': awayTeam['team']['displayName'] ?? 'TBD',
        'abbreviation': _getTeamAbbreviation(homeTeam['team']['abbreviation'] ?? ''),
        'abbreviation2': _getTeamAbbreviation(awayTeam['team']['abbreviation'] ?? ''),
        'picture': homeTeam['team']['logo'] ?? '',
        'picture2': awayTeam['team']['logo'] ?? '',
        'score': homeTeam['score']?.toString() ?? '0',
        'score2': awayTeam['score']?.toString() ?? '0',
        'status': competition['status']['type']['name'] ?? 'scheduled',
        'time': _formatTime(event['date'] ?? ''),
        'venue': competition['venue']?['fullName'] ?? '',
        'broadcast': competition['broadcasts']?[0]?['names']?.join(', ') ?? '',
        'favorite': '',
        'spread': 0.0,
      };
    } catch (e) {
      debugPrint('ScheduleCacheService: Error parsing event: $e');
      return null;
    }
  }

  /// Format game date
  String _formatGameDate(String originalDate) {
    try {
      final date = DateTime.parse(originalDate);
      final months = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ];
      
      final day = date.day;
      final month = months[date.month - 1];
      final year = date.year;
      
      String daySuffix = 'TH';
      if (day == 1 || day == 21 || day == 31) daySuffix = 'ST';
      else if (day == 2 || day == 22) daySuffix = 'ND';
      else if (day == 3 || day == 23) daySuffix = 'RD';
      
      return '$month ${day}${daySuffix}, $year';
    } catch (e) {
      debugPrint('ScheduleCacheService: Error formatting date: $e');
      return DateTime.now().toString();
    }
  }

  /// Format game time
  String _formatTime(String originalDate) {
    try {
      final date = DateTime.parse(originalDate);
      final hour = date.hour;
      final minute = date.minute;
      final isPM = hour >= 12;
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '${displayHour}:${minute.toString().padLeft(2, '0')} ${isPM ? 'PM' : 'AM'}';
    } catch (e) {
      debugPrint('ScheduleCacheService: Error formatting time: $e');
      return '8:00 PM';
    }
  }

  /// Cache schedule data
  Future<void> _cacheScheduleData(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, json.encode(data));
      await prefs.setString(_lastUpdateKey, DateTime.now().toIso8601String());
      debugPrint('ScheduleCacheService: Successfully cached schedule data');
    } catch (e) {
      debugPrint('ScheduleCacheService: Error caching schedule data: $e');
    }
  }

  /// Cache local data structure (for fallback)
  Future<void> _cacheLocalDataStructure() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastUpdateKey, DateTime.now().toIso8601String());
      debugPrint('ScheduleCacheService: Cached local data structure timestamp');
    } catch (e) {
      debugPrint('ScheduleCacheService: Error caching local data structure: $e');
    }
  }

  /// Get cached current week
  Future<Map<String, dynamic>?> _getCachedCurrentWeek() async {
    try {
      // For now, return a default preseason week
      // In a real implementation, this would be determined from the cached data
      return {
        'week': 1,
        'season_type': 1,
        'season': 2025,
        'seasonName': 'PRE'
      };
    } catch (e) {
      debugPrint('ScheduleCacheService: Error getting cached current week: $e');
      return null;
    }
  }

  /// Fetch and cache current week
  Future<Map<String, dynamic>?> _fetchAndCacheCurrentWeek() async {
    try {
      final currentWeek = await _scheduleService.getCurrentWeek();
      if (currentWeek != null) {
        await _cacheLocalDataStructure(); // Update cache timestamp
      }
      return currentWeek;
    } catch (e) {
      debugPrint('ScheduleCacheService: Error fetching and caching current week: $e');
      return null;
    }
  }

  /// Check for updates in background
  void _checkForUpdatesInBackground() {
    // This would run in the background to check for schedule updates
    // For now, just log that we would check for updates
    debugPrint('ScheduleCacheService: Would check for updates in background');
  }

  /// Clear cache (for testing or manual refresh)
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      await prefs.remove(_lastUpdateKey);
      debugPrint('ScheduleCacheService: Cache cleared');
    } catch (e) {
      debugPrint('ScheduleCacheService: Error clearing cache: $e');
    }
  }

  /// Get cache status for debugging
  Future<Map<String, dynamic>> getCacheStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastUpdate = prefs.getString(_lastUpdateKey);
      final hasCachedData = prefs.getString(_cacheKey) != null;
      
      return {
        'hasCachedData': hasCachedData,
        'lastUpdate': lastUpdate,
        'isValid': await _isCacheValid(),
      };
    } catch (e) {
      debugPrint('ScheduleCacheService: Error getting cache status: $e');
      return {
        'hasCachedData': false,
        'lastUpdate': null,
        'isValid': false,
      };
    }
  }

  /// Normalize local schedule data to match expected format
  List<Map<String, dynamic>> _normalizeLocalScheduleData(List<dynamic> weekGames) {
    List<Map<String, dynamic>> normalizedGames = [];
    
    for (var game in weekGames) {
      var normalizedGame = {
        'date': game['date'],
        'fullname': game['fullname'] ?? '',
        'fullname2': game['fullname2'] ?? '',
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
      };
      
      normalizedGames.add(normalizedGame);
    }
    
    return normalizedGames;
  }

  /// Get team abbreviation with mapping
  String _getTeamAbbreviation(String espnAbbr) {
    // Team abbreviation mapping to match your app's format
    const Map<String, String> teamMapping = {
      'ARI': 'ARI', 'ATL': 'ATL', 'BAL': 'BAL', 'BUF': 'BUF',
      'CAR': 'CAR', 'CHI': 'CHI', 'CIN': 'CIN', 'CLE': 'CLE',
      'DAL': 'DAL', 'DEN': 'DEN', 'DET': 'DET', 'GB': 'GB',
      'HOU': 'HOU', 'IND': 'IND', 'JAX': 'JAX', 'KC': 'KC',
      'LV': 'LV', 'LAC': 'LAC', 'LAR': 'LAR', 'MIA': 'MIA',
      'MIN': 'MIN', 'NE': 'NE', 'NO': 'NO', 'NYG': 'NYG',
      'NYJ': 'NYJ', 'PHI': 'PHI', 'PIT': 'PIT', 'SF': 'SF',
      'SEA': 'SEA', 'TB': 'TB', 'TEN': 'TEN', 'WAS': 'WAS'
    };
    
    final result = teamMapping[espnAbbr] ?? espnAbbr;
    return result;
  }
} 