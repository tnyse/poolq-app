import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

// Script to fetch the complete 2025 NFL schedule from ESPN API
void main() async {
  print('🏈 Fetching 2025 NFL Schedule...');
  
  try {
    await fetch2025Schedule();
    print('✅ Successfully fetched and saved 2025 NFL schedule!');
  } catch (e) {
    print('❌ Error fetching schedule: $e');
    exit(1);
  }
}

Future<void> fetch2025Schedule() async {
  const baseUrl = 'https://site.api.espn.com/apis/site/v2/sports/football/nfl';
  
  Map<String, String> headers = {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    'User-Agent': 'PoolQ-App/1.0',
  };

  List<Map<String, dynamic>> allGames = [];
  
  // Fetch preseason (weeks 1-3)
  print('📅 Fetching preseason schedule...');
  for (int week = 1; week <= 3; week++) {
    print('  - Fetching preseason week $week');
    try {
      var url = '$baseUrl/schedule?season=2025&seasontype=1&week=$week';
      var response = await http.get(Uri.parse(url), headers: headers);
      
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        var games = parseESPNSchedule(data, 'PRE', week);
        allGames.addAll(games);
        print('    ✓ Found ${games.length} games');
        
        // Add delay to be respectful to the API
        await Future.delayed(Duration(milliseconds: 500));
      } else {
        print('    ⚠️ Failed to fetch preseason week $week: ${response.statusCode}');
      }
    } catch (e) {
      print('    ❌ Error fetching preseason week $week: $e');
    }
  }
  
  // Fetch regular season (weeks 1-18)
  print('📅 Fetching regular season schedule...');
  for (int week = 1; week <= 18; week++) {
    print('  - Fetching regular season week $week');
    try {
      var url = '$baseUrl/schedule?season=2025&seasontype=2&week=$week';
      var response = await http.get(Uri.parse(url), headers: headers);
      
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        var games = parseESPNSchedule(data, 'REG', week);
        allGames.addAll(games);
        print('    ✓ Found ${games.length} games');
        
        // Add delay to be respectful to the API
        await Future.delayed(Duration(milliseconds: 500));
      } else {
        print('    ⚠️ Failed to fetch regular season week $week: ${response.statusCode}');
      }
    } catch (e) {
      print('    ❌ Error fetching regular season week $week: $e');
    }
  }
  
  print('\n📊 Total games fetched: ${allGames.length}');
  
  // Save to local file
  await saveScheduleToFile(allGames);
}

List<Map<String, dynamic>> parseESPNSchedule(Map<String, dynamic> data, String mode, int week) {
  List<Map<String, dynamic>> games = [];
  
  if (data['events'] != null) {
    for (var event in data['events']) {
      try {
        var game = parseESPNGame(event, mode, week);
        if (game != null) {
          games.add(game);
        }
      } catch (e) {
        print('    ⚠️ Error parsing game: $e');
      }
    }
  }
  
  return games;
}

