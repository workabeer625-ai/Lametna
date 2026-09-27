import 'package:flutter/material.dart';

/// How a game is played once it starts.
enum GameMode {
  /// Pass-the-phone secret roles (spy style) → reveal → timer → vote.
  imposter,

  /// A swipeable deck of prompt cards.
  deck,
}

class PartyGame {
  const PartyGame({
    required this.id,
    required this.name,
    required this.tagline,
    required this.description,
    required this.emoji,
    required this.icon,
    required this.colors,
    required this.category,
    required this.minPlayers,
    required this.maxPlayers,
    required this.minutes,
    required this.heat,
    required this.mode,
    this.prompts = const <String>[],
    this.featured = false,
    this.rules = const <String>[],
  });

  final String id;
  final String name;
  final String tagline;
  final String description;
  final String emoji;
  final IconData icon;
  final List<Color> colors;
  final String category;
  final int minPlayers;
  final int maxPlayers;
  final int minutes;

  /// 1 → هادئة، 2 → متوسطة، 3 → نار 🔥
  final int heat;
  final GameMode mode;
  final List<String> prompts;
  final bool featured;
  final List<String> rules;

  Color get primary => colors.first;

  LinearGradient get gradient => LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: colors,
      );

  String get playersLabel => '$minPlayers–$maxPlayers لاعبين';

  String get heatLabel => switch (heat) {
        1 => 'هادئة',
        2 => 'متوسطة',
        _ => 'نار',
      };
}
