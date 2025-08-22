import 'package:flutter/material.dart';

class LikesFollowsPage extends StatelessWidget {
  const LikesFollowsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('پسندها و دنبال‌ها')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: const [
          ListTile(leading: Icon(Icons.favorite), title: Text('محصولات پسندیده')),
          ListTile(leading: Icon(Icons.person_add_alt), title: Text('فروشنده‌های دنبال‌شده')),
        ],
      ),
    );
  }
}
