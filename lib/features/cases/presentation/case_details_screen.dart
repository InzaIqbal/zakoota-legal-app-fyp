import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../data/case_details_mock_data.dart';

/// Case Details Screen with Tabs (Overview, Timeline, Documents)
class CaseDetailsScreen extends StatefulWidget {
  final String caseId;
  final int initialTabIndex;

  const CaseDetailsScreen({
    super.key,
    required this.caseId,
    this.initialTabIndex = 0,
  });

  @override
  State<CaseDetailsScreen> createState() => _CaseDetailsScreenState();
}

class _CaseDetailsScreenState extends State<CaseDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic> caseData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    _loadCaseData();
  }

  Future<void> _loadCaseData() async {
    final mock = CaseDetailsMockData.getCaseDetails(widget.caseId);
    if (mock.isNotEmpty) {
      if (!mounted) return;
      setState(() {
        caseData = mock;
        _isLoading = false;
      });
      return;
    }

    try {
      final caseDoc = await FirebaseFirestore.instance
          .collection('cases')
          .doc(widget.caseId)
          .get();

      if (!caseDoc.exists) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final data = caseDoc.data() ?? <String, dynamic>{};
      final createdAt = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
      final acceptedLawyerId = data['acceptedLawyerId'] as String?;

      String lawyerName = 'Not assigned yet';
      String lawyerAvatar = 'https://api.dicebear.com/7.x/avataaars/png?seed=Lawyer';

      if (acceptedLawyerId != null && acceptedLawyerId.isNotEmpty) {
        final lawyerDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(acceptedLawyerId)
            .get();
        if (lawyerDoc.exists) {
          final lawyerData = lawyerDoc.data() ?? <String, dynamic>{};
          lawyerName = (lawyerData['fullName'] ?? 'Assigned Lawyer').toString();
          lawyerAvatar = (lawyerData['photoUrl'] ?? lawyerAvatar).toString();
        }
      }

      final attachments = (data['attachments'] as List<dynamic>? ?? []);
      final documents = attachments.map((item) {
        final doc = item as Map<String, dynamic>;
        return {
          'name': (doc['title'] ?? 'Untitled Document').toString(),
          'size': 'Unknown size',
          'uploadedDate': createdAt,
        };
      }).toList();

      final status = (data['status'] ?? 'open').toString();
      final timeline = [
        {
          'title': 'Case Created',
          'description': 'Your case was posted successfully.',
          'date': createdAt,
          'isCompleted': true,
          'isCurrent': false,
        },
        {
          'title': 'Proposal Collection',
          'description': 'Lawyers can submit proposals for your case.',
          'date': null,
          'isCompleted': (data['proposalCount'] ?? 0) > 0,
          'isCurrent': (data['proposalCount'] ?? 0) == 0,
        },
        {
          'title': 'Case Processing',
          'description': 'Case is currently $status.',
          'date': null,
          'isCompleted': status == 'closed',
          'isCurrent': status == 'active' || status == 'open',
        },
      ];

      final mapped = {
        'id': widget.caseId,
        'title': (data['title'] ?? 'Untitled Case').toString(),
        'status': status,
        'filedDate': createdAt,
        'nextHearing': {
          'date': createdAt.add(const Duration(days: 7)),
          'time': '10:00 AM',
          'venue': 'Court to be assigned',
          'room': 'N/A',
        },
        'lawyerAvatar': lawyerAvatar,
        'lawyerName': lawyerName,
        'lawyerId': acceptedLawyerId ?? '',
        'category': (data['category'] ?? 'General').toString(),
        'description': (data['description'] ?? 'No description available').toString(),
        'timeline': timeline,
        'documents': documents,
      };

      if (!mounted) return;
      setState(() {
        caseData = mapped;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (caseData.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          title: const Text('Case Not Found'),
        ),
        body: const Center(
          child: Text('Case details not available'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              pinned: true,
              floating: true,
              expandedHeight: 120,
              leading: IconButton(
                icon: const PhosphorIcon(PhosphorIconsRegular.arrowLeft),
                onPressed: () => context.pop(),
              ),
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  'Case #${caseData['id']}',
                  style: textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                centerTitle: false,
                titlePadding: const EdgeInsets.only(
                  left: 56,
                  bottom: 56,
                ),
              ),
              bottom: TabBar(
                controller: _tabController,
                indicatorColor: AppColors.secondary,
                indicatorWeight: 3,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white.withValues(alpha: 0.6),
                labelStyle: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                tabs: const [
                  Tab(text: 'Overview'),
                  Tab(text: 'Timeline'),
                  Tab(text: 'Documents'),
                ],
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildOverviewTab(),
            _buildTimelineTab(),
            _buildDocumentsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    final textTheme = Theme.of(context).textTheme;
    final nextHearing = caseData['nextHearing'] as Map<String, dynamic>;
    final hearingDate = nextHearing['date'] as DateTime;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  caseData['title'],
                  style: textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text(
                    'Status: ${caseData['status']}',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Filed on ${DateFormat('MMM dd, yyyy').format(caseData['filedDate'])}',
                  style: textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Next Hearing Widget
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border(
                left: BorderSide(
                  color: AppColors.error,
                  width: 4,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const PhosphorIcon(
                        PhosphorIconsFill.calendarCheck,
                        color: AppColors.error,
                        size: 24,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Upcoming Hearing',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      const PhosphorIcon(
                        PhosphorIconsRegular.clock,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${_formatHearingDate(hearingDate)}, ${nextHearing['time']}',
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const PhosphorIcon(
                        PhosphorIconsRegular.mapPin,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${nextHearing['venue']}, ${nextHearing['room']}',
                        style: textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Add to Calendar - Coming soon'),
                          backgroundColor: AppColors.secondary,
                        ),
                      );
                    },
                    icon: const PhosphorIcon(
                      PhosphorIconsRegular.calendarPlus,
                      size: 18,
                    ),
                    label: const Text('Add to Calendar'),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Assigned Lawyer
          Text(
            'Assigned Lawyer',
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.grey300),
            ),
            child: ListTile(
              leading: CircleAvatar(
                radius: 24,
                backgroundImage: NetworkImage(caseData['lawyerAvatar']),
              ),
              title: Text(
                caseData['lawyerName'],
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: Text(
                caseData['category'],
                style: textTheme.bodySmall,
              ),
              trailing: OutlinedButton.icon(
                onPressed: () {
                  final lawyerId = (caseData['lawyerId'] ?? '').toString();
                  if (lawyerId.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('No lawyer assigned yet'),
                        backgroundColor: AppColors.warning,
                      ),
                    );
                    return;
                  }

                  context.push(
                    '/chat/$lawyerId',
                    extra: {
                      'lawyerName': caseData['lawyerName'],
                      'lawyerId': lawyerId,
                      'isOnline': true,
                      'lawyerAvatar': caseData['lawyerAvatar'],
                    },
                  );
                },
                icon: const PhosphorIcon(
                  PhosphorIconsRegular.chatCircleText,
                  size: 16,
                ),
                label: const Text('Message'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Case Description
          Text(
            'Case Description',
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.grey300),
            ),
            child: Text(
              caseData['description'],
              style: textTheme.bodyMedium?.copyWith(
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineTab() {
    final timeline = caseData['timeline'] as List;
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'The Legal Journey',
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          ...List.generate(timeline.length, (index) {
            final step = timeline[index];
            final isLast = index == timeline.length - 1;

            return _TimelineStep(
              title: step['title'],
              description: step['description'],
              date: step['date'],
              isCompleted: step['isCompleted'],
              isCurrent: step['isCurrent'] ?? false,
              isLast: isLast,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDocumentsTab() {
    final documents = caseData['documents'] as List;
    final textTheme = Theme.of(context).textTheme;

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: documents.length,
      itemBuilder: (context, index) {
        final doc = documents[index];
        return Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.grey300),
          ),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: const PhosphorIcon(
                PhosphorIconsFill.filePdf,
                color: AppColors.error,
                size: 24,
              ),
            ),
            title: Text(
              doc['name'],
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              '${doc['size']} • Uploaded ${DateFormat('MMM dd, yyyy').format(doc['uploadedDate'])}',
              style: textTheme.bodySmall,
            ),
            trailing: IconButton(
              icon: const PhosphorIcon(
                PhosphorIconsRegular.downloadSimple,
                color: AppColors.primary,
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Downloading ${doc['name']}...'),
                    backgroundColor: AppColors.secondary,
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  String _formatHearingDate(DateTime date) {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == tomorrow) {
      return 'Tomorrow';
    } else {
      return DateFormat('MMM dd, yyyy').format(date);
    }
  }
}

/// Timeline Step Widget
class _TimelineStep extends StatelessWidget {
  final String title;
  final String description;
  final DateTime? date;
  final bool isCompleted;
  final bool isCurrent;
  final bool isLast;

  const _TimelineStep({
    required this.title,
    required this.description,
    this.date,
    required this.isCompleted,
    required this.isCurrent,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline Indicator
          Column(
            children: [
              // Dot
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? AppColors.success
                      : isCurrent
                          ? AppColors.secondary
                          : AppColors.grey300,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isCurrent ? AppColors.primary : Colors.transparent,
                    width: 3,
                  ),
                ),
                child: Center(
                  child: isCompleted
                      ? const PhosphorIcon(
                          PhosphorIconsFill.check,
                          size: 16,
                          color: Colors.white,
                        )
                      : isCurrent
                          ? Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            )
                          : null,
                ),
              ),
              // Line
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: isCompleted ? AppColors.success : AppColors.grey300,
                  ),
                ),
            ],
          ),

          const SizedBox(width: AppSpacing.md),

          // Content
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.lg),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: isCurrent
                    ? AppColors.secondary.withValues(alpha: 0.1)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: isCurrent ? AppColors.secondary : AppColors.grey300,
                  width: isCurrent ? 2 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isCurrent
                                ? AppColors.primary
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (isCurrent)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.secondary,
                            borderRadius: BorderRadius.circular(AppRadius.full),
                          ),
                          child: Text(
                            'Current',
                            style: textTheme.bodySmall?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (date != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const PhosphorIcon(
                          PhosphorIconsRegular.calendar,
                          size: 14,
                          color: AppColors.textLight,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('MMM dd, yyyy').format(date!),
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.textLight,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
