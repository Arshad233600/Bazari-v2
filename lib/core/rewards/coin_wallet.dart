import 'package:shared_preferences/shared_preferences.dart';

class CoinWallet {
  static const _k = 'wallet_coins';
  Future<int> getBalance() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_k) ?? 0;
  }
  Future<void> add(int delta) async {
    final p = await SharedPreferences.getInstance();
    final bal = p.getInt(_k) ?? 0;
    await p.setInt(_k, bal + delta);
  }
}