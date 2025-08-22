// lib/data/categories.dart
import 'package:flutter/material.dart';
import 'package:bazari_8656/app/i18n/i18n.dart';

/// کتگوری با عناوین چهاربانه
class CategorySpec {
  final String id;
  final IconData icon;
  final List<CategorySpec> children;

  /// عناوین برای زبان‌های مختلف
  final String fa; // دری
  final String ps; // پشتو
  final String de; // آلمانی
  final String en; // انگلیسی

  const CategorySpec({
    required this.id,
    required this.icon,
    required this.fa,
    required this.ps,
    required this.de,
    required this.en,
    this.children = const [],
  });

  /// عنوان محلی‌شده براساس زبان انتخاب‌شده در برنامه
  String get title {
    final code = AppLang.instance.locale.languageCode;
    switch (code) {
      case 'fa':
        return fa;
      case 'ps':
        return ps;
      case 'de':
        return de;
      case 'en':
      default:
        return en;
    }
  }
}

/// نوع فیلد در فرمِ داینامیک
enum AttrType { text, number, select, toggle, multiselect, date }

/// شِمای یک فیلد
class AttrSpec {
  final String id;
  final String label;
  final AttrType type;
  final bool required;
  final List<String>? options; // برای select/multiselect
  final String? unit;          // مثلاً km, m², GB
  const AttrSpec({
    required this.id,
    required this.label,
    required this.type,
    this.required = false,
    this.options,
    this.unit,
  });
}

