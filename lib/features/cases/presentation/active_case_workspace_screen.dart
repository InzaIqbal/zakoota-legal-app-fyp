import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/case_model.dart';
import '../models/consultation_model.dart';
import '../services/consultation_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../events/models/event_model.dart';
import '../../events/services/event_service.dart';
import '../../notifications/services/notification_service.dart';
import '../../notifications/models/notification_model.dart';
import '../../dashboard/services/recent_update_service.dart';
import '../../dashboard/models/recent_update_model.dart';
import '../models/file_model.dart';
import '../models/case_milestone_model.dart';
import '../models/case_invoice_model.dart';
import '../services/file_service.dart';
import '../services/case_service.dart';
import '../services/case_milestone_service.dart';
import '../services/case_invoice_service.dart';
import '../../lawyers/services/lawyer_service.dart';
import '../../lawyers/data/lawyer_mock_data.dart';
import '../../wallet/services/wallet_service.dart';
import '../../../core/widgets/user_avatar.dart';

class ActiveCaseWorkspaceScreen extends StatefulWidget {
  final CaseModel caseModel;
  final bool isClient; // true if current user is the client
  final int initialTabIndex;

  const ActiveCaseWorkspaceScreen({
    super.key,
    required this.caseModel,
    required this.isClient,
    this.initialTabIndex = 0,
  });

  @override
  State<ActiveCaseWorkspaceScreen> createState() =>
      _ActiveCaseWorkspaceScreenState();
}

