// lib/app/i18n/i18n.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// i18n سبک با ۴ زبان (fa-AF, ps-AF, de-DE, en-US) + RTL/LTR + persistence.
/// از ChangeNotifier ارث می‌بَرد تا تغییر زبان را به UI اعلام کند.
class AppLang extends ChangeNotifier {
  AppLang._();
  static final AppLang instance = AppLang._();

  static const _kLang = 'app_locale_language_code';
  static const _kCountry = 'app_locale_country_code';

  Locale _locale = const Locale('fa', 'AF'); // پیش‌فرض: دری
  Locale get locale => _locale;

  static const List<Locale> supportedLocales = <Locale>[
    Locale('fa', 'AF'), // دری (RTL)
    Locale('ps', 'AF'), // پشتو (RTL)
    Locale('de', 'DE'), // آلمانی
    Locale('en', 'US'), // انگلیسی
  ];

  /// alias برای کد قدیمی
  List<Locale> get supported => supportedLocales;

  TextDirection get textDirection {
    final lc = _locale.languageCode.toLowerCase();
    return (lc == 'fa' || lc == 'ps') ? TextDirection.rtl : TextDirection.ltr;
  }

  bool get isRtl => textDirection == TextDirection.rtl;

  /// تنظیم زبان + ذخیره در SharedPreferences
  Future<void> setLocale(Locale l, {bool persist = true}) async {
    final fixed = _normalizeToSupported(l);
    _locale = fixed;
    if (persist) {
      final p = await SharedPreferences.getInstance();
      await p.setString(_kLang, fixed.languageCode);
      await p.setString(_kCountry, fixed.countryCode ?? '');
    }
    notifyListeners();
  }

  /// بارگذاری زبان ذخیره‌شده (اگر نبود، از Locale دستگاه استفاده می‌کند)
  Future<void> loadSaved() async {
    final p = await SharedPreferences.getInstance();
    final lang = p.getString(_kLang);
    final country = p.getString(_kCountry);

    if (lang != null && lang.isNotEmpty) {
      await setLocale(Locale(lang, (country ?? '').isEmpty ? null : country), persist: false);
      return;
    }

    final device = WidgetsBinding.instance.platformDispatcher.locale;
    await setLocale(device, persist: false);
  }

  /// ترجمه‌ی کلید
  String t(String key) {
    final m = _dict[_locale]?.call();
    if (m != null && m.containsKey(key)) return m[key]!;
    // fallback به انگلیسی
    final en = _dict[const Locale('en', 'US')]!.call();
    return en[key] ?? key;
  }

  /* ---------------------- دیکشنری‌ها ---------------------- */

  static final Map<Locale, Map<String, String> Function()> _dict = {
    const Locale('fa', 'AF'): _faAF,
    const Locale('ps', 'AF'): _psAF,
    const Locale('de', 'DE'): _deDE,
    const Locale('en', 'US'): _enUS,
  };

  // اگر Locale پشتیبانی نشد، نزدیک‌ترین را برمی‌گرداند
  Locale _normalizeToSupported(Locale? l) {
    if (l == null) return _locale;
    for (final s in supportedLocales) {
      if (s.languageCode == l.languageCode &&
          (s.countryCode ?? '') == (l.countryCode ?? '')) {
        return s;
      }
    }
    for (final s in supportedLocales) {
      if (s.languageCode == l.languageCode) return s;
    }
    return const Locale('fa', 'AF');
  }

