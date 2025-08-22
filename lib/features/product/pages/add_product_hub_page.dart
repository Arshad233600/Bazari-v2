import 'package:flutter/material.dart';

/// صفحه‌ی هاب افزودن محصول: دو تب «هوش مصنوعی» و «دستی»
/// - آیکون Home در AppBar: برگشت به هوم
/// - روی اسکرین‌های عریض، NavigationRail + TabBarView
class AddProductHubPage extends StatefulWidget {
  const AddProductHubPage({super.key});

  @override
  State<AddProductHubPage> createState() => _AddProductHubPageState();
}

class _AddProductHubPageState extends State<AddProductHubPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  /// برگشت امن به صفحه‌ی اول (هوم).
  /// اگر روت نام‌گذاری‌شده داری، می‌تونی خط pushNamedAndRemoveUntil را باز کنی.
  void _goHome() {
    // Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 900;

    final tabs = const [
      Tab(text: 'AI'),
      Tab(text: 'Manual'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add product'),
        actions: [
          IconButton(
            tooltip: 'Home',
            icon: const Icon(Icons.home_outlined),
            onPressed: _goHome,
          ),
        ],
        bottom: isWide ? null : TabBar(controller: _tabs, tabs: tabs),
      ),
      body: isWide
          ? Row(
        children: [
          NavigationRail(
            selectedIndex: _tabs.index,
            onDestinationSelected: _tabs.animateTo,
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.auto_awesome),
                label: Text('AI'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.edit_outlined),
                label: Text('Manual'),
              ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              physics: const NeverScrollableScrollPhysics(),
              children: const [
                _AiAddProductPane(),
                _ManualAddProductPane(),
              ],
            ),
          ),
        ],
      )
          : TabBarView(
        controller: _tabs,
        children: const [
          _AiAddProductPane(),
          _ManualAddProductPane(),
        ],
      ),
    );
  }
}

class _AiAddProductPane extends StatelessWidget {
  const _AiAddProductPane();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text(
              'AI-assisted add',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Describe your product',
                hintText:
                'e.g. “iPhone 13 Pro, 256GB, graphite, lightly used”',
                border: OutlineInputBorder(),
              ),
              minLines: 3,
              maxLines: 5,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () {
                // TODO: اینجا فراخوانی جریان هوش مصنوعی شما (API/Bloc/Provider) می‌آید
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('AI suggestion flow not wired yet'),
                  ),
                );
              },
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Generate details'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ManualAddProductPane extends StatelessWidget {
  const _ManualAddProductPane();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text(
              'Manual add',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Price',
                prefixText: '\$ ',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),

            // دسته‌بندی نمونه (می‌تونی بعداً از مدل/دیتاسورس واقعی‌ات پر کنی)
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'electronics', child: Text('Electronics')),
                DropdownMenuItem(value: 'fashion', child: Text('Fashion')),
                DropdownMenuItem(value: 'home', child: Text('Home & Living')),
              ],
              onChanged: (v) {},
            ),

            const SizedBox(height: 12),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              minLines: 4,
              maxLines: 6,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                // TODO: ذخیره‌سازی واقعی
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Saved (stub)')),
                );
              },
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save product'),
            ),
          ],
        ),
      ),
    );
  }
}
