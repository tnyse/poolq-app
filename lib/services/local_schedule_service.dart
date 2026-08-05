import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:poolqapp/constants/season_config.dart';
import 'package:poolqapp/services/app_config_service.dart';

class LocalScheduleService {
  static final LocalScheduleService _instance = LocalScheduleService._internal();
  factory LocalScheduleService() => _instance;
  LocalScheduleService._internal();

  Future<String> _loadScheduleJson() async {
    final year = AppConfigService().isLoaded
        ? AppConfigService().currentSeason
        : SeasonConfig.currentSeasonYear();
    final primary = SeasonConfig.assetPathForYear(year);
    try {
      return await rootBundle.loadString(primary);
    } catch (_) {
      // Fallback to previous season asset if 2026 not bundled yet
      return await rootBundle.loadString(SeasonConfig.assetPathForYear(year - 1));
    }
  }

  /// Load schedule from local JSON file
  Future<List<Map<String, dynamic>>> getScheduleForWeek(String weekName) async {
    try {
      debugPrint('LocalScheduleService: Loading schedule for $weekName');
      
      final jsonString = await _loadScheduleJson();
      final scheduleData = json.decode(jsonString);
      
      // New format: scheduleData['weeks'][weekName]
      final weekGames = scheduleData['weeks']?[weekName];
      if (weekGames != null && weekGames is List && weekGames.isNotEmpty) {
        debugPrint('LocalScheduleService: Loaded ${weekGames.length} games for $weekName');
        return _normalizeScheduleData(weekGames);
      }
      
      debugPrint('LocalScheduleService: No games found for $weekName');
      return [];
    } catch (e) {
      debugPrint('LocalScheduleService: Error loading schedule: $e');
      return [];
    }
  }

  /// Earliest kickoff (UTC) for a week from raw schedule JSON.
  Future<DateTime?> getFirstKickoff(String weekName) async {
    try {
      final jsonString = await _loadScheduleJson();
      final scheduleData = json.decode(jsonString);
      final weekGames = scheduleData['weeks']?[weekName];
      if (weekGames is! List || weekGames.isEmpty) return null;

      DateTime? earliest;
      for (final game in weekGames) {
        final dateStr = game['date']?.toString();
        if (dateStr == null || dateStr.isEmpty) continue;
        final kickoff = DateTime.tryParse(dateStr);
        if (kickoff == null) continue;
        if (earliest == null || kickoff.isBefore(earliest)) {
          earliest = kickoff;
        }
      }
      return earliest;
    } catch (e) {
      debugPrint('LocalScheduleService: getFirstKickoff error: $e');
      return null;
    }
  }

  /// Available week keys in the bundled schedule (sorted).
  Future<List<String>> listWeeks() async {
    try {
      final jsonString = await _loadScheduleJson();
      final scheduleData = json.decode(jsonString);
      final weeks = scheduleData['weeks'];
      if (weeks is! Map) return const ['PRE1'];
      final keys = weeks.keys.map((k) => k.toString()).toList();
      keys.sort();
      return keys;
    } catch (_) {
      return const ['PRE1', 'PRE2', 'PRE3'];
    }
  }

  /// Get current week information
  Future<Map<String, dynamic>?> getCurrentWeek() async {
    try {
      debugPrint('LocalScheduleService: Getting current week');
      final config = AppConfigService();
      final week = config.isLoaded
          ? config.activeWeek
          : SeasonConfig.defaultWeekName();
      final year = config.isLoaded
          ? config.currentSeason
          : SeasonConfig.currentSeasonYear();
      final mode = SeasonConfig.modeFromWeek(week);
      
      return {
        'week': week,
        'season_type': SeasonConfig.seasonTypeFromWeek(week),
        'season': year,
        'seasonName': mode,
        'year': year,
        'mode': mode,
      };
    } catch (e) {
      debugPrint('LocalScheduleService: Error getting current week: $e');
      return null;
    }
  }

  /// Update scores for a specific week (optional API call)
  Future<List<Map<String, dynamic>>> updateScoresForWeek(String weekName) async {
    try {
      debugPrint('LocalScheduleService: Updating scores for $weekName');
      
      // For demo mode, return the same schedule with mock scores
      final schedule = await getScheduleForWeek(weekName);
      
      // Add some mock scores for demo
      for (var game in schedule) {
        if (game['score'] == '0' && game['score2'] == '0') {
          // Add random scores for demo
          game['score'] = '24';
          game['score2'] = '17';
          game['status'] = 'final';
        }
      }
      
      return schedule;
    } catch (e) {
      debugPrint('LocalScheduleService: Error updating scores: $e');
      return await getScheduleForWeek(weekName);
    }
  }

  /// ESPN alternate codes → PoolQ pick / asset abbreviations.
  static String normalizeTeamAbbr(String? raw) {
    final clean = (raw ?? '').toUpperCase().replaceAll(' ', '').trim();
    switch (clean) {
      case 'WSH':
        return 'WAS';
      case 'JAC':
        return 'JAX';
      default:
        return clean;
    }
  }

