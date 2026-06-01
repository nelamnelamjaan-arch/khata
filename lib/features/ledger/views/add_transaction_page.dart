import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:smart_khata_manager/app/routes/app_routes.dart';
import 'package:smart_khata_manager/core/theme/app_colors.dart';
import 'package:smart_khata_manager/features/ledger/controllers/add_transaction_controller.dart';
import 'package:smart_khata_manager/features/ledger/controllers/ledger_controller.dart';
import 'package:smart_khata_manager/features/ledger/models/party.dart';
import 'package:smart_khata_manager/features/ledger/models/khata_labels.dart';
import 'package:smart_khata_manager/features/ledger/models/transaction_type.dart';
import 'package:smart_khata_manager/features/ledger/widgets/transaction_history_table.dart';

/// Add Transaction form with hybrid OCR + Gemini AI auto-fill.
class AddTransactionPage extends GetView<AddTransactionController> {
  const AddTransactionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ledger = Get.find<LedgerController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Transaction'),
        actions: [
          Obx(() => IconButton(
                icon: controller.isScanning.value
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.document_scanner),
                tooltip: 'Scan Receipt',
                onPressed:
                    controller.isScanning.value ? null : controller.scanReceipt,
              )),
        ],
      ),
      body: Obx(() {
        if (controller.isScanning.value) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Reading receipt…'),
                SizedBox(height: 8),
                Text(
                  'ML Kit OCR → Gemini AI parsing',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ScanReceiptCard(controller: controller),
              const SizedBox(height: 24),
              Obx(() {
                if (controller.lockPartySelection.value) {
                  return InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Party',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    child: Text(
                      controller.partyNameController.text,
                      style: const TextStyle(fontSize: 16),
                    ),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: controller.partyNameController,
                      decoration: const InputDecoration(
                        labelText: 'Party Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: controller.selectedPartyId.value,
                      decoration: const InputDecoration(
                        labelText: 'Or select existing party',
                        border: OutlineInputBorder(),
                      ),
                      items: ledger.parties
                          .map(
                            (p) => DropdownMenuItem(
                              value: p.id,
                              child: Text(p.name),
                            ),
                          )
                          .toList(),
                      onChanged: (id) {
                        controller.selectedPartyId.value = id;
                        if (id != null) {
                          final party =
                              ledger.parties.firstWhereOrNull((p) => p.id == id);
                          if (party != null) {
                            controller.partyNameController.text = party.name;
                          }
                        }
                      },
                    ),
                  ],
                );
              }),
              const SizedBox(height: 12),
              TextField(
                controller: controller.amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Amount (Rs.)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.currency_rupee),
                ),
              ),
              const SizedBox(height: 12),
              Obx(() => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Tareekh aur Waqt'),
                    subtitle: Text(
                      '${DateFormat('dd MMM yyyy').format(controller.selectedDate.value)} · '
                      '${DateFormat('hh:mm a').format(controller.selectedDate.value)}',
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await pickDateAndTime(
                        context,
                        initial: controller.selectedDate.value,
                      );
                      if (picked != null) {
                        controller.selectedDate.value = picked;
                      }
                    },
                  )),
              const SizedBox(height: 12),
              Obx(() => SegmentedButton<TransactionType>(
                    segments: [
                      ButtonSegment(
                        value: TransactionType.debit,
                        label: Text(
                          KhataLabels.entryTypeShort(TransactionType.debit),
                        ),
                        icon: const Icon(Icons.add_circle_outline,
                            color: AppColors.receivable),
                      ),
                      ButtonSegment(
                        value: TransactionType.credit,
                        label: Text(
                          KhataLabels.entryTypeShort(TransactionType.credit),
                        ),
                        icon: const Icon(Icons.remove_circle_outline,
                            color: AppColors.payable),
                      ),
                    ],
                    selected: {controller.transactionType.value},
                    onSelectionChanged: (set) =>
                        controller.transactionType.value = set.first,
                  )),
              const SizedBox(height: 4),
              Obx(() => Text(
                    KhataLabels.entryDescription(controller.transactionType.value),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  )),
              const SizedBox(height: 12),
              TextField(
                controller: controller.noteController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Note (raw OCR text stored here after scan)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.notes),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 24),
              Obx(() => FilledButton.icon(
                    onPressed: controller.isSubmitting.value
                        ? null
                        : controller.submitTransaction,
                    icon: controller.isSubmitting.value
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: const Text('Save Transaction'),
                  )),
            ],
          ),
        );
      }),
    );
  }
}

class _ScanReceiptCard extends StatelessWidget {
  const _ScanReceiptCard({required this.controller});

  final AddTransactionController controller;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      color: AppColors.primary.withOpacity(0.04),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.document_scanner, color: AppColors.primary, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Smart Receipt Scan',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'On-device ML Kit OCR + Gemini AI parsing when online.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: controller.scanReceipt,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Scan Receipt'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: controller.scanReceiptFromGallery,
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Choose from Gallery'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Opens [AddTransactionPage] with a pre-selected party (includes scan).
void openAddTransactionWithParty(Party party) {
  Get.toNamed(AppRoutes.addTransaction, arguments: party);
}
