import 'dart:convert';
import 'dart:io';

// Script to create the 2025 NFL schedule using the official preseason schedule
void main() async {
  print('🏈 Creating 2025 NFL Schedule...');
  
  try {
    await create2025Schedule();
    print('✅ Successfully created 2025 NFL schedule!');
  } catch (e) {
    print('❌ Error creating schedule: $e');
    exit(1);
  }
}

Future<void> create2025Schedule() async {
  List<Map<String, dynamic>> allGames = [];
  
  // Create preseason games (based on official 2025 schedule)
  print('📅 Creating preseason schedule...');
  
  // PRE Week 1 (August 7-10, 2025)
  var pre1Games = [
    // August 7
    {'awayTeam': 'IND', 'homeTeam': 'BAL', 'date': '2025-08-07T23:00:00Z'},
    {'awayTeam': 'CIN', 'homeTeam': 'PHI', 'date': '2025-08-07T23:30:00Z'},
    {'awayTeam': 'LV', 'homeTeam': 'SEA', 'date': '2025-08-08T02:00:00Z'},
    
    // August 8
    {'awayTeam': 'CLE', 'homeTeam': 'CAR', 'date': '2025-08-08T23:00:00Z'},
    {'awayTeam': 'DET', 'homeTeam': 'ATL', 'date': '2025-08-08T23:00:00Z'},
    {'awayTeam': 'WAS', 'homeTeam': 'NE', 'date': '2025-08-08T23:30:00Z'},
    
    // August 9
    {'awayTeam': 'NYG', 'homeTeam': 'BUF', 'date': '2025-08-09T17:00:00Z'},
    {'awayTeam': 'KC', 'homeTeam': 'ARI', 'date': '2025-08-10T00:00:00Z'},
    {'awayTeam': 'DAL', 'homeTeam': 'LAR', 'date': '2025-08-09T23:00:00Z'},
    {'awayTeam': 'HOU', 'homeTeam': 'MIN', 'date': '2025-08-09T20:00:00Z'},
    {'awayTeam': 'NYJ', 'homeTeam': 'GB', 'date': '2025-08-09T23:00:00Z'},
    {'awayTeam': 'PIT', 'homeTeam': 'JAX', 'date': '2025-08-09T23:00:00Z'},
    {'awayTeam': 'TEN', 'homeTeam': 'TB', 'date': '2025-08-09T23:30:00Z'},
    {'awayTeam': 'DEN', 'homeTeam': 'SF', 'date': '2025-08-10T00:30:00Z'},
    
    // August 10
    {'awayTeam': 'MIA', 'homeTeam': 'CHI', 'date': '2025-08-10T17:00:00Z'},
    {'awayTeam': 'NO', 'homeTeam': 'LAC', 'date': '2025-08-10T23:05:00Z'},
  ];
  
  // PRE Week 2 (August 15-17, 2025)
  var pre2Games = [
    {'awayTeam': 'TEN', 'homeTeam': 'ATL', 'date': '2025-08-15T23:00:00Z'},
    {'awayTeam': 'KC', 'homeTeam': 'SEA', 'date': '2025-08-16T02:00:00Z'},
    {'awayTeam': 'CAR', 'homeTeam': 'HOU', 'date': '2025-08-16T17:00:00Z'},
    {'awayTeam': 'GB', 'homeTeam': 'IND', 'date': '2025-08-16T17:00:00Z'},
    {'awayTeam': 'MIA', 'homeTeam': 'DET', 'date': '2025-08-16T17:00:00Z'},
    {'awayTeam': 'NE', 'homeTeam': 'MIN', 'date': '2025-08-16T17:00:00Z'},
    {'awayTeam': 'CLE', 'homeTeam': 'PHI', 'date': '2025-08-16T17:00:00Z'},
    {'awayTeam': 'BAL', 'homeTeam': 'DAL', 'date': '2025-08-16T23:00:00Z'},
    {'awayTeam': 'NYJ', 'homeTeam': 'NYG', 'date': '2025-08-16T23:00:00Z'},
    {'awayTeam': 'TB', 'homeTeam': 'PIT', 'date': '2025-08-16T23:00:00Z'},
    {'awayTeam': 'ARI', 'homeTeam': 'DEN', 'date': '2025-08-17T01:30:00Z'},
    {'awayTeam': 'SF', 'homeTeam': 'LV', 'date': '2025-08-16T20:00:00Z'},
    {'awayTeam': 'LAC', 'homeTeam': 'LAR', 'date': '2025-08-17T02:00:00Z'},
    {'awayTeam': 'JAX', 'homeTeam': 'NO', 'date': '2025-08-17T17:00:00Z'},
    {'awayTeam': 'BUF', 'homeTeam': 'CHI', 'date': '2025-08-17T00:00:00Z'},
    {'awayTeam': 'CIN', 'homeTeam': 'WAS', 'date': '2025-08-18T00:00:00Z'},
  ];
  
  // PRE Week 3 (August 21-23, 2025)  
  var pre3Games = [
    {'awayTeam': 'NE', 'homeTeam': 'NYG', 'date': '2025-08-21T00:00:00Z'},
    {'awayTeam': 'PIT', 'homeTeam': 'CAR', 'date': '2025-08-21T23:00:00Z'},
    {'awayTeam': 'ATL', 'homeTeam': 'DAL', 'date': '2025-08-22T00:00:00Z'},
    {'awayTeam': 'CHI', 'homeTeam': 'KC', 'date': '2025-08-22T00:20:00Z'},
    {'awayTeam': 'PHI', 'homeTeam': 'NYJ', 'date': '2025-08-22T23:30:00Z'},
    {'awayTeam': 'MIN', 'homeTeam': 'TEN', 'date': '2025-08-22T00:00:00Z'},
    {'awayTeam': 'WAS', 'homeTeam': 'BAL', 'date': '2025-08-23T16:00:00Z'},
    {'awayTeam': 'IND', 'homeTeam': 'CIN', 'date': '2025-08-23T17:00:00Z'},
    {'awayTeam': 'HOU', 'homeTeam': 'DET', 'date': '2025-08-23T17:00:00Z'},
    {'awayTeam': 'LAR', 'homeTeam': 'CLE', 'date': '2025-08-23T17:00:00Z'},
    {'awayTeam': 'DEN', 'homeTeam': 'NO', 'date': '2025-08-23T17:00:00Z'},
    {'awayTeam': 'SEA', 'homeTeam': 'GB', 'date': '2025-08-23T20:00:00Z'},
    {'awayTeam': 'BUF', 'homeTeam': 'TB', 'date': '2025-08-23T23:30:00Z'},
    {'awayTeam': 'MIA', 'homeTeam': 'JAX', 'date': '2025-08-23T23:00:00Z'},
    {'awayTeam': 'LAC', 'homeTeam': 'SF', 'date': '2025-08-24T00:30:00Z'},
    {'awayTeam': 'LV', 'homeTeam': 'ARI', 'date': '2025-08-24T02:00:00Z'},
  ];
  
  // Process preseason games
  allGames.addAll(processWeekGames(pre1Games, 'PRE', 1));
  allGames.addAll(processWeekGames(pre2Games, 'PRE', 2)); 
  allGames.addAll(processWeekGames(pre3Games, 'PRE', 3));
  
  print('  ✓ Created ${allGames.length} preseason games');
  
  // Create sample regular season games (just a few for demo)
  print('📅 Creating sample regular season games...');
  
  // REG Week 1 (September 4-8, 2025) - Sample games
  var reg1Games = [
    {'awayTeam': 'KC', 'homeTeam': 'BAL', 'date': '2025-09-04T20:20:00Z'},
    {'awayTeam': 'LAR', 'homeTeam': 'DET', 'date': '2025-09-07T17:00:00Z'},
    {'awayTeam': 'ATL', 'homeTeam': 'PIT', 'date': '2025-09-07T17:00:00Z'},
    {'awayTeam': 'ARI', 'homeTeam': 'BUF', 'date': '2025-09-07T17:00:00Z'},
    {'awayTeam': 'CIN', 'homeTeam': 'CLE', 'date': '2025-09-07T17:00:00Z'},
    {'awayTeam': 'HOU', 'homeTeam': 'IND', 'date': '2025-09-07T17:00:00Z'},
    {'awayTeam': 'JAX', 'homeTeam': 'MIA', 'date': '2025-09-07T17:00:00Z'},
    {'awayTeam': 'CHI', 'homeTeam': 'TEN', 'date': '2025-09-07T17:00:00Z'},
    {'awayTeam': 'NE', 'homeTeam': 'CIN', 'date': '2025-09-07T17:00:00Z'},
    {'awayTeam': 'CAR', 'homeTeam': 'NO', 'date': '2025-09-07T17:00:00Z'},
    {'awayTeam': 'MIN', 'homeTeam': 'NYG', 'date': '2025-09-07T17:00:00Z'},
    {'awayTeam': 'LV', 'homeTeam': 'LAC', 'date': '2025-09-07T20:05:00Z'},
    {'awayTeam': 'WAS', 'homeTeam': 'TB', 'date': '2025-09-07T20:25:00Z'},
    {'awayTeam': 'DAL', 'homeTeam': 'NYJ', 'date': '2025-09-08T20:15:00Z'},
    {'awayTeam': 'SF', 'homeTeam': 'SEA', 'date': '2025-09-08T20:20:00Z'},
    {'awayTeam': 'PHI', 'homeTeam': 'GB', 'date': '2025-09-08T20:25:00Z'},
  ];
  
  allGames.addAll(processWeekGames(reg1Games, 'REG', 1));
  
  print('  ✓ Created ${reg1Games.length} regular season week 1 games');
  print('📊 Total games created: ${allGames.length}');
  
  // Save to local file
  await saveScheduleToFile(allGames);
}

