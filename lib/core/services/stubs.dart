import 'daily_update_service.dart';
import 'offline/offline_remote_config.dart';
import '../feature_flags/feature_flags.dart';
class RemoteConfigServiceImpl implements RemoteConfigService{
  final OfflineRemoteConfig _orc=OfflineRemoteConfig();
  late final FeatureFlags flags=FeatureFlags(_orc);
  @override Future<void> refresh() async { await _orc.load(); }
}
class HomeAlgomerchControllerImpl implements HomeAlgomerchController{
  @override Future<void> warmUp() async {}
}
class RecentTrendingServiceImpl implements RecentTrendingService{
  @override Future<void> refreshTrending() async {}
}