/// درخت کتگوری‌ها با چهار زبان
const List<CategorySpec> marketplaceCategories = [
  CategorySpec(
    id: 'vehicles',
    fa: 'وسایل نقلیه',
    ps: 'ترانسپورټ',
    de: 'Fahrzeuge',
    en: 'Vehicles',
    icon: Icons.directions_car_outlined,
    children: [
      CategorySpec(
        id: 'car',
        fa: 'موتر/خودرو',
        ps: 'موټر',
        de: 'Auto',
        en: 'Car',
        icon: Icons.directions_car,
      ),
      CategorySpec(
        id: 'motorcycle',
        fa: 'موترسایکِل',
        ps: 'موټرسایکل',
        de: 'Motorrad',
        en: 'Motorcycle',
        icon: Icons.two_wheeler,
      ),
      CategorySpec(
        id: 'truck',
        fa: 'موتر باربری',
        ps: 'لارۍ',
        de: 'Lkw',
        en: 'Truck',
        icon: Icons.local_shipping_outlined,
      ),
      CategorySpec(
        id: 'bike',
        fa: 'بایسکل',
        ps: 'سایکل',
        de: 'Fahrrad',
        en: 'Bicycle',
        icon: Icons.pedal_bike,
      ),
      CategorySpec(
        id: 'parts',
        fa: 'پُرزه و لوازم',
        ps: 'پرزې او لوازم',
        de: 'Ersatzteile',
        en: 'Parts',
        icon: Icons.build_outlined,
      ),
    ],
  ),

  CategorySpec(
    id: 'real_estate',
    fa: 'ملکیات',
    ps: 'ملکیتونه',
    de: 'Immobilien',
    en: 'Real Estate',
    icon: Icons.home_outlined,
    children: [
      CategorySpec(
        id: 'apartment',
        fa: 'آپارتمان',
        ps: 'اپارتمان',
        de: 'Wohnung',
        en: 'Apartment',
        icon: Icons.apartment_outlined,
      ),
      CategorySpec(
        id: 'house',
        fa: 'خانه',
        ps: 'کور',
        de: 'Haus',
        en: 'House',
        icon: Icons.house_outlined,
      ),
      CategorySpec(
        id: 'room',
        fa: 'اتاق',
        ps: 'کوټه',
        de: 'Zimmer',
        en: 'Room',
        icon: Icons.meeting_room_outlined,
      ),
      CategorySpec(
        id: 'office',
        fa: 'دفتر/تجاری',
        ps: 'دفتر/تجارتي',
        de: 'Büro/Gewerbe',
        en: 'Office/Commercial',
        icon: Icons.business_outlined,
      ),
      CategorySpec(
        id: 'land',
        fa: 'زمین',
        ps: 'ځمکه',
        de: 'Grundstück',
        en: 'Land/Plot',
        icon: Icons.terrain_outlined,
      ),
    ],
  ),

  CategorySpec(
    id: 'electronics',
    fa: 'الکترونیک',
    ps: 'برقي وسایل',
    de: 'Elektronik',
    en: 'Electronics',
    icon: Icons.devices_other_outlined,
    children: [
      CategorySpec(
        id: 'phone',
        fa: 'موبایل',
        ps: 'موبایل',
        de: 'Handy',
        en: 'Phone',
        icon: Icons.smartphone,
      ),
      CategorySpec(
        id: 'laptop',
        fa: 'لپ‌تاپ',
        ps: 'لپټاپ',
        de: 'Laptop',
        en: 'Laptop',
        icon: Icons.laptop_mac,
      ),
      CategorySpec(
        id: 'tablet',
        fa: 'تبلت',
        ps: 'ټابلیټ',
        de: 'Tablet',
        en: 'Tablet',
        icon: Icons.tablet_android,
      ),
      CategorySpec(
        id: 'camera',
        fa: 'کمره',
        ps: 'کمره',
        de: 'Kamera',
        en: 'Camera',
        icon: Icons.photo_camera_outlined,
      ),
      CategorySpec(
        id: 'tv',
        fa: 'تلویزیون/صوتی',
        ps: 'تلویزیون/آوازي',
        de: 'TV/Audio',
        en: 'TV/Audio',
        icon: Icons.tv_outlined,
      ),
      CategorySpec(
        id: 'console',
        fa: 'کنسول بازی',
        ps: 'د لوبو کنسول',
        de: 'Spielkonsole',
        en: 'Game Console',
        icon: Icons.sports_esports_outlined,
      ),
    ],
  ),

  CategorySpec(
    id: 'home_garden',
    fa: 'خانه و باغ',
    ps: 'کور او باغ',
    de: 'Haus & Garten',
    en: 'Home & Garden',
    icon: Icons.chair_outlined,
    children: [
      CategorySpec(
        id: 'appliance',
        fa: 'لوازم خانگی',
        ps: 'د کور وسایل',
        de: 'Haushaltsgeräte',
        en: 'Appliances',
        icon: Icons.kitchen_outlined,
      ),
      CategorySpec(
        id: 'furniture',
        fa: 'فرنیچر',
        ps: 'فرنیچر',
        de: 'Möbel',
        en: 'Furniture',
        icon: Icons.chair_alt_outlined,
      ),
      CategorySpec(
        id: 'tools',
        fa: 'ابزار',
        ps: 'اوزار',
        de: 'Werkzeuge',
        en: 'Tools',
        icon: Icons.handyman_outlined,
      ),
      CategorySpec(
        id: 'garden',
        fa: 'باغبانی',
        ps: 'باغباني',
        de: 'Garten',
        en: 'Gardening',
        icon: Icons.grass_outlined,
      ),
      CategorySpec(
        id: 'decor',
        fa: 'دکور',
        ps: 'سجावट',
        de: 'Deko',
        en: 'Decor',
        icon: Icons.wallpaper_outlined,
      ),
    ],
  ),

  CategorySpec(
    id: 'fashion',
    fa: 'پوشاک و فیشن',
    ps: 'فېشن/کالي',
    de: 'Mode',
    en: 'Fashion',
    icon: Icons.checkroom_outlined,
    children: [
      CategorySpec(
        id: 'men_cloth',
        fa: 'لباس مردانه',
        ps: 'د سړو کالي',
        de: 'Herrenbekleidung',
        en: 'Men\'s Clothing',
        icon: Icons.man_2_outlined,
      ),
      CategorySpec(
        id: 'women_cloth',
        fa: 'لباس زنانه',
        ps: 'د ښځو کالي',
        de: 'Damenbekleidung',
        en: 'Women\'s Clothing',
        icon: Icons.woman_2_outlined,
      ),
      CategorySpec(
        id: 'shoes',
        fa: 'کفش',
        ps: 'بوټونه',
        de: 'Schuhe',
        en: 'Shoes',
        icon: Icons.hiking_outlined,
      ),
      CategorySpec(
        id: 'bags',
        fa: 'بکس و کیف',
        ps: 'بکس/کیف',
        de: 'Taschen',
        en: 'Bags',
        icon: Icons.backpack_outlined,
      ),
      CategorySpec(
        id: 'watch',
        fa: 'ساعت/جواهرات',
        ps: 'ساعت/ګاڼې',
        de: 'Uhren/Schmuck',
        en: 'Watches/Jewelry',
        icon: Icons.watch_outlined,
      ),
    ],
  ),

  CategorySpec(
    id: 'beauty',
    fa: 'سلامتی و زیبایی',
    ps: 'روغتیا او ښکلا',
    de: 'Gesundheit & Schönheit',
    en: 'Health & Beauty',
    icon: Icons.spa_outlined,
    children: [
      CategorySpec(
        id: 'cosmetics',
        fa: 'لوازم آرایشی',
        ps: 'آرایشي توکي',
        de: 'Kosmetik',
        en: 'Cosmetics',
        icon: Icons.brush_outlined,
      ),
      CategorySpec(
        id: 'hairtools',
        fa: 'وسایل مو/برقی',
        ps: 'د ويښتو برقي وسایل',
        de: 'Haargeräte',
        en: 'Hair Tools',
        icon: Icons.energy_savings_leaf_outlined,
      ),
    ],
  ),

  CategorySpec(
    id: 'sports',
    fa: 'ورزشی',
    ps: 'سپورتي',
    de: 'Sport',
    en: 'Sports',
    icon: Icons.sports_basketball_outlined,
    children: [
      CategorySpec(
        id: 'fitness',
        fa: 'فیتنس',
        ps: 'فټنس',
        de: 'Fitness',
        en: 'Fitness',
        icon: Icons.fitness_center_outlined,
      ),
      CategorySpec(
        id: 'outdoor',
        fa: 'کمپ/کوهنوردی',
        ps: 'کمپ/غر ختل',
        de: 'Outdoor/Camping',
        en: 'Outdoor/Camping',
        icon: Icons.landscape_outlined,
      ),
      CategorySpec(
        id: 'team_sport',
        fa: 'تیمی',
        ps: 'ډلېزې لوبې',
        de: 'Teamsport',
        en: 'Team Sports',
        icon: Icons.sports_soccer_outlined,
      ),
    ],
  ),

  CategorySpec(
    id: 'baby',
    fa: 'اطفال',
    ps: 'ماشومان',
    de: 'Baby & Kind',
    en: 'Baby & Kids',
    icon: Icons.child_friendly_outlined,
    children: [
      CategorySpec(
        id: 'stroller',
        fa: 'کالای کودک',
        ps: 'د ماشوم توکي',
        de: 'Kinderartikel',
        en: 'Baby Gear',
        icon: Icons.stroller_outlined,
      ),
      CategorySpec(
        id: 'toys',
        fa: 'اسباب‌بازی',
        ps: 'لوبتکي',
        de: 'Spielzeug',
        en: 'Toys',
        icon: Icons.toys_outlined,
      ),
    ],
  ),

  CategorySpec(
    id: 'hobbies',
    fa: 'علاقه‌مندی‌ها',
    ps: 'شوقونه',
    de: 'Hobby & Freizeit',
    en: 'Hobbies',
    icon: Icons.palette_outlined,
    children: [
      CategorySpec(
        id: 'art',
        fa: 'هنر',
        ps: 'هنر',
        de: 'Kunst',
        en: 'Art',
        icon: Icons.color_lens_outlined,
      ),
      CategorySpec(
        id: 'music',
        fa: 'موسیقی/ساز',
        ps: 'موسیقي/اوزار',
        de: 'Musik/Instrumente',
        en: 'Music/Instruments',
        icon: Icons.music_note_outlined,
      ),
      CategorySpec(
        id: 'collectibles',
        fa: 'کلکسیون',
        ps: 'کلکسیون',
        de: 'Sammlerstücke',
        en: 'Collectibles',
        icon: Icons.auto_awesome_outlined,
      ),
      CategorySpec(
        id: 'books',
        fa: 'کتاب',
        ps: 'کتاب',
        de: 'Bücher',
        en: 'Books',
        icon: Icons.menu_book_outlined,
      ),
      CategorySpec(
        id: 'boardgames',
        fa: 'بازی رومیزی',
        ps: 'مېز لوبې',
        de: 'Brettspiele',
        en: 'Board Games',
        icon: Icons.extension_outlined,
      ),
    ],
  ),

  CategorySpec(id: 'pet',        fa: 'حیوانات خانگی', ps: 'کورني حیوانات', de: 'Haustiere',        en: 'Pets',        icon: Icons.pets_outlined),
  CategorySpec(id: 'food',       fa: 'خوراکه',        ps: 'خوراکه',        de: 'Lebensmittel',     en: 'Food',        icon: Icons.restaurant_outlined),
  CategorySpec(id: 'office',     fa: 'اداری',         ps: 'اداري',         de: 'Bürobedarf',       en: 'Office',      icon: Icons.print_outlined),
  CategorySpec(id: 'education',  fa: 'تعلیم/کورس',    ps: 'زده‌کړه/کورسونه', de: 'Bildung/Kurse', en: 'Education/Courses', icon: Icons.school_outlined),
  CategorySpec(id: 'services',   fa: 'خدمات',         ps: 'خدمتونه',       de: 'Dienstleistungen', en: 'Services',    icon: Icons.support_agent_outlined),
  CategorySpec(id: 'jobs',       fa: 'وظایف',         ps: 'دندې',          de: 'Jobs',             en: 'Jobs',        icon: Icons.work_outline),
  CategorySpec(id: 'events',     fa: 'ایونت/بلیط',    ps: 'پیښې/ټکټونه',    de: 'Events/Tickets',  en: 'Events/Tickets', icon: Icons.event_outlined),
  CategorySpec(id: 'health',     fa: 'تندرستی',       ps: 'روغتیا',         de: 'Gesundheit',      en: 'Health',      icon: Icons.local_hospital_outlined),
  CategorySpec(id: 'industrial', fa: 'صنعتی',         ps: 'صنعتي',          de: 'Industrie',        en: 'Industrial',  icon: Icons.factory_outlined),
  CategorySpec(id: 'agri',       fa: 'زراعتی',        ps: 'کرنه',           de: 'Landwirtschaft',   en: 'Agriculture', icon: Icons.agriculture_outlined),
  CategorySpec(id: 'construction',fa:'ساختمانی',      ps: 'ساختماني',       de: 'Bauwesen',         en: 'Construction',icon: Icons.construction_outlined),
  CategorySpec(id: 'security',   fa: 'امنیتی',        ps: 'امنیتي',         de: 'Sicherheit',       en: 'Security',    icon: Icons.security_outlined),
  CategorySpec(id: 'it',         fa: 'شبکه/آی‌تی',     ps: 'شبکه/آی‌ټي',      de: 'IT/Netzwerk',      en: 'IT/Network',  icon: Icons.memory_outlined),
  CategorySpec(id: 'other',      fa: 'متفرقه',        ps: 'نور',            de: 'Sonstiges',        en: 'Other',       icon: Icons.category_outlined),
];

