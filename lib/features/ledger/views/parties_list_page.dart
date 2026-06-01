import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_khata_manager/app/routes/app_routes.dart';
import 'package:smart_khata_manager/core/theme/app_colors.dart';
import 'package:smart_khata_manager/features/ledger/controllers/ledger_controller.dart';
import 'package:smart_khata_manager/features/ledger/models/khata_labels.dart';
import 'package:smart_khata_manager/features/ledger/models/party.dart';
import 'package:smart_khata_manager/features/ledger/widgets/add_party_sheet.dart';
import 'package:smart_khata_manager/features/ledger/widgets/party_list_tile.dart';

/// Har shakhs ka alag khata — unlimited parties.
class PartiesListPage extends GetView<LedgerController> {
  const PartiesListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(KhataLabels.partiesTitle),
        leading: IconButton(
          icon: const Icon(Icons.dashboard_outlined),
          tooltip: 'Dashboard',
          onPressed: () => Get.offAllNamed(AppRoutes.dashboard),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.parties.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.parties.isEmpty) {
          return _EmptyState(onAdd: () => _openAddPartySheet(context));
        }

        return RefreshIndicator(
          onRefresh: () async {
            // Firestore stream auto-refreshes; brief delay for UX feedback.
            await Future.delayed(const Duration(milliseconds: 400));
          },
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: controller.parties.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
            itemBuilder: (context, index) {
              final party = controller.parties[index];
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
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddPartySheet(context),
        icon: const Icon(Icons.person_add),
        label: const Text('Naam Add Karein'),
      ),
    );
  }

  void _openAddPartySheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => AddPartySheet(controller: controller),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Party party) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Delete Party'),
        content: Text(
          'Delete "${party.name}" and all its transactions? This cannot be undone.',
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
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 72, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Abhi koi naam nahi',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              KhataLabels.addPartyHint,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.person_add),
              label: const Text('Pehla Naam Add Karein'),
            ),
          ],
        ),
      ),
    );
  }
}
