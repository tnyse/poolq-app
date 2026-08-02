import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:poolqapp/constants/season_config.dart';

/// Reads `config/appConfig` once at startup and caches values.
class AppConfigService {
  static final AppConfigService _instance = AppConfigService._internal();
  factory AppConfigService() => _instance;
  AppConfigService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _loaded = false;
  bool preseasonFree = true;
  int currentSeason = SeasonConfig.currentSeasonYear();
  String activeWeek = SeasonConfig.defaultWeekName();
  int paymentDeadlineHours = 48;

  bool get isLoaded => _loaded;

  Future<void> load() async {
    try {
      final doc =
          await _firestore.collection('config').doc('appConfig').get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        preseasonFree = data['preseasonFree'] as bool? ?? true;
        currentSeason =
            data['currentSeason'] as int? ?? SeasonConfig.currentSeasonYear();
        activeWeek = data['activeWeek'] as String? ??
            SeasonConfig.defaultWeekName();
        paymentDeadlineHours = data['paymentDeadlineHours'] as int? ?? 48;
        debugPrint(
          'AppConfigService: loaded preseasonFree=$preseasonFree '
          'season=$currentSeason week=$activeWeek',
        );
      } else {
        debugPrint('AppConfigService: no config doc, using safe defaults');
        _applyDefaults();
      }
    } catch (e) {
      debugPrint('AppConfigService: load failed ($e), using defaults');
      _applyDefaults();
    }
    _loaded = true;
  }

  void _applyDefaults() {
    preseasonFree = true;
    currentSeason = SeasonConfig.currentSeasonYear();
    activeWeek = SeasonConfig.defaultWeekName();
    paymentDeadlineHours = 48;
  }

  bool get isPreseasonFreeWeek =>
      preseasonFree && activeWeek.startsWith('PRE');
}
