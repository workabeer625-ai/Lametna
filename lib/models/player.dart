import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A person sitting around the table.
class Player {
  Player({
    required this.id,
    required this.name,
    required this.emoji,
    required this.color,
    this.score = 0,
  });

  final String id;
  String name;
  String emoji;
  Color color;
  int score;

  /// Filled in while a round is running.
  bool isImposter = false;
  String secret = '';

  static const List<String> emojiPool = <String>[
    '🦊', '🐼', '🦁', '🐯', '🐸', '🐵', '🦄', '🐙',
    '🐳', '🦖', '🐧', '🦉', '🐝', '🦋', '👾', '🤖',
  ];

  factory Player.create(String name, int index) {
    return Player(
      id: '${DateTime.now().microsecondsSinceEpoch}_$index',
      name: name,
      emoji: emojiPool[index % emojiPool.length],
      color: AppColors.avatarColors[index % AppColors.avatarColors.length],
    );
  }

  /// First letter, used as a fallback avatar glyph.
  String get initial {
    final String trimmed = name.trim();
    return trimmed.isEmpty ? '?' : trimmed.substring(0, 1);
  }
}
