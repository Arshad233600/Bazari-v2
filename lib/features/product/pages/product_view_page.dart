import 'package:flutter/material.dart';
import '../../chat/pages/chat_room_page.dart';
import '../models/product.dart';

class ProductViewPage extends StatelessWidget {
  ProductViewPage({
    super.key,
    required this.currentUserId,
    Product? product, // پارامتر جدید
    Product? p,       // برای سازگاری عقب‌رو (کدهای قدیمی)
  }) : product = product ?? p ?? (throw ArgumentError('ProductViewPage: product is required'));

  final String currentUserId;

  /// محصول
  final Product product;

  @override
  Widget build(BuildContext context) {
    final th = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(product.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(icon: const Icon(Icons.share_outlined), onPressed: () => _share(context)),
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
      body: ListView(
        children: [
          // گالری
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

          // عنوان + قیمت
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(product.title,
                style: th.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
            child: Text(
              '${product.price.toStringAsFixed(2)} ${product.currency}',
              style: th.textTheme.titleLarge
                  ?.copyWith(color: th.colorScheme.primary, fontWeight: FontWeight.w800),
            ),
          ),

          // چیپ‌های کلیدواژه
          if (product.keywords.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: -8,
                children: product.keywords
                    .map((k) => ActionChip(label: Text(k), onPressed: () {}))
                    .toList(),
              ),
            ),

          const Divider(height: 24),

          // توضیحات
          if (product.description.trim().isNotEmpty)
            _Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(product.description, style: th.textTheme.bodyMedium),
              ),
            ),

          // جزئیات پویا (اگر داری widget اختصاصی‌اش را نگه داشتی)
          if (product.details.isNotEmpty)
            _Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: _DetailsSimple(categoryId: product.categoryId, details: product.details),
              ),
            ),

          // فروشنده + چت
          _Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundImage: (product.seller.avatarUrl != null &&
                        product.seller.avatarUrl!.trim().isNotEmpty)
                    ? NetworkImage(product.seller.avatarUrl!)
                    : null,
                child: (product.seller.avatarUrl == null ||
                        product.seller.avatarUrl!.trim().isEmpty)
                    ? Text(product.seller.name.characters.first.toUpperCase())
                    : null,
              ),
              title: Text(product.seller.name),
              subtitle: const Text('فعال'),
              trailing: OutlinedButton.icon(
                icon: const Icon(Icons.chat),
                label: const Text('چت'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatRoomPage(
                        chatId: product.seller.id,
                        meId: currentUserId,
                        peerTitle: product.seller.name, // ← title قدیمی را استفاده نکن
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // محصولات مشابه
          if (product.similar.isNotEmpty)
            _Card(
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
                                    currentUserId: currentUserId,
                                    product: p,
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
                                    '${p.price.toStringAsFixed(0)} ${p.currency}',
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

          // اکشن‌ها
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.favorite_border),
                    label: const Text('پسندیدن'),
                    onPressed: () => ScaffoldMessenger.of(context)
                        .showSnackBar(const SnackBar(content: Text('محصول لایک شد'))),
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
    );
  }

  void _share(BuildContext context) {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('لینک محصول به اشتراک گذاشته شد')));
  }

  void _report(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('گزارش ارسال شد')));
  }

  void _block(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('فروشنده بلاک شد')));
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: child,
    );
  }
}

/// نمایش ساده‌ی Details با لیبل‌های پرکاربرد برای house/car/phone/job
class _DetailsSimple extends StatelessWidget {
  const _DetailsSimple({required this.categoryId, required this.details});
  final String categoryId;
  final Map<String, dynamic> details;

