import 'package:flutter/material.dart';
import '../../chat/pages/chat_room_page.dart';
import '../models/product.dart';

/// ProductView کامل و مستقل از بک‌اند.
/// - گالری تصاویر (Hero + PageView)
/// - عنوان/قیمت/توضیحات
/// - چیپ‌های کلیدواژه
/// - جزئیات پویا بر اساس دسته (house/car/phone/job)
/// - فروشنده + دکمهٔ چت
/// - محصولات مشابه (Horizontal)
/// - اکشن‌های لایک/پیام/گزارش/بلاک
class ProductViewPage extends StatelessWidget {
  const ProductViewPage({
    super.key,
    required this.product,
    required this.currentUserId,
  });

  final Product product;
  final String currentUserId;

  @override
  Widget build(BuildContext context) {
    final th = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(product.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: 'اشتراک‌گذاری',
            icon: const Icon(Icons.share_outlined),
            onPressed: () => _share(context),
          ),
          PopupMenuButton<String>(
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'report', child: Text('گزارش')),
              PopupMenuItem(value: 'block', child: Text('بلاک فروشنده')),
            ],
            onSelected: (v) {
              if (v == 'report') _report(context);
              if (v == 'block') _block(context);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // اگر خواستی به دیتابیس وصل کنی، اینجا refresh کن.
          await Future.delayed(const Duration(milliseconds: 700));
        },
        child: ListView(
          children: [
            // === Gallery ===
            AspectRatio(
              aspectRatio: 1,
              child: PageView.builder(
                itemCount: product.images.length,
                itemBuilder: (context, i) {
                  final url = product.images[i];
                  return Hero(
                    tag: '${product.id}_img_$i',
                    child: Image.network(url, fit: BoxFit.cover),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // === Title + Price ===
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                product.title,
                style: th.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
              child: Text(
                _fmtPrice(product.price, product.currency),
                style: th.textTheme.titleLarge?.copyWith(
                  color: th.colorScheme.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),

            // === Keyword chips ===
            if (product.keywords.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: -8,
                  children: product.keywords.map((k) {
                    return ActionChip(
                      label: Text(k),
                      onPressed: () {
                        // TODO: جستجوی محصولات مشابه با این کلیدواژه
                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(content: Text('جستجو: $k')));
                      },
                    );
                  }).toList(),
                ),
              ),

            const Divider(height: 24),

            // === Description ===
            if (product.description.trim().isNotEmpty)
              _Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(product.description, style: th.textTheme.bodyMedium),
                ),
              ),

            // === Dynamic Details by Category ===
            if (product.details.isNotEmpty)
              _Card(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: _DetailsSection(
                  categoryId: product.categoryId,
                  details: product.details,
                ),
              ),

            // === Seller / Profile / Chat ===
            _Card(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                leading: CircleAvatar(
                  radius: 22,
                  backgroundImage: (product.seller.avatarUrl != null &&
                          product.seller.avatarUrl!.trim().isNotEmpty)
                      ? NetworkImage(product.seller.avatarUrl!)
                      : null,
                  child: (product.seller.avatarUrl == null ||
                          product.seller.avatarUrl!.trim().isEmpty)
                      ? Text(product.seller.name.characters.first.toUpperCase())
                      : null,
                ),
                title: Text(product.seller.name,
                    style: th.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                subtitle: const Text('فعال'), // TODO: آخرین وضعیت آنلاین
                trailing: OutlinedButton.icon(
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('چت'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatRoomPage(
                          chatId: product.seller.id, // chatId را sellerId درنظر گرفتیم
                          meId: currentUserId,
                          peerTitle: product.seller.name,
                        ),
                      ),
                    );
                  },
                ),
                onTap: () {
                  // TODO: Navigator.push به SellerProfilePage اگر صفحهٔ پروفایل دارید
                },
              ),
            ),

            // === Similar Products ===
            if (product.similar.isNotEmpty)
              _Card(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('محصولات مشابه',
                          style: th.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 168,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: product.similar.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemBuilder: (context, i) {
                            final p = product.similar[i];
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ProductViewPage(
                                      product: p,
                                      currentUserId: currentUserId,
                                    ),
                                  ),
                                );
                              },
                              child: SizedBox(
                                width: 132,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: AspectRatio(
                                        aspectRatio: 1,
                                        child: Image.network(p.images.first, fit: BoxFit.cover),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(p.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: th.textTheme.bodyMedium),
                                    Text(
                                      _fmtPrice(p.price, p.currency),
                                      style: th.textTheme.bodySmall
                                          ?.copyWith(color: th.colorScheme.primary),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 8),

            // === Actions ===
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.favorite_border),
                      label: const Text('پسندیدن'),
                      onPressed: () {
                        // TODO: اتصال Like به Firestore/Repository
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('محصول لایک شد')),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.chat),
                      label: const Text('پیام به فروشنده'),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatRoomPage(
                              chatId: product.seller.id,
                              meId: currentUserId,
                              peerTitle: product.seller.name,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _fmtPrice(double v, String cur) {
    // ساده: می‌توانی به PriceFormatter پروژه‌ات وصل کنی
    return '${v.toStringAsFixed(2)} $cur';
  }

  void _share(BuildContext context) {
    // TODO: share_plus
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('لینک محصول به اشتراک گذاشته شد')),
    );
  }

