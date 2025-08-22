import 'package:bazari_8656/core/services/offline/offline_remote_config.dart';
class FeatureFlags{
  final OfflineRemoteConfig rc; FeatureFlags(this.rc);
  double get targetCtrLow => rc.get<double>('targetCtrLow',0.12);
  double get targetCtrHigh=> rc.get<double>('targetCtrHigh',0.16);
  double get targetDivLow => rc.get<double>('targetDivLow',0.55);
  double get targetDivHigh=> rc.get<double>('targetDivHigh',0.70);
  bool get shimmerEnabled => rc.get<bool>('shimmerEnabled', true);
}
