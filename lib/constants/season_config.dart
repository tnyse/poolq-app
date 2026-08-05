/// NFL season year and week defaults for schedule loading.
class SeasonConfig {
  /// NFL season year: March–December use current calendar year;
  /// Jan–Feb still belong to the prior NFL season year.
  static int currentSeasonYear([DateTime? now]) {
    final date = now ?? DateTime.now();
    return date.month >= 3 ? date.year : date.year - 1;
  }

  /// Safe default when appConfig / API are unavailable.
  /// Mock test week for system validation before live PRE1.
  static String defaultWeekName([DateTime? now]) {
    return 'MOCK1';
  }

  static String modeFromWeek(String weekName) {
    if (weekName.startsWith('MOCK')) return 'MOCK';
    if (weekName.startsWith('PRE')) return 'PRE';
    if (weekName.startsWith('POST')) return 'POST';
    return 'REG';
  }

  /// If [raw] is already MOCK1/PRE1/REG1/… return it; if it's just a number,
  /// prefix [mode] (or mode inferred from [fallbackWeek]).
  static String canonicalizeWeekName(
    String raw, {
    String? mode,
    String? fallbackWeek,
  }) {
    final s = raw.trim();
    if (s.startsWith('MOCK') ||
        s.startsWith('PRE') ||
        s.startsWith('REG') ||
        s.startsWith('POST')) {
      return s;
    }
    final m = mode ??
        (fallbackWeek != null ? modeFromWeek(fallbackWeek) : 'REG');
    return '$m$s';
  }

  /// Strip season prefix → "1" from "MOCK1" / "PRE1" / "REG12".
  static String weekNumberToken(String weekName) {
    return weekName.replaceFirst(RegExp(r'^(MOCK|PRE|REG|POST)'), '');
  }

  static int seasonTypeFromWeek(String weekName) {
    if (weekName.startsWith('MOCK')) return 0;
    if (weekName.startsWith('PRE')) return 1;
    if (weekName.startsWith('POST')) return 3;
    return 2;
  }

  /// Ordered pool weeks — MOCK1 first for scoring/admin dry-run.
  static const List<String> entryWeekSequence = [
    'MOCK1',
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

  /// Weeks shown in admin score / winners / entries dropdowns.
  static const List<String> adminWeekChoices = [
    'MOCK1',
    'PRE0',
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

  static String adminWeekLabel(String weekName) {
    if (weekName == 'MOCK1') return 'Mock Test Wk';
    if (weekName == 'PRE0') return 'HoF';
    if (weekName.startsWith('PRE')) {
      return 'Pre Wk ${weekName.replaceAll('PRE', '')}';
    }
    if (weekName.startsWith('REG')) {
      return 'Week ${weekName.replaceAll('REG', '')}';
    }
    return weekName;
  }

  /// Next week after [weekName], or null if at end of sequence.
  static String? nextWeekName(String weekName) {
    final idx = entryWeekSequence.indexOf(weekName.toUpperCase());
    if (idx < 0 || idx >= entryWeekSequence.length - 1) return null;
    return entryWeekSequence[idx + 1];
  }

  /// Previous week before [weekName], or null if at start of sequence.
  static String? previousWeekName(String weekName) {
    final idx = entryWeekSequence.indexOf(weekName.toUpperCase());
    if (idx <= 0) return null;
    return entryWeekSequence[idx - 1];
  }

  static String assetPathForYear(int year) =>
      'assets/data/nfl_schedule_$year.json';
}
