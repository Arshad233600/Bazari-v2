import 'package:flutter/material.dart';

/// یک آیتم زبان
class AppLangItem {
  final String code;
  final String label;
  const AppLangItem(this.code, this.label);
}

/// سرویس مدیریت زبان
class AppLang extends ChangeNotifier {
  AppLang._();
  static final AppLang instance = AppLang._();

  String _lang = 'fa';
  String get lang => _lang;

  /// لیست زبان‌ها
  final List<AppLangItem> languages = const [
    AppLangItem('fa', 'فارسی'),
    AppLangItem('ps', 'پشتو'),
    AppLangItem('en', 'English'),
    AppLangItem('tr', 'Türkçe'),
  ];

  /// برای سازگاری با `main.dart`
  Future<void> load() async {
    // اینجا می‌توانی زبان ذخیره شده در SharedPreferences را بارگذاری کنی
  }

  /// تغییر زبان
  Future<void> setLang(String code) async {
    _lang = code;
    notifyListeners();
  }

  /// ترجمه کلید
  String t(String key) {
    const m = {
      'fa': {
        'search': 'جستجو',
        'category': 'دسته‌بندی',
        'add': 'افزودن',
        'refresh': 'موردی یافت نشد'
      },
      'en': {
        'search': 'Search',
        'category': 'Category',
        'add': 'Add',
        'refresh': 'No items found'
      },
    };
    final map = m[_lang] ?? m['en']!;
    return map[key] ?? key;
  }
}

/// اکستنشن برای استفاده راحت در ویجت‌ها
extension AppLangContextExt on BuildContext {
  /// استفاده: `context.tr('search')`
  String tr(String key) => AppLang.instance.t(key);
}
