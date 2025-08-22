import 'package:flutter/material.dart';
import 'package:bazari_8656/data/models.dart';

class ProductCard extends StatelessWidget {
  final Product p;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;

  /// نشان‌های کوچک روی تصویر (مثلا "ویژه")
  final List<String> badges;

  /// زیرمتن اختیاری (مثلا شهر/محل)
  final String? subtitle;

  /// اگر Hero می‌خواهی، شناسه بده. خالی باشد Hero غیرفعال است.
  final String? heroTag;

  const ProductCard({
    super.key,
    required this.p,
    this.onTap,
    this.onLongPress,
    this.isFavorite = false,
    this.onFavoriteToggle,
    this.badges = const <String>[],
    this.subtitle,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: cs.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // تصویر: کشسان تا هیچ‌وقت Overflow رخ نده
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: _buildImage(context),
                ),
              ),

              // عنوان (حداکثر 2 خط)
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
                child: Text(
                  p.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600, height: 1.2),
                ),
              ),

              // زیرمتن (اختیاری) – تک خط
              if (subtitle != null && subtitle!.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 2, 10, 0),
                  child: Text(
                    subtitle!.trim(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),

              // قیمت + دکمه علاقه‌مندی
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 6, 6, 8),
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        _formatPrice(p.price, p.currency),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 6),
                    _FavButton(
                      isOn: isFavorite,
                      onToggle: onFavoriteToggle,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /* -------------------- Parts -------------------- */

  Widget _buildImage(BuildContext context) {
    final img = _networkImageOrPlaceholder(p.imageUrl);
    final child = Stack(
      fit: StackFit.expand,
      children: [
        img,

        // گرادیان ملایم پایین برای خوانایی متن‌های روی تصویر (اگر بعداً لازم شد)
        const _BottomGradientOverlay(),

        // بَج‌ها (گوشهٔ بالا-راست/چپ: RTL/LTR-safe)
        if (badges.isNotEmpty) _Badges(badges: badges),
      ],
    );

    if (heroTag != null && heroTag!.isNotEmpty) {
      return Hero(tag: heroTag!, child: child);
    }
    return child;
  }

  Widget _networkImageOrPlaceholder(String url) {
    if (url.isEmpty) {
      return const ColoredBox(
        color: Color(0x11000000),
        child: Center(child: Icon(Icons.image_outlined, size: 36)),
      );
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const ColoredBox(
        color: Color(0x11000000),
        child: Center(child: Icon(Icons.broken_image_outlined, size: 36)),
      ),
      loadingBuilder: (c, child, p) {
        if (p == null) return child;
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  String _formatPrice(double value, String currency) {
    // فرمت سبک با جداکننده هزارگان (بدون پکیج)
    final s = value.toStringAsFixed(0);
    final re = RegExp(r'\B(?=(\d{3})+(?!\d))');
    final withSep = s.replaceAllMapped(re, (m) => ',');
    // اگر قیمت اعشاری لازم داری: toStringAsFixed(2) را بگذار و regex را حفظ کن
    return '$withSep $currency';
  }
}

/* -------------------- Small widgets -------------------- */

class _FavButton extends StatelessWidget {
  final bool isOn;
  final VoidCallback? onToggle;
  const _FavButton({required this.isOn, this.onToggle});

  @override
  Widget build(BuildContext context) {
    // دکمه کوچکِ ثابت‌ابعاد که توی ردیف قیمت سرریز نده
    return SizedBox(
      width: 32,
      height: 32,
      child: IconButton(
        onPressed: onToggle,
        iconSize: 20,
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        icon: Icon(isOn ? Icons.favorite : Icons.favorite_border),
        color: isOn ? Colors.redAccent : Theme.of(context).iconTheme.color,
        tooltip: isOn ? 'حذف از علاقه‌مندی' : 'افزودن به علاقه‌مندی',
      ),
    );
  }
}

class _BottomGradientOverlay extends StatelessWidget {
  const _BottomGradientOverlay();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: IgnorePointer(
        child: Container(
          height: 36,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Color(0x22000000)],
            ),
          ),
        ),
      ),
    );
  }
}

class _Badges extends StatelessWidget {
  final List<String> badges;
  const _Badges({required this.badges});

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final align = isRtl ? Alignment.topLeft : Alignment.topRight;
    final pad = isRtl
        ? const EdgeInsets.only(top: 8, left: 8)
        : const EdgeInsets.only(top: 8, right: 8);

    return Align(
      alignment: align,
      child: Padding(
        padding: pad,
        child: Wrap(
          spacing: 6,
          runSpacing: 6,
          children: badges.take(3).map((b) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                b,
                style: const TextStyle(color: Colors.white, fontSize: 11, height: 1),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
