import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../providers/room_provider.dart';
import '../animal_plant_object/apo_view.dart';
import '../group_story/group_story_view.dart';
import '../liar/liar_view.dart';
import '../mafia/mafia_view.dart';
import '../shared/single_answer_view.dart';

/// واجهة تعريف اللعبة — نقطة التوسعة لإضافة ألعاب جديدة مستقبلًا.
///
/// كل ما تحتاجه لعبة جديدة:
///   1. صف يرث [GameDefinition] ويبني واجهة الجولة.
///   2. سطر في [GameRegistry.definitions].
///   3. منطق التوليد والتقييم في `_begin_round` و`resolve_round` في Postgres.
///
/// المنطق الحساس (المحتوى السري، النقاط، الأدوار، الفوز) يبقى دائمًا على
/// الخادم؛ هذه الطبقة عرض وإدخال فقط.
abstract class GameDefinition {
  const GameDefinition();

  /// مفتاح اللعبة كما في جدول `games`.
  String get key;

  /// هل تحتاج اللعبة دورًا سريًا لكل لاعب (مثل المافيا)؟
  bool get hasSecretRoles => false;

  /// هل تدعم اللعبة المتفرجين أثناء اللعب؟
  bool get supportsSpectators => true;

  /// واجهة الجولة الحالية.
  Widget buildRound(BuildContext context, GameRoundContext ctx);

  /// واجهة نتيجة الجولة (اختيارية — الافتراضي عرض عام).
  Widget? buildRoundResult(BuildContext context, GameRoundContext ctx) => null;
}

/// كل ما تحتاجه واجهة اللعبة، مجمّعًا في كائن واحد.
@immutable
class GameRoundContext {
  const GameRoundContext({
    required this.roomId,
    required this.state,
    required this.controller,
    required this.myUserId,
  });

  final String roomId;
  final RoomState state;
  final RoomController controller;
  final String? myUserId;
}

class GameRegistry {
  const GameRegistry._();

  static const Map<String, GameDefinition> definitions = <String, GameDefinition>{
    GameKeys.animalPlantObject: AnimalPlantObjectGame(),
    GameKeys.mafia: MafiaGame(),
    GameKeys.trueFalse: TrueFalseGame(),
    GameKeys.guessWord: GuessWordGame(),
    GameKeys.proverbs: ProverbsGame(),
    GameKeys.whoAmI: WhoAmIGame(),
    GameKeys.liar: LiarGame(),
    GameKeys.groupStory: GroupStoryGame(),
  };

  static GameDefinition? of(String key) => definitions[key];
}