  /* ========================= دری (fa-AF) ========================= */
  static Map<String, String> _faAF() => {
    // عمومی
    'language': 'زبان',
    'search': 'جستجو...',
    'category': 'دسته‌بندی',
    'refresh': 'بروزرسانی',
    'unknown': '—',
    'common.category': 'دسته',
    'common.price': 'قیمت',
    'common.date': 'تاریخ',
    'common.code': 'کد',
    'common.cancel': 'انصراف',
    'common.add': 'افزودن',
    'common.save_and_back': 'ذخیره و بازگشت',

    // محصول
    'product.details': 'جزئیات محصول',
    'product.description': 'توضیحات',
    'product.highlights': 'هایلایت‌ها',
    'product.specs': 'مشخصات',
    'product.similar': 'محصولات مشابه',
    'product.chat': 'گفتگو با فروشنده',
    'product.favorites': 'علاقه‌مندی',
    'product.copy': 'کپی',
    'product.copied': 'کپی شد',

    // فروشنده
    'seller.trades': 'معامله',

    // نقشه
    'map.unavailable': 'نقشه در دسترس نیست',

    /* --- AppBar Add Product / Draft --- */
    'add.titleBar': 'افزودن آگهی',
    'add.preview': 'پیش‌نمایش',
    'add.preview_attrs': 'ویژگی‌ها',
    'draft.clear': 'پاک کردن پیش‌نویس',
    'draft.cleared': 'پیش‌نویس پاک شد',

    /* --- فرم افزودن --- */
    'add.mainInfo': 'اطلاعات اصلی',
    'add.title': 'عنوان',
    'add.title.hint': 'عنوان کوتاه برای محصول...',
    'add.price': 'قیمت',
    'add.category': 'انتخاب دسته',
    'v.status': 'وضعیت',
    'cond.new': 'نو',
    'cond.like_new': 'در حد نو',
    'cond.used': 'کارکرده',
    'cond.parts': 'برای قطعات',

    'add.generic': 'مشخصات کلی',
    'p.brand': 'برند',
    'p.model': 'مدل',

    'add.description': 'توضیحات',
    'add.desc.hint': 'توضیحاتی دربارهٔ وضعیت، لوازم، ضمانت و ...',

    /* --- آدرس --- */
    'addr.title': 'آدرس و موقعیت',
    'addr.address': 'آدرس',
    'addr.hint': 'کوچه/خیابان، شهر، کدپستی...',
    'addr.search': 'جستجوی مختصات',
    'addr.use_current': 'موقعیت فعلی من',
    'addr.no_coords': 'مختصات تعیین نشده',

    /* --- عکس‌ها --- */
    'photos': 'عکس‌ها',
    'photos.gallery': 'از گالری',
    'photos.camera': 'دوربین',
    'photos.add_link': 'افزودن لینک',
    'photos.none': 'عکسی اضافه نشده است',
    'photos.limit': 'حداکثر ۱۰ عکس قابل افزودن است.',

    /* --- خطاهای رسانه --- */
    'images.add_by_link': 'افزودن با لینک',
    'images.link': 'لینک عکس',
    'images.gallery_error': 'خطا در دسترسی به گالری',
    'images.camera_error': 'خطا در باز کردن دوربین',

    /* --- خطاهای مکان --- */
    'location.perm_error': 'نیاز به دسترسی موقعیت یا فعال بودن GPS است.',
    'location.geocode_error': 'تبدیل آدرس به مختصات انجام نشد.',

    /* --- خودرو --- */
    'car.specs': 'مشخصات خودرو',
    'car.brand': 'برند',
    'car.model': 'مدل',
    'car.year': 'سال ساخت',
    'car.mileage': 'کارکرد (کیلومتر)',
    'car.fuel': 'سوخت',
    'car.trans': 'گیربکس',
    'car.body': 'بدنه',
    'car.color': 'رنگ',
    'fuel.gasoline': 'بنزین',
    'fuel.diesel': 'دیزل',
    'fuel.hybrid': 'هیبرید',
    'fuel.electric': 'برقی',
    'trans.auto': 'اتومات',
    'trans.manual': 'دستی',
    'body.sedan': 'سدان',
    'body.suv': 'SUV',
    'body.hatchback': 'هاچ‌بک',
    'body.coupe': 'کوپه',
    'body.pickup': 'پیکاپ',

    /* --- موترسایکل --- */
    'moto.specs': 'مشخصات موترسایکل',
    'moto.brand': 'برند',
    'moto.model': 'مدل',
    'moto.year': 'سال ساخت',
    'moto.cc': 'حجم موتور (سی‌سی)',

    /* --- موبایل --- */
    'phone.specs': 'مشخصات موبایل',
    'phone.brand': 'برند',
    'phone.model': 'مدل',
    'phone.storage': 'حافظه (GB)',
    'phone.ram': 'RAM (GB)',
    'phone.dualSim': 'دو سیم‌کارت',

    /* --- لپ‌تاپ --- */
    'laptop.specs': 'مشخصات لپ‌تاپ',
    'laptop.brand': 'برند',
    'laptop.model': 'مدل',
    'laptop.cpu': 'CPU',
    'laptop.ram': 'RAM (GB)',
    'laptop.storage': 'حافظه (GB)',
    'laptop.gpu': 'GPU',
    'laptop.screen': 'اندازه صفحه (اینچ)',

    /* --- تلویزیون --- */
    'tv.specs': 'مشخصات تلویزیون',
    'tv.brand': 'برند',
    'tv.size': 'اندازه (اینچ)',
    'tv.panel': 'نوع پنل',
    'tv.smart': 'هوشمند (Smart TV)',

    /* --- فرنیچر --- */
    'furn.specs': 'مشخصات فرنیچر',
    'furn.type': 'نوع',
    'furn.material': 'متریال',
    'furn.color': 'رنگ',
    'furn.sofa': 'مبل',
    'furn.chair': 'صندلی',
    'furn.table': 'میز',
    'furn.wardrobe': 'کمد',
    'furn.bed': 'تخت',

    /* --- لوازم خانگی --- */
    'appliance.specs': 'مشخصات لوازم خانگی',
    'appliance.brand': 'برند',
    'appliance.model': 'مدل',
    'appliance.energy': 'رده انرژی',

    /* --- خطاهای اعتبارسنجی --- */
    'err.required': 'این فیلد الزامی است',
    'err.price': 'قیمت معتبر نیست',
    'err.price.negative': 'قیمت نمی‌تواند منفی باشد',
    'err.year': 'سال ساخت معتبر نیست',

    /* --- کتگوری‌ها (ریشه) --- */
    'cat.vehicles': 'وسایل نقلیه',
    'cat.real_estate': 'ملکیات',
    'cat.electronics': 'الکترونیک',
    'cat.home_garden': 'خانه و باغ',
    'cat.fashion': 'پوشاک و فیشن',
    'cat.beauty': 'سلامتی و زیبایی',
    'cat.sports': 'ورزشی',
    'cat.baby': 'اطفال',
    'cat.hobbies': 'علاقه‌مندی‌ها',
    'cat.pet': 'حیوانات خانگی',
    'cat.food': 'خوراکه',
    'cat.office': 'اداری',
    'cat.education': 'تعلیم/کورس',
    'cat.services': 'خدمات',
    'cat.jobs': 'وظایف',
    'cat.events': 'ایونت/بلیط',
    'cat.health': 'تندرستی',
    'cat.industrial': 'صنعتی',
    'cat.agri': 'زراعتی',
    'cat.construction': 'ساختمانی',
    'cat.security': 'امنیتی',
    'cat.it': 'شبکه/آی‌تی',
    'cat.other': 'متفرقه',

    /* --- زیرشاخه‌ها --- */
    'cat.vehicles.car': 'موتر/خودرو',
    'cat.vehicles.motorcycle': 'موترسایکل',
    'cat.vehicles.truck': 'موتر باربری',
    'cat.vehicles.bike': 'بایسکل',
    'cat.vehicles.parts': 'پُرزه و لوازم',
    'cat.real_estate.apartment': 'آپارتمان',
    'cat.real_estate.house': 'خانه',
    'cat.real_estate.room': 'اتاق',
    'cat.real_estate.office': 'دفتر/تجاری',
    'cat.real_estate.land': 'زمین',
    'cat.electronics.phone': 'موبایل',
    'cat.electronics.laptop': 'لپ‌تاپ',
    'cat.electronics.tablet': 'تبلت',
    'cat.electronics.camera': 'کمره',
    'cat.electronics.tv': 'تلویزیون/صوتی',
    'cat.electronics.console': 'کنسول بازی',
    'cat.home_garden.appliance': 'لوازم خانگی',
    'cat.home_garden.furniture': 'فرنیچر',
    'cat.home_garden.tools': 'ابزار',
    'cat.home_garden.garden': 'باغبانی',
    'cat.home_garden.decor': 'دکور',
    'cat.fashion.men_cloth': 'لباس مردانه',
    'cat.fashion.women_cloth': 'لباس زنانه',
    'cat.fashion.shoes': 'کفش',
    'cat.fashion.bags': 'بکس و کیف',
    'cat.fashion.watch': 'ساعت/جواهرات',
    'cat.beauty.cosmetics': 'لوازم آرایشی',
    'cat.beauty.hairtools': 'وسایل مو/برقی',
    'cat.sports.fitness': 'فیتنس',
    'cat.sports.outdoor': 'کمپ/کوهنوردی',
    'cat.sports.team_sport': 'تیمی',
    'cat.baby.stroller': 'کالای کودک',
    'cat.baby.toys': 'اسباب‌بازی',
    'cat.hobbies.art': 'هنر',
    'cat.hobbies.music': 'موسیقی/ساز',
    'cat.hobbies.collectibles': 'کلکسیون',
    'cat.hobbies.books': 'کتاب',
    'cat.hobbies.boardgames': 'بازی رومیزی',
  };

