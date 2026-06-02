import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_khata_manager/app/routes/app_routes.dart';
import 'package:smart_khata_manager/features/ledger/models/khata_category.dart';
import 'package:smart_khata_manager/features/ledger/views/khata_book_tabs_page.dart';

/// Deep link wrapper — opens tabs page on a specific category.
class CategoryKhataPage extends StatelessWidget {
  const CategoryKhataPage({super.key, required this.category});

  final KhataCategory category;

  @override
  Widget build(BuildContext context) {
    return KhataBookTabsPage(initialCategory: category);
  }
}

/// Opens khata book tabs — optional starting tab.
void openKhataBook({KhataCategory? category}) {
  if (category == KhataCategory.lenay) {
    Get.toNamed(AppRoutes.ledgerLenay);
  } else if (category == KhataCategory.denay) {
    Get.toNamed(AppRoutes.ledgerDenay);
  } else {
    Get.toNamed(AppRoutes.ledger);
  }
}
