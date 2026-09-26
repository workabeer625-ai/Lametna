/// جولة لعب. `secret_data` لا يصل للعميل أبدًا (محجوب بصلاحيات الأعمدة في Postgres).
class GameRound {
  const GameRound({
    required this.id,
    required this.sessionId,
    required this.index,
    required this.phase,
    required this.endsAt,
    this.prompt = const <String, dynamic>{},
    this.startsAt,
    this.resolvedAt,
    this.result,
  });

  final String id;
  final String sessionId;
  final int index;
  final String phase;
  final Map<String, dynamic> prompt;
  final DateTime? startsAt;
  final DateTime endsAt;
  final DateTime? resolvedAt;
  final Map<String, dynamic>? result;

  bool get isResolved => resolvedAt != null;
  String get stage => (prompt['stage'] ?? 'answer').toString();

  /// جماد حيوان نبات
  String? get letter => prompt['letter'] as String?;
  List<String> get categories => ((prompt['categories'] ?? const <dynamic>[]) as List<dynamic>)
      .map((dynamic e) => e.toString())
      .toList();

  /// الأسئلة
  String? get questionBody => prompt['body'] as String?;
  List<String> get choices => ((prompt['choices'] ?? const <dynamic>[]) as List<dynamic>)
      .map((dynamic e) => e.toString())
      .toList();
  List<String> get hints => ((prompt['hints'] ?? const <dynamic>[]) as List<dynamic>)
      .map((dynamic e) => e.toString())
      .toList();

  /// الكذاب / القصة الجماعية أثناء التصويت
  List<Map<String, dynamic>> get ballot {
    final dynamic raw = prompt['descriptions'] ?? prompt['lines'];
    if (raw is! List) return const <Map<String, dynamic>>[];
    return raw
        .map((dynamic e) => Map<String, dynamic>.from(e as Map<dynamic, dynamic>))
        .toList();
  }

  bool get isMafiaNight => phase == 'night';
  bool get isVoting => phase == 'voting' || stage == 'vote';

  factory GameRound.fromMap(Map<String, dynamic> map) => GameRound(
        id: map['id'] as String,
        sessionId: (map['session_id'] ?? '') as String,
        index: (map['round_index'] ?? 0) as int,
        phase: (map['phase'] ?? 'pending') as String,
        prompt: Map<String, dynamic>.from(
            (map['prompt'] ?? const <String, dynamic>{}) as Map<dynamic, dynamic>),
        startsAt: map['starts_at'] == null ? null : DateTime.parse(map['starts_at'] as String),
        endsAt: DateTime.parse(map['ends_at'] as String),
        resolvedAt:
            map['resolved_at'] == null ? null : DateTime.parse(map['resolved_at'] as String),
        result: map['result'] == null
            ? null
            : Map<String, dynamic>.from(map['result'] as Map<dynamic, dynamic>),
      );
}
