import 'package:flutter/foundation.dart';
import 'package:poolqapp/services/nfl_schedule_service.dart';

class NFLGameService {
  static final NFLGameService _instance = NFLGameService._internal();
  
  factory NFLGameService() {
    return _instance;
  }
  
  NFLGameService._internal();
  
  // Loads real NFL games for a given week from the local schedule file
  Future<List<Map<String, dynamic>>> getGamesForWeek(String weekName, {int year = 2025}) async {
    final scheduleService = NFLScheduleService();
    return await scheduleService.getScheduleForWeekWithLocalFallback(weekName, year: year);
  }
  
  // Loads winners for a given week from the real schedule (where status is 'completed' and score > score2)
  Future<List<String>> getWinnersForWeek(String weekName, {int year = 2025}) async {
    final games = await getGamesForWeek(weekName, year: year);
    List<String> winners = [];
    for (final game in games) {
      if (game['status'] == 'completed') {
        final score1 = int.tryParse(game['score'] ?? '0') ?? 0;
        final score2 = int.tryParse(game['score2'] ?? '0') ?? 0;
        if (score1 > score2) {
          winners.add(game['abbreviation']);
        } else if (score2 > score1) {
          winners.add(game['abbreviation2']);
        }
      }
    }
    return winners;
  }
} 