List<Map<String, dynamic>> processWeekGames(List<Map<String, dynamic>> gameData, String mode, int week) {
  List<Map<String, dynamic>> games = [];
  
  for (int i = 0; i < gameData.length; i++) {
    var gameInfo = gameData[i];
    
    var game = {
      'id': 'game-$mode$week-${i + 1}',
      'date': gameInfo['date'],
      'name': '${getTeamName(gameInfo['awayTeam'])} at ${getTeamName(gameInfo['homeTeam'])}',
      'shortName': '${gameInfo['awayTeam']} @ ${gameInfo['homeTeam']}',
      'week': '$mode$week',
      'mode': mode,
      'weekNumber': week,
      'year': 2025,
      'homeTeam': {
        'id': getTeamId(gameInfo['homeTeam']),
        'name': getTeamName(gameInfo['homeTeam']),
        'abbreviation': gameInfo['homeTeam'],
        'logo': 'assets/images/teams/${gameInfo['homeTeam']}.png',
        'color': getTeamColor(gameInfo['homeTeam']),
      },
      'awayTeam': {
        'id': getTeamId(gameInfo['awayTeam']),
        'name': getTeamName(gameInfo['awayTeam']),
        'abbreviation': gameInfo['awayTeam'],
        'logo': 'assets/images/teams/${gameInfo['awayTeam']}.png',
        'color': getTeamColor(gameInfo['awayTeam']),
      },
      'homeScore': null,
      'awayScore': null,
      'status': 'scheduled',
      'statusDetail': 'Scheduled',
      'completed': false,
      'venue': '${getTeamName(gameInfo['homeTeam'])} Stadium',
      'broadcast': '',
    };
    
    games.add(game);
  }
  
  return games;
}

