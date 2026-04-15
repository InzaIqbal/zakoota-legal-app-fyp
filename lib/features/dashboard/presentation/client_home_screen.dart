import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/auth_service.dart';
import '../../cases/models/case_model.dart';
import '../../cases/services/case_service.dart';
import '../models/recent_update_model.dart';
import '../services/recent_update_service.dart';
import '../../notifications/services/notification_service.dart';
import '../../events/models/event_model.dart';
import '../../events/services/event_service.dart';

class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  final NotificationService _notificationService = NotificationService();

  Future<void> _onRefresh() async {
    // Simulate data refresh
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dashboard refreshed'),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _buildAppBar(context),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: AppColors.secondary,
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 20),
          children: [
            _buildPriorityEventStream(),
            const SizedBox(height: 28),
            _buildLegalServicesGrid(context),
            const SizedBox(height: 28),
            _buildActiveCasesStream(),
            const SizedBox(height: 28),
            _buildRecentUpdatesStream(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: Colors.grey.shade200, height: 1),
      ),
      leadingWidth: 64,
      leading: Padding(
        padding: const EdgeInsets.only(left: 16.0, top: 8.0, bottom: 8.0),
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>?>(
          stream: AuthService().getUserStream(),
          builder: (context, snapshot) {
            final userData = snapshot.data?.data();
            final photoUrl = userData?['photoUrl'] as String? ??
                'https://api.dicebear.com/7.x/avataaars/png?seed=ZakootaUser';
            return CircleAvatar(
              backgroundImage: NetworkImage(photoUrl),
              backgroundColor: AppColors.grey200,
            );
          },
        ),
      ),
      title: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>?>(
        stream: AuthService().getUserStream(),
        builder: (context, snapshot) {
          final userData = snapshot.data?.data();
          final displayName = userData?['fullName'] as String? ?? 'User';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back,',
                style: textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                  fontSize: 11,
                ),
              ),
              Text(
                displayName,
                style: textTheme.titleMedium?.copyWith(
                  color: Colors.black87,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ],
          );
        },
      ),
      actions: [
        GestureDetector(
          onTap: () {
            context.push('/wallet');
          },
          child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>?>(
            stream: AuthService().getUserStream(),
            builder: (context, snapshot) {
              final userData = snapshot.data?.data();
              final walletBalance =
                  (userData?['walletBalance'] as num?)?.toInt() ?? 0;

              return Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    PhosphorIcon(
                      PhosphorIconsRegular.wallet,
                      color: colorScheme.primary,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'PKR $walletBalance',
                      style: textTheme.labelMedium?.copyWith(
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        StreamBuilder<DocumentSnapshot<Map<String, dynamic>>?>(
          stream: AuthService().getUserStream(),
          builder: (context, userSnapshot) {
            final userId = userSnapshot.data?.id;
            if (userId == null) return const SizedBox.shrink();

            return StreamBuilder<int>(
              stream: _notificationService.streamUnreadCount(userId),
              builder: (context, unreadSnapshot) {
                final unreadCount = unreadSnapshot.data ?? 0;
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      icon: PhosphorIcon(
                        PhosphorIconsRegular.bell,
                        color: Colors.black87,
                      ),
                      onPressed: () => context.push('/notifications'),
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            unreadCount > 99 ? '99+' : unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            );
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildPriorityEventStream() {
    final userId = AuthService().currentUser?.uid;
    if (userId == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            "Today's Agenda",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 12),
        StreamBuilder<EventModel?>(
          stream: EventService().getNextUpcomingEvent(userId),
          builder: (context, eventSnapshot) {
            if (eventSnapshot.hasError) {
              return _buildPriorityEventCard(null); // Fallback if no index or offline
            }
            if (eventSnapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  height: 100, 
                  child: Center(child: CircularProgressIndicator())
                ),
              );
            }
            final event = eventSnapshot.data;
            return _buildPriorityEventCard(event);
          },
        ),
      ],
    );
  }

  Widget _buildPriorityEventCard(EventModel? event) {
    if (event == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          color: Colors.white,
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: AppColors.success.withOpacity(0.1),
              radius: 24,
              child: PhosphorIcon(PhosphorIconsRegular.coffee,
                  color: AppColors.success),
            ),
            title: const Text('All caught up!',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                  'You have no urgent events or hearings today. Enjoy your day.',
                  style:
                      TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            ),
          ),
        ),
      );
    }

    final dateFormat = DateFormat('MMM d, h:mm a');
    final formattedDate = dateFormat.format(event.scheduledAt);
    final eventKind = event.type == 'consultation'
      ? 'Consultation'
      : event.type == 'hearing'
        ? 'Hearing'
        : 'Workspace Event';
    final eventLocation = (event.location != null && event.location!.isNotEmpty)
      ? event.location!
      : event.subtitle;
    final caseId = _resolveEventCaseId(event);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 0,
        color: AppColors.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      eventKind,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12),
                    ),
                  ),
                  PhosphorIcon(
                    event.type == 'consultation'
                        ? PhosphorIconsRegular.users
                        : PhosphorIconsRegular.gavel,
                    color: Colors.white70,
                    size: 24,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(event.title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(eventLocation,
                  style: const TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 2),
              Text(
                formattedDate,
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: caseId == null
                      ? null
                      : () => context.push(
                            '/case-workspace?caseId=$caseId&isClient=true&tab=events',
                          ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('View Details',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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

  Widget _buildLegalServicesGrid(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Legal Services',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ClientHomeData.services
                .map((service) => _buildServiceItem(context, service))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildServiceItem(BuildContext context, ServiceData service) {
    return GestureDetector(
      onTap: () => context.push(service.route),
      child: SizedBox(
        width: 76,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: PhosphorIcon(service.icon,
                  color: AppColors.primary, size: 28),
            ),
            Text(
              service.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveCasesStream() {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>?>(
      stream: AuthService().getUserStream(),
      builder: (context, userSnapshot) {
        final userId = userSnapshot.data?.id;
        if (userId == null) return const SizedBox.shrink();

        return StreamBuilder<List<CaseModel>>(
          stream: CaseService().getCasesForClient(userId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                  height: 160,
                  child: Center(child: CircularProgressIndicator()));
            }
            if (snapshot.hasError) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Error loading cases'),
              );
            }

            final activeCases = (snapshot.data ?? [])
                .where((c) => c.status == 'open' || c.status == 'active')
                .toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Active Cases',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.go('/client-cases'),
                        child: Text(
                          'View All',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (activeCases.isEmpty)
                  _buildEmptyActiveCasesState(context)
                else
                  SizedBox(
                    height: 180,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.only(left: 16, right: 4),
                      itemCount: activeCases.length,
                      itemBuilder: (context, index) {
                        return _buildActiveCaseCard(context, activeCases[index]);
                      },
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyActiveCasesState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primary.withOpacity(0.1),
                radius: 24,
                child: PhosphorIcon(PhosphorIconsRegular.briefcase,
                    color: AppColors.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('No active cases',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text('Post a new case to get started.',
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 13)),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => context.push('/post-case'),
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  foregroundColor: AppColors.primary,
                ),
                child: const Text('Post Case'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return AppColors.info;
      case 'active':
        return AppColors.warning;
      case 'closed':
        return AppColors.success;
      case 'pending':
        return AppColors.secondary;
      default:
        return AppColors.textSecondary;
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return 'Open';
      case 'active':
        return 'Active';
      case 'closed':
        return 'Closed';
      case 'pending':
        return 'Pending';
      default:
        return status;
    }
  }

  Widget _buildActiveCaseCard(BuildContext context, CaseModel caseModel) {
    final statusColor = _getStatusColor(caseModel.status);

    return InkWell(
      onTap: () => context.push('/case-ad-details', extra: caseModel),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 260,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '#${caseModel.caseId.substring(0, (caseModel.caseId.length > 8 ? 8 : caseModel.caseId.length)).toUpperCase()}',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _getStatusLabel(caseModel.status).toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                caseModel.title.isNotEmpty ? caseModel.title : 'Untitled Case',
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (caseModel.budgetMin > 0)
                    Text(
                      'Rs. ${caseModel.budgetMin.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  const Text(
                    'View Details',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentUpdatesStream() {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>?>(
      stream: AuthService().getUserStream(),
      builder: (context, userSnapshot) {
        final userId = userSnapshot.data?.id;
        if (userId == null) return const SizedBox.shrink();

        return StreamBuilder<List<RecentUpdate>>(
          stream: RecentUpdateService().streamRecentUpdates(userId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator()));
            }
            if (snapshot.hasError) return const SizedBox.shrink();

            final updates = snapshot.data ?? [];

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Recent Updates',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (updates.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Center(
                      child: Text(
                        'No recent updates yet',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    ),
                  )
                else
                  Card(
                    elevation: 0,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    color: Colors.white,
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: updates.length,
                      separatorBuilder: (context, index) =>
                          Divider(height: 1, color: Colors.grey.shade200),
                      itemBuilder: (context, index) {
                        final update = updates[index];
                        return ListTile(
                          onTap: () => _handleUpdateTap(context, update),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          leading: CircleAvatar(
                            backgroundColor:
                                _getUpdateColor(update.colorType).withOpacity(0.1),
                            child: PhosphorIcon(
                              _getUpdateIcon(update.iconType),
                              color: _getUpdateColor(update.colorType),
                              size: 20,
                            ),
                          ),
                          title: Text(
                            update.title,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87),
                          ),
                          subtitle: Text(
                            update.message,
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey.shade600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Text(
                            _formatTime(update.timestamp),
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey.shade500),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  void _handleUpdateTap(BuildContext context, RecentUpdate update) {
    if (update.relatedId != null) {
      if (update.type == UpdateType.casePosted ||
          update.type == UpdateType.proposalReceived ||
          update.type == UpdateType.documentUploaded) {
        context.push('/case-details/${update.relatedId}');
      } else if (update.type == UpdateType.messageReceived) {
        context.push('/chat/${update.relatedId}');
      } else if (update.type == UpdateType.consultationScheduled) {
        context.push('/consultation-details/${update.relatedId}');
      }
    }
  }

  PhosphorIconData _getUpdateIcon(String type) {
    switch (type) {
      case 'briefcase': return PhosphorIconsRegular.briefcase;
      case 'fileText': return PhosphorIconsRegular.fileText;
      case 'check': return PhosphorIconsRegular.check;
      case 'x': return PhosphorIconsRegular.x;
      case 'creditCard': return PhosphorIconsRegular.creditCard;
      case 'prohibit': return PhosphorIconsRegular.prohibit;
      case 'checkCircle': return PhosphorIconsRegular.checkCircle;
      case 'calendar': return PhosphorIconsRegular.calendar;
      case 'upload': return PhosphorIconsRegular.upload;
      case 'checkDouble': return PhosphorIconsRegular.checks;
      case 'chatCircle': return PhosphorIconsRegular.chatCircle;
      default: return PhosphorIconsRegular.info;
    }
  }

  Color _getUpdateColor(String type) {
    switch (type) {
      case 'success': return AppColors.success;
      case 'error': return AppColors.error;
      case 'secondary': return Theme.of(context).colorScheme.secondary;
      case 'info': return AppColors.info;
      default: return Colors.grey.shade600;
    }
  }

  String _formatTime(DateTime timestamp) {
    final difference = DateTime.now().difference(timestamp);
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return '${timestamp.month}/${timestamp.day}';
  }
}

// ============================================================================
// MOCK DATA MODELS
// ============================================================================

class ClientHomeData {
  static final PriorityActionData priorityAction = PriorityActionData(
    title: 'Hearing Tomorrow!',
    subtitle: 'Case #204 vs State',
  );

  static final List<ServiceData> services = [
    ServiceData(
      name: 'Find Lawyers',
      icon: PhosphorIconsRegular.magnifyingGlass,
      route: '/lawyer-search',
    ),
    ServiceData(
      name: 'Post a Case',
      icon: PhosphorIconsRegular.briefcase,
      route: '/create-case',
    ),
    ServiceData(
      name: 'Document Review',
      icon: PhosphorIconsRegular.fileText,
      route: '/document-review',
    ),
    ServiceData(
      name: 'Legal Articles',
      icon: PhosphorIconsRegular.books,
      route: '/legal-articles',
    ),
  ];

  static final List<RecentActivityData> recentActivities = [
    RecentActivityData(
      icon: PhosphorIconsRegular.check,
      iconColor: AppColors.success,
      title: 'Document Verified',
      subtitle: 'Your CNIC was approved.',
      time: '2m ago',
    ),
    RecentActivityData(
      icon: PhosphorIconsRegular.chatCircle,
      iconColor: AppColors.info,
      title: 'New Message',
      subtitle: 'Adv. Sarah sent you a message.',
      time: '1h ago',
    ),
    RecentActivityData(
      icon: PhosphorIconsRegular.calendar,
      iconColor: AppColors.warning,
      title: 'Hearing Scheduled',
      subtitle: 'Case #204 - Feb 8, 2026 at 10:00 AM',
      time: '3h ago',
    ),
    RecentActivityData(
      icon: PhosphorIconsRegular.fileText,
      iconColor: AppColors.secondary,
      title: 'Document Uploaded',
      subtitle: 'Evidence.pdf added to Case #CHD-2023',
      time: '5h ago',
    ),
  ];
}

class PriorityActionData {
  final String title;
  final String subtitle;

  PriorityActionData({
    required this.title,
    required this.subtitle,
  });
}

class ServiceData {
  final String name;
  final PhosphorIconData icon;
  final String route;

  ServiceData({
    required this.name,
    required this.icon,
    required this.route,
  });
}

class RecentActivityData {
  final PhosphorIconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String time;

  RecentActivityData({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.time,
  });
}