/// فِلَت‌ کردن کل درخت برای جست‌وجو/اتو‌کمپلیت
Iterable<CategorySpec> flattenCategories([List<CategorySpec>? roots]) sync* {
  final list = roots ?? marketplaceCategories;
  for (final c in list) {
    yield c;
    if (c.children.isNotEmpty) yield* flattenCategories(c.children);
  }
}

/* ----------------------- شِمای فیلدهای کتگوری‌ها ----------------------- */

List<AttrSpec> attrsForCategory(String categoryId) {
  switch (categoryId) {
  /* Vehicles */
    case 'car':
      return const [
        AttrSpec(id: 'brand', label: 'برند', type: AttrType.select, required: true,
            options: ['Toyota','Honda','Hyundai','Kia','BMW','Mercedes','Audi','Volkswagen','Nissan','Mazda','Other']),
        AttrSpec(id: 'model', label: 'مدل', type: AttrType.text, required: true),
        AttrSpec(id: 'year', label: 'سال ساخت', type: AttrType.number, required: true),
        AttrSpec(id: 'mileage', label: 'کارکرد (کیلومتر)', type: AttrType.number, unit: 'km', required: true),
        AttrSpec(id: 'fuel', label: 'سوخت', type: AttrType.select, options: ['بنزین','دیزل','هیبرید','برقی']),
        AttrSpec(id: 'transmission', label: 'گیربکس', type: AttrType.select, options: ['اتومات','دستی']),
        AttrSpec(id: 'color', label: 'رنگ', type: AttrType.text),
        AttrSpec(id: 'condition', label: 'وضعیت', type: AttrType.select, options: ['نو','درحدنو','کارکرده','معیوب']),
      ];
    case 'motorcycle':
      return const [
        AttrSpec(id: 'brand', label: 'برند', type: AttrType.text, required: true),
        AttrSpec(id: 'model', label: 'مدل', type: AttrType.text, required: true),
        AttrSpec(id: 'year', label: 'سال', type: AttrType.number),
        AttrSpec(id: 'mileage', label: 'کارکرد (km)', type: AttrType.number, unit: 'km'),
        AttrSpec(id: 'condition', label: 'وضعیت', type: AttrType.select, options: ['نو','درحدنو','کارکرده','معیوب']),
      ];
    case 'bike':
      return const [
        AttrSpec(id: 'brand', label: 'برند', type: AttrType.text),
        AttrSpec(id: 'frame', label: 'سایز فریم', type: AttrType.text),
        AttrSpec(id: 'wheel', label: 'قطر تایر (اینچ)', type: AttrType.number, unit: '"'),
        AttrSpec(id: 'brake', label: 'نوع ترمز', type: AttrType.select, options: ['Disc','Rim','Other']),
        AttrSpec(id: 'condition', label: 'وضعیت', type: AttrType.select, options: ['نو','درحدنو','کارکرده']),
      ];

  /* Real estate */
    case 'apartment':
    case 'house':
    case 'room':
    case 'office':
    case 'land':
    case 'real_estate':
      return const [
        AttrSpec(id: 'deal', label: 'نوع معامله', type: AttrType.select, required: true,
            options: ['رهن/کرایه','فروش']),
        AttrSpec(id: 'type', label: 'نوع ملک', type: AttrType.select,
            options: ['آپارتمان','خانه','اتاق','دفتر/تجاری','زمین']),
        AttrSpec(id: 'area', label: 'متراژ', type: AttrType.number, unit: 'm²', required: true),
        AttrSpec(id: 'rooms', label: 'تعداد اتاق', type: AttrType.number),
        AttrSpec(id: 'floor', label: 'طبقه', type: AttrType.number),
        AttrSpec(id: 'yearBuilt', label: 'سال ساخت', type: AttrType.number),
        AttrSpec(id: 'furnished', label: 'مبله', type: AttrType.toggle),
        AttrSpec(id: 'parking', label: 'پارکینگ', type: AttrType.toggle),
        AttrSpec(id: 'address', label: 'آدرس', type: AttrType.text),
      ];

  /* Electronics */
    case 'phone':
      return const [
        AttrSpec(id: 'brand', label: 'برند', type: AttrType.select, required: true,
            options: ['Apple','Samsung','Xiaomi','Huawei','Google','OnePlus','Nokia','Other']),
        AttrSpec(id: 'model', label: 'مدل', type: AttrType.text, required: true),
        AttrSpec(id: 'storage', label: 'حافظه', type: AttrType.select,
            options: ['32 GB','64 GB','128 GB','256 GB','512 GB','1 TB']),
        AttrSpec(id: 'color', label: 'رنگ', type: AttrType.text),
        AttrSpec(id: 'condition', label: 'وضعیت', type: AttrType.select,
            options: ['نو','درحدنو','کارکرده','معیوب']),
        AttrSpec(id: 'warranty', label: 'گارانتی (ماه)', type: AttrType.number, unit: 'm'),
      ];
    case 'laptop':
      return const [
        AttrSpec(id: 'brand', label: 'برند', type: AttrType.select,
            options: ['Apple','Dell','HP','Lenovo','ASUS','Acer','MSI','Microsoft','Other']),
        AttrSpec(id: 'cpu', label: 'CPU', type: AttrType.text),
        AttrSpec(id: 'ram', label: 'RAM', type: AttrType.select,
            options: ['4 GB','8 GB','16 GB','32 GB','64 GB']),
        AttrSpec(id: 'storage', label: 'Storage', type: AttrType.select,
            options: ['128 GB SSD','256 GB SSD','512 GB SSD','1 TB SSD','HDD']),
        AttrSpec(id: 'screen', label: 'اندازه صفحه', type: AttrType.select,
            options: ['13"','14"','15"','16"+']),
        AttrSpec(id: 'gpu', label: 'GPU', type: AttrType.text),
        AttrSpec(id: 'condition', label: 'وضعیت', type: AttrType.select,
            options: ['نو','درحدنو','کارکرده','معیوب']),
      ];
    case 'tablet':
      return const [
        AttrSpec(id: 'brand', label: 'برند', type: AttrType.text),
        AttrSpec(id: 'model', label: 'مدل', type: AttrType.text),
        AttrSpec(id: 'storage', label: 'حافظه', type: AttrType.select,
            options: ['32 GB','64 GB','128 GB','256 GB','512 GB','1 TB']),
        AttrSpec(id: 'condition', label: 'وضعیت', type: AttrType.select,
            options: ['نو','درحدنو','کارکرده','معیوب']),
      ];
    case 'camera':
      return const [
        AttrSpec(id: 'brand', label: 'برند', type: AttrType.text),
        AttrSpec(id: 'model', label: 'مدل', type: AttrType.text),
        AttrSpec(id: 'type', label: 'نوع', type: AttrType.select,
            options: ['DSLR','Mirrorless','Compact','Action','Other']),
        AttrSpec(id: 'mp', label: 'مگاپیکسل', type: AttrType.number),
        AttrSpec(id: 'condition', label: 'وضعیت', type: AttrType.select,
            options: ['نو','درحدنو','کارکرده']),
      ];

  /* Home & Garden */
    case 'appliance':
      return const [
        AttrSpec(id: 'type', label: 'نوع دستگاه', type: AttrType.select,
            options: ['یخچال','ماشین لباسشویی','ظرفشویی','مایکروویو','جاروبرقی','دیگر']),
        AttrSpec(id: 'brand', label: 'برند', type: AttrType.text),
        AttrSpec(id: 'condition', label: 'وضعیت', type: AttrType.select,
            options: ['نو','درحدنو','کارکرده','معیوب']),
      ];
    case 'furniture':
      return const [
        AttrSpec(id: 'type', label: 'نوع', type: AttrType.select,
            options: ['مبل','تخت','میز','صندلی','کمد','دکور','دیگر']),
        AttrSpec(id: 'material', label: 'متریال', type: AttrType.text),
        AttrSpec(id: 'condition', label: 'وضعیت', type: AttrType.select,
            options: ['نو','درحدنو','کارکرده']),
      ];

  /* Fashion */
    case 'men_cloth':
    case 'women_cloth':
      return const [
        AttrSpec(id: 'size', label: 'سایز', type: AttrType.select,
            options: ['XS','S','M','L','XL','XXL']),
        AttrSpec(id: 'brand', label: 'برند', type: AttrType.text),
        AttrSpec(id: 'condition', label: 'وضعیت', type: AttrType.select,
            options: ['نو','درحدنو','کم‌استفاده','کارکرده']),
      ];

  /* Pets */
    case 'pet':
      return const [
        AttrSpec(id: 'species', label: 'نوع حیوان', type: AttrType.select,
            options: ['سگ','گربه','پرنده','ماهی','جوندگان','خزندگان','دیگر']),
        AttrSpec(id: 'age', label: 'سن (ماه)', type: AttrType.number, unit: 'm'),
        AttrSpec(id: 'gender', label: 'جنسیت', type: AttrType.select, options: ['نر','ماده']),
        AttrSpec(id: 'vaccinated', label: 'واکسین', type: AttrType.toggle),
      ];

  /* Default */
    default:
      return const [
        AttrSpec(id: 'condition', label: 'وضعیت', type: AttrType.select,
            options: ['نو','درحدنو','کارکرده']),
      ];
  }
}

/// Helpers for quick type checks on CategorySpec
extension CategorySpecX on CategorySpec {
  bool get isPhone =>
      id.contains('phone') || id.contains('mobile') || id.contains('phones');

  bool get isLaptop =>
      id.contains('laptop') || id.contains('notebook') || id.contains('mac');

  bool get isTv => id.contains('tv') || id.contains('television');

  bool get isAppliance =>
      id.contains('appliance') || id.contains('home_appliance');

  bool get isFashion =>
      id.contains('fashion') || id.contains('clothes') || id.contains('apparel');

  bool get isFurniture => id.contains('furniture');

  bool get isCar =>
      id.contains('car') ||
          id.contains('auto') ||
          id.contains('sedan') ||
          id.startsWith('vehicle') ||
          id.startsWith('vehicles');

  bool get isMotorcycle => id.contains('motorcycle') || id.contains('bike');

  bool get isVehicle =>
      isCar || isMotorcycle || id.contains('truck') || id.contains('bus');

  bool get isPhoneOrLaptop => isPhone || isLaptop;
}