class _ActiveCaseWorkspaceScreenState extends State<ActiveCaseWorkspaceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final EventService _eventService = EventService();
  final CaseMilestoneService _milestoneService = CaseMilestoneService();
  final CaseInvoiceService _invoiceService = CaseInvoiceService();
  final WalletService _walletService = WalletService();
  final NotificationService _notificationService = NotificationService();
  final RecentUpdateService _recentUpdateService = RecentUpdateService();
  Map<String, dynamic>? _partnerData;
  Map<String, dynamic>? _currentUserData;
  LawyerProfile? _lawyerProfile;
  bool _isLoadingData = true;
  bool _isUploadingFile = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 6,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 5),
    );
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      final partnerId = widget.isClient
          ? widget.caseModel.acceptedLawyerId
          : widget.caseModel.clientId;

      // Group fetches
      Future<DocumentSnapshot?> fetchCurrent() async {
        if (currentUserId == null) return null;
        return FirebaseFirestore.instance.collection('users').doc(currentUserId).get();
      }

      Future<DocumentSnapshot?> fetchPartner() async {
        if (partnerId == null || partnerId.isEmpty) return null;
        return FirebaseFirestore.instance.collection('users').doc(partnerId).get();
      }

      Future<LawyerProfile?> fetchProfile() async {
        if (!widget.isClient || partnerId == null || partnerId.isEmpty) return null;
        return LawyerService().getLawyerById(partnerId);
      }

      Future<Map<String, dynamic>?> fetchReviews() async {
        if (!widget.isClient || partnerId == null || partnerId.isEmpty) return null;
        return LawyerService().getLawyerReviews(partnerId);
      }

      final results = await Future.wait([
        fetchCurrent(),
        fetchPartner(),
        fetchProfile(),
        fetchReviews(),
      ]);

      if (mounted) {
        setState(() {
          final currentDoc = results[0] as DocumentSnapshot?;
          if (currentDoc != null && currentDoc.exists) {
            _currentUserData = currentDoc.data() as Map<String, dynamic>?;
          }

          final partnerDoc = results[1] as DocumentSnapshot?;
          if (partnerDoc != null && partnerDoc.exists) {
            _partnerData = partnerDoc.data() as Map<String, dynamic>?;
          }

          final profile = results[2] as LawyerProfile?;
          final reviewsData = results[3] as Map<String, dynamic>?;

          if (profile != null) {
            _lawyerProfile = profile;
            if (reviewsData != null && reviewsData.isNotEmpty) {
              final dynamicCount = reviewsData['count'] as int;
              if (dynamicCount > 0) {
                final dynamicRating = reviewsData['rating'] as double;
                final dynamicReviews = (reviewsData['reviews'] as List).cast<LawyerReview>();
                _lawyerProfile = LawyerProfile(
                  id: profile.id,
                  fullName: profile.fullName,
                  professionalHeading: profile.professionalHeading,
                  location: profile.location,
                  photoUrl: profile.photoUrl,
                  specializations: profile.specializations,
                  experienceYears: profile.experienceYears,
                  rating: dynamicRating,
                  reviewsCount: dynamicCount,
                  hourlyRate: profile.hourlyRate,
                  verificationStatus: profile.verificationStatus,
                  accountStatus: profile.accountStatus,
                  isAcceptingCases: profile.isAcceptingCases,
                  education: profile.education,
                  barLicenseNo: profile.barLicenseNo,
                  bio: profile.bio,
                  reviews: dynamicReviews,
                );
              }
            }
          }
          _isLoadingData = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Work Place'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(widget.isClient ? '/client-cases' : '/lawyer-cases');
            }
          },
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      body: Column(
        children: [
          // Partner Header Card
          _buildPartnerHeader(),

          // Tabs
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'Consultations'),
                Tab(text: 'Files'),
                Tab(text: 'Events'),
                Tab(text: 'Milestones'),
                Tab(text: 'Invoices'),
              ],
            ),
          ),

          // Tab View
          Expanded(
            child: StreamBuilder<CaseModel>(
              stream: FirebaseFirestore.instance
                  .collection('cases')
                  .doc(widget.caseModel.caseId)
                  .snapshots()
                  .map((doc) {
                    if (!doc.exists) {
                      return widget.caseModel; // Keep showing initial data if document is deleted
                    }
                    try {
                      return CaseModel.fromMap(doc.data()!, doc.id);
                    } catch (e) {
                      // If there's a parsing error, use initial data
                      return widget.caseModel;
                    }
                  }),
              initialData: widget.caseModel,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Text('Error: ${snapshot.error}'),
                    ),
                  );
                }
                
                final currentCase = snapshot.data ?? widget.caseModel;
                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(currentCase),
                    _buildConsultationsTab(),
                    _buildFilesTab(),
                    _buildEventsTab(),
                    _buildMilestonesTab(),
                    _buildInvoicesTab(),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPartnerHeader() {
    if (_isLoadingData) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: LinearProgressIndicator(),
      );
    }

    if (_partnerData == null) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Text('Partner details not found'),
      );
    }

    final partnerId = widget.isClient ? widget.caseModel.acceptedLawyerId : widget.caseModel.clientId;
    final name = _partnerData!['fullName'] ?? 'Unknown';
    final role = widget.isClient ? 'Lawyer' : 'Client';
    
    // Additional details based on role
    String extraInfo = '';
    if (widget.isClient) {
      // We are looking at a lawyer
      final rating = _lawyerProfile?.rating?.toStringAsFixed(1) ?? _partnerData!['rating']?.toString() ?? '0.0';
      final reviews = _lawyerProfile?.reviewsCount.toString() ?? _partnerData!['reviewsCount']?.toString() ?? '0';
      final experience = _lawyerProfile?.experienceYears.toString() ?? _partnerData!['experienceYears']?.toString() ?? '0';
      extraInfo = '⭐ $rating ($reviews reviews) • $experience yrs exp';
    } else {
      // We are looking at a client
      // Try to parse createdAt to show joined date
      if (_partnerData!['createdAt'] != null) {
        try {
          final DateTime joined = (_partnerData!['createdAt'] as Timestamp).toDate();
          final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
          extraInfo = 'Joined ${months[joined.month - 1]} ${joined.year}';
        } catch (e) {
          extraInfo = 'Client';
        }
      } else {
        extraInfo = 'Client';
      }
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      color: Colors.white,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UserAvatar(
            uid: partnerId ?? '',
            radius: 30,
            fallbackName: name,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  role,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  extraInfo,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // Actions
          Row(
            children: [
              if (widget.caseModel.status != 'closed')
                IconButton(
                  onPressed: () {
                    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
                    final partnerId = widget.isClient
                        ? widget.caseModel.acceptedLawyerId
                        : widget.caseModel.clientId;
                    
                    if (currentUserId != null && partnerId != null && partnerId.isNotEmpty) {
                      final partnerName = _partnerData?['fullName'] ?? 'User';
                      final partnerAvatar = _partnerData?['photoUrl'];
                      
                      context.push(
                        '/chat/direct/$partnerId',
                        extra: {
                          'clientId': widget.isClient ? currentUserId : partnerId,
                          'lawyerId': widget.isClient ? partnerId : currentUserId,
                          'clientName': widget.isClient
                              ? (_currentUserData != null ? _currentUserData!['fullName'] ?? 'Client' : 'Client')
                              : partnerName,
                          'lawyerName': widget.isClient
                              ? partnerName
                              : (_currentUserData != null ? _currentUserData!['fullName'] ?? 'Lawyer' : 'Lawyer'),
                          'clientAvatar': widget.isClient
                              ? (_currentUserData != null ? _currentUserData!['photoUrl'] : null)
                              : partnerAvatar,
                          'lawyerAvatar': widget.isClient
                              ? partnerAvatar
                              : (_currentUserData != null ? _currentUserData!['photoUrl'] : null),
                        },
                      );
                    }
                  },
                  icon: const PhosphorIcon(PhosphorIconsRegular.chatCircleText,
                      color: AppColors.primary),
                ),
              if (widget.isClient) // Only client might want to view lawyer profile details
                IconButton(
                  onPressed: () {
                    final partnerId = widget.caseModel.acceptedLawyerId;
                    if (partnerId != null && partnerId.isNotEmpty) {
                      context.push('/lawyer-profile/$partnerId');
                    }
                  },
                  icon: const PhosphorIcon(PhosphorIconsRegular.userCircle,
                      color: AppColors.textSecondary),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(CaseModel currentCase) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Completion Flow UI
          _buildCompletionFlowUI(currentCase),
          const SizedBox(height: AppSpacing.md),

          // Case Summary Card
          _buildInfoCard(
            'Case Summary',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        currentCase.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        currentCase.category.toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'ID: ${currentCase.caseId.toUpperCase()}',
                  style: const TextStyle(
                    color: AppColors.textLight,
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Description Card
          _buildInfoCard(
            'Description',
            Text(
              currentCase.description,
              style: const TextStyle(height: 1.5),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Project Details Card
          _buildInfoCard(
            'Project Details',
            Column(
              children: [
                _buildDetailRow(
                  PhosphorIconsRegular.mapPin,
                  'Location',
                  currentCase.city,
                ),
                const Divider(height: 24),
                _buildDetailRow(
                  PhosphorIconsRegular.currencyDollar,
                  'Budget',
                  currentCase.agreedBudget != null
                      ? 'PKR ${currentCase.agreedBudget!.toInt()} (Agreed with Lawyer)'
                      : 'PKR ${currentCase.budgetMin.toInt()} - ${currentCase.budgetMax.toInt()} (Client Range)',
                ),
                const Divider(height: 24),
                _buildDetailRow(
                  PhosphorIconsRegular.usersThree,
                  'Meeting Preference',
                  currentCase.meetingPreference == 'in_person'
                      ? 'In-Person Meeting'
                      : 'Virtual / Online',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Timeline & Status Card
          _buildInfoCard(
            'Timeline & Status',
            Column(
              children: [
                _buildDetailRow(
                  PhosphorIconsRegular.calendarCheck,
                  'Created On',
                  '${currentCase.createdAt.day}/${currentCase.createdAt.month}/${currentCase.createdAt.year}',
                ),
                const Divider(height: 24),
                _buildStatusRow(currentCase),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildCompletionFlowUI(CaseModel currentCase) {
    if (currentCase.status == 'closed') {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.success),
        ),
        child: const Row(
          children: [
            PhosphorIcon(PhosphorIconsFill.checkCircle, color: AppColors.success),
            SizedBox(width: 8),
            Text(
              'Case Completed Successfully',
              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.success),
            ),
          ],
        ),
      );
    }

    if (widget.isClient) {
      if (currentCase.workCompletionStatus == 'lawyer_signalled') {
        return _buildClientVerificationCard(currentCase);
      } else if (currentCase.workCompletionStatus == 'client_accepted') {
        return _buildClientFinalStepsCard(currentCase);
      }
    } else {
      // Lawyer View
      if (currentCase.workCompletionStatus == null || currentCase.workCompletionStatus == 'client_rejected') {
        return _buildLawyerSignalButton(currentCase);
      } else if (currentCase.workCompletionStatus == 'lawyer_signalled') {
        return _buildSimpleStatusCard('Waiting for Client to verify work...', AppColors.warning);
      } else if (currentCase.workCompletionStatus == 'client_accepted') {
        return _buildSimpleStatusCard('Work approved! Waiting for payment release...', AppColors.success);
      }
    }

    return const SizedBox.shrink();
  }

  Widget _buildLawyerSignalButton(CaseModel currentCase) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          const Text(
            'Have you finished the work? Send a signal to the client to verify and release payment.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => _showSignalWorkDoneDialog(currentCase),
            icon: const PhosphorIcon(PhosphorIconsRegular.checkSquare),
            label: const Text('Signal Work Done'),
            style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 45)),
          ),
        ],
      ),
    );
  }

  Widget _buildClientVerificationCard(CaseModel currentCase) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.warning),
      ),
      child: Column(
        children: [
          const Text(
            'Lawyer has marked the work as done. Please verify if you are satisfied.',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _verifyWork(currentCase, false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                  ),
                  child: const Text('Still Pending'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () => _verifyWork(currentCase, true),
                  style: FilledButton.styleFrom(backgroundColor: AppColors.success),
                  child: const Text('Work Approved'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClientFinalStepsCard(CaseModel currentCase) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.success),
      ),
      child: Column(
        children: [
          const Text(
             'Work approved! Please rate the lawyer and release the payment to close the case.',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => _showRatingDialog(currentCase),
            icon: const PhosphorIcon(PhosphorIconsRegular.star),
            label: const Text('Rate & Release Payment'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size(double.infinity, 45),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleStatusCard(String text, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      width: double.infinity,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }

  Future<void> _showSignalWorkDoneDialog(CaseModel currentCase) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Signal Completion?'),
        content: const Text('Answering "Yes" will notify the client that the work is finished and ask them to verify it.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Signal Work Done')),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await CaseService().signalWorkDone(currentCase.caseId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Completion signal sent to client')));
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _verifyWork(CaseModel currentCase, bool isAccepted) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isAccepted ? 'Approve Work?' : 'Reject Completion?'),
        content: Text(isAccepted 
          ? 'Are you sure you want to approve this work? You will be asked to rate and pay next.' 
          : 'Are you sure the work is not done? This will signal the lawyer to continue working.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true), 
            style: isAccepted ? null : FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(isAccepted ? 'Yes, Approve' : 'Yes, Work is Pending'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await CaseService().verifyWork(currentCase.caseId, isAccepted);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(isAccepted ? 'Work approved!' : 'Rejection sent to lawyer'),
            backgroundColor: isAccepted ? AppColors.success : AppColors.error,
          ));
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _showRatingDialog(CaseModel currentCase) async {
    final Map<String, double> ratings = {
      'Quality of Work': 5.0,
      'Budget Adjustment': 5.0,
      'Way of Talking': 5.0,
      'Promptness': 5.0,
      'Expertise': 5.0,
    };
    final TextEditingController descriptionController = TextEditingController();

    final bool? result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Rate Lawyer'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ...ratings.keys.map((key) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(key, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    Row(
                      children: List.generate(5, (index) => GestureDetector(
                        onTap: () => setDialogState(() => ratings[key] = (index + 1).toDouble()),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                          child: Icon(
                            index < ratings[key]! ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                            size: 32,
                          ),
                        ),
                      )),
                    ),
                    const SizedBox(height: 8),
                  ],
                )),
                TextField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Write a review...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(
              onPressed: () => Navigator.pop(context, true), 
              child: const Text('Submit Review & Continue'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      try {
        await CaseService().submitReview(
          caseId: currentCase.caseId,
          lawyerId: currentCase.acceptedLawyerId!,
          clientId: currentCase.clientId,
          ratings: ratings,
          description: descriptionController.text,
        );
        if (mounted) {
          _showPaymentReleaseDialog(currentCase);
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to submit review: $e')));
      }
    }
  }

  Future<void> _showPaymentReleaseDialog(CaseModel currentCase) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Release Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('The work is approved and reviewed. Now release the agreed payment to the lawyer.'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.grey100,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Agreed Amount:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    'PKR ${currentCase.agreedBudget?.toInt() ?? 0}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 18),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Release Payment'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await CaseService().completeCase(currentCase.caseId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Payment released! Case marked as completed.'),
            backgroundColor: AppColors.success,
          ));
          // Case will automatically update in StreamBuilder and show completion state
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Payment failed: $e')));
      }
    }
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.grey100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: PhosphorIcon(icon, size: 20, color: AppColors.primary),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textLight,
                  fontSize: 12,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusRow(CaseModel currentCase) {
    Color statusColor;
    String statusText;

    switch (currentCase.status.toLowerCase()) {
      case 'active':
        statusColor = AppColors.success;
        statusText = 'Currently Active (Workspace)';
        break;
      case 'closed':
        statusColor = AppColors.error;
        statusText = 'Case Closed / Completed';
        break;
      default:
        statusColor = AppColors.warning;
        statusText = currentCase.status.toUpperCase();
    }

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: PhosphorIcon(PhosphorIconsFill.info, size: 20, color: statusColor),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Current Status',
                style: TextStyle(
                  color: AppColors.textLight,
                  fontSize: 12,
                ),
              ),
              Text(
                statusText,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: statusColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConsultationsTab() {
    final consultationService = ConsultationService();

    return Column(
      children: [
        if (widget.caseModel.status != 'closed')
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: FilledButton.icon(
              onPressed: _showRequestConsultationSheet,
              icon: const PhosphorIcon(PhosphorIconsRegular.videoCamera),
              label: const Text('Request Consultation'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ),
        Expanded(
          child: StreamBuilder<List<ConsultationModel>>(
            stream: consultationService
                .getConsultationsForCase(widget.caseModel.caseId),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final consultations = snapshot.data ?? [];
              if (consultations.isEmpty) {
                return const Center(
                  child: Text(
                    'No consultations scheduled yet.\nRequest one above!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                itemCount: consultations.length,
                itemBuilder: (context, index) {
                  final consult = consultations[index];
                  return _buildConsultationCard(consult);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildConsultationCard(ConsultationModel consult) {
    // Determine if we are the requester or target
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    // Note: This logic assumes we can get current user. passing in is better but this works.
    final isRequester = consult.requesterId == currentUserId;

    // Status color
    Color statusColor;
    switch (consult.status) {
      case 'accepted':
        statusColor = AppColors.success;
        break;
      case 'rejected':
        statusColor = AppColors.error;
        break;
      default:
        statusColor = AppColors.warning;
    }

    return InkWell(
      onTap: () {
        context.push('/consultation-details/${widget.caseModel.caseId}/${consult.id}');
      },
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: AppColors.grey200),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    consult.type == 'video'
                        ? PhosphorIconsRegular.videoCamera
                        : PhosphorIconsRegular.usersThree,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          consult.type == 'video' ? 'Video Call' : 'In-Person',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${consult.scheduledAt.day}/${consult.scheduledAt.month}/${consult.scheduledAt.year} @ ${consult.scheduledAt.hour}:${consult.scheduledAt.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Partner: ${widget.isClient ? consult.lawyerName : consult.clientName}',
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      consult.status.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
  
              // Action Buttons (Accept/Reject) - Only for Target if Pending
              if (consult.status == 'pending' && !isRequester) ...[
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () =>
                          _updateConsultationStatus(consult.id, 'rejected'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        visualDensity: VisualDensity.compact,
                      ),
                      child: const Text('Reject'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () =>
                          _updateConsultationStatus(consult.id, 'accepted'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.success,
                        visualDensity: VisualDensity.compact,
                      ),
                      child: const Text('Accept'),
                    ),
                  ],
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }

  void _updateConsultationStatus(String id, String status) {
    ConsultationService().updateStatus(widget.caseModel.caseId, id, status);
  }

  void _showRequestConsultationSheet() {
    String clientName = 'Client';
    String lawyerName = 'Lawyer';
    String? clientAvatar;
    String? lawyerAvatar;

    if (widget.isClient) {
      clientName = _currentUserData?['fullName'] ?? 'Client';
      lawyerName = _partnerData?['fullName'] ?? 'Lawyer';
      clientAvatar = _currentUserData?['photoUrl'];
      lawyerAvatar = _partnerData?['photoUrl'];
    } else {
      clientName = _partnerData?['fullName'] ?? 'Client';
      lawyerName = _currentUserData?['fullName'] ?? 'Lawyer';
      clientAvatar = _partnerData?['photoUrl'];
      lawyerAvatar = _currentUserData?['photoUrl'];
    }

    final lawyerOfficeLocation = widget.isClient
        ? (_partnerData?['officeLocation'] ?? _partnerData?['address'])
        : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (context) => _RequestConsultationSheet(
        caseId: widget.caseModel.caseId,
        targetId: widget.isClient
            ? widget.caseModel.acceptedLawyerId! // Must exist if active
            : widget.caseModel.clientId,
        caseTitle: widget.caseModel.title,
        clientName: clientName,
        lawyerName: lawyerName,
        clientAvatar: clientAvatar,
        lawyerAvatar: lawyerAvatar,
        lawyerOfficeLocation: lawyerOfficeLocation,
        isClient: widget.isClient,
      ),
    );
  }

  Widget _buildFilesTab() {
    return Column(
      children: [
        if (widget.caseModel.status != 'closed')
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: FilledButton.icon(
              onPressed: _isUploadingFile ? null : _uploadFile,
              icon: _isUploadingFile
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const PhosphorIcon(PhosphorIconsRegular.uploadSimple),
              label: Text(_isUploadingFile ? 'Uploading...' : 'Upload File'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ),
        Expanded(
          child: StreamBuilder<List<FileModel>>(
            stream: FileService().streamFilesForCase(widget.caseModel.caseId),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final dbFiles = snapshot.data ?? [];
              
              // Map initial attachments from CaseModel to FileModel-like objects
              final initialFiles = widget.caseModel.attachments.map((att) => FileModel(
                id: 'initial_${att.fileUrl.hashCode}',
                caseId: widget.caseModel.caseId,
                uploaderId: widget.caseModel.clientId,
                fileName: att.title.isEmpty ? 'Original Attachment' : att.title,
                fileUrl: att.fileUrl,
                fileSize: 0, // Not available for original attachments
                uploadedAt: widget.caseModel.createdAt,
              )).toList();

              final allFiles = [...initialFiles, ...dbFiles];

              if (allFiles.isEmpty) {
                return const Center(
                  child: Text(
                    'No files shared yet.\nUpload documents here!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                itemCount: allFiles.length,
                itemBuilder: (context, index) {
                  final file = allFiles[index];
                  final isInitial = file.id.startsWith('initial_');
                  final isMe = !isInitial && file.uploaderId == FirebaseAuth.instance.currentUser?.uid;
                  
                  // Label Logic
                  String uploaderLabel = '';
                  if (isInitial) {
                    uploaderLabel = 'Uploaded by Client (Initial)';
                  } else if (file.uploaderId == widget.caseModel.clientId) {
                    uploaderLabel = 'Uploaded by Client';
                  } else if (file.uploaderId == widget.caseModel.acceptedLawyerId) {
                    uploaderLabel = 'Uploaded by Lawyer';
                  }

                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    shape: RoundedRectangleBorder(
                      side: const BorderSide(color: AppColors.grey200),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isInitial ? AppColors.primary.withValues(alpha: 0.1) : AppColors.grey100,
                        child: PhosphorIcon(
                          isInitial ? PhosphorIconsFill.shieldStar : PhosphorIconsRegular.file, 
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        file.fileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            uploaderLabel,
                            style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            isInitial 
                              ? 'Original Attachment • ${file.uploadedAt.day}/${file.uploadedAt.month}/${file.uploadedAt.year}'
                              : '${(file.fileSize / 1024).toStringAsFixed(1)} KB • ${file.uploadedAt.day}/${file.uploadedAt.month}/${file.uploadedAt.year}',
                            style: const TextStyle(fontSize: 11),
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isMe) ...[
                            IconButton(
                              icon: const PhosphorIcon(PhosphorIconsRegular.pencilSimple, color: AppColors.textLight, size: 20),
                              onPressed: () => _renameFile(file),
                            ),
                            IconButton(
                              icon: const PhosphorIcon(PhosphorIconsRegular.trash, color: AppColors.error, size: 20),
                              onPressed: () => _deleteFile(file),
                            ),
                          ],
                          IconButton(
                            icon: const PhosphorIcon(PhosphorIconsRegular.downloadSimple, color: AppColors.primary, size: 20),
                            onPressed: () => _openFile(file.fileUrl),
                          ),
                        ],
                      ),
                      onTap: () => _openFile(file.fileUrl),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEventsTab() {
    return Column(
      children: [
        if (!widget.isClient && widget.caseModel.status != 'closed')
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: FilledButton.icon(
              onPressed: _showAddEventDialog,
              icon: const PhosphorIcon(PhosphorIconsRegular.plusCircle),
              label: const Text('Add Event'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ),
        if (widget.isClient)
          const Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Only lawyer can add events. You can view all updates here.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        Expanded(
          child: StreamBuilder<List<EventModel>>(
            stream: _eventService.streamCaseEvents(widget.caseModel.caseId),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final events = snapshot.data ?? [];
              if (events.isEmpty) {
                return const Center(
                  child: Text(
                    'No case events yet.\nLawyer can add updates here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final event = events[index];
                  final eventTime =
                      '${event.scheduledAt.day}/${event.scheduledAt.month}/${event.scheduledAt.year} '
                      '${event.scheduledAt.hour.toString().padLeft(2, '0')}:${event.scheduledAt.minute.toString().padLeft(2, '0')}';

                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    shape: RoundedRectangleBorder(
                      side: const BorderSide(color: AppColors.grey200),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(AppSpacing.md),
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        child: const PhosphorIcon(
                          PhosphorIconsRegular.calendarDots,
                          color: AppColors.primary,
                        ),
                      ),
                      title: Text(
                        event.title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event.location?.isNotEmpty == true
                                  ? 'Place: ${event.location}'
                                  : event.subtitle,
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Time: $eventTime',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.info.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          event.status.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.info,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMilestonesTab() {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final canEdit = widget.caseModel.status != 'closed';

    return Column(
      children: [
        if (canEdit)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: FilledButton.icon(
              onPressed: _showAddMilestoneDialog,
              icon: const PhosphorIcon(PhosphorIconsRegular.plusCircle),
              label: const Text('Add Milestone / Task'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ),
        Expanded(
          child: StreamBuilder<List<CaseMilestoneModel>>(
            stream: _milestoneService.streamCaseMilestones(widget.caseModel.caseId),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final milestones = snapshot.data ?? [];
              if (milestones.isEmpty) {
                return const Center(
                  child: Text(
                    'No milestones yet.\nAdd tasks to keep progress clear.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                itemCount: milestones.length,
                itemBuilder: (context, index) {
                  final milestone = milestones[index];
                  final isPaidMilestone = milestone.status == 'paid';
                  final isCompleted = milestone.status == 'completed' || isPaidMilestone;
                  final hasPayment = milestone.paymentAmount > 0;
                  final dueText = milestone.dueDate != null
                      ? 'Due ${milestone.dueDate!.day}/${milestone.dueDate!.month}/${milestone.dueDate!.year}'
                      : 'No due date';
                  final canToggle = canEdit && currentUserId != null && !isPaidMilestone;

                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    shape: RoundedRectangleBorder(
                      side: const BorderSide(color: AppColors.grey200),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: isCompleted
                                    ? AppColors.success.withValues(alpha: 0.12)
                                    : AppColors.primary.withValues(alpha: 0.1),
                                child: PhosphorIcon(
                                  isCompleted
                                      ? PhosphorIconsFill.checkCircle
                                      : PhosphorIconsRegular.circle,
                                  color: isCompleted ? AppColors.success : AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      milestone.title,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        decoration:
                                            isCompleted ? TextDecoration.lineThrough : null,
                                      ),
                                    ),
                                    if (milestone.details.isNotEmpty)
                                      Text(
                                        milestone.details,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              if (canToggle)
                                IconButton(
                                  onPressed: () => _toggleMilestoneStatus(
                                    milestone,
                                    isCompleted ? 'pending' : 'completed',
                                  ),
                                  icon: PhosphorIcon(
                                    isCompleted
                                        ? PhosphorIconsRegular.arrowCounterClockwise
                                        : PhosphorIconsRegular.check,
                                    color: isCompleted
                                        ? AppColors.warning
                                        : AppColors.success,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            dueText,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          if (hasPayment) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(AppRadius.md),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Payment Amount',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      Text(
                                        'PKR ${milestone.paymentAmount.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (currentUserId == widget.caseModel.clientId && widget.isClient)
                                    FilledButton.icon(
                                      onPressed: isPaidMilestone ? null : () => _payMilestone(milestone),
                                      icon: const PhosphorIcon(PhosphorIconsRegular.creditCard),
                                      label: Text(isPaidMilestone ? 'Paid' : 'Pay'),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildInvoicesTab() {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final canCreateInvoice = !widget.isClient && widget.caseModel.status != 'closed';

    return Column(
      children: [
        if (canCreateInvoice)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: FilledButton.icon(
              onPressed: _showCreateInvoiceDialog,
              icon: const PhosphorIcon(PhosphorIconsRegular.receipt),
              label: const Text('Create Invoice'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ),
        Expanded(
          child: StreamBuilder<List<CaseInvoiceModel>>(
            stream: _invoiceService.streamCaseInvoices(widget.caseModel.caseId),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final invoices = snapshot.data ?? [];
              if (invoices.isEmpty) {
                return const Center(
                  child: Text(
                    'No invoices yet.\nLawyer can create payment requests here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                itemCount: invoices.length,
                itemBuilder: (context, index) {
                  final invoice = invoices[index];
                  final isPaid = invoice.status == 'paid';
                  final canMarkPaid = !isPaid && currentUserId != null &&
                      currentUserId == invoice.payerId;

                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    shape: RoundedRectangleBorder(
                      side: const BorderSide(color: AppColors.grey200),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  invoice.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isPaid
                                      ? AppColors.success.withValues(alpha: 0.12)
                                      : AppColors.warning.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  isPaid ? 'PAID' : 'PENDING',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        isPaid ? AppColors.success : AppColors.warning,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${invoice.currency} ${invoice.amount.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (invoice.notes.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              invoice.notes,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Text(
                            invoice.dueDate != null
                                ? 'Due: ${invoice.dueDate!.day}/${invoice.dueDate!.month}/${invoice.dueDate!.year}'
                                : 'Due: Not set',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          if (invoice.paidAt != null)
                            Text(
                              'Paid: ${invoice.paidAt!.day}/${invoice.paidAt!.month}/${invoice.paidAt!.year}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          if (canMarkPaid) ...[
                            const SizedBox(height: AppSpacing.sm),
                            Align(
                              alignment: Alignment.centerRight,
                              child: FilledButton.icon(
                                onPressed: () => _payInvoice(invoice),
                                icon: const PhosphorIcon(PhosphorIconsRegular.creditCard),
                                label: const Text('Pay'),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _showAddMilestoneDialog() async {
    final titleController = TextEditingController();
    final detailsController = TextEditingController();
    final paymentController = TextEditingController();
    DateTime? dueDate;
    bool isSubmitting = false;

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Milestone / Task'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    hintText: 'e.g., Draft petition and review',
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: detailsController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Details',
                    hintText: 'Optional notes for this task',
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: paymentController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Payment Amount (PKR)',
                    hintText: 'Optional - leave empty if no payment required',
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: dueDate ?? DateTime.now().add(const Duration(days: 3)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setDialogState(() => dueDate = picked);
                      }
                    },
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(
                      dueDate == null
                          ? 'Set Due Date (Optional)'
                          : '${dueDate!.day}/${dueDate!.month}/${dueDate!.year}',
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      final title = titleController.text.trim();
                      final details = detailsController.text.trim();
                      final paymentText = paymentController.text.trim();
                      
                      if (title.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Task title is required'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                        return;
                      }

                      setDialogState(() => isSubmitting = true);
                      await _createMilestone(
                        title: title,
                        details: details,
                        dueDate: dueDate,
                        paymentAmount: paymentText.isEmpty ? 0.0 : double.tryParse(paymentText) ?? 0.0,
                      );
                      if (!mounted) return;
                      Navigator.pop(context);
                    },
              child: isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createMilestone({
    required String title,
    required String details,
    required DateTime? dueDate,
    required double paymentAmount,
  }) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final lawyerId = widget.caseModel.acceptedLawyerId;
    final clientId = widget.caseModel.clientId;

    if (currentUserId == null || lawyerId == null || lawyerId.isEmpty) {
      return;
    }

    await _milestoneService.createMilestone(
      caseId: widget.caseModel.caseId,
      title: title,
      details: details,
      dueDate: dueDate,
      paymentAmount: paymentAmount,
      createdBy: currentUserId,
    );

    final dueText = dueDate != null
        ? ' (due ${dueDate.day}/${dueDate.month}/${dueDate.year})'
        : '';
    final message = '$title$dueText';

    await _notificationService.createBatchNotifications([
      AppNotification(
        id: '',
        userId: clientId,
        actorId: currentUserId,
        type: NotificationType.generic,
        title: 'New milestone added',
        message: message,
        referenceType: 'case_milestone',
        referenceId: widget.caseModel.caseId,
        payload: {'caseId': widget.caseModel.caseId},
        createdAt: DateTime.now(),
      ),
      AppNotification(
        id: '',
        userId: lawyerId,
        actorId: currentUserId,
        type: NotificationType.generic,
        title: 'New milestone added',
        message: message,
        referenceType: 'case_milestone',
        referenceId: widget.caseModel.caseId,
        payload: {'caseId': widget.caseModel.caseId},
        createdAt: DateTime.now(),
      ),
    ]);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Milestone added successfully')),
      );
    }
  }

  Future<void> _toggleMilestoneStatus(
    CaseMilestoneModel milestone,
    String status,
  ) async {
    await _milestoneService.updateStatus(
      caseId: widget.caseModel.caseId,
      milestoneId: milestone.id,
      status: status,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == 'completed'
                ? 'Milestone marked as completed'
                : 'Milestone reopened',
          ),
        ),
      );
    }
  }

  Future<void> _showCreateInvoiceDialog() async {
    final titleController = TextEditingController();
    final notesController = TextEditingController();
    final amountController = TextEditingController();
    DateTime? dueDate;
    bool isSubmitting = false;

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Create Invoice'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Invoice Title',
                    hintText: 'e.g., Filing fee - stage 1',
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Amount (PKR)',
                    hintText: 'e.g., 15000',
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    hintText: 'Optional payment details',
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: dueDate ?? DateTime.now().add(const Duration(days: 7)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setDialogState(() => dueDate = picked);
                      }
                    },
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(
                      dueDate == null
                          ? 'Set Due Date (Optional)'
                          : '${dueDate!.day}/${dueDate!.month}/${dueDate!.year}',
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      final amount = double.tryParse(amountController.text.trim()) ?? 0;
                      if (titleController.text.trim().isEmpty || amount <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Title and a valid amount are required'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                        return;
                      }

                      setDialogState(() => isSubmitting = true);
                      await _createInvoice(
                        title: titleController.text.trim(),
                        notes: notesController.text.trim(),
                        amount: amount,
                        dueDate: dueDate,
                      );
                      if (!mounted) return;
                      Navigator.pop(context);
                    },
              child: isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createInvoice({
    required String title,
    required String notes,
    required double amount,
    required DateTime? dueDate,
  }) async {
    final lawyerId = widget.caseModel.acceptedLawyerId;
    final clientId = widget.caseModel.clientId;

    if (lawyerId == null || lawyerId.isEmpty) return;

    await _invoiceService.createInvoice(
      caseId: widget.caseModel.caseId,
      title: title,
      notes: notes,
      amount: amount,
      currency: 'PKR',
      payerId: clientId,
      payeeId: lawyerId,
      dueDate: dueDate,
    );

    await _notificationService.createBatchNotifications([
      AppNotification(
        id: '',
        userId: clientId,
        actorId: lawyerId,
        type: NotificationType.generic,
        title: 'New invoice created',
        message: '$title - PKR ${amount.toStringAsFixed(0)}',
        referenceType: 'case_invoice',
        referenceId: widget.caseModel.caseId,
        payload: {'caseId': widget.caseModel.caseId},
        createdAt: DateTime.now(),
      ),
      AppNotification(
        id: '',
        userId: lawyerId,
        actorId: lawyerId,
        type: NotificationType.generic,
        title: 'Invoice sent to client',
        message: '$title - PKR ${amount.toStringAsFixed(0)}',
        referenceType: 'case_invoice',
        referenceId: widget.caseModel.caseId,
        payload: {'caseId': widget.caseModel.caseId},
        createdAt: DateTime.now(),
      ),
    ]);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invoice created successfully')),
      );
    }
  }

  Future<void> _payInvoice(CaseInvoiceModel invoice) async {
    final lawyerId = widget.caseModel.acceptedLawyerId;
    final clientId = widget.caseModel.clientId;
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    if (lawyerId == null || lawyerId.isEmpty || currentUserId == null) return;

    if (currentUserId != invoice.payerId) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Only payer can mark invoice paid')),
        );
      }
      return;
    }

    // Pre-check balance for a clean low-budget message before transaction errors.
    final payerBalance = await _walletService.getWalletBalance(currentUserId);
    if (payerBalance < invoice.amount) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Insufficient balance. Available: PKR ${payerBalance.toStringAsFixed(2)}, Required: PKR ${invoice.amount.toStringAsFixed(2)}',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    try {
      await _invoiceService.payInvoice(
        caseId: widget.caseModel.caseId,
        invoiceId: invoice.id,
        currentUserId: currentUserId,
      );

      // Best-effort notifications/logs: payment should still count as success if these fail.
      try {
        await _notificationService.createBatchNotifications([
          AppNotification(
            id: '',
            userId: clientId,
            actorId: clientId,
            type: NotificationType.paymentSuccess,
            title: 'Invoice paid',
            message: '${invoice.title} has been marked as paid',
            referenceType: 'case_invoice',
            referenceId: invoice.id,
            payload: {'caseId': widget.caseModel.caseId, 'invoiceId': invoice.id},
            createdAt: DateTime.now(),
          ),
          AppNotification(
            id: '',
            userId: lawyerId,
            actorId: clientId,
            type: NotificationType.paymentSuccess,
            title: 'Client marked invoice as paid',
            message: '${invoice.title} has been marked as paid',
            referenceType: 'case_invoice',
            referenceId: invoice.id,
            payload: {'caseId': widget.caseModel.caseId, 'invoiceId': invoice.id},
            createdAt: DateTime.now(),
          ),
        ]);

        await _recentUpdateService.addRecentUpdate(
          RecentUpdate(
            id: '',
            userId: clientId,
            type: UpdateType.paymentAccepted,
            title: 'Invoice paid',
            message: '${invoice.title} payment completed',
            relatedId: widget.caseModel.caseId,
            timestamp: DateTime.now(),
          ),
        );

        await _recentUpdateService.addRecentUpdate(
          RecentUpdate(
            id: '',
            userId: lawyerId,
            type: UpdateType.paymentAccepted,
            title: 'Client payment received',
            message: '${invoice.title} marked paid in workspace',
            relatedId: widget.caseModel.caseId,
            timestamp: DateTime.now(),
          ),
        );
      } catch (_) {
        // Ignore post-payment side-effect failures.
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invoice marked as paid'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final raw = e.toString().replaceFirst('Exception: ', '').trim();
        final message = _friendlyPaymentError(raw);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  String _friendlyPaymentError(String raw) {
    final msg = raw.toLowerCase();
    if (msg.contains('insufficient') || msg.contains('not enough')) {
      return 'Insufficient balance to complete payment. Please add funds and try again.';
    }
    if (msg.contains('permission')) {
      return 'You are not allowed to perform this payment.';
    }
    if (msg.contains('payer') || msg.contains('only the invoice payer')) {
      return 'Only the invoice payer can pay this invoice.';
    }
    if (msg.contains('not found')) {
      return 'This invoice could not be found. Please refresh and try again.';
    }
    if (msg.contains('dart exception thrown from converted future')) {
      return 'Payment could not be completed. Please try again.';
    }
    return raw.isEmpty ? 'Payment failed. Please try again.' : raw;
  }

  Future<void> _payMilestone(CaseMilestoneModel milestone) async {
    final lawyerId = widget.caseModel.acceptedLawyerId;
    final clientId = widget.caseModel.clientId;
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    if (lawyerId == null || lawyerId.isEmpty || currentUserId == null) return;

    if (currentUserId != clientId) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Only client can pay milestone')),
        );
      }
      return;
    }

    if (milestone.status == 'paid') {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This milestone is already paid')),
        );
      }
      return;
    }

    // Check wallet balance
    final walletBalance = await _walletService.getWalletBalance(clientId);
    if (walletBalance < milestone.paymentAmount) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Insufficient balance. Available: PKR ${walletBalance.toStringAsFixed(2)}, Required: PKR ${milestone.paymentAmount.toStringAsFixed(2)}',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    try {
      // Perform atomic transfer from client to lawyer
      await _walletService.transfer(
        fromUserId: clientId,
        toUserId: lawyerId,
        amount: milestone.paymentAmount,
        operationId: 'milestone_payment_${milestone.id}_${DateTime.now().millisecondsSinceEpoch}',
        debitReason: 'Milestone payment: ${milestone.title}',
        creditReason: 'Received milestone payment: ${milestone.title}',
        referenceType: 'case_milestone',
        referenceId: milestone.id,
      );

      await _milestoneService.updateStatus(
        caseId: widget.caseModel.caseId,
        milestoneId: milestone.id,
        status: 'paid',
      );

      // Create notifications for both parties
      await _notificationService.createBatchNotifications([
        AppNotification(
          id: '',
          userId: clientId,
          actorId: clientId,
          type: NotificationType.paymentSuccess,
          title: 'Milestone payment sent',
          message: 'Payment of PKR ${milestone.paymentAmount.toStringAsFixed(0)} sent for "${milestone.title}"',
          referenceType: 'case_milestone',
          referenceId: milestone.id,
          payload: {'caseId': widget.caseModel.caseId, 'milestoneId': milestone.id},
          createdAt: DateTime.now(),
        ),
        AppNotification(
          id: '',
          userId: lawyerId,
          actorId: clientId,
          type: NotificationType.paymentSuccess,
          title: 'Milestone payment received',
          message: 'You received PKR ${milestone.paymentAmount.toStringAsFixed(0)} for "${milestone.title}"',
          referenceType: 'case_milestone',
          referenceId: milestone.id,
          payload: {'caseId': widget.caseModel.caseId, 'milestoneId': milestone.id},
          createdAt: DateTime.now(),
        ),
      ]);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment of PKR ${milestone.paymentAmount.toStringAsFixed(0)} sent successfully'),
            duration: const Duration(seconds: 2),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Payment failed: ${e.toString().replaceFirst('Exception: ', '')}',
            ),
            duration: const Duration(seconds: 3),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _showAddEventDialog() async {
    if (widget.isClient) return;

    final nameController = TextEditingController();
    final placeController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = const TimeOfDay(hour: 10, minute: 0);
    bool isSubmitting = false;

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Case Event'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Event Name',
                    hintText: 'e.g., Court Hearing',
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: placeController,
                  decoration: const InputDecoration(
                    labelText: 'Event Place',
                    hintText: 'e.g., District Court Lahore',
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                          );
                          if (picked != null) {
                            setDialogState(() => selectedDate = picked);
                          }
                        },
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(
                          '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: selectedTime,
                          );
                          if (picked != null) {
                            setDialogState(() => selectedTime = picked);
                          }
                        },
                        icon: const Icon(Icons.access_time, size: 16),
                        label: Text(selectedTime.format(context)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      final name = nameController.text.trim();
                      final place = placeController.text.trim();

                      if (name.isEmpty || place.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Event name and place are required'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                        return;
                      }

                      final eventDateTime = DateTime(
                        selectedDate.year,
                        selectedDate.month,
                        selectedDate.day,
                        selectedTime.hour,
                        selectedTime.minute,
                      );

                      setDialogState(() => isSubmitting = true);
                      await _createCaseEvent(name, place, eventDateTime);
                      if (!mounted) return;
                      Navigator.pop(context);
                    },
              child: isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Create Event'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createCaseEvent(
    String eventName,
    String place,
    DateTime scheduledAt,
  ) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final lawyerId = widget.caseModel.acceptedLawyerId;
    final clientId = widget.caseModel.clientId;

    if (currentUserId == null || lawyerId == null || lawyerId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot create event for this case'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    final eventId = FirebaseFirestore.instance.collection('events').doc().id;
    final event = EventModel(
      id: eventId,
      type: 'case_event',
      title: eventName,
      subtitle: 'Case #${widget.caseModel.caseId.toUpperCase()}',
      location: place,
      caseId: widget.caseModel.caseId,
      referenceId: widget.caseModel.caseId,
      participants: [clientId, lawyerId],
      scheduledAt: scheduledAt,
      status: 'upcoming',
      createdBy: currentUserId,
    );

    await _eventService.createEvent(event);

    final eventTimeText =
        '${scheduledAt.day}/${scheduledAt.month}/${scheduledAt.year} '
        '${scheduledAt.hour.toString().padLeft(2, '0')}:${scheduledAt.minute.toString().padLeft(2, '0')}';
    final eventMessage = '$eventName at $place on $eventTimeText';

    await _notificationService.createBatchNotifications([
      AppNotification(
        id: '',
        userId: clientId,
        actorId: lawyerId,
        type: NotificationType.generic,
        title: 'New case event added',
        message: eventMessage,
        referenceType: 'case_event',
        referenceId: eventId,
        payload: {
          'caseId': widget.caseModel.caseId,
          'eventId': eventId,
          'place': place,
          'scheduledAt': scheduledAt.toIso8601String(),
        },
        createdAt: DateTime.now(),
      ),
      AppNotification(
        id: '',
        userId: lawyerId,
        actorId: lawyerId,
        type: NotificationType.generic,
        title: 'Event created successfully',
        message: eventMessage,
        referenceType: 'case_event',
        referenceId: eventId,
        payload: {
          'caseId': widget.caseModel.caseId,
          'eventId': eventId,
          'place': place,
          'scheduledAt': scheduledAt.toIso8601String(),
        },
        createdAt: DateTime.now(),
      ),
    ]);

    await _recentUpdateService.addRecentUpdate(
      RecentUpdate(
        id: '',
        userId: clientId,
        type: UpdateType.hearingScheduled,
        title: 'New event scheduled',
        message: eventMessage,
        relatedId: widget.caseModel.caseId,
        timestamp: DateTime.now(),
      ),
    );

    await _recentUpdateService.addRecentUpdate(
      RecentUpdate(
        id: '',
        userId: lawyerId,
        type: UpdateType.hearingScheduled,
        title: 'Event added to case',
        message: eventMessage,
        relatedId: widget.caseModel.caseId,
        timestamp: DateTime.now(),
      ),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Event added and users notified'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _uploadFile() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      // 1. Check file limit (max 3 files per party)
      final count = await FileService().getUserFileCount(widget.caseModel.caseId, userId);
      if (count >= 3) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Upload limit reached (Max 3 files per party)'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      // 2. Pick file
      final result = await FilePicker.platform.pickFiles(type: FileType.any);

      if (result != null && result.files.single.path != null) {
        // 3. Prompt for name
        final String? customName = await _showFileNameDialog(result.files.single.name);
        if (customName == null || customName.trim().isEmpty) return;

        setState(() => _isUploadingFile = true);

        final file = File(result.files.single.path!);
        final fileName = customName.trim();

        await FileService().uploadFile(
          caseId: widget.caseModel.caseId,
          uploaderId: userId,
          file: file,
          fileName: fileName,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File uploaded successfully!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading file: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingFile = false);
      }
    }
  }

  Future<String?> _showFileNameDialog(String initialName) async {
    final controller = TextEditingController(text: initialName);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Name your file'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'File Name',
            hintText: 'Enter name for other party to see',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Upload'),
          ),
        ],
      ),
    );
  }

  Future<void> _renameFile(FileModel file) async {
    final controller = TextEditingController(text: file.fileName);
    final String? newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename file'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'New Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newName != null && newName.trim().isNotEmpty && newName != file.fileName) {
      try {
        await FileService().updateFileName(widget.caseModel.caseId, file.id, newName.trim());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('File renamed')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Rename failed: $e')));
        }
      }
    }
  }

  Future<void> _deleteFile(FileModel file) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (file.uploaderId != userId) return;

    // Confirm deletion
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete File?'),
        content: Text('Are you sure you want to delete "${file.fileName}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await FileService().deleteFile(widget.caseModel.caseId, file);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File deleted')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: $e')),
        );
      }
    }
  }

  Future<void> _openFile(String url) async {
    try {
      final uri = Uri.parse(url);
      // Directly try to launch, as canLaunchUrl is unreliable on newer Android versions 
      // without manifest queries, and we know these are valid https storage URLs.
      final launched = await launchUrl(
        uri, 
        mode: LaunchMode.externalApplication,
      );
      
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open file. No application found to handle this link.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening file: $e')),
        );
      }
    }
  }

  Widget _buildInfoCard(String title, Widget content) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
                color: AppColors.textSecondary, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          content,
        ],
      ),
    );
  }
}

class _RequestConsultationSheet extends StatefulWidget {
  final String caseId;
  final String targetId;
  final String caseTitle;
  final String clientName;
  final String lawyerName;
  final String? clientAvatar;
  final String? lawyerAvatar;
  final String? lawyerOfficeLocation; // Lawyer's office location for in-person
  final bool isClient;

  const _RequestConsultationSheet({
    required this.caseId,
    required this.targetId,
    required this.caseTitle,
    required this.clientName,
    required this.lawyerName,
    this.clientAvatar,
    this.lawyerAvatar,
    this.lawyerOfficeLocation,
    required this.isClient,
  });

  @override
  State<_RequestConsultationSheet> createState() =>
      _RequestConsultationSheetState();
}

class _RequestConsultationSheetState extends State<_RequestConsultationSheet> {
  String _type = 'video';
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 10, minute: 0);
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Request Consultation',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            widget.caseTitle,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.md),

          // Type Selection
          Row(
            children: [
              _buildTypeChip(
                  'video', 'Video Call', PhosphorIconsRegular.videoCamera),
              const SizedBox(width: 8),
              _buildTypeChip(
                  'in_person', 'In-Person', PhosphorIconsRegular.usersThree),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // Show location info for in-person
          if (_type == 'in_person')
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Meeting Location',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (widget.lawyerOfficeLocation != null &&
                      widget.lawyerOfficeLocation!.isNotEmpty)
                    Text(
                      widget.lawyerOfficeLocation!,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    )
                  else
                    Text(
                      'No lawyer office location set. Please agree on location via chat.',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.warning,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ),

          const SizedBox(height: AppSpacing.md),

          // Date & Time
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text(
                      '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickTime,
                  icon: const Icon(Icons.access_time, size: 16),
                  label: Text(_selectedTime.format(context)),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          FilledButton(
            onPressed: _isSubmitting ? null : _submitRequest,
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('Send Request'),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  Widget _buildTypeChip(String value, String label, IconData icon) {
    final isSelected = _type == value;
    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.black),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      onSelected: (bool selected) {
        if (selected) setState(() => _type = value);
      },
      backgroundColor: Colors.white,
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black,
      ),
      checkmarkColor: Colors.white,
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      final candidate = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        picked.hour,
        picked.minute,
      );

      if (candidate.isBefore(DateTime.now())) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Selected time has already passed. Please choose a future time.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _submitRequest() async {
    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('No user logged in');

      // 1. Check Consultation Limit (3 free per case)
      final existingCount = await ConsultationService().getConsultationCountForCase(widget.caseId);
      if (existingCount >= 3) {
        // Dummy payment flow
        if (mounted) {
          _showPaymentRequiredDialog(context);
        }
        setState(() => _isSubmitting = false);
        return;
      }

      // Combine Date and Time
      final scheduledAt = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      if (scheduledAt.isBefore(DateTime.now())) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please select a future date and time for consultation.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      final consultation = ConsultationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(), // Simple ID gen
        caseId: widget.caseId,
        requesterId: user.uid,
        targetId: widget.targetId,
        caseTitle: widget.caseTitle,
        clientName: widget.clientName,
        lawyerName: widget.lawyerName,
        clientId: widget.isClient ? user.uid : widget.targetId,
        lawyerId: widget.isClient ? widget.targetId : user.uid,
        clientAvatar: widget.clientAvatar,
        lawyerAvatar: widget.lawyerAvatar,
        type: _type,
        lawyerOfficeLocation: _type == 'in_person' ? widget.lawyerOfficeLocation : null,
        status: 'pending',
        scheduledAt: scheduledAt,
        createdAt: DateTime.now(),
      );

      // Pass user's display name or use a default
      final requesterName = user.displayName ?? 'User';
      final requesterRole = widget.isClient ? 'Client' : 'Lawyer';
      
      await ConsultationService().requestConsultation(consultation, requesterName, requesterRole);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Consultation request sent!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showPaymentRequiredDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Consultation Limit Reached'),
        content: const Text(
          'Each workspace includes 3 free consultations. You have reached this limit. Please pay to schedule more.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Payment gateway coming soon...')),
              );
            },
            child: const Text('Pay for 1 More (\$10)'),
          ),
        ],
      ),
    );
  }
}
