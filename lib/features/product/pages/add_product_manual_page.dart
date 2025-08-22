// lib/features/product/pages/add_product_manual_page.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ✅ i18n برای چهار زبان
import 'package:bazari_8656/app/i18n/i18n.dart';

// ✅ دسته‌بندی‌ها
import 'package:bazari_8656/data/categories.dart';

// ✅ مکان و ژئوکدینگ برای آدرس خودکار/دستی
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class AddProductManualPage extends StatefulWidget {
  const AddProductManualPage({
    super.key,
    this.initialCategoryId, // ⬅️ جدید: کتگوری اولیه
  });

  final String? initialCategoryId;

  @override
  State<AddProductManualPage> createState() => _AddProductManualPageState();
}

class _AddProductManualPageState extends State<AddProductManualPage> {
  // شورت‌کات ترجمه
  String t(String key) => AppLang.instance.t(key);

  final _form = GlobalKey<FormState>();

  // فیلدهای عمومی
  final _titleCtl = TextEditingController();
  final _priceCtl = TextEditingController();
  final _descCtl  = TextEditingController();

  CategorySpec? _selectedCategory;

  /// تصاویر: لینک http/https یا data:image/jpeg;base64,...
  final List<String> _images = <String>[];

  bool _saving = false;

  /* ======================= وضعیت فرم‌های پویا ======================= */

  // عمومی
  String? _condition; // نو/درحدنو/کارکرده/برای قطعه
  final _brandCtl = TextEditingController();
  final _modelCtl = TextEditingController();

  // خودرو
  final _carBrandCtl = TextEditingController();
  final _carModelCtl = TextEditingController();
  final _carYearCtl = TextEditingController();
  final _carMileageCtl = TextEditingController(); // km
  String? _carFuel;       // بنزین/دیزل/برقی/هیبرید
  String? _carGearbox;    // اتومات/دنده‌ای
  String? _carBody;       // سدان/SUV/هاچ‌بک/کوپه/پیکاپ
  final _carColorCtl = TextEditingController();

  // موتور
  final _motoBrandCtl = TextEditingController();
  final _motoModelCtl = TextEditingController();
  final _motoYearCtl = TextEditingController();
  final _motoCCCtl = TextEditingController(); // CC

  // موبایل
  final _phoneBrandCtl = TextEditingController();
  final _phoneModelCtl = TextEditingController();
  final _phoneStorageCtl = TextEditingController(); // GB
  final _phoneRamCtl = TextEditingController();     // GB
  bool _phoneDualSim = false;

  // لپ‌تاپ
  final _lapBrandCtl = TextEditingController();
  final _lapModelCtl = TextEditingController();
  final _lapCpuCtl = TextEditingController();
  final _lapRamCtl = TextEditingController(); // GB
  final _lapStorageCtl = TextEditingController(); // GB
  final _lapGpuCtl = TextEditingController();
  final _lapScreenCtl = TextEditingController(); // اینچ

  // تلویزیون
  final _tvBrandCtl = TextEditingController();
  final _tvInchCtl = TextEditingController();
  String? _tvPanel; // LED/OLED/QLED/MiniLED
  bool _tvSmart = true;

  // مبلمان
  String? _furnType; // مبل/صندلی/میز/کمد/تخت
  final _furnMaterialCtl = TextEditingController();
  final _furnColorCtl = TextEditingController();

  // لوازم خانگی
  final _appBrandCtl = TextEditingController();
  final _appModelCtl = TextEditingController();
  String? _appEnergy; // A++/A+/A/...

  /* ======================= آدرس (دستی + خودکار) ======================= */
  final _addressCtl = TextEditingController();
  double? _lat;
  double? _lng;
  bool _resolvingLoc = false;

