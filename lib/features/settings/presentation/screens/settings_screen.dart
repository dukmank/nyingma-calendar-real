import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/remote_data_cache.dart';
import '../../../../core/services/shared_preferences_provider.dart';
import '../../../../core/services/weather_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../profile/presentation/controllers/profile_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bo           = ref.watch(languageProvider);
    final useCelsius   = ref.watch(tempUnitCelsiusProvider);
    String s(String en, String tib) => bo ? tib : en;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.surface,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            titleSpacing: 20,
            title: Text(
              s('Settings', 'སྒྲིག་འགོད།'),
              style: AppTextStyles.headlineLarge,
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),

                  // ── NYINGMAPA COMMUNITY ──────────────────────────────
                  _SectionHeader(label: s('NYINGMAPA COMMUNITY', 'ཉིང་མ་སྡེ་ཚོགས།')),
                  const SizedBox(height: 8),
                  Container(
                    decoration: _cardDecoration,
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _SocialIcon(label: 'Facebook', color: const Color(0xFF1877F2),
                            icon: Icons.facebook, onTap: () {}),
                        _SocialIcon(label: 'Instagram', color: const Color(0xFFE1306C),
                            icon: Icons.camera_alt_rounded, onTap: () {}),
                        _SocialIcon(label: 'Youtube', color: const Color(0xFFFF0000),
                            icon: Icons.play_circle_fill_rounded, onTap: () {}),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── ACCOUNT ─────────────────────────────────────────
                  _SectionHeader(label: s('ACCOUNT', 'རྩིས་དེབ།')),
                  const SizedBox(height: 8),
                  Container(
                    decoration: _cardDecoration,
                    child: _SettingsRow(
                      icon: Icons.person_outline_rounded,
                      iconColor: AppColors.textSecondary,
                      label: s('Update Profile', 'གཞི་ནས་གསར་བཅོས།'),
                      onTap: () {},
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── APP SETTINGS ────────────────────────────────────
                  _SectionHeader(label: s('APP SETTINGS', 'ཉེར་སྤྱོད་སྒྲིག་འགོད།')),
                  const SizedBox(height: 8),
                  Container(
                    decoration: _cardDecoration,
                    child: Column(
                      children: [
                        _SettingsRow(
                          icon: Icons.notifications_outlined,
                          iconColor: AppColors.primary,
                          label: s('Notification', 'སྐུལ་བརྡ།'),
                          onTap: () {},
                        ),
                        const _Divider(),
                        // Language toggle row
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 32, height: 32,
                                decoration: BoxDecoration(
                                  color: AppColors.cardNeutral,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.language, size: 16, color: AppColors.textSecondary),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(s('Language', 'སྐད་ཡིག'), style: AppTextStyles.titleSmall),
                              ),
                              // བོད | EN toggle — controls global language
                              GestureDetector(
                                onTap: () async {
                                  ref.read(languageProvider.notifier).state = !bo;
                                  final prefs = ref.read(sharedPreferencesProvider);
                                  await prefs.setBool(AppConstants.spLanguage, !bo);
                                },
                                child: Container(
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: AppColors.cardNeutral,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _LangChip(label: 'བོད', active: bo),
                                      _LangChip(label: 'EN', active: !bo),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const _Divider(),
                        // Temperature unit toggle row
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 32, height: 32,
                                decoration: BoxDecoration(
                                  color: AppColors.cardNeutral,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.thermostat_outlined,
                                    size: 16, color: AppColors.textSecondary),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  s('Temperature Unit', 'དྲོད་ཚད་ཀྱི་ཚད།'),
                                  style: AppTextStyles.titleSmall,
                                ),
                              ),
                              // °C | °F toggle
                              GestureDetector(
                                onTap: () {
                                  ref.read(weatherProvider.notifier)
                                      .setTempUnitCelsius(!useCelsius);
                                },
                                child: Container(
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: AppColors.cardNeutral,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _TempChip(label: '°C', active: useCelsius),
                                      _TempChip(label: '°F', active: !useCelsius),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const _Divider(),
                        _SettingsRow(
                          icon: Icons.sync_outlined,
                          iconColor: AppColors.textSecondary,
                          label: s('Calendar Sync', 'ལོ་ཐོ་མཐུན།'),
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── DATA MANAGEMENT ──────────────────────────────────
                  _SectionHeader(label: s('DATA', 'གཞི་གྲངས།')),
                  const SizedBox(height: 8),
                  Container(
                    decoration: _cardDecoration,
                    child: Column(
                      children: [
                        _SettingsRow(
                          icon: Icons.cloud_upload_outlined,
                          iconColor: const Color(0xFF2471A3),
                          label: s('Sync to Server', 'གཞི་གྲངས་སེར་བར་མཐུད།'),
                          onTap: () async {
                            await ref.read(profileProvider.notifier).sync();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text(s('Sync complete', 'མཐུད་ལེགས།')),
                                backgroundColor: AppColors.primary,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ));
                            }
                          },
                        ),
                        const _Divider(),
                        const _Divider(),
                        _SettingsRow(
                          icon: Icons.cleaning_services_outlined,
                          iconColor: const Color(0xFF7D6608),
                          label: s('Clear Data Cache', 'གཞི་གྲངས་སྐྱེལ་སྦལ་བསུབ།'),
                          onTap: () => _confirmClearCache(context, ref, bo),
                        ),
                        const _Divider(),
                        _SettingsRow(
                          icon: Icons.delete_outline_rounded,
                          iconColor: Colors.red,
                          label: s('Clear All My Data', 'གཞི་གྲངས་ཚང་མ་བསུབ།'),
                          onTap: () => _confirmClearData(context, ref, bo),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── SUPPORT ─────────────────────────────────────────
                  _SectionHeader(label: s('SUPPORT', 'རོགས་རམ།')),
                  const SizedBox(height: 8),
                  Container(
                    decoration: _cardDecoration,
                    child: Column(
                      children: [
                        _SettingsRow(icon: Icons.groups_outlined, iconColor: AppColors.primary,
                            label: s('About us', 'ང་ཚོའི་སྐོར།'),
                            onTap: () => _showAboutSheet(context, bo)),
                        const _Divider(),
                        _SettingsRow(icon: Icons.ios_share_outlined, iconColor: AppColors.textSecondary,
                            label: s('Share the app', 'ཉེར་སྤྱོད་བཤར།'), onTap: () {}),
                        const _Divider(),
                        _SettingsRow(icon: Icons.star_outline_rounded,
                            iconColor: const Color(0xFFF59E0B),
                            label: s('Rate the app', 'ཉེར་སྤྱོད་མཐོ་དམན།'), onTap: () {}),
                        const _Divider(),
                        _SettingsRow(icon: Icons.mail_outline_rounded, iconColor: AppColors.textSecondary,
                            label: s('Contact support', 'རོགས་འདེབས།'), onTap: () {}),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // ── Version ──────────────────────────────────────────
                  Center(
                    child: GestureDetector(
                      onLongPress: () {
                        Clipboard.setData(const ClipboardData(text: 'v${AppConstants.appVersion}'));
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: const Text('Version copied'),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ));
                      },
                      child: Column(children: [
                        const Icon(Icons.auto_awesome, size: 16, color: AppColors.gold),
                        const SizedBox(height: 6),
                        Text(
                          '${AppConstants.appName}',
                          style: AppTextStyles.titleSmall.copyWith(
                              color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'v${AppConstants.appVersion}  •  Phugpa Tradition',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          s('Built with devotion for the Nyingma community',
                              'ཉིང་མའི་སྡེ་ཚོགས་ལ་གུས་མོས་ཀྱིས་བཞེངས།'),
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textMuted,
                              fontStyle: FontStyle.italic),
                        ),
                      ]),
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration get _cardDecoration => BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      );
}

// ── Top-level helpers ───────────────────────────────────────────────────────

void _confirmClearCache(BuildContext context, WidgetRef ref, bool bo) {
  String s(String en, String tib) => bo ? tib : en;
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(s('Clear Data Cache', 'གཞི་གྲངས་སྐྱེལ་སྦལ་བསུབ།'),
          style: AppTextStyles.titleMedium),
      content: Text(
        s(
          'Calendar and event data will be re-downloaded from the server on next launch. '
          'Your personal data and practices are not affected.',
          'ལོ་ཐོ་དང་དུས་ཆེན་གྱི་གཞི་གྲངས་ཐེངས་རྗེས་མར་གསར་བཀྱེད་གནང་རོགས། ཁྱེད་ཀྱི་དངོས་གཞི་གྲངས་ལ་གནོད་པ་མི་འབྱུང་།',
        ),
        style: AppTextStyles.bodySmall,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(s('Cancel', 'ལོག'), style: AppTextStyles.labelLarge),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7D6608),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10))),
          onPressed: () async {
            Navigator.of(ctx).pop();
            await ref.read(remoteDataCacheProvider).clearCache();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(s('Cache cleared', 'སྐྱེལ་སྦལ་བསུབས་སོང་།')),
                backgroundColor: const Color(0xFF7D6608),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ));
            }
          },
          child: Text(s('Clear Cache', 'བསུབ།'), style: AppTextStyles.labelLarge),
        ),
      ],
    ),
  );
}

