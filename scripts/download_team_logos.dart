import 'dart:io';
import 'package:http/http.dart' as http;

final Map<String, String> teamLogos = {
  "ARI": "https://a.espncdn.com/i/teamlogos/nfl/500/ari.png",
  "ATL": "https://a.espncdn.com/i/teamlogos/nfl/500/atl.png",
  "BAL": "https://a.espncdn.com/i/teamlogos/nfl/500/bal.png",
  "BUF": "https://a.espncdn.com/i/teamlogos/nfl/500/buf.png",
  "CAR": "https://a.espncdn.com/i/teamlogos/nfl/500/car.png",
  "CHI": "https://a.espncdn.com/i/teamlogos/nfl/500/chi.png",
  "CIN": "https://a.espncdn.com/i/teamlogos/nfl/500/cin.png",
  "CLE": "https://a.espncdn.com/i/teamlogos/nfl/500/cle.png",
  "DAL": "https://a.espncdn.com/i/teamlogos/nfl/500/dal.png",
  "DEN": "https://a.espncdn.com/i/teamlogos/nfl/500/den.png",
  "DET": "https://a.espncdn.com/i/teamlogos/nfl/500/det.png",
  "GB": "https://a.espncdn.com/i/teamlogos/nfl/500/gb.png",
  "HOU": "https://a.espncdn.com/i/teamlogos/nfl/500/hou.png",
  "IND": "https://a.espncdn.com/i/teamlogos/nfl/500/ind.png",
  "JAX": "https://a.espncdn.com/i/teamlogos/nfl/500/jax.png",
  "KC": "https://a.espncdn.com/i/teamlogos/nfl/500/kc.png",
  "LV": "https://a.espncdn.com/i/teamlogos/nfl/500/lv.png",
  "LAC": "https://a.espncdn.com/i/teamlogos/nfl/500/lac.png",
  "LAR": "https://a.espncdn.com/i/teamlogos/nfl/500/lar.png",
  "MIA": "https://a.espncdn.com/i/teamlogos/nfl/500/mia.png",
  "MIN": "https://a.espncdn.com/i/teamlogos/nfl/500/min.png",
  "NE": "https://a.espncdn.com/i/teamlogos/nfl/500/ne.png",
  "NO": "https://a.espncdn.com/i/teamlogos/nfl/500/no.png",
  "NYG": "https://a.espncdn.com/i/teamlogos/nfl/500/nyg.png",
  "NYJ": "https://a.espncdn.com/i/teamlogos/nfl/500/nyj.png",
  "PHI": "https://a.espncdn.com/i/teamlogos/nfl/500/phi.png",
  "PIT": "https://a.espncdn.com/i/teamlogos/nfl/500/pit.png",
  "SF": "https://a.espncdn.com/i/teamlogos/nfl/500/sf.png",
  "SEA": "https://a.espncdn.com/i/teamlogos/nfl/500/sea.png",
  "TB": "https://a.espncdn.com/i/teamlogos/nfl/500/tb.png",
  "TEN": "https://a.espncdn.com/i/teamlogos/nfl/500/ten.png",
  "WAS": "https://a.espncdn.com/i/teamlogos/nfl/500/wsh.png",
};

Future<void> main() async {
  final dir = Directory('assets/images/teams');
  if (!await dir.exists()) {
    await dir.create(recursive: true);
    print('Created directory: ${dir.path}');
  }

  for (final entry in teamLogos.entries) {
    final abbr = entry.key;
    final url = entry.value;
    final file = File('${dir.path}/$abbr.png');
    print('Downloading $abbr logo...');
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        print('✅ Saved: ${file.path}');
      } else {
        print('❌ Failed to download $abbr: HTTP ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error downloading $abbr: $e');
    }
    await Future.delayed(Duration(milliseconds: 100));
  }
  print('\nAll downloads complete!');
} 