  /* ========================= پشتو (ps-AF) ========================= */
  static Map<String, String> _psAF() => {
    // عمومي
    'language': 'ژبه',
    'search': 'لټون...',
    'category': 'کټګوري',
    'refresh': 'نوی کول',
    'unknown': '—',
    'common.category': 'کټګوري',
    'common.price': 'بیه',
    'common.date': 'نېټه',
    'common.code': 'کوډ',
    'common.cancel': 'لغوه',
    'common.add': 'زیاتول',
    'common.save_and_back': 'ثبت او بېرته',

    // محصول
    'product.details': 'د محصول جزئيات',
    'product.description': 'تشريح',
    'product.highlights': 'هایلايټونه',
    'product.specs': 'مشخصات',
    'product.similar': 'ورته محصولات',
    'product.chat': 'له پلورونکي سره خبرې',
    'product.favorites': 'خوښې',
    'product.copy': 'کاپي',
    'product.copied': 'کاپي شو',

    // پلورونکی
    'seller.trades': 'معاملې',

    // نقشه
    'map.unavailable': 'نقشه شتون نه لري',

    // Draft / Add
    'add.titleBar': 'اعلان زیاتول',
    'add.preview': 'مخکتنه',
    'add.preview_attrs': 'ځانګړنې',
    'draft.clear': 'مسوده پاکول',
    'draft.cleared': 'مسوده پاکه شوه',

    'add.mainInfo': 'اصلي معلومات',
    'add.title': 'سرلیک',
    'add.title.hint': 'د محصول لنډ سرلیک...',
    'add.price': 'بیه',
    'add.category': 'کټګوري ټاکل',
    'v.status': 'حالت',
    'cond.new': 'نوی',
    'cond.like_new': 'نږدې نوی',
    'cond.used': 'استعمال شوی',
    'cond.parts': 'د پرزو لپاره',

    'add.generic': 'عمومي مشخصات',
    'p.brand': 'برنډ',
    'p.model': 'ماډل',

    'add.description': 'تشريح',
    'add.desc.hint': 'د حالت، لوازمو، تضمین او ... په اړه',

    // آدرس
    'addr.title': 'پته او موقعیت',
    'addr.address': 'پته',
    'addr.hint': 'کوڅه، ښار، پوسټ کوډ...',
    'addr.search': 'مختصات لټول',
    'addr.use_current': 'زما اوسنی موقعیت',
    'addr.no_coords': 'مختصات ټاکل شوي نه دي',

    // عکسونه
    'photos': 'انځورونه',
    'photos.gallery': 'له ګالري',
    'photos.camera': 'کمره',
    'photos.add_link': 'د لینک له لارې',
    'photos.none': 'هیڅ انځور نشته',
    'photos.limit': 'تر ۱۰ انځورونو پورې زیاتولی شئ.',

    'images.add_by_link': 'د لینک له لارې زیاتول',
    'images.link': 'د انځور لینک',
    'images.gallery_error': 'د ګالري د لاسرسي تېروتنه',
    'images.camera_error': 'کمره نه پرانیستل شوه',

    'location.perm_error': 'د موقعیت اجازه یا GPS ته اړتیا ده.',
    'location.geocode_error': 'پته مختصاتو ته واوښتله نه.',

    // موټر
    'car.specs': 'د موټر مشخصات',
    'car.brand': 'برنډ',
    'car.model': 'ماډل',
    'car.year': 'کال',
    'car.mileage': 'کارېدنه (کم)',
    'car.fuel': 'سوند',
    'car.trans': 'ګیربکس',
    'car.body': 'بدنه',
    'car.color': 'رنګ',
    'fuel.gasoline': 'پټرول',
    'fuel.diesel': 'ډیزل',
    'fuel.hybrid': 'هایبریډ',
    'fuel.electric': 'برقي',
    'trans.auto': 'اتومات',
    'trans.manual': 'لاسۍ',
    'body.sedan': 'سېدان',
    'body.suv': 'SUV',
    'body.hatchback': 'هاچ‌بک',
    'body.coupe': 'کوپه',
    'body.pickup': 'پیک‌اپ',

    // موټرسایکل
    'moto.specs': 'د موټرسایکل ځانګړنې',
    'moto.brand': 'برنډ',
    'moto.model': 'ماډل',
    'moto.year': 'کال',
    'moto.cc': 'انجن (CC)',

    // موبایل
    'phone.specs': 'د موبایل ځانګړنې',
    'phone.brand': 'برنډ',
    'phone.model': 'ماډل',
    'phone.storage': 'حافظه (GB)',
    'phone.ram': 'RAM (GB)',
    'phone.dualSim': 'دو سیم',

    // لپ‌تاپ
    'laptop.specs': 'د لپ‌تاپ ځانګړنې',
    'laptop.brand': 'برنډ',
    'laptop.model': 'ماډل',
    'laptop.cpu': 'CPU',
    'laptop.ram': 'RAM (GB)',
    'laptop.storage': 'حافظه (GB)',
    'laptop.gpu': 'GPU',
    'laptop.screen': 'سکرین (انچ)',

    // تلویزیون
    'tv.specs': 'د تلویزیون ځانګړنې',
    'tv.brand': 'برنډ',
    'tv.size': 'اندازه (انچ)',
    'tv.panel': 'پینل',
    'tv.smart': 'سماټ ټي‌وي',

    // فرنیچر
    'furn.specs': 'د فرنیچر ځانګړنې',
    'furn.type': 'ډول',
    'furn.material': 'مواد',
    'furn.color': 'رنګ',
    'furn.sofa': 'صوفه',
    'furn.chair': 'چوکی',
    'furn.table': 'مېز',
    'furn.wardrobe': 'کپړۍ',
    'furn.bed': 'چپرکټ',

    // وسایل کور
    'appliance.specs': 'د کور وسایلو ځانګړنې',
    'appliance.brand': 'برنډ',
    'appliance.model': 'ماډل',
    'appliance.energy': 'انرژي درجه',

    // خطاګانې
    'err.required': 'دا ساحه ضروري ده',
    'err.price': 'بیه ناسمه ده',
    'err.price.negative': 'بیه منفي نه شي کېدای',
    'err.year': 'کال ناسمه دی',

    // کتګوری‌ها (ریښه او فرعي) — مانند دری (لهجوي توپیر نه‌اړین)
    'cat.vehicles': 'موټرونه',
    'cat.real_estate': 'ملکيت',
    'cat.electronics': 'الکترونیک',
    'cat.home_garden': 'کور او باغ',
    'cat.fashion': 'فېشن/کالي',
    'cat.beauty': 'روغتيا او ښکلا',
    'cat.sports': 'ورزش',
    'cat.baby': 'ماشومان',
    'cat.hobbies': 'شوقونه',
    'cat.pet': 'کورني حیوانات',
    'cat.food': 'خوراک',
    'cat.office': 'اداري',
    'cat.education': 'ښوونه/کورس',
    'cat.services': 'خدمات',
    'cat.jobs': 'دندې',
    'cat.events': 'ایونټ/ټکټ',
    'cat.health': 'روغتيا',
    'cat.industrial': 'صنعتي',
    'cat.agri': 'کرنه',
    'cat.construction': 'ساختماني',
    'cat.security': 'امنیتي',
    'cat.it': 'آی‌ټي/شبکه',
    'cat.other': 'نور',
    'cat.vehicles.car': 'موټر',
    'cat.vehicles.motorcycle': 'موټرسایکل',
    'cat.vehicles.truck': 'لارۍ',
    'cat.vehicles.bike': 'سایکل',
    'cat.vehicles.parts': 'پرزې',
    'cat.real_estate.apartment': 'اپارتمان',
    'cat.real_estate.house': 'کور',
    'cat.real_estate.room': 'کوټه',
    'cat.real_estate.office': 'دفتر/تجارتي',
    'cat.real_estate.land': 'ځمکه',
    'cat.electronics.phone': 'موبایل',
    'cat.electronics.laptop': 'لیپ ټاپ',
    'cat.electronics.tablet': 'ټابلیټ',
    'cat.electronics.camera': 'کمره',
    'cat.electronics.tv': 'تلویزیون/اډیو',
    'cat.electronics.console': 'لوبې کنسول',
    'cat.home_garden.appliance': 'د کور وسایل',
    'cat.home_garden.furniture': 'فرنیچر',
    'cat.home_garden.tools': 'اوزار',
    'cat.home_garden.garden': 'باغباني',
    'cat.home_garden.decor': 'سجاوٹ',
    'cat.fashion.men_cloth': 'د نارینه جامې',
    'cat.fashion.women_cloth': 'د ښځو جامې',
    'cat.fashion.shoes': 'بوټان',
    'cat.fashion.bags': 'بکس/کيف',
    'cat.fashion.watch': 'ساعت/زیورات',
    'cat.beauty.cosmetics': 'آرایشي توکي',
    'cat.beauty.hairtools': 'د ویښتو برقي وسایل',
    'cat.sports.fitness': 'فټنس',
    'cat.sports.outdoor': 'بهرنی/کمپ',
    'cat.sports.team_sport': 'ټیمي ورزش',
    'cat.baby.stroller': 'د ماشوم توکي',
    'cat.baby.toys': 'لوبتکې',
    'cat.hobbies.art': 'هنر',
    'cat.hobbies.music': 'موسیقي/اله',
    'cat.hobbies.collectibles': 'کلکسیون',
    'cat.hobbies.books': 'کتابونه',
    'cat.hobbies.boardgames': 'بورډ لوبې',
  };

