import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:zakoota/l10n/app_localizations.dart';
import '../../cases/models/case_model.dart';
import '../../cases/models/consultation_model.dart';
import '../../cases/services/case_service.dart';
import '../../cases/services/consultation_service.dart';
import '../../cases/services/consultation_utils.dart';

/// My Cases Screen - Appointments & Active Cases
class MyCasesScreen extends StatefulWidget {
  const MyCasesScreen({super.key});

  @override
  State<MyCasesScreen> createState() => _MyCasesScreenState();
}

class _MyCasesScreenState extends State<MyCasesScreen> {
  Future<void> _onRefresh() async {
    // Simulate data refresh
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cases refreshed'),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final loc = AppLocalizations.of(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          automaticallyImplyLeading: false,
          toolbarHeight: 70,
          title: Text(
            loc.myCases,
            style: textTheme.headlineSmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.grey200,
                    width: 1,
                  ),
                ),
              ),
              child: TabBar(
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  border: const Border(
                    bottom: BorderSide(
                      color: AppColors.primary,
                      width: 3,
                    ),
                  ),
                ),
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
                unselectedLabelStyle: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                ),
                tabs: [
                  Tab(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(loc.consultations),
                    ),
                  ),
                  Tab(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(loc.myCases),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        body: TabBarView(
          children: [
            _ConsultationsTab(onRefresh: _onRefresh),
            _MyCasesTab(onRefresh: _onRefresh),
          ],
        ),
      ),
    );
  }
}

/// Consultations Tab
class _ConsultationsTab extends StatelessWidget {
  final Future<void> Function() onRefresh;

  const _ConsultationsTab({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final authService = AuthService();
    final consultationService = ConsultationService();
    final user = authService.currentUser;

    if (user == null) {
      return Center(child: Text(loc.loginToViewConsultations));
    }

    return StreamBuilder<List<ConsultationModel>>(
      stream: consultationService.getConsultationsForUser(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final consultations = snapshot.data ?? [];

        if (consultations.isEmpty) {
          return RefreshIndicator(
            onRefresh: onRefresh,
            color: AppColors.primary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height - 200,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.grey200, width: 2),
                        ),
                        child: PhosphorIcon(
                          PhosphorIconsRegular.calendarX,
                          size: 48,
                          color: AppColors.textLight,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        loc.noConsultationsYet,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: onRefresh,
          color: AppColors.primary,
          child: ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: consultations.length,
            separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) {
              return _ConsultationCard(
                consultation: consultations[index],
                currentUserId: user.uid,
              );
            },
          ),
        );
      },
    );
  }
}

/// Consultation Card Widget
class _ConsultationCard extends StatelessWidget {
  final ConsultationModel consultation;
  final String currentUserId;

  const _ConsultationCard({
    required this.consultation,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final typeIcon = consultation.type == 'video'
        ? PhosphorIconsRegular.videoCamera
        : PhosphorIconsRegular.usersThree;

    final isStandalone = consultation.caseId == 'standalone';
    final otherPartyName = consultation.requesterId == currentUserId ? consultation.lawyerName : consultation.clientName;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.grey200, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date Box
                Container(
                  width: 65,
                  height: 75,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _getMonth(consultation.scheduledAt),
                        style: textTheme.labelSmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${consultation.scheduledAt.day}',
                        style: textTheme.headlineMedium?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              consultation.caseTitle,
                              style: textTheme.labelMedium?.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          _ConsultationStatusChip(status: consultation.status),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        otherPartyName,
                        style: textTheme.titleMedium?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                PhosphorIcon(typeIcon, size: 14, color: AppColors.textSecondary),
                                const SizedBox(width: 4),
                                Text(
                                  consultation.type == 'video' ? 'Video' : 'In-Person',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                PhosphorIcon(PhosphorIconsRegular.clock, size: 14, color: AppColors.textSecondary),
                                const SizedBox(width: 4),
                                Text(
                                  '${consultation.scheduledAt.hour.toString().padLeft(2, '0')}:${consultation.scheduledAt.minute.toString().padLeft(2, '0')}',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isStandalone) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.secondary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                'DIRECT',
                                style: textTheme.labelSmall?.copyWith(
                                  color: AppColors.secondary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ]
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Actions Footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(AppRadius.lg),
                bottomRight: Radius.circular(AppRadius.lg),
              ),
              border: Border(top: BorderSide(color: AppColors.grey200)),
            ),
            child: Row(
              children: [
                if (isStandalone)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        context.push(
                          '/chat/direct/${consultation.requesterId == currentUserId ? consultation.lawyerId : consultation.clientId}',
                          extra: {
                            'clientId': consultation.clientId,
                            'lawyerId': consultation.lawyerId,
                            'clientName': consultation.clientName,
                            'lawyerName': consultation.lawyerName,
                            'clientAvatar': consultation.clientAvatar,
                            'lawyerAvatar': consultation.lawyerAvatar,
                          },
                        );
                      },
                      icon: const PhosphorIcon(PhosphorIconsRegular.chatCircleDots, size: 18),
                      label: const Text('Message'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.grey300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                if (isStandalone) const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: FilledButton(
                    onPressed: () => _handleConsultationAction(context, 'details'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.surface,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('View Details'),
                  ),
                ),
                if (consultation.status == 'pending' && consultation.targetId == currentUserId) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => _handleConsultationAction(context, 'respond'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        foregroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Respond', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
                if (ConsultationUtils.canCancel(consultation)) ...[
                  const SizedBox(width: AppSpacing.sm),
                  IconButton(
                    onPressed: () => _handleConsultationAction(context, 'cancel'),
                    icon: const PhosphorIcon(PhosphorIconsRegular.xCircle, color: AppColors.error),
                    tooltip: 'Cancel',
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.error.withValues(alpha: 0.1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ]
              ],
            ),
          )
        ],
      ),
    );
  }

