extension DurationX on Duration {
  /// 01:23
  String get mmss {
    final int m = inMinutes;
    final int s = inSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String get compact => inMinutes > 0 ? mmss : '$inSeconds';
}
