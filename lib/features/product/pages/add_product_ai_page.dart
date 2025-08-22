// lib/features/product/pages/add_product_ai_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

// AI (موبایل = MLKit، وب = استابِ بدون خطا)
import 'package:bazari_8656/features/product/ai/vision.dart';

// دسته‌بندی‌ها (۲۴ کتگوری و زیرکتگوری‌ها)
import 'package:bazari_8656/data/categories.dart';

class AddProductAiPage extends StatefulWidget {
  const AddProductAiPage({super.key});

  @override
  State<AddProductAiPage> createState() => _AddProductAiPageState();
}

class _AddProductAiPageState extends State<AddProductAiPage> {
  // ---- UI State
  final _titleCtl = TextEditingController();
  final _descCtl  = TextEditingController();
  final _priceCtl = TextEditingController();

  CategorySpec? _selectedCategory;
  String? _imageDataUrl; // data:image/jpeg;base64,...

  bool _analyzing = false;
  bool _saving = false;

  // ---- AI bridge
  final VisionAi _ai = VisionAiMobile();

  @override
  void dispose() {
    _ai.dispose();
    _titleCtl.dispose();
    _descCtl.dispose();
    _priceCtl.dispose();
    super.dispose();
  }

  /* --------------------------- عکس از دوربین/گالری --------------------------- */

