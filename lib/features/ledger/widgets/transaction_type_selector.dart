import 'package:flutter/material.dart';
import 'package:smart_khata_manager/core/theme/app_colors.dart';
import 'package:smart_khata_manager/features/ledger/models/khata_category.dart';
import 'package:smart_khata_manager/features/ledger/models/khata_labels.dart';
import 'package:smart_khata_manager/features/ledger/models/transaction_type.dart';

/// Category ke mutabiq sirf 2 entry types — odhaar + wapas/ada.
class TransactionTypeSelector extends StatelessWidget {
  const TransactionTypeSelector({
    super.key,
    required this.category,
    required this.selected,
    required this.onChanged,
  });

  final KhataCategory category;
  final TransactionType selected;
  final ValueChanged<TransactionType> onChanged;

  @override
  Widget build(BuildContext context) {
    final types = category.entryTypes;
    final accent = category.color;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          category.subtitle,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: accent,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (var i = 0; i < types.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                child: _TypeChip(
                  type: types[i],
                  selected: selected == types[i],
                  accent: accent,
                  onTap: () => onChanged(types[i]),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Text(
          KhataLabels.entryDescription(selected),
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.type,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final TransactionType type;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? accent.withValues(alpha: 0.15) : AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? accent : Colors.grey.shade300,
              width: selected ? 2 : 1,
            ),
          ),
          child: Text(
            KhataLabels.entryTypeShort(type),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.bold : FontWeight.w500,
              color: selected ? accent : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
