import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smart_khata_manager/core/theme/app_colors.dart';
import 'package:smart_khata_manager/features/ledger/models/khata_labels.dart';
import 'package:smart_khata_manager/features/ledger/models/transaction.dart';

class TransactionListTile extends StatelessWidget {
  const TransactionListTile({
    super.key,
    required this.transaction,
    this.onDelete,
  });

  final TransactionModel transaction;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final isDebit = transaction.isDebit;
    final color = isDebit ? AppColors.receivable : AppColors.payable;
    final typeLabel = KhataLabels.entryTypeLabel(transaction.type);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.15),
        child: Icon(
          isDebit ? Icons.add : Icons.check,
          color: color,
          size: 20,
        ),
      ),
      title: Text(
        'Rs. ${transaction.amount.toStringAsFixed(0)}',
        style: TextStyle(fontWeight: FontWeight.bold, color: color),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$typeLabel · ${DateFormat.yMMMd().format(transaction.date)}'),
          if (transaction.note.isNotEmpty)
            Text(
              transaction.note,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
        ],
      ),
      trailing: onDelete != null
          ? IconButton(
              icon: Icon(Icons.delete_outline, color: Colors.grey.shade600),
              onPressed: onDelete,
            )
          : null,
    );
  }
}
