import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../app/router/route_names.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/tibetan_utils.dart';
import '../../domain/entities/user_profile_entity.dart';
import '../controllers/profile_controller.dart';
import '../states/profile_state.dart';

// ── Screen ─────────────────────────────────────────────────────────────────

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bo = ref.watch(languageProvider);
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (state) => _AccountBody(state: state, bo: bo),
      ),
    );
  }
}

// ── URLs / contacts ────────────────────────────────────────────────────────────

const _kFacebookUrl    = 'https://www.facebook.com/people/Vajra-Lotus-Foundation/61575704750387/?mibextid=wwXIfr';
const _kInstagramUrl   = 'https://www.instagram.com/vajralotusfoundation?igsh=MWh2bGQ2a2E0ajhqZg%3D%3D&utm_source=qr';
const _kYouTubeUrl     = 'https://www.youtube.com/@vajralotusfoundation?si=26KIlJaEQuzBygdO';
const _kNamKhaZoeUrl   = 'https://www.vajralotusfoundation.org/namkhazoe';
const _kDharmaShopUrl  = 'https://www.vajralotusfoundation.org/shop';
const _kSupportEmail   = 'info@vajralotusfoundation.org';
const _kAppStoreUrl    = 'https://apps.apple.com/app/id000000000'; // update with real ID
const _kShareText      = 'Discover the Nyingmapa Calendar — track Tibetan auspicious days, practices & events! 🙏';

Future<void> _launch(String url) async {
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

// ── Account Body ──────────────────────────────────────────────────────────

class _AccountBody extends ConsumerStatefulWidget {
  final ProfileState state;
  final bool bo;

  const _AccountBody({required this.state, required this.bo});

  @override
  ConsumerState<_AccountBody> createState() => _AccountBodyState();
}

class _AccountBodyState extends ConsumerState<_AccountBody> {
  // Local notification toggle; defaults to true (enabled)
  bool _notifEnabled = true;

  String s(String en, String tib) => widget.bo ? tib : en;

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final bo    = widget.bo;
    final profile = state.profile;

    return SingleChildScrollView(
      child: Column(
        children: [
          // ── Profile header banner ────────────────────────────────
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF3A1208), Color(0xFF8B1A1A)],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                child: Column(
                  children: [
                    // Avatar + edit
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          width: 80, height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withOpacity(0.4), width: 2),
                          ),
                          child: Center(
                            child: Text(
                              profile.initials,
                              style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _showEditSheet(context, state, bo),
                          child: Container(
                            width: 26, height: 26,
                            decoration: BoxDecoration(
                              color: AppColors.gold,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(Icons.edit, color: Colors.white, size: 13),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(profile.displayName,
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                    if ((profile.email ?? '').isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(profile.email ?? '',
                          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
                    ],
                  ],
                ),
              ),
            ),
          ),


          // ── My Practices + My Events ────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(children: [
              Expanded(
                child: _QuickLinkCard(
                  icon: Icons.self_improvement_outlined,
                  label: s('My Practices', 'སྒྲུབ་པ།'),
                  count: state.practices.length,
                  bo: bo,
                  onTap: () => context.push(RouteNames.myPractices),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickLinkCard(
                  icon: Icons.bookmark_outline,
                  label: s('My Events', 'ང་ཡི་དུས་ཆེན།'),
                  count: state.events.length,
                  bo: bo,
                  onTap: () => context.push(RouteNames.myEvents),
                ),
              ),
            ]),
          ),

          const SizedBox(height: 20),

          // ── Our Community ────────────────────────────────────────
          _SectionCard(
            title: s('OUR COMMUNITY', 'ང་ཚོའི་སྤྱི་ཚོགས།'),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _SocialBtn(
                  color: const Color(0xFF1877F2),
                  icon: Icons.facebook_outlined,
                  label: 'Facebook',
                  onTap: () => _launch(_kFacebookUrl),
                ),
                _SocialBtn(
                  color: const Color(0xFFE1306C),
                  icon: Icons.camera_alt_outlined,
                  label: 'Instagram',
                  onTap: () => _launch(_kInstagramUrl),
                ),
                _SocialBtn(
                  color: const Color(0xFFFF0000),
                  icon: Icons.play_circle_outline,
                  label: 'YouTube',
                  onTap: () => _launch(_kYouTubeUrl),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Our Products ─────────────────────────────────────────
          _SectionCard(
            title: s('OUR PRODUCTS', 'ང་ཚོའི་ཐོན་རྫས།'),
            child: Column(children: [
              _ListTileRow(
                icon: Icons.store_outlined,
                label: 'Nam Kha Zoe',
                onTap: () => _launch(_kNamKhaZoeUrl),
              ),
              const Divider(height: 1, color: AppColors.divider),
              _ListTileRow(
                icon: Icons.volunteer_activism_outlined,
                label: 'Dharma Gift Shop',
                onTap: () => _launch(_kDharmaShopUrl),
              ),
            ]),
          ),

          const SizedBox(height: 12),

          // ── App Settings ─────────────────────────────────────────
          _SectionCard(
            title: s('APP SETTINGS', 'གཡོག་ཁང་།'),
            child: Column(children: [
              _ToggleRow(
                icon: Icons.notifications_outlined,
                label: s('Notification', 'བརྡ་འཕྲིན།'),
                value: _notifEnabled,
                onChanged: (v) async {
                  if (v) {
                    final granted = await NotificationService.requestPermission();
                    setState(() => _notifEnabled = granted);
                    if (!granted && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(s(
                          'Please enable notifications in Settings',
                          'སྒྲིག་བཀོད་ནས་བརྡ་འཕྲིན་ཆོག་མཆན་གནང་།',
                        )),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ));
                    }
                  } else {
                    await NotificationService.cancelAll();
                    setState(() => _notifEnabled = false);
                  }
                },
              ),
              const Divider(height: 1, color: AppColors.divider),
              _ToggleRow(
                icon: Icons.language_outlined,
                label: s('Language', 'སྐད་ཡིག'),
                value: bo,
                onChanged: (v) => ref.read(languageProvider.notifier).state = v,
              ),
              const Divider(height: 1, color: AppColors.divider),
              _ListTileRow(
                icon: Icons.sync_outlined,
                label: s('Calendar Sync', 'ལོ་ཐོ་མཐུན་སྒྲིག'),
                onTap: () => _showSyncDialog(context),
              ),
            ]),
          ),

          const SizedBox(height: 12),

          // ── Support ──────────────────────────────────────────────
          _SectionCard(
            title: s('SUPPORT', 'རོགས་རམ།'),
            child: Column(children: [
              _ListTileRow(
                icon: Icons.info_outline,
                label: s('About us', 'ང་ཚོར་སྐོར།'),
                onTap: () => _launch('https://www.vajralotusfoundation.org'),
              ),
              const Divider(height: 1, color: AppColors.divider),
              _ListTileRow(
                icon: Icons.share_outlined,
                label: s('Share the app', 'གཞི་གྲངས་བགོས།'),
                onTap: () => Share.share(_kShareText),
              ),
              const Divider(height: 1, color: AppColors.divider),
              _ListTileRow(
                icon: Icons.star_outline,
                label: s('Rate the app', 'བོད་བཤད།'),
                onTap: () => _launch(_kAppStoreUrl),
              ),
              const Divider(height: 1, color: AppColors.divider),
              _ListTileRow(
                icon: Icons.email_outlined,
                label: s('Contact support', 'རོགས་རམ་གནང་།'),
                onTap: () => _launch('mailto:$_kSupportEmail?subject=Nyingmapa Calendar Support'),
              ),
            ]),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showEditSheet(BuildContext context, ProfileState state, bool bo) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditSheet(state: state, bo: bo, ref: ref),
    );
  }

  void _showSyncDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(s('Calendar Sync', 'ལོ་ཐོ་མཐུན་སྒྲིག')),
        content: Text(s(
          'Calendar sync keeps your practices and events up to date across devices. This feature is coming soon.',
          'ལོ་ཐོ་མཐུན་སྒྲིག་གིས་ཁྱེད་ཀྱི་སྒྲུབ་པ་དང་དུས་ཆེན་མིང་གཞིར་གྱུར་རྒྱུ། ཚབ་ལས་འགྲོ་བཞིན་ཡོད།',
        )),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(s('OK', 'ཡིན།'), style: const TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}

// ── Quick Link Card ───────────────────────────────────────────────────────────

class _QuickLinkCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final bool bo;
  final VoidCallback onTap;

  const _QuickLinkCard({required this.icon, required this.label, required this.count, this.bo = false, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: AppTextStyles.titleSmall.copyWith(fontSize: 12)),
              Text(
                bo ? '${toTibNum(count)} རྩིས།' : '$count items',
                style: AppTextStyles.bodySmall.copyWith(fontSize: 10),
              ),
            ])),
            const Icon(Icons.chevron_right, size: 16, color: AppColors.textMuted),
          ]),
        ),
      );
}

// ── Section Card ──────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              child: Text(
                title,
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.textMuted,
                  letterSpacing: 1.5,
                  fontSize: 10,
                ),
              ),
            ),
            const Divider(height: 1, color: AppColors.divider),
            Padding(
              padding: const EdgeInsets.all(12),
              child: child,
            ),
          ],
        ),
      );
}

// ── Social Button ─────────────────────────────────────────────────────────────

class _SocialBtn extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SocialBtn({required this.color, required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Column(children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(height: 6),
          Text(label, style: AppTextStyles.labelMedium.copyWith(color: AppColors.textSecondary, fontSize: 9)),
        ]),
      );
}

// ── List Tile Row ─────────────────────────────────────────────────────────────

class _ListTileRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ListTileRow({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(children: [
            Icon(icon, size: 20, color: AppColors.textSecondary),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary))),
            const Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
          ]),
        ),
      );
}

// ── Toggle Row ────────────────────────────────────────────────────────────────

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({required this.icon, required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary))),
          Transform.scale(
            scale: 0.8,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeColor: AppColors.primary,
            ),
          ),
        ]),
      );
}

// ── Edit Sheet ────────────────────────────────────────────────────────────────

class _EditSheet extends ConsumerStatefulWidget {
  final ProfileState state;
  final bool bo;
  final WidgetRef ref;

  const _EditSheet({required this.state, required this.bo, required this.ref});

  @override
  ConsumerState<_EditSheet> createState() => _EditSheetState();
}

class _EditSheetState extends ConsumerState<_EditSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.state.profile.displayName);
    _emailCtrl = TextEditingController(text: widget.state.profile.email ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String s(String en, String tib) => widget.bo ? tib : en;

    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text(s('Edit Profile', 'གཞི་ལུགས་བཅོས།'), style: AppTextStyles.headlineSmall),
            const SizedBox(height: 16),
            TextField(controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: s('Display name', 'མཚན།'),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.primary)),
              )),
            const SizedBox(height: 12),
            TextField(controller: _emailCtrl,
              decoration: InputDecoration(
                labelText: s('Email', 'གློག་འཕྲིན།'),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.primary)),
              )),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : () async {
                  setState(() => _saving = true);
                  await ref.read(profileProvider.notifier).updateProfile(
                    widget.state.profile.copyWith(
                      displayName: _nameCtrl.text.trim(),
                      email: _emailCtrl.text.trim(),
                    ),
                  );
                  if (context.mounted) Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: _saving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(s('Save', 'ཉར།')),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
