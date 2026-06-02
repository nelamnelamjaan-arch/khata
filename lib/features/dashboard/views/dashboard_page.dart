import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_khata_manager/app/routes/app_routes.dart';
import 'package:smart_khata_manager/core/config/app_constants.dart';
import 'package:smart_khata_manager/core/services/auth_service.dart';
import 'package:smart_khata_manager/core/services/network_service.dart';
import 'package:smart_khata_manager/core/theme/app_colors.dart';
import 'package:smart_khata_manager/features/dashboard/models/dashboard_summary.dart';
import 'package:smart_khata_manager/features/ledger/models/khata_category.dart';
import 'package:smart_khata_manager/features/ledger/services/ledger_service.dart';

/// Real-time khata summary from Firestore.
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late final Stream<DashboardSummary> _summaryStream;

  @override
  void initState() {
    super.initState();
    _summaryStream = Get.find<LedgerService>().watchDashboardSummary();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!Get.find<AuthService>().isSignedIn) {
        Get.offAllNamed(AppRoutes.auth);
      }
    });
  }

  void _openKhataBook(KhataCategory category) {
    Get.toNamed(
      category == KhataCategory.lenay
          ? AppRoutes.ledgerLenay
          : AppRoutes.ledgerDenay,
    );
  }

  void _showKhataPicker() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Khata Book Kholein',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              _KhataBookTile(
                category: KhataCategory.lenay,
                onTap: () {
                  Navigator.pop(context);
                  _openKhataBook(KhataCategory.lenay);
                },
              ),
              const SizedBox(height: 8),
              _KhataBookTile(
                category: KhataCategory.denay,
                onTap: () {
                  Navigator.pop(context);
                  _openKhataBook(KhataCategory.denay);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_book_outlined),
            tooltip: 'Khata Books',
            onPressed: _showKhataPicker,
          ),
          PopupMenuButton<String>(
            tooltip: 'Account',
            onSelected: (value) async {
              if (value == 'signout') {
                await Get.find<AuthService>().signOut();
                Get.offAllNamed(AppRoutes.auth);
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'signout',
                child: ListTile(
                  leading: Icon(Icons.logout),
                  title: Text('Sign out'),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
            ],
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
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Do alag khata books — tap karein aur kaam karein',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 20),
                _KhataBreakdownCard(
                  title: KhataCategory.lenay.title,
                  subtitle: KhataCategory.lenay.subtitle,
                  baaki: summary.totalReceivable,
                  kul: summary.kulOdhaarDiya,
                  wapas: summary.totalWasooli,
                  partyCount: summary.receivablePartyCount,
                  color: KhataCategory.lenay.color,
                  bgColor: KhataCategory.lenay.bgColor,
                  icon: KhataCategory.lenay.icon,
                  kulLabel: KhataCategory.lenay.kulLabel,
                  wapasLabel: KhataCategory.lenay.wapasLabel,
                  baakiLabel: KhataCategory.lenay.baakiLabel,
                  onTap: () => _openKhataBook(KhataCategory.lenay),
                ),
                const SizedBox(height: 12),
                _KhataBreakdownCard(
                  title: KhataCategory.denay.title,
                  subtitle: KhataCategory.denay.subtitle,
                  baaki: summary.totalPayable,
                  kul: summary.kulOdhaarLiya,
                  wapas: summary.totalAdaKiya,
                  partyCount: summary.payablePartyCount,
                  color: KhataCategory.denay.color,
                  bgColor: KhataCategory.denay.bgColor,
                  icon: KhataCategory.denay.icon,
                  kulLabel: KhataCategory.denay.kulLabel,
                  wapasLabel: KhataCategory.denay.wapasLabel,
                  baakiLabel: KhataCategory.denay.baakiLabel,
                  onTap: () => _openKhataBook(KhataCategory.denay),
                ),
                if (summary.rawTransactionDocs > 0 &&
                    summary.transactionCount == 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      'Firestore mein ${summary.rawTransactionDocs} documents hain '
                      'lekin fields match nahi kar rahi. '
                      'Har doc mein amount aur type hona chahiye.',
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
                        onPressed: () => _openKhataBook(KhataCategory.lenay),
                        icon: const Icon(Icons.arrow_downward),
                        label: const Text('Unhon Ne Liya'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _openKhataBook(KhataCategory.denay),
                        icon: const Icon(Icons.arrow_upward),
                        label: const Text('Maine Liya'),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _KhataBookTile extends StatelessWidget {
  const _KhataBookTile({required this.category, required this.onTap});

  final KhataCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: category.color.withValues(alpha: 0.15),
        child: Icon(category.icon, color: category.color),
      ),
      title: Text(category.title),
      subtitle: Text(category.subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: category.color.withValues(alpha: 0.3)),
      ),
    );
  }
}

class _KhataBreakdownCard extends StatelessWidget {
  const _KhataBreakdownCard({
    required this.title,
    required this.subtitle,
    required this.baaki,
    required this.kul,
    required this.wapas,
    required this.partyCount,
    required this.color,
    required this.bgColor,
    required this.icon,
    required this.kulLabel,
    required this.wapasLabel,
    required this.baakiLabel,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final double baaki;
  final double kul;
  final double wapas;
  final int partyCount;
  final Color color;
  final Color bgColor;
  final IconData icon;
  final String kulLabel;
  final String wapasLabel;
  final String baakiLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      color: bgColor,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withValues(alpha: 0.3)),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: color.withValues(alpha: 0.85),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: color),
                ],
              ),
              const SizedBox(height: 16),
              _BreakdownRow(label: kulLabel, amount: kul, color: color),
              _BreakdownRow(
                label: wapasLabel,
                amount: wapas,
                color: AppColors.textSecondary,
              ),
              const Divider(height: 20),
              _BreakdownRow(
                label: baakiLabel,
                amount: baaki,
                color: color,
                bold: true,
              ),
              if (partyCount > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '$partyCount ${partyCount == 1 ? 'naam' : 'naam'} — khata book kholein',
                    style: TextStyle(
                      fontSize: 12,
                      color: color.withValues(alpha: 0.7),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.label,
    required this.amount,
    required this.color,
    this.bold = false,
  });

  final String label;
  final double amount;
  final Color color;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: bold ? 14 : 13,
              fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          Text(
            'Rs. ${amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.w600,
              fontSize: bold ? 20 : 14,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
