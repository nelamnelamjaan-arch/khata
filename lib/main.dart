import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:smart_khata_manager/app/app.dart';
import 'package:smart_khata_manager/app/bindings/initial_binding.dart';
import 'package:smart_khata_manager/core/bootstrap/app_bootstrap.dart';
import 'package:smart_khata_manager/core/utils/reset_web_hash_stub.dart'
    if (dart.library.html) 'package:smart_khata_manager/core/utils/reset_web_hash_web.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    setUrlStrategy(const HashUrlStrategy());
    resetWebHashToSplash();
  }

  registerCoreServices();

  final bootstrap = await bootstrapApplication();
  if (kDebugMode && !bootstrap.firebaseReady) {
    // ignore: avoid_print
    print(
      'Bootstrap incomplete: ${bootstrap.errorMessage ?? "unknown"}',
    );
  }

  runApp(const SmartKhataApp());
}
