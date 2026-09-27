import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/nav.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/avatar_orb.dart';
import '../widgets/brand.dart';
import '../widgets/fade_in.dart';
import '../widgets/glass.dart';
import '../widgets/pressable.dart';
import '../widgets/section_header.dart';
import 'players_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppState state = AppScope.of(context);

    return SafeArea(
      bottom: false,
      child: ListView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 130),
        children: <Widget>[
          FadeInUp(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('الإعدادات',
                    style: Theme.of(context).textTheme.displayMedium),
                const SizedBox(height: 4),
                Text(
                  'ظبّط التجربة على مزاجك',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // ── Players card ──────────────────────────────────────
          FadeInUp(
            delay: const Duration(milliseconds: 80),
            child: GlassCard(
              onTap: () => Nav.push(context, const PlayersScreen()),
              tint: state.accent,
              tintOpacity: 0.12,
              glowColor: state.accent,
              child: Row(
                children: <Widget>[
                  AvatarStack(players: state.players, size: 38),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const Text(
                          'إدارة اللاعبين',
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                        Text(
                          '${state.players.length} لاعبين محفوظين',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_left_rounded, color: Colors.white.op(0.4)),
                ],
              ),
            ),
          ),

          const SizedBox(height: 26),
          SectionHeader(
            title: 'لون الواجهة',
            subtitle: 'يغيّر توهّج التطبيق بالكامل',
            accent: state.accent,
          ),
          const SizedBox(height: 14),
          FadeInUp(
            delay: const Duration(milliseconds: 140),
            child: GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  for (final Color c in AppColors.accentChoices)
                    Pressable(
                      scale: 0.88,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        state.accent = c;
                      },
                      child: AnimatedContainer(
                        duration: AppTheme.fast,
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppGradients.from(c),
                          border: Border.all(
                            color: state.accent == c
                                ? Colors.white
                                : Colors.white.op(0.12),
                            width: state.accent == c ? 2.4 : 1,
                          ),
                          boxShadow: state.accent == c
                              ? AppTheme.glow(c, opacity: 0.55, blur: 18, y: 6)
                              : null,
                        ),
                        child: state.accent == c
                            ? const Icon(Icons.check_rounded,
                                size: 18, color: Colors.white)
                            : null,
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 26),
          SectionHeader(
            title: 'التجربة',
            subtitle: 'صوت، اهتزاز وحركة',
            accent: state.accent,
          ),
          const SizedBox(height: 14),
          FadeInUp(
            delay: const Duration(milliseconds: 200),
            child: GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Column(
                children: <Widget>[
                  _SwitchTile(
                    icon: Icons.volume_up_rounded,
                    title: 'المؤثرات الصوتية',
                    subtitle: 'أصوات البطاقات والمؤقّت',
                    value: state.sound,
                    accent: state.accent,
                    onChanged: state.toggleSound,
                  ),
                  _divider(),
                  _SwitchTile(
                    icon: Icons.vibration_rounded,
                    title: 'الاهتزاز',
                    subtitle: 'ردّة فعل لمسية عند الضغط',
                    value: state.haptics,
                    accent: state.accent,
                    onChanged: state.toggleHaptics,
                  ),
                  _divider(),
                  _SwitchTile(
                    icon: Icons.local_fire_department_rounded,
                    title: 'الوضع الصعب',
                    subtitle: 'أسئلة أجرأ ووقت أقصر',
                    value: state.hardMode,
                    accent: state.accent,
                    onChanged: state.toggleHardMode,
                  ),
                  _divider(),
                  _SwitchTile(
                    icon: Icons.motion_photos_off_rounded,
                    title: 'تقليل الحركة',
                    subtitle: 'يوقف حركة الخلفية لتوفير البطارية',
                    value: state.reduceMotion,
                    accent: state.accent,
                    onChanged: state.toggleReduceMotion,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 26),
          FadeInUp(
            delay: const Duration(milliseconds: 260),
            child: GlassCard(
              child: Column(
                children: <Widget>[
                  const BrandMark(size: 56),
                  const SizedBox(height: 12),
                  const BrandWordmark(fontSize: 24),
                  const SizedBox(height: 6),
                  Text(
                    'الإصدار 1.0.0 • صُنع للّمات الحلوة',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Divider(color: Colors.white.op(0.07), height: 1),
      );
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.accent,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final Color accent;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: <Widget>[
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(13),
              color: accent.op(value ? 0.18 : 0.08),
              border: Border.all(color: accent.op(value ? 0.35 : 0.12)),
            ),
            child: Icon(icon, size: 18, color: value ? accent : AppColors.inkMuted),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                Text(subtitle, style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: (bool v) {
              HapticFeedback.selectionClick();
              onChanged(v);
            },
            activeTrackColor: accent,
          ),
        ],
      ),
    );
  }
}
