import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_loading.dart';
import '../controllers/news_controller.dart';

class NewsDetailScreen extends ConsumerWidget {
  final String newsId;
  const NewsDetailScreen({super.key, required this.newsId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bo = ref.watch(languageProvider);
    final async = ref.watch(newsDetailProvider(newsId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: async.when(
        loading: () => const AppLoading(),
        error: (_, __) => _NotFound(onBack: () => Navigator.pop(context)),
        data: (post) {
          if (post == null) return _NotFound(onBack: () => Navigator.pop(context));

          return CustomScrollView(
            slivers: [
              // ── Hero image app bar ───────────────────────────────────
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                backgroundColor: AppColors.primary,
                surfaceTintColor: Colors.transparent,
                leading: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    margin: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.35),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 18),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: _HeroImage(url: post.imageUrl),
                ),
              ),

              // ── Article body ─────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category
                      _CategoryPill(category: post.category, bo: bo),
                      const SizedBox(height: 14),

                      // Title
                      Text(
                        post.title(bo),
                        style: AppTextStyles.headlineLarge.copyWith(
                          fontSize: 24,
                          height: 1.3,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Author + date row
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(children: [
                          Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.person_outline,
                                color: AppColors.primary, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                post.author,
                                style: AppTextStyles.titleSmall.copyWith(
                                    color: AppColors.textPrimary),
                              ),
                              if (post.publishedAt != null)
                                Text(
                                  _formatDate(post.publishedAt!),
                                  style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.textMuted, fontSize: 11),
                                ),
                            ],
                          )),
                        ]),
                      ),
                      const SizedBox(height: 20),

                      // Excerpt (bold lead)
                      if (post.excerpt(bo).isNotEmpty) ...[
                        Text(
                          post.excerpt(bo),
                          style: AppTextStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Divider(color: AppColors.border),
                        const SizedBox(height: 16),
                      ],

                      // Full content
                      Text(
                        post.content(bo),
                        style: AppTextStyles.bodyLarge.copyWith(
                          height: 1.75,
                          color: AppColors.textPrimary,
                        ),
                      ),

                      const SizedBox(height: 48),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = ['', 'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'];
    return '${months[dt.month]} ${dt.day}, ${dt.year}';
  }
}

// ── Hero image ─────────────────────────────────────────────────────────────────

class _HeroImage extends StatelessWidget {
  final String url;
  const _HeroImage({required this.url});

  @override
  Widget build(BuildContext context) => Stack(
        fit: StackFit.expand,
        children: [
          url.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(color: AppColors.surfaceVariant),
                  errorWidget: (_, __, ___) => _fallback(),
                )
              : _fallback(),
          // Bottom gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.5),
                ],
                stops: const [0.5, 1.0],
              ),
            ),
          ),
        ],
      );

  Widget _fallback() => Container(
        color: AppColors.primary.withOpacity(0.1),
        child: Center(
          child: Icon(Icons.article_outlined,
              size: 80, color: AppColors.primary.withOpacity(0.3)),
        ),
      );
}

// ── Category pill ──────────────────────────────────────────────────────────────

class _CategoryPill extends StatelessWidget {
  final String category;
  final bool bo;
  const _CategoryPill({required this.category, required this.bo});

  static const _bg = {
    'teachings':      Color(0xFFE8F4FD),
    'lineage':        Color(0xFFF3E8FD),
    'announcements':  Color(0xFFFDF6E3),
  };
  static const _fg = {
    'teachings':      Color(0xFF1565C0),
    'lineage':        Color(0xFF6A1B9A),
    'announcements':  Color(0xFF8B6000),
  };

  String _label() {
    if (!bo) {
      switch (category) {
        case 'teachings':     return 'TEACHINGS';
        case 'lineage':       return 'LINEAGE';
        case 'announcements': return 'ANNOUNCEMENTS';
        default:              return category.toUpperCase();
      }
    }
    switch (category) {
      case 'teachings':     return 'ཆོས།';
      case 'lineage':       return 'བཀའ་བརྒྱུད།';
      case 'announcements': return 'བསྒྲགས་བྱ།';
      default:              return category;
    }
  }

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: _bg[category] ?? AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          _label(),
          style: TextStyle(
            color: _fg[category] ?? AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: bo ? 0 : 0.5,
          ),
        ),
      );
}

// ── Not found ──────────────────────────────────────────────────────────────────

class _NotFound extends StatelessWidget {
  final VoidCallback onBack;
  const _NotFound({required this.onBack});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              onPressed: onBack),
          backgroundColor: AppColors.surface,
          elevation: 0,
        ),
        body: Center(
          child: Text('Article not found',
              style: AppTextStyles.bodyMedium),
        ),
      );
}
