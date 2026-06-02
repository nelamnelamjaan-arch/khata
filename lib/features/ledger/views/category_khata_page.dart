import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_khata_manager/app/routes/app_routes.dart';
import 'package:smart_khata_manager/core/theme/app_colors.dart';
import 'package:smart_khata_manager/features/ledger/controllers/ledger_controller.dart';
import 'package:smart_khata_manager/features/ledger/models/khata_category.dart';
import 'package:smart_khata_manager/features/ledger/models/party.dart';
import 'package:smart_khata_manager/features/ledger/widgets/add_party_sheet.dart';
import 'package:smart_khata_manager/features/ledger/widgets/party_list_tile.dart';
import 'package:smart_khata_manager/features/ledger/services/ledger_service.dart';

/// Ek category ka alag khata book — naam add + entries alag.
class CategoryKhataPage extends StatelessWidget {
  const CategoryKhataPage({super.key, required this.category});

  final KhataCategory category;

  @override
  Widget build(BuildContext context) {
    final ledger = Get.find<LedgerService>();

    return Scaffold(
      appBar: AppBar(
        title: Text(category.title),
        leading: IconButton(
          icon: const Icon(Icons.dashboard_outlined),
          tooltip: 'Dashboard',
          onPressed: () => Get.offAllNamed(AppRoutes.dashboard),
        ),
      ),
      body: StreamBuilder<List<Party>>(
        stream: ledger.watchParties(category: category),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final parties = snapshot.data!;
          if (parties.isEmpty) {
            return _EmptyState(
              category: category,
              onAdd: () => _openAddPartySheet(context),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await Future.delayed(const Duration(milliseconds: 400));
            },
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: parties.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, indent: 72),
              itemBuilder: (context, index) {
                final party = parties[index];
                return PartyListTile(
                  party: party,
                  onTap: () => Get.toNamed(
                    AppRoutes.partyDetail,
                    arguments: party,
                  ),
                  onDelete: () => _confirmDelete(context, party),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddPartySheet(context),
        icon: const Icon(Icons.person_add),
        label: Text(category.addNameLabel),
      ),
    );
  }

  void _openAddPartySheet(BuildContext context) {
    final controller = Get.find<LedgerController>();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => AddPartySheet(
        controller: controller,
        category: category,
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Party party) async {
    final controller = Get.find<LedgerController>();
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Naam Delete'),
        content: Text(
          '"${party.name}" aur us ki sari entries delete karein?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.payable),
            onPressed: () => Get.back(result: true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await controller.deleteParty(party.id);
      if (controller.errorMessage.value != null) {
        Get.snackbar('Error', controller.errorMessage.value!);
      }
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.category, required this.onAdd});

  final KhataCategory category;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(category.icon, size: 72, color: category.color),
            const SizedBox(height: 16),
            Text(
              'Abhi koi naam nahi',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              category.emptyHint,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.person_add),
              label: Text(category.addNameLabel),
            ),
          ],
        ),
      ),
    );
  }
}
