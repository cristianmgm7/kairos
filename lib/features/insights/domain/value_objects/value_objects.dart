enum EmotionType {
  joy(value: 0),
  calm(value: 1),
  neutral(value: 2),
  sadness(value: 3),
  stress(value: 4),
  anger(value: 5),
  fear(value: 6),
  excitement(value: 7);

  const EmotionType({required this.value});

  final int value;

  static EmotionType fromInt(int code) {
    return EmotionType.values.firstWhere(
      (e) => e.value == code,
      orElse: () => EmotionType.neutral,
    );
  }
}

enum InsightType {
  thread(value: 0),
  global(value: 1),
  dailyGlobal(value: 2);

  const InsightType({required this.value});

  final int value;

  static InsightType fromInt(int code) {
    return InsightType.values.firstWhere(
      (e) => e.value == code,
      orElse: () => InsightType.thread,
    );
  }
}

enum InsightPeriod {
  oneDay,    // Last 24 hours
  threeDays, // Last 3 days
  oneWeek,   // Last 7 days
  oneMonth,  // Last 30 days
  daily,     // Single day snapshot (for aggregation)
}
