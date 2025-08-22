// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:bazari_8656/app/i18n/i18n.dart';
import 'package:bazari_8656/features/home/pages/home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppLang.instance.loadSaved();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

  runApp(const BazariApp());
}

class BazariApp extends StatelessWidget {
  const BazariApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppLang.instance, // تغییر زبان/rtl -> رندر مجدد
      builder: (context, _) {
        final loc = AppLang.instance.locale;

        return MaterialApp(
          debugShowCheckedModeBanner: false,

          // زبان فعلی از i18n
          locale: loc,
          supportedLocales: AppLang.supportedLocales,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],

          // چون ps (پشتو) به‌صورت کامل در Localizations نیست، فالبک سمت ویجت‌ها:
          localeResolutionCallback: (device, supported) {
            // اگر همین locale دقیق پشتیبانی شد
            if (supported.any((s) =>
            s.languageCode == loc.languageCode &&
                (s.countryCode ?? '') == (loc.countryCode ?? ''))) {
              return loc;
            }
            // اگر فقط زبان پشتیبانی شد
            if (supported.any((s) => s.languageCode == loc.languageCode)) {
              return supported.firstWhere((s) => s.languageCode == loc.languageCode);
            }
            // پیش‌فرض: دری
            return const Locale('fa', 'AF');
          },

          // خیلی مهم: تزریق جهت متن (RTL/LTR) در بالاترین سطح
          builder: (context, child) => Directionality(
            textDirection: AppLang.instance.textDirection,
            child: child ?? const SizedBox.shrink(),
          ),

          // تم روشن/تاریک (پویا بر اساس زبان)
          theme: _buildTheme(Brightness.light),
          darkTheme: _buildTheme(Brightness.dark),

          home: const HomePage(),
        );
      },
    );
  }
}

/* ========================= THEME ========================= */

// رنگ seed پویا بر اساس زبان
Color _seedForLocale() {
  switch (AppLang.instance.locale.languageCode.toLowerCase()) {
    case 'fa':
      return const Color(0xFF14B8A6); // Teal برای دری
    case 'ps':
      return const Color(0xFF16A34A); // سبز ملایم برای پشتو
    case 'de':
      return const Color(0xFF4C6EF5); // ایندیگو برای آلمانی
    case 'en':
      return const Color(0xFF7C3AED); // بنفش برای انگلیسی
    default:
      return const Color(0xFF14B8A6);
  }
}

ThemeData _buildTheme(Brightness brightness) {
  final seed = _seedForLocale();

  final base = ThemeData(
    useMaterial3: true,
    colorSchemeSeed: seed,
    brightness: brightness,
  );
  final cs = base.colorScheme;

  return base.copyWith(
    scaffoldBackgroundColor: cs.surface,

    appBarTheme: AppBarTheme(
      elevation: 0.5,
      scrolledUnderElevation: 0,
      backgroundColor: cs.surface,
      foregroundColor: cs.onSurface,
      systemOverlayStyle:
      brightness == Brightness.dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
    ),

    // ⬅️ توجه: نوع درست CardThemeData
    cardTheme: CardThemeData(
      elevation: 0,
      color: cs.surface,
      surfaceTintColor: cs.surface,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),

    inputDecorationTheme: InputDecorationTheme(
      isDense: true,
      filled: true,
      fillColor: cs.surfaceVariant.withOpacity(0.30),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.primary, width: 1.4),
      ),
    ),

    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(44),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(44),
        side: BorderSide(color: cs.outlineVariant),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),

    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: cs.inverseSurface,
      contentTextStyle: TextStyle(color: cs.onInverseSurface),
      actionTextColor: cs.tertiary,
      elevation: 4,
    ),

    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: ZoomPageTransitionsBuilder(),
        TargetPlatform.iOS: ZoomPageTransitionsBuilder(),
        TargetPlatform.macOS: ZoomPageTransitionsBuilder(),
        TargetPlatform.windows: ZoomPageTransitionsBuilder(),
        TargetPlatform.linux: ZoomPageTransitionsBuilder(),
        TargetPlatform.fuchsia: ZoomPageTransitionsBuilder(),
      },
    ),
  );
}

