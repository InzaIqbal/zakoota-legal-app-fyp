import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';
import 'package:zakoota/l10n/app_localizations.dart';

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

  Future<void> _onRefresh(AppLocalizations loc) async {
    // Simulate data refresh
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.dashboardRefreshed),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F4F8),
      appBar: _buildAppBar(context, loc),
      body: RefreshIndicator(
        onRefresh: () => _onRefresh(loc),
        color: AppColors.secondary,
        child: ListView(
          padding: const EdgeInsets.only(top: 16, bottom: 40),
          children: [
            _buildPriorityEventStream(loc),
            const SizedBox(height: 24),
            _buildLegalServicesGrid(context),
            const SizedBox(height: 24),
            _buildActiveCasesStream(loc),
            const SizedBox(height: 24),
            _buildRecentUpdatesStream(loc),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, AppLocalizations loc) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight + 82),
      child: Container(
        color: AppColors.primary,
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Top bar row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    Flexible(
                      child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>?>(
                        stream: AuthService().getUserStream(),
                        builder: (context, snapshot) {
                          final userData = snapshot.data?.data();
                          final photoUrl = userData?['photoUrl'] as String? ??
                              'https://api.dicebear.com/7.x/avataaars/png?seed=ZakootaUser';
                          final displayName = userData?['fullName'] as String? ?? 'User';
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundImage: NetworkImage(photoUrl),
                                backgroundColor: AppColors.grey700,
                              ),
                              const SizedBox(width: 10),
                              Flexible(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      loc.welcomeBackComma,
                                      style: const TextStyle(
                                        color: Colors.white60,
                                        fontSize: 11,
                                        fontFamily: 'Inter',
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      displayName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        fontFamily: 'Poppins',
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const Spacer(),
                    // Wallet chip
                    StreamBuilder<DocumentSnapshot<Map<String, dynamic>>?>(
                      stream: AuthService().getUserStream(),
                      builder: (context, snapshot) {
                        final walletBalance =
                            (snapshot.data?.data()?['walletBalance'] as num?)?.toInt() ?? 0;
                        return GestureDetector(
                          onTap: () => context.push('/wallet'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: Row(
                              children: [
                                PhosphorIcon(PhosphorIconsRegular.wallet,
                                    color: AppColors.secondary, size: 14),
                                const SizedBox(width: 5),
                                Text(
                                  'PKR $walletBalance',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    // Notification bell
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
                                  icon: PhosphorIcon(PhosphorIconsRegular.bell,
                                      color: Colors.white, size: 22),
                                  onPressed: () => context.push('/notifications'),
                                ),
                                if (unreadCount > 0)
                                  Positioned(
                                    right: 6,
                                    top: 6,
                                    child: Container(
                                      padding: const EdgeInsets.all(3),
                                      decoration: const BoxDecoration(
                                          color: AppColors.error,
                                          shape: BoxShape.circle),
                                      child: Text(
                                        unreadCount > 99
                                            ? '99+'
                                            : unreadCount.toString(),
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 8,
                                            fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
              // Bottom stats strip
              Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white12),
                ),
                child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>?>(
                  stream: AuthService().getUserStream(),
                  builder: (context, snapshot) {
                    final userId = snapshot.data?.id ?? '';
                    return StreamBuilder<List<CaseModel>>(
                      stream: userId.isEmpty
                          ? const Stream.empty()
                          : CaseService().getCasesForClient(userId),
                      builder: (context, caseSnap) {
                        final cases = caseSnap.data ?? [];
                        final active = cases
                            .where((c) => c.status == 'active')
                            .length;
                        final pending = cases
                            .where((c) => c.status == 'open')
                            .length;
                        final total = cases.length;
                        return Row(
                          children: [
                            _buildStatItem(active.toString(), 'Active Cases',
                                PhosphorIconsRegular.briefcase),
                            _buildStatDivider(),
                            _buildStatItem(total.toString(), 'Total Cases',
                                PhosphorIconsRegular.folder),
                            _buildStatDivider(),
                            _buildStatItem(pending.toString(), 'Pending Bids',
                                PhosphorIconsRegular.scales),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label, PhosphorIconData icon) {
    return Expanded(
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PhosphorIcon(icon, color: AppColors.secondary, size: 13),
            const SizedBox(width: 5),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins',
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 9,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(
        width: 1, height: 28, color: Colors.white12);
  }

  Widget _buildPriorityEventStream(AppLocalizations loc) {
    final userId = AuthService().currentUser?.uid;
    if (userId == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            loc.todaysAgenda,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              fontFamily: 'Poppins',
            ),
          ),
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<EventModel>>(
          stream: EventService().streamUserEvents(userId),
          builder: (context, eventsSnap) {
            if (eventsSnap.hasError) return _buildPriorityEventCard(null, loc);
            if (eventsSnap.connectionState == ConnectionState.waiting) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildPriorityEventCard(null, loc),
              );
            }

            final events = eventsSnap.data ?? [];
            if (events.isEmpty) return _buildPriorityEventCard(null, loc);

            final now = DateTime.now();
            final startOfToday = DateTime(now.year, now.month, now.day);
            final endOfToday = startOfToday.add(const Duration(days: 1));

            // Group events strictly by workspace caseId (only events tied to a case workspace)
            final Map<String, List<EventModel>> eventsByCase = {};
            for (var e in events) {
              if (e.caseId != null && e.caseId!.isNotEmpty) {
                eventsByCase.putIfAbsent(e.caseId!, () => []).add(e);
              }
            }

            // If no case-linked events exist, fall back to grouping by referenceId
            if (eventsByCase.isEmpty) {
              for (var e in events) {
                final key = e.referenceId.isNotEmpty ? e.referenceId : 'no_case_${e.id}';
                eventsByCase.putIfAbsent(key, () => []).add(e);
              }
            }

            // For each case, pick nearest today's event; if none, pick nearest future event.
            final List<EventModel> nearestPerCase = [];
            for (var entry in eventsByCase.entries) {
              final list = entry.value..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
              final todays = list.where((ev) => !ev.scheduledAt.isBefore(startOfToday) && ev.scheduledAt.isBefore(endOfToday)).toList();
              if (todays.isNotEmpty) {
                nearestPerCase.add(todays.first);
              } else {
                final future = list.where((ev) => !ev.scheduledAt.isBefore(now)).toList();
                if (future.isNotEmpty) nearestPerCase.add(future.first);
              }
            }

            if (nearestPerCase.isEmpty) return _buildPriorityEventCard(null, loc);

            nearestPerCase.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

            // Render one card per case (nearest event for that case)
            return Column(
              children: nearestPerCase
                  .map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildPriorityEventCard(e, loc),
                      ))
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPriorityEventCard(EventModel? event, AppLocalizations loc) {
    if (event == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.grey200),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: PhosphorIcon(PhosphorIconsRegular.coffee,
                    color: AppColors.success, size: 20),
              ),
              const SizedBox(width: 14),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(loc.allCaughtUp,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: AppColors.textPrimary,
                            fontFamily: 'Inter'),
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 3),
                    Text(loc.noUrgentEventsToday,
                        style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontFamily: 'Inter'),
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
    // Defensive logging to help diagnose missing/empty event fields at runtime.
    try {
      // ignore: avoid_print
      print('Rendering event card: id=${event.id} title="${event.title}" scheduledAt=${event.scheduledAt.toIso8601String()} caseId=${event.caseId}');
    } catch (_) {}

    final dateFormat = DateFormat('MMM d, h:mm a');
    String formattedDate;
    try {
      formattedDate = dateFormat.format(event.scheduledAt);
    } catch (_) {
      formattedDate = '';
    }
    final eventKind = event.type == 'consultation'
      ? loc.consultationEvent
      : event.type == 'hearing'
        ? loc.hearingEvent
        : loc.workspaceEvent;
    final eventLocation = (event.location != null && event.location!.isNotEmpty)
      ? event.location!
      : event.subtitle;
    final caseId = _resolveEventCaseId(event);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.grey200),
          ),
          child: Stack(
            children: [
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(width: 4, color: AppColors.secondary),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      eventKind,
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                          fontFamily: 'Inter'),
                    ),
                  ),
                  PhosphorIcon(
                    event.type == 'consultation'
                        ? PhosphorIconsRegular.users
                        : PhosphorIconsRegular.gavel,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                (event.title.trim().isEmpty) ? 'Untitled Event' : event.title,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Poppins'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Row(
                children: [
                  PhosphorIcon(PhosphorIconsRegular.mapPin,
                      color: AppColors.textSecondary, size: 12),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(eventLocation,
                        style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontFamily: 'Inter'),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  PhosphorIcon(PhosphorIconsRegular.clock,
                      color: AppColors.textSecondary, size: 12),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(formattedDate,
                        style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontFamily: 'Inter'),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: caseId == null
                      ? null
                      : () => context.push(
                            '/case-workspace?caseId=$caseId&isClient=true&tab=events',
                          ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    textStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Inter'),
                  ),
                  child: Text(loc.viewDetails),
                ),
              ),
            ],
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
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              fontFamily: 'Poppins',
            ),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: ClientHomeData.services
                .map((service) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: _buildServiceItem(context, service),
                      ),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildServiceItem(BuildContext context, ServiceData service) {
    return GestureDetector(
      onTap: () => context.push(service.route),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.grey200),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.07),
                borderRadius: BorderRadius.circular(8),
              ),
              child: PhosphorIcon(service.icon,
                  color: AppColors.primary, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              service.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontFamily: 'Inter',
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveCasesStream(AppLocalizations loc) {
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
              return Padding(
                padding: const EdgeInsets.all(16),
                child: const Text('Error loading cases'),
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
                      Text(
                        loc.activeCases,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.go('/client-cases'),
                        child: Text(
                          loc.viewAll,
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
                  _buildEmptyActiveCasesState(context, loc)
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

  Widget _buildEmptyActiveCasesState(BuildContext context, AppLocalizations loc) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.grey200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.07),
                borderRadius: BorderRadius.circular(8),
              ),
              child: PhosphorIcon(PhosphorIconsRegular.briefcase,
                  color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(loc.noActiveCases,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: AppColors.textPrimary,
                          fontFamily: 'Inter')),
                  const SizedBox(height: 3),
                  Text(loc.postNewCaseToGetStarted,
                      style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontFamily: 'Inter')),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => context.push('/post-case'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Inter'),
              ),
              child: Text(loc.postACase),
            ),
          ],
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
    final loc = AppLocalizations.of(context);

    return InkWell(
      onTap: () => context.push('/case-ad-details', extra: caseModel),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 240,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.grey200),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '#${caseModel.caseId.substring(0, (caseModel.caseId.length > 8 ? 8 : caseModel.caseId.length)).toUpperCase()}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                      fontFamily: 'Inter',
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _getStatusLabel(caseModel.status).toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 9,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                caseModel.title.isNotEmpty ? caseModel.title : loc.untitledCase,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  fontFamily: 'Poppins',
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Divider(height: 20, color: AppColors.grey200),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (caseModel.budgetMin > 0)
                    Text(
                      'Rs. ${caseModel.budgetMin.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        fontFamily: 'Inter',
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                  Row(
                    children: [
                      Text(
                        loc.viewDetails,
                        style: const TextStyle(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          fontFamily: 'Inter',
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.arrow_forward_ios,
                          size: 10, color: AppColors.secondary),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentUpdatesStream(AppLocalizations loc) {
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    loc.recentUpdates,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (updates.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Center(
                      child: Text(
                        loc.noRecentUpdatesYet,
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    ),
                  )
                else
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.grey200),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: updates.length,
                      separatorBuilder: (context, index) =>
                          Divider(height: 1, color: AppColors.grey100),
                      itemBuilder: (context, index) {
                        final update = updates[index];
                        return ListTile(
                          onTap: () => _handleUpdateTap(context, update),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 4),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _getUpdateColor(update.colorType).withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: PhosphorIcon(
                              _getUpdateIcon(update.iconType),
                              color: _getUpdateColor(update.colorType),
                              size: 18,
                            ),
                          ),
                          title: Text(
                            update.title,
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                                fontFamily: 'Inter'),
                          ),
                          subtitle: Text(
                            update.message,
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                fontFamily: 'Inter'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Text(
                            _formatTime(update.timestamp),
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                                fontFamily: 'Inter'),
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
