import 'package:flutter/material.dart';
import 'package:bazari_8656/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

Widget wrapWithTheme({
  required Widget child,
  Locale? locale,
  Brightness? brightness,
}) {
  final ThemeData light = ThemeData(useMaterial3: true, brightness: Brightness.light);
  final ThemeData dark = ThemeData(useMaterial3: true, brightness: Brightness.dark);

  return MaterialApp(
    locale: locale,
    theme: light,
    darkTheme: dark,
    themeMode: (brightness == Brightness.dark) ? ThemeMode.dark : ThemeMode.light,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: child,
  );
}

Widget wrapWithDark(Widget child, {Locale? locale}) =>
    wrapWithTheme(child: child, locale: locale, brightness: Brightness.dark);
