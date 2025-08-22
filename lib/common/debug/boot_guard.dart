import 'dart:async';
import 'package:flutter/material.dart';

void guardedRun(Widget app) {
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.dumpErrorToConsole(details);
  };

  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: Colors.white,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Text(
              'Flutter error:\n\n'
              '${details.exceptionAsString()}\n\n'
              '${details.stack}',
              style: TextStyle(fontFamily: 'monospace'),
            ),
          ),
        ),
      ),
    );
  };

  runZonedGuarded(() => runApp(app), (error, stack) {
    debugPrint('Zoned error: $error\n$stack');
  });
}
