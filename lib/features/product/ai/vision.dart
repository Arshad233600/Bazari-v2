// lib/features/product/ai/vision.dart
/// رابط ساده برای برچسب‌گذاری تصویر (Image Labels).
/// فعلاً ماک است: لیست خالی برمی‌گرداند تا UI بدون خطا اجرا شود.
abstract class VisionAi {
  Future<List<String>> labelImageFile(String path);
  void dispose() {}
}

/// نسخه‌ی ماک برای موبایل/وب. لیست خالی برمی‌گرداند.
/// (HomePage اگر لیست خالی باشد پیام راهنما نشان می‌دهد.)
class VisionAiMobile implements VisionAi {
  @override
  Future<List<String>> labelImageFile(String path) async {
    // می‌توانید بعداً اینجا ML Kit / TFLite یا سرویس ابری اضافه کنید.
    await Future.delayed(const Duration(milliseconds: 60));
    return <String>[];
  }

  @override
  void dispose() {}
}
