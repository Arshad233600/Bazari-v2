import 'package:shared_preferences/shared_preferences.dart';
abstract class RemoteConfigService{ Future<void> refresh(); }
abstract class HomeAlgomerchController{ Future<void> warmUp(); }
abstract class RecentTrendingService{ Future<void> refreshTrending(); }
class DailyUpdateService{
  static const _k='daily_update_last_run';
  final RemoteConfigService rc; final HomeAlgomerchController algo; final RecentTrendingService trend;
  DailyUpdateService({required this.rc, required this.algo, required this.trend});
  Future<void> runIfNeeded() async {
    final p=await SharedPreferences.getInstance();
    final last=p.getInt(_k); final now=DateTime.now();
    if(last!=null && now.difference(DateTime.fromMillisecondsSinceEpoch(last)).inHours<24) return;
    await rc.refresh(); await trend.refreshTrending(); await algo.warmUp(); await p.setInt(_k, now.millisecondsSinceEpoch);
  }
}
