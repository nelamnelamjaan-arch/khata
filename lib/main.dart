import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:smart_khata_manager/app/app.dart';
import 'package:smart_khata_manager/app/bindings/initial_binding.dart';

void main() {
  runZonedGuarded(() {
    WidgetsFlutterBinding.ensureInitialized();

    if (kIsWeb) {
      setUrlStrategy(const HashUrlStrategy());
    }

    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      if (kDebugMode) {
        // ignore: avoid_print
        print('FlutterError: ${details.exceptionAsString()}');
      }
    };

    try {
      registerCoreServices();
    } catch (e, stack) {
      if (kDebugMode) print('registerCoreServices failed: $e\n$stack');
      runApp(_BootstrapErrorApp(message: e.toString()));
      return;
    }

    runApp(const SmartKhataApp());
  }, (error, stack) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('Uncaught error: $error\n$stack');
    }
  });
}

class _BootstrapErrorApp extends StatelessWidget {
  const _BootstrapErrorApp({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text(
                'App failed to start:\n$message',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
