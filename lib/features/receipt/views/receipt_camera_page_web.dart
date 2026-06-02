import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Web stub — camera capture is mobile-only.
class ReceiptCameraPage extends StatelessWidget {
  const ReceiptCameraPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Receipt')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.camera_alt_outlined, size: 48),
              const SizedBox(height: 16),
              const Text(
                'Receipt camera scan is available on mobile.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton(onPressed: Get.back, child: const Text('Go Back')),
            ],
          ),
        ),
      ),
    );
  }
}
