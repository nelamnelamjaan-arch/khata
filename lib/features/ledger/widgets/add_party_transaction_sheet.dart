import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:smart_khata_manager/core/theme/app_colors.dart';
import 'package:smart_khata_manager/features/ledger/controllers/party_detail_controller.dart';
import 'package:smart_khata_manager/features/ledger/models/khata_labels.dart';
import 'package:smart_khata_manager/features/ledger/models/party.dart';
import 'package:smart_khata_manager/features/ledger/models/transaction_type.dart';
import 'package:smart_khata_manager/features/ledger/widgets/transaction_history_table.dart';

/// Quick entry form — udhar ya wasooli for one party.
class AddPartyTransactionSheet extends StatefulWidget {
  const AddPartyTransactionSheet({
    super.key,
    required this.party,
    required this.controller,
  });

  final Party party;
  final PartyDetailController controller;

  @override
  State<AddPartyTransactionSheet> createState() =>
      _AddPartyTransactionSheetState();
}

class _AddPartyTransactionSheetState extends State<AddPartyTransactionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TransactionType _type = TransactionType.debit;
  bool _isSaving = false;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      await widget.controller.addTransaction(
        amount: double.parse(_amountController.text.trim()),
        type: _type,
        date: _selectedDate,
        note: _noteController.text.trim(),
      );
      if (mounted) Navigator.of(context).pop();
      Get.snackbar('Saved', '${widget.party.name} ka khata update ho gaya');
    } catch (e) {
      Get.snackbar(
        'Error',
        widget.controller.ledger.errorMessage.value ?? e.toString(),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset + 16),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'Entry — ${widget.party.name}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Rupay (Rs.) *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.currency_rupee),
              ),
              validator: (v) {
                final amount = double.tryParse(v?.trim() ?? '');
                if (amount == null || amount <= 0) {
                  return 'Sahi amount likhein';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Text(
              'Entry ki qism',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            SegmentedButton<TransactionType>(
              segments: [
                ButtonSegment(
                  value: TransactionType.debit,
                  label: Text(KhataLabels.entryTypeShort(TransactionType.debit)),
                  icon: const Icon(Icons.add_circle_outline,
                      color: AppColors.receivable),
                ),
                ButtonSegment(
                  value: TransactionType.credit,
                  label: Text(KhataLabels.entryTypeShort(TransactionType.credit)),
                  icon: const Icon(Icons.remove_circle_outline,
                      color: AppColors.payable),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (set) => setState(() => _type = set.first),
            ),
            const SizedBox(height: 8),
            Text(
              KhataLabels.entryDescription(_type),
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Tareekh aur Waqt'),
              subtitle: Text(
                '${DateFormat('dd MMM yyyy').format(_selectedDate)} · '
                '${DateFormat('hh:mm a').format(_selectedDate)}',
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final picked = await pickDateAndTime(
                  context,
                  initial: _selectedDate,
                );
                if (picked != null) setState(() => _selectedDate = picked);
              },
            ),
            TextFormField(
              controller: _noteController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.notes),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _isSaving ? null : _submit,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(_isSaving ? 'Saving…' : 'Save Karein'),
            ),
          ],
        ),
      ),
    );
  }
}
