import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:zakoota/l10n/app_localizations.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/auth_service.dart';
import '../data/lawyer_dashboard_mock_data.dart';
import '../../jobs/data/job_mock_data.dart';
import '../../jobs/presentation/widgets/job_opportunity_card.dart';
import '../../ads/models/lawyer_ad_model.dart';
import '../../ads/services/lawyer_ad_service.dart';
import '../../events/models/event_model.dart';
import '../../events/services/event_service.dart';
import '../../notifications/services/notification_service.dart';
import '../../jobs/models/job_opportunity.dart';
import '../../cases/models/case_model.dart';
import '../../cases/services/case_service.dart';
import 'package:intl/intl.dart';
/// Lawyer Home Screen (Dashboard)
class LawyerHomeScreen extends StatelessWidget {
  const LawyerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final loc = AppLocalizations.of(context);
    final caseService = CaseService();
    final notificationService = NotificationService();
    final lawyerAdService = LawyerAdService();

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>?>(
      stream: AuthService().getUserStream(),
      builder: (context, snapshot) {
        // Default/Loading/Error values
        String fullName = 'Advocate';
        String? photoUrl;
        double walletBalance = 0.0;
        String initials = 'A';

        if (snapshot.hasData &&
            snapshot.data != null &&
            snapshot.data!.exists) {
          final data = snapshot.data!.data();
          if (data != null) {
            fullName = data['fullName'] ?? 'Advocate';
            photoUrl = data['photoUrl'];
            // Handle wallet balance being int or double
            walletBalance = (data['walletBalance'] ?? 0).toDouble();

            if (fullName.isNotEmpty) {
              initials = fullName
                  .trim()
                  .split(' ')
                  .map((e) => e.isNotEmpty ? e[0] : '')
                  .take(2)
                  .join()
                  .toUpperCase();
            }
          }
        } else {
          debugPrint('LawyerDashboard: Snapshot has NO DATA or does not exist');
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                backgroundColor: AppColors.primary,
                expandedHeight: 180,
                elevation: 0,
                leading: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.secondary,
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: photoUrl != null
                        ? Image.network(
                            photoUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Text(
                                  initials,
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primary,
                                ),
                              );
                            },
                          )
                        : Center(
                            child: Text(
                              initials,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                  ),
                ),
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.welcomeBackComma,
                      style: TextStyle(fontSize: 12, color: AppColors.textLight),
                    ),
                    Text(
                      fullName,
                      style: textTheme.titleMedium?.copyWith(
                        color: AppColors.textOnPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                actions: [
                  IconButton(
                    onPressed: () => context.push('/lawyer-availability-settings'),
                    icon: const PhosphorIcon(
                      PhosphorIconsRegular.clock,
                      color: Colors.white,
                    ),
                    tooltip: loc.availabilitySettings,
                  ),
                  Builder(
                    builder: (context) {
                      final currentUser = AuthService().currentUser;
                      if (currentUser == null) {
                        return Container(
                          margin: const EdgeInsets.only(right: 16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            onPressed: () => context.push('/notifications'),
                            icon: PhosphorIcon(
                              PhosphorIconsRegular.bell,
                              color: AppColors.textOnPrimary,
                            ),
                          ),
                        );
                      }

                      return StreamBuilder<int>(
                        stream: notificationService.streamUnreadCount(currentUser.uid),
                        builder: (context, unreadSnapshot) {
                          final unreadCount = unreadSnapshot.data ?? 0;
                          return Container(
                            margin: const EdgeInsets.only(right: 16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                IconButton(
                                  onPressed: () => context.push('/notifications'),
                                  icon: PhosphorIcon(
                                    PhosphorIconsRegular.bell,
                                    color: AppColors.textOnPrimary,
                                  ),
                                ),
                                if (unreadCount > 0)
                                  Positioned(
                                    right: 6,
                                    top: 6,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                      decoration: const BoxDecoration(
                                        color: AppColors.error,
                                        shape: BoxShape.circle,
                                      ),
                                      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                                      child: Text(
                                        unreadCount > 99 ? '99+' : '$unreadCount',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    color: AppColors.primary,
                    child: Stack(
                      children: [
                        SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(AppSpacing.lg,
                                60, AppSpacing.lg, AppSpacing.md),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(AppSpacing.md),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.lg),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.2),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding:
                                            const EdgeInsets.all(AppSpacing.sm),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          PhosphorIconsRegular.wallet,
                                          color: AppColors.secondary,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.md),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            loc.walletBalance,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: Colors.white
                                                      .withOpacity(0.8),
                                                ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'PKR ${walletBalance.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleLarge
                                                ?.copyWith(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 0.5,
                                                ),
                                          ),
                                        ],
                                      ),
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: AppColors.secondary,
                                          borderRadius: BorderRadius.circular(
                                              AppRadius.full),
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  Colors.black.withOpacity(0.2),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            )
                                          ],
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              PhosphorIconsFill.star,
                                              color: AppColors.primary,
                                              size: 14,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '4.9',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelMedium
                                                  ?.copyWith(
                                                    color: AppColors.primary,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Quick Actions
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.quickActions,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _QuickAction(
                            label: loc.postAd,
                            icon: PhosphorIconsRegular.megaphone,
                            color: AppColors.info,
                            onTap: () => context.push('/lawyer-create-ad'),
                          ),
                          _QuickAction(
                            label: loc.withdraw,
                            icon: PhosphorIconsRegular.bank,
                            color: AppColors.success,
                            onTap: () => context.push('/withdraw'),
                          ),
                          _QuickAction(
                            label: loc.calendar,
                            icon: PhosphorIconsRegular.calendar,
                            color: AppColors.warning,
                            onTap: () => context.push('/calendar'),
                          ),
                          _QuickAction(
                            label: loc.analytics,
                            icon: PhosphorIconsRegular.chartLine,
                            color: AppColors.primary,
                            onTap: () => context.push('/lawyer-dashboard/lawyer-analytics'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Active Ads Section
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            loc.myActiveAds,
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          TextButton(
                            onPressed: () => context.push('/lawyer-manage-ads'),
                            child: Text(loc.viewAll),
                          ),
                        ],
                      ),
                    ),
                    StreamBuilder<DocumentSnapshot<Map<String, dynamic>>?>(
                      stream: AuthService().getUserStream(),
                      builder: (context, userSnapshot) {
                        final lawyerId = userSnapshot.data?.id;
                        if (lawyerId == null) {
                          return const Padding(
                            padding: EdgeInsets.all(AppSpacing.lg),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }

                        return StreamBuilder<List<LawyerAdModel>>(
                          stream: lawyerAdService.streamMyAds(lawyerId),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const SizedBox(
                                height: 140,
                                child: Center(child: CircularProgressIndicator()),
                              );
                            }

                            final ads = snapshot.data ?? [];
                            if (ads.isEmpty) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.lg,
                                  vertical: AppSpacing.sm,
                                ),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(AppSpacing.md),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(AppRadius.md),
                                    border: Border.all(color: AppColors.grey200),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        loc.noActiveAdsYet,
                                        style: textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        loc.createFirstAdHint,
                                        style: TextStyle(color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }

                            return SizedBox(
                              height: 160,
                              child: ListView.separated(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.lg,
                                ),
                                scrollDirection: Axis.horizontal,
                                itemCount: ads.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: AppSpacing.md),
                                itemBuilder: (context, index) =>
                                    _LawyerAdPerformanceCard(ad: ads[index]),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SliverGap(AppSpacing.lg),

              const SliverGap(AppSpacing.xl),

              // New Job Matches
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'New Job Matches',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          TextButton(
                            onPressed: () => context.go('/lawyer-job-board'),
                            child: Text(loc.explore),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      StreamBuilder<List<CaseModel>>(
                        stream: caseService.getOpenCases(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: Padding(
                              padding: EdgeInsets.all(AppSpacing.lg),
                              child: CircularProgressIndicator(),
                            ));
                          }
                          
                          final jobs = (snapshot.data ?? [])
                            .map((c) => JobOpportunity.fromCaseModel(c))
                            .toList();

                            if (jobs.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                              child: Center(
                                child: Text(loc.noJobMatchesFound,
                                  style: const TextStyle(color: AppColors.textSecondary),
                                ),
                              ),
                            );
                          }

                          return Column(
                            children: jobs.take(10).map((job) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                                child: JobOpportunityCard(job: job),
                              );
                            }).toList(),
                          );
                        },
                      ),
                      const SizedBox(height: AppSpacing.xl),
                    ],
                  ),
                ),
              ),

              const SliverGap(AppSpacing.lg),

              // Agenda Section (Upcoming Events)
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.todaysAgenda,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      StreamBuilder<DocumentSnapshot<Map<String, dynamic>>?>(
                        stream: AuthService().getUserStream(),
                        builder: (context, userSnapshot) {
                          final userId = userSnapshot.data?.id;
                          if (userId == null) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          
                          return StreamBuilder<EventModel?>(
                            stream: EventService().getNextUpcomingEvent(userId),
                            builder: (context, eventSnapshot) {
                              if (eventSnapshot.connectionState == ConnectionState.waiting) {
                                return const Center(child: Padding(
                                  padding: EdgeInsets.all(20.0),
                                  child: CircularProgressIndicator(),
                                ));
                              }
                              
                              final event = eventSnapshot.data;
                              
                              if (event == null) {
                                // Fallback UI
                                return Container(
                                  padding: const EdgeInsets.all(AppSpacing.md),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(AppRadius.lg),
                                    border: Border.all(color: AppColors.grey200),
                                    boxShadow: [
                                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                                    ],
                                  ),
                                  child: Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                        children: [
                                          Text(loc.allCaughtUp, style: const TextStyle(fontWeight: FontWeight.bold)),
                                          const SizedBox(height: 6),
                                          Text(loc.noUrgentEventsToday, style: const TextStyle(color: AppColors.textSecondary)),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }
                              
                              final dateFormat = DateFormat('MMM d, h:mm a');
                                final eventKind = event.type == 'consultation'
                                  ? 'Consultation'
                                  : event.type == 'hearing'
                                    ? 'Hearing'
                                    : 'Workspace Event';
                                final eventLocation = (event.location != null && event.location!.isNotEmpty)
                                  ? event.location!
                                  : event.subtitle;
                                final caseId = _resolveEventCaseId(event);
                              
                              return Container(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(AppRadius.lg),
                                  border: Border.all(color: AppColors.grey200),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: AppColors.secondary.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Icon(
                                            event.type == 'consultation'
                                                ? PhosphorIconsRegular.users
                                                : PhosphorIconsRegular.gavel,
                                            color: AppColors.secondary,
                                          ),
                                        ),
                                        const SizedBox(width: AppSpacing.md),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                event.title,
                                                style: textTheme.titleSmall
                                                    ?.copyWith(fontWeight: FontWeight.bold),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                eventLocation,
                                                style: textTheme.bodySmall?.copyWith(
                                                    color: AppColors.textSecondary),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                dateFormat.format(event.scheduledAt),
                                                style: textTheme.bodySmall?.copyWith(
                                                    color: AppColors.textLight),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            eventKind,
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton(
                                        onPressed: caseId == null
                                            ? null
                                            : () => context.push(
                                                  '/case-workspace?caseId=$caseId&isClient=false&tab=events',
                                                ),
                                        child: const Text('Open Workspace Event'),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                          );
                        }
                      ),
                    ],
                  ),
                ),
              ),

              const SliverGap(AppSpacing.xl),

              const SliverGap(AppSpacing.xl),

              // (Agenda was moved up from here... wait, no, it was originally up there and Jobs was here.)
              // The replacement chunk 1 covered both the Agenda and Jobs blocks, swapping their physical order!
            ],
          ),
        );
      },
    );
  }
}

