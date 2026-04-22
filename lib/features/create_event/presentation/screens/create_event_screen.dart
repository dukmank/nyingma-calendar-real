import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/services/remote_data_cache.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/tibetan_utils.dart';
import '../../../profile/domain/entities/user_event_entity.dart';
import '../../../profile/presentation/controllers/profile_controller.dart';
import '../../../../core/services/notification_service.dart';

class CreateEventScreen extends ConsumerStatefulWidget {
  /// When non-null, screen is in edit mode.
  final UserEventEntity? existing;

  const CreateEventScreen({super.key, this.existing});

  @override
  ConsumerState<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends ConsumerState<CreateEventScreen>
    with SingleTickerProviderStateMixin {
  final _titleCtrl   = TextEditingController();
  final _contentCtrl = TextEditingController();
  late TabController _tabCtrl;

  TimeOfDay _time     = TimeOfDay.now();
  DateTime  _date     = DateTime.now();
  String    _repeat   = 'Never';
  String    _reminder = 'On time';
  bool      _saving   = false;

  // Tibetan date info loaded for the selected Gregorian date
  String _tibDay   = '';
  String _tibMonth = '';
  String _tibYear  = '';

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    if (widget.existing != null) {
      final e = widget.existing!;
      _titleCtrl.text   = e.title;
      _contentCtrl.text = e.content;
      final parts = e.dateKey.split('-');
      if (parts.length == 3) {
        _date = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      }
      final tp = e.timeOfDay.split(':');
      if (tp.length == 2) {
        _time = TimeOfDay(hour: int.tryParse(tp[0]) ?? 9, minute: int.tryParse(tp[1]) ?? 0);
      }
      _repeat   = _minutesToRepeat(-1); // stored differently — skip for now
      _reminder = _minutesToReminder(e.reminderMinutes);
    }
    _loadTibetanDate(_date);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadTibetanDate(DateTime d) async {
    try {
      final json = await ref.read(remoteDataCacheProvider)
          .getJson(AppConstants.calendarPath(d.year, d.month));
      final days = json['days'];
      if (days is List) {
        final key = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
        for (final item in days) {
          if (item is Map && item['date_key'] == key) {
            setState(() {
              _tibDay   = item['tibetan_day_en']?.toString() ?? '';
              _tibMonth = item['tibetan_month_name_en'] as String? ?? '';
              _tibYear  = item['tibetan_year_en']?.toString() ?? '';
            });
            break;
          }
        }
      }
    } catch (_) {}
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
    if (picked != null) {
      setState(() => _date = picked);
      await _loadTibetanDate(picked);
    }
  }

  static String _localizeRepeat(String r, bool bo) {
    if (!bo) return r;
    switch (r) {
      case 'Never':   return 'མེད།';
      case 'Daily':   return 'ཉིན་རེ།';
      case 'Weekly':  return 'གཟའ་ཕར།';
      case 'Monthly': return 'ཟླ་ཕར།';
      case 'Yearly':  return 'ལོ་ཕར།';
      default:        return r;
    }
  }

  static String _localizeReminder(String r, bool bo) {
    if (!bo) return r;
    switch (r) {
      case 'On time':           return 'དུས་ཚོད་ལ།';
      case '5 minutes before':  return 'སྐར་མ་༥ སྔོན།';
      case '15 minutes before': return 'སྐར་མ་༡༥ སྔོན།';
      case '30 minutes before': return 'སྐར་མ་༣༠ སྔོན།';
      case '1 hour before':     return 'ཆུ་ཚོད་༡ སྔོན།';
      default:                  return r;
    }
  }

  Future<void> _pickRepeat() async {
    final bo = ref.read(languageProvider);
    final keys = ['Never', 'Daily', 'Weekly', 'Monthly', 'Yearly'];
    final labels = keys.map((k) => _localizeRepeat(k, bo)).toList();
    final result = await _showPicker(keys, labels, _repeat);
    if (result != null) setState(() => _repeat = result);
  }

  Future<void> _pickReminder() async {
    final bo = ref.read(languageProvider);
    final keys = ['On time', '5 minutes before', '15 minutes before', '30 minutes before', '1 hour before'];
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
            ...keys.asMap().entries.map((e) => ListTile(
              title: Text(labels[e.key], style: AppTextStyles.bodyMedium),
              trailing: e.value == current
                  ? const Icon(Icons.check, color: AppColors.primary, size: 20)
                  : null,
              onTap: () => Navigator.pop(context, e.value),
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

  String _minutesToReminder(int m) {
    switch (m) {
      case 5:  return '5 minutes before';
      case 15: return '15 minutes before';
      case 30: return '30 minutes before';
      case 60: return '1 hour before';
      default: return 'On time';
    }
  }

  String _minutesToRepeat(int _) => 'Never';

  String get _dateKey =>
      '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}';

  String get _timeStr =>
      _time.hour.toString().padLeft(2, '0') + ':' + _time.minute.toString().padLeft(2, '0');

  String get _lunarLabel => _tibDay.isNotEmpty && _tibMonth.isNotEmpty
      ? 'Day $_tibDay · $_tibMonth · $_tibYear'
      : '';

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

    final reminderMinutes = _reminderToMinutes(_reminder);
    // Build event date-time for scheduling
    final eventDateTime = DateTime(
      _date.year, _date.month, _date.day,
      _time.hour, _time.minute,
    );
    final reminderDateTime = eventDateTime.subtract(Duration(minutes: reminderMinutes));
    // Stable notification id from title + date
    final notifId = NotificationService.idFromString('$title|$_dateKey');

    if (_isEdit) {
      final updated = widget.existing!.copyWith(
        title: title,
        content: _contentCtrl.text.trim(),
        dateKey: _dateKey,
        timeOfDay: _timeStr,
        lunarLabel: _lunarLabel,
        reminderMinutes: reminderMinutes,
        updatedAt: now,
      );
      await notifier.updateEvent(updated);
    } else {
      final event = UserEventEntity(
        id: '',
        title: title,
        content: _contentCtrl.text.trim(),
        dateKey: _dateKey,
        timeOfDay: _timeStr,
        lunarLabel: _lunarLabel,
        repeatType: _repeat.toLowerCase(),
        reminderMinutes: reminderMinutes,
        createdAt: now,
        updatedAt: now,
      );
      await notifier.addEvent(event);
    }

    // Schedule one-time reminder notification
    await NotificationService.cancelNotification(notifId);
    if (reminderDateTime.isAfter(DateTime.now())) {
      await NotificationService.scheduleNotification(
        id: notifId,
        title: '🗓 $title',
        body: reminderMinutes > 0
            ? 'Starts in $reminderMinutes minutes'
            : 'Event starting now',
        scheduledTime: reminderDateTime,
        payload: 'event|$_dateKey',
      );
    }

    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final bo = ref.watch(languageProvider);
    String s(String en, String tib) => bo ? tib : en;

    final timeStr = _timeStr;
    final dateStr = _date.day.toString().padLeft(2, '0') +
        '/' + _date.month.toString().padLeft(2, '0') +
        '/' + _date.year.toString().substring(2);

    final tibDateStr = _tibDay.isNotEmpty
        ? 'Day $_tibDay · $_tibMonth · $_tibYear'
        : '—';

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
          s(_isEdit ? 'Edit Event' : 'Add Your Event',
            _isEdit ? 'དུས་ཆེན་བཅོས།' : 'ཁྱེད་ཀྱི་དུས་ཆེན།'),
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
                    hint: s('Enter event name', 'དུས་ཆེན་གྱི་མིང་བཀང་།'),
                  ),
                  const SizedBox(height: 20),

                  // ── Content ──────────────────────────────────────────
                  Text(s('Content', 'ནང་དོན།'), style: _labelStyle),
                  const SizedBox(height: 8),
                  _TextField(
                    controller: _contentCtrl,
                    hint: s('Enter event content', 'དུས་ཆེན་གྱི་ནང་དོན་བཀང་།'),
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
                      Tab(text: s('Gregorian', 'ཉིན་ཐོ་།')),
                      Tab(text: s('Tibetan', 'བོད་ཉིན་ཐོ།')),
                    ],
                    onTap: (_) {}, // display only
                  ),
                  const SizedBox(height: 20),

                  // ── Time + Date (Gregorian or Tibetan display) ────────
                  AnimatedBuilder(
                    animation: _tabCtrl,
                    builder: (_, __) {
                      final isTib = _tabCtrl.index == 1;
                      return _RowPicker(
                        label: s('Time', 'དུས་ཚོད།'),
                        value1: timeStr,
                        value2: isTib ? tibDateStr : dateStr,
                        onTap1: isTib ? () {} : _pickTime,
                        onTap2: isTib ? () {} : _pickDate,
                        readOnly2: isTib,
                      );
                    },
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

// ── Shared widgets (same as create_practice) ──────────────────────────────────

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
  final bool readOnly2;

  const _RowPicker({
    required this.label,
    required this.value1,
    required this.value2,
    required this.onTap1,
    required this.onTap2,
    this.readOnly2 = false,
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
              child: Text(value1,
                  style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: readOnly2 ? null : onTap2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(
                    color: readOnly2 ? AppColors.border.withOpacity(0.5) : AppColors.border),
                borderRadius: BorderRadius.circular(8),
                color: readOnly2 ? AppColors.surfaceVariant : null,
              ),
              child: Text(value2,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: readOnly2 ? AppColors.textMuted : AppColors.textPrimary,
                  )),
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
                  Text(subtitle!,
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted)),
                ],
              ],
            )),
            Text(value,
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
          ]),
        ),
      );
}
