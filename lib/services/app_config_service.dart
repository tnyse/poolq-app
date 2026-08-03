import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:poolqapp/constants/season_config.dart';

/// Reads `config/appConfig` once at startup and caches values.
class AppConfigService {
  static final AppConfigService _instance = AppConfigService._internal();
  factory AppConfigService() => _instance;
  AppConfigService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String defaultZelle = 'poolq.payments@gmail.com';
  static const String defaultPayPal = 'poolq.payments@gmail.com';
  static const String defaultVenmo = 'https://venmo.com/u/PoolQPayments';
  static const String defaultCashApp = '\$PoolQPayments';
  static const String defaultPaymentMethod = 'zelle';

  bool _loaded = false;
  bool preseasonFree = true;
  int currentSeason = SeasonConfig.currentSeasonYear();
  String activeWeek = SeasonConfig.defaultWeekName();
  int paymentDeadlineHours = 48;

  /// Default method shown first in payment UI: zelle | venmo | paypal | cashapp
  String defaultPaymentMethodKey = defaultPaymentMethod;
  String zelleDestination = defaultZelle;
  String paypalDestination = defaultPayPal;
  String venmoDestination = defaultVenmo;
  String cashAppDestination = defaultCashApp;

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
        _loadPaymentDestinations(data);
        debugPrint(
          'AppConfigService: loaded preseasonFree=$preseasonFree '
          'season=$currentSeason week=$activeWeek '
          'defaultPay=$defaultPaymentMethodKey',
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

  void _loadPaymentDestinations(Map<String, dynamic> data) {
    final handles = data['paymentHandles'];
    if (handles is Map) {
      zelleDestination =
          handles['zelle']?.toString() ?? defaultZelle;
      paypalDestination =
          handles['paypal']?.toString() ?? defaultPayPal;
      venmoDestination =
          handles['venmo']?.toString() ?? defaultVenmo;
      cashAppDestination =
          handles['cashapp']?.toString() ?? defaultCashApp;
    } else {
      zelleDestination = data['zelleDestination']?.toString() ?? defaultZelle;
      paypalDestination =
          data['paypalDestination']?.toString() ?? defaultPayPal;
      venmoDestination = data['venmoDestination']?.toString() ?? defaultVenmo;
      cashAppDestination =
          data['cashAppDestination']?.toString() ?? defaultCashApp;
    }
    final key = data['defaultPaymentMethod']?.toString().toLowerCase();
    defaultPaymentMethodKey =
        (key != null && key.isNotEmpty) ? key : defaultPaymentMethod;
  }

  void _applyDefaults() {
    preseasonFree = true;
    currentSeason = SeasonConfig.currentSeasonYear();
    activeWeek = SeasonConfig.defaultWeekName();
    paymentDeadlineHours = 48;
    defaultPaymentMethodKey = defaultPaymentMethod;
    zelleDestination = defaultZelle;
    paypalDestination = defaultPayPal;
    venmoDestination = defaultVenmo;
    cashAppDestination = defaultCashApp;
  }

  bool get isPreseasonFreeWeek =>
      preseasonFree && activeWeek.startsWith('PRE');

  Map<String, String> get paymentHandles => {
        'zelle': zelleDestination,
        'paypal': paypalDestination,
        'venmo': venmoDestination,
        'cashapp': cashAppDestination,
      };

  /// Persist active week (admin). Updates local cache on success.
  Future<void> setActiveWeek(String weekName) async {
    await _firestore.collection('config').doc('appConfig').set({
      'activeWeek': weekName,
      'currentSeason': currentSeason,
      'preseasonFree': preseasonFree,
      'paymentDeadlineHours': paymentDeadlineHours,
    }, SetOptions(merge: true));
    activeWeek = weekName;
    debugPrint('AppConfigService: activeWeek set to $weekName');
  }

  /// Persist payment destinations + default method (admin / Firebase admin user).
  Future<void> setPaymentDestinations({
    required String zelle,
    required String paypal,
    required String venmo,
    required String cashApp,
    String defaultMethod = defaultPaymentMethod,
  }) async {
    final handles = {
      'zelle': zelle.trim(),
      'paypal': paypal.trim(),
      'venmo': venmo.trim(),
      'cashapp': cashApp.trim(),
    };
    await _firestore.collection('config').doc('appConfig').set({
      'paymentHandles': handles,
      'defaultPaymentMethod': defaultMethod.trim().toLowerCase(),
    }, SetOptions(merge: true));
    zelleDestination = handles['zelle']!;
    paypalDestination = handles['paypal']!;
    venmoDestination = handles['venmo']!;
    cashAppDestination = handles['cashapp']!;
    defaultPaymentMethodKey = defaultMethod.trim().toLowerCase();
    debugPrint(
      'AppConfigService: payment handles updated default=$defaultPaymentMethodKey',
    );
  }
}
