import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/auth_service.dart';
import '../models/job_opportunity.dart';
import '../models/proposal.dart';
import '../services/proposal_service.dart';
import 'widgets/proposal_card.dart';

/// Job Details Screen
class JobDetailsScreen extends StatefulWidget {
  final JobOpportunity job;

  const JobDetailsScreen({super.key, required this.job});

  @override
  State<JobDetailsScreen> createState() => _JobDetailsScreenState();
}

class _JobDetailsScreenState extends State<JobDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AuthService _authService = AuthService();
  final ProposalService _proposalService = ProposalService();

  Map<String, dynamic>? _clientData;
  bool _isLoadingClient = true;
  bool _isSubmitting = false;

  // Form Controllers
  final _bidController = TextEditingController();
  final _durationController = TextEditingController();
  final _coverLetterController = TextEditingController();

  AppLocalizations get loc => AppLocalizations.of(context);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchClientData();
  }

  Future<void> _fetchClientData() async {
    final data = await _authService.getUserData(widget.job.clientId);
    if (mounted) {
      setState(() {
        _clientData = data;
        _isLoadingClient = false;
      });
    }
  }

  Future<void> _submitProposal() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.pleaseLoginToSubmitProposal)),
      );
      return;
    }

    if (_bidController.text.isEmpty ||
        _durationController.text.isEmpty ||
        _coverLetterController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.pleaseFillAllFields)),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Fetch current lawyer data for name/image/rating
      final lawyerData = await _authService.getUserData(user.uid);
      if (!mounted) return;
      
      final lawyerName = lawyerData?['fullName'] ?? loc.lawyer;
      final lawyerImage = lawyerData?['photoUrl'] ??
          'https://api.dicebear.com/7.x/avataaars/png?seed=${user.uid}';
      final rating = (lawyerData?['rating'] ?? 0.0).toDouble();
      final city = lawyerData?['city'] ?? loc.unknown;

      await _proposalService.submitProposal(
        caseId: widget.job.id,
        lawyerId: user.uid,
        lawyerName: lawyerName,
        lawyerImage: lawyerImage,
        rating: rating,
        location: city,
        coverLetter: _coverLetterController.text,
        bidAmount: double.tryParse(_bidController.text) ?? 0.0,
        duration: _durationController.text,
      );
      
      if (!mounted) return;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.proposalSubmittedSuccessfully)),
        );
        // Clear form
        _bidController.clear();
        _durationController.clear();
        _coverLetterController.clear();
        // Switch to proposals tab to see it
        _tabController.animateTo(1);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${loc.error}: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _bidController.dispose();
    _durationController.dispose();
    _coverLetterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(loc.jobDetails),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: [
            Tab(text: loc.details),
            Tab(text: loc.proposals),
          ],
        ),
      ),
      body: StreamBuilder<List<Proposal>>(
          stream: _proposalService.getProposalsForCase(widget.job.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('${loc.error}: ${snapshot.error}'));
            }

            final proposals = snapshot.data ?? [];
            final currentUserId = FirebaseAuth.instance.currentUser?.uid;

            // Find if current user has submitted a proposal
            Proposal? myProposal;
            try {
              myProposal =
                  proposals.firstWhere((p) => p.lawyerId == currentUserId);
            } catch (e) {
              myProposal = null;
            }

            return TabBarView(
              controller: _tabController,
              children: [
                _buildDetailsTab(myProposal),
                _buildProposalsTab(proposals),
              ],
            );
          }),
    );
  }

  Widget _buildDetailsTab(Proposal? myProposal) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Job Header
          Text(
            widget.job.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              _InfoChip(
                  label: widget.job.budgetLabel, color: AppColors.success),
              const SizedBox(width: AppSpacing.sm),
              _InfoChip(label: widget.job.category, color: AppColors.secondary),
              const SizedBox(width: AppSpacing.sm),
              Text(
                widget.job.postedAgo,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Client Info
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.grey200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  Text(
                    loc.aboutTheClient,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                if (_isLoadingClient)
                  const Center(child: CircularProgressIndicator())
                else
                  Row(
                    children: [
                      // Using a generic avatar if photoUrl is missing or private
                      CircleAvatar(
                        backgroundImage: NetworkImage(_clientData?[
                                'photoUrl'] ??
                            'https://api.dicebear.com/7.x/avataaars/png?seed=${widget.job.clientId}'),
                        radius: 20,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _clientData?['city'] ??
                                widget.job.location, // Fallback to job location
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                                  Text(
                                    _clientData?['createdAt'] != null
                                        ? loc.joined(DateFormat.yMMMd().format((_clientData!['createdAt'] as Timestamp).toDate()))
                                        : loc.memberSince2024,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Description
          Text(
            loc.jobDescription,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            widget.job.description,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Attachments
          if (widget.job.attachments.isNotEmpty) ...[
            Text(
              loc.attachments,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ...widget.job.attachments.map((doc) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Row(
                    children: [
                      const Icon(Icons.attach_file,
                          size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        doc,
                        style: const TextStyle(
                          color: AppColors.primary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: AppSpacing.xl),
          ],

          const Divider(),
          const SizedBox(height: AppSpacing.lg),

          // Conditional UI: Form or Existing Proposal
          if (myProposal != null) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                    Row(
                    children: [
                      Icon(Icons.check_circle, color: AppColors.success),
                      SizedBox(width: 8),
                      Text(loc.proposalSubmitted,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.success)),
                    ],
                  ),
                  const SizedBox(height: 8),
                    Text(loc.proposalAlreadySubmitted,
                      style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 13)),
                  const SizedBox(height: 16),
                  ProposalCard(
                    proposal: myProposal,
                    caseId: widget.job.id,
                    onEdit: () => _showEditProposalDialog(myProposal),
                    onDelete: () => _confirmDeleteProposal(myProposal),
                  ),
                ],
              ),
            )
          ] else ...[
            Text(
              loc.submitAProposal,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _bidController,
                    label: loc.bidAmountPkr,
                    hint: loc.example50000,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _buildTextField(
                    controller: _durationController,
                    label: loc.duration,
                    hint: loc.example7Days,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _buildTextField(
              controller: _coverLetterController,
              label: loc.coverLetter,
              hint: loc.describeWhyYouAreBestFit,
              maxLines: 4,
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitProposal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Text(loc.submitProposal,
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.textLight),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: const BorderSide(color: AppColors.grey300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: const BorderSide(color: AppColors.grey300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
      ],
    );
  }

  Widget _buildProposalsTab(List<Proposal> proposals) {
    if (proposals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.description_outlined,
                size: 48, color: AppColors.grey300),
            const SizedBox(height: 16),
              Text(
                loc.noProposalsYet,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              loc.beTheFirstToSubmit,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textLight,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: proposals.length,
      itemBuilder: (context, index) {
        final proposal = proposals[index];
        return ProposalCard(
          proposal: proposal,
          caseId: widget.job.id,
          onDelete: () => _confirmDeleteProposal(proposal),
          onEdit: () => _showEditProposalDialog(proposal),
        );
      },
    );
  }

  // --- Actions ---

  Future<void> _confirmDeleteProposal(Proposal proposal) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.deleteProposal),
        content: Text(loc.deleteProposalConfirm),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(loc.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(loc.delete),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _proposalService.deleteProposal(widget.job.id, proposal.id);
        if (!mounted) return;
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(loc.proposalDeleted)));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('${loc.error}: $e')));
        }
      }
    }
  }

  void _showEditProposalDialog(Proposal proposal) {
    final editBidCtrl =
        TextEditingController(text: proposal.bidAmount.toInt().toString());
    final editDurationCtrl = TextEditingController(text: proposal.duration);
    final editCoverCtrl = TextEditingController(text: proposal.coverLetter);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.editProposal),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(
                  controller: editBidCtrl,
                  label: 'Bid Amount',
                  hint: 'e.g 50000',
                  keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              _buildTextField(
                  controller: editDurationCtrl,
                  label: 'Duration',
                  hint: 'e.g 7 Days'),
              const SizedBox(height: 16),
              _buildTextField(
                  controller: editCoverCtrl,
                  label: 'Cover Letter',
                  hint: '',
                  maxLines: 3),
            ],
          ),
        ),
        actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(loc.cancel)),
          ElevatedButton(
              onPressed: () async {
                try {
                  await _proposalService.updateProposal(
                      caseId: widget.job.id,
                      proposalId: proposal.id,
                      coverLetter: editCoverCtrl.text,
                      bidAmount: double.tryParse(editBidCtrl.text) ??
                          proposal.bidAmount,
                      duration: editDurationCtrl.text);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(loc.proposalUpdated)));
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text('${loc.error}: $e')));
                  }
                }
              },
                child: Text(loc.saveChanges)),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final Color color;

  const _InfoChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