  void _report(BuildContext context) {
    // TODO: Firestore reports
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('گزارش ارسال شد')),
    );
  }

  void _block(BuildContext context) {
    // TODO: BlocklistController
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('فروشنده بلاک شد')),
    );
  }
}

/// کارت ساده با سایهٔ لطیف
class _Card extends StatelessWidget {
  const _Card({required this.child, this.margin});
  final Widget child;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: child,
    );
  }
}

/// سکشن نمایش جزئیاتِ دسته‌محور.
/// از categoryId و details برای برچسب‌گذاری کاربرپسند استفاده می‌کند.
class _DetailsSection extends StatelessWidget {
  const _DetailsSection({required this.categoryId, required this.details});

  final String categoryId;
  final Map<String, dynamic> details;

  @override
  Widget build(BuildContext context) {
    final th = Theme.of(context);
    final schema = _SchemaRegistry.forCategory(categoryId);

    final rows = <Widget>[];
    for (final f in schema.fields) {
      final v = details[f.key];
      if (v == null) continue;

      Widget valueWidget;
      switch (f.type) {
        case _FieldType.toggle:
          valueWidget = Text(v == true ? 'بله' : 'خیر');
          break;
        case _FieldType.multiselect:
          final list = List<String>.from(v);
          valueWidget = Wrap(
            spacing: 6,
            runSpacing: -6,
            children: list.map((e) => Chip(label: Text(e))).toList(),
          );
          break;
        case _FieldType.repeater:
          final list = List<String>.from(v);
          valueWidget = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: list
                .map((e) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_outline, size: 16),
                          const SizedBox(width: 6),
                          Expanded(child: Text(e)),
                        ],
                      ),
                    ))
                .toList(),
          );
          break;
        default:
          final text = (f.unit != null && v is num) ? '$v ${f.unit}' : v.toString();
          valueWidget = Text(text);
      }

      rows.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: _KV(label: f.label, child: valueWidget),
      ));
    }

    if (rows.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('جزئیات ${schema.title}',
              style: th.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ...rows,
        ],
      ),
    );
  }
}

class _KV extends StatelessWidget {
  const _KV({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final th = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: th.textTheme.bodyMedium?.copyWith(
              color: th.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: child),
      ],
    );
  }
}

/// ======= Schema Registry (نمایش) =======
/// فقط برای نمایشِ لیبل‌دار؛ فرم‌سازی اینجا نیست.
enum _FieldType { text, number, integer, select, multiselect, toggle, repeater }