  Future<void> _pickFromCamera() async {
    final x = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 85, maxWidth: 2000);
    if (x == null) return;
    final bytes = await x.readAsBytes();
    setState(() {
      _imageDataUrl = 'data:image/jpeg;base64,${base64Encode(bytes)}';
    });
  }

  Future<void> _pickFromGallery() async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85, maxWidth: 2000);
    if (x == null) return;
    final bytes = await x.readAsBytes();
    setState(() {
      _imageDataUrl = 'data:image/jpeg;base64,${base64Encode(bytes)}';
    });
  }

  /* --------------------------------- آنالیز --------------------------------- */

  Future<void> _analyze() async {
    if (_imageDataUrl == null || _imageDataUrl!.isEmpty) return;
    if (_analyzing) return;

    setState(() => _analyzing = true);

    try {
      // نکته: نسخهٔ وب استاب است و لیبل خالی برمی‌گرداند.
      // برای موبایل (Android/iOS) لیبل‌های MLKit می‌آید.
      final labels = await _ai.labelImageFile('path-not-used-on-web');

      // حدس کتگوری از روی برچسب‌ها
      final guessed = _guessCategoryFromLabels(labels);
      if (guessed != null) {
        _selectedCategory = guessed;
      }

      // عنوان پیشنهادی
      final title = _makeTitle(labels, _selectedCategory);
      if (title.isNotEmpty) {
        _titleCtl.text = title;
      }

      // توضیح پیشنهادی
      final desc = _makeDescription(labels, _selectedCategory);
      if (desc.isNotEmpty) {
        _descCtl.text = desc;
      }

      // قیمت تقریبی پیشنهادی
      final price = _suggestPrice(labels, _selectedCategory);
      if (price != null) {
        _priceCtl.text = price.toStringAsFixed(2);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(labels.isEmpty ? 'آنالیز AI روی این دستگاه در دسترس نیست (وب).'
            : 'پیشنهادها براساس عکس آماده شد.')),
      );
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا در آنالیز: $e')),
      );
    } finally {
      if (mounted) setState(() => _analyzing = false);
    }
  }

  CategorySpec? _guessCategoryFromLabels(List<String> labels) {
    final flat = flattenCategories().toList();
    if (labels.isEmpty) {
      // fallback: چیزی حدس نزن
      return null;
    }

    // کلمات کلیدی رایج
    final Map<String, List<String>> groups = {
      'phone'     : ['phone','mobile','smartphone','iphone','cellphone','handy','گوشی','موبایل'],
      'laptop'    : ['laptop','notebook','macbook','computer','pc','کامپیوتر','لپ','لپ‌تاپ'],
      'camera'    : ['camera','dslr','lens','camcorder','دوربین'],
      'watch'     : ['watch','smartwatch','ساعت'],
      'shoe'      : ['shoe','sneaker','boots','کفش'],
      'bag'       : ['bag','backpack','handbag','کیف'],
      'bicycle'   : ['bicycle','bike','دوچرخه'],
      'car'       : ['car','vehicle','automobile','sedan','suv','van','truck','موتر','خودرو'],
      'furniture' : ['sofa','chair','table','bed','کاناپه','مبل','صندلی','میز','تخت'],
      'tv'        : ['tv','television','تلویزیون'],
      'appliance' : ['microwave','fridge','refrigerator','washer','dryer','یخچال','لباسشویی'],
      'toy'       : ['toy','lego','doll','اسباب','اسباب‌بازی'],
      'beauty'    : ['cosmetics','perfume','makeup','ادکلن','عطر','آرایش'],
      'book'      : ['book','novel','کتاب'],
      'game'      : ['playstation','xbox','nintendo','console','بازی','کنسول'],
      'instrument': ['guitar','piano','violin','drum','ساز','گیتار','پیانو'],
      'pet'       : ['pet','dog','cat','حیوان','سگ','گربه'],
      'sport'     : ['ball','football','soccer','tennis','bike','gym','ورزشی','ورزش'],
    };

    String? bucket;
    final lower = labels.map((e)=>e.toLowerCase()).toList();
    int bestScore = 0;

    groups.forEach((k, words) {
      int score = 0;
      for (final w in words) {
        if (lower.any((l) => l.contains(w))) score++;
      }
      if (score > bestScore) {
        bestScore = score;
        bucket = k;
      }
    });

    if (bucket == null) return null;

    // حالا بهترین کتگوری واقعی را از بین لیست‌ها پیدا کن
    CategorySpec? best;
    int bestTitleScore = 0;
    for (final c in flat) {
      final title = c.title.toLowerCase();
      int s = 0;
      switch (bucket) {
        case 'phone'     : if (title.contains('موب') || title.contains('phone')) s += 2; break;
        case 'laptop'    : if (title.contains('لپ') || title.contains('notebook') || title.contains('laptop')) s += 2; break;
        case 'camera'    : if (title.contains('دوربین') || title.contains('camera')) s += 2; break;
        case 'watch'     : if (title.contains('ساعت') || title.contains('watch')) s += 2; break;
        case 'shoe'      : if (title.contains('کفش') || title.contains('shoe') || title.contains('sneaker')) s += 2; break;
        case 'bag'       : if (title.contains('کیف') || title.contains('bag')) s += 2; break;
        case 'bicycle'   : if (title.contains('دوچرخه') || title.contains('bicycle')) s += 2; break;
        case 'car'       : if (title.contains('خودرو') || title.contains('موتر') || title.contains('car')) s += 2; break;
        case 'furniture' : if (title.contains('مبلمان') || title.contains('sofa') || title.contains('furniture')) s += 2; break;
        case 'tv'        : if (title.contains('تلویزیون') || title.contains('tv')) s += 2; break;
        case 'appliance' : if (title.contains('خانه') || title.contains('appliance') || title.contains('یخچال') || title.contains('لباسشویی')) s += 2; break;
        case 'toy'       : if (title.contains('اسباب') || title.contains('toys')) s += 2; break;
        case 'beauty'    : if (title.contains('زیبایی') || title.contains('آرای') || title.contains('perfume') || title.contains('cosmetic')) s += 2; break;
        case 'book'      : if (title.contains('کتاب') || title.contains('book')) s += 2; break;
        case 'game'      : if (title.contains('بازی') || title.contains('console')) s += 2; break;
        case 'instrument': if (title.contains('ساز') || title.contains('guitar') || title.contains('piano')) s += 2; break;
        case 'pet'       : if (title.contains('حیوان') || title.contains('pet') || title.contains('سگ') || title.contains('گربه')) s += 2; break;
        case 'sport'     : if (title.contains('ورزش') || title.contains('sport')) s += 2; break;
      }

      // کمی وزن به تطبیق دقیق عنوان بده
      for (final l in lower) {
        if (title.contains(l)) s++;
      }

      if (s > bestTitleScore) {
        bestTitleScore = s;
        best = c;
      }
    }
    return best;
  }

  String _makeTitle(List<String> labels, CategorySpec? cat) {
    final lc = labels.map((e)=>e.toLowerCase()).toList();
    String base = 'کالا';
    if (cat != null) base = cat.title;
    if (lc.any((e)=> e.contains('iphone'))) return 'iPhone - ${base}';
    if (lc.any((e)=> e.contains('laptop') || e.contains('notebook') || e.contains('macbook'))) return 'Laptop - ${base}';
    if (lc.any((e)=> e.contains('camera'))) return 'Camera - ${base}';
    if (lc.any((e)=> e.contains('watch'))) return 'Watch - ${base}';
    return base;
  }

  String _makeDescription(List<String> labels, CategorySpec? cat) {
    final catName = cat?.title ?? 'کالا';
    final tags = labels.take(5).join(', ');
    return 'این آگهی برای "$catName" است. تصاویر با استفاده از هوش مصنوعی تحلیل شد و برچسب‌های زیر تشخیص داده شد: $tags.\n'
        'لطفاً مشخصات دقیق (مدل/سایز/وضعیت) را اضافه کنید تا خریداران راحت‌تر تصمیم بگیرند.';
  }

  double? _suggestPrice(List<String> labels, CategorySpec? cat) {
    final t = (cat?.title.toLowerCase() ?? '');
    // قیمت پایه‌ی تقریبی بر اساس کتگوری؛ فقط برای شروع
    double? base;
    if (t.contains('موب') || t.contains('phone')) base = 300;
    else if (t.contains('لپ') || t.contains('notebook') || t.contains('laptop')) base = 700;
    else if (t.contains('دوربین') || t.contains('camera')) base = 250;
    else if (t.contains('ساعت') || t.contains('watch')) base = 120;
    else if (t.contains('تلویزیون') || t.contains('tv')) base = 220;
    else if (t.contains('دوچرخه') || t.contains('bicycle')) base = 150;
    else if (t.contains('خودرو') || t.contains('موتر') || t.contains('car')) base = 5000;
    else if (t.contains('مبلمان') || t.contains('sofa')) base = 300;
    else base = 100;
    return base;
  }

  /* ------------------------------- ذخیره خروجی ------------------------------- */

  Future<void> _save() async {
    if (_saving) return;
    if (_imageDataUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لطفاً عکس انتخاب کنید')));
      return;
    }
    if ((_titleCtl.text.trim()).isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('برای آگهی یک عنوان بنویسید')));
      return;
    }

    final price = double.tryParse(_priceCtl.text.trim()) ?? 0.0;

    final map = <String, dynamic>{
      'title': _titleCtl.text.trim(),
      'price': price,
      'categoryId': _selectedCategory?.id ?? 'misc',
      'images': <String>[_imageDataUrl!],
      'description': _descCtl.text.trim(),
      'createdAt': DateTime.now(),
    };

    setState(() => _saving = true);
    try {
      if (!mounted) return;
      Navigator.of(context).pop<Map<String, dynamic>>(map);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /* ---------------------------------- UI ---------------------------------- */

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('افزودن با هوش مصنوعی')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            // عکس
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cs.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('عکس', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  AspectRatio(
                    aspectRatio: 16/10,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: cs.surfaceVariant.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _imageDataUrl == null
                          ? Center(
                        child: Text('عکسی انتخاب نشده است',
                            style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                      )
                          : ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(
                          base64Decode(_imageDataUrl!.split(',').last),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: _pickFromGallery,
                        icon: const Icon(Icons.photo_library_outlined),
                        label: const Text('گالری'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: _pickFromCamera,
                        icon: const Icon(Icons.photo_camera_outlined),
                        label: const Text('دوربین'),
                      ),
                      const Spacer(),
                      FilledButton.icon(
                        onPressed: _imageDataUrl == null || _analyzing ? null : _analyze,
                        icon: const Icon(Icons.auto_awesome),
                        label: Text(_analyzing ? 'در حال پردازش…' : 'تحلیل با هوش مصنوعی'),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // اطلاعات
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cs.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('جزئیات آگهی', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _titleCtl,
                    decoration: const InputDecoration(labelText: 'عنوان'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _priceCtl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'قیمت پیشنهادی (CHF)'),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      final picked = await showModalBottomSheet<CategorySpec>(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => const _AiCategoryPickerSheet(),
                      );
                      if (picked != null) {
                        setState(() => _selectedCategory = picked);
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                        border: Border.all(color: cs.outlineVariant),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(_selectedCategory?.icon ?? Icons.category_outlined),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _selectedCategory?.title ?? 'انتخاب دسته‌بندی',
                              style: TextStyle(
                                fontWeight: _selectedCategory == null ? FontWeight.w400 : FontWeight.w600,
                                color: _selectedCategory == null ? cs.onSurfaceVariant : cs.onSurface,
                              ),
                            ),
                          ),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descCtl,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'توضیحات پیشنهادی',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _saving ? null : () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('انصراف'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: const Icon(Icons.check),
                    label: const Text('ثبت آگهی'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/* ---------------------- Picker دسته‌بندی برای صفحهٔ AI ---------------------- */

class _AiCategoryPickerSheet extends StatefulWidget {
  const _AiCategoryPickerSheet();

  @override
  State<_AiCategoryPickerSheet> createState() => _AiCategoryPickerSheetState();
}

class _AiCategoryPickerSheetState extends State<_AiCategoryPickerSheet> {
  final _searchCtl = TextEditingController();
  late final List<CategorySpec> _flat = flattenCategories().toList();

  @override
  void dispose() {
    _searchCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final roots = marketplaceCategories;

    final q = _searchCtl.text.trim().toLowerCase();
    final results = q.isEmpty
        ? <CategorySpec>[]
        : _flat.where((c) => c.title.toLowerCase().contains(q)).toList();

    return SafeArea(
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, controller) {
          return Container(
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 8),
                Container(width: 40, height: 4, decoration: BoxDecoration(color: cs.outlineVariant, borderRadius: BorderRadius.circular(999))),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: TextField(
                    controller: _searchCtl,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'جستجوی دسته…',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: q.isEmpty
                      ? ListView.builder(
                    controller: controller,
                    itemCount: roots.length,
                    itemBuilder: (_, i) {
                      final r = roots[i];
                      return ExpansionTile(
                        leading: Icon(r.icon),
                        title: Text(r.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                        children: [
                          if (r.children.isEmpty)
                            ListTile(
                              leading: Icon(r.icon),
                              title: Text(r.title),
                              onTap: () => Navigator.pop(context, r),
                            )
                          else
                            ...r.children.map((c) => ListTile(
                              leading: Icon(c.icon),
                              title: Text(c.title),
                              onTap: () => Navigator.pop(context, c),
                            )),
                        ],
                      );
                    },
                  )
                      : ListView.builder(
                    controller: controller,
                    itemCount: results.length,
                    itemBuilder: (_, i) {
                      final c = results[i];
                      return ListTile(
                        leading: Icon(c.icon),
                        title: Text(c.title),
                        onTap: () => Navigator.pop(context, c),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

