import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../app/router/route_names.dart';
import '../../domain/entities/news_post_entity.dart';
import '../controllers/news_controller.dart';

class NewsScreen extends ConsumerStatefulWidget {
  const NewsScreen({super.key});
  @override
  ConsumerState<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends ConsumerState<NewsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  static const _tabs = ['latest', 'teachings', 'lineage', 'announcements'];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bo = ref.watch(languageProvider);
    String s(String en, String tib) => bo ? tib : en;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerScrolled) => [
          SliverAppBar(
            pinned: true,
            floating: true,
            backgroundColor: AppColors.surface,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            automaticallyImplyLeading: false,
            titleSpacing: 16,
            title: Text(s('News', 'གསར་འགྱུར།'), style: AppTextStyles.headlineMedium),
            bottom: TabBar(
              controller: _tab,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textMuted,
              indicatorColor: AppColors.primary,
              indicatorSize: TabBarIndicatorSize.label,
              dividerColor: AppColors.border,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w400, fontSize: 13),
              tabs: [
                Tab(text: s('Latest', 'གསར་ཤོས།')),
                Tab(text: s('Teachings', 'ཆོས།')),
                Tab(text: s('Lineage', 'བཀའ་བརྒྱུད།')),
                Tab(text: s('Announcements', 'བསྒྲགས་བྱ།')),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tab,
          children: _tabs.map((tabKey) => _NewsTab(
            tabKey: tabKey,
            bo: bo,
          )).toList(),
        ),
      ),
    );
  }
}

// ── Tab body ──────────────────────────────────────────────────────────────────

class _NewsTab extends ConsumerWidget {
  final String tabKey;
  final bool bo;
  const _NewsTab({required this.tabKey, required this.bo});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLatest = tabKey == 'latest';
    final async = isLatest
        ? ref.watch(newsListProvider)
        : ref.watch(newsByCategoryProvider(tabKey));

    return async.when(
      loading: () => const AppLoading(),
      error: (e, _) => _ErrorView(message: e.toString()),
      data: (posts) {
        if (posts.isEmpty) return _EmptyView(bo: bo);
        if (isLatest) return _LatestList(posts: posts, bo: bo);
        return _CategoryList(posts: posts, bo: bo);
      },
    );
  }
}

// ── Latest tab: featured card + list ─────────────────────────────────────────

class _LatestList extends StatelessWidget {
  final List<NewsPostEntity> posts;
  final bool bo;
  const _LatestList({required this.posts, required this.bo});

  @override
  Widget build(BuildContext context) {
    final featured = posts.first;
    final rest = posts.skip(1).toList();

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _FeaturedCard(post: featured, bo: bo),
        if (rest.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
            child: Text(
              bo ? 'གསར་འགྱུར་གཞན།' : 'More News',
              style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.textSecondary, letterSpacing: 0.3),
            ),
          ),
          ...rest.map((p) => _NewsTile(post: p, bo: bo)),
        ],
        const SizedBox(height: 32),
      ],
    );
  }
}

// ── Category tab: simple list ─────────────────────────────────────────────────

class _CategoryList extends StatelessWidget {
  final List<NewsPostEntity> posts;
  final bool bo;
  const _CategoryList({required this.posts, required this.bo});

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.only(top: 12, bottom: 32),
        children: posts.map((p) => _NewsTile(post: p, bo: bo)).toList(),
      );
}

// ── Featured card ─────────────────────────────────────────────────────────────

