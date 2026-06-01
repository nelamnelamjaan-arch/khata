import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:smart_khata_manager/app/app.dart';
import 'package:smart_khata_manager/app/bindings/initial_binding.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    // Avoid 404 on refresh when served from a static host (python, GitHub Pages).
    setUrlStrategy(const HashUrlStrategy());
  }

  registerCoreServices();
  runApp(const SmartKhataApp());
}