String? _resolveEventCaseId(EventModel event) {
  if (event.caseId != null && event.caseId!.isNotEmpty) {
    return event.caseId;
  }

  if (event.referenceId.isNotEmpty && event.type == 'case_event') {
    return event.referenceId;
  }

  final match = RegExp(r'Case #([A-Za-z0-9_-]+)').firstMatch(event.subtitle);
  return match?.group(1);
}

class _QuickAction extends StatelessWidget {
  final String label;
  final PhosphorIconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _QuickAction({
    required this.label,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: PhosphorIcon(
                icon,
                color: color,
                size: 26,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _LawyerAdPerformanceCard extends StatelessWidget {
  final LawyerAdModel ad;

  const _LawyerAdPerformanceCard({required this.ad});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isActive = ad.isActive;

    return Container(
      width: 260,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B), // Dark Navy
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.success.withOpacity(0.2)
                      : AppColors.grey600,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isActive ? 'Active' : 'Paused',
                  style: TextStyle(
                    fontSize: 10,
                    color: isActive ? AppColors.success : Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                icon: Icon(Icons.more_horiz,
                    color: Colors.white.withValues(alpha: 0.5), size: 18),
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      context.push('/lawyer-edit-ad/${ad.id}');
                      break;
                    case 'toggle':
                      // Logic to toggle active status
                      break;
                    case 'delete':
                      // Logic to delete ad
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit Ad')),
                  PopupMenuItem(
                      value: 'toggle',
                      child: Text(ad.isActive ? 'Pause Ad' : 'Resume Ad')),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete Ad', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          Text(
            ad.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: textTheme.titleSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            ad.category,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _StatBadge(
                  icon: Icons.shopping_bag_outlined,
                  value: ad.bookings.toString(),
                  label: 'Bookings'),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatBadge({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.secondary),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
        ),
      ],
    );
  }
}

// Helper for gaps
class SliverGap extends StatelessWidget {
  final double size;
  const SliverGap(this.size, {super.key});
  @override
  Widget build(BuildContext context) =>
      SliverToBoxAdapter(child: SizedBox(height: size));
}