  /* ========================= آلمانی (de-DE) ========================= */
  static Map<String, String> _deDE() => {
    // Allgemein
    'language': 'Sprache',
    'search': 'Suchen...',
    'category': 'Kategorie',
    'refresh': 'Aktualisieren',
    'unknown': '—',
    'common.category': 'Kategorie',
    'common.price': 'Preis',
    'common.date': 'Datum',
    'common.code': 'Code',
    'common.cancel': 'Abbrechen',
    'common.add': 'Hinzufügen',
    'common.save_and_back': 'Speichern & zurück',

    // Produkt
    'product.details': 'Produktdetails',
    'product.description': 'Beschreibung',
    'product.highlights': 'Highlights',
    'product.specs': 'Spezifikationen',
    'product.similar': 'Ähnliche Produkte',
    'product.chat': 'Chat mit Verkäufer',
    'product.favorites': 'Favoriten',
    'product.copy': 'Kopieren',
    'product.copied': 'Kopiert',

    // Verkäufer
    'seller.trades': 'Verkäufe',

    // Karte
    'map.unavailable': 'Karte nicht verfügbar',

    // Draft / Add
    'add.titleBar': 'Anzeige erstellen',
    'add.preview': 'Vorschau',
    'add.preview_attrs': 'Eigenschaften',
    'draft.clear': 'Entwurf löschen',
    'draft.cleared': 'Entwurf gelöscht',

    'add.mainInfo': 'Hauptinformationen',
    'add.title': 'Titel',
    'add.title.hint': 'Kurzer Titel für den Artikel...',
    'add.price': 'Preis',
    'add.category': 'Kategorie wählen',
    'v.status': 'Zustand',
    'cond.new': 'Neu',
    'cond.like_new': 'Wie neu',
    'cond.used': 'Gebraucht',
    'cond.parts': 'Für Ersatzteile',

    'add.generic': 'Allgemeine Spezifikationen',
    'p.brand': 'Marke',
    'p.model': 'Modell',

    'add.description': 'Beschreibung',
    'add.desc.hint': 'Infos zu Zustand, Zubehör, Garantie ...',

    // Adresse
    'addr.title': 'Adresse & Standort',
    'addr.address': 'Adresse',
    'addr.hint': 'Straße, Stadt, PLZ ...',
    'addr.search': 'Koordinaten suchen',
    'addr.use_current': 'Aktuellen Standort',
    'addr.no_coords': 'Keine Koordinaten',

    // Fotos
    'photos': 'Fotos',
    'photos.gallery': 'Aus Galerie',
    'photos.camera': 'Kamera',
    'photos.add_link': 'Per Link',
    'photos.none': 'Keine Fotos hinzugefügt',
    'photos.limit': 'Maximal 10 Fotos möglich.',

    'images.add_by_link': 'Per Link hinzufügen',
    'images.link': 'Bild-Link',
    'images.gallery_error': 'Fehler beim Zugriff auf Galerie',
    'images.camera_error': 'Kamera konnte nicht geöffnet werden',

    'location.perm_error': 'Standortberechtigung bzw. GPS erforderlich.',
    'location.geocode_error': 'Adresse konnte nicht gefunden werden.',

    // Auto
    'car.specs': 'Fahrzeugspezifikationen',
    'car.brand': 'Marke',
    'car.model': 'Modell',
    'car.year': 'Baujahr',
    'car.mileage': 'Kilometerstand',
    'car.fuel': 'Kraftstoff',
    'car.trans': 'Getriebe',
    'car.body': 'Karosserie',
    'car.color': 'Farbe',
    'fuel.gasoline': 'Benzin',
    'fuel.diesel': 'Diesel',
    'fuel.hybrid': 'Hybrid',
    'fuel.electric': 'Elektrisch',
    'trans.auto': 'Automatik',
    'trans.manual': 'Manuell',
    'body.sedan': 'Limousine',
    'body.suv': 'SUV',
    'body.hatchback': 'Kompakt',
    'body.coupe': 'Coupé',
    'body.pickup': 'Pickup',

    // Motorrad
    'moto.specs': 'Motorradspezifikationen',
    'moto.brand': 'Marke',
    'moto.model': 'Modell',
    'moto.year': 'Baujahr',
    'moto.cc': 'Hubraum (cc)',

    // Smartphone
    'phone.specs': 'Smartphone-Spezifikationen',
    'phone.brand': 'Marke',
    'phone.model': 'Modell',
    'phone.storage': 'Speicher (GB)',
    'phone.ram': 'RAM (GB)',
    'phone.dualSim': 'Dual-SIM',

    // Laptop
    'laptop.specs': 'Laptop-Spezifikationen',
    'laptop.brand': 'Marke',
    'laptop.model': 'Modell',
    'laptop.cpu': 'CPU',
    'laptop.ram': 'RAM (GB)',
    'laptop.storage': 'Speicher (GB)',
    'laptop.gpu': 'GPU',
    'laptop.screen': 'Bildschirm (Zoll)',

    // TV
    'tv.specs': 'TV-Spezifikationen',
    'tv.brand': 'Marke',
    'tv.size': 'Größe (Zoll)',
    'tv.panel': 'Panel',
    'tv.smart': 'Smart TV',

    // Möbel
    'furn.specs': 'Möbelspezifikationen',
    'furn.type': 'Typ',
    'furn.material': 'Material',
    'furn.color': 'Farbe',
    'furn.sofa': 'Sofa',
    'furn.chair': 'Stuhl',
    'furn.table': 'Tisch',
    'furn.wardrobe': 'Kleiderschrank',
    'furn.bed': 'Bett',

    // Haushaltsgeräte
    'appliance.specs': 'Gerätespezifikationen',
    'appliance.brand': 'Marke',
    'appliance.model': 'Modell',
    'appliance.energy': 'Energieklasse',

    // Validierung
    'err.required': 'Pflichtfeld',
    'err.price': 'Ungültiger Preis',
    'err.price.negative': 'Preis darf nicht negativ sein',
    'err.year': 'Ungültiges Baujahr',

    // Kategorien (Root + Unterkategorien)
    'cat.vehicles': 'Fahrzeuge',
    'cat.real_estate': 'Immobilien',
    'cat.electronics': 'Elektronik',
    'cat.home_garden': 'Haus & Garten',
    'cat.fashion': 'Mode',
    'cat.beauty': 'Gesundheit & Schönheit',
    'cat.sports': 'Sport',
    'cat.baby': 'Baby & Kinder',
    'cat.hobbies': 'Hobbys',
    'cat.pet': 'Haustiere',
    'cat.food': 'Lebensmittel',
    'cat.office': 'Büro',
    'cat.education': 'Bildung/Kurse',
    'cat.services': 'Dienstleistungen',
    'cat.jobs': 'Jobs',
    'cat.events': 'Events/Tickets',
    'cat.health': 'Gesundheit',
    'cat.industrial': 'Industrie',
    'cat.agri': 'Landwirtschaft',
    'cat.construction': 'Bau',
    'cat.security': 'Sicherheit',
    'cat.it': 'IT/Netzwerk',
    'cat.other': 'Sonstiges',
    'cat.vehicles.car': 'Auto',
    'cat.vehicles.motorcycle': 'Motorrad',
    'cat.vehicles.truck': 'LKW',
    'cat.vehicles.bike': 'Fahrrad',
    'cat.vehicles.parts': 'Teile & Zubehör',
    'cat.real_estate.apartment': 'Wohnung',
    'cat.real_estate.house': 'Haus',
    'cat.real_estate.room': 'Zimmer',
    'cat.real_estate.office': 'Büro/Gewerbe',
    'cat.real_estate.land': 'Grundstück',
    'cat.electronics.phone': 'Smartphone',
    'cat.electronics.laptop': 'Laptop',
    'cat.electronics.tablet': 'Tablet',
    'cat.electronics.camera': 'Kamera',
    'cat.electronics.tv': 'TV/Audio',
    'cat.electronics.console': 'Spielkonsole',
    'cat.home_garden.appliance': 'Haushaltsgeräte',
    'cat.home_garden.furniture': 'Möbel',
    'cat.home_garden.tools': 'Werkzeuge',
    'cat.home_garden.garden': 'Garten',
    'cat.home_garden.decor': 'Deko',
    'cat.fashion.men_cloth': 'Herrenbekleidung',
    'cat.fashion.women_cloth': 'Damenbekleidung',
    'cat.fashion.shoes': 'Schuhe',
    'cat.fashion.bags': 'Taschen',
    'cat.fashion.watch': 'Uhren/Schmuck',
    'cat.beauty.cosmetics': 'Kosmetik',
    'cat.beauty.hairtools': 'Haargeräte',
    'cat.sports.fitness': 'Fitness',
    'cat.sports.outdoor': 'Outdoor/Camping',
    'cat.sports.team_sport': 'Teamsport',
    'cat.baby.stroller': 'Kinderartikel',
    'cat.baby.toys': 'Spielzeug',
    'cat.hobbies.art': 'Kunst',
    'cat.hobbies.music': 'Musik/Instrumente',
    'cat.hobbies.collectibles': 'Sammlerstücke',
    'cat.hobbies.books': 'Bücher',
    'cat.hobbies.boardgames': 'Brettspiele',
  };