  Future<void> _fillCurrentLocation() async {
    setState(() => _resolvingLoc = true);
    try {
      final service = await Geolocator.isLocationServiceEnabled();
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (!service || perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        throw 'perm';
      }
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      _lat = pos.latitude;
      _lng = pos.longitude;
      final pm = await placemarkFromCoordinates(_lat!, _lng!);
      if (pm.isNotEmpty) {
        final p = pm.first;
        final addr = [
          p.street,
          p.locality,
          p.postalCode,
          p.administrativeArea,
          p.country
        ].where((e) => (e ?? '').trim().isNotEmpty).join(', ');
        _addressCtl.text = addr;
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('location.perm_error'))),
      );
    } finally {
      if (mounted) setState(() => _resolvingLoc = false);
      _scheduleDraftSave();
    }
  }

  Future<void> _geocodeAddress() async {
    final q = _addressCtl.text.trim();
    if (q.isEmpty) return;
    setState(() => _resolvingLoc = true);
    try {
      final list = await locationFromAddress(q);
      if (list.isNotEmpty) {
        _lat = list.first.latitude;
        _lng = list.first.longitude;
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('location.geocode_error'))),
      );
    } finally {
      if (mounted) setState(() => _resolvingLoc = false);
      _scheduleDraftSave();
    }
  }

  /* ========================== Draft autosave ========================== */
  static const _draftKey = 'draft_add_product_manual';
  final List<TextEditingController> _allControllers = [];
  DateTime _lastLoadedAt = DateTime.now();

  @override
  void initState() {
    super.initState();

    // ⬅️ جدید: اگر از هوم کتگوری اولیه آمد، همان را ست کن
    if (widget.initialCategoryId != null && widget.initialCategoryId!.trim().isNotEmpty) {
      final c = _findCategoryById(widget.initialCategoryId!.trim());
      if (c != null) _selectedCategory = c;
    }

    _allControllers.addAll([
      _titleCtl, _priceCtl, _descCtl,
      _brandCtl, _modelCtl,
      _carBrandCtl, _carModelCtl, _carYearCtl, _carMileageCtl, _carColorCtl,
      _motoBrandCtl, _motoModelCtl, _motoYearCtl, _motoCCCtl,
      _phoneBrandCtl, _phoneModelCtl, _phoneStorageCtl, _phoneRamCtl,
      _lapBrandCtl, _lapModelCtl, _lapCpuCtl, _lapRamCtl, _lapStorageCtl, _lapGpuCtl, _lapScreenCtl,
      _tvBrandCtl, _tvInchCtl,
      _furnMaterialCtl, _furnColorCtl,
      _appBrandCtl, _appModelCtl,
      _addressCtl,
    ]);
    for (final c in _allControllers) {
      c.addListener(_scheduleDraftSave);
    }
    _loadDraft();
  }

  @override
  void dispose() {
    for (final c in _allControllers) {
      c.removeListener(_scheduleDraftSave);
    }

    _titleCtl.dispose();
    _priceCtl.dispose();
    _descCtl.dispose();

    _brandCtl.dispose();
    _modelCtl.dispose();

    _carBrandCtl.dispose();
    _carModelCtl.dispose();
    _carYearCtl.dispose();
    _carMileageCtl.dispose();
    _carColorCtl.dispose();

    _motoBrandCtl.dispose();
    _motoModelCtl.dispose();
    _motoYearCtl.dispose();
    _motoCCCtl.dispose();

    _phoneBrandCtl.dispose();
    _phoneModelCtl.dispose();
    _phoneStorageCtl.dispose();
    _phoneRamCtl.dispose();

    _lapBrandCtl.dispose();
    _lapModelCtl.dispose();
    _lapCpuCtl.dispose();
    _lapRamCtl.dispose();
    _lapStorageCtl.dispose();
    _lapGpuCtl.dispose();
    _lapScreenCtl.dispose();

    _tvBrandCtl.dispose();
    _tvInchCtl.dispose();

    _furnMaterialCtl.dispose();
    _furnColorCtl.dispose();

    _appBrandCtl.dispose();
    _appModelCtl.dispose();

    _addressCtl.dispose();

    _draftDebounce?.cancel();
    super.dispose();
  }

  Timer? _draftDebounce;
  void _scheduleDraftSave() {
    _draftDebounce?.cancel();
    _draftDebounce = Timer(const Duration(milliseconds: 400), _saveDraft);
  }

  Future<void> _saveDraft() async {
    if (DateTime.now().difference(_lastLoadedAt).inMilliseconds < 300) return;

    final data = _collectMapForSave();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_draftKey, jsonEncode(data));
  }

  Future<void> _loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_draftKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      _lastLoadedAt = DateTime.now();

      _titleCtl.text = (map['title'] ?? '').toString();
      _priceCtl.text = (map['price']?.toString() ?? '');
      _descCtl.text = (map['description'] ?? '').toString();
      _condition = map['condition'] as String?;

      _images
        ..clear()
        ..addAll(((map['images'] as List?) ?? const []).cast<String>());

      final catId = map['categoryId'] as String?;
      if (catId != null) {
        final cat = _findCategoryById(catId);
        if (cat != null) _selectedCategory = cat;
      }

      final attrs = (map['attrs'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};

      // عمومی
      _brandCtl.text = (attrs['brand'] ?? '').toString();
      _modelCtl.text = (attrs['model'] ?? '').toString();

      // خودرو
      _carBrandCtl.text   = (attrs['brand'] ?? '').toString();
      _carModelCtl.text   = (attrs['model'] ?? '').toString();
      _carYearCtl.text    = (attrs['year']?.toString() ?? '');
      _carMileageCtl.text = (attrs['mileage_km']?.toString() ?? '');
      _carFuel            = attrs['fuel'] as String?;
      _carGearbox         = attrs['gearbox'] as String?;
      _carBody            = attrs['body'] as String?;
      _carColorCtl.text   = (attrs['color'] ?? '').toString();

      // موتور
      _motoBrandCtl.text = (attrs['brand'] ?? '').toString();
      _motoModelCtl.text = (attrs['model'] ?? '').toString();
      _motoYearCtl.text  = (attrs['year']?.toString() ?? '');
      _motoCCCtl.text    = (attrs['engine_cc']?.toString() ?? '');

      // موبایل
      _phoneBrandCtl.text   = (attrs['brand'] ?? '').toString();
      _phoneModelCtl.text   = (attrs['model'] ?? '').toString();
      _phoneStorageCtl.text = (attrs['storage_gb']?.toString() ?? '');
      _phoneRamCtl.text     = (attrs['ram_gb']?.toString() ?? '');
      _phoneDualSim         = (attrs['dual_sim'] as bool?) ?? false;

      // لپتاپ
      _lapBrandCtl.text   = (attrs['brand'] ?? '').toString();
      _lapModelCtl.text   = (attrs['model'] ?? '').toString();
      _lapCpuCtl.text     = (attrs['cpu'] ?? '').toString();
      _lapRamCtl.text     = (attrs['ram_gb']?.toString() ?? '');
      _lapStorageCtl.text = (attrs['storage_gb']?.toString() ?? '');
      _lapGpuCtl.text     = (attrs['gpu'] ?? '').toString();
      _lapScreenCtl.text  = (attrs['screen_inch']?.toString() ?? '');

      // TV
      _tvBrandCtl.text = (attrs['brand'] ?? '').toString();
      _tvInchCtl.text  = (attrs['inch']?.toString() ?? '');
      _tvPanel         = attrs['panel'] as String?;
      _tvSmart         = (attrs['smart'] as bool?) ?? true;

      // مبلمان
      _furnType             = attrs['type'] as String?;
      _furnMaterialCtl.text = (attrs['material'] ?? '').toString();
      _furnColorCtl.text    = (attrs['color'] ?? '').toString();

      // لوازم خانگی
      _appBrandCtl.text = (attrs['brand'] ?? '').toString();
      _appModelCtl.text = (attrs['model'] ?? '').toString();
      _appEnergy        = attrs['energy_class'] as String?;

      // آدرس
      _addressCtl.text = (map['address'] ?? '').toString();
      _lat = (map['lat'] as num?)?.toDouble();
      _lng = (map['lng'] as num?)?.toDouble();

      if (mounted) setState(() {});
    } catch (_) {/* ignore bad draft */}
  }

  Future<void> _clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_draftKey);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t('draft.cleared'))));
  }

  Map<String, dynamic> _collectMapForSave() {
    final price = double.tryParse(_priceCtl.text.trim()) ?? 0.0;

    final attrs = <String, dynamic>{
      if (_condition != null) 'condition': _condition,
    };

    if (_isCar) {
      attrs.addAll({
        'brand': _carBrandCtl.text.trim(),
        'model': _carModelCtl.text.trim(),
        'year': int.tryParse(_carYearCtl.text.trim()),
        'mileage_km': int.tryParse(_carMileageCtl.text.trim()),
        'fuel': _carFuel,
        'gearbox': _carGearbox,
        'body': _carBody,
        'color': _carColorCtl.text.trim(),
      });
    } else if (_isMotorcycle) {
      attrs.addAll({
        'brand': _motoBrandCtl.text.trim(),
        'model': _motoModelCtl.text.trim(),
        'year': int.tryParse(_motoYearCtl.text.trim()),
        'engine_cc': int.tryParse(_motoCCCtl.text.trim()),
      });
    } else if (_isPhone) {
      attrs.addAll({
        'brand': _phoneBrandCtl.text.trim(),
        'model': _phoneModelCtl.text.trim(),
        'storage_gb': int.tryParse(_phoneStorageCtl.text.trim()),
        'ram_gb': int.tryParse(_phoneRamCtl.text.trim()),
        'dual_sim': _phoneDualSim,
      });
    } else if (_isLaptop) {
      attrs.addAll({
        'brand': _lapBrandCtl.text.trim(),
        'model': _lapModelCtl.text.trim(),
        'cpu': _lapCpuCtl.text.trim(),
        'ram_gb': int.tryParse(_lapRamCtl.text.trim()),
        'storage_gb': int.tryParse(_lapStorageCtl.text.trim()),
        'gpu': _lapGpuCtl.text.trim(),
        'screen_inch': double.tryParse(_lapScreenCtl.text.trim()),
      });
    } else if (_isTv) {
      attrs.addAll({
        'brand': _tvBrandCtl.text.trim(),
        'inch': int.tryParse(_tvInchCtl.text.trim()),
        'panel': _tvPanel,
        'smart': _tvSmart,
      });
    } else if (_isFurniture) {
      attrs.addAll({
        'type': _furnType,
        'material': _furnMaterialCtl.text.trim(),
        'color': _furnColorCtl.text.trim(),
      });
    } else if (_isAppliance) {
      attrs.addAll({
        'brand': _appBrandCtl.text.trim(),
        'model': _appModelCtl.text.trim(),
        'energy_class': _appEnergy,
      });
    } else {
      // عمومی
      attrs.addAll({
        'brand': _brandCtl.text.trim(),
        'model': _modelCtl.text.trim(),
      });
    }

    final map = <String, dynamic>{
      'title': _titleCtl.text.trim(),
      'price': price,
      'categoryId': _selectedCategory?.id ?? 'misc',
      'images': List<String>.from(_images),
      'description': _descCtl.text.trim(),
      'condition': _condition,
      'attrs': attrs,
      // آدرس
      'address': _addressCtl.text.trim(),
      'lat': _lat,
      'lng': _lng,
      'createdAt': DateTime.now().toIso8601String(),
    };
    return map;
  }

  /* ============================= تصاویر ============================= */

  Future<void> _pickFromGallery() async {
    try {
      final picker = ImagePicker();
      final files = await picker.pickMultiImage(imageQuality: 85, maxWidth: 2000);
      if (files.isEmpty) return;
      for (final x in files) {
        final bytes = await x.readAsBytes();
        final b64 = base64Encode(bytes);
        _images.add('data:image/jpeg;base64,$b64');
      }
      _scheduleDraftSave();
      if (mounted) setState(() {});
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('images.gallery_error'))),
      );
    }
  }

  Future<void> _pickFromCamera() async {
    try {
      final picker = ImagePicker();
      final x = await picker.pickImage(source: ImageSource.camera, imageQuality: 85, maxWidth: 2000);
      if (x == null) return;
      final bytes = await x.readAsBytes();
      final b64 = base64Encode(bytes);
      _images.add('data:image/jpeg;base64,$b64');
      _scheduleDraftSave();
      if (mounted) setState(() {});
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('images.camera_error'))),
      );
    }
  }

  Future<void> _addByUrlDialog() async {
    final urlCtl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(t('images.add_by_link')),
        content: TextField(
          controller: urlCtl,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'https://... or data:image/jpeg;base64,...',
            labelText: t('images.link'),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(t('common.cancel'))),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(t('common.add'))),
        ],
      ),
    );
    if (ok == true) {
      final raw = urlCtl.text.trim();
      if (raw.isNotEmpty) {
        _images.add(raw);
        _scheduleDraftSave();
        if (mounted) setState(() {});
      }
    }
  }

  Widget _imageThumb(String src) {
    final cs = Theme.of(context).colorScheme;
    if (src.startsWith('data:image')) {
      try {
        final base64Part = src.split(',').last;
        final bytes = base64Decode(base64Part);
        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.memory(bytes, fit: BoxFit.cover),
        );
      } catch (_) {}
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.network(
        src,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          decoration: BoxDecoration(
            color: cs.surfaceVariant,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Center(child: Icon(Icons.broken_image_outlined)),
        ),
      ),
    );
  }

  /* ======================== انتخاب دسته‌بندی ======================== */

  Future<void> _pickCategory() async {
    final picked = await showModalBottomSheet<CategorySpec>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _CategoryPickerSheet(),
    );
    if (picked != null) {
      setState(() => _selectedCategory = picked);
      _scheduleDraftSave();
    }
  }

  bool _catIdContains(Iterable<String> keys) {
    final id = _selectedCategory?.id.toLowerCase() ?? '';
    return keys.any((k) => id.contains(k));
  }

  bool get _isCar        => _catIdContains(['car', 'cars', 'vehicle.car', 'vehicles.cars']);
  bool get _isMotorcycle => _catIdContains(['motor', 'motorcycle', 'bike', 'moto']);
  bool get _isPhone      => _catIdContains(['phone', 'smartphone', 'mobile']);
  bool get _isLaptop     => _catIdContains(['laptop', 'notebook', 'macbook']);
  bool get _isTv         => _catIdContains(['tv', 'television']);
  bool get _isFurniture  => _catIdContains(['furniture', 'sofa', 'chair', 'table', 'bed', 'wardrobe']);
  bool get _isAppliance  => _catIdContains(['appliance', 'home_appliance', 'washer', 'fridge', 'oven', 'vacuum']);

  CategorySpec? _findCategoryById(String id) {
    for (final c in flattenCategories()) {
      if (c.id == id) return c;
    }
    return null;
  }

  // ⬅️ عنوان محلی‌شده‌ی کتگوری/زیرکتگوری
  String _localizedCategoryTitle(CategorySpec c) {
    final tr = AppLang.instance.t;
    // پیدا کردن والد اگر زیرشاخه باشد
    CategorySpec? parent;
    for (final r in marketplaceCategories) {
      if (identical(r, c)) { parent = null; break; }
      if (r.children.any((ch) => identical(ch, c) || ch.id == c.id)) {
        parent = r;
        break;
      }
    }
    if (parent != null) {
      final k = 'cat.${parent.id}.${c.id}';
      final v = tr(k);
      if (v != k) return v;
    }
    final kRoot = 'cat.${c.id}';
    final v2 = tr(kRoot);
    return (v2 != kRoot) ? v2 : c.title;
  }

  /* =========================== ذخیره‌سازی =========================== */

  Future<void> _save() async {
    if (_saving) return;
    final f = _form.currentState;
    if (f == null) return;
    if (!f.validate()) return;

    final map = _collectMapForSave();

    setState(() => _saving = true);
    try {
      // پاک کردن پیش‌نویس بعد از ذخیره موفق
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_draftKey);

      if (!mounted) return;
      Navigator.of(context).pop<Map<String, dynamic>>(map);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /* ============================== UI ============================== */

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(t('add.titleBar')),
        actions: [
          IconButton(
            tooltip: t('add.preview'),
            icon: const Icon(Icons.visibility_outlined),
            onPressed: _showPreview,
          ),
          IconButton(
            tooltip: t('draft.clear'),
            icon: const Icon(Icons.delete_outline),
            onPressed: _clearDraft,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              // اطلاعات اصلی
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(t('add.mainInfo'), style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _titleCtl,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: t('add.title'),
                        hintText: t('add.title.hint'),
                      ),
                      onChanged: (_) => _scheduleDraftSave(),
                      validator: (v) => (v == null || v.trim().isEmpty) ? t('err.required') : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _priceCtl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: t('add.price'),
                        suffixText: 'CHF',
                        hintText: '499.00',
                      ),
                      onChanged: (_) => _scheduleDraftSave(),
                      validator: (v) {
                        final d = double.tryParse((v ?? '').trim());
                        if (d == null) return t('err.price');
                        if (d < 0) return t('err.price.negative');
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    // انتخاب دسته‌بندی
                    InkWell(
                      onTap: _pickCategory,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        decoration: BoxDecoration(
                          border: Border.all(color: cs.outlineVariant),
                          borderRadius: BorderRadius.circular(12),
                          color: cs.surface,
                        ),
                        child: Row(
                          children: [
                            Icon(_selectedCategory?.icon ?? Icons.category_outlined, size: 22),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _selectedCategory == null
                                    ? t('add.category')
                                    : _localizedCategoryTitle(_selectedCategory!),
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
                    // وضعیت
                    DropdownButtonFormField<String>(
                      value: _condition,
                      decoration: InputDecoration(labelText: t('v.status')),
                      items: [
                        DropdownMenuItem(value: 'new', child: Text(t('cond.new'))),
                        DropdownMenuItem(value: 'like_new', child: Text(t('cond.like_new'))),
                        DropdownMenuItem(value: 'used', child: Text(t('cond.used'))),
                        DropdownMenuItem(value: 'for_parts', child: Text(t('cond.parts'))),
                      ],
                      onChanged: (v) { setState(() => _condition = v); _scheduleDraftSave(); },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // فرم پویا بر اساس کتگوری
              _Card(child: _buildCategoryForm(context, tt)),

              const SizedBox(height: 12),

              // توضیحات
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(t('add.description'), style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descCtl,
                      maxLines: 5,
                      onChanged: (_) => _scheduleDraftSave(),
                      decoration: InputDecoration(
                        hintText: t('add.desc.hint'),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // آدرس
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(t('addr.title'), style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _addressCtl,
                      decoration: InputDecoration(
                        labelText: t('addr.address'),
                        hintText: t('addr.hint'),
                        suffixIcon: IconButton(
                          onPressed: _resolvingLoc ? null : _geocodeAddress,
                          icon: const Icon(Icons.location_searching),
                          tooltip: t('addr.search'),
                        ),
                      ),
                      onChanged: (_) => _scheduleDraftSave(),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _resolvingLoc ? null : _fillCurrentLocation,
                            icon: _resolvingLoc
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.my_location_outlined),
                            label: Text(t('addr.use_current')),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            (_lat != null && _lng != null)
                                ? 'Lat: ${_lat!.toStringAsFixed(5)}, Lng: ${_lng!.toStringAsFixed(5)}'
                                : t('addr.no_coords'),
                            maxLines: 2,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // عکس‌ها
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Text(t('photos'), style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                        const Spacer(),
                        IconButton(
                          tooltip: t('photos.gallery'),
                          onPressed: _pickFromGallery,
                          icon: const Icon(Icons.photo_library_outlined),
                        ),
                        IconButton(
                          tooltip: t('photos.camera'),
                          onPressed: _pickFromCamera,
                          icon: const Icon(Icons.photo_camera_outlined),
                        ),
                        IconButton(
                          tooltip: t('photos.add_link'),
                          onPressed: _addByUrlDialog,
                          icon: const Icon(Icons.link_outlined),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_images.isEmpty)
                      Container(
                        height: 120,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: cs.surfaceVariant.withOpacity(0.45),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: cs.outlineVariant),
                        ),
                        child: Text(t('photos.none')),
                      )
                    else
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                        ),
                        itemCount: _images.length,
                        itemBuilder: (_, i) {
                          final url = _images[i];
                          return Stack(
                            fit: StackFit.expand,
                            children: [
                              _imageThumb(url),
                              Positioned(
                                right: 4,
                                top: 4,
                                child: InkWell(
                                  onTap: () {
                                    _images.removeAt(i);
                                    _scheduleDraftSave();
                                    setState(() {});
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.black45,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: const Icon(Icons.close, size: 16, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    if (_images.length >= 10) ...[
                      const SizedBox(height: 8),
                      Text(t('photos.limit'),
                          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                    ],
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
                      label: Text(t('common.cancel')),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: const Icon(Icons.check),
                      label: Text(t('common.save_and_back')),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /* ===================== سازنده فرم پویا ===================== */

  Widget _buildCategoryForm(BuildContext context, TextTheme tt) {
    if (_selectedCategory == null) return _genericForm(tt);
    if (_isCar)        return _carForm(tt);
    if (_isMotorcycle) return _motorForm(tt);
    if (_isPhone)      return _phoneForm(tt);
    if (_isLaptop)     return _laptopForm(tt);
    if (_isTv)         return _tvForm(tt);
    if (_isFurniture)  return _furnitureForm(tt);
    if (_isAppliance)  return _applianceForm(tt);
    return _genericForm(tt);
  }

  // عمومی
  Widget _genericForm(TextTheme tt) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(t('add.generic'), style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        TextFormField(
          controller: _brandCtl,
          onChanged: (_) => _scheduleDraftSave(),
          decoration: InputDecoration(labelText: t('p.brand')),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _modelCtl,
          onChanged: (_) => _scheduleDraftSave(),
          decoration: InputDecoration(labelText: t('p.model')),
        ),
      ],
    );
  }

  // خودرو
  Widget _carForm(TextTheme tt) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(t('car.specs'), style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        TextFormField(
          controller: _carBrandCtl,
          decoration: InputDecoration(labelText: t('car.brand')),
          onChanged: (_) => _scheduleDraftSave(),
          validator: (v) => (v==null || v.trim().isEmpty) ? t('err.required') : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _carModelCtl,
          decoration: InputDecoration(labelText: t('car.model')),
          onChanged: (_) => _scheduleDraftSave(),
          validator: (v) => (v==null || v.trim().isEmpty) ? t('err.required') : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _carYearCtl,
          decoration: InputDecoration(labelText: t('car.year')),
          keyboardType: TextInputType.number,
          onChanged: (_) => _scheduleDraftSave(),
          validator: (v) => (int.tryParse((v??'').trim())==null) ? t('err.year') : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _carMileageCtl,
          decoration: InputDecoration(labelText: t('car.mileage')),
          keyboardType: TextInputType.number,
          onChanged: (_) => _scheduleDraftSave(),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _carFuel,
          decoration: InputDecoration(labelText: t('car.fuel')),
          items: [
            DropdownMenuItem(value: 'gasoline', child: Text(t('fuel.gasoline'))),
            DropdownMenuItem(value: 'diesel', child: Text(t('fuel.diesel'))),
            DropdownMenuItem(value: 'hybrid', child: Text(t('fuel.hybrid'))),
            DropdownMenuItem(value: 'electric', child: Text(t('fuel.electric'))),
          ],
          onChanged: (v) { setState(() => _carFuel = v); _scheduleDraftSave(); },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _carGearbox,
          decoration: InputDecoration(labelText: t('car.trans')),
          items: [
            DropdownMenuItem(value: 'auto', child: Text(t('trans.auto'))),
            DropdownMenuItem(value: 'manual', child: Text(t('trans.manual'))),
          ],
          onChanged: (v) { setState(() => _carGearbox = v); _scheduleDraftSave(); },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _carBody,
          decoration: InputDecoration(labelText: t('car.body')),
          items: [
            DropdownMenuItem(value: 'sedan', child: Text(t('body.sedan'))),
            DropdownMenuItem(value: 'suv', child: Text(t('body.suv'))),
            DropdownMenuItem(value: 'hatchback', child: Text(t('body.hatchback'))),
            DropdownMenuItem(value: 'coupe', child: Text(t('body.coupe'))),
            DropdownMenuItem(value: 'pickup', child: Text(t('body.pickup'))),
          ],
          onChanged: (v) { setState(() => _carBody = v); _scheduleDraftSave(); },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _carColorCtl,
          onChanged: (_) => _scheduleDraftSave(),
          decoration: InputDecoration(labelText: t('car.color')),
        ),
      ],
    );
  }

  // موتور
  Widget _motorForm(TextTheme tt) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(t('moto.specs'), style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        TextFormField(
            controller: _motoBrandCtl,
            decoration: InputDecoration(labelText: t('moto.brand')),
            onChanged: (_) => _scheduleDraftSave(),
            validator: (v)=> (v==null||v.trim().isEmpty)? t('err.required') : null),
        const SizedBox(height: 12),
        TextFormField(
            controller: _motoModelCtl,
            decoration: InputDecoration(labelText: t('moto.model')),
            onChanged: (_) => _scheduleDraftSave(),
            validator: (v)=> (v==null||v.trim().isEmpty)? t('err.required') : null),
        const SizedBox(height: 12),
        TextFormField(
          controller: _motoYearCtl,
          decoration: InputDecoration(labelText: t('moto.year')),
          keyboardType: TextInputType.number,
          onChanged: (_) => _scheduleDraftSave(),
          validator: (v)=> (int.tryParse((v??'').trim())==null)? t('err.year') : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _motoCCCtl,
          decoration: InputDecoration(labelText: t('moto.cc')),
          keyboardType: TextInputType.number,
          onChanged: (_) => _scheduleDraftSave(),
        ),
      ],
    );
  }

  // موبایل
  Widget _phoneForm(TextTheme tt) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(t('phone.specs'), style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        TextFormField(
            controller: _phoneBrandCtl,
            decoration: InputDecoration(labelText: t('phone.brand')),
            onChanged: (_)=>_scheduleDraftSave(),
            validator: (v)=> (v==null||v.trim().isEmpty)? t('err.required') : null),
        const SizedBox(height: 12),
        TextFormField(
            controller: _phoneModelCtl,
            decoration: InputDecoration(labelText: t('phone.model')),
            onChanged: (_)=>_scheduleDraftSave(),
            validator: (v)=> (v==null||v.trim().isEmpty)? t('err.required') : null),
        const SizedBox(height: 12),
        TextFormField(
          controller: _phoneStorageCtl,
          decoration: InputDecoration(labelText: t('phone.storage')),
          keyboardType: TextInputType.number,
          onChanged: (_) => _scheduleDraftSave(),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _phoneRamCtl,
          decoration: InputDecoration(labelText: t('phone.ram')),
          keyboardType: TextInputType.number,
          onChanged: (_) => _scheduleDraftSave(),
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(t('phone.dualSim')),
          value: _phoneDualSim,
          onChanged: (v) { setState(()=>_phoneDualSim = v); _scheduleDraftSave(); },
        ),
      ],
    );
  }

  // لپ‌تاپ
  Widget _laptopForm(TextTheme tt) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(t('laptop.specs'), style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        TextFormField(
            controller: _lapBrandCtl,
            decoration: InputDecoration(labelText: t('laptop.brand')),
            onChanged: (_)=>_scheduleDraftSave(),
            validator: (v)=> (v==null||v.trim().isEmpty)? t('err.required') : null),
        const SizedBox(height: 12),
        TextFormField(
            controller: _lapModelCtl,
            decoration: InputDecoration(labelText: t('laptop.model')),
            onChanged: (_)=>_scheduleDraftSave(),
            validator: (v)=> (v==null||v.trim().isEmpty)? t('err.required') : null),
        const SizedBox(height: 12),
        TextFormField(
          controller: _lapCpuCtl,
          decoration: InputDecoration(labelText: t('laptop.cpu')),
          onChanged: (_)=>_scheduleDraftSave(),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _lapRamCtl,
          decoration: InputDecoration(labelText: t('laptop.ram')),
          keyboardType: TextInputType.number,
          onChanged: (_) => _scheduleDraftSave(),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _lapStorageCtl,
          decoration: InputDecoration(labelText: t('laptop.storage')),
          keyboardType: TextInputType.number,
          onChanged: (_) => _scheduleDraftSave(),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _lapGpuCtl,
          decoration: InputDecoration(labelText: t('laptop.gpu')),
          onChanged: (_)=>_scheduleDraftSave(),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _lapScreenCtl,
          decoration: InputDecoration(labelText: t('laptop.screen')),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) => _scheduleDraftSave(),
        ),
      ],
    );
  }

  // تلویزیون
  Widget _tvForm(TextTheme tt) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(t('tv.specs'), style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        TextFormField(
            controller: _tvBrandCtl,
            decoration: InputDecoration(labelText: t('tv.brand')),
            onChanged: (_)=>_scheduleDraftSave(),
            validator: (v)=> (v==null||v.trim().isEmpty)? t('err.required') : null),
        const SizedBox(height: 12),
        TextFormField(
          controller: _tvInchCtl,
          decoration: InputDecoration(labelText: t('tv.size')),
          keyboardType: TextInputType.number,
          onChanged: (_) => _scheduleDraftSave(),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _tvPanel,
          decoration: InputDecoration(labelText: t('tv.panel')),
          items: const [
            DropdownMenuItem(value: 'LED', child: Text('LED')),
            DropdownMenuItem(value: 'OLED', child: Text('OLED')),
            DropdownMenuItem(value: 'QLED', child: Text('QLED')),
            DropdownMenuItem(value: 'MiniLED', child: Text('MiniLED')),
          ],
          onChanged: (v) { setState(() => _tvPanel = v); _scheduleDraftSave(); },
        ),
        const SizedBox(height: 4),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(t('tv.smart')),
          value: _tvSmart,
          onChanged: (v) { setState(()=>_tvSmart = v); _scheduleDraftSave(); },
        ),
      ],
    );
  }

  // مبلمان
  Widget _furnitureForm(TextTheme tt) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(t('furn.specs'), style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _furnType,
          decoration: InputDecoration(labelText: t('furn.type')),
          items: [
            DropdownMenuItem(value: 'sofa', child: Text(t('furn.sofa'))),
            DropdownMenuItem(value: 'chair', child: Text(t('furn.chair'))),
            DropdownMenuItem(value: 'table', child: Text(t('furn.table'))),
            DropdownMenuItem(value: 'wardrobe', child: Text(t('furn.wardrobe'))),
            DropdownMenuItem(value: 'bed', child: Text(t('furn.bed'))),
          ],
          onChanged: (v) { setState(() => _furnType = v); _scheduleDraftSave(); },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _furnMaterialCtl,
          decoration: InputDecoration(labelText: t('furn.material')),
          onChanged: (_)=>_scheduleDraftSave(),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _furnColorCtl,
          decoration: InputDecoration(labelText: t('furn.color')),
          onChanged: (_)=>_scheduleDraftSave(),
        ),
      ],
    );
  }

  // لوازم خانگی
  Widget _applianceForm(TextTheme tt) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(t('appliance.specs'), style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        TextFormField(
            controller: _appBrandCtl,
            decoration: InputDecoration(labelText: t('appliance.brand')),
            onChanged: (_)=>_scheduleDraftSave(),
            validator: (v)=> (v==null||v.trim().isEmpty)? t('err.required') : null),
        const SizedBox(height: 12),
        TextFormField(
            controller: _appModelCtl,
            decoration: InputDecoration(labelText: t('appliance.model')),
            onChanged: (_)=>_scheduleDraftSave(),
            validator: (v)=> (v==null||v.trim().isEmpty)? t('err.required') : null),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _appEnergy,
          decoration: InputDecoration(labelText: t('appliance.energy')),
          items: const [
            DropdownMenuItem(value: 'A++', child: Text('A++')),
            DropdownMenuItem(value: 'A+', child: Text('A+')),
            DropdownMenuItem(value: 'A', child: Text('A')),
            DropdownMenuItem(value: 'B', child: Text('B')),
          ],
          onChanged: (v) { setState(() => _appEnergy = v); _scheduleDraftSave(); },
        ),
      ],
    );
  }

  /* ========================== Preview ========================== */

  void _showPreview() {
    final m = _collectMapForSave();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (c) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16,16,16,24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.remove_red_eye_outlined),
                  const SizedBox(width: 8),
                  Text(t('add.preview'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  IconButton(onPressed: ()=>Navigator.pop(c), icon: const Icon(Icons.close)),
                ],
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: (m['images'] as List).isNotEmpty
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _previewImage((m['images'] as List).first as String),
                )
                    : const Icon(Icons.image_outlined, size: 36),
                title: Text(m['title']?.toString() ?? ''),
                subtitle: Text((m['categoryId']?.toString() ?? 'misc')),
                trailing: Text('${(m['price'] as num).toStringAsFixed(2)} CHF',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(t('add.preview_attrs'), style: Theme.of(context).textTheme.titleMedium),
              ),
              const SizedBox(height: 6),
              _attrsWrap((m['attrs'] as Map<String, dynamic>)),
              const SizedBox(height: 12),
              if ((m['address'] as String?)?.isNotEmpty == true)
                Row(
                  children: [
                    const Icon(Icons.place_outlined, size: 18),
                    const SizedBox(width: 6),
                    Expanded(child: Text(m['address'] as String)),
                  ],
                ),
              if (m['lat'] != null && m['lng'] != null) ...[
                const SizedBox(height: 6),
                Text('Lat: ${(m['lat'] as num).toStringAsFixed(5)},  Lng: ${(m['lng'] as num).toStringAsFixed(5)}'),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _previewImage(String src) {
    if (src.startsWith('data:image')) {
      try {
        final base64Part = src.split(',').last;
        final bytes = base64Decode(base64Part);
        return Image.memory(bytes, width: 56, height: 56, fit: BoxFit.cover);
      } catch (_) {}
    }
    return Image.network(src, width: 56, height: 56, fit: BoxFit.cover);
  }

  Widget _attrsWrap(Map<String, dynamic> attrs) {
    if (attrs.isEmpty) return const Text('—');
    final entries = attrs.entries
        .where((e) => e.value != null && e.value.toString().isNotEmpty)
        .map((e) => '${e.key}: ${e.value}')
        .toList();
    return Align(
      alignment: Alignment.centerLeft,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: entries.map((t) =>
            Chip(label: Text(t, overflow: TextOverflow.ellipsis, maxLines: 1))
        ).toList(),
      ),
    );
  }
}