  @override
  Widget build(BuildContext context) {
    final th = Theme.of(context);
    final schema = _Schema.forCategory(categoryId);
    final rows = <Widget>[];

    for (final f in schema) {
      final v = details[f.key];
      if (v == null) continue;

      Widget w;
      switch (f.type) {
        case _FieldType.toggle:
          w = Text(v == true ? 'بله' : 'خیر');
          break;
        case _FieldType.multiselect:
          final list = List<String>.from(v);
          w = Wrap(spacing: 6, runSpacing: -6, children: list.map((e) => Chip(label: Text(e))).toList());
          break;
        case _FieldType.repeater:
          final list = List<String>.from(v);
          w = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: list
                .map((e) => Row(children: [
                      const Icon(Icons.check_circle_outline, size: 16),
                      const SizedBox(width: 6),
                      Expanded(child: Text(e)),
                    ]))
                .toList(),
          );
          break;
        default:
          final text = (f.unit != null && v is num) ? '$v ${f.unit}' : v.toString();
          w = Text(text);
      }

      rows.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              child: Text(f.label,
                  style: th.textTheme.bodyMedium?.copyWith(
                    color: th.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  )),
            ),
            const SizedBox(width: 8),
            Expanded(child: w),
          ],
        ),
      ));
    }

    if (rows.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('جزئیات', style: th.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        ...rows,
      ],
    );
  }
}

enum _FieldType { text, number, integer, select, multiselect, toggle, repeater }

class _Field {
  final String key;
  final String label;
  final _FieldType type;
  final String? unit;
  const _Field(this.key, this.label, this.type, {this.unit});
}

class _Schema {
  static List<_Field> house = [
    _Field('location', 'موقعیت', _FieldType.text),
    _Field('area_m2', 'متراژ', _FieldType.number, unit: 'm²'),
    _Field('rooms', 'تعداد اتاق', _FieldType.integer),
    _Field('bedrooms', 'اتاق خواب', _FieldType.integer),
    _Field('bathrooms', 'حمام/توالت', _FieldType.integer),
    _Field('floor', 'طبقه', _FieldType.integer),
    _Field('year_built', 'سال ساخت', _FieldType.integer),
    _Field('furnished', 'مبله', _FieldType.toggle),
    _Field('parking', 'پارکینگ', _FieldType.toggle),
    _Field('amenities', 'امکانات', _FieldType.multiselect),
    _Field('features', 'ویژگی‌های دیگر', _FieldType.repeater),
  ];

  static List<_Field> car = [
    _Field('brand', 'برند', _FieldType.select),
    _Field('model', 'مدل', _FieldType.text),
    _Field('year', 'سال', _FieldType.integer),
    _Field('km', 'کارکرد', _FieldType.number, unit: 'km'),
    _Field('fuel', 'سوخت', _FieldType.select),
    _Field('transmission', 'گیربکس', _FieldType.select),
    _Field('color', 'رنگ', _FieldType.text),
    _Field('owners', 'تعداد مالک', _FieldType.integer),
    _Field('accident_free', 'بی‌تصادف', _FieldType.toggle),
    _Field('extras', 'آپشن‌ها', _FieldType.multiselect),
  ];

  static List<_Field> phone = [
    _Field('brand', 'برند', _FieldType.select),
    _Field('model', 'مدل', _FieldType.text),
    _Field('storage', 'حافظه', _FieldType.select),
    _Field('ram', 'RAM', _FieldType.select),
    _Field('condition', 'وضعیت', _FieldType.select),
    _Field('battery_health', 'سلامت باتری', _FieldType.integer, unit: '%'),
    _Field('dual_sim', 'دو سیم‌کارت', _FieldType.toggle),
    _Field('accessories', 'لوازم همراه', _FieldType.multiselect),
    _Field('notes', 'یادداشت‌ها', _FieldType.repeater),
  ];

  static List<_Field> job = [
    _Field('job_title', 'عنوان شغل', _FieldType.text),
    _Field('employment_type', 'نوع همکاری', _FieldType.select),
    _Field('location', 'محل کار', _FieldType.text),
    _Field('remote', 'دورکار', _FieldType.toggle),
    _Field('salary_min', 'حداقل حقوق', _FieldType.number, unit: 'CHF'),
    _Field('salary_max', 'حداکثر حقوق', _FieldType.number, unit: 'CHF'),
    _Field('requirements', 'شرایط/مهارت‌ها', _FieldType.repeater),
  ];

  static List<_Field> forCategory(String id) {
    switch (id) {
      case 'house':
        return house;
      case 'car':
        return car;
      case 'phone':
        return phone;
      case 'job':
        return job;
      default:
        return house;
    }
  }
}
