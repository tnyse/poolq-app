import 'package:flutter/material.dart';
import 'package:poolqapp/constants/season_config.dart';
import 'package:poolqapp/services/week_results_service.dart';
import 'package:poolqapp/widgets/leaderboard/leaderboard_podium.dart';
import 'package:provider/provider.dart';
import 'package:poolqapp/Provider/homeProvider.dart';

/// Home-section podium for the previous (or latest declared) week.
class PreviousWeekTop3 extends StatefulWidget {
  const PreviousWeekTop3({super.key});

  @override
  State<PreviousWeekTop3> createState() => _PreviousWeekTop3State();
}

class _PreviousWeekTop3State extends State<PreviousWeekTop3> {
  final _service = WeekResultsService();
  List<Map<String, dynamic>> _top3 = [];
  Set<String> _champs = {};
  String? _weekLabel;
  int? _gamesPlayed;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    final current = dataProvider.game?['name']?.toString() ??
        SeasonConfig.defaultWeekName();
    final previous = SeasonConfig.previousWeekName(current);

    Map<String, dynamic>? result;
    if (previous != null) {
      result = await _service.getWeekResult(previous);
    }
    result ??= await _service.getLatestDeclaredResult();

    List<Map<String, dynamic>> top3 = [];
    String? label;
    int? games;
    if (result != null) {
      label = (result['weekName'] ?? previous ?? '').toString();
      games = (result['gamesPlayed'] as num?)?.toInt();
      if (result['top3'] is List) {
        top3 = List<Map<String, dynamic>>.from(
          (result['top3'] as List)
              .map((e) => Map<String, dynamic>.from(e as Map)),
        );
      }
    } else if (previous != null) {
      label = previous;
      top3 = await _service.getTop3ForWeek(previous);
    }

    final champs = await _service.getReigningChampionUids();
    if (!mounted) return;
    setState(() {
      _top3 = top3;
      _champs = champs;
      _weekLabel = label;
      _gamesPlayed = games;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    if (_top3.isEmpty) return const SizedBox.shrink();

    return LeaderboardPodium(
      top3: _top3,
      reigningChampionUids: _champs,
      gamesPlayed: _gamesPlayed,
      subtitle: _weekLabel == null || _weekLabel!.isEmpty
          ? 'LAST WEEK TOP 3'
          : '$_weekLabel TOP 3',
    );
  }
}
