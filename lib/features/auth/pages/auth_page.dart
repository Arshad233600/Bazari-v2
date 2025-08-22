import 'package:flutter/material.dart';
import 'package:bazari_8656/core/services/auth_service.dart';
import 'package:bazari_8656/features/auth/widgets/country_picker.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});
  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> with SingleTickerProviderStateMixin {
  late final TabController _tab;
  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ورود / ثبت‌نام'),
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: 'شماره موبایل'),
            Tab(text: 'ایمیل'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: const [
          _PhoneTab(),
          _EmailTab(),
        ],
      ),
    );
  }
}

class _PhoneTab extends StatefulWidget {
  const _PhoneTab();

  @override
  State<_PhoneTab> createState() => _PhoneTabState();
}

class _PhoneTabState extends State<_PhoneTab> {
  Country _c = countries.first;
  final _phone = TextEditingController();
  final _name  = TextEditingController();
  final _last  = TextEditingController();
  final _otp   = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _phone.dispose(); _name.dispose(); _last.dispose(); _otp.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            CountryPickerField(value: _c, onPick: (x){ setState(()=> _c = x); }),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'شماره موبایل',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _name,
          decoration: const InputDecoration(
            labelText: 'نام',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _last,
          decoration: const InputDecoration(
            labelText: 'نام خانوادگی',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        if (!_sent)
          ElevatedButton.icon(
            onPressed: (){
              if (_phone.text.trim().isEmpty) return;
              setState(()=> _sent = true);
            },
            icon: const Icon(Icons.sms),
            label: const Text('ارسال کد ۴ رقمی'),
          )
        else ...[
          TextField(
            controller: _otp,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'کد ۴ رقمی',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: (){
              if (_otp.text.trim().length < 4) return;
              AuthService.instance.mockSignIn(
                id: 'u_${DateTime.now().millisecondsSinceEpoch}',
                name: '${_name.text} ${_last.text}'.trim(),
                phone: '${_c.dial}${_phone.text}',
              );
              Navigator.pop(context, true);
            },
            icon: const Icon(Icons.login),
            label: const Text('تایید و ورود'),
          ),
        ],
      ],
    );
  }
}

class _EmailTab extends StatefulWidget {
  const _EmailTab();

  @override
  State<_EmailTab> createState() => _EmailTabState();
}

class _EmailTabState extends State<_EmailTab> {
  final _email = TextEditingController();
  final _pass  = TextEditingController();

  @override
  void dispose() { _email.dispose(); _pass.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'ایمیل',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _pass,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'رمز عبور',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: (){
            if (_email.text.trim().isEmpty || _pass.text.trim().isEmpty) return;
            AuthService.instance.mockSignIn(
              id: 'u_${DateTime.now().millisecondsSinceEpoch}',
              name: _email.text.split('@').first,
              email: _email.text.trim(),
            );
            Navigator.pop(context, true);
          },
          icon: const Icon(Icons.login),
          label: const Text('ورود / ثبت'),
        ),
      ],
    );
  }
}
