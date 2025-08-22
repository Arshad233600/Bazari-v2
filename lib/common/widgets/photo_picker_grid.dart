import 'package:flutter/material.dart';

/// گرید نمایش عکس‌ها (http/https یا data:image/*)
/// برای سازگاری با کدهای قدیمی، چند پارامتر اختیاری اضافه شده که
/// در این ویجت استفادهٔ UI ندارند اما برای امضا حفظ شده‌اند.
class PhotoPickerGrid extends StatelessWidget {
  const PhotoPickerGrid({
    super.key,
    List<String>? images,                 // قبلاً required بود → حالا اختیاری با پیش‌فرض []
    this.onTap,
    this.crossAxisCount = 3,
    // پارامترهای legacy برای سازگاری:
    this.maxCount,                        // اختیاری - استفاده نمی‌شود
    this.initial,                         // اختیاری - استفاده نمی‌شود
    this.onChanged,                       // اختیاری - استفاده نمی‌شود
    this.title,                           // اختیاری - استفاده نمی‌شود
  }) : images = images ?? const <String>[];

  /// لینک‌ها (http/https یا data:image/...)
  final List<String> images;

  /// واکنش به کلیک روی آیتم
  final void Function(int index)? onTap;

  /// تعداد ستون‌ها
  final int crossAxisCount;

  // ---------- Legacy API (برای سازگاری با کدهای قدیمی) ----------
  final int? maxCount;
  final List<String>? initial;
  final ValueChanged<List<String>>? onChanged;
  final String? title;
  // --------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (images.isEmpty) {
      return Container(
        height: 120,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: cs.surfaceVariant.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: const Text('عکسی انتخاب نشده است'),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: images.length,
      itemBuilder: (_, i) {
        final url = images[i];
        return GestureDetector(
          onTap: onTap == null ? null : () => onTap!(i),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: cs.surfaceVariant,
                child: const Center(child: Icon(Icons.broken_image_outlined)),
              ),
            ),
          ),
        );
      },
    );
  }
}
