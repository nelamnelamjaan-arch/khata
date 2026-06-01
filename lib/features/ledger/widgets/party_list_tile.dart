import 'package:flutter/material.dart';
import 'package:smart_khata_manager/core/theme/app_colors.dart';
import 'package:smart_khata_manager/features/ledger/models/party.dart';

/// Har naam ki row — baaki lenay/denay amount.
class PartyListTile extends StatelessWidget {
  const PartyListTile({
    super.key,
    required this.party,
    this.onTap,
    this.onDelete,
  });

  final Party party;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final balanceInfo = _balanceLabel(party);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: CircleAvatar(
        backgroundColor: balanceInfo.color.withValues(alpha: 0.15),
        child: Text(
          party.name.isNotEmpty ? party.name[0].toUpperCase() : '?',
          style: TextStyle(
            color: balanceInfo.color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        party.name,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
      subtitle: Text(
        party.phone.isNotEmpty ? party.phone : 'Tap karein — khata dekhein',
        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            party.isSettled
                ? 'Clear'
                : 'Rs. ${party.currentBalance.abs().toStringAsFixed(0)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: balanceInfo.color,
              fontSize: 16,
            ),
          ),
          Text(
            balanceInfo.label,
            style: TextStyle(fontSize: 11, color: balanceInfo.color),
          ),
        ],
      ),
      onTap: onTap,
      onLongPress: onDelete,
    );
  }

  ({String label, Color color}) _balanceLabel(Party party) {
    if (party.isReceivable) {
      return (label: 'Baaki lenay hain', color: AppColors.receivable);
    }
    if (party.isPayable) {
      return (label: 'Baaki denay hain', color: AppColors.payable);
    }
    return (label: 'Clear', color: AppColors.textSecondary);
  }
}