  /// Normalize schedule data to match expected format
  List<Map<String, dynamic>> _normalizeScheduleData(List<dynamic> weekGames) {
    List<Map<String, dynamic>> normalizedGames = [];
    
    for (var game in weekGames) {
      // Handle new format with homeTeam/awayTeam objects
      final homeTeam = Map<String, dynamic>.from(
        (game['homeTeam'] as Map?)?.cast<String, dynamic>() ?? const {},
      );
      final awayTeam = Map<String, dynamic>.from(
        (game['awayTeam'] as Map?)?.cast<String, dynamic>() ?? const {},
      );
      final homeAbbr = normalizeTeamAbbr(homeTeam['abbreviation']?.toString());
      final awayAbbr = normalizeTeamAbbr(awayTeam['abbreviation']?.toString());
      homeTeam['abbreviation'] = homeAbbr;
      awayTeam['abbreviation'] = awayAbbr;
      if (homeAbbr.isNotEmpty) {
        homeTeam['logo'] = 'assets/images/teams/$homeAbbr.png';
      }
      if (awayAbbr.isNotEmpty) {
        awayTeam['logo'] = 'assets/images/teams/$awayAbbr.png';
      }
      final rawDate = game['date']?.toString() ?? '';
      
      // Convert ISO date to app's expected format
      String formattedDate = _formatDateForApp(rawDate);
      
      var normalizedGame = {
        // Keep ISO for DateTime.parse callers (FrontPage, kickoff, etc.)
        'dateIso': rawDate,
        'date': formattedDate,
        'homeTeam': homeTeam,
        'awayTeam': awayTeam,
        'homeScore': game['homeScore'] ?? 0,
        'awayScore': game['awayScore'] ?? 0,
        'completed': game['completed'] == true,
        'fullname': homeTeam['name'] ?? '',
        'fullname2': awayTeam['name'] ?? '',
        'abbreviation': homeAbbr,
        'abbreviation2': awayAbbr,
        'picture': homeTeam['logo'] ?? '',
        'picture2': awayTeam['logo'] ?? '',
        'score': game['homeScore']?.toString() ?? '0',
        'score2': game['awayScore']?.toString() ?? '0',
        'status': game['status'] ?? 'scheduled',
        'time': _formatTimeForApp(rawDate),
        'venue': game['venue'] ?? '',
        'broadcast': game['broadcast'] ?? '',
        'favorite': '', // Not provided in new format
        'spread': 0.0, // Not provided in new format
        'week': game['week'] ?? '',
        'mode': game['mode'] ?? '',
        'weekNumber': game['weekNumber'] ?? 0,
        'year': game['year'] ?? 2025,
        'id': game['id'] ?? '',
        'name': game['name'] ?? '',
        'shortName': game['shortName'] ?? '',
      };
      
      normalizedGames.add(normalizedGame);
    }
    
    return normalizedGames;
  }

  /// Convert ISO date to app's expected format: "Friday August 8TH, 2025"
  String _formatDateForApp(String isoDate) {
    try {
      if (isoDate.isEmpty) return 'Thursday August 7TH, 2025'; // Default fallback
      
      DateTime dateTime = DateTime.parse(isoDate);
      
      const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      const months = ['January', 'February', 'March', 'April', 'May', 'June', 
                     'July', 'August', 'September', 'October', 'November', 'December'];
      
      String weekday = weekdays[dateTime.weekday - 1];
      String month = months[dateTime.month - 1];
      String day = '${dateTime.day}${_getOrdinalSuffix(dateTime.day)}';
      String year = '${dateTime.year}';
      
      return '$weekday $month $day, $year';
    } catch (e) {
      debugPrint('LocalScheduleService: Error formatting date: $e');
      return 'Thursday August 7TH, 2025'; // Default fallback
    }
  }

  /// Convert ISO date to time format: "7:00 PM"
  String _formatTimeForApp(String isoDate) {
    try {
      if (isoDate.isEmpty) return '7:00 PM'; // Default fallback
      
      DateTime dateTime = DateTime.parse(isoDate).toLocal();
      String period = dateTime.hour >= 12 ? 'PM' : 'AM';
      int hour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
      hour = hour == 0 ? 12 : hour;
      String minute = dateTime.minute.toString().padLeft(2, '0');
      
      return '$hour:$minute $period';
    } catch (e) {
      debugPrint('LocalScheduleService: Error formatting time: $e');
      return '7:00 PM'; // Default fallback
    }
  }

  /// Get ordinal suffix for a number (1st, 2nd, 3rd, etc)
  String _getOrdinalSuffix(int number) {
    if (number >= 11 && number <= 13) {
      return 'TH';
    }
    switch (number % 10) {
      case 1: return 'ST';
      case 2: return 'ND';
      case 3: return 'RD';
      default: return 'TH';
    }
  }
} 