  /* ========================= انگلیسی (en-US) ========================= */
  static Map<String, String> _enUS() => {
    // Common
    'language': 'Language',
    'search': 'Search...',
    'category': 'Category',
    'refresh': 'Refresh',
    'unknown': '—',
    'common.category': 'Category',
    'common.price': 'Price',
    'common.date': 'Date',
    'common.code': 'Code',
    'common.cancel': 'Cancel',
    'common.add': 'Add',
    'common.save_and_back': 'Save & back',

    // Product
    'product.details': 'Product Details',
    'product.description': 'Description',
    'product.highlights': 'Highlights',
    'product.specs': 'Specifications',
    'product.similar': 'Similar Products',
    'product.chat': 'Chat with Seller',
    'product.favorites': 'Favorites',
    'product.copy': 'Copy',
    'product.copied': 'Copied',

    // Seller
    'seller.trades': 'deals',

    // Map
    'map.unavailable': 'Map unavailable',

    // Draft / Add
    'add.titleBar': 'Create Listing',
    'add.preview': 'Preview',
    'add.preview_attrs': 'Attributes',
    'draft.clear': 'Clear draft',
    'draft.cleared': 'Draft cleared',

    'add.mainInfo': 'Main info',
    'add.title': 'Title',
    'add.title.hint': 'Short title for the item...',
    'add.price': 'Price',
    'add.category': 'Choose category',
    'v.status': 'Condition',
    'cond.new': 'New',
    'cond.like_new': 'Like new',
    'cond.used': 'Used',
    'cond.parts': 'For parts',

    'add.generic': 'Generic specs',
    'p.brand': 'Brand',
    'p.model': 'Model',

    'add.description': 'Description',
    'add.desc.hint': 'Details about condition, accessories, warranty...',

    // Address
    'addr.title': 'Address & Location',
    'addr.address': 'Address',
    'addr.hint': 'Street, city, postal code...',
    'addr.search': 'Lookup coordinates',
    'addr.use_current': 'Use current location',
    'addr.no_coords': 'No coordinates',

    // Photos
    'photos': 'Photos',
    'photos.gallery': 'From gallery',
    'photos.camera': 'Camera',
    'photos.add_link': 'Add by link',
    'photos.none': 'No photos added',
    'photos.limit': 'Up to 10 photos allowed.',

    'images.add_by_link': 'Add by link',
    'images.link': 'Image link',
    'images.gallery_error': 'Failed to access gallery',
    'images.camera_error': 'Failed to open camera',

    'location.perm_error': 'Location permission/GPS required.',
    'location.geocode_error': 'Failed to geocode the address.',

    // Car
    'car.specs': 'Car specs',
    'car.brand': 'Brand',
    'car.model': 'Model',
    'car.year': 'Year',
    'car.mileage': 'Mileage (km)',
    'car.fuel': 'Fuel',
    'car.trans': 'Transmission',
    'car.body': 'Body type',
    'car.color': 'Color',
    'fuel.gasoline': 'Gasoline',
    'fuel.diesel': 'Diesel',
    'fuel.hybrid': 'Hybrid',
    'fuel.electric': 'Electric',
    'trans.auto': 'Automatic',
    'trans.manual': 'Manual',
    'body.sedan': 'Sedan',
    'body.suv': 'SUV',
    'body.hatchback': 'Hatchback',
    'body.coupe': 'Coupe',
    'body.pickup': 'Pickup',

    // Motorcycle
    'moto.specs': 'Motorcycle specs',
    'moto.brand': 'Brand',
    'moto.model': 'Model',
    'moto.year': 'Year',
    'moto.cc': 'Engine (cc)',

    // Phone
    'phone.specs': 'Phone specs',
    'phone.brand': 'Brand',
    'phone.model': 'Model',
    'phone.storage': 'Storage (GB)',
    'phone.ram': 'RAM (GB)',
    'phone.dualSim': 'Dual SIM',

    // Laptop
    'laptop.specs': 'Laptop specs',
    'laptop.brand': 'Brand',
    'laptop.model': 'Model',
    'laptop.cpu': 'CPU',
    'laptop.ram': 'RAM (GB)',
    'laptop.storage': 'Storage (GB)',
    'laptop.gpu': 'GPU',
    'laptop.screen': 'Screen (inch)',

    // TV
    'tv.specs': 'TV specs',
    'tv.brand': 'Brand',
    'tv.size': 'Size (inch)',
    'tv.panel': 'Panel',
    'tv.smart': 'Smart TV',

    // Furniture
    'furn.specs': 'Furniture specs',
    'furn.type': 'Type',
    'furn.material': 'Material',
    'furn.color': 'Color',
    'furn.sofa': 'Sofa',
    'furn.chair': 'Chair',
    'furn.table': 'Table',
    'furn.wardrobe': 'Wardrobe',
    'furn.bed': 'Bed',

    // Appliance
    'appliance.specs': 'Appliance specs',
    'appliance.brand': 'Brand',
    'appliance.model': 'Model',
    'appliance.energy': 'Energy class',

    // Validation
    'err.required': 'This field is required',
    'err.price': 'Invalid price',
    'err.price.negative': 'Price cannot be negative',
    'err.year': 'Invalid year',

    // Categories (root + sub)
    'cat.vehicles': 'Vehicles',
    'cat.real_estate': 'Real Estate',
    'cat.electronics': 'Electronics',
    'cat.home_garden': 'Home & Garden',
    'cat.fashion': 'Fashion',
    'cat.beauty': 'Health & Beauty',
    'cat.sports': 'Sports',
    'cat.baby': 'Baby',
    'cat.hobbies': 'Hobbies',
    'cat.pet': 'Pets',
    'cat.food': 'Food',
    'cat.office': 'Office',
    'cat.education': 'Education/Courses',
    'cat.services': 'Services',
    'cat.jobs': 'Jobs',
    'cat.events': 'Events/Tickets',
    'cat.health': 'Health',
    'cat.industrial': 'Industrial',
    'cat.agri': 'Agriculture',
    'cat.construction': 'Construction',
    'cat.security': 'Security',
    'cat.it': 'IT/Network',
    'cat.other': 'Other',
    'cat.vehicles.car': 'Car',
    'cat.vehicles.motorcycle': 'Motorcycle',
    'cat.vehicles.truck': 'Truck',
    'cat.vehicles.bike': 'Bicycle',
    'cat.vehicles.parts': 'Parts & Accessories',
    'cat.real_estate.apartment': 'Apartment',
    'cat.real_estate.house': 'House',
    'cat.real_estate.room': 'Room',
    'cat.real_estate.office': 'Office/Commercial',
    'cat.real_estate.land': 'Land',
    'cat.electronics.phone': 'Phone',
    'cat.electronics.laptop': 'Laptop',
    'cat.electronics.tablet': 'Tablet',
    'cat.electronics.camera': 'Camera',
    'cat.electronics.tv': 'TV/Audio',
    'cat.electronics.console': 'Game Console',
    'cat.home_garden.appliance': 'Appliance',
    'cat.home_garden.furniture': 'Furniture',
    'cat.home_garden.tools': 'Tools',
    'cat.home_garden.garden': 'Gardening',
    'cat.home_garden.decor': 'Decor',
    'cat.fashion.men_cloth': 'Men Clothing',
    'cat.fashion.women_cloth': 'Women Clothing',
    'cat.fashion.shoes': 'Shoes',
    'cat.fashion.bags': 'Bags',
    'cat.fashion.watch': 'Watches/Jewelry',
    'cat.beauty.cosmetics': 'Cosmetics',
    'cat.beauty.hairtools': 'Hair Tools',
    'cat.sports.fitness': 'Fitness',
    'cat.sports.outdoor': 'Outdoor/Camping',
    'cat.sports.team_sport': 'Team Sports',
    'cat.baby.stroller': 'Baby Items',
    'cat.baby.toys': 'Toys',
    'cat.hobbies.art': 'Art',
    'cat.hobbies.music': 'Music/Instruments',
    'cat.hobbies.collectibles': 'Collectibles',
    'cat.hobbies.books': 'Books',
    'cat.hobbies.boardgames': 'Board Games',
  };
}
