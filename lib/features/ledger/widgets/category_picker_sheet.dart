import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_khata_manager/features/ledger/models/khata_category.dart';

/// Lenay / Denay select karein — entry ya naam add karne se pehle.
Future<KhataCategory?> showCategoryPickerSheet(
  BuildContext context, {
  required String title,
  String? subtitle,
  KhataCategory? preselected,
}) {
  return showModalBottomSheet<KhataCategory>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => _CategoryPickerSheet(
      title: title,
      subtitle: subtitle,
      preselected: preselected,
    ),
  );
}

/// Save se pehle confirm karein ke entry kis section mein jayegi.
Future<bool> confirmEntryCategory(
  BuildContext context, {
  required KhataCategory category,
  required String partyName,
  required double amount,
}) async {
  final result = await Get.dialog<bool>(
    AlertDialog(
      title: const Text('Entry Confirm Karein'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Yeh entry "${category.title}" section mein save hogi.'),
          const SizedBox(height: 12),
          Text('Naam: $partyName'),
          Text('Rupay: Rs. ${amount.toStringAsFixed(0)}'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(result: false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Get.back(result: true),
          child: const Text('Haan, Save Karein'),
        ),
      ],
    ),
  );
  return result == true;
}

class _CategoryPickerSheet extends StatelessWidget {
  const _CategoryPickerSheet({
    required this.title,
    this.subtitle,
    this.preselected,
  });

  final String title;
  final String? subtitle;
  final KhataCategory? preselected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
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
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
            ],
            const SizedBox(height: 16),
            _CategoryOption(
              category: KhataCategory.lenay,
              selected: preselected == KhataCategory.lenay,
              onTap: () => Navigator.pop(context, KhataCategory.lenay),
            ),
            const SizedBox(height: 8),
            _CategoryOption(
              category: KhataCategory.denay,
              selected: preselected == KhataCategory.denay,
              onTap: () => Navigator.pop(context, KhataCategory.denay),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryOption extends StatelessWidget {
  const _CategoryOption({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final KhataCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? category.color.withValues(alpha: 0.12)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? category.color : Colors.grey.shade300,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(category.icon, color: category.color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: category.color,
                      ),
                    ),
                    Text(
                      category.subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (selected) Icon(Icons.check_circle, color: category.color),
            ],
          ),
        ),
      ),
    );
  }
}