String getTeamName(String abbr) {
  const teamNames = {
    'ARI': 'Arizona Cardinals', 'ATL': 'Atlanta Falcons', 'BAL': 'Baltimore Ravens', 'BUF': 'Buffalo Bills',
    'CAR': 'Carolina Panthers', 'CHI': 'Chicago Bears', 'CIN': 'Cincinnati Bengals', 'CLE': 'Cleveland Browns',
    'DAL': 'Dallas Cowboys', 'DEN': 'Denver Broncos', 'DET': 'Detroit Lions', 'GB': 'Green Bay Packers',
    'HOU': 'Houston Texans', 'IND': 'Indianapolis Colts', 'JAX': 'Jacksonville Jaguars', 'KC': 'Kansas City Chiefs',
    'LV': 'Las Vegas Raiders', 'LAC': 'Los Angeles Chargers', 'LAR': 'Los Angeles Rams', 'MIA': 'Miami Dolphins',
    'MIN': 'Minnesota Vikings', 'NE': 'New England Patriots', 'NO': 'New Orleans Saints', 'NYG': 'New York Giants',
    'NYJ': 'New York Jets', 'PHI': 'Philadelphia Eagles', 'PIT': 'Pittsburgh Steelers', 'SF': 'San Francisco 49ers',
    'SEA': 'Seattle Seahawks', 'TB': 'Tampa Bay Buccaneers', 'TEN': 'Tennessee Titans', 'WAS': 'Washington Commanders'
  };
  return teamNames[abbr] ?? abbr;
}

