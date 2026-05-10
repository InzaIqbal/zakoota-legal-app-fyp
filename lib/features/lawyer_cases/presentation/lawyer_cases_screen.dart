import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:zakoota/l10n/app_localizations.dart';
import '../../../../core/constants/app_constants.dart';
import '../../cases/models/case_model.dart';
import '../services/lawyer_case_service.dart';
import '../../cases/models/consultation_model.dart';
import '../../cases/services/consultation_service.dart';
import '../../cases/services/consultation_utils.dart';

class LawyerCasesScreen extends StatelessWidget {
  const LawyerCasesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          toolbarHeight: 82,
          automaticallyImplyLeading: false,
          titleSpacing: AppSpacing.md,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                loc.myCases,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Track active work and consultations in one place',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.76),
                    ),
              ),
            ],
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(56),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: TabBar(
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white,
                indicator: BoxDecoration(),
                dividerColor: Colors.transparent,
                labelStyle: const TextStyle(fontWeight: FontWeight.w800),
                tabs: [
                  Tab(text: loc.activeCases),
                  Tab(text: loc.consultations),
                ],
              ),
            ),
          ),
        ),
        body: const TabBarView(
          children: [
            _ActiveCasesTab(),
            _ConsultationsTab(),
          ],
        ),
      ),
    );
  }
}

class _ActiveCasesTab extends StatelessWidget {
  const _ActiveCasesTab();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final loc = AppLocalizations.of(context);
    if (user == null) {
      return Center(child: Text(loc.loginToViewCases));
    }

    return StreamBuilder<List<CaseModel>>(
      stream: LawyerCaseService().getActiveCasesForLawyer(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('${loc.error}: ${snapshot.error}'));
        }

