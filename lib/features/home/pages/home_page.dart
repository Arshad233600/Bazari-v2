// lib/features/home/pages/home_page.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// جستجوی تصویری
import 'package:image_picker/image_picker.dart';
import 'package:bazari_8656/features/product/ai/vision.dart';

// سرویس‌ها و صفحات
import 'package:bazari_8656/core/services/auth_service.dart';
import 'package:bazari_8656/features/account/pages/user_dashboard_page.dart';
import 'package:bazari_8656/features/product/pages/add_product_manual_page.dart';
import 'package:bazari_8656/features/product/pages/add_product_ai_page.dart';

// داده‌ها و ویجت‌ها
import 'package:bazari_8656/app/i18n/i18n.dart';
import 'package:bazari_8656/data/products_repository.dart';
import 'package:bazari_8656/data/mock_data.dart' as mock;
import 'package:bazari_8656/data/models.dart'; // Product (قدیمی) + SortMode
import 'package:bazari_8656/features/home/widgets/product_card.dart';
import 'package:bazari_8656/features/home/widgets/category_chip_bar.dart';
import 'package:bazari_8656/features/home/widgets/home_filter_sheet.dart';
import 'package:bazari_8656/common/widgets/horizontal_chips.dart';

// آیکن چت با Badge
import 'package:bazari_8656/features/chat/widgets/chat_badge_action.dart';

// صفحهٔ محصول و مدل جدید
import '../../product/pages/product_view_page.dart' as pv;
import 'package:bazari_8656/features/product/models/product.dart' as fp;

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with AutomaticKeepAliveClientMixin<HomePage> {
  @override
  bool get wantKeepAlive => true;

  final _repo = const ProductsRepository();
  final _scroll = ScrollController();
  final _searchCtl = TextEditingController();

  // AI برای جستجوی تصویری
  final VisionAi _ai = VisionAiMobile();
  bool _imgSearching = false;

  final List<Product> _items = <Product>[];
  bool _loading = false;
  bool _hasMore = true;
  int _page = 1;

  String? _categoryId;
  String _query = '';
  double? _minPrice;
  double? _maxPrice;
  SortMode _sort = SortMode.newest;
  bool _onlyAvailable = false;

  // پیشنهادها + دیباونس
  final List<String> _suggestions = <String>[];
  Timer? _debounce;

  // back-to-top
  bool _showBackToTop = false;

  @override
  void initState() {
    super.initState();
    _loadPersistedFilters();
    _scroll.addListener(_onScroll);
    _scroll.addListener(_onScrollForBackTop);
    _searchCtl.addListener(() => setState(() {})); // نمایش/عدم نمایش clear
    _refresh(first: true);
  }

  @override
  void dispose() {
    _ai.dispose();
    _debounce?.cancel();
    _scroll.removeListener(_onScroll);
    _scroll.removeListener(_onScrollForBackTop);
    _scroll.dispose();
    _searchCtl.dispose();
    super.dispose();
  }

  /* ------------------------ Persist filters ------------------------ */

  Future<void> _loadPersistedFilters() async {
    final p = await SharedPreferences.getInstance();
    setState(() {
      _query = p.getString('home_query') ?? '';
      _searchCtl.text = _query;
      _categoryId = p.getString('home_cat');
      _minPrice = p.getDouble('home_min_price');
      _maxPrice = p.getDouble('home_max_price');
      final idx = (p.getInt('home_sort') ?? 0);
      _sort = SortMode.values[idx.clamp(0, SortMode.values.length - 1)];
      _onlyAvailable = p.getBool('home_only_avail') ?? false;
    });
  }

  Future<void> _persistFilters() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('home_query', _query);
    if (_categoryId == null) {
      await p.remove('home_cat');
    } else {
      await p.setString('home_cat', _categoryId!);
    }
    if (_minPrice == null) {
      await p.remove('home_min_price');
    } else {
      await p.setDouble('home_min_price', _minPrice!);
    }
    if (_maxPrice == null) {
      await p.remove('home_max_price');
    } else {
      await p.setDouble('home_max_price', _maxPrice!);
    }
    await p.setInt('home_sort', _sort.index);
    await p.setBool('home_only_avail', _onlyAvailable);
  }

  /* --------------------------- Paging --------------------------- */

  void _onScroll() {
    if (_scroll.position.pixels >
            _scroll.position.maxScrollExtent - 300 &&
        !_loading &&
        _hasMore) {
      _loadMore();
    }
  }

  void _onScrollForBackTop() {
    final show = _scroll.hasClients && _scroll.offset > 600;
    if (show != _showBackToTop) {
      setState(() => _showBackToTop = show);
    }
  }

  Future<void> _refresh({bool first = false}) async {
    setState(() {
      _loading = true;
      _hasMore = true;
      _page = 1;
      _items.clear();
    });
    await _persistFilters();
    try {
      final list = await _fetch();
      if (!mounted) return;
      setState(() {
        _items.addAll(list);
        _loading = false;
        _hasMore = list.isNotEmpty;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('خطا در بارگذاری: $e')));
    }
  }

  Future<void> _loadMore() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _page += 1;
    });
    try {
      final list = await _fetch();
      if (!mounted) return;
      setState(() {
        _items.addAll(list);
        _loading = false;
        if (list.isEmpty) _hasMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('خطا در صفحه بعد: $e')));
    }
  }

  Future<List<Product>> _fetch() async {
    List<Product> base;
    if (_query.trim().isNotEmpty) {
      base = await _repo.searchSmart(_query.trim());
    } else {
      base = await _repo.fetchPage(page: _page, categoryId: _categoryId);
    }

    base = base.where((p) {
      final okCat = _categoryId == null || p.categoryId == _categoryId;
      final pr = p.price;
      final okMin = _minPrice == null || pr >= _minPrice!;
      final okMax = _maxPrice == null || pr <= _maxPrice!;
      return okCat && okMin && okMax;
    }).toList();

    switch (_sort) {
      case SortMode.newest:
        base.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case SortMode.priceLow:
        base.sort((a, b) => a.price.compareTo(b.price));
        break;
      case SortMode.priceHigh:
        base.sort((a, b) => b.price.compareTo(a.price));
        break;
      case SortMode.random:
        base.shuffle();
        break;
    }
    return base;
  }

  /* --------------------- Live search (debounce) --------------------- */

  void _onQueryChanged(String text) {
    _debounce?.cancel();
    setState(() {
      _query = text;
      _categoryId = null; // هنگام سرچ زنده، فیلتر کتگوری کنار گذاشته شود
      _loading = true;
    });

    if (text.trim().isEmpty) {
      _suggestions.clear();
      _hasMore = true;
      _page = 1;
      _refresh();
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 250), () async {
      final q = text.trim();
      final results = await _repo.searchSmart(q);
      final sugg = await _repo.suggest(q, limit: 10);
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(results);
        _hasMore = false; // نتایج زنده صفحه‌بندی نمی‌شود
        _loading = false;

        _suggestions
          ..clear()
          ..addAll(sugg);
      });
    });
  }

  /* -------------------------- Filters / chips -------------------------- */

  Future<void> _openFilters() async {
    final res = await showModalBottomSheet<HomeFilterState>(
      context: context,
      isScrollControlled: true,
      builder: (_) => HomeFilterSheet(
        initial: HomeFilterState(
          query: _query,
          categoryId: _categoryId,
          minPrice: _minPrice,
          maxPrice: _maxPrice,
          sort: _sort,
          onlyAvailable: _onlyAvailable,
        ),
      ),
    );
    if (res != null) {
      setState(() {
        _query = res.query ?? '';
        _searchCtl.text = _query;
        _categoryId = res.categoryId;
        _minPrice = res.minPrice;
        _maxPrice = res.maxPrice;
        _sort = res.sort;
        _onlyAvailable = res.onlyAvailable;
      });
      await _refresh();
    }
  }

  Future<void> _onSearchSubmit(String text) async {
    _onQueryChanged(text);
  }

  void _onCategoryTap(mock.CategorySpec? cat) async {
    setState(() => _categoryId = cat?.id);
    await _refresh();
  }

  /* ------------------------- Helpers ------------------------- */

  String _pickImageUrl(Map<String, dynamic> it, String fallback) {
    final imgs = it['images'];
    if (imgs is List && imgs.isNotEmpty) {
      final first = imgs.first;
      if (first is String && first.trim().isNotEmpty) return first.trim();
      if (first is List<int> && first.isNotEmpty) {
        final b64 = base64Encode(first);
        return 'data:image/jpeg;base64,$b64';
      }
    }
    final u1 = it['imageUrl'];
    if (u1 is String && u1.trim().isNotEmpty) return u1.trim();
    final b64 = it['imageBase64'];
    if (b64 is String && b64.trim().isNotEmpty) {
      final s = b64.trim();
      return s.startsWith('data:') ? s : 'data:image/jpeg;base64,$s';
    }
    final photos = it['photos'];
    if (photos is List && photos.isNotEmpty && photos.first is String) {
      final s = (photos.first as String).trim();
      if (s.isNotEmpty) return s;
    }
    return fallback;
  }

  void _prependNewItem(Map<String, dynamic> item) {
    final id =
        (item['id'] ?? DateTime.now().millisecondsSinceEpoch.toString())
            .toString();
    final title = (item['title'] ?? 'New Item').toString();
    final priceRaw = item['price'];
    final price = priceRaw is num
        ? priceRaw.toDouble()
        : double.tryParse('$priceRaw') ?? 0.0;
    final cat = (item['categoryId'] ?? _categoryId ?? 'misc').toString();
    final createdAt = (item['createdAt'] is DateTime)
        ? (item['createdAt'] as DateTime)
        : DateTime.now();

    final img = _pickImageUrl(item, 'https://picsum.photos/seed/$id/800/600');

    final product = Product(
      id: id,
      title: title,
      price: price,
      currency: 'CHF',
      imageUrl: img,
      createdAt: createdAt,
      sellerId: 'local_seller',
      sellerName: 'Seller',
      sellerAvatarUrl: 'https://i.pravatar.cc/64?u=$id',
      categoryId: cat,
    );

    setState(() => _items.insert(0, product));
    _scroll.animateTo(0,
        duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  /* ----------------------- جستجو با عکس ----------------------- */

  Future<void> _searchByImage() async {
    if (_imgSearching) return;

    final source = await showModalBottomSheet<String>(
      context: context,
      builder: (c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('عکس با دوربین'),
              onTap: () => Navigator.pop(c, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('انتخاب از گالری'),
              onTap: () => Navigator.pop(c, 'gallery'),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    final picker = ImagePicker();
    XFile? file;
    if (source == 'camera') {
      file = await picker.pickImage(
          source: ImageSource.camera, imageQuality: 85, maxWidth: 2000);
    } else {
      file = await picker.pickImage(
          source: ImageSource.gallery, imageQuality: 85, maxWidth: 2000);
    }
    if (file == null) return;

    setState(() => _imgSearching = true);
    try {
      final labels = await _ai.labelImageFile(file.path);
      if (labels.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'جستجوی تصویری روی این پلتفرم در دسترس نیست. لطفاً متن وارد کنید.')));
        return;
      }
      final query = labels.take(3).join(' ');
      _searchCtl.text = query;
      _onQueryChanged(query);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('خطا در جستجوی تصویری: $e')));
    } finally {
      if (mounted) setState(() => _imgSearching = false);
    }
  }

  /* --------------------------------- UI ---------------------------------- */

  @override
  Widget build(BuildContext context) {
    super.build(context); // ← برای KeepAlive
    final t = AppLang.instance.t;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  margin:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: cs.surfaceVariant.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchCtl,
                          textInputAction: TextInputAction.search,
                          onSubmitted: _onSearchSubmit,
                          onChanged: _onQueryChanged, // ← جستجوی زنده
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: t('search'),
                          ),
                        ),
                      ),
                      if (_searchCtl.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          tooltip: 'پاک‌کردن',
                          onPressed: () {
                            _searchCtl.clear();
                            _onQueryChanged(''); // بازگشت به فید
                          },
                        ),
                      IconButton(
                        tooltip: 'جستجو با عکس',
                        onPressed: _imgSearching ? null : _searchByImage,
                        icon: _imgSearching
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.camera_alt_outlined),
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                onPressed: _openFilters,
                icon: const Icon(Icons.filter_list),
                tooltip: t('category'),
              ),
            ],
          ),
        ),
        actions: [
          PopupMenuButton<Locale>(
            tooltip: AppLang.instance.t('language'),
            icon: const Icon(Icons.translate),
            onSelected: (locale) {
              AppLang.instance.setLocale(locale);
              setState(() {}); // ریفرش همین صفحه
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: Locale('fa', 'AF'), child: Text('دری')),
              PopupMenuItem(value: Locale('ps', 'AF'), child: Text('پښتو')),
              PopupMenuItem(value: Locale('de', 'DE'), child: Text('Deutsch')),
              PopupMenuItem(value: Locale('en', 'US'), child: Text('English')),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: _refresh,
        child: CustomScrollView(
          key: const PageStorageKey('home_scroll'),
          controller: _scroll,
          slivers: [
            if (_suggestions.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _suggestions.map((s) {
                      return ActionChip(
                        label: Text(s,
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        onPressed: () {
                          _searchCtl.text = s;
                          _onQueryChanged(s);
                        },
                      );
                    }).toList(),
                  ),
                ),
              ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 8, right: 12, left: 12),
                child: HorizontalChips(
                  items: const ['همه', 'تازه‌ترین', 'پرفروش', 'پیشنهادی'],
                  onTap: (_) {},
                ),
              ),
            ),

            SliverPersistentHeader(
              pinned: true,
              delegate: _StickyHeaderDelegate(
                minHeight: 56,
                maxHeight: 56,
                child: Material(
                  color: Theme.of(context).colorScheme.surface,
                  elevation: 0.5,
                  child: CategoryChipBar(
                    onTap: _onCategoryTap,
                    selectedId: _categoryId,
                  ),
                ),
              ),
            ),

            if (_loading && _items.isEmpty) const _GridSkeleton(),

            if (_items.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.all(12),
                sliver: SliverGrid(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.72,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (c, i) {
                      final p = _items[i];
                      final vp = _toFeatureProduct(p);

                      return GestureDetector(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => pv.ProductViewPage(
                              p: vp,
                              currentUserId: _resolveCurrentUserId(),
                            ),
                          ),
                        ),
                        child: RepaintBoundary(child: ProductCard(p: p)),
                      );
                    },
                    childCount: _items.length,
                  ),
                ),
              ),

            if (!_loading && _items.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 48),
                  child: _EmptyState(onReset: null), // ساده‌سازی
                ),
              ),

            SliverToBoxAdapter(
              child: _loading && _items.isNotEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : const SizedBox.shrink(),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_add_center',
        onPressed: () async {
          final sel = await showModalBottomSheet<String>(
            context: context,
            builder: (c) => SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.edit_outlined),
                    title: Text(AppLang.instance.t('manual_add')),
                    onTap: () => Navigator.pop(c, 'manual'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.auto_awesome),
                    title: Text(AppLang.instance.t('ai_add')),
                    onTap: () => Navigator.pop(c, 'ai'),
                  ),
                ],
              ),
            ),
          );

          if (sel == 'manual') {
            final result =
                await Navigator.of(context).push<Map<String, dynamic>>(
              MaterialPageRoute(builder: (_) => const AddProductManualPage()),
            );
            if (result != null) _prependNewItem(result);
          } else if (sel == 'ai') {
            final aiResult =
                await Navigator.of(context).push<Map<String, dynamic>>(
              MaterialPageRoute(builder: (_) => const AddProductAiPage()),
            );
            if (aiResult != null) _prependNewItem(aiResult);
          }
        },
        tooltip: AppLang.instance.t('add'),
        child: const Icon(Icons.add, size: 28),
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: const _ProBottomBar(
        onChat: _noop,
        onDashboard: _noop,
      ),
    );
  }

  // ---------- Helpers: گرفتن UID و تبدیل مدل ----------

  String _resolveCurrentUserId() {
    try {
      final a = AuthService.instance as dynamic;
      try { final v = a.currentUserId;    if (v is String && v.isNotEmpty) return v; } catch (_) {}
      try { final v = a.userId;           if (v is String && v.isNotEmpty) return v; } catch (_) {}
      try { final v = a.uid;              if (v is String && v.isNotEmpty) return v; } catch (_) {}
      try { final v = a.currentUser?.uid; if (v is String && v.isNotEmpty) return v; } catch (_) {}
    } catch (_) {}
    return 'guest';
  }

  /// مبدل Product (data/models.dart) → Product (features/product/models/product.dart)
  fp.Product _toFeatureProduct(Product p) {
    final img = (p.imageUrl ?? '').toString().trim();
    return fp.Product(
      id: p.id,
      title: p.title,
      price: p.price,
      currency: p.currency,
      images: img.isEmpty ? const <String>[] : <String>[img],
      createdAt: p.createdAt,
      seller: fp.Seller(
        id: p.sellerId ?? 'unknown',
        name: p.sellerName ?? 'Seller',
        avatarUrl: p.sellerAvatarUrl,
      ),
      categoryId: p.categoryId ?? 'misc',
      description: '', // دیتامدل قدیمی description ندارد
      keywords: const <String>[],
      details: const <String, dynamic>{},
      similar: const <fp.Product>[],
    );
  }
}

