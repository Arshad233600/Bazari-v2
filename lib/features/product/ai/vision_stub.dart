/// استاب برای وب/دسکتاپ: هیچ وابستگی به MLKit ندارد

abstract class VisionAi {
  Future<List<String>> labelImageFile(String path);
  void dispose() {}
}

class VisionAiMobile implements VisionAi {
  @override
  Future<List<String>> labelImageFile(String path) async => <String>[];

  @override
  void dispose() {}
}
