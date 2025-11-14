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
  global(value: 1);

  const InsightType({required this.value});

  final int value;

  static InsightType fromInt(int code) {
    return InsightType.values.firstWhere(
      (e) => e.value == code,
      orElse: () => InsightType.thread,
    );
  }
}