  void _handleConsultationAction(BuildContext context, String action) {
    switch (action) {
      case 'details':
        context.push('/consultation-details/${consultation.caseId}/${consultation.id}');
        break;
      case 'respond':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Go to workspace to respond to consultation')),
        );
        break;
      case 'cancel':
        _showCancelDialog(context);
        break;
    }
  }

  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Consultation'),
        content: const Text('Are you sure you want to cancel this consultation?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _cancelConsultation(context);
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Cancel Consultation'),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelConsultation(BuildContext context) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      await ConsultationService().requestCancellation(
        consultation,
        user?.uid ?? 'unknown',
        user?.displayName ?? 'User',
        'Cancelled by user',
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Consultation cancelled'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  String _getMonth(DateTime date) {
    const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    return months[date.month - 1];
  }
}

/// Consultation Status Chip Widget
class _ConsultationStatusChip extends StatelessWidget {
  final String status;

  const _ConsultationStatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color backgroundColor;
    Color textColor;
    String label;

    switch (status.toLowerCase()) {
      case 'accepted':
        backgroundColor = AppColors.success.withValues(alpha: 0.1);
        textColor = AppColors.success;
        label = 'Accepted';
        break;
      case 'pending':
        backgroundColor = const Color(0xFFF59E0B).withValues(alpha: 0.1);
        textColor = const Color(0xFFD97706);
        label = 'Pending';
        break;
      case 'rejected':
      case 'cancelled':
        backgroundColor = AppColors.error.withValues(alpha: 0.1);
        textColor = AppColors.error;
        label = status == 'rejected' ? 'Rejected' : 'Cancelled';
        break;
      case 'completed':
        backgroundColor = AppColors.grey200;
        textColor = AppColors.textSecondary;
        label = 'Completed';
        break;
      case 'cancellation_requested':
        backgroundColor = AppColors.grey200;
        textColor = AppColors.textSecondary;
        label = 'Cancellation Requested';
        break;
      case 'no_show':
        backgroundColor = AppColors.error.withValues(alpha: 0.1);
        textColor = AppColors.error;
        label = 'No Show';
        break;
      default:
        backgroundColor = AppColors.grey200;
        textColor = AppColors.textSecondary;
        label = status.toUpperCase();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// My Cases Tab
class _MyCasesTab extends StatelessWidget {
  final Future<void> Function() onRefresh;

  const _MyCasesTab({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final authService = AuthService();
    final caseService = CaseService();
    final user = authService.currentUser;

    if (user == null) {
      return Center(child: Text(loc.loginToViewCases));
    }

    return StreamBuilder<List<CaseModel>>(
      stream: caseService.getCasesForClient(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: PhosphorIcon(PhosphorIconsRegular.warningCircle, color: AppColors.error, size: 48),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          );
        }

        final cases = snapshot.data ?? [];

        return Column(
          children: [
            // Header Action
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              color: AppColors.background,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${cases.length} ${loc.activeCases}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () => context.push('/create-case'),
                    icon: const PhosphorIcon(PhosphorIconsRegular.plus, size: 18),
                    label: Text(loc.postACase, style: const TextStyle(fontWeight: FontWeight.w600)),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.surface,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ),

            // Cases List
            Expanded(
              child: cases.isEmpty
                  ? RefreshIndicator(
                      onRefresh: onRefresh,
                      color: AppColors.primary,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: SizedBox(
                          height: MediaQuery.of(context).size.height - 300,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppColors.grey200, width: 2),
                                  ),
                                  child: PhosphorIcon(
                                    PhosphorIconsRegular.folderOpen,
                                    size: 48,
                                    color: AppColors.textLight,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                Text(
                                  loc.noActiveCases,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: onRefresh,
                      color: AppColors.primary,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
                        itemCount: cases.length,
                        separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
                        itemBuilder: (context, index) {
                          return _CaseSummaryCard(caseModel: cases[index]);
                        },
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}

/// Case Summary Card Widget
class _CaseSummaryCard extends StatelessWidget {
  final CaseModel caseModel;

  const _CaseSummaryCard({required this.caseModel});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final statusColor = _getStatusColor(caseModel.status);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.grey200, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.grey200)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: PhosphorIcon(
                    _getCaseIcon(caseModel.title),
                    size: 24,
                    color: statusColor,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Case #${caseModel.caseId.substring(0, 8).toUpperCase()}',
                            style: textTheme.labelSmall?.copyWith(
                              color: AppColors.textSecondary,
                              letterSpacing: 1,
                              fontFamily: 'Courier',
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              caseModel.status.toUpperCase(),
                              style: textTheme.labelSmall?.copyWith(
                                color: statusColor,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        caseModel.title,
                        style: textTheme.titleMedium?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (caseModel.status == 'active')
                        FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance.collection('users').doc(caseModel.acceptedLawyerId).get(),
                          builder: (context, snapshot) {
                            if (snapshot.hasData && snapshot.data!.exists) {
                              final name = snapshot.data!.get('fullName') ?? 'Lawyer';
                              return Row(
                                children: [
                                  const PhosphorIcon(PhosphorIconsRegular.user, size: 14, color: AppColors.secondary),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Adv. $name',
                                    style: textTheme.bodySmall?.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        )
                      else if (!caseModel.isAdVisible)
                        Row(
                          children: [
                            PhosphorIcon(PhosphorIconsRegular.eyeClosed, size: 14, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              'Ad Paused',
                              style: textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                if (caseModel.status != 'active') ...[
                  const SizedBox(width: 8),
                  Transform.scale(
                    scale: 0.8,
                    alignment: Alignment.centerRight,
                    child: Switch(
                      value: caseModel.isAdVisible,
                      activeColor: AppColors.primary,
                      inactiveThumbColor: AppColors.surface,
                      inactiveTrackColor: AppColors.grey300,
                      onChanged: (value) async {
                        try {
                          await CaseService().toggleAdVisibility(caseModel.caseId, value);
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error updating ad: $e')),
                            );
                          }
                        }
                      },
                    ),
                  ),
                ]
              ],
            ),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  caseModel.description,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const PhosphorIcon(PhosphorIconsRegular.mapPin, size: 16, color: AppColors.textSecondary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              caseModel.city,
                              style: textTheme.bodySmall?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        const PhosphorIcon(PhosphorIconsRegular.calendarBlank, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Text(
                          _formatDate(caseModel.createdAt),
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Footer Action
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(AppRadius.lg),
                bottomRight: Radius.circular(AppRadius.lg),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  context.push('/case-ad-details', extra: caseModel);
                },
                icon: PhosphorIcon(
                  caseModel.status == 'active' ? PhosphorIconsRegular.briefcase : PhosphorIconsRegular.pencilSimple,
                  size: 18,
                ),
                label: Text(
                  caseModel.status == 'active' ? 'Open Workspace' : 'Manage Ad Details',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: caseModel.status == 'active' ? AppColors.primary : AppColors.surface,
                  foregroundColor: caseModel.status == 'active' ? AppColors.surface : AppColors.primary,
                  side: caseModel.status == 'active' ? BorderSide.none : BorderSide(color: AppColors.grey300),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return AppColors.info;
      case 'active':
        return AppColors.success;
      case 'resolved':
      case 'settled':
        return AppColors.success;
      case 'closed':
        return AppColors.textSecondary;
      default:
        return AppColors.grey400;
    }
  }

  PhosphorIconData _getCaseIcon(String title) {
    if (title.toLowerCase().contains('property') || title.toLowerCase().contains('dispute')) {
      return PhosphorIconsRegular.buildings;
    } else if (title.toLowerCase().contains('contract') || title.toLowerCase().contains('business')) {
      return PhosphorIconsRegular.fileText;
    } else if (title.toLowerCase().contains('family')) {
      return PhosphorIconsRegular.users;
    } else if (title.toLowerCase().contains('criminal')) {
      return PhosphorIconsRegular.warning;
    }
    return PhosphorIconsRegular.scales;
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