void _confirmClearData(BuildContext context, WidgetRef ref, bool bo) {
  String s(String en, String tib) => bo ? tib : en;
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        s('Clear All Data?', 'གཞི་གྲངས་ཚང་མ་བསུབ།'),
        style: AppTextStyles.titleLarge,
      ),
      content: Text(
        s(
          'This will permanently delete all your practices, events, and profile data. This action cannot be undone.',
          'འདིས་ཁྱེད་ཀྱི་སྒྲུབ་པ་དང་དུས་ཆེན། གཞི་གྲངས་ཚང་མ་མི་ལོག་ཐུབ་པར་བསུབ་གི་རེད།',
        ),
        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(
            s('Cancel', 'འདོར།'),
            style: AppTextStyles.labelLarge
                .copyWith(color: AppColors.textSecondary),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () async {
            Navigator.of(ctx).pop();
            await ref.read(profileProvider.notifier).clearAllData();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(s('All data cleared', 'གཞི་གྲངས་བསུབས།')),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ));
            }
          },
          child: Text(s('Delete', 'བསུབ།')),
        ),
      ],
    ),
  );
}

void _showAboutSheet(BuildContext context, bool bo) {
  String s(String en, String tib) => bo ? tib : en;
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // App icon placeholder
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color: AppColors.cardAuspicious,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.gold.withOpacity(0.4), width: 1.5),
            ),
            child: const Icon(Icons.auto_awesome,
                size: 36, color: AppColors.gold),
          ),
          const SizedBox(height: 14),

          Text(
            AppConstants.appName,
            style: AppTextStyles.headlineLarge,
          ),
          const SizedBox(height: 4),
          Text(
            'v${AppConstants.appVersion}  •  Phugpa Tradition',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              s(
                'The Nyingmapa Calendar is a sacred tool built to support the daily practice and spiritual life of the Nyingma community. It provides Tibetan lunar dates, auspicious days, practice tracking, and event reminders — all rooted in the Phugpa astronomical tradition.',
                'ཉིང་མའི་ལོ་ཐོ་འདི་ཉིང་མའི་སྡེ་ཚོགས་ཀྱི་ཉིན་རེའི་སྒྲུབ་པ་དང་ལམ་ལུགས་ལ་རོགས་རམ་གནང་བའི་ཆེད་བཞེངས་པའི་དམ་པའི་ལག་ཆ་ཞིག་རེད། འདིས་བོད་ཀྱི་ཟླ་ཚེས་དང་བཀྲ་ཤིས་ཉིན། སྒྲུབ་བརྩི། དང་དུས་ཆེན་དྲན་བརྡ་སོགས་ཕུག་པའི་ལྡེབས་རྩིས་ལུགས་ལ་གཞིར་བཞག་ནས་ཁྱབ་གདལ་བྱས།',
              ),
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary, height: 1.6),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),

          // Contact row
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () {},
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.mail_outline_rounded,
                      size: 16, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s('Contact Us', 'འབྲེལ་གཏུགས།'),
                          style: AppTextStyles.titleSmall),
                      Text('info@nyingmapacalendar.org',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.textMuted)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right,
                    size: 16, color: AppColors.textMuted),
              ]),
            ),
          ),
          const SizedBox(height: 16),

          Text(
            s(
              'Built with devotion for the Nyingma community',
              'ཉིང་མའི་སྡེ་ཚོགས་ལ་གུས་མོས་ཀྱིས་བཞེངས།',
            ),
            style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textMuted, fontStyle: FontStyle.italic),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}