String getTeamId(String abbr) {
  // Simple team ID mapping
  const teamIds = {
    'ARI': '22', 'ATL': '1', 'BAL': '33', 'BUF': '2', 'CAR': '29', 'CHI': '3', 'CIN': '4', 'CLE': '5',
    'DAL': '6', 'DEN': '7', 'DET': '8', 'GB': '9', 'HOU': '34', 'IND': '11', 'JAX': '30', 'KC': '12',
    'LV': '13', 'LAC': '24', 'LAR': '14', 'MIA': '15', 'MIN': '16', 'NE': '17', 'NO': '18', 'NYG': '19',
    'NYJ': '20', 'PHI': '21', 'PIT': '23', 'SF': '25', 'SEA': '26', 'TB': '27', 'TEN': '10', 'WAS': '28'
  };
  return teamIds[abbr] ?? '0';
}

String getTeamColor(String abbr) {
  const teamColors = {
    'ARI': '#97233F', 'ATL': '#A71930', 'BAL': '#241773', 'BUF': '#00338D', 'CAR': '#0085CA', 'CHI': '#0B162A',
    'CIN': '#FB4F14', 'CLE': '#311D00', 'DAL': '#041E42', 'DEN': '#FB4F14', 'DET': '#0076B6', 'GB': '#203731',
    'HOU': '#03202F', 'IND': '#002C5F', 'JAX': '#006778', 'KC': '#E31837', 'LV': '#000000', 'LAC': '#0080C6',
    'LAR': '#003594', 'MIA': '#008E97', 'MIN': '#4F2683', 'NE': '#002244', 'NO': '#D3BC8D', 'NYG': '#0B2265',
    'NYJ': '#125740', 'PHI': '#004C54', 'PIT': '#FFB612', 'SF': '#AA0000', 'SEA': '#002244', 'TB': '#D50A0A',
    'TEN': '#0C2340', 'WAS': '#5A1414'
  };
  return teamColors[abbr] ?? '#000000';
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
  print('PRE Week 1:');
  var pre1Games = games.where((g) => g['week'] == 'PRE1').take(3);
  for (var game in pre1Games) {
    print('  ${game['awayTeam']['abbreviation']} @ ${game['homeTeam']['abbreviation']} (${game['date']})');
  }
  
  if (regularSeasonGames > 0) {
    print('\nREG Week 1:');
    var reg1Games = games.where((g) => g['week'] == 'REG1').take(3);
    for (var game in reg1Games) {
      print('  ${game['awayTeam']['abbreviation']} @ ${game['homeTeam']['abbreviation']} (${game['date']})');
    }
  }
}