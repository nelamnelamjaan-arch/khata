import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:smart_khata_manager/app/app.dart';
import 'package:smart_khata_manager/app/bindings/initial_binding.dart';
import 'package:smart_khata_manager/core/bootstrap/app_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    setUrlStrategy(const HashUrlStrategy());
  }

  registerCoreServices();

  final bootstrap = await bootstrapApplication();
  if (kDebugMode && !bootstrap.firebaseReady) {
    // ignore: avoid_print
    print(
      'Firebase bootstrap incomplete: ${bootstrap.errorMessage ?? "unknown"}',
    );
  }

  runApp(const SmartKhataApp());
}
