import 'package:flutter/foundation.dart';

class RewardsController extends ChangeNotifier {
  int impressions = 0;
  int clicks = 0;
  int rewards = 0;

  void onImpression([int n=1]) { impressions += n; notifyListeners(); }
  void onClick([int n=1]) { clicks += n; rewards += 1; notifyListeners(); }
  void spin() { rewards += 5; notifyListeners(); }
}

final rewards = RewardsController();