class _FeaturedCard extends StatelessWidget {
  final NewsPostEntity post;
  final bool bo;
  const _FeaturedCard({required this.post, required this.bo});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(RouteNames.newsDetailOf(post.id)),
      child: Container(
        margin: const EdgeInsets.all(16),
        height: 240,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Hero image
              _NewsImage(url: post.imageUrl, fit: BoxFit.cover),

              // Gradient
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.8),
                    ],
                    stops: const [0.35, 1.0],
                  ),
                ),
              ),

              // Category badge + title
              Positioned(
                left: 16, right: 16, bottom: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _CategoryBadge(category: post.category, bo: bo),
                    const SizedBox(height: 8),
                    Text(
                      post.title(bo),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        height: 1.3,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(children: [
                      const Icon(Icons.person_outline,
                          color: Colors.white60, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        post.author,
                        style: const TextStyle(color: Colors.white60, fontSize: 11),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.access_time,
                          color: Colors.white60, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(post.publishedAt, bo),
                        style: const TextStyle(color: Colors.white60, fontSize: 11),
                      ),
                    ]),
                  ],
                ),
              ),

              // "FEATURED" tag
              Positioned(
                top: 12, right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.gold,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    bo ? 'གལ་ཆེ།' : 'FEATURED',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── News tile (compact list item) ─────────────────────────────────────────────

class _NewsTile extends StatelessWidget {
  final NewsPostEntity post;
  final bool bo;
  const _NewsTile({required this.post, required this.bo});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(RouteNames.newsDetailOf(post.id)),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8, offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(children: [
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: _NewsImage(url: post.imageUrl, width: 76, height: 76, fit: BoxFit.cover),
          ),
          const SizedBox(width: 12),

          // Text
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CategoryBadge(category: post.category, bo: bo, small: true),
              const SizedBox(height: 5),
              Text(
                post.title(bo),
                style: AppTextStyles.titleMedium.copyWith(
                    fontSize: 13, fontWeight: FontWeight.w700),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 5),
              Text(
                post.excerpt(bo),
                style: AppTextStyles.bodySmall.copyWith(fontSize: 11, height: 1.4),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 5),
              Text(
                _formatDate(post.publishedAt, bo),
                style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textMuted, fontSize: 10),
              ),
            ],
          )),

          const Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
        ]),
      ),
    );
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────

class _CategoryBadge extends StatelessWidget {
  final String category;
  final bool bo;
  final bool small;
  const _CategoryBadge({required this.category, required this.bo, this.small = false});

  static const _colors = {
    'teachings':      Color(0xFFE8F4FD),
    'lineage':        Color(0xFFF3E8FD),
    'announcements':  Color(0xFFFDF6E3),
  };
  static const _textColors = {
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
        padding: EdgeInsets.symmetric(
            horizontal: small ? 7 : 10, vertical: small ? 2 : 3),
        decoration: BoxDecoration(
          color: _colors[category] ?? AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          _label(),
          style: TextStyle(
            color: _textColors[category] ?? AppColors.textSecondary,
            fontSize: small ? 9 : 10,
            fontWeight: FontWeight.w700,
            letterSpacing: bo ? 0 : 0.3,
          ),
        ),
      );
}

class _NewsImage extends StatelessWidget {
  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  const _NewsImage({required this.url, this.width, this.height, this.fit = BoxFit.cover});

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) return _placeholder();
    return CachedNetworkImage(
      imageUrl: url,
      width: width,
      height: height,
      fit: fit,
      placeholder: (_, __) => _placeholder(),
      errorWidget: (_, __, ___) => _placeholder(),
    );
  }

  Widget _placeholder() => Container(
        width: width,
        height: height,
        color: AppColors.surfaceVariant,
        child: Center(
          child: Icon(Icons.article_outlined,
              color: AppColors.textMuted.withOpacity(0.5),
              size: (width ?? 40) * 0.5),
        ),
      );
}

class _EmptyView extends StatelessWidget {
  final bool bo;
  const _EmptyView({required this.bo});
  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.article_outlined,
                size: 56, color: AppColors.textMuted.withOpacity(0.4)),
            const SizedBox(height: 12),
            Text(
              bo ? 'གསར་འགྱུར་མེད།' : 'No news yet',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
      );
}

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined,
                  size: 48, color: AppColors.textMuted),
              const SizedBox(height: 12),
              Text('Could not load news',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted)),
              const SizedBox(height: 8),
              Text(
                message,
                style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textMuted, fontSize: 11),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
}

String _formatDate(DateTime? dt, bool bo) {
  if (dt == null) return '';
  const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${months[dt.month]} ${dt.day}, ${dt.year}';
}