class _FieldSpec {
  final String key;
  final String label;
  final _FieldType type;
  final String? unit;
  final List<String>? options;
  const _FieldSpec(this.key, this.label, this.type, {this.unit, this.options});
}

class _CategorySchema {
  final String id;
  final String title;
  final List<_FieldSpec> fields;
  const _CategorySchema(this.id, this.title, this.fields);
}

class _SchemaRegistry {
  static const house = _CategorySchema('house', 'خانه / ملک', [
    _FieldSpec('location', 'موقعیت', _FieldType.text),
    _FieldSpec('area_m2', 'متراژ', _FieldType.number, unit: 'm²'),
    _FieldSpec('rooms', 'تعداد اتاق', _FieldType.integer),
    _FieldSpec('bedrooms', 'اتاق خواب', _FieldType.integer),
    _FieldSpec('bathrooms', 'حمام/توالت', _FieldType.integer),
    _FieldSpec('floor', 'طبقه', _FieldType.integer),
    _FieldSpec('year_built', 'سال ساخت', _FieldType.integer),
    _FieldSpec('furnished', 'مبله', _FieldType.toggle),
    _FieldSpec('parking', 'پارکینگ', _FieldType.toggle),
    _FieldSpec('amenities', 'امکانات', _FieldType.multiselect),
    _FieldSpec('features', 'ویژگی‌های دیگر', _FieldType.repeater),
  ]);

  static const car = _CategorySchema('car', 'خودرو', [
    _FieldSpec('brand', 'برند', _FieldType.select),
    _FieldSpec('model', 'مدل', _FieldType.text),
    _FieldSpec('year', 'سال', _FieldType.integer),
    _FieldSpec('km', 'کارکرد', _FieldType.number, unit: 'km'),
    _FieldSpec('fuel', 'سوخت', _FieldType.select),
    _FieldSpec('transmission', 'گیربکس', _FieldType.select),
    _FieldSpec('color', 'رنگ', _FieldType.text),
    _FieldSpec('owners', 'تعداد مالک', _FieldType.integer),
    _FieldSpec('accident_free', 'بی‌تصادف', _FieldType.toggle),
    _FieldSpec('extras', 'آپشن‌ها', _FieldType.multiselect),
  ]);

  static const phone = _CategorySchema('phone', 'موبایل', [
    _FieldSpec('brand', 'برند', _FieldType.select),
    _FieldSpec('model', 'مدل', _FieldType.text),
    _FieldSpec('storage', 'حافظه', _FieldType.select),
    _FieldSpec('ram', 'RAM', _FieldType.select),
    _FieldSpec('condition', 'وضعیت', _FieldType.select),
    _FieldSpec('battery_health', 'سلامت باتری', _FieldType.integer, unit: '%'),
    _FieldSpec('dual_sim', 'دو سیم‌کارت', _FieldType.toggle),
    _FieldSpec('accessories', 'لوازم همراه', _FieldType.multiselect),
    _FieldSpec('notes', 'یادداشت‌ها', _FieldType.repeater),
  ]);

  static const job = _CategorySchema('job', 'آگهی شغلی', [
    _FieldSpec('job_title', 'عنوان شغل', _FieldType.text),
    _FieldSpec('employment_type', 'نوع همکاری', _FieldType.select),
    _FieldSpec('location', 'محل کار', _FieldType.text),
    _FieldSpec('remote', 'دورکار', _FieldType.toggle),
    _FieldSpec('salary_min', 'حداقل حقوق', _FieldType.number, unit: 'CHF'),
    _FieldSpec('salary_max', 'حداکثر حقوق', _FieldType.number, unit: 'CHF'),
    _FieldSpec('requirements', 'شرایط/مهارت‌ها', _FieldType.repeater),
  ]);

  static const _all = [house, car, phone, job];

  static _CategorySchema forCategory(String id) {
    return _all.firstWhere((e) => e.id == id, orElse: () => house);
  }
}
