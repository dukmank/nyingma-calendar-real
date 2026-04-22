import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/services/shared_preferences_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../app/router/route_names.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  // ── Slide data ──────────────────────────────────────────────────────────

  static const _slides = [
    _Slide(
      iconData: Icons.auto_awesome,
      titleEn: 'Nyingmapa Calendar',
      titleBo: 'ཉིང་མའི་ལོ་ཐོ།',
      bodyEn:
          'A sacred tool for the Nyingma community — aligning your daily life with the rhythm of the Tibetan lunar calendar.',
      bodyBo:
          'ཉིང་མའི་སྡེ་ཚོགས་ལ་བོད་ཀྱི་ཟླ་ཚེས་ལུགས་ལ་བསྟེན་ནས་ཉིན་རེའི་འཚོ་བར་རོགས་རམ་གནང་བའི་དམ་པའི་ལག་ཆ།',
      accentColor: AppColors.primary,
    ),
    _Slide(
      iconData: Icons.calendar_month_outlined,
      titleEn: 'What\'s Inside',
      titleBo: 'ནང་གི་དོན་ཚན།',
      bodyEn:
          'Tibetan lunar calendar · Auspicious days · Sacred events · Practice tracking · Astrology & directions',
      bodyBo:
          'བོད་ཀྱི་ཟླ་ཚེས། · བཀྲ་ཤིས་ཉིན། · དམ་པའི་དུས་ཆེན། · སྒྲུབ་བརྩི། · སྐར་རྩིས།',
      accentColor: AppColors.gold,
    ),
    _Slide(
      iconData: Icons.language,
      titleEn: 'Choose Your Language',
      titleBo: 'སྐད་ཡིག་འདེམས།',
      bodyEn: 'The app is fully bilingual. You can switch languages at any time in Settings.',
      bodyBo: 'ཉིང་མའི་ལོ་ཐོ་ཡིག་སྐད་གཉིས་ཀར་སྤྱོད་ཆོག། སྒྲིག་བཀོད་ཀྱི་ཤོག་ལྷེ་ལ་སྐད་ཡིག་བསྒྱུར་ཆོག',
      accentColor: AppColors.primary,
      isLanguageSlide: true,
    ),
  ];

  // ── Navigation ───────────────────────────────────────────────────────────

  void _next() {
    if (_page < _slides.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(AppConstants.spOnboardingDone, true);
    if (mounted) context.go(RouteNames.calendar);
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bo = ref.watch(languageProvider);
    final slide = _slides[_page];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _finish,
                child: Text(
                  bo ? 'བརྒལ།' : 'Skip',
                  style: AppTextStyles.labelMedium
                      .copyWith(color: AppColors.textMuted),
                ),
              ),
            ),

            // PageView
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                itemCount: _slides.length,
                itemBuilder: (ctx, i) =>
                    _SlidePage(slide: _slides[i], bo: bo, ref: ref),
              ),
            ),

            // Dot indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _slides.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: i == _page ? 22 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: i == _page ? slide.accentColor : AppColors.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Action button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ElevatedButton(
                onPressed: _next,
                style: ElevatedButton.styleFrom(
                  backgroundColor: slide.accentColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                  textStyle: AppTextStyles.labelLarge
                      .copyWith(color: Colors.white, letterSpacing: 1.5),
                ),
                child: Text(
                  _page < _slides.length - 1
                      ? (bo ? 'རྗེས་མ།' : 'Next')
                      : (bo ? 'འགོ་བརྩམས།' : 'Get Started'),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

// ── Slide page ───────────────────────────────────────────────────────────────

class _SlidePage extends StatelessWidget {
  final _Slide slide;
  final bool bo;
  final WidgetRef ref;

  const _SlidePage({required this.slide, required this.bo, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon orb
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: slide.accentColor.withOpacity(0.08),
              border: Border.all(
                  color: slide.accentColor.withOpacity(0.25), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: slide.accentColor.withOpacity(0.12),
                  blurRadius: 24,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Icon(slide.iconData, size: 48, color: slide.accentColor),
          ),
          const SizedBox(height: 36),

          // Title
          Text(
            bo ? slide.titleBo : slide.titleEn,
            style: AppTextStyles.displayMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Body
          Text(
            bo ? slide.bodyBo : slide.bodyEn,
            style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textSecondary, height: 1.6),
            textAlign: TextAlign.center,
          ),

          // Language selector (only on the last slide)
          if (slide.isLanguageSlide) ...[
            const SizedBox(height: 36),
            _LanguageSelector(bo: bo, ref: ref, accentColor: slide.accentColor),
          ],
        ],
      ),
    );
  }
}

// ── Language selector ────────────────────────────────────────────────────────

class _LanguageSelector extends StatelessWidget {
  final bool bo;
  final WidgetRef ref;
  final Color accentColor;

  const _LanguageSelector(
      {required this.bo, required this.ref, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _LangOption(
            label: 'English',
            sublabel: 'Use the app in English',
            selected: !bo,
            isTop: true,
            accentColor: accentColor,
            onTap: () => _select(context, false),
          ),
          Divider(height: 1, color: AppColors.border),
          _LangOption(
            label: 'བོད་སྐད།',
            sublabel: 'བོད་སྐད་དུ་སྤྱོད།',
            selected: bo,
            isTop: false,
            accentColor: accentColor,
            onTap: () => _select(context, true),
          ),
        ],
      ),
    );
  }

  void _select(BuildContext context, bool tibetan) {
    ref.read(languageProvider.notifier).state = tibetan;
    final prefs = ref.read(sharedPreferencesProvider);
    prefs.setBool(AppConstants.spLanguage, tibetan);
  }
}

class _LangOption extends StatelessWidget {
  final String label;
  final String sublabel;
  final bool selected;
  final bool isTop;
  final Color accentColor;
  final VoidCallback onTap;

  const _LangOption({
    required this.label,
    required this.sublabel,
    required this.selected,
    required this.isTop,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.vertical(
          top: isTop ? const Radius.circular(16) : Radius.zero,
          bottom: !isTop ? const Radius.circular(16) : Radius.zero,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? accentColor : Colors.transparent,
                  border: Border.all(
                    color: selected ? accentColor : AppColors.border,
                    width: 2,
                  ),
                ),
                child: selected
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTextStyles.titleMedium),
                  Text(sublabel,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textMuted)),
                ],
              ),
            ],
          ),
        ),
      );
}

// ── Slide data model ─────────────────────────────────────────────────────────

class _Slide {
  final IconData iconData;
  final String titleEn;
  final String titleBo;
  final String bodyEn;
  final String bodyBo;
  final Color accentColor;
  final bool isLanguageSlide;

  const _Slide({
    required this.iconData,
    required this.titleEn,
    required this.titleBo,
    required this.bodyEn,
    required this.bodyBo,
    required this.accentColor,
    this.isLanguageSlide = false,
  });
}
