import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:zakoota/l10n/app_localizations.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/case_model.dart';
import '../models/consultation_model.dart';
import '../services/consultation_service.dart';
import '../../lawyer_auth/services/lawyer_availability_service.dart';
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
  bool _isPayingMilestone = false;
  bool _isPayingInvoice = false;

  AppLocalizations get loc => AppLocalizations.of(context);

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
    final loc = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(loc.workplaceTitle),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(widget.isClient ? '/client-home' : '/lawyer-dashboard');
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

          // Scrollable Tabs
          Container(
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicator: UnderlineTabIndicator(
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                ),
                tabAlignment: TabAlignment.start,
                isScrollable: true,
                labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                tabs: [
                  Tab(text: loc.overview),
                  Tab(text: loc.consultations),
                  Tab(text: loc.files),
                  Tab(text: loc.events),
                  Tab(text: loc.milestones),
                  Tab(text: loc.invoices),
                ],
              ),
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
                      return widget.caseModel;
                    }
                    try {
                      return CaseModel.fromMap(doc.data()!, doc.id);
                    } catch (e) {
                      return widget.caseModel;
                    }
                  }),
              initialData: widget.caseModel,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Text('${loc.error}: ${snapshot.error}'),
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
    final loc = AppLocalizations.of(context);
    if (_isLoadingData) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: LinearProgressIndicator(),
      );
    }

    if (_partnerData == null) {
      return Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Text(loc.partnerDetailsNotFound),
      );
    }

    final partnerId = widget.isClient ? widget.caseModel.acceptedLawyerId : widget.caseModel.clientId;
    final name = _partnerData!['fullName'] ?? loc.unknown;
    final role = widget.isClient ? loc.lawyer : loc.client;
    
    String extraInfo = '';
    if (widget.isClient) {
      final rating = _lawyerProfile?.rating?.toStringAsFixed(1) ?? _partnerData!['rating']?.toString() ?? '0.0';
      final reviews = _lawyerProfile?.reviewsCount.toString() ?? _partnerData!['reviewsCount']?.toString() ?? '0';
      extraInfo = '⭐ $rating ($reviews)';
    } else {
      if (_partnerData!['createdAt'] != null) {
        try {
          final DateTime joined = (_partnerData!['createdAt'] as Timestamp).toDate();
          extraInfo = loc.joined('${joined.month}/${joined.year}');
        } catch (e) {
          extraInfo = loc.client;
        }
      } else {
        extraInfo = loc.client;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      color: Colors.white,
      child: Row(
        children: [
          UserAvatar(
            uid: partnerId ?? '',
            radius: 24,
            fallbackName: name,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$role • $extraInfo',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // Actions
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
              icon: const PhosphorIcon(PhosphorIconsRegular.chatCircleText, color: AppColors.primary),
              constraints: const BoxConstraints.tightFor(width: 40, height: 40),
              padding: EdgeInsets.zero,
              iconSize: 20,
            ),
          if (widget.isClient)
            IconButton(
              onPressed: () {
                final partnerId = widget.caseModel.acceptedLawyerId;
                if (partnerId != null && partnerId.isNotEmpty) {
                  context.push('/lawyer-profile/$partnerId');
                }
              },
              icon: const PhosphorIcon(PhosphorIconsRegular.info, color: AppColors.textSecondary),
              constraints: const BoxConstraints.tightFor(width: 40, height: 40),
              padding: EdgeInsets.zero,
              iconSize: 20,
            ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(CaseModel currentCase) {
    final loc = AppLocalizations.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Completion Flow UI
          _buildCompletionFlowUI(currentCase),
          const SizedBox(height: AppSpacing.md),

          if ((currentCase.heldAmount ?? 0) > 0 || currentCase.paymentStatus == 'held')
            _buildInfoCard(
              loc.fundsInCustody,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow(
                    PhosphorIconsRegular.lockSimple,
                    loc.status,
                    loc.heldInSystemCustody,
                  ),
                  const Divider(height: 24),
                  _buildDetailRow(
                    PhosphorIconsRegular.wallet,
                    loc.heldAmount,
                    '${loc.currencyPKR} ${(currentCase.heldAmount ?? 0).toInt()}',
                  ),
                ],
              ),
            ),
          if ((currentCase.heldAmount ?? 0) > 0 || currentCase.paymentStatus == 'held')
            const SizedBox(height: AppSpacing.md),

          // Case Summary Card
          _buildInfoCard(
            loc.caseSummary,
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
                  '${loc.idLabel} ${currentCase.caseId.toUpperCase()}',
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
            loc.description,
            Text(
              currentCase.description,
              style: const TextStyle(height: 1.5),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Project Details Card
          _buildInfoCard(
            loc.projectDetails,
            Column(
              children: [
                _buildDetailRow(
                  PhosphorIconsRegular.mapPin,
                  loc.location,
                  currentCase.city,
                ),
                const Divider(height: 24),
                _buildDetailRow(
                  PhosphorIconsRegular.currencyDollar,
                  loc.budget,
                  currentCase.agreedBudget != null
                      ? '${loc.currencyPKR} ${currentCase.agreedBudget!.toInt()} (${loc.agreedWithLawyer})'
                      : '${loc.currencyPKR} ${currentCase.budgetMin.toInt()} - ${currentCase.budgetMax.toInt()} (${loc.clientRange})',
                ),
                const Divider(height: 24),
                _buildDetailRow(
                  PhosphorIconsRegular.usersThree,
                  loc.meetingPreference,
                  currentCase.meetingPreference == 'in_person'
                      ? loc.inPersonMeeting
                      : loc.virtualOnline,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Timeline & Status Card
          _buildInfoCard(
            loc.timelineAndStatus,
            Column(
              children: [
                _buildDetailRow(
                  PhosphorIconsRegular.calendarCheck,
                  loc.createdOn,
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
    final loc = AppLocalizations.of(context);
    if (currentCase.status == 'closed') {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.success),
        ),
        child: Row(
          children: [
            const PhosphorIcon(PhosphorIconsFill.checkCircle, color: AppColors.success),
            const SizedBox(width: 8),
            Text(
              loc.caseCompletedSuccessfully,
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
        return _buildSimpleStatusCard(loc.waitingForClientToVerifyWork, AppColors.warning);
      } else if (currentCase.workCompletionStatus == 'client_accepted') {
        return _buildSimpleStatusCard(loc.workApprovedWaitingForPaymentRelease, AppColors.success);
      }
    }

    return const SizedBox.shrink();
  }

  Widget _buildLawyerSignalButton(CaseModel currentCase) {
    final loc = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            loc.finishWorkSignalClient,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => _showSignalWorkDoneDialog(currentCase),
            icon: const PhosphorIcon(PhosphorIconsRegular.checkSquare),
            label: Text(loc.signalWorkDone),
            style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 45)),
          ),
        ],
      ),
    );
  }

  Widget _buildClientVerificationCard(CaseModel currentCase) {
    final loc = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.warning),
      ),
      child: Column(
        children: [
          Text(
            loc.lawyerMarkedWorkDoneVerify,
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
                  child: Text(loc.stillPending),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () => _verifyWork(currentCase, true),
                  style: FilledButton.styleFrom(backgroundColor: AppColors.success),
                  child: Text(loc.workApproved),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClientFinalStepsCard(CaseModel currentCase) {
    final loc = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.success),
      ),
      child: Column(
        children: [
           Text(
             loc.workApprovedRateAndRelease,
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => _showRatingDialog(currentCase),
            icon: const PhosphorIcon(PhosphorIconsRegular.star),
            label: Text(loc.rateAndReleasePayment),
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
    final loc = AppLocalizations.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.signalCompletionTitle),
        content: Text(loc.signalCompletionMessage),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(loc.cancel)),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(loc.signalWorkDone)),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await CaseService().signalWorkDone(currentCase.caseId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.completionSignalSentToClient)));
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${loc.error}: $e')));
      }
    }
  }

  Future<void> _verifyWork(CaseModel currentCase, bool isAccepted) async {
    final loc = AppLocalizations.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isAccepted ? loc.approveWorkTitle : loc.rejectCompletionTitle),
        content: Text(isAccepted 
          ? loc.approveWorkMessage 
          : loc.rejectCompletionMessage),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(loc.cancel)),
          FilledButton(
            onPressed: () => Navigator.pop(context, true), 
            style: isAccepted ? null : FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(isAccepted ? loc.yesApprove : loc.yesWorkPending),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await CaseService().verifyWork(currentCase.caseId, isAccepted);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(isAccepted ? loc.workApproved : loc.rejectionSentToLawyer),
            backgroundColor: isAccepted ? AppColors.success : AppColors.error,
          ));
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${loc.error}: $e')));
      }
    }
  }

  Future<void> _showRatingDialog(CaseModel currentCase) async {
    final loc = AppLocalizations.of(context);
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
          title: Text(loc.rateLawyerTitle),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ...ratings.keys.map((key) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_ratingLabel(key), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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
                  decoration: InputDecoration(
                    labelText: loc.writeReviewHint,
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(loc.cancel)),
            FilledButton(
              onPressed: () => Navigator.pop(context, true), 
              child: Text(loc.submitReviewAndContinue),
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
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${loc.failedToSubmitReview}: $e')));
      }
    }
  }

  Future<void> _showPaymentReleaseDialog(CaseModel currentCase) async {
    final loc = AppLocalizations.of(context);
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.releasePaymentTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(loc.releasePaymentDescription),
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
                  Text(loc.agreedAmountLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
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
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(loc.cancel)),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(loc.releasePaymentAction),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await CaseService().completeCase(currentCase.caseId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(loc.paymentReleasedAndCaseCompleted),
            backgroundColor: AppColors.success,
          ));
          // Case will automatically update in StreamBuilder and show completion state
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${loc.paymentFailed}: $e')));
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

  String _consultationStatusLabel(String status) {
    final loc = AppLocalizations.of(context);
    switch (status.toLowerCase()) {
      case 'pending':
        return loc.pendingStatus;
      case 'accepted':
        return loc.accept;
      case 'rejected':
        return loc.reject;
      default:
        return status.toUpperCase();
    }
  }

  String _eventStatusLabel(String status) {
    final loc = AppLocalizations.of(context);
    switch (status.toLowerCase()) {
      case 'upcoming':
        return loc.upcoming;
      case 'completed':
        return loc.completed;
      case 'cancelled':
        return loc.cancelled;
      default:
        return status.toUpperCase();
    }
  }

  String _invoiceStatusLabel(String status) {
    final loc = AppLocalizations.of(context);
    switch (status.toLowerCase()) {
      case 'paid':
        return loc.paid;
      case 'held':
        return loc.held;
      default:
        return loc.pendingStatus;
    }
  }

  String _ratingLabel(String key) {
    final loc = AppLocalizations.of(context);
    switch (key) {
      case 'Quality of Work':
        return loc.qualityOfWork;
      case 'Budget Adjustment':
        return loc.budgetAdjustment;
      case 'Way of Talking':
        return loc.wayOfTalking;
      case 'Promptness':
        return loc.promptness;
      case 'Expertise':
        return loc.expertise;
      default:
        return key;
    }
  }

  Widget _buildStatusRow(CaseModel currentCase) {
    final loc = AppLocalizations.of(context);
    Color statusColor;
    String statusText;

    switch (currentCase.status.toLowerCase()) {
      case 'active':
        statusColor = AppColors.success;
        statusText = loc.currentlyActiveWorkspace;
        break;
      case 'closed':
        statusColor = AppColors.error;
        statusText = loc.caseClosedCompleted;
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
              Text(
                loc.currentStatus,
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
    final loc = AppLocalizations.of(context);
    final consultationService = ConsultationService();

    return Column(
      children: [
        if (widget.caseModel.status != 'closed')
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: FilledButton.icon(
              onPressed: _showRequestConsultationSheet,
              icon: const PhosphorIcon(PhosphorIconsRegular.videoCamera),
              label: Text(loc.requestConsultation),
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
                return Center(child: Text('${loc.error}: ${snapshot.error}'));
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final consultations = snapshot.data ?? [];
              if (consultations.isEmpty) {
                return Center(
                  child: Text(
                    loc.noConsultationsScheduledYet,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textSecondary),
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
    final loc = AppLocalizations.of(context);
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isRequester = consult.requesterId == currentUserId;

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
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: AppColors.grey100)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: PhosphorIcon(
                        consult.type == 'video'
                            ? PhosphorIconsRegular.videoCamera
                            : PhosphorIconsRegular.usersThree,
                        color: AppColors.primary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  consult.type == 'video' ? loc.videoCall : loc.inPerson,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Text(
                                  _consultationStatusLabel(consult.status),
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${consult.scheduledAt.day}/${consult.scheduledAt.month}/${consult.scheduledAt.year} @ ${consult.scheduledAt.hour}:${consult.scheduledAt.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (consult.status == 'pending' && !isRequester)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.md),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () => _updateConsultationStatus(consult.id, 'rejected'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: const BorderSide(color: AppColors.error),
                            visualDensity: VisualDensity.compact,
                          ),
                          child: Text(loc.reject),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: () => _updateConsultationStatus(consult.id, 'accepted'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.success,
                            visualDensity: VisualDensity.compact,
                          ),
                          child: Text(loc.accept),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
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
    final loc = AppLocalizations.of(context);
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
              label: Text(_isUploadingFile ? loc.uploading : loc.uploadFile),
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
                return Center(child: Text('${loc.error}: ${snapshot.error}'));
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final dbFiles = snapshot.data ?? [];
              
              final initialFiles = widget.caseModel.attachments.map((att) => FileModel(
                id: 'initial_${att.fileUrl.hashCode}',
                caseId: widget.caseModel.caseId,
                uploaderId: widget.caseModel.clientId,
                fileName: att.title.isEmpty ? loc.originalAttachment : att.title,
                fileUrl: att.fileUrl,
                fileSize: 0,
                uploadedAt: widget.caseModel.createdAt,
              )).toList();

              final allFiles = [...initialFiles, ...dbFiles];

              if (allFiles.isEmpty) {
                return Center(
                  child: Text(
                    loc.noFilesSharedYet,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textSecondary),
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
                  
                  String uploaderLabel = '';
                  if (isInitial) {
                    uploaderLabel = loc.uploadedByClientInitial;
                  } else if (file.uploaderId == widget.caseModel.clientId) {
                    uploaderLabel = loc.uploadedByClient;
                  } else if (file.uploaderId == widget.caseModel.acceptedLawyerId) {
                    uploaderLabel = loc.uploadedByLawyer;
                  }

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(bottom: BorderSide(color: AppColors.grey100)),
                    ),
                    child: InkWell(
                      onTap: () => _openFile(file.fileUrl),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isInitial ? AppColors.primary.withValues(alpha: 0.1) : AppColors.grey100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: PhosphorIcon(
                              isInitial ? PhosphorIconsFill.shieldStar : PhosphorIconsRegular.file, 
                              color: AppColors.primary,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  file.fileName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isInitial 
                                    ? '${loc.originalAttachment} • ${file.uploadedAt.day}/${file.uploadedAt.month}/${file.uploadedAt.year}'
                                    : '${(file.fileSize / 1024).toStringAsFixed(1)} KB • $uploaderLabel',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'download') {
                                _openFile(file.fileUrl);
                              } else if (value == 'rename' && isMe) {
                                _renameFile(file);
                              } else if (value == 'delete' && isMe) {
                                _deleteFile(file);
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(value: 'download', child: const Text('Download')),
                              if (isMe) PopupMenuItem(value: 'rename', child: const Text('Rename')),
                              if (isMe) PopupMenuItem(value: 'delete', child: const Text('Delete')),
                            ],
                            child: const PhosphorIcon(PhosphorIconsRegular.dotsThreeVertical, size: 18),
                          ),
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

  Widget _buildEventsTab() {
    final loc = AppLocalizations.of(context);
    return Column(
      children: [
        if (!widget.isClient && widget.caseModel.status != 'closed')
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: FilledButton.icon(
              onPressed: _showAddEventDialog,
              icon: const PhosphorIcon(PhosphorIconsRegular.plusCircle),
              label: Text(loc.addEvent),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ),
        if (widget.isClient)
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                loc.onlyLawyerCanAddEvents,
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
                return Center(child: Text('${loc.error}: ${snapshot.error}'));
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final events = snapshot.data ?? [];
              if (events.isEmpty) {
                return Center(
                  child: Text(
                    loc.noCaseEventsYet,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textSecondary),
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

                  return Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(bottom: BorderSide(color: AppColors.grey100)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const PhosphorIcon(
                            PhosphorIconsRegular.calendarDots,
                            color: AppColors.primary,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                event.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                event.location?.isNotEmpty == true
                                    ? '${event.location} • $eventTime'
                                    : eventTime,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.info.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            _eventStatusLabel(event.status),
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: AppColors.info,
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
        ),
      ],
    );
  }

  Widget _buildMilestonesTab() {
    final loc = AppLocalizations.of(context);
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
              label: Text(loc.addMilestoneTask),
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
                return Center(child: Text('${loc.error}: ${snapshot.error}'));
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final milestones = snapshot.data ?? [];
              if (milestones.isEmpty) {
                return Center(
                  child: Text(
                    loc.noMilestonesYet,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textSecondary),
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
                      ? '${loc.due} ${milestone.dueDate!.day}/${milestone.dueDate!.month}/${milestone.dueDate!.year}'
                      : loc.noDueDate;
                  final canToggle = canEdit && currentUserId != null && !isPaidMilestone;

                  return Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(bottom: BorderSide(color: AppColors.grey100)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: isCompleted
                                    ? AppColors.success.withValues(alpha: 0.1)
                                    : AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: PhosphorIcon(
                                isCompleted
                                    ? PhosphorIconsFill.checkCircle
                                    : PhosphorIconsRegular.circle,
                                color: isCompleted ? AppColors.success : AppColors.primary,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    milestone.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      decoration: isCompleted ? TextDecoration.lineThrough : null,
                                      color: isCompleted ? AppColors.textSecondary : null,
                                    ),
                                  ),
                                  if (milestone.details.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text(
                                        milestone.details,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      dueText,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: AppColors.textLight,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            if (hasPayment)
                              Padding(
                                padding: const EdgeInsets.only(right: AppSpacing.sm),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'PKR ${milestone.paymentAmount.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                        color: isCompleted ? AppColors.success : AppColors.primary,
                                      ),
                                    ),
                                    Text(
                                      isPaidMilestone ? loc.paid : (milestone.status == 'held' ? 'Held' : 'Pending'),
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: isPaidMilestone ? AppColors.success : AppColors.warning,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (canToggle)
                              GestureDetector(
                                onTap: () => _toggleMilestoneStatus(
                                  milestone,
                                  isCompleted ? 'pending' : 'completed',
                                ),
                                child: PhosphorIcon(
                                  isCompleted
                                      ? PhosphorIconsRegular.arrowCounterClockwise
                                      : PhosphorIconsRegular.check,
                                  color: isCompleted ? AppColors.warning : AppColors.success,
                                  size: 20,
                                ),
                              ),
                          ],
                        ),
                        if (hasPayment && currentUserId == widget.caseModel.clientId && widget.isClient)
                          Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.md),
                            child: Row(
                              children: [
                                if (isPaidMilestone)
                                  FilledButton.icon(
                                    onPressed: null,
                                    icon: const PhosphorIcon(PhosphorIconsRegular.creditCard, size: 16),
                                    label: Text(loc.paid),
                                    style: FilledButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  )
                                else if (milestone.status == 'held')
                                  FilledButton.icon(
                                    onPressed: _isPayingMilestone ? null : () async {
                                      setState(() => _isPayingMilestone = true);
                                      try {
                                        final opId = 'milestone_release_${milestone.id}_${DateTime.now().millisecondsSinceEpoch}';
                                        final holdOpId = milestone.holdOperationId;
                                        final lawyerId = widget.caseModel.acceptedLawyerId;
                                        if (holdOpId == null || holdOpId.isEmpty) {
                                          throw Exception('Hold operation not found');
                                        }
                                        if (lawyerId == null || lawyerId.isEmpty) {
                                          throw Exception('Lawyer not assigned to case');
                                        }

                                        await _walletService.releaseHeldFunds(
                                          fromUserId: widget.caseModel.clientId,
                                          toUserId: lawyerId,
                                          amount: milestone.paymentAmount,
                                          operationId: opId,
                                          releaseReason: 'Release milestone payment: ${milestone.title}',
                                          originalHoldOperationId: holdOpId,
                                        );

                                        await _milestoneService.markAsReleased(
                                          caseId: widget.caseModel.caseId,
                                          milestoneId: milestone.id,
                                          releaseOperationId: opId,
                                        );

                                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.paymentReleasedSuccessfully), backgroundColor: AppColors.success));
                                      } catch (e) {
                                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${loc.releaseFailed}: ${e.toString().replaceFirst("Exception: ", "")}'), backgroundColor: AppColors.error));
                                      } finally {
                                        if (mounted) setState(() => _isPayingMilestone = false);
                                      }
                                    },
                                    icon: _isPayingMilestone
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const PhosphorIcon(PhosphorIconsRegular.check, size: 16),
                                    label: Text(_isPayingMilestone ? loc.processing : loc.release),
                                    style: FilledButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  )
                                else
                                  FilledButton.icon(
                                    onPressed: _isPayingMilestone
                                        ? null
                                        : () => _payMilestone(milestone),
                                    icon: _isPayingMilestone
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const PhosphorIcon(PhosphorIconsRegular.creditCard, size: 16),
                                    label: Text(_isPayingMilestone ? loc.processing : loc.pay),
                                    style: FilledButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                      ],
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
    final loc = AppLocalizations.of(context);
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
              label: Text(loc.createInvoice),
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
                return Center(child: Text('${loc.error}: ${snapshot.error}'));
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final invoices = snapshot.data ?? [];
              if (invoices.isEmpty) {
                return Center(
                  child: Text(
                    loc.noInvoicesYet,
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
                  final isHeld = invoice.status == 'held';
                  final canMarkPaid = !isPaid && currentUserId != null &&
                      currentUserId == invoice.payerId;

                  return Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(bottom: BorderSide(color: AppColors.grey100)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    invoice.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${invoice.currency} ${invoice.amount.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: isPaid
                                    ? AppColors.success.withValues(alpha: 0.15)
                                      : isHeld
                                          ? AppColors.primary.withValues(alpha: 0.15)
                                          : AppColors.warning.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                _invoiceStatusLabel(invoice.status),
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: isPaid
                                    ? AppColors.success
                                    : isHeld
                                      ? AppColors.primary
                                      : AppColors.warning,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (invoice.notes.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.sm),
                            child: Text(
                              invoice.notes,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.sm),
                          child: Row(
                            children: [
                              Text(
                                invoice.dueDate != null
                                    ? '${loc.due}: ${invoice.dueDate!.day}/${invoice.dueDate!.month}/${invoice.dueDate!.year}'
                                    : loc.noDueDate,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textLight,
                                ),
                              ),
                              if (invoice.paidAt != null)
                                Padding(
                                  padding: const EdgeInsets.only(left: AppSpacing.md),
                                  child: Text(
                                    'Paid: ${invoice.paidAt!.day}/${invoice.paidAt!.month}/${invoice.paidAt!.year}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.success,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (canMarkPaid)
                          Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.md),
                            child: FilledButton.icon(
                              onPressed: () => _payInvoice(invoice),
                              icon: const PhosphorIcon(PhosphorIconsRegular.creditCard, size: 16),
                              label: Text(isHeld ? loc.release : loc.pay),
                              style: FilledButton.styleFrom(
                                visualDensity: VisualDensity.compact,
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
        ),
      ],
    );
  }

  Future<void> _showAddMilestoneDialog() async {
    final loc = AppLocalizations.of(context);
    final titleController = TextEditingController();
    final detailsController = TextEditingController();
    final paymentController = TextEditingController();
    DateTime? dueDate;
    bool isSubmitting = false;

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(loc.addMilestoneTask),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: loc.titleLabel,
                    hintText: loc.milestoneTitleHint,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: detailsController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: loc.detailsLabel,
                    hintText: loc.optionalTaskNotesHint,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: paymentController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: loc.paymentAmountPKRLabel,
                    hintText: loc.optionalLeaveEmptyIfNoPaymentRequired,
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
                          ? loc.setDueDateOptional
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
              child: Text(loc.cancel),
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
                          SnackBar(
                            content: Text(loc.taskTitleRequired),
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
                  : Text(loc.add),
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
    final loc = AppLocalizations.of(context);
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
      ? ' (${loc.due} ${dueDate.day}/${dueDate.month}/${dueDate.year})'
        : '';
    final message = '$title$dueText';

    await _notificationService.createBatchNotifications([
      AppNotification(
        id: '',
        userId: clientId,
        actorId: currentUserId,
        type: NotificationType.generic,
        title: loc.newMilestoneAdded,
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
        title: loc.newMilestoneAdded,
        message: message,
        referenceType: 'case_milestone',
        referenceId: widget.caseModel.caseId,
        payload: {'caseId': widget.caseModel.caseId},
        createdAt: DateTime.now(),
      ),
    ]);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.milestoneAddedSuccessfully)),
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
                ? loc.milestoneMarkedCompleted
                : loc.milestoneReopened,
          ),
        ),
      );
    }
  }

  Future<void> _showCreateInvoiceDialog() async {
    final loc = AppLocalizations.of(context);
    final titleController = TextEditingController();
    final notesController = TextEditingController();
    final amountController = TextEditingController();
    DateTime? dueDate;
    bool isSubmitting = false;

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(loc.createInvoice),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: loc.invoiceTitleLabel,
                    hintText: loc.invoiceTitleHint,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: loc.amountPKRLabel,
                    hintText: loc.amountHint,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: notesController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: loc.notesLabel,
                    hintText: loc.optionalPaymentDetailsHint,
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
                          ? loc.setDueDateOptional
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
              child: Text(loc.cancel),
            ),
            FilledButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      final amount = double.tryParse(amountController.text.trim()) ?? 0;
                      if (titleController.text.trim().isEmpty || amount <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(loc.titleAndValidAmountRequired),
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
    final loc = AppLocalizations.of(context);
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
        title: loc.newInvoiceCreated,
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
        title: loc.invoiceSentToClient,
        message: '$title - PKR ${amount.toStringAsFixed(0)}',
        referenceType: 'case_invoice',
        referenceId: widget.caseModel.caseId,
        payload: {'caseId': widget.caseModel.caseId},
        createdAt: DateTime.now(),
      ),
    ]);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.invoiceCreatedSuccessfully)),
      );
    }
  }

  Future<void> _payInvoice(CaseInvoiceModel invoice) async {
    final loc = AppLocalizations.of(context);
    final lawyerId = widget.caseModel.acceptedLawyerId;
    final clientId = widget.caseModel.clientId;
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    if (lawyerId == null || lawyerId.isEmpty || currentUserId == null) return;

    if (currentUserId != invoice.payerId) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.onlyPayerCanMarkInvoicePaid)),
        );
      }
      return;
    }

    if (mounted) setState(() => _isPayingInvoice = true);
    try {
      if (invoice.status == 'held') {
        final holdOperationId = invoice.holdOperationId;
        if (holdOperationId == null || holdOperationId.isEmpty) {
          throw Exception('Invoice hold not found');
        }

        await _invoiceService.releaseInvoicePayment(
          caseId: widget.caseModel.caseId,
          invoiceId: invoice.id,
          currentUserId: currentUserId,
        );
      } else {
        final payerBalance = await _walletService.getWalletBalance(currentUserId);
        if (payerBalance < invoice.amount) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  loc.insufficientBalanceForInvoice(
                    payerBalance.toStringAsFixed(2),
                    invoice.amount.toStringAsFixed(2),
                  ),
                ),
                backgroundColor: AppColors.error,
              ),
            );
          }
          return;
        }

        await _invoiceService.payInvoice(
          caseId: widget.caseModel.caseId,
          invoiceId: invoice.id,
          currentUserId: currentUserId,
        );
      }

      // Best-effort notifications/logs: payment should still count as success if these fail.
      try {
        await _notificationService.createBatchNotifications([
          AppNotification(
            id: '',
            userId: clientId,
            actorId: clientId,
            type: NotificationType.paymentSuccess,
            title: invoice.status == 'held' ? loc.invoiceReleased : loc.invoiceHeld,
            message: invoice.status == 'held'
                ? loc.invoiceReleasedToLawyer(invoice.title)
                : loc.invoiceHeldInEscrow(invoice.title),
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
            title: invoice.status == 'held' ? loc.invoiceReleasedByClient : loc.invoicePaymentHeld,
            message: invoice.status == 'held'
              ? loc.invoiceReleasedByClientMessage(invoice.title)
              : loc.invoicePaymentHeldMessage(invoice.title),
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
            title: invoice.status == 'held' ? loc.invoiceReleased : loc.invoiceHeld,
            message: invoice.status == 'held'
                ? loc.invoiceReleaseCompleted(invoice.title)
                : loc.invoicePaymentHeldInEscrow(invoice.title),
            relatedId: widget.caseModel.caseId,
            timestamp: DateTime.now(),
          ),
        );

        await _recentUpdateService.addRecentUpdate(
          RecentUpdate(
            id: '',
            userId: lawyerId,
            type: UpdateType.paymentAccepted,
            title: invoice.status == 'held' ? loc.invoiceReleased : loc.invoicePaymentHeld,
            message: invoice.status == 'held'
                ? loc.invoiceMarkedReleasedInWorkspace(invoice.title)
                : loc.invoiceHeldInWorkspace(invoice.title),
            relatedId: widget.caseModel.caseId,
            timestamp: DateTime.now(),
          ),
        );
      } catch (_) {
        // Ignore post-payment side-effect failures.
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.invoiceUpdatedSuccessfully),
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
    } finally {
      if (mounted) setState(() => _isPayingInvoice = false);
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
    final loc = AppLocalizations.of(context);
    final lawyerId = widget.caseModel.acceptedLawyerId;
    final clientId = widget.caseModel.clientId;
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    if (lawyerId == null || lawyerId.isEmpty || currentUserId == null) return;

    if (currentUserId != clientId) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.onlyClientCanPayMilestone)),
        );
      }
      return;
    }

    if (milestone.status == 'paid') {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.milestoneAlreadyPaid)),
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
              loc.insufficientBalanceForMilestone(
                walletBalance.toStringAsFixed(2),
                milestone.paymentAmount.toStringAsFixed(2),
              ),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    if (mounted) setState(() => _isPayingMilestone = true);
    try {
      final opId = 'milestone_payment_${milestone.id}_${DateTime.now().millisecondsSinceEpoch}';
      // Hold funds in escrow from client
      await _walletService.holdFunds(
        userId: clientId,
        amount: milestone.paymentAmount,
        operationId: opId,
        reason: loc.milestonePaymentReason(milestone.title),
        referenceType: 'case_milestone',
        referenceId: milestone.id,
      );

      await _milestoneService.markAsHeld(
        caseId: widget.caseModel.caseId,
        milestoneId: milestone.id,
        holdOperationId: opId,
      );

      // Create notifications for both parties
      await _notificationService.createBatchNotifications([
        AppNotification(
          id: '',
          userId: clientId,
          actorId: clientId,
          type: NotificationType.paymentSuccess,
          title: loc.milestonePaymentHeld,
          message: loc.milestonePaymentHeldMessage(milestone.paymentAmount.toStringAsFixed(0), milestone.title),
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
          title: loc.milestonePaymentAwaitingRelease,
          message: loc.milestonePaymentAwaitingReleaseMessage(milestone.paymentAmount.toStringAsFixed(0), milestone.title),
          referenceType: 'case_milestone',
          referenceId: milestone.id,
          payload: {'caseId': widget.caseModel.caseId, 'milestoneId': milestone.id},
          createdAt: DateTime.now(),
        ),
      ]);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.milestonePaymentHeldInEscrow(milestone.paymentAmount.toStringAsFixed(0))),
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
              loc.paymentFailedWithDetails(e.toString().replaceFirst('Exception: ', '')),
            ),
            duration: const Duration(seconds: 3),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPayingMilestone = false);
    }
  }

  Future<void> _showAddEventDialog() async {
    if (widget.isClient) return;

    final loc = AppLocalizations.of(context);

    final nameController = TextEditingController();
    final placeController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = const TimeOfDay(hour: 10, minute: 0);
    bool isSubmitting = false;

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(loc.addCaseEvent),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: loc.eventNameLabel,
                    hintText: loc.eventNameHint,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: placeController,
                  decoration: InputDecoration(
                    labelText: loc.eventPlaceLabel,
                    hintText: loc.eventPlaceHint,
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
              child: Text(loc.cancel),
            ),
            FilledButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      final name = nameController.text.trim();
                      final place = placeController.text.trim();

                      if (name.isEmpty || place.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(loc.eventNameAndPlaceRequired),
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
                  : Text(loc.createEvent),
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
          SnackBar(
            content: Text(loc.cannotCreateEventForThisCase),
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
    final eventMessage = loc.caseEventMessage(eventName, place, eventTimeText);

    await _notificationService.createBatchNotifications([
      AppNotification(
        id: '',
        userId: clientId,
        actorId: lawyerId,
        type: NotificationType.generic,
        title: loc.newCaseEventAdded,
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
        title: loc.eventCreatedSuccessfully,
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
        title: loc.newEventScheduled,
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
        title: loc.eventAddedToCase,
        message: eventMessage,
        relatedId: widget.caseModel.caseId,
        timestamp: DateTime.now(),
      ),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.eventAddedAndUsersNotified),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _uploadFile() async {
    final loc = AppLocalizations.of(context);
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      // 1. Check file limit (max 3 files per party)
      final count = await FileService().getUserFileCount(widget.caseModel.caseId, userId);
      if (count >= 3) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(loc.uploadLimitReached),
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
            SnackBar(content: Text(loc.fileUploadedSuccessfully)),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${loc.errorUploadingFile}: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingFile = false);
      }
    }
  }

  Future<String?> _showFileNameDialog(String initialName) async {
    final loc = AppLocalizations.of(context);
    final controller = TextEditingController(text: initialName);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.nameYourFile),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: loc.fileNameLabel,
            hintText: loc.fileNameHint,
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(loc.upload),
          ),
        ],
      ),
    );
  }

  Future<void> _renameFile(FileModel file) async {
    final loc = AppLocalizations.of(context);
    final controller = TextEditingController(text: file.fileName);
    final String? newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.renameFile),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: loc.newNameLabel),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(loc.save),
          ),
        ],
      ),
    );

    if (newName != null && newName.trim().isNotEmpty && newName != file.fileName) {
      try {
        await FileService().updateFileName(widget.caseModel.caseId, file.id, newName.trim());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.fileRenamed)));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${loc.renameFailed}: $e')));
        }
      }
    }
  }

  Future<void> _deleteFile(FileModel file) async {
    final loc = AppLocalizations.of(context);
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (file.uploaderId != userId) return;

    // Confirm deletion
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.deleteFileTitle),
        content: Text(loc.deleteFileConfirm(file.fileName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(loc.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(loc.delete),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await FileService().deleteFile(widget.caseModel.caseId, file);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.fileDeleted)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${loc.deleteFailed}: $e')),
        );
      }
    }
  }

  Future<void> _openFile(String url) async {
    final loc = AppLocalizations.of(context);
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
          SnackBar(content: Text(loc.couldNotOpenFile)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${loc.errorOpeningFile}: $e')),
        );
      }
    }
  }

  Widget _buildInfoCard(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: AppColors.grey100, width: 1),
            ),
          ),
          child: content,
        ),
      ],
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
  final _note = '';
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 10, minute: 0);
  bool _isSubmitting = false;

  AppLocalizations get loc => AppLocalizations.of(context);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
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
          Text(
            loc.requestConsultation,
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
                  'video', loc.videoCall, PhosphorIconsRegular.videoCamera),
              const SizedBox(width: 8),
              _buildTypeChip(
                  'in_person', loc.inPerson, PhosphorIconsRegular.usersThree),
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
                    loc.meetingLocation,
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
                      loc.noLawyerOfficeLocationSet,
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
            SnackBar(
              content: Text(loc.selectedTimeAlreadyPassed),
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
            SnackBar(
              content: Text(loc.pleaseSelectFutureConsultationDateTime),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      final durationMinutes = 30;

      // Validate availability and conflicts before creating the consultation
      final availabilityService = LawyerAvailabilityService();
      final isAvailable = await availabilityService.isTimeWithinAvailability(
        widget.targetId,
        scheduledAt,
        durationMinutes,
      );
      if (!isAvailable) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(loc.selectedTimeOutsideLawyerAvailability),
              backgroundColor: AppColors.error,
            ),
          );
        }
        setState(() => _isSubmitting = false);
        return;
      }

      final hasConflict = await ConsultationService().checkTimeSlotConflict(
        widget.targetId,
        scheduledAt,
        durationMinutes,
      );
      if (hasConflict) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(loc.selectedTimeConflictsWithAnotherConsultation),
              backgroundColor: AppColors.error,
            ),
          );
        }
        setState(() => _isSubmitting = false);
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
        durationMinutes: durationMinutes,
        type: _type,
        lawyerOfficeLocation: _type == 'in_person' ? widget.lawyerOfficeLocation : null,
        status: 'pending',
        scheduledAt: scheduledAt,
        createdAt: DateTime.now(),
      );

      // Pass user's display name or use a default
      final requesterName = user.displayName ?? 'User';
      final requesterRole = widget.isClient ? loc.client : loc.lawyer;
      
      await ConsultationService().requestConsultation(consultation, requesterName, requesterRole);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.consultationRequestSent)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('${loc.error}: $e'), backgroundColor: AppColors.error),
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
        title: Text(loc.consultationLimitReached),
        content: Text(loc.consultationLimitReachedDescription),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.cancel),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(loc.paymentGatewayComingSoon)),
              );
            },
            child: Text(loc.payForOneMore),
          ),
        ],
      ),
    );
  }
}
