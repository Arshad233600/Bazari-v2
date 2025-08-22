
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';

/// همان API انتزاعی که در vision.dart استفاده می‌کنیم
abstract class VisionAi {
  Future<List<String>> labelImageFile(String path);
  void dispose() {}
}

/// پیاده‌سازی موبایل با ML Kit
class VisionAiMobile implements VisionAi {
  final ImageLabeler _labeler =
  ImageLabeler(options: ImageLabelerOptions(confidenceThreshold: 0.5));

  @override
  Future<List<String>> labelImageFile(String path) async {
    // از fromFilePath استفاده کن؛ روی همه‌ی پلتفرم‌های موبایل پایدارتره
    final inputImage = InputImage.fromFilePath(path);

    final List<ImageLabel> labels = await _labeler.processImage(inputImage);
    // خروجی: برچسب‌های پایین‌حروف برای مپ کردن به کتگوری‌ها
    return labels.map((e) => e.label.toLowerCase()).toList();
  }

  @override
  void dispose() {
    _labeler.close();
  }
}
