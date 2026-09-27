import 'dart:math';

import 'package:flutter/material.dart';

import '../data/game_catalog.dart';
import '../models/party_game.dart';
import '../models/player.dart';
import '../theme/app_colors.dart';

/// A single lightweight store for the whole app — no external packages.
class AppState extends ChangeNotifier {
  AppState() {
    _players.addAll(<Player>[
      Player.create('ريم', 0),
      Player.create('سالم', 1),
      Player.create('نورة', 2),
      Player.create('فهد', 3),
    ]);
  }

  final Random _rng = Random();

  // ── Players ────────────────────────────────────────────────────
  final List<Player> _players = <Player>[];
  List<Player> get players => List<Player>.unmodifiable(_players);

  void addPlayer(String name) {
    final String clean = name.trim();
    if (clean.isEmpty || _players.length >= 16) return;
    _players.add(Player.create(clean, _players.length + _rng.nextInt(3)));
    notifyListeners();
  }

  void removePlayer(String id) {
    _players.removeWhere((Player p) => p.id == id);
    notifyListeners();
  }

  void renamePlayer(String id, String name) {
    for (final Player p in _players) {
      if (p.id == id) p.name = name.trim();
    }
    notifyListeners();
  }

  void cycleAvatar(Player player) {
    final int i = Player.emojiPool.indexOf(player.emoji);
    player.emoji = Player.emojiPool[(i + 1) % Player.emojiPool.length];
    final int ci = AppColors.avatarColors.indexOf(player.color);
    player.color = AppColors.avatarColors[(ci + 1) % AppColors.avatarColors.length];
    notifyListeners();
  }

  void addPoints(String id, int points) {
    for (final Player p in _players) {
      if (p.id == id) p.score += points;
    }
    notifyListeners();
  }

  void resetScores() {
    for (final Player p in _players) {
      p.score = 0;
    }
    notifyListeners();
  }

  List<Player> get ranking {
    final List<Player> list = <Player>[..._players];
    list.sort((Player a, Player b) => b.score.compareTo(a.score));
    return list;
  }

  // ── Session / round setup ──────────────────────────────────────
  PartyGame _game = GameCatalog.games.first;
  PartyGame get game => _game;
  set game(PartyGame value) {
    _game = value;
    notifyListeners();
  }

  int roundMinutes = 5;
  int imposterCount = 1;
  int roundsPlayed = 0;

  void setRoundMinutes(int v) {
    roundMinutes = v.clamp(1, 15);
    notifyListeners();
  }

  void setImposterCount(int v) {
    imposterCount = v.clamp(1, max(1, _players.length - 2));
    notifyListeners();
  }

  /// Currently revealed secret word for imposter games.
  String secretWord = '';

  /// Shuffles roles for a new imposter round.
  void dealRoles() {
    final List<String> pool = _game.prompts.isEmpty
        ? GameCatalog.byId('spy').prompts
        : _game.prompts;
    secretWord = pool[_rng.nextInt(pool.length)];

    for (final Player p in _players) {
      p.isImposter = false;
      p.secret = secretWord;
    }
    final List<Player> shuffled = <Player>[..._players]..shuffle(_rng);
    final int count = imposterCount.clamp(1, max(1, _players.length - 1));
    for (int i = 0; i < count && i < shuffled.length; i++) {
      shuffled[i].isImposter = true;
      shuffled[i].secret = '';
    }
    notifyListeners();
  }

  List<Player> get imposters =>
      _players.where((Player p) => p.isImposter).toList();

  void completeRound() {
    roundsPlayed++;
    notifyListeners();
  }

  // ── Preferences ────────────────────────────────────────────────
  Color _accent = AppColors.violet;
  Color get accent => _accent;
  set accent(Color value) {
    _accent = value;
    notifyListeners();
  }

  bool sound = true;
  bool haptics = true;
  bool hardMode = false;
  bool reduceMotion = false;

  void toggleSound(bool v) {
    sound = v;
    notifyListeners();
  }

  void toggleHaptics(bool v) {
    haptics = v;
    notifyListeners();
  }

  void toggleHardMode(bool v) {
    hardMode = v;
    notifyListeners();
  }

  void toggleReduceMotion(bool v) {
    reduceMotion = v;
    notifyListeners();
  }
}

/// Inherited access to [AppState] — rebuilds dependents on notify.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
      : super(notifier: state);

  static AppState of(BuildContext context) {
    final AppScope? scope =
        context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope was not found in the widget tree');
    return scope!.notifier!;
  }

  /// Read without subscribing to rebuilds.
  static AppState read(BuildContext context) {
    final AppScope? scope =
        context.getInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope was not found in the widget tree');
    return scope!.notifier!;
  }
}
