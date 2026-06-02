import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smart_khata_manager/core/theme/app_colors.dart';
import 'package:smart_khata_manager/features/ledger/models/khata_labels.dart';
import 'package:smart_khata_manager/features/ledger/models/transaction.dart';

/// Har lenay/denay entry ka table — tareekh, waqt, qism, rupay.
class TransactionHistoryTable extends StatelessWidget {
  const TransactionHistoryTable({
    super.key,
    required this.transactions,
    this.onDelete,
  });

  final List<TransactionModel> transactions;
  final void Function(String id)? onDelete;

  static final _dateFmt = DateFormat('dd MMM yyyy');
  static final _timeFmt = DateFormat('hh:mm a');

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 520),
          child: Card(
            elevation: 1,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Table(
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              columnWidths: const {
                0: FixedColumnWidth(36),
                1: FixedColumnWidth(108),
                2: FixedColumnWidth(72),
                3: FixedColumnWidth(120),
                4: FixedColumnWidth(88),
                5: FixedColumnWidth(100),
              },
              border: TableBorder(
                horizontalInside: BorderSide(color: Colors.grey.shade200),
              ),
              children: [
                _headerRow(),
                ...transactions.asMap().entries.map(
                      (e) => _dataRow(
                        index: e.key + 1,
                        tx: e.value,
                      ),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  TableRow _headerRow() {
    return TableRow(
      decoration: BoxDecoration(color: Colors.grey.shade100),
      children: const [
        _HeaderCell('#'),
        _HeaderCell('Tareekh'),
        _HeaderCell('Waqt'),
        _HeaderCell('Qism'),
        _HeaderCell('Rupay'),
        _HeaderCell('Note'),
      ],
    );
  }

  TableRow _dataRow({required int index, required TransactionModel tx}) {
    final color = tx.type.isLenaySide
        ? AppColors.receivable
        : AppColors.payable;
    final typeLabel = KhataLabels.entryTypeShort(tx.type);

    return TableRow(
      children: [
        _DataCell(Text('$index', style: const TextStyle(fontSize: 12))),
        _DataCell(Text(_dateFmt.format(tx.date), style: const TextStyle(fontSize: 12))),
        _DataCell(Text(_timeFmt.format(tx.date), style: const TextStyle(fontSize: 12))),
        _DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              typeLabel,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ),
        _DataCell(
          Text(
            'Rs.${tx.amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 13,
            ),
          ),
        ),
        _DataCell(
          Row(
            children: [
              Expanded(
                child: Text(
                  tx.note.isEmpty ? '—' : tx.note,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                ),
              ),
              if (onDelete != null)
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  onPressed: () => onDelete!(tx.id),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

class _DataCell extends StatelessWidget {
  const _DataCell(this.child);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: child,
    );
  }
}

/// Date + time picker helper.
Future<DateTime?> pickDateAndTime(
  BuildContext context, {
  required DateTime initial,
}) async {
  final pickedDate = await showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: DateTime(2020),
    lastDate: DateTime.now().add(const Duration(days: 365)),
  );
  if (pickedDate == null || !context.mounted) return null;

  final pickedTime = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(initial),
  );
  if (pickedTime == null) return null;

  return DateTime(
    pickedDate.year,
    pickedDate.month,
    pickedDate.day,
    pickedTime.hour,
    pickedTime.minute,
  );
}
