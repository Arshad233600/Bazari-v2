// lib/features/product/pages/product_view_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';

import 'package:bazari_8656/data/models.dart';
import 'package:bazari_8656/data/products_repository.dart';

// گفتگو
import 'package:bazari_8656/features/chat/data/chat_repository.dart';
import 'package:bazari_8656/features/chat/pages/chat_room_page.dart';

class ProductViewPage extends StatefulWidget {
  const ProductViewPage({
    super.key,
    required this.p,
    this.locationLat,
    this.locationLng,
    this.locationName,
    this.description,
    this.highlights,
    this.specs,
    this.showMap = true, // ← امکان خاموش/روشن کردن نقشه
  });

  final Product p;

  // از «افزودن محصول»
  final double? locationLat;
  final double? locationLng;
  final String? locationName;

  final String? description;
  final List<String>? highlights;
  final Map<String, String>? specs;

  final bool showMap;

  @override
  State<ProductViewPage> createState() => _ProductViewPageState();
}

class _ProductViewPageState extends State<ProductViewPage> {
  final _repo = ProductsRepository();
  List<Product> _similar = const [];
  bool _descExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadSimilar();
  }

  Future<void> _loadSimilar() async {
    try {
      final list = await _repo.fetchPage(page: 1, categoryId: widget.p.categoryId);
      if (!mounted) return;
      setState(() {
        _similar = list.where((x) => x.id != widget.p.id).take(6).toList();
      });
    } catch (_) {}
  }

  /* =================== Helpers =================== */

  bool get _isFaLike {
    final code = Localizations.localeOf(context).languageCode.toLowerCase();
    return const {'fa', 'prs', 'ps'}.contains(code);
  }

  void _afterFrame(VoidCallback cb) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) cb();
    });
  }

  String _s(String? v, [String fallback = '']) =>
      (v?.trim().isNotEmpty ?? false) ? v!.trim() : fallback;

  bool _hasNum(double? v) => v != null && v.isFinite;

  String _faDigits(String input) {
    if (!_isFaLike) return input;
    const latin = ['0','1','2','3','4','5','6','7','8','9'];
    const pers  = ['۰','۱','۲','۳','۴','۵','۶','۷','۸','۹'];
    var out = input;
    for (var i = 0; i < 10; i++) {
      out = out.replaceAll(latin[i], pers[i]);
    }
    return out;
  }

  String _formatPrice(num? price, String currency) {
    if (price == null) return _faDigits('—');
    final fixed = price.toStringAsFixed(2);
    final s = '$fixed ${currency.trim()}'.trim();
    return _faDigits(s);
  }

  String _osmStaticUrl(double lat, double lng, {int zoom = 14, int w = 900, int h = 360}) {
    return 'https://staticmap.openstreetmap.de/staticmap.php'
        '?center=$lat,$lng&zoom=$zoom&size=${w}x$h&maptype=mapnik&markers=$lat,$lng,red';
  }

  /* ============== نگاشت و یکسان‌سازی کلیدهای مشخصات فارسی ============== */

  // نگاشت کلیدهای رایج به برچسب فارسیِ استاندارد
  static const Map<String, String> _specSynonymsFa = {
    // عمومی
    'status': 'وضعیت', 'state': 'وضعیت', 'condition': 'وضعیت', 'نو/دست‌دوم': 'وضعیت',
    'brand': 'برند', 'مارک': 'برند', 'model': 'مدل',
    'year': 'سال', 'manufacture year': 'سال',
    'mileage': 'کارکرد', 'odo': 'کارکرد', 'کارکرد': 'کارکرد',
    'gearbox': 'گیربکس', 'transmission': 'گیربکس', 'گیربکس': 'گیربکس',
    'fuel': 'سوخت',
    'color': 'رنگ',
    'storage': 'حافظه', 'capacity': 'حافظه', 'حافظه': 'حافظه',
    'ram': 'رم', 'memory': 'رم',
    'cpu': 'CPU', 'processor': 'CPU',
    'gpu': 'GPU', 'graphic': 'GPU',
    'size': 'اندازه', 'dimension': 'ابعاد', 'dimensions': 'ابعاد', 'ابعاد': 'ابعاد',
    'material': 'جنس', 'جنس': 'جنس',
    'warranty': 'گارانتی', 'guarantee': 'گارانتی', 'گارانتی تا': 'گارانتی',
    'delivery': 'تحویل', 'shipping': 'هزینه ارسال', 'post': 'هزینه ارسال',

    // راه‌های تماس
    'phone': 'شماره تماس', 'tel': 'شماره تماس', 'contact': 'شماره تماس',
    'whatsapp': 'واتساپ', 'telegram': 'تلگرام', 'instagram': 'اینستاگرام',

    // موقعیت
    'location': 'موقعیت', 'city': 'موقعیت', 'area': 'موقعیت', 'address': 'موقعیت', 'region': 'موقعیت',
  };

  // تلاش برای یکسان‌سازی کلیدها به فارسی استاندارد
  Map<String, String> _normalizeSpecs(Map<String, String> input) {
    final out = <String, String>{};
    input.forEach((k, v) {
      final key = _s(k);
      final val = _s(v);
      if (key.isEmpty || val.isEmpty) return;
      final lk = key.toLowerCase().replaceAll('‌', '').replaceAll(' ', '');
      // ابتدا جست‌وجو بین هم‌معنی‌ها
      String? mapped;
      for (final entry in _specSynonymsFa.entries) {
        final rk = entry.key.toLowerCase().replaceAll(' ', '');
        if (lk == rk) { mapped = entry.value; break; }
      }
      // اگر نگاشت پیدا نشد و خودِ کلید فارسی رایج است، همان را نگه می‌داریم
      final finalKey = mapped ?? key;
      out[finalKey] = _isFaLike ? _faDigits(val) : val;
    });
    return out;
  }

  /* =================== Header =================== */

  Widget _header(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final img = _s(widget.p.imageUrl);
    return AspectRatio(
      aspectRatio: 16 / 10,
      child: DecoratedBox(
        decoration: BoxDecoration(color: cs.surfaceVariant),
        child: img.isEmpty
            ? const Center(child: Icon(Icons.image, size: 56))
            : Image.network(
          img,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Center(child: Text('خطا در بارگذاری تصویر')),
          loadingBuilder: (c, child, p) =>
          p == null ? child : const Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }

  /* =================== Title & Price =================== */

  Widget _titlePrice(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final priceNum = (widget.p as dynamic).price;
    final priceText = (priceNum is num)
        ? _formatPrice(priceNum, _s(widget.p.currency, ''))
        : _faDigits('—');

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        textDirection: _isFaLike ? TextDirection.rtl : TextDirection.ltr,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              _s(widget.p.title, '—'),
              textAlign: _isFaLike ? TextAlign.right : TextAlign.left,
              style: t.titleLarge?.copyWith(fontWeight: FontWeight.w700, height: 1.2),
            ),
          ),
          const SizedBox(width: 12),
          DecoratedBox(
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Text(
                priceText,
                textDirection: TextDirection.ltr,
                style: TextStyle(color: cs.onPrimaryContainer, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /* =================== Seller Card =================== */

  Widget _stars(double rating) {
    final full = rating.floor();
    final half = (rating - full) >= 0.5;
    return Row(mainAxisSize: MainAxisSize.min, children: List.generate(5, (i) {
      if (i < full) return const Icon(Icons.star, size: 18);
      if (i == full && half) return const Icon(Icons.star_half, size: 18);
      return const Icon(Icons.star_border, size: 18);
    }));
  }

  Widget _sellerCard(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const rating = 4.6;
    const trades = 128;
    final avatar = _s(widget.p.sellerAvatarUrl);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Row(
          textDirection: _isFaLike ? TextDirection.rtl : TextDirection.ltr,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: cs.surfaceVariant,
              backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
              child: avatar.isEmpty ? const Icon(Icons.person_outline) : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment:
                _isFaLike ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Text(
                    _s(widget.p.sellerName, '—'),
                    textAlign: _isFaLike ? TextAlign.right : TextAlign.left,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    textDirection: _isFaLike ? TextDirection.rtl : TextDirection.ltr,
                    children: [
                      _stars(rating),
                      const SizedBox(width: 8),
                      Text(_faDigits('$rating • $trades معامله')),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /* =================== Description (Expandable) =================== */

  Widget _description(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    final body = _s(widget.description, 'توضیحاتی برای این محصول ثبت نشده است.');
    final List<String> highlights = (widget.highlights ?? const [])
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final String shortText = body.length > 220 ? '${body.substring(0, 220)}…' : body;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment:
          _isFaLike ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Align(
              alignment: _isFaLike ? Alignment.centerRight : Alignment.centerLeft,
              child: Text('توضیحات', style: t.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 8),
            AnimatedCrossFade(
              crossFadeState: _descExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 160),
              firstChild: Text(
                _isFaLike ? _faDigits(shortText) : shortText,
                textAlign: _isFaLike ? TextAlign.right : TextAlign.left,
              ),
              secondChild: Text(
                _isFaLike ? _faDigits(body) : body,
                textAlign: _isFaLike ? TextAlign.right : TextAlign.left,
              ),
            ),
            if (body.length > 220) ...[
              const SizedBox(height: 6),
              Align(
                alignment: _isFaLike ? Alignment.centerRight : Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => setState(() => _descExpanded = !_descExpanded),
                  child: Text(_descExpanded ? 'کمتر' : 'بیشتر'),
                ),
              ),
            ],
            if (highlights.isNotEmpty) ...[
              const SizedBox(height: 12),
              Align(
                alignment: _isFaLike ? Alignment.centerRight : Alignment.centerLeft,
                child:
                Text('هایلایت‌ها', style: t.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                textDirection: _isFaLike ? TextDirection.rtl : TextDirection.ltr,
                children: highlights.map((h) {
                  final hv = _isFaLike ? _faDigits(h) : h;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: cs.surfaceVariant.withOpacity(0.6),
                      border: Border.all(color: cs.outlineVariant),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(hv),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /* =================== Specs (RTL + ترتیب فارسی + موقعیت) =================== */

  static const List<String> _preferredOrderFa = [
    'موقعیت',
    'وضعیت',
    'برند','مدل','سال','کارکرد','گیربکس','سوخت','رنگ',
    'حافظه','رم','CPU','GPU','اندازه','ابعاد','جنس',
    'گارانتی','تحویل','هزینه ارسال',
    'شماره تماس','واتساپ','تلگرام','اینستاگرام',
    'قیمت','تاریخ ثبت','کد',
  ];

  String _composeLocationField() {
    final name = _s(widget.locationName);
    if (name.isNotEmpty) return _isFaLike ? _faDigits(name) : name;
    final lat = widget.locationLat, lng = widget.locationLng;
    if (_hasNum(lat) && _hasNum(lng)) {
      final s = '${lat!.toStringAsFixed(5)}, ${lng!.toStringAsFixed(5)}';
      return _faDigits(s);
    }
    return '';
  }

  Map<String, String> _mergedSpecs() {
    // مشخصات واردشده توسط کاربر (یکسان‌سازی کلیدها)
    final userRaw = widget.specs ?? const <String, String>{};
    final user = _normalizeSpecs(userRaw);

    // موقعیت (همان بالا نمایش داده می‌شود)
    final loc = _composeLocationField();
    if (loc.isNotEmpty) user['موقعیت'] = loc;

    // پایه
    final base = <String, String>{
      'قیمت': (() {
        final p = (widget.p as dynamic).price;
        return (p is num) ? _formatPrice(p, _s(widget.p.currency, '')) : _faDigits('—');
      })(),
      'تاریخ ثبت': _isFaLike ? _faDigits(widget.p.createdAt.toString()) : widget.p.createdAt.toString(),
      'کد': _faDigits(widget.p.id),
      'دسته‌بندی': _s(widget.p.categoryId),
    };

    // مرتب‌سازی: اول ترتیب فارسی، بعد بقیه، بعد پایه
    final ordered = <MapEntry<String,String>>[];
    if (_isFaLike) {
      for (final key in _preferredOrderFa) {
        if (user.containsKey(key)) {
          ordered.add(MapEntry(key, user[key]!));
          user.remove(key);
        }
      }
    }
    ordered.addAll(user.entries);
    ordered.addAll(base.entries);

    return { for (final e in ordered) e.key : e.value };
  }

  Widget _specs(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final rows = _mergedSpecs().entries.toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment:
          _isFaLike ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(12, 12, 12, 4),
              child: Text('مشخصات', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
            for (int i = 0; i < rows.length; i++)
              Directionality(
                textDirection: _isFaLike ? TextDirection.rtl : TextDirection.ltr,
                child: Container(
                  color: i.isEven ? cs.surface : cs.surfaceVariant.withOpacity(0.35),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 140,
                        child: Text(
                          rows[i].key,
                          textAlign: _isFaLike ? TextAlign.right : TextAlign.left,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          rows[i].value,
                          textAlign: _isFaLike ? TextAlign.left : TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /* =================== Map (اختیاری) =================== */

  Widget _map(BuildContext context) {
    if (!widget.showMap) return const SizedBox.shrink();
    final lat = widget.locationLat;
    final lng = widget.locationLng;
    if (!_hasNum(lat) || !_hasNum(lng)) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;
    final url = _osmStaticUrl(lat!, lng!, w: 900, h: 360, zoom: 14);
    final loc = _s(widget.locationName);

    final latText = _faDigits(lat.toStringAsFixed(5));
    final lngText = _faDigits(lng.toStringAsFixed(5));

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Row(
                mainAxisAlignment:
                _isFaLike ? MainAxisAlignment.end : MainAxisAlignment.start,
                children: [
                  const Text('موقعیت', style: TextStyle(fontWeight: FontWeight.w700)),
                  if (loc.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Text('• ${_isFaLike ? _faDigits(loc) : loc}'),
                  ],
                ],
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                url,
                height: 220,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                const SizedBox(height: 180, child: Center(child: Text('نقشه در دسترس نیست'))),
                loadingBuilder: (c, child, p) =>
                p == null ? child : const SizedBox(height: 180, child: Center(child: CircularProgressIndicator())),
              ),
            ),
            Row(
              textDirection: _isFaLike ? TextDirection.rtl : TextDirection.ltr,
              children: [
                const SizedBox(width: 12, height: 44),
                Expanded(
                  child: Text(
                    _isFaLike
                        ? 'مختصات: $latText, $lngText'
                        : 'Coords: $latText, $lngText',
                  ),
                ),
                TextButton.icon(
                  onPressed: () async {
                    final txt = '${lat.toStringAsFixed(6)},${lng.toStringAsFixed(6)}';
                    await Clipboard.setData(ClipboardData(text: txt));
                    _afterFrame(() {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(const SnackBar(content: Text('مختصات کپی شد')));
                    });
                  },
                  icon: const Icon(Icons.copy_all_rounded),
                  label: Text(_isFaLike ? 'کپی' : 'Copy'),
                ),
                const SizedBox(width: 4),
                TextButton(
                  onPressed: () async {
                    final l1 = lat.toStringAsFixed(6);
                    final l2 = lng.toStringAsFixed(6);
                    final link = 'https://www.openstreetmap.org/?mlat=$l1&mlon=$l2#map=16/$l1/$l2';
                    await Clipboard.setData(ClipboardData(text: link));
                    _afterFrame(() {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(const SnackBar(content: Text('لینک نقشه کپی شد')));
                    });
                  },
                  child: const Text('OSM'),
                ),
                const SizedBox(width: 8),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /* =================== Similar Grid =================== */

  Widget _similarGrid(BuildContext context) {
    if (_similar.isEmpty) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment:
        _isFaLike ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          const Text('محصولات مشابه', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.78,
            ),
            itemCount: _similar.length,
            itemBuilder: (_, i) {
              final x = _similar[i];
              final img = _s(x.imageUrl);
              final price = (() {
                final p = (x as dynamic).price;
                return (p is num) ? _formatPrice(p, _s(x.currency, '')) : _faDigits('—');
              })();

              return Container(
                decoration: BoxDecoration(
                  color: cs.surface,
                  border: Border.all(color: cs.outlineVariant),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        child: img.isEmpty
                            ? const Center(child: Icon(Icons.image))
                            : Image.network(
                          img,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.image)),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        _s(x.title, '—'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: _isFaLike ? TextAlign.right : TextAlign.left,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                      child: Text(
                        price,
                        textDirection: TextDirection.ltr,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /* =================== Chat =================== */

  void _openChatWithContext() {
    final chatId = 'product_${widget.p.id}_${widget.p.sellerId}';
    ChatRepository.instance.upsertChat(
      id: chatId,
      title: _s(widget.p.sellerName, '—'),
      subtitle: 'درباره: ${_s(widget.p.title, '')}',
    );
    _afterFrame(() {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatRoomPage(
            chatId: chatId,
            title: _s(widget.p.sellerName, '—'),
            productTitle: _s(widget.p.title, ''),
            productImage: _s(widget.p.imageUrl, ''),
          ),
        ),
      );
    });
  }

  /* =================== Build =================== */

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Directionality(
      textDirection: _isFaLike ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(title: const Text('جزئیات محصول')),
        body: SafeArea(
          child: ListView(
            children: [
              _header(context),
              _titlePrice(context),
              _sellerCard(context),
              _description(context),
              _specs(context),
              _map(context),
              _similarGrid(context),
              const SizedBox(height: 16),
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Container(
            decoration: BoxDecoration(
              color: cs.surface,
              border: Border(top: BorderSide(color: cs.outlineVariant)),
            ),
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _afterFrame(() {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(const SnackBar(content: Text('به علاقه‌مندی‌ها اضافه شد')));
                      });
                    },
                    icon: const Icon(Icons.favorite_border),
                    label: const Text('علاقه‌مندی'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _openChatWithContext,
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: const Text('گفتگو با فروشنده'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