        final cases = snapshot.data ?? [];
        if (cases.isEmpty) {
          return _EmptyStateCard(
            icon: PhosphorIconsRegular.briefcase,
            title: loc.noActiveCasesYetApplyToJobs,
            message: 'All assigned cases will appear here.',
          );
        }

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.sm,
                ),
                child: _SummaryStrip(
                  title: loc.activeCases,
                  value: cases.length.toString(),
                  caption: 'Cases assigned',
                  icon: PhosphorIconsRegular.briefcase,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.md,
              ),
              sliver: SliverList.separated(
                itemCount: cases.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: AppSpacing.md),
                itemBuilder: (context, index) {
                  final caseItem = cases[index];
                  return _LawyerCaseCard(caseItem: caseItem);
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _LawyerCaseCard extends StatelessWidget {
  final CaseModel caseItem;

  const _LawyerCaseCard({required this.caseItem});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final budgetText = loc.budgetRange(
      caseItem.budgetMin.toInt().toString(),
      caseItem.budgetMax.toInt().toString(),
    );

    return GestureDetector(
      onTap: () {
        context.push('/case-workspace?caseId=${caseItem.caseId}&isClient=false', extra: {
          'caseModel': caseItem,
          'isClient': false,
        });
      },
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.grey100)),
              ),
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      '${loc.idLabel} ${caseItem.caseId.substring(0, 4).toUpperCase()}',
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: AppColors.textLight,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      loc.active,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    caseItem.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      _InfoChip(
                        icon: PhosphorIconsRegular.user,
                        label: loc.clientLabel,
                      ),
                      _InfoChip(
                        icon: PhosphorIconsRegular.currencyDollar,
                        label: budgetText,
                      ),
                      _InfoChip(
                        icon: PhosphorIconsRegular.tag,
                        label: caseItem.category,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        context.push(
                          '/case-workspace?caseId=${caseItem.caseId}&isClient=false',
                          extra: {
                            'caseModel': caseItem,
                            'isClient': false,
                          },
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                      ),
                      icon: const Icon(
                        PhosphorIconsRegular.arrowSquareOut,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      label: Text(
                        loc.openWorkspace,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
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

class _ConsultationsTab extends StatelessWidget {
  const _ConsultationsTab();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final loc = AppLocalizations.of(context);
    if (user == null) {
      return Center(child: Text(loc.loginToViewCases));
    }

    return StreamBuilder<List<ConsultationModel>>(
      stream: ConsultationService().getConsultationsForUser(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('${loc.error}: ${snapshot.error}'));
        }
        
        final consultations = snapshot.data ?? [];

        if (consultations.isEmpty) {
                  return _EmptyStateCard(
                    icon: PhosphorIconsRegular.calendarBlank,
                    title: loc.noScheduledConsultations,
                    message: 'Scheduled consultations will appear here.',
          );
        }

                return CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          AppSpacing.md,
                          AppSpacing.md,
                          AppSpacing.sm,
                        ),
                        child: _SummaryStrip(
                          title: loc.consultations,
                          value: consultations.length.toString(),
                          caption: 'Scheduled consultations',
                          icon: PhosphorIconsRegular.calendarBlank,
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        0,
                        AppSpacing.md,
                        AppSpacing.md,
                      ),
                      sliver: SliverList.separated(
                        itemCount: consultations.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: AppSpacing.md),
                        itemBuilder: (context, index) {
                          final consultation = consultations[index];
                          return _ConsultationCard(
                            consultation: consultation,
                            currentUserId: user.uid,
                          );
                        },
                      ),
                    ),
                  ],
        );
      },
    );
  }
}

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
    final loc = AppLocalizations.of(context);
    final typeIcon = consultation.type == 'video'
        ? PhosphorIconsRegular.videoCamera
        : PhosphorIconsRegular.usersThree;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.04),
              border: const Border(bottom: BorderSide(color: AppColors.grey100)),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _getMonthShort(consultation.scheduledAt),
                        style: textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                        ),
                      ),
                      Text(
                        '${consultation.scheduledAt.day}',
                        style: textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        consultation.caseTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleMedium?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _MiniBadge(
                            icon: typeIcon,
                            label: consultation.type == 'video'
                                ? loc.videoCall
                                : loc.inPerson,
                          ),
                          _MiniBadge(
                            icon: consultation.status == 'pending'
                                ? PhosphorIconsRegular.clock
                                : PhosphorIconsRegular.checkCircle,
                            label: _statusLabel(loc, consultation.status),
                            accentColor: _statusColor(consultation.status),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const PhosphorIcon(
                    PhosphorIconsRegular.dotsThreeVertical,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                  onSelected: (value) {
                    _handleConsultationAction(context, value);
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    PopupMenuItem<String>(
                      value: 'details',
                      child: Text(loc.viewDetails),
                    ),
                    if (consultation.status == 'pending' &&
                        consultation.targetId == currentUserId)
                      PopupMenuItem<String>(
                        value: 'respond',
                        child: Text(loc.respond),
                      ),
                    if (ConsultationUtils.canCancel(consultation))
                      PopupMenuItem<String>(
                        value: 'cancel',
                        child: Text(loc.cancel),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoRow(
                  icon: PhosphorIconsRegular.user,
                  label: consultation.targetId == currentUserId
                      ? loc.withLabel(consultation.clientName)
                      : loc.withLabel(consultation.lawyerName ?? loc.unknown),
                ),
                const SizedBox(height: 8),
                _InfoRow(
                  icon: PhosphorIconsRegular.clock,
                  label: loc.timeLabel(
                    '${consultation.scheduledAt.hour.toString().padLeft(2, '0')}:${consultation.scheduledAt.minute.toString().padLeft(2, '0')}',
                  ),
                ),
                if (consultation.caseId.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _InfoRow(
                    icon: PhosphorIconsRegular.hash,
                    label: '${loc.idLabel} ${consultation.caseId.substring(0, 4).toUpperCase()}',
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      context.push('/consultation-details/${consultation.caseId}/${consultation.id}');
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                    ),
                    child: Text(
                      loc.viewDetails,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleConsultationAction(BuildContext context, String action) {
    final loc = AppLocalizations.of(context);
    switch (action) {
      case 'details':
        context.push('/consultation-details/${consultation.caseId}/${consultation.id}');
        break;
      case 'respond':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.goToWorkspaceToRespondToConsultation)),
        );
        break;
      case 'cancel':
        _showCancelDialog(context);
        break;
    }
  }

  void _showCancelDialog(BuildContext context) {
    final loc = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.cancelConsultation),
        content: Text(loc.areYouSureWantToCancelConsultation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.no),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _cancelConsultation(context);
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: Text(loc.cancelConsultation),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelConsultation(BuildContext context) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final loc = AppLocalizations.of(context);
      await ConsultationService().lawyerDirectCancellation(
        consultation,
        user?.uid ?? 'unknown',
        user?.displayName ?? 'Lawyer',
        loc.cancelledByLawyer,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.consultationCancelled),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        final loc = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${loc.error}: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  String _getMonthShort(DateTime date) {
    const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    return months[date.month - 1];
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return AppColors.success;
      case 'pending':
        return const Color(0xFFFFA726);
      case 'rejected':
      case 'cancelled':
        return AppColors.error;
      case 'completed':
        return AppColors.textSecondary;
      default:
        return AppColors.textSecondary;
    }
  }

  String _statusLabel(AppLocalizations loc, String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return loc.acceptedStatus;
      case 'pending':
        return loc.pendingStatus;
      case 'rejected':
        return loc.rejectedStatus;
      case 'cancelled':
        return loc.cancelledStatus;
      case 'completed':
        return loc.completedStatus;
      case 'no_show':
        return loc.noShowStatus;
      default:
        return status;
    }
  }
}

class _SummaryStrip extends StatelessWidget {
  final String title;
  final String value;
  final String caption;
  final IconData icon;

  const _SummaryStrip({
    required this.title,
    required this.value,
    required this.caption,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.grey100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.textLight,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _EmptyStateCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.grey100),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.primary, size: 28),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.grey100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: AppColors.textLight),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
          ),
        ),
      ],
    );
  }
}

class _MiniBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? accentColor;

  const _MiniBadge({
    required this.icon,
    required this.label,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? AppColors.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _ConsultationStatusChip extends StatelessWidget {
  final String status;

  const _ConsultationStatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);

    Color backgroundColor;
    Color textColor;
    String label;

    switch (status.toLowerCase()) {
      case 'accepted':
        backgroundColor = AppColors.success.withValues(alpha: 0.1);
        textColor = AppColors.success;
        label = loc.acceptedStatus;
        break;
      case 'pending':
        backgroundColor = const Color(0xFFFFA726).withValues(alpha: 0.1);
        textColor = const Color(0xFFFFA726);
        label = loc.pendingStatus;
        break;
      case 'rejected':
      case 'cancelled':
        backgroundColor = AppColors.error.withValues(alpha: 0.1);
        textColor = AppColors.error;
        label = status == 'rejected' ? loc.rejectedStatus : loc.cancelledStatus;
        break;
      case 'completed':
        backgroundColor = AppColors.textLight.withValues(alpha: 0.1);
        textColor = AppColors.textSecondary;
        label = loc.completedStatus;
        break;
      case 'no_show':
        backgroundColor = AppColors.error.withValues(alpha: 0.1);
        textColor = AppColors.error;
        label = loc.noShowStatus;
        break;
      default:
        backgroundColor = AppColors.textLight.withValues(alpha: 0.1);
        textColor = AppColors.textSecondary;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}
