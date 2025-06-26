import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class TeamImageVerifier {
  // Team data from NFLGameService
  static const Map<String, Map<String, String>> teams = {
    "ARI": {"fullname": "Arizona Cardinals", "picture": "https://a.espncdn.com/i/teamlogos/nfl/500/ari.png"},
    "ATL": {"fullname": "Atlanta Falcons", "picture": "https://a.espncdn.com/i/teamlogos/nfl/500/atl.png"},
    "BAL": {"fullname": "Baltimore Ravens", "picture": "https://a.espncdn.com/i/teamlogos/nfl/500/bal.png"},
    "BUF": {"fullname": "Buffalo Bills", "picture": "https://a.espncdn.com/i/teamlogos/nfl/500/buf.png"},
    "CAR": {"fullname": "Carolina Panthers", "picture": "https://a.espncdn.com/i/teamlogos/nfl/500/car.png"},
    "CHI": {"fullname": "Chicago Bears", "picture": "https://a.espncdn.com/i/teamlogos/nfl/500/chi.png"},
    "CIN": {"fullname": "Cincinnati Bengals", "picture": "https://a.espncdn.com/i/teamlogos/nfl/500/cin.png"},
    "CLE": {"fullname": "Cleveland Browns", "picture": "https://a.espncdn.com/i/teamlogos/nfl/500/cle.png"},
    "DAL": {"fullname": "Dallas Cowboys", "picture": "https://a.espncdn.com/i/teamlogos/nfl/500/dal.png"},
    "DEN": {"fullname": "Denver Broncos", "picture": "https://a.espncdn.com/i/teamlogos/nfl/500/den.png"},
    "DET": {"fullname": "Detroit Lions", "picture": "https://a.espncdn.com/i/teamlogos/nfl/500/det.png"},
    "GB": {"fullname": "Green Bay Packers", "picture": "https://a.espncdn.com/i/teamlogos/nfl/500/gb.png"},
    "HOU": {"fullname": "Houston Texans", "picture": "https://a.espncdn.com/i/teamlogos/nfl/500/hou.png"},
    "IND": {"fullname": "Indianapolis Colts", "picture": "https://a.espncdn.com/i/teamlogos/nfl/500/ind.png"},
    "JAX": {"fullname": "Jacksonville Jaguars", "picture": "https://a.espncdn.com/i/teamlogos/nfl/500/jax.png"},
    "KC": {"fullname": "Kansas City Chiefs", "picture": "https://a.espncdn.com/i/teamlogos/nfl/500/kc.png"},
    "LV": {"fullname": "Las Vegas Raiders", "picture": "https://a.espncdn.com/i/teamlogos/nfl/500/lv.png"},
    "LAC": {"fullname": "Los Angeles Chargers", "picture": "https://a.espncdn.com/i/teamlogos/nfl/500/lac.png"},
    "LAR": {"fullname": "Los Angeles Rams", "picture": "https://a.espncdn.com/i/teamlogos/nfl/500/lar.png"},
    "MIA": {"fullname": "Miami Dolphins", "picture": "https://a.espncdn.com/i/teamlogos/nfl/500/mia.png"},
    "MIN": {"fullname": "Minnesota Vikings", "picture": "https://a.espncdn.com/i/teamlogos/nfl/500/min.png"},
    "NE": {"fullname": "New England Patriots", "picture": "https://a.espncdn.com/i/teamlogos/nfl/500/ne.png"},
    "NO": {"fullname": "New Orleans Saints", "picture": "https://a.espncdn.com/i/teamlogos/nfl/500/no.png"},
    "NYG": {"fullname": "New York Giants", "picture": "https://a.espncdn.com/i/teamlogos/nfl/500/nyg.png"},
    "NYJ": {"fullname": "New York Jets", "picture": "https://a.espncdn.com/i/teamlogos/nfl/500/nyj.png"},
    "PHI": {"fullname": "Philadelphia Eagles", "picture": "https://a.espncdn.com/i/teamlogos/nfl/500/phi.png"},
    "PIT": {"fullname": "Pittsburgh Steelers", "picture": "https://a.espncdn.com/i/teamlogos/nfl/500/pit.png"},
    "SF": {"fullname": "San Francisco 49ers", "picture": "https://a.espncdn.com/i/teamlogos/nfl/500/sf.png"},
    "SEA": {"fullname": "Seattle Seahawks", "picture": "https://a.espncdn.com/i/teamlogos/nfl/500/sea.png"},
    "TB": {"fullname": "Tampa Bay Buccaneers", "picture": "https://a.espncdn.com/i/teamlogos/nfl/500/tb.png"},
    "TEN": {"fullname": "Tennessee Titans", "picture": "https://a.espncdn.com/i/teamlogos/nfl/500/ten.png"},
    "WAS": {"fullname": "Washington Commanders", "picture": "https://a.espncdn.com/i/teamlogos/nfl/500/wsh.png"},
  };

  static Future<bool> verifyImageUrl(String url, String teamName) async {
    try {
      final response = await http.get(Uri.parse(url)).timeout(Duration(seconds: 10));
      if (response.statusCode == 200) {
        print('✅ ${teamName.padRight(25)} - Image loads successfully');
        return true;
      } else {
        print('❌ ${teamName.padRight(25)} - HTTP ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ ${teamName.padRight(25)} - Error: ${e.toString().substring(0, 50)}...');
      return false;
    }
  }

  static Future<void> verifyAllTeamImages() async {
    print('NFL Team Image Verification');
    print('==========================');
    print('Verifying ${teams.length} team images...\n');

    int successCount = 0;
    int failureCount = 0;
    List<String> failedTeams = [];

    for (var entry in teams.entries) {
      final teamCode = entry.key;
      final teamData = entry.value;
      final teamName = teamData['fullname']!;
      final imageUrl = teamData['picture']!;

      final success = await verifyImageUrl(imageUrl, teamName);
      if (success) {
        successCount++;
      } else {
        failureCount++;
        failedTeams.add('$teamCode: $teamName');
      }

      // Small delay to avoid overwhelming the server
      await Future.delayed(Duration(milliseconds: 100));
    }

    print('\n==========================');
    print('VERIFICATION SUMMARY');
    print('==========================');
    print('Total teams: ${teams.length}');
    print('✅ Successful: $successCount');
    print('❌ Failed: $failureCount');

    if (failedTeams.isNotEmpty) {
      print('\nFailed teams:');
      for (var team in failedTeams) {
        print('  - $team');
      }
    }

    if (failureCount == 0) {
      print('\n🎉 All team images are loading successfully!');
    } else {
      print('\n⚠️  Some team images failed to load. Check the URLs above.');
    }
  }

  // Also test ESPN API team logos
  static Future<void> verifyESPNTeamLogos() async {
    print('\nESPN API Team Logo Verification');
    print('================================');
    
    try {
      final response = await http.get(
        Uri.parse('https://site.api.espn.com/apis/site/v2/sports/football/nfl/teams'),
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'PoolQ-Team-Verifier/1.0',
        },
      ).timeout(Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final teams = data['sports']?[0]?['leagues']?[0]?['teams'] ?? [];
        
        print('Found ${teams.length} teams in ESPN API');
        
        int logoCount = 0;
        for (var team in teams) {
          final teamData = team['team'];
          final teamName = teamData['name'] ?? 'Unknown';
          final logoUrl = teamData['logo'] ?? '';
          
          if (logoUrl.isNotEmpty) {
            logoCount++;
            print('✅ $teamName - Logo available');
          } else {
            print('❌ $teamName - No logo URL');
          }
        }
        
        print('\nESPN API Summary: $logoCount/${teams.length} teams have logos');
      } else {
        print('❌ ESPN API returned status code: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error accessing ESPN API: $e');
    }
  }
}

void main() async {
  await TeamImageVerifier.verifyAllTeamImages();
  await TeamImageVerifier.verifyESPNTeamLogos();
} 