/* ============================== ویجت‌های کمکی ============================== */

class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  _StickyHeaderDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  final double minHeight;
  final double maxHeight;
  final Widget child;

  @override
  double get minExtent => minHeight;
  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(covariant _StickyHeaderDelegate oldDelegate) {
    return minHeight != oldDelegate.minHeight ||
        maxHeight != oldDelegate.maxHeight ||
        child != oldDelegate.child;
  }
}

class _GridSkeleton extends StatelessWidget {
  const _GridSkeleton();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SliverPadding(
      padding: const EdgeInsets.all(12),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.72,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
        ),
        delegate: SliverChildBuilderDelegate(
          (c, i) {
            return _Shimmer(
              child: Container(
                decoration: BoxDecoration(
                  color: cs.surfaceVariant.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          },
          childCount: 8,
        ),
      ),
    );
  }
}

class _Shimmer extends StatefulWidget {
  const _Shimmer({required this.child});
  final Widget child;

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = Colors.grey.shade300;
    final highlight = Colors.grey.shade100;

    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = _c.value * 2 - 1; // -1 → 1
        final center = (t + 1) / 2; // 0 → 1
        const w = 0.20;

        final stop1 = (center - w).clamp(0.0, 1.0);
        final stop2 = center.clamp(0.0, 1.0);
        final stop3 = (center + w).clamp(0.0, 1.0);

