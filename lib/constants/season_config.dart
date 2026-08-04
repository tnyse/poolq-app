/// NFL season year and week defaults for schedule loading.
class SeasonConfig {
  /// NFL season year: March–December use current calendar year;
  /// Jan–Feb still belong to the prior NFL season year.
  static int currentSeasonYear([DateTime? now]) {
    final date = now ?? DateTime.now();
    return date.month >= 3 ? date.year : date.year - 1;
  }

  /// Safe default when appConfig / API are unavailable.
  /// Preseason testing launch defaults to PRE1.
  static String defaultWeekName([DateTime? now]) {
    final date = now ?? DateTime.now();
    final year = currentSeasonYear(date);
    // Before typical REG1 (early September), prefer preseason.
    if (date.year == year && date.month < 9) {
      return 'PRE1';
    }
    return 'REG1';
  }

  static String modeFromWeek(String weekName) {
    if (weekName.startsWith('PRE')) return 'PRE';
    if (weekName.startsWith('POST')) return 'POST';
    return 'REG';
  }

  static int seasonTypeFromWeek(String weekName) {
    if (weekName.startsWith('PRE')) return 1;
    if (weekName.startsWith('POST')) return 3;
    return 2;
  }

  /// Ordered pool weeks for 2026 entry routing.
  static const List<String> entryWeekSequence = [
    'PRE1',
    'PRE2',
    'PRE3',
    'REG1',
    'REG2',
    'REG3',
    'REG4',
    'REG5',
    'REG6',
    'REG7',
    'REG8',
    'REG9',
    'REG10',
    'REG11',
    'REG12',
    'REG13',
    'REG14',
    'REG15',
    'REG16',
    'REG17',
    'REG18',
  ];

  /// Next week after [weekName], or null if at end of sequence.
  static String? nextWeekName(String weekName) {
    final idx = entryWeekSequence.indexOf(weekName.toUpperCase());
    if (idx < 0 || idx >= entryWeekSequence.length - 1) return null;
    return entryWeekSequence[idx + 1];
  }

  static String assetPathForYear(int year) =>
      'assets/data/nfl_schedule_$year.json';
}
