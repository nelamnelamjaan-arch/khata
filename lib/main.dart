import 'package:flutter/material.dart';
import 'package:smart_khata_manager/app/app.dart';
import 'package:smart_khata_manager/app/bindings/initial_binding.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  registerCoreServices();
  runApp(const SmartKhataApp());
}
