import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class TrendingService {
  Map<String, dynamic>? _data;
  Future<void> refreshTrending() async {
    final s = await rootBundle.loadString('assets/public_trending.json');
    _data = jsonDecode(s);
  }
  List<dynamic> get items => (_data?['items'] as List<dynamic>? ?? const []);
}