// ── Section Header ─────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) => Text(
        label,
        style: AppTextStyles.labelMedium.copyWith(
          color: AppColors.textSecondary,
          letterSpacing: 1.5,
          fontSize: 11,
        ),
      );
}

// ── Social Icon ────────────────────────────────────────────────────────────────

class _SocialIcon extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _SocialIcon({required this.label, required this.color, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: color.withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: Icon(icon, color: Colors.white, size: 32),
            ),
            const SizedBox(height: 8),
            Text(label, style: AppTextStyles.labelMedium.copyWith(color: AppColors.textSecondary, fontSize: 12)),
          ],
        ),
      );
}

// ── Language Chip ──────────────────────────────────────────────────────────────

class _LangChip extends StatelessWidget {
  final String label;
  final bool active;
  const _LangChip({required this.label, required this.active});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelMedium.copyWith(
            color: active ? Colors.white : AppColors.textMuted,
            fontSize: 12,
          ),
        ),
      );
}

// ── Temperature Chip ───────────────────────────────────────────────────────────

class _TempChip extends StatelessWidget {
  final String label;
  final bool active;
  const _TempChip({required this.label, required this.active});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelMedium.copyWith(
            color: active ? Colors.white : AppColors.textMuted,
            fontSize: 12,
          ),
        ),
      );
}

// ── Settings Row ───────────────────────────────────────────────────────────────

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;

  const _SettingsRow({required this.icon, required this.iconColor, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(label, style: AppTextStyles.titleSmall)),
              const Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
            ],
          ),
        ),
      );
}

// ── Divider ────────────────────────────────────────────────────────────────────

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, indent: 60, color: AppColors.divider);
}
