// lib/data/products_repository.dart
import 'dart:math';
import 'package:bazari_8656/data/models.dart';
import 'package:bazari_8656/data/categories.dart' as cat show CategorySpec, flattenCategories;

class ProductsRepository {
  const ProductsRepository();

  /// صفحه محصولات ماک بر اساس کتگوری (اگر null باشد، متفرقه)
  Future<List<Product>> fetchPage({required int page, String? categoryId}) async {
    await Future.delayed(const Duration(milliseconds: 200));

    final cat.CategorySpec? spec = categoryId != null ? _findCategory(categoryId) : null;

    final rng = Random(_seedFrom(categoryId, page));
    const int count = 12;
    final List<Product> out = [];

    for (int i = 0; i < count; i++) {
      final id = '${categoryId ?? 'misc'}_${page}_$i';
      final title = _autoTitle(spec, i);
      final price = _autoPrice(spec, rng);

      out.add(Product(
        id: id,
        title: title,
        price: double.parse(price.toStringAsFixed(2)),
        currency: 'CHF',
        imageUrl: 'https://picsum.photos/seed/$id/800/600',
        createdAt: DateTime.now().subtract(Duration(days: rng.nextInt(180))),
        sellerId: 's_${rng.nextInt(10000)}',
        sellerName: 'Seller ${rng.nextInt(999)}',
        sellerAvatarUrl: 'https://i.pravatar.cc/64?u=$id',
        categoryId: categoryId ?? 'misc',
      ));
    }
    return out;
  }

  /// جستجوی «هوشمند» ساده: چند کتگوری مرتبط + فیلتر روی عنوان
  Future<List<Product>> searchSmart(String query) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return <Product>[];

    // کتگوری‌هایی که با کوئری مچ می‌شوند را در اولویت می‌آوریم
    final allCats = cat.flattenCategories().toList();
    final matchedCats = allCats.where((c) {
      final t = c.title.toLowerCase();
      final id = c.id.toLowerCase();
      return t.contains(q) || id.contains(q);
    }).toList();

    // اگر هیچ کتگوری خاصی نخورد، از چند کتگوری اول استفاده می‌کنیم
    final searchCats = (matchedCats.isNotEmpty ? matchedCats : allCats.take(8)).toList();

    // یک پُل از محصولات به‌صورت ماک
    final pool = <Product>[];
    for (final c in searchCats.take(10)) {
      final items = await fetchPage(page: 1, categoryId: c.id);
      pool.addAll(items);
    }

    // فیلتر عنوان
    final res = pool.where((p) => p.title.toLowerCase().contains(q)).toList();

    // اگر هیچ عنوانی نخورد، خود پُل را برگردان (که حداقل چیزی نشان بدهد)
    return res.isNotEmpty ? res : pool.take(20).toList();
  }

  /// ساجست کوتاه برای نوار پیشنهاد
  Future<List<String>> suggest(String query, {int limit = 10}) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return <String>[];

    final out = <String>{};

    // از کتگوری‌ها
    for (final c in cat.flattenCategories()) {
      final t = c.title.trim();
      if (t.toLowerCase().contains(q)) {
        out.add(t);
        if (out.length >= limit) break;
      }
    }

    // از عناوین محصولات (با استفاده از searchSmart)
    if (out.length < limit) {
      final products = await searchSmart(query);
      for (final p in products) {
        final t = p.title.trim();
        if (t.toLowerCase().contains(q)) {
          out.add(t);
          if (out.length >= limit) break;
        }
      }
    }

    return out.take(limit).toList();
  }

  // ------------------------ Helpers ------------------------

  int _seedFrom(String? catId, int page) {
    final s = '${catId ?? 'misc'}_$page';
    return s.codeUnits.fold<int>(0, (a, b) => (a * 31 + b) & 0x7fffffff);
    // ^ مقدار ثابت‌زا برای تکرارپذیری نتایج ماک
  }

  cat.CategorySpec? _findCategory(String id) {
    for (final c in cat.flattenCategories()) {
      if (c.id == id) return c;
    }
    return null;
  }

  String _autoTitle(cat.CategorySpec? c, int i) {
    if (c == null) return 'Item ${i + 1}';
    final base = c.title.isNotEmpty ? c.title : 'Item';
    // کمی تنوع ظاهری در عنوان‌ها
    switch ((i % 5)) {
      case 0: return '$base ${i + 1}';
      case 1: return '$base — مدل ${100 + i}';
      case 2: return '$base سری ${String.fromCharCode(65 + (i % 26))}';
      case 3: return '$base نسخه ${2020 + (i % 6)}';
      default: return '$base Special';
    }
  }

  double _autoPrice(cat.CategorySpec? c, Random rng) {
    if (c == null) return 20 + rng.nextDouble() * 800;

    bool like(String s) {
      final t = c.title.toLowerCase();
      final id = c.id.toLowerCase();
      return t.contains(s) || id.contains(s);
    }

    if (like('car') || like('vehicle') || like('auto') || like('motor')) {
      return 1500 + rng.nextDouble() * 30000;
    }
    if (like('phone') || like('mobile') || like('موبایل')) {
      return 120 + rng.nextDouble() * 1300;
    }
    if (like('laptop') || like('notebook') || like('لپ') || like('کامپیوتر')) {
      return 300 + rng.nextDouble() * 2200;
    }
    if (like('tv') || like('تلویزیون') || like('monitor')) {
      return 180 + rng.nextDouble() * 1600;
    }
    if (like('furniture') || like('مبل') || like('صندلی') || like('میز')) {
      return 60 + rng.nextDouble() * 900;
    }
    if (like('appliance') || like('خانگی') || like('یخچال') || like('لباسشویی')) {
      return 80 + rng.nextDouble() * 1200;
    }
    if (like('fashion') || like('لباس') || like('کفش') || like('کیف')) {
      return 15 + rng.nextDouble() * 250;
    }
    return 20 + rng.nextDouble() * 900;
  }
}
