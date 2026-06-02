import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_khata_manager/app/routes/app_routes.dart';
import 'package:smart_khata_manager/core/theme/app_colors.dart';
import 'package:smart_khata_manager/features/ledger/controllers/party_detail_controller.dart';
import 'package:smart_khata_manager/features/ledger/models/party.dart';
import 'package:smart_khata_manager/features/ledger/models/party_account_summary.dart';
import 'package:smart_khata_manager/features/ledger/widgets/add_party_transaction_sheet.dart';
import 'package:smart_khata_manager/features/ledger/widgets/transaction_history_table.dart';

/// Har shakhs ka alag khata — lenay/denay breakdown + history.
class PartyDetailPage extends GetView<PartyDetailController> {
  const PartyDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final party = controller.currentParty;
      final transactions = controller.ledger.transactions;
      final summary = PartyAccountSummary.fromTransactions(
        party.category,
        transactions,
        currentBalance: party.currentBalance,
      );

      return Scaffold(
        appBar: AppBar(
          title: Text(party.name),
          actions: [
            IconButton(
              icon: const Icon(Icons.receipt_long),
              tooltip: 'Receipt scan',
              onPressed: () => Get.toNamed(
                AppRoutes.addTransaction,
                arguments: party,
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            _KhataSummaryCard(party: party, summary: summary),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  Text(
                    '${party.category.title} — entries',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: party.category.color,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const Spacer(),
                  Text(
                    '${transactions.length} entries',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: transactions.isEmpty
                  ? _EmptyTransactions(partyName: party.name)
                  : TransactionHistoryTable(
                      transactions: transactions,
                      onDelete: (id) => _confirmDeleteTransaction(context, id),
                    ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _openAddTransactionSheet(context, party),
          icon: const Icon(Icons.add),
          label: const Text('Entry Add Karein'),
        ),
      );
    });
  }

  void _openAddTransactionSheet(BuildContext context, Party party) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => AddPartyTransactionSheet(
        party: party,
        controller: controller,
      ),
    );
  }

  Future<void> _confirmDeleteTransaction(
    BuildContext context,
    String transactionId,
  ) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Entry Delete'),
        content: const Text(
          'Ye entry delete karein? Balance dubara calculate hoga.',
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
      await controller.deleteTransaction(transactionId);
      if (controller.ledger.errorMessage.value != null) {
        Get.snackbar('Error', controller.ledger.errorMessage.value!);
      }
    }
  }
}

class _KhataSummaryCard extends StatelessWidget {
  const _KhataSummaryCard({
    required this.party,
    required this.summary,
  });

  final Party party;
  final PartyAccountSummary summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (party.phone.isNotEmpty)
            Text(
              party.phone,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          const SizedBox(height: 12),
          _SectionTitle(
            title: party.category.title,
            color: party.category.color,
          ),
          const SizedBox(height: 8),
          _StatRow(
            label: party.category.kulLabel,
            value: summary.kulOdhaar,
            color: party.category.color,
          ),
          _StatRow(
            label: party.category.wapasLabel,
            value: summary.totalWapas,
            color: AppColors.textSecondary,
          ),
          _StatRow(
            label: party.category.baakiLabel,
            value: summary.baaki,
            color: party.category.color,
            bold: true,
          ),
          if (!summary.hasActivity && summary.isSettled)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Abhi koi entry nahi — pehli entry add karein',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ),
          if (summary.isSettled && summary.hasActivity)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Center(
                child: Text(
                  '✓ Account clear — sab wasool / ada ho gaya',
                  style: TextStyle(
                    color: AppColors.receivable,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.color});

  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 15,
        color: color,
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.label,
    required this.value,
    required this.color,
    this.bold = false,
  });

  final String label;
  final double value;
  final Color color;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            'Rs. ${value.toStringAsFixed(0)}',
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.w600,
              fontSize: bold ? 18 : 15,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyTransactions extends StatelessWidget {
  const _EmptyTransactions({required this.partyName});

  final String partyName;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              '$partyName ka khata khali hai',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '"Entry Add Karein" se udhar ya wasooli likhein.\n'
              'Baaki balance khud calculate hoga.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
