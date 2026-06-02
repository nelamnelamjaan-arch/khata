import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_khata_manager/app/routes/app_routes.dart';
import 'package:smart_khata_manager/core/theme/app_colors.dart';
import 'package:smart_khata_manager/features/ledger/controllers/ledger_controller.dart';
import 'package:smart_khata_manager/features/ledger/models/khata_category.dart';
import 'package:smart_khata_manager/features/ledger/views/category_khata_tab.dart';
import 'package:smart_khata_manager/features/ledger/widgets/add_party_sheet.dart';
import 'package:smart_khata_manager/features/ledger/widgets/category_picker_sheet.dart';

/// Lenay | Denay tabs — ek page par alag sections, mix data nahi.
class KhataBookTabsPage extends StatefulWidget {
  const KhataBookTabsPage({super.key, this.initialCategory});

  final KhataCategory? initialCategory;

  @override
  State<KhataBookTabsPage> createState() => _KhataBookTabsPageState();
}

class _KhataBookTabsPageState extends State<KhataBookTabsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    final initialIndex =
        widget.initialCategory == KhataCategory.denay ? 1 : 0;
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: initialIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  KhataCategory get _activeCategory =>
      _tabController.index == 0 ? KhataCategory.lenay : KhataCategory.denay;

  void _openAddPartySheet() {
    final controller = Get.find<LedgerController>();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => AddPartySheet(
        controller: controller,
        category: _activeCategory,
      ),
    );
  }

  Future<void> _openAddEntryFlow() async {
    final category = await showCategoryPickerSheet(
      context,
      title: 'Entry kahan add karni hai?',
      subtitle: 'Lenay ya Denay select karein',
      preselected: _activeCategory,
    );
    if (category == null || !mounted) return;

    if (category != _activeCategory) {
      _tabController.animateTo(category == KhataCategory.lenay ? 0 : 1);
    }

    Get.snackbar(
      category.title,
      'Pehle naam select karein, phir "Entry Add Karein" dabayein.',
      duration: const Duration(seconds: 3),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Khata Book'),
        leading: IconButton(
          icon: const Icon(Icons.dashboard_outlined),
          tooltip: 'Dashboard',
          onPressed: () => Get.offAllNamed(AppRoutes.dashboard),
        ),
        bottom: TabBar(
          controller: _tabController,
          onTap: (_) => setState(() {}),
          tabs: const [
            Tab(
              icon: Icon(Icons.arrow_downward),
              text: 'Lenay',
            ),
            Tab(
              icon: Icon(Icons.arrow_upward),
              text: 'Denay',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          CategoryKhataTab(category: KhataCategory.lenay),
          CategoryKhataTab(category: KhataCategory.denay),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'add_entry',
            onPressed: _openAddEntryFlow,
            icon: const Icon(Icons.receipt_long),
            label: const Text('Entry Add'),
            backgroundColor: AppColors.primary,
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'add_name',
            onPressed: _openAddPartySheet,
            icon: const Icon(Icons.person_add),
            label: Text(_activeCategory.addNameLabel),
          ),
        ],
      ),
    );
  }
}
