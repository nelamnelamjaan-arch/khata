import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_khata_manager/app/routes/app_routes.dart';
import 'package:smart_khata_manager/core/config/app_constants.dart';
import 'package:smart_khata_manager/core/services/firebase_service.dart';
import 'package:smart_khata_manager/core/services/network_service.dart';
import 'package:smart_khata_manager/core/theme/app_colors.dart';
import 'package:smart_khata_manager/core/widgets/firebase_connection_panel.dart';
import 'package:smart_khata_manager/features/dashboard/models/dashboard_summary.dart';
import 'package:smart_khata_manager/features/ledger/services/ledger_service.dart';

/// Real-time khata summary from Firestore.
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late final Stream<DashboardSummary> _summaryStream =
      Get.find<LedgerService>().watchDashboardSummary();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.people),
            tooltip: 'Parties',
            onPressed: () => Get.toNamed(AppRoutes.ledger),
          ),
          if (Get.isRegistered<NetworkService>())
            Obx(() {
              final network = Get.find<NetworkService>();
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Icon(
                  network.isOnline.value ? Icons.cloud_done : Icons.cloud_off,
                  color: network.isOnline.value
                      ? Colors.greenAccent
                      : Colors.orangeAccent,
                ),
              );
            }),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (Get.isRegistered<FirebaseService>())
              const FirebaseConnectionPanel(),
            Expanded(
              child: StreamBuilder<DashboardSummary>(
                stream: _summaryStream,
                initialData: DashboardSummary.empty,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Firestore error:\n${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.payable),
                        ),
                      ),
                    );
                  }

                  final summary = snapshot.data ?? DashboardSummary.empty;

                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(
                        'Khata Summary',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Sab logon ka khata — live update',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 20),
                      _SummaryCard(
                        title: 'Total Receivable',
                        subtitle: 'Lenay hain',
                        amount: summary.totalReceivable,
                        partyCount: summary.receivablePartyCount,
                        color: AppColors.receivable,
                        bgColor: AppColors.receivableLight,
                        icon: Icons.arrow_downward,
                      ),
                      const SizedBox(height: 12),
                      _SummaryCard(
                        title: 'Total Payable',
                        subtitle: 'Denay hain',
                        amount: summary.totalPayable,
                        partyCount: summary.payablePartyCount,
                        color: AppColors.payable,
                        bgColor: AppColors.payableLight,
                        icon: Icons.arrow_upward,
                      ),
                      if (summary.rawTransactionDocs > 0 &&
                          summary.transactionCount == 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            'Firestore mein ${summary.rawTransactionDocs} documents hain '
                            'lekin fields match nahi kar rahi. '
                            'Har doc mein amount aur type (debit/credit) hona chahiye.',
                            style: TextStyle(
                              color: Colors.orange.shade800,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => Get.toNamed(AppRoutes.ledger),
                              icon: const Icon(Icons.people_outline),
                              label: const Text('Khata Book'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () =>
                                  Get.toNamed(AppRoutes.addTransaction),
                              icon: const Icon(Icons.receipt_long),
                              label: const Text('Add Entry'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.toNamed(AppRoutes.addTransaction),
        icon: const Icon(Icons.add),
        label: const Text('Transaction'),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.partyCount,
    required this.color,
    required this.bgColor,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final double amount;
  final int partyCount;
  final Color color;
  final Color bgColor;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      color: bgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: color.withValues(alpha: 0.85),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Rs. ${amount.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  if (partyCount > 0)
                    Text(
                      '$partyCount ${partyCount == 1 ? 'party' : 'parties'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: color.withValues(alpha: 0.7),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