/* ============================ ویجت‌های کمکی ============================ */

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}

/// BottomSheet انتخاب دسته/زیر‌دسته (با ترجمه‌ی چهارضبانه)
class _CategoryPickerSheet extends StatefulWidget {
  const _CategoryPickerSheet();

  @override
  State<_CategoryPickerSheet> createState() => _CategoryPickerSheetState();
}

class _CategoryPickerSheetState extends State<_CategoryPickerSheet> {
  final _searchCtl = TextEditingController();
  late List<CategorySpec> _flat;

  String t(String key) => AppLang.instance.t(key);

  @override
  void initState() {
    super.initState();
    _flat = flattenCategories().toList();
  }

  @override
  void dispose() {
    _searchCtl.dispose();
    super.dispose();
  }

  CategorySpec? _parentOf(CategorySpec c) {
    for (final r in marketplaceCategories) {
      if (identical(r, c)) return null;
      if (r.children.any((ch) => identical(ch, c) || ch.id == c.id)) return r;
    }
    return null;
  }

  String _locTitle(CategorySpec c) {
    final parent = _parentOf(c);
    if (parent != null) {
      final k = 'cat.${parent.id}.${c.id}';
      final v = t(k);
      if (v != k) return v;
    }
    final rootKey = 'cat.${c.id}';
    final vr = t(rootKey);
    return (vr != rootKey) ? vr : c.title;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final query = _searchCtl.text.trim().toLowerCase();
    final roots = marketplaceCategories;

    List<CategorySpec> results = _flat;
    if (query.isNotEmpty) {
      results = _flat.where((c) {
        final title = _locTitle(c).toLowerCase();
        return title.contains(query) || c.id.toLowerCase().contains(query);
      }).toList();
    }

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
                Container(width: 40, height: 4,
                    decoration: BoxDecoration(color: cs.outlineVariant, borderRadius: BorderRadius.circular(999))),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: TextField(
                    controller: _searchCtl,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: t('search'),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: query.isEmpty
                      ? ListView.builder(
                    controller: controller,
                    itemCount: roots.length,
                    itemBuilder: (_, i) {
                      final r = roots[i];
                      final children = r.children;
                      final rTitle = _locTitle(r);
                      return ExpansionTile(
                        leading: Icon(r.icon),
                        title: Text(rTitle, style: const TextStyle(fontWeight: FontWeight.w700)),
                        children: [
                          if (children.isEmpty)
                            ListTile(
                              leading: Icon(r.icon),
                              title: Text(rTitle),
                              onTap: () => Navigator.pop(context, r),
                            )
                          else
                            ...children.map((c) => ListTile(
                              leading: Icon(c.icon),
                              title: Text(_locTitle(c)),
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
                      final parent = _parentOf(c);
                      final subtitle = parent == null ? null : t('cat.${parent.id}');
                      return ListTile(
                        leading: Icon(c.icon),
                        title: Text(_locTitle(c)),
                        subtitle: subtitle == null ? null : Text(subtitle),
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