        return ShaderMask(
          shaderCallback: (rect) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [base, highlight, base],
              stops: [stop1, stop2, stop3],
            ).createShader(rect);
          },
          blendMode: BlendMode.srcATop,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onReset});
  final VoidCallback? onReset;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Icon(Icons.search_off_rounded, size: 72, color: cs.onSurfaceVariant),
        const SizedBox(height: 12),
        const Text(
          'نتیجه‌ای پیدا نشد',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          'عبارت جستجو یا فیلترها را تغییر دهید.',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: cs.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: onReset,
          icon: const Icon(Icons.refresh),
          label: const Text('ریست فیلترها'),
        ),
      ],
    );
  }
}

/* ----------------------------- پاورقی حرفه‌ای ----------------------------- */

class _ProBottomBar extends StatelessWidget {
  const _ProBottomBar({
    required this.onChat,
    required this.onDashboard,
  });

  final VoidCallback onChat;
  final VoidCallback onDashboard;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return BottomAppBar(
      color: cs.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 6,
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: SizedBox(
        height: 60,
        child: Row(
          children: const [
            // چپ: داشبورد
            IconButton(
              tooltip: 'Dashboard',
              icon: Icon(Icons.person_outline),
              onPressed: _noop,
            ),
            Spacer(),
            SizedBox(width: 60), // notch
            Spacer(),
            // راست: چت (با Badge آماده)
            ChatBadgeAction(),
          ],
        ),
      ),
    );
  }
}

void _noop() {}
