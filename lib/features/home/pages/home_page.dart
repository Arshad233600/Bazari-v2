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
import 'package:bazari_8656/features/product/pages/product_view_page.dart';

// داده‌ها و ویجت‌ها
import 'package:bazari_8656/app/i18n/i18n.dart';
import 'package:bazari_8656/data/products_repository.dart';
import 'package:bazari_8656/data/mock_data.dart' as mock;
import 'package:bazari_8656/data/models.dart';
import 'package:bazari_8656/features/home/widgets/product_card.dart';
import 'package:bazari_8656/features/home/widgets/category_chip_bar.dart';
import 'package:bazari_8656/features/home/widgets/home_filter_sheet.dart';
import 'package:bazari_8656/common/widgets/horizontal_chips.dart';

// آیکن چت با Badge
import 'package:bazari_8656/features/chat/widgets/chat_badge_action.dart';

// نسخه جدید Product
import 'package:bazari_8656/features/product/models/product.dart' as fp;

import '../../product/pages/product_view_page.dart' as pv;

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
    _searchCtl.addListener(() => setState(() {}));
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

  /* -------------------------- Helpers -------------------------- */

  /// UID کاربر
  String _resolveCurrentUserId() {
    try {
      final a = AuthService.instance as dynamic;
      try {
        final v = a.currentUserId;
        if (v is String && v.isNotEmpty) return v;
      } catch (_) {}
      try {
        final v = a.userId;
        if (v is String && v.isNotEmpty) return v;
      } catch (_) {}
      try {
        final v = a.uid;
        if (v is String && v.isNotEmpty) return v;
      } catch (_) {}
      try {
        final v = a.currentUser?.uid;
        if (v is String && v.isNotEmpty) return v;
      } catch (_) {}
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
      description: p.description ?? '',
      keywords: const <String>[],
      details: const <String, dynamic>{},
      similar: const <fp.Product>[],
    );
  }

  /* --------------------------------- UI ---------------------------------- */

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final t = AppLang.instance.t;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: const Text("بازاری"),
        actions: const [ChatBadgeAction()],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: CustomScrollView(
          controller: _scroll,
          slivers: [
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
          ],
        ),
      ),
    );
  }
}