Map<String, dynamic>? parseESPNGame(Map<String, dynamic> event, String mode, int week) {
  try {
    var competitions = event['competitions'];
    if (competitions == null || competitions.isEmpty) return null;
    
    var competition = competitions[0];
    var competitors = competition['competitors'];
    if (competitors == null || competitors.length != 2) return null;
    
    // Find home and away teams
    var homeTeam = competitors.firstWhere((c) => c['homeAway'] == 'home');
    var awayTeam = competitors.firstWhere((c) => c['homeAway'] == 'away');
    
    var homeTeamInfo = homeTeam['team'];
    var awayTeamInfo = awayTeam['team'];
    
    // Map team abbreviations
    String homeAbbr = mapTeamAbbreviation(homeTeamInfo['abbreviation']);
    String awayAbbr = mapTeamAbbreviation(awayTeamInfo['abbreviation']);
    
    return {
      'id': event['id'],
      'date': event['date'],
      'name': event['name'],
      'shortName': event['shortName'],
      'week': '$mode$week',
      'mode': mode,
      'weekNumber': week,
      'year': 2025,
      'homeTeam': {
        'id': homeTeamInfo['id'],
        'name': homeTeamInfo['displayName'],
        'abbreviation': homeAbbr,
        'logo': homeTeamInfo['logo'] ?? '',
        'color': homeTeamInfo['color'] ?? '',
      },
      'awayTeam': {
        'id': awayTeamInfo['id'],
        'name': awayTeamInfo['displayName'], 
        'abbreviation': awayAbbr,
        'logo': awayTeamInfo['logo'] ?? '',
        'color': awayTeamInfo['color'] ?? '',
      },
      'homeScore': homeTeam['score']?['value'],
      'awayScore': awayTeam['score']?['value'],
      'status': competition['status']['type']['name'],
      'statusDetail': competition['status']['type']['detail'],
      'completed': competition['status']['type']['completed'] ?? false,
      'venue': competition['venue']?['fullName'] ?? '',
      'broadcast': competition['broadcasts']?.isNotEmpty == true ? 
                   competition['broadcasts'][0]['names']?.join(', ') : '',
    };
  } catch (e) {
    print('Error parsing ESPN game: $e');
    return null;
  }
}

String mapTeamAbbreviation(String espnAbbr) {
  // Map ESPN abbreviations to your app's format
  const mapping = {
    'ARI': 'ARI', 'ATL': 'ATL', 'BAL': 'BAL', 'BUF': 'BUF',
    'CAR': 'CAR', 'CHI': 'CHI', 'CIN': 'CIN', 'CLE': 'CLE',
    'DAL': 'DAL', 'DEN': 'DEN', 'DET': 'DET', 'GB': 'GB',
    'HOU': 'HOU', 'IND': 'IND', 'JAX': 'JAX', 'KC': 'KC',
    'LV': 'LV', 'LAC': 'LAC', 'LAR': 'LAR', 'MIA': 'MIA',
    'MIN': 'MIN', 'NE': 'NE', 'NO': 'NO', 'NYG': 'NYG',
    'NYJ': 'NYJ', 'PHI': 'PHI', 'PIT': 'PIT', 'SF': 'SF',
    'SEA': 'SEA', 'TB': 'TB', 'TEN': 'TEN', 'WAS': 'WAS'
  };
  
  return mapping[espnAbbr] ?? espnAbbr;
}

Future<void> saveScheduleToFile(List<Map<String, dynamic>> games) async {
  // Organize games by week
  Map<String, List<Map<String, dynamic>>> schedule = {};
  
  for (var game in games) {
    String week = game['week'];
    if (!schedule.containsKey(week)) {
      schedule[week] = [];
    }
    schedule[week]!.add(game);
  }
  
  // Create the final schedule structure
  Map<String, dynamic> fullSchedule = {
    'season': 2025,
    'lastUpdated': DateTime.now().toIso8601String(),
    'totalGames': games.length,
    'weeks': schedule,
    'allGames': games,
  };
  
  // Save to assets/data/nfl_schedule_2025.json
  final file = File('assets/data/nfl_schedule_2025.json');
  await file.parent.create(recursive: true);
  await file.writeAsString(json.encode(fullSchedule));
  
  print('💾 Schedule saved to: ${file.path}');
  print('📈 Schedule summary:');
  
  // Print summary
  var preseasonGames = games.where((g) => g['mode'] == 'PRE').length;
  var regularSeasonGames = games.where((g) => g['mode'] == 'REG').length;
  
  print('  - Preseason games: $preseasonGames');
  print('  - Regular season games: $regularSeasonGames');
  print('  - Total weeks: ${schedule.keys.length}');
  
  // Show first few games as example
  print('\n🎮 Sample games:');
  for (int i = 0; i < (games.length < 5 ? games.length : 5); i++) {
    var game = games[i];
    print('  ${game['week']}: ${game['awayTeam']['abbreviation']} @ ${game['homeTeam']['abbreviation']} (${game['date']})');
  }
}