import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:smart_khata_manager/app/routes/app_routes.dart';
import 'package:smart_khata_manager/core/theme/app_colors.dart';
import 'package:smart_khata_manager/features/ledger/controllers/add_transaction_controller.dart';
import 'package:smart_khata_manager/features/ledger/models/khata_category.dart';
import 'package:smart_khata_manager/features/ledger/models/party.dart';
import 'package:smart_khata_manager/features/ledger/widgets/transaction_type_selector.dart';
import 'package:smart_khata_manager/features/ledger/widgets/transaction_history_table.dart';

/// Add Transaction form with hybrid OCR + Gemini AI auto-fill.
class AddTransactionPage extends GetView<AddTransactionController> {
  const AddTransactionPage({super.key});

  @override
  Widget build(BuildContext context) {
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
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      InputDecorator(
                        decoration: InputDecoration(
                          labelText: controller.selectedCategory.value.title,
                          border: const OutlineInputBorder(),
                          prefixIcon: Icon(controller.selectedCategory.value.icon),
                        ),
                        child: Text(
                          controller.partyNameController.text,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Kaun sa khata book?',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: Text(KhataCategory.lenay.title),
                            selected: controller.selectedCategory.value ==
                                KhataCategory.lenay,
                            onSelected: controller.lockPartySelection.value
                                ? null
                                : (_) => controller
                                    .setCategory(KhataCategory.lenay),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ChoiceChip(
                            label: Text(KhataCategory.denay.title),
                            selected: controller.selectedCategory.value ==
                                KhataCategory.denay,
                            onSelected: controller.lockPartySelection.value
                                ? null
                                : (_) => controller
                                    .setCategory(KhataCategory.denay),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: controller.partyNameController,
                      decoration: const InputDecoration(
                        labelText: 'Naam',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: controller.selectedPartyId.value,
                      decoration: const InputDecoration(
                        labelText: 'Ya pehle se naam select karein',
                        border: OutlineInputBorder(),
                      ),
                      items: controller.partiesInCategory
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
                          final party = controller.partiesInCategory
                              .firstWhereOrNull((p) => p.id == id);
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
              Obx(
                () => TransactionTypeSelector(
                  category: controller.selectedCategory.value,
                  selected: controller.transactionType.value,
                  onChanged: (t) => controller.transactionType.value = t,
                ),
              ),
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
