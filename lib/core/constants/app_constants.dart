/// ثوابت عامة للتطبيق — Lametna app-wide constants.
class AppConstants {
  const AppConstants._();

  static const String appNameAr = 'لمّتنا';
  static const String appNameEn = 'Lametna';
  static const String sloganAr = 'لمّتنا تجمعنا… واللعبة تبدأ هنا';
  static const String sloganEn = 'Lametna brings us together… the game starts here';

  static const String supportEmail = 'support@lametna.app';
  static const String privacyUrl = 'https://lametna.app/privacy';
  static const String termsUrl = 'https://lametna.app/terms';

  /// حدود الخطة المجانية — free-tier friendly limits.
  static const int maxMessageLength = 300;
  static const int maxAnswerLength = 60;
  static const int maxNicknameLength = 24;
  static const int minNicknameLength = 2;
  static const int messagesPerMinute = 10;
  static const int maxHostedRooms = 2;
  static const int chatHistoryLimit = 60;

  static const Duration heartbeatInterval = Duration(seconds: 20);
  static const Duration reconnectGrace = Duration(minutes: 2);
  static const Duration clockResyncInterval = Duration(minutes: 5);
  static const Duration realtimeRetryBase = Duration(seconds: 2);
}

/// مفاتيح الألعاب كما هي في قاعدة البيانات.
class GameKeys {
  const GameKeys._();

  static const String animalPlantObject = 'animal_plant_object';
  static const String mafia = 'mafia';
  static const String whoAmI = 'who_am_i';
  static const String trueFalse = 'true_false';
  static const String guessWord = 'guess_word';
  static const String liar = 'liar';
  static const String proverbs = 'proverbs';
  static const String groupStory = 'group_story';

  // --- توسعة الكتالوج (ترحيل 0012) ---
  static const String capitals = 'capitals';
  static const String flags = 'flags';
  static const String riddles = 'riddles';
  static const String islamic = 'islamic';
  static const String sports = 'sports';
  static const String history = 'history';
  static const String emojiPuzzle = 'emoji_puzzle';
  static const String fastMath = 'fast_math';
  static const String secretJob = 'secret_job';
  static const String bestAnswer = 'best_answer';

  static const List<String> all = <String>[
    animalPlantObject, mafia, whoAmI, trueFalse, guessWord, liar, proverbs, groupStory,
    capitals, flags, riddles, islamic, sports, history, emojiPuzzle, fastMath,
    secretJob, bestAnswer,
  ];
}

/// فئات جماد حيوان نبات (مفاتيح مستقرة + ترجمة في طبقة العرض).
class ApoCategories {
  const ApoCategories._();

  static const List<String> all = <String>[
    'name', 'animal', 'plant', 'object', 'country', 'city',
    'food', 'job', 'yemeni_city', 'yemeni_name', 'home_item',
  ];

  static const List<String> defaults = <String>[
    'name', 'animal', 'plant', 'object', 'country', 'city', 'food', 'job',
  ];
}

/// الصور الرمزية المضمّنة داخل التطبيق (لا رفع صور شخصية).
class BuiltInAvatars {
  const BuiltInAvatars._();

  static const List<String> keys = <String>[
    'coffee', 'lion', 'falcon', 'camel', 'star', 'moon',
    'palm', 'jambiya', 'lantern', 'mountain', 'sea', 'book',
  ];

  /// رمز تعبيري احتياطي عند غياب ملف الصورة.
  static const Map<String, String> emoji = <String, String>{
    'coffee': '☕', 'lion': '🦁', 'falcon': '🦅', 'camel': '🐪',
    'star': '⭐', 'moon': '🌙', 'palm': '🌴', 'jambiya': '🗡️',
    'lantern': '🏮', 'mountain': '🏔️', 'sea': '🌊', 'book': '📚',
  };

  static String emojiFor(String? key) => emoji[key] ?? '🙂';
}
