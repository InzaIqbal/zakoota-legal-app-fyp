import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/constants/app_constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/auth_service.dart';
class LawyerAnalyticsScreen extends StatefulWidget {
  const LawyerAnalyticsScreen({super.key});

  @override
  State<LawyerAnalyticsScreen> createState() => _LawyerAnalyticsScreenState();
}

class _LawyerAnalyticsScreenState extends State<LawyerAnalyticsScreen> {
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(loc.analytics),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Income Stats Cards
            Text(
              'Income Overview',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildIncomeStatsGrid(),
            const SizedBox(height: AppSpacing.lg),

            // Case Statistics
            Text(
              'Case Statistics',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildCaseStats(),
            const SizedBox(height: AppSpacing.lg),

            // Ad Performance
            Text(
              'Ad Performance',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildAdPerformance(),
            const SizedBox(height: AppSpacing.lg),

            // Report Generation
            _buildReportGenerationSection(),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildIncomeStatsGrid() {
    final user = AuthService().currentUser;
    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        double walletBalance = 0;
        double heldBalance = 0;
        
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          walletBalance = (data?['walletBalance'] ?? 0).toDouble();
          heldBalance = (data?['heldBalance'] ?? 0).toDouble();
        }

        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Available Balance',
                    value: 'PKR ${walletBalance.toStringAsFixed(0)}',
                    icon: PhosphorIconsRegular.currencyDollar,
                    color: AppColors.success,
                    details: 'Ready to withdraw',
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _StatCard(
                    title: 'Pending',
                    value: 'PKR ${heldBalance.toStringAsFixed(0)}',
                    icon: PhosphorIconsRegular.clock,
                    color: AppColors.warning,
                    details: 'To be released',
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildCaseStats() {
    final user = AuthService().currentUser;
    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('cases')
          .where('acceptedLawyerId', isEqualTo: user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        int activeCases = 0;
        int completedCases = 0;

        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>?;
            final status = data?['status'] as String?;
            if (status == 'active') activeCases++;
            if (status == 'completed') completedCases++;
          }
        }

        return Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.grey200),
          ),
          child: Column(
            children: [
              _buildStatRow(
                'Active Cases',
                activeCases.toString(),
                PhosphorIconsRegular.briefcase,
                AppColors.primary,
              ),
              const Divider(height: 24),
              _buildStatRow(
                'Completed Cases',
                completedCases.toString(),
                PhosphorIconsRegular.checkCircle,
                AppColors.success,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatRow(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: PhosphorIcon(icon, color: color, size: 20),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildAdPerformance() {
    final user = AuthService().currentUser;
    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('lawyer_ads')
          .where('lawyerId', isEqualTo: user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        int activeAds = 0;
        int totalImpressions = 0;
        
        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>?;
            final isActive = data?['isActive'] == true;
            if (isActive) activeAds++;
            totalImpressions += (data?['impressions'] ?? 0) as int;
          }
        }

        return Column(
          children: [
            _buildAdStatCard(
              'Total Ad Impressions',
              totalImpressions.toString(),
              'Views across all ads',
              PhosphorIconsRegular.eye,
              AppColors.primary,
            ),
            const SizedBox(height: AppSpacing.md),
            _buildAdStatCard(
              'Active Ads',
              activeAds.toString(),
              'Currently running',
              PhosphorIconsRegular.play,
              AppColors.secondary,
            ),
            const SizedBox(height: AppSpacing.md),
            _buildAdStatCard(
              'Total Spent',
              'PKR 0', // Ad spending is not directly tracked right now
              'On active ads',
              PhosphorIconsRegular.wallet,
              AppColors.info,
            ),
          ],
        );
      },
    );
  }

  Widget _buildAdStatCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color, {
    Color? statusColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: PhosphorIcon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportGenerationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Generate Reports',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const PhosphorIcon(
                      PhosphorIconsRegular.fileText,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Download Financial Report',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Get your earnings, cases, and ad spending in PDF format',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _generateReport('PDF'),
                      icon: const PhosphorIcon(PhosphorIconsRegular.downloadSimple, size: 18),
                      label: const Text('Download PDF'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _generateReport('CSV'),
                      icon: const PhosphorIcon(PhosphorIconsRegular.downloadSimple, size: 18),
                      label: const Text('Download CSV'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _generateReport(String format) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Generating $format report...'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String details;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.details,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: PhosphorIcon(icon, color: color, size: 16),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            details,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }
}
