import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class OfflineRemoteConfig{
  Map<String,dynamic> _data={};
  Future<void> load() async {
    try{ final txt=await rootBundle.loadString('assets/remote_config.json'); _data=json.decode(txt) as Map<String,dynamic>; }
    catch(_){ _data={}; }
  }
  T get<T>(String key, T fallback){ final v=_data[key]; return v is T? v : fallback; }
}
