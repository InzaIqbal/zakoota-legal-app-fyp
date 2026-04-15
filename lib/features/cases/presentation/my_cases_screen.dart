import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Text(
            'My Cases',
            style: textTheme.headlineSmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          bottom: TabBar(
            indicatorColor: AppColors.secondary,
            indicatorWeight: 3,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textLight,
            labelStyle: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            unselectedLabelStyle: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
            tabs: const [
              Tab(text: 'Consultations'),
              Tab(text: 'My Cases'),
            ],
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
    final authService = AuthService();
    final consultationService = ConsultationService();
    final user = authService.currentUser;

    if (user == null) {
      return const Center(child: Text('Please log in to view consultations.'));
    }

    return StreamBuilder<List<ConsultationModel>>(
      stream: consultationService.getConsultationsForUser(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final consultations = snapshot.data ?? [];

        if (consultations.isEmpty) {
          return RefreshIndicator(
            onRefresh: onRefresh,
            color: AppColors.secondary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height - 200,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      PhosphorIcon(
                        PhosphorIconsRegular.calendarX,
                        size: 64,
                        color: AppColors.textLight,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'No consultations yet',
                        style:
                            Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: AppColors.textSecondary,
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
          color: AppColors.secondary,
          child: ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: consultations.length,
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

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: isStandalone 
            ? Border.all(color: AppColors.secondary.withValues(alpha: 0.3), width: 1.5)
            : null,
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
                  _getMonth(consultation.scheduledAt),
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
                Row(
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
                    if (isStandalone) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'DIRECT',
                          style: textTheme.labelSmall?.copyWith(
                            color: AppColors.secondary,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
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
                // determine partner name to show
                Text(
                  'With: ${consultation.requesterId == currentUserId ? consultation.lawyerName : consultation.clientName}',
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
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isStandalone)
                    IconButton(
                      icon: PhosphorIcon(
                        PhosphorIconsRegular.chatCircleDots,
                        size: 20,
                        color: AppColors.secondary,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
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
                      tooltip: 'Go to Chat',
                    ),
                  if (isStandalone) const SizedBox(width: 8),
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
    const months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC'
    ];
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

    switch (status) {
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

/// My Cases Tab
class _MyCasesTab extends StatelessWidget {
  final Future<void> Function() onRefresh;

  const _MyCasesTab({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final caseService = CaseService();
    final user = authService.currentUser;

    if (user == null) {
      return const Center(child: Text('Please log in to view your cases.'));
    }

    return StreamBuilder<List<CaseModel>>(
      stream: caseService.getCasesForClient(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  SelectableText(
                    'Error: ${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
              ),
            ),
          );
        }

        final cases = snapshot.data ?? [];

        return Column(
          children: [
            // Header with Post New Case Button
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              color: AppColors.surface,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${cases.length} Active Cases',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      context.push('/create-case');
                    },
                    icon: PhosphorIcon(
                      PhosphorIconsRegular.plus,
                      size: 20,
                      color: Colors.white,
                    ),
                    label: const Text('Post New Case'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: 12,
                      ),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
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
                      color: AppColors.secondary,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: SizedBox(
                          height: MediaQuery.of(context).size.height - 300,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                PhosphorIcon(
                                  PhosphorIconsRegular.folderOpen,
                                  size: 64,
                                  color: AppColors.textLight,
                                ),
                                const SizedBox(height: AppSpacing.md),
                                Text(
                                  'No active cases',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(
                                        color: AppColors.textSecondary,
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
                      color: AppColors.secondary,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        itemCount: cases.length,
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
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border(
          left: BorderSide(
            color: statusColor,
            width: 4,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Icon and Status
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppRadius.md),
                topRight: Radius.circular(AppRadius.md),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: PhosphorIcon(
                    _getCaseIcon(caseModel.title),
                    size: 24,
                    color: statusColor,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Case #${caseModel.caseId.substring(0, 8)}...',
                        style: textTheme.labelMedium?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        caseModel.title,
                        style: textTheme.titleMedium?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (caseModel.status == 'active')
                        FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance.collection('users').doc(caseModel.acceptedLawyerId).get(),
                          builder: (context, snapshot) {
                            if (snapshot.hasData && snapshot.data!.exists) {
                              final name = snapshot.data!.get('fullName') ?? 'Lawyer';
                              return Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  'Lawyer: $name',
                                  style: textTheme.labelMedium?.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        )
                      else if (!caseModel.isAdVisible)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            'Job Ad Paused',
                            style: textTheme.labelSmall?.copyWith(
                              color: AppColors.textLight,
                              fontWeight: FontWeight.bold,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // Ad Visibility Toggle - Hide if active
                if (caseModel.status != 'active')
                  Transform.scale(
                    scale: 0.8,
                    child: Switch(
                      value: caseModel.isAdVisible,
                      activeThumbColor: Colors.black,
                      activeTrackColor: Colors.grey.withValues(alpha: 0.3),
                      inactiveThumbColor: Colors.white,
                      inactiveTrackColor: Colors.black.withValues(alpha: 0.1),
                      onChanged: (value) async {
                        try {
                          await CaseService()
                              .toggleAdVisibility(caseModel.caseId, value);
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
              ],
            ),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Description
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

                // Metadata Row
                Row(
                  children: [
                    // City
                    Expanded(
                      child: Row(
                        children: [
                          const PhosphorIcon(
                            PhosphorIconsRegular.mapPin,
                            size: 18,
                            color: AppColors.secondary,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              caseModel.city,
                              style: textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Created At
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.grey200,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const PhosphorIcon(
                            PhosphorIconsRegular.calendar,
                            size: 14,
                            color: AppColors.textLight,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(caseModel.createdAt),
                            style: textTheme.labelSmall?.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.md),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          context.push('/case-ad-details', extra: caseModel);
                        },
                        icon: PhosphorIcon(
                          caseModel.status == 'active' ? PhosphorIconsRegular.briefcase : PhosphorIconsRegular.chartLineUp,
                          size: 16,
                        ),
                        label: Text(caseModel.status == 'active' ? 'Open Workspace' : 'Manage Ad'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.grey300),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return const Color(0xFF2196F3);
      case 'active':
        return AppColors.secondary;
      case 'resolved':
      case 'settled':
        return AppColors.success;
      case 'closed':
        return AppColors.textLight;
      default:
        return AppColors.grey300;
    }
  }

  PhosphorIconData _getCaseIcon(String title) {
    if (title.toLowerCase().contains('property') ||
        title.toLowerCase().contains('dispute')) {
      return PhosphorIconsRegular.buildings;
    } else if (title.toLowerCase().contains('contract') ||
        title.toLowerCase().contains('business')) {
      return PhosphorIconsRegular.fileText;
    } else if (title.toLowerCase().contains('family')) {
      return PhosphorIconsRegular.users;
    } else if (title.toLowerCase().contains('criminal')) {
      return PhosphorIconsRegular.warning;
    }
    return PhosphorIconsRegular.scales;
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${date.day} ${months[date.month - 1]}';
  }
}
