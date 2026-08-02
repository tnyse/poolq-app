import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Fetches 2026 NFL schedule via ESPN scoreboard (by date).
/// Schedule endpoint may 404 before ESPN publishes full season pages.
void main() async {
  print('Fetching 2026 NFL Schedule via scoreboard dates...');
  try {
    await fetch2026Schedule();
    print('Successfully fetched and saved 2026 NFL schedule!');
  } catch (e) {
    print('Error fetching schedule: $e');
    exit(1);
  }
}

Future<void> fetch2026Schedule() async {
  const baseUrl =
      'https://site.api.espn.com/apis/site/v2/sports/football/nfl/scoreboard';

  final headers = {
    'Accept': 'application/json',
    'User-Agent': 'PoolQ-App/1.0',
  };

  // Hall of Fame + PRE1–PRE3 date windows (2026)
  final weekRanges = <String, List<DateTime>>{
    'PRE0': _dates(DateTime(2026, 8, 6), DateTime(2026, 8, 6)), // HoF
    'PRE1': _dates(DateTime(2026, 8, 13), DateTime(2026, 8, 16)),
    'PRE2': _dates(DateTime(2026, 8, 20), DateTime(2026, 8, 23)),
    'PRE3': _dates(DateTime(2026, 8, 27), DateTime(2026, 8, 29)),
  };

  // REG1–REG3 early windows (expand later as needed)
  weekRanges.addAll({
    'REG1': _dates(DateTime(2026, 9, 10), DateTime(2026, 9, 15)),
    'REG2': _dates(DateTime(2026, 9, 17), DateTime(2026, 9, 22)),
    'REG3': _dates(DateTime(2026, 9, 24), DateTime(2026, 9, 29)),
  });

  final allGames = <Map<String, dynamic>>[];
  final seenIds = <String>{};

  for (final entry in weekRanges.entries) {
    final weekName = entry.key;
    final mode = weekName.startsWith('PRE') ? 'PRE' : 'REG';
    final weekNumber =
        int.tryParse(weekName.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1;
    print('Fetching $weekName...');

    for (final day in entry.value) {
      final dateStr =
          '${day.year}${day.month.toString().padLeft(2, '0')}${day.day.toString().padLeft(2, '0')}';
      try {
        final url = '$baseUrl?dates=$dateStr&limit=100';
        final response = await http.get(Uri.parse(url), headers: headers);
        if (response.statusCode != 200) {
          print('  $dateStr -> HTTP ${response.statusCode}');
          continue;
        }
        final data = json.decode(response.body) as Map<String, dynamic>;
        final events = data['events'] as List? ?? [];
        for (final event in events) {
          final game = parseScoreboardEvent(
            Map<String, dynamic>.from(event as Map),
            mode,
            weekNumber,
            weekName,
          );
          if (game == null) continue;
          final id = game['id']?.toString() ?? '';
          if (id.isNotEmpty && seenIds.contains(id)) continue;
          if (id.isNotEmpty) seenIds.add(id);
          allGames.add(game);
        }
        await Future.delayed(const Duration(milliseconds: 250));
      } catch (e) {
        print('  Error on $dateStr: $e');
      }
    }
    final count = allGames.where((g) => g['week'] == weekName).length;
    print('  $weekName: $count games');
  }

  print('\nTotal games fetched: ${allGames.length}');
  await saveScheduleToFile(allGames);
}

List<DateTime> _dates(DateTime start, DateTime end) {
  final days = <DateTime>[];
  var cursor = DateTime(start.year, start.month, start.day);
  final last = DateTime(end.year, end.month, end.day);
  while (!cursor.isAfter(last)) {
    days.add(cursor);
    cursor = cursor.add(const Duration(days: 1));
  }
  return days;
}

Map<String, dynamic>? parseScoreboardEvent(
  Map<String, dynamic> event,
  String mode,
  int weekNumber,
  String weekName,
) {
  try {
    final competitions = event['competitions'] as List?;
    if (competitions == null || competitions.isEmpty) return null;
    final competition = competitions[0] as Map<String, dynamic>;
    final competitors = competition['competitors'] as List?;
    if (competitors == null || competitors.length != 2) return null;

    final homeTeam = competitors.firstWhere((c) => c['homeAway'] == 'home');
    final awayTeam = competitors.firstWhere((c) => c['homeAway'] == 'away');
    final homeTeamInfo = homeTeam['team'] as Map<String, dynamic>;
    final awayTeamInfo = awayTeam['team'] as Map<String, dynamic>;

    final homeAbbr = mapTeamAbbreviation(homeTeamInfo['abbreviation']?.toString() ?? '');
    final awayAbbr = mapTeamAbbreviation(awayTeamInfo['abbreviation']?.toString() ?? '');
    final statusType = competition['status']?['type'] as Map<String, dynamic>?;

    return {
      'id': event['id'],
      'date': event['date'],
      'name': event['name'],
      'shortName': event['shortName'],
      'week': weekName,
      'mode': mode,
      'weekNumber': weekNumber,
      'year': 2026,
      'homeTeam': {
        'id': homeTeamInfo['id'],
        'name': homeTeamInfo['displayName'],
        'abbreviation': homeAbbr,
        'logo': 'assets/images/teams/$homeAbbr.png',
        'color': homeTeamInfo['color'] ?? '',
      },
      'awayTeam': {
        'id': awayTeamInfo['id'],
        'name': awayTeamInfo['displayName'],
        'abbreviation': awayAbbr,
        'logo': 'assets/images/teams/$awayAbbr.png',
        'color': awayTeamInfo['color'] ?? '',
      },
      'homeScore': homeTeam['score'],
      'awayScore': awayTeam['score'],
      'status': statusType?['name'] ?? '',
      'statusDetail': statusType?['detail'] ?? '',
      'completed': statusType?['completed'] ?? false,
      'venue': competition['venue']?['fullName'] ?? '',
      'broadcast': (competition['broadcasts'] is List &&
              (competition['broadcasts'] as List).isNotEmpty)
          ? ((competition['broadcasts'] as List).first['names'] as List?)
              ?.join(', ')
          : '',
    };
  } catch (e) {
    print('Error parsing event: $e');
    return null;
  }
}

String mapTeamAbbreviation(String espnAbbr) {
  const mapping = {
    'WSH': 'WAS',
    'WAS': 'WAS',
  };
  return mapping[espnAbbr] ?? espnAbbr;
}

Future<void> saveScheduleToFile(List<Map<String, dynamic>> games) async {
  final schedule = <String, List<Map<String, dynamic>>>{};
  for (final game in games) {
    final week = game['week'] as String;
    schedule.putIfAbsent(week, () => []).add(game);
  }

  final fullSchedule = {
    'season': 2026,
    'lastUpdated': DateTime.now().toIso8601String(),
    'totalGames': games.length,
    'currentWeek': 'PRE1',
    'weeks': schedule,
    'allGames': games,
  };

  final file = File('assets/data/nfl_schedule_2026.json');
  await file.parent.create(recursive: true);
  await file.writeAsString(
    const JsonEncoder.withIndent('  ').convert(fullSchedule),
  );

  print('Saved to: ${file.path}');
  for (final key in schedule.keys.toList()..sort()) {
    print('  $key: ${schedule[key]!.length} games');
  }
}
