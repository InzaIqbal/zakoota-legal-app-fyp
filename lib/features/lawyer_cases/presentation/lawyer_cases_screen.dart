import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
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
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Text(
            'My Case',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
          ),
          actions: [
            IconButton(
              icon: const Icon(PhosphorIconsRegular.magnifyingGlass,
                  color: AppColors.primary),
              onPressed: () {},
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          bottom: const TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.secondary,
            indicatorWeight: 3,
            labelStyle: TextStyle(fontWeight: FontWeight.bold),
            tabs: [
              Tab(text: 'Active Cases'),
              Tab(text: 'Consultations'),
            ],
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
    if (user == null) {
      return const Center(child: Text('Please log in to view cases'));
    }

    return StreamBuilder<List<CaseModel>>(
      stream: LawyerCaseService().getActiveCasesForLawyer(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final cases = snapshot.data ?? [];
        if (cases.isEmpty) {
          return const Center(
            child: Text(
              'No active cases yet.\nApply to jobs to find work!',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: cases.length,
          separatorBuilder: (context, index) =>
              const SizedBox(height: AppSpacing.md),
          itemBuilder: (context, index) {
            final caseItem = cases[index];
            return _LawyerCaseCard(caseItem: caseItem);
          },
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
    return GestureDetector(
      onTap: () {
        context.push('/case-workspace?caseId=${caseItem.caseId}&isClient=false', extra: {
          'caseModel': caseItem,
          'isClient': false,
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.grey100),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    'ID: ${caseItem.caseId.substring(0, 4).toUpperCase()}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textLight,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const Text('|', style: TextStyle(color: AppColors.grey300)),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    caseItem.category,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'ACTIVE',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
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
                    caseItem.title,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 12,
                        backgroundColor: AppColors.grey100,
                        child: Icon(PhosphorIconsRegular.user,
                            size: 14, color: AppColors.primary),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      // We don't have client name easily in CaseModel without fetching.
                      // Can create a future builder or just show "Client View"
                      // For now, static text or fetch if we want to be fancy.
                      const Text(
                        'Client', // Placeholder until fetched or passed
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      const Icon(PhosphorIconsRegular.currencyDollar,
                          size: 18, color: AppColors.secondary),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Budget: ${caseItem.budgetMin.toInt()} - ${caseItem.budgetMax.toInt()}',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Footer (Action Bar)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: OutlinedButton(
                        onPressed: () {
                          context.push('/case-workspace?caseId=${caseItem.caseId}&isClient=false', extra: {
                            'caseModel': caseItem,
                            'isClient': false,
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                        ),
                        child: const Text(
                          'Open Workspace',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
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
    if (user == null) {
      return const Center(child: Text('Please log in'));
    }

    return StreamBuilder<List<ConsultationModel>>(
      stream: ConsultationService().getConsultationsForUser(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        
        final consultations = snapshot.data ?? [];

        if (consultations.isEmpty) {
          return const Center(
            child: Text(
              'No scheduled consultations',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: consultations.length,
          separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (context, index) {
            final consultation = consultations[index];
            return _ConsultationCard(consultation: consultation, currentUserId: user.uid);
          },
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
    final typeIcon = consultation.type == 'video'
        ? PhosphorIconsRegular.videoCamera
        : PhosphorIconsRegular.usersThree;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date Box
          Container(
            width: 60,
            height: 70,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _getMonthShort(consultation.scheduledAt),
                  style: textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${consultation.scheduledAt.day}',
                  style: textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
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
                Text(
                  consultation.caseTitle,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    PhosphorIcon(
                      typeIcon,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      consultation.type == 'video' ? 'Video Call' : 'In-Person',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Show client name for lawyers
                Text(
                  'With: ${consultation.clientName}',
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Time: ${consultation.scheduledAt.hour.toString().padLeft(2, '0')}:${consultation.scheduledAt.minute.toString().padLeft(2, '0')}',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
          ),

          // Status & Menu
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _ConsultationStatusChip(status: consultation.status),
              const SizedBox(height: 4),
              PopupMenuButton<String>(
                child: PhosphorIcon(
                  PhosphorIconsRegular.dotsThreeVertical,
                  size: 20,
                ),
                onSelected: (value) {
                  _handleConsultationAction(context, value);
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'details',
                    child: Text('View Details'),
                  ),
                  if (consultation.status == 'pending' &&
                      consultation.targetId == currentUserId)
                    const PopupMenuItem<String>(
                      value: 'respond',
                      child: Text('Respond'),
                    ),
                  if (ConsultationUtils.canCancel(consultation))
                    const PopupMenuItem<String>(
                      value: 'cancel',
                      child: Text('Cancel'),
                    ),
                ],
              ),
            ],
          ),
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
          const SnackBar(
              content: Text('Go to workspace to respond to consultation')),
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
        content: const Text(
            'Are you sure you want to cancel this consultation?'),
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
      await ConsultationService().lawyerDirectCancellation(
        consultation,
        user?.uid ?? 'unknown',
        user?.displayName ?? 'Lawyer',
        'Cancelled by lawyer',
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

  String _getMonthShort(DateTime date) {
    const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    return months[date.month - 1];
  }
}

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
        backgroundColor = const Color(0xFFFFA726).withValues(alpha: 0.1);
        textColor = const Color(0xFFFFA726);
        label = 'Pending';
        break;
      case 'rejected':
      case 'cancelled':
        backgroundColor = AppColors.error.withValues(alpha: 0.1);
        textColor = AppColors.error;
        label = status == 'rejected' ? 'Rejected' : 'Cancelled';
        break;
      case 'completed':
        backgroundColor = AppColors.textLight.withValues(alpha: 0.1);
        textColor = AppColors.textSecondary;
        label = 'Completed';
        break;
      case 'no_show':
        backgroundColor = AppColors.error.withValues(alpha: 0.1);
        textColor = AppColors.error;
        label = 'No Show';
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
