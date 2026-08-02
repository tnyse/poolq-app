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

  static String assetPathForYear(int year) =>
      'assets/data/nfl_schedule_$year.json';
}
