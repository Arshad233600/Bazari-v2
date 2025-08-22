import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FunPage extends StatefulWidget {
  const FunPage({super.key});
  @override
  State<FunPage> createState() => _FunPageState();
}

class _FunPageState extends State<FunPage> {
  int _coins = 0;
  @override
  void initState(){ super.initState(); _load(); }
  Future<void> _load() async { final p=await SharedPreferences.getInstance(); setState(()=>_coins=p.getInt('coins')??0); }
  Future<void> _earn(int x) async { final p=await SharedPreferences.getInstance(); setState(()=>_coins+=x); await p.setInt('coins', _coins); }
  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(title: const Text('Fun & Coins')),
      body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('Your Coins: $_coins', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height:16),
        FilledButton.icon(onPressed:()=>_earn(5), icon: const Icon(Icons.sports_esports), label: const Text('Play & Earn +5')),
      ])),
    );
  }
}
