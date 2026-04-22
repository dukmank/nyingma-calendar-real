import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/tibetan_utils.dart';
import '../../../profile/domain/entities/practice_entity.dart';
import '../../../profile/presentation/controllers/profile_controller.dart';
import '../../../../core/services/notification_service.dart';

class CreatePracticeScreen extends ConsumerStatefulWidget {
  /// When non-null, screen is in edit mode.
  final PracticeEntity? existing;

  const CreatePracticeScreen({super.key, this.existing});

  @override
  ConsumerState<CreatePracticeScreen> createState() => _CreatePracticeScreenState();
}

class _CreatePracticeScreenState extends ConsumerState<CreatePracticeScreen>
    with SingleTickerProviderStateMixin {
  final _titleCtrl   = TextEditingController();
  final _contentCtrl = TextEditingController();
  late TabController _tabCtrl;

  TimeOfDay _time     = TimeOfDay.now();
  DateTime  _date     = DateTime.now();
  String    _repeat   = 'Never';
  String    _reminder = 'On time';
  bool      _saving   = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    if (widget.existing != null) {
      final e = widget.existing!;
      _titleCtrl.text   = e.title;
      _contentCtrl.text = e.description ?? '';
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) setState(() => _date = picked);
  }

  static String _localizeRepeat(String r, bool bo) {
    if (!bo) return r;
    switch (r) {
      case 'Daily':   return 'ཉིན་རེ།';
      case 'Weekly':  return 'གཟའ་ཕར།';
      case 'Monthly': return 'ཟླ་ཕར།';
      case 'Yearly':  return 'ལོ་ཕར།';
      default:        return 'མེད།'; // Never
    }
  }

  static String _localizeReminder(String r, bool bo) {
    if (!bo) return r;
    switch (r) {
      case '5 minutes before':  return 'སྐར་མ་༥ སྔོན།';
      case '15 minutes before': return 'སྐར་མ་༡༥ སྔོན།';
      case '30 minutes before': return 'སྐར་མ་༣༠ སྔོན།';
      case '1 hour before':     return 'ཆུ་ཚོད་༡ སྔོན།';
      default:                  return 'དུས་ཚོད་ལ།'; // On time
    }
  }

  Future<void> _pickRepeat() async {
    final bo = ref.read(languageProvider);
    const keys   = ['Never', 'Daily', 'Weekly', 'Monthly', 'Yearly'];
    final labels  = keys.map((k) => _localizeRepeat(k, bo)).toList();
    final result  = await _showPicker(keys, labels, _repeat);
    if (result != null) setState(() => _repeat = result);
  }

  Future<void> _pickReminder() async {
    final bo = ref.read(languageProvider);
    const keys = ['On time', '5 minutes before', '15 minutes before', '30 minutes before', '1 hour before'];
    final labels = keys.map((k) => _localizeReminder(k, bo)).toList();
    final result = await _showPicker(keys, labels, _reminder);
    if (result != null) setState(() => _reminder = result);
  }

  Future<String?> _showPicker(List<String> keys, List<String> labels, String current) {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(width: 40, height: 4,
                decoration: BoxDecoration(color: AppColors.border,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 12),
            ...List.generate(keys.length, (i) => ListTile(
              title: Text(labels[i], style: AppTextStyles.bodyMedium),
              trailing: keys[i] == current
                  ? const Icon(Icons.check, color: AppColors.primary, size: 20)
                  : null,
              onTap: () => Navigator.pop(context, keys[i]),
            )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  int _reminderToMinutes(String r) {
    switch (r) {
      case '5 minutes before':  return 5;
      case '15 minutes before': return 15;
      case '30 minutes before': return 30;
      case '1 hour before':     return 60;
      default:                  return 0; // On time
    }
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    final bo = ref.read(languageProvider);
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(bo ? 'མིང་བཀང་རོགས།' : 'Please enter a title'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
      return;
    }
    setState(() => _saving = true);
    final now = DateTime.now();
    final notifier = ref.read(profileProvider.notifier);

    // Use title hash as stable notification ID (consistent across create/edit)
    final notifId = NotificationService.idFromString(title);
    // Cancel any existing reminder first
    await NotificationService.cancelNotification(notifId);

    if (_isEdit) {
      final updated = widget.existing!.copyWith(
        title: title,
        description: _contentCtrl.text.trim().isEmpty ? null : _contentCtrl.text.trim(),
        updatedAt: now,
      );
      await notifier.updatePractice(updated);
    } else {
      final practice = PracticeEntity(
        id: '',
        title: title,
        description: _contentCtrl.text.trim().isEmpty ? null : _contentCtrl.text.trim(),
        colorHex: '#8B1A1A',
        createdAt: now,
        updatedAt: now,
      );
      await notifier.addPractice(practice);
    }

    // Schedule daily reminder if selected
    if (_reminder != 'On time' || true) {
      // 'On time' means at the chosen time; other options shift back
      final offsetMin = _reminderToMinutes(_reminder);
      final totalMin = _time.hour * 60 + _time.minute - offsetMin;
      final finalHour = ((totalMin ~/ 60) % 24 + 24) % 24;
      final finalMin  = ((totalMin % 60) + 60) % 60;
      await NotificationService.scheduleDailyPractice(
        id: notifId,
        practiceName: title,
        hour: finalHour,
        minute: finalMin,
      );
    }

    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final bo = ref.watch(languageProvider);
    String s(String en, String tib) => bo ? tib : en;

    final String timeStr;
    final String dateStr;
    if (bo) {
      timeStr = toTibNum(_time.hour) + ':' + toTibNum(_time.minute);
      dateStr = toTibNum(_date.day) + '/' + toTibNum(_date.month) +
          '/' + toTibNum(_date.year % 100);
    } else {
      timeStr = _time.hour.toString().padLeft(2, '0') +
          ':' + _time.minute.toString().padLeft(2, '0');
      dateStr = _date.day.toString().padLeft(2, '0') +
          '/' + _date.month.toString().padLeft(2, '0') +
          '/' + _date.year.toString().substring(2);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: AppColors.textPrimary, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          s(_isEdit ? 'Edit Practice' : 'Add Practice',
            _isEdit ? 'སྒྲུབ་པ་བཅོས།' : 'སྒྲུབ་པ་གསར།'),
          style: AppTextStyles.headlineSmall,
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Title ────────────────────────────────────────────
                  Text(s('Title', 'མིང་།'), style: _labelStyle),
                  const SizedBox(height: 8),
                  _TextField(
                    controller: _titleCtrl,
                    hint: s('Enter practice name', 'སྒྲུབ་པའི་མིང་བཀང་།'),
                  ),
                  const SizedBox(height: 20),

                  // ── Content ──────────────────────────────────────────
                  Text(s('Content', 'ནང་དོན།'), style: _labelStyle),
                  const SizedBox(height: 8),
                  _TextField(
                    controller: _contentCtrl,
                    hint: s('Enter practice content', 'སྒྲུབ་པའི་ནང་དོན་བཀང་།'),
                    maxLines: 4,
                  ),
                  const SizedBox(height: 24),

                  // ── Calendar tab ──────────────────────────────────────
                  TabBar(
                    controller: _tabCtrl,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: AppColors.textSecondary,
                    indicatorColor: AppColors.primary,
                    indicatorSize: TabBarIndicatorSize.label,
                    dividerColor: AppColors.border,
                    labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    tabs: [
                      Tab(text: s('Gregorian calendar', 'ཉིན་ཐོ་།')),
                      Tab(text: s('Tibetan calendar', 'བོད་ཉིན་ཐོ།')),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Time + Date ───────────────────────────────────────
                  _RowPicker(
                    label: s('Time', 'དུས་ཚོད།'),
                    value1: timeStr,
                    value2: dateStr,
                    onTap1: _pickTime,
                    onTap2: _pickDate,
                  ),
                  const Divider(height: 1, color: AppColors.border),
                  const SizedBox(height: 4),

                  // ── Repeat ────────────────────────────────────────────
                  _ArrowRow(
                    label: s('Repeat', 'བསྐྱར་བཟོ།'),
                    value: _localizeRepeat(_repeat, bo),
                    onTap: _pickRepeat,
                  ),
                  const Divider(height: 1, color: AppColors.border),
                  const SizedBox(height: 4),

                  // ── Reminder ──────────────────────────────────────────
                  _ArrowRow(
                    label: s('Reminder', 'དྲན་སྐུལ།'),
                    value: _localizeReminder(_reminder, bo),
                    onTap: _pickReminder,
                    subtitle: _localizeReminder(_reminder, bo),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          // ── Add button ────────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20,
                MediaQuery.of(context).padding.bottom + 16),
            child: GestureDetector(
              onTap: _saving ? null : _save,
              child: Container(
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8C96A),
                  borderRadius: BorderRadius.circular(30),
                ),
                alignment: Alignment.center,
                child: _saving
                    ? const SizedBox(width: 22, height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(
                        s(_isEdit ? 'Save' : 'Add', _isEdit ? 'ཉར།' : 'ཞུ།'),
                        style: const TextStyle(
                          color: Color(0xFF5A3A00),
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared UI helpers ─────────────────────────────────────────────────────────

const _labelStyle = TextStyle(
  color: AppColors.textPrimary,
  fontSize: 14,
  fontWeight: FontWeight.w600,
);

class _TextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;

  const _TextField({required this.controller, required this.hint, this.maxLines = 1});

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        maxLines: maxLines,
        style: AppTextStyles.bodyMedium,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
          filled: true,
          fillColor: const Color(0xFFF7F7F7),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
        ),
      );
}

class _RowPicker extends StatelessWidget {
  final String label;
  final String value1;
  final String value2;
  final VoidCallback onTap1;
  final VoidCallback onTap2;

  const _RowPicker({
    required this.label,
    required this.value1,
    required this.value2,
    required this.onTap1,
    required this.onTap2,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(children: [
          Expanded(child: Text(label, style: _labelStyle)),
          GestureDetector(
            onTap: onTap1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(value1, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onTap2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(value2, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
            ),
          ),
        ]),
      );
}

class _ArrowRow extends StatelessWidget {
  final String label;
  final String value;
  final String? subtitle;
  final VoidCallback onTap;

  const _ArrowRow({required this.label, required this.value, this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(children: [
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: _labelStyle),
                if (subtitle != null && subtitle != label) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted)),
                ],
              ],
            )),
            Text(value, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
          ]),
        ),
      );
}
