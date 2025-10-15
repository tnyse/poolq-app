import 'package:flutter/foundation.dart';

/// Service to simulate different time periods for testing with real NFL data
/// Allows testing leaderboards and scoring with completed weeks from 2025 season
class TimeSimulationService {
  static final TimeSimulationService _instance = TimeSimulationService._internal();
  factory TimeSimulationService() => _instance;
  TimeSimulationService._internal();

  // Simulated current date/week for testing
  DateTime? _simulatedDate;
  String? _simulatedWeek;
  bool _isSimulationEnabled = false;

  /// Enable time simulation for testing
  void enableSimulation() {
    _isSimulationEnabled = true;
    debugPrint('TimeSimulation: Simulation enabled');
  }

  /// Disable time simulation (use real current time)
  void disableSimulation() {
    _isSimulationEnabled = false;
    _simulatedDate = null;
    _simulatedWeek = null;
    debugPrint('TimeSimulation: Simulation disabled');
  }

  /// Set simulated date for testing
  void setSimulatedDate(DateTime date) {
    _simulatedDate = date;
    _isSimulationEnabled = true;
    debugPrint('TimeSimulation: Set simulated date to $date');
  }

  /// Set simulated week for testing (e.g., "REG1", "REG2")
  void setSimulatedWeek(String week) {
    _simulatedWeek = week;
    _isSimulationEnabled = true;
    debugPrint('TimeSimulation: Set simulated week to $week');
  }

  /// Get current date (real or simulated)
  DateTime getCurrentDate() {
    if (_isSimulationEnabled && _simulatedDate != null) {
      return _simulatedDate!;
    }
    return DateTime.now();
  }

  /// Get current week (real or simulated)
  String? getCurrentWeek() {
    if (_isSimulationEnabled && _simulatedWeek != null) {
      return _simulatedWeek!;
    }
    return null; // Let other services determine real current week
  }

  /// Check if simulation is active
  bool get isSimulationEnabled => _isSimulationEnabled;

  /// Simulate being in Week 1 of 2025 season (September 5-9, 2025)
  void simulateWeek1() {
    setSimulatedDate(DateTime(2025, 9, 9)); // After Week 1 games completed
    setSimulatedWeek('REG1');
    debugPrint('TimeSimulation: Simulating Week 1 (completed games)');
  }

  /// Simulate being in Week 2 of 2025 season (September 12-16, 2025)
  void simulateWeek2() {
    setSimulatedDate(DateTime(2025, 9, 16)); // After Week 2 games completed
    setSimulatedWeek('REG2');
    debugPrint('TimeSimulation: Simulating Week 2 (completed games)');
  }

  /// Simulate being before Week 1 starts (for pick submission testing)
  void simulatePreWeek1() {
    setSimulatedDate(DateTime(2025, 9, 4)); // Before Week 1 games start
    setSimulatedWeek('REG1');
    debugPrint('TimeSimulation: Simulating before Week 1 starts');
  }

  /// Simulate being before Week 2 starts (for pick submission testing)
  void simulatePreWeek2() {
    setSimulatedDate(DateTime(2025, 9, 11)); // Before Week 2 games start
    setSimulatedWeek('REG2');
    debugPrint('TimeSimulation: Simulating before Week 2 starts');
  }

  /// Get week info for simulated time
  Map<String, dynamic>? getSimulatedWeekInfo() {
    if (!_isSimulationEnabled || _simulatedWeek == null) {
      return null;
    }

    // Extract week number from week name (e.g., "REG1" -> 1)
    final weekMatch = RegExp(r'(\d+)').firstMatch(_simulatedWeek!);
    final weekNumber = weekMatch != null ? int.parse(weekMatch.group(1)!) : 1;

    return {
      'week': _simulatedWeek,
      'weekNumber': weekNumber,
      'year': 2025,
      'mode': _simulatedWeek!.startsWith('PRE') ? 'PRE' : 'REG',
      'seasonType': _simulatedWeek!.startsWith('PRE') ? 1 : 2, // 1=preseason, 2=regular
      'isSimulated': true,
      'simulatedDate': _simulatedDate?.toIso8601String(),
    };
  }

  /// Reset to specific test scenario
  void resetToTestScenario(String scenario) {
    switch (scenario) {
      case 'week1_completed':
        simulateWeek1();
        break;
      case 'week2_completed':
        simulateWeek2();
        break;
      case 'pre_week1':
        simulatePreWeek1();
        break;
      case 'pre_week2':
        simulatePreWeek2();
        break;
      default:
        disableSimulation();
    }
  }

  /// Get status for debugging
  Map<String, dynamic> getStatus() {
    return {
      'isEnabled': _isSimulationEnabled,
      'simulatedDate': _simulatedDate?.toIso8601String(),
      'simulatedWeek': _simulatedWeek,
      'currentEffectiveDate': getCurrentDate().toIso8601String(),
      'currentEffectiveWeek': getCurrentWeek(),
    };
  }
}

