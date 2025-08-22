import 'package:flutter/material.dart';
import 'package:bazari_8656/features/auth/pages/auth_page.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  bool _signedIn = false;
  Map<String, dynamic>? _user;

  bool get isSignedIn => _signedIn;
  Map<String, dynamic>? get currentUser => _user;

  void signOut() {
    _signedIn = false;
    _user = null;
  }

  void mockSignIn({
    required String id,
    required String name,
    String? email,
    String? phone,
  }) {
    _signedIn = true;
    _user = {
      'id': id,
      'name': name,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
    };
  }

  /// امضای صحیح: کانتکست می‌گیرد و AuthPage را push می‌کند
  Future<bool> ensureSignedIn(BuildContext context) async {
    if (_signedIn) return true;
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AuthPage()),
    );
    return ok == true;
  }
}
