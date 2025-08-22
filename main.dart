import 'package:flutter/material.dart';

import 'package:bazari_8656/features/home/pages/home_page.dart';
// اگر این صفحات را داری، نگه دار. اگر نداری، موقتاً کامنت کن یا استاب بساز.
// import 'features/search/pages/search_page.dart';
// import 'features/fun/pages/fun_page.dart';

void main() {
  runApp(const BazariApp());
}

class BazariApp extends StatelessWidget {
  const BazariApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bazari 8656',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.teal,
        useMaterial3: true,
      ),
      home: const RootScaffold(),
    );
  }
}

class RootScaffold extends StatefulWidget {
  const RootScaffold({super.key});
  @override
  State<RootScaffold> createState() => _RootScaffoldState();
}

class _RootScaffoldState extends State<RootScaffold> {
  int _index = 0;

  // اگر SearchPage / FunPage را نداری، همین HomePage را موقتاً تکرار گذاشتم
  final List<Widget> _pages = const [
    HomePage(),
    // SearchPage(),
    // FunPage(),
    HomePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'خانه'),
          // NavigationDestination(icon: Icon(Icons.search_outlined), selectedIcon: Icon(Icons.search), label: 'جستجو'),
          // NavigationDestination(icon: Icon(Icons.celebration_outlined), selectedIcon: Icon(Icons.celebration), label: 'سرگرمی'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'پروفایل'),
        ],
      ),
    );
  }
}
