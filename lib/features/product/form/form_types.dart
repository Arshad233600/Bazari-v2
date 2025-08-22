import 'package:flutter/material.dart';

enum FieldType { text, number, integer, select, multiselect, toggle, repeater, group }

class FieldSpec {
  final String key;             // کلید ذخیره‌سازی در details
  final String label;           // برچسب برای UI
  final FieldType type;
  final bool required;
  final List<String>? options;  // برای select/multiselect
  final List<FieldSpec>? children; // برای group/repeater
  final String? hint;
  final String? unit;           // مثلاً m², km, CHF
  final num? min;
  final num? max;

  const FieldSpec({
    required this.key,
    required this.label,
    required this.type,
    this.required = false,
    this.options,
    this.children,
    this.hint,
    this.unit,
    this.min,
    this.max,
  });
}

class CategorySchema {
  final String id;        // house / car / phone / job
  final String title;     // عنوان دسته
  final List<FieldSpec> fields;

  const CategorySchema({
    required this.id,
    required this.title,
    required this.fields,
  });
}

/// رجیستری اسکیمای دسته‌ها
class ProductSchemas {
  static const house = CategorySchema(
    id: 'house',
    title: 'خانه / ملک',
    fields: [
      FieldSpec(key: 'location', label: 'موقعیت', type: FieldType.text, required: true, hint: 'شهر، منطقه'),
      FieldSpec(key: 'area_m2', label: 'متراژ', type: FieldType.number, unit: 'm²', required: true, min: 1),
      FieldSpec(key: 'rooms', label: 'تعداد اتاق', type: FieldType.integer, min: 0, max: 50, required: true),
      FieldSpec(key: 'bedrooms', label: 'اتاق خواب', type: FieldType.integer, min: 0, max: 30),
      FieldSpec(key: 'bathrooms', label: 'حمام/توالت', type: FieldType.integer, min: 0, max: 30),
      FieldSpec(key: 'floor', label: 'طبقه', type: FieldType.integer, min: -3, max: 100),
      FieldSpec(key: 'year_built', label: 'سال ساخت', type: FieldType.integer, min: 1800, max: 2100),
      FieldSpec(key: 'furnished', label: 'مبله', type: FieldType.toggle),
      FieldSpec(key: 'parking', label: 'پارکینگ', type: FieldType.toggle),
      FieldSpec(
        key: 'amenities',
        label: 'امکانات',
        type: FieldType.multiselect,
        options: [
          'بالکن','آسانسور','انباری','سیستم گرمایش','سیستم سرمایش','حیاط','استخر','امنیت/درب ضدسرقت'
        ],
      ),
      FieldSpec(
        key: 'features',
        label: 'ویژگی‌های دیگر',
        type: FieldType.repeater, // رپیتر ساده: رشته‌ای
        hint: 'مثلاً: نزدیک مترو / بازسازی‌شده',
      ),
    ],
  );

  static const car = CategorySchema(
    id: 'car',
    title: 'خودرو',
    fields: [
      FieldSpec(key: 'brand', label: 'برند', type: FieldType.select, required: true, options: ['BMW','Mercedes','Toyota','VW','Audi','Other']),
      FieldSpec(key: 'model', label: 'مدل', type: FieldType.text, required: true),
      FieldSpec(key: 'year', label: 'سال', type: FieldType.integer, min: 1950, max: 2100, required: true),
      FieldSpec(key: 'km', label: 'کارکرد', type: FieldType.number, unit: 'km', min: 0),
      FieldSpec(key: 'fuel', label: 'سوخت', type: FieldType.select, options: ['بنزین','دیزل','هیبرید','برقی']),
      FieldSpec(key: 'transmission', label: 'گیربکس', type: FieldType.select, options: ['دستی','اتومات']),
      FieldSpec(key: 'color', label: 'رنگ', type: FieldType.text),
      FieldSpec(key: 'owners', label: 'تعداد مالک', type: FieldType.integer, min: 0, max: 20),
      FieldSpec(key: 'accident_free', label: 'بی‌تصادف', type: FieldType.toggle),
      FieldSpec(
        key: 'extras',
        label: 'آپشن‌ها',
        type: FieldType.multiselect,
        options: ['سانروف','کروزکنترل','دوربین عقب','سنسور پارک','گرمایش صندلی','نویگیشن'],
      ),
    ],
  );

  static const phone = CategorySchema(
    id: 'phone',
    title: 'موبایل',
    fields: [
      FieldSpec(key: 'brand', label: 'برند', type: FieldType.select, required: true, options: ['Apple','Samsung','Xiaomi','Huawei','Other']),
      FieldSpec(key: 'model', label: 'مدل', type: FieldType.text, required: true),
      FieldSpec(key: 'storage', label: 'حافظه', type: FieldType.select, options: ['64GB','128GB','256GB','512GB','1TB']),
      FieldSpec(key: 'ram', label: 'RAM', type: FieldType.select, options: ['4GB','6GB','8GB','12GB','16GB']),
      FieldSpec(key: 'condition', label: 'وضعیت', type: FieldType.select, options: ['نو','در حد نو','تمیز','کارکرده']),
      FieldSpec(key: 'battery_health', label: 'سلامت باتری', type: FieldType.integer, unit: '%', min: 0, max: 100),
      FieldSpec(key: 'dual_sim', label: 'دو سیم‌کارت', type: FieldType.toggle),
      FieldSpec(
        key: 'accessories',
        label: 'لوازم همراه',
        type: FieldType.multiselect,
        options: ['شارژر','کابل','جعبه','هدست','کاور','شیشه محافظ'],
      ),
      FieldSpec(
        key: 'notes',
        label: 'یادداشت‌ها',
        type: FieldType.repeater,
        hint: 'مثلاً: خط‌وخش جزئی / فاکتور موجود',
      ),
    ],
  );

  static const job = CategorySchema(
    id: 'job',
    title: 'آگهی شغلی',
    fields: [
      FieldSpec(key: 'job_title', label: 'عنوان شغل', type: FieldType.text, required: true),
      FieldSpec(key: 'employment_type', label: 'نوع همکاری', type: FieldType.select, options: ['تمام‌وقت','پاره‌وقت','پروژه‌ای','کارآموزی'], required: true),
      FieldSpec(key: 'location', label: 'محل کار', type: FieldType.text, hint: 'شهر/دورکار'),
      FieldSpec(key: 'remote', label: 'دورکار', type: FieldType.toggle),
      FieldSpec(key: 'salary_min', label: 'حداقل حقوق', type: FieldType.number, unit: 'CHF', min: 0),
      FieldSpec(key: 'salary_max', label: 'حداکثر حقوق', type: FieldType.number, unit: 'CHF', min: 0),
      FieldSpec(
        key: 'requirements',
        label: 'شرایط/مهارت‌ها',
        type: FieldType.repeater, // لیست مهارت‌ها
        hint: 'مثلاً: Flutter 2 سال، Firebase، آلمانی B1',
      ),
    ],
  );

  static const all = <CategorySchema>[house, car, phone, job];

  static CategorySchema byId(String id) =>
      all.firstWhere((e) => e.id == id, orElse: () => house);
}

/// استایل‌های ساده برای کارت‌بندی و تیتر
class FormStyles {
  static EdgeInsets get sectionPad => const EdgeInsets.fromLTRB(16, 12, 16, 16);
  static BorderRadius get radius => BorderRadius.circular(16);
  static BoxDecoration card(BuildContext c) => BoxDecoration(
        color: Theme.of(c).colorScheme.surface,
        borderRadius: radius,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, 4))],
      );
}
