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
import 'package:bazari_8656/data/models.dart' show Product; // ← مدل قدیمی
import 'package:bazari_8656/features/home/widgets/product_card.dart';
import 'package:bazari_8656/features/home/widgets/category_chip_bar.dart';
import 'package:bazari_8656/features/home/widgets/home_filter_sheet.dart';
import 'package:bazari_8656/common/widgets/horizontal_chips.dart';

// آیکن چت با Badge
import 'package:bazari_8656/features/chat/widgets/chat_badge_action.dart';

// صفحه محصول (مدل جدید)
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

  final VisionAi _ai = VisionAiMobile();
  bool _imgSearching = false;

  final List<Product> _items = <Product>[]; // مدل قدیمی
  bool _loading = false;
  bool _hasMore = true;
  int _page = 1;

  String? _categoryId;
  String _query = '';
  double? _minPrice;
  double? _maxPrice;
  SortMode _sort = SortMode.newest;
  bool _onlyAvailable = false;

  final List<String> _suggestions = <String>[];
  Timer? _debounce;
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
    _scroll.dispose();
    _searchCtl.dispose();
    super.dispose();
  }

  /* --------------------------- Fetch/Paging --------------------------- */

  Future<void> _refresh({bool first = false}) async {
    setState(() {
      _loading = true;
      _hasMore = true;
      _page = 1;
      _items.clear();
    });
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
    return base;
  }

  /* ---------------------- Helpers ---------------------- */

  String _resolveCurrentUserId() {
    try {
      final a = AuthService.instance as dynamic;
      if (a.currentUserId != null) return a.currentUserId;
      if (a.userId != null) return a.userId;
      if (a.uid != null) return a.uid;
      if (a.currentUser?.uid != null) return a.currentUser.uid;
    } catch (_) {}
    return 'guest';
  }

  /// مبدل دیتامدل → مدل فیچر
  fp.Product _toFeatureProduct(Product p) {
    final img = (p.imageUrl ?? '').trim();
    return fp.Product(
      id: p.id,
      title: p.title,
      price: p.price,
      currency: p.currency,
      images: img.isEmpty ? const [] : [img],
      categoryId: p.categoryId ?? 'misc',
      createdAt: p.createdAt,
      seller: fp.Seller(
        id: p.sellerId ?? 'unknown',
        name: p.sellerName ?? 'Seller',
        avatarUrl: p.sellerAvatarUrl,
      ),
    );
  }

  /* -------------------------- UI -------------------------- */

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final t = AppLang.instance.t;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(t('search')),
        actions: const [ChatBadgeAction()],
      ),
      body: _items.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.72,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _items.length,
              itemBuilder: (ctx, i) {
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
                  child: ProductCard(p: p),
                );
              },
            ),
    );
  }
}
