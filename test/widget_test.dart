import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:smart_khata_manager/app/app.dart';

void main() {
  testWidgets('SmartKhataApp renders splash route shell', (tester) async {
    await tester.pumpWidget(const SmartKhataApp());
    await tester.pump();

    expect(find.byType(GetMaterialApp), findsOneWidget);
  });
}
