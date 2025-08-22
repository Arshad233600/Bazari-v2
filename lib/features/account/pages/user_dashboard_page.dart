import 'package:flutter/material.dart';
import 'package:bazari_8656/core/services/auth_service.dart';

class UserDashboardPage extends StatelessWidget {
  const UserDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;
    final name = (user?['email'] as String?) ?? (user?['phone'] as String?) ?? 'کاربر عزیز';

    return Scaffold(
      appBar: AppBar(
        title: const Text('داشبورد'),
        actions: [
          IconButton(
            tooltip: 'خروج',
            onPressed: () async {
              AuthService.instance.signOut();
              if (!context.mounted) return;
              Navigator.of(context).pop(); // برگشت به صفحه قبل
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text(name),
            subtitle: Text('روش ورود: ${user?['method'] ?? '-'}'),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.history),
              title: const Text('سفارش‌ها'),
              onTap: () {},
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.favorite_outline),
              title: const Text('علاقه‌مندی‌ها'),
              onTap: () {},
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('تنظیمات حساب'),
              onTap: () {},
            ),
          ),
        ],
      ),
    );
  }
}

