import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../../cases/models/case_model.dart';
import '../../cases/services/case_service.dart';
import '../../jobs/models/proposal.dart';
import '../../jobs/services/proposal_service.dart';
import 'widgets/client_proposal_card.dart';
import 'active_case_workspace_screen.dart';
import '../../chat/services/chat_service.dart';
import '../../../core/services/auth_service.dart';

class ClientCaseAdDetailsScreen extends StatefulWidget {
  final CaseModel caseModel;

  const ClientCaseAdDetailsScreen({super.key, required this.caseModel});

  @override
  State<ClientCaseAdDetailsScreen> createState() =>
      _ClientCaseAdDetailsScreenState();
}

class _ClientCaseAdDetailsScreenState extends State<ClientCaseAdDetailsScreen> {
  late bool _isAdVisible;
  late List<CaseAttachment> _attachments;
  bool _isLoading = false;
  late int _viewsCount;
  bool _hasIncrementedViews = false;

  @override
  void initState() {
    super.initState();
    _isAdVisible = widget.caseModel.isAdVisible;
    _attachments = List.from(widget.caseModel.attachments);
    _viewsCount = widget.caseModel.viewsCount;
    _incrementViewsOnce();
  }

  Future<void> _incrementViewsOnce() async {
    if (_hasIncrementedViews) return;
    _hasIncrementedViews = true;

    try {
      await CaseService().incrementViewCount(widget.caseModel.caseId);
      if (!mounted) return;
      setState(() {
        _viewsCount += 1;
      });
    } catch (_) {
      // Keep the screen usable even if the analytics update fails.
    }
  }

  @override
  Widget build(BuildContext context) {
    // If case is active (proposal accepted) or completed, show the Workspace instead of Ad Manager
    if (widget.caseModel.status == 'active' || widget.caseModel.status == 'closed') {
      return ActiveCaseWorkspaceScreen(
        caseModel: widget.caseModel,
        isClient: true,
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text('Case Management'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Details'),
              Tab(text: 'Proposals'),
            ],
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
          ),
          actions: [
            // Edit Button (FAB alternative in AppBar)
            TextButton.icon(
              onPressed: () {
                context.push('/edit-case', extra: widget.caseModel);
              },
              icon: const PhosphorIcon(PhosphorIconsRegular.pencilSimple,
                  size: 20),
              label: const Text('Edit'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
            ),
          ],
        ),
        body: TabBarView(
          children: [
            // Tab 1: Case Details
            _buildDetailsTab(context),
            // Tab 2: Proposals List
            _buildProposalsTab(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Status & Toggle Card
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.md),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: _isAdVisible
                        ? Colors.black.withValues(alpha: 0.1)
                        : AppColors.grey300.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: PhosphorIcon(
                    _isAdVisible
                        ? PhosphorIconsRegular.checkCircle
                        : PhosphorIconsRegular.pauseCircle,
                    color:
                        _isAdVisible ? Colors.black : AppColors.textSecondary,
                    size: 32,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isAdVisible ? 'Ad is Active' : 'Ad is Paused',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: _isAdVisible
                                      ? Colors.black
                                      : AppColors.textSecondary,
                                ),
                      ),
                      Text(
                        _isAdVisible
                            ? 'Lawyers can find and view your case.'
                            : 'Your case is hidden from the job board.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _isAdVisible,
                  activeThumbColor: Colors.black,
                  activeTrackColor: Colors.grey.withValues(alpha: 0.3),
                  inactiveThumbColor: Colors.white,
                  inactiveTrackColor: Colors.black.withValues(alpha: 0.1),
                  onChanged: (value) async {
                    setState(() {
                      _isAdVisible = value;
                    });
                    try {
                      await CaseService()
                          .toggleAdVisibility(widget.caseModel.caseId, value);
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                      setState(() => _isAdVisible = !value); // Revert
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // 2. Analytics Grid
          Text(
            'Performance Analytics',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              _AnalyticsCard(
                label: 'Views',
                value: _viewsCount.toString(),
                icon: PhosphorIconsRegular.eye,
                color: Colors.blue,
              ),
              const SizedBox(width: AppSpacing.md),
              _AnalyticsCard(
                label: 'Proposals',
                value: widget.caseModel.proposalCount.toString(),
                icon: PhosphorIconsRegular.paperPlaneRight,
                color: Colors.orange,
              ),
            ],
          ),
          // Insight Tip
          if (_viewsCount > 10 &&
              widget.caseModel.proposalCount == 0)
            Container(
              margin: const EdgeInsets.only(top: AppSpacing.md),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  PhosphorIcon(PhosphorIconsRegular.lightbulb,
                      color: Colors.amber[800]),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      "Many lawyers are viewing your case but not applying. Consider increasing your budget range to attract more proposals.",
                      style: TextStyle(color: Colors.amber[900], fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: AppSpacing.xl),

          // 3. Document Management
          _buildDocumentSection(context),

          const SizedBox(height: AppSpacing.xl),

          // 4. Case Details Preview
          Text(
            'Case Details',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.grey200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DetailRow(label: 'Title', value: widget.caseModel.title),
                const Divider(height: 24),
                _DetailRow(
                    label: 'Budget',
                    value:
                        'PKR ${widget.caseModel.budgetMin.toInt()} - ${widget.caseModel.budgetMax.toInt()}'),
                const Divider(height: 24),
                _DetailRow(label: 'Location', value: widget.caseModel.city),
                const Divider(height: 24),
                const Text(
                  'Description',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.caseModel.description,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProposalsTab(BuildContext context) {
    final proposalService = ProposalService();
    return StreamBuilder<List<Proposal>>(
      stream: proposalService.getProposalsForCase(widget.caseModel.caseId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final proposals = snapshot.data ?? [];

        if (proposals.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                PhosphorIcon(PhosphorIconsRegular.paperPlaneTilt,
                    size: 64, color: AppColors.textLight),
                SizedBox(height: AppSpacing.md),
                Text(
                  'No proposals yet',
                  style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
                SizedBox(height: AppSpacing.sm),
                Text(
                  'Wait for lawyers to apply to your case.',
                  style: TextStyle(color: AppColors.textLight),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: proposals.length,
          itemBuilder: (context, index) {
            final proposal = proposals[index];
            return ClientProposalCard(
              proposal: proposal,
              onAccept: () => _acceptProposal(proposal),
              onReject: () => _rejectProposal(proposal),
              onUnreject: () => _unrejectProposal(proposal),
              onMessage: () => _handleMessageLawyer(proposal),
              onViewProfile: () => _handleViewProfile(proposal.lawyerId),
            );
          },
        );
      },
    );
  }

  Future<void> _acceptProposal(Proposal proposal) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Accept Proposal?'),
        content: Text(
          'Are you sure you want to accept ${proposal.lawyerName}\'s proposal?\n\nThis will automatically reject all other proposals for this case.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Accept & Hire'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!mounted) return;
      try {
        await ProposalService()
            .acceptProposal(widget.caseModel.caseId, proposal.id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Proposal accepted! Others rejected.'),
            backgroundColor: AppColors.success,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error accepting proposal: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _rejectProposal(Proposal proposal) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Proposal?'),
        content: Text(
          'Are you sure you want to reject ${proposal.lawyerName}\'s proposal?',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!mounted) return;
      try {
        await ProposalService()
            .rejectProposal(widget.caseModel.caseId, proposal.id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Proposal rejected.')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error rejecting proposal: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _unrejectProposal(Proposal proposal) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Undo Rejection?'),
        content: Text(
          'Do you want to move ${proposal.lawyerName}\'s proposal back to pending?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Undo Rejection'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!mounted) return;
      try {
        await ProposalService()
            .unrejectProposal(widget.caseModel.caseId, proposal.id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Proposal returned to pending.')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error undoing rejection: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _handleMessageLawyer(Proposal proposal) async {
    final authService = AuthService();
    final chatService = ChatService();
    final currentUser = authService.currentUser;

    if (currentUser == null) return;

    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Fetch client profile for name
      final clientData = await authService.getUserData(currentUser.uid);
      final clientName = clientData?['fullName'] ?? 'Client';
      final clientAvatar = clientData?['photoUrl'];

      // Get or create chat
      final chat = await chatService.getOrCreateChat(
        clientId: currentUser.uid,
        lawyerId: proposal.lawyerId,
        clientName: clientName,
        lawyerName: proposal.lawyerName,
        clientAvatar: clientAvatar,
        lawyerAvatar: proposal.lawyerImage,
      );

      if (!mounted) return;
      // Pop loading
      Navigator.pop(context);

      // Navigate to chat
      context.push('/chat/${chat.id}', extra: {
        'lawyerId': proposal.lawyerId,
        'lawyerName': proposal.lawyerName,
        'lawyerAvatar': proposal.lawyerImage,
      });
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Pop loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error starting chat: $e')),
      );
    }
  }

  void _handleViewProfile(String lawyerId) {
    context.push('/lawyer-profile/$lawyerId');
  }

  Widget _buildDocumentSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Attached Documents',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
            ),
            if (!_isLoading)
              TextButton.icon(
                onPressed: _addDocument,
                icon: const PhosphorIcon(PhosphorIconsRegular.plus, size: 16),
                label: const Text('Add'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.secondary,
                  visualDensity: VisualDensity.compact,
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (_attachments.isEmpty)
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.grey200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const PhosphorIcon(PhosphorIconsRegular.file,
                    color: AppColors.textLight),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'No documents attached',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          )
        else
          ..._attachments.map((attachment) => _buildAttachmentCard(attachment)),
      ],
    );
  }

  Widget _buildAttachmentCard(CaseAttachment attachment) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: PhosphorIcon(
              _getFileIcon(attachment.fileType),
              color: AppColors.secondary,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attachment.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  attachment.fileType.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const PhosphorIcon(PhosphorIconsRegular.dotsThreeVertical,
                color: AppColors.textSecondary),
            onSelected: (value) {
              switch (value) {
                case 'download':
                  _downloadDocument(attachment);
                  break;
                case 'rename':
                  _renameDocument(attachment);
                  break;
                case 'delete':
                  _deleteDocument(attachment);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'download',
                child: Row(
                  children: [
                    Icon(Icons.download, size: 18),
                    SizedBox(width: 8),
                    Text('Download'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'rename',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 18),
                    SizedBox(width: 8),
                    Text('Rename'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red, size: 18),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  PhosphorIconData _getFileIcon(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'pdf':
        return PhosphorIconsRegular.filePdf;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return PhosphorIconsRegular.fileImage;
      case 'doc':
      case 'docx':
        return PhosphorIconsRegular.fileDoc;
      default:
        return PhosphorIconsRegular.file;
    }
  }

  Future<void> _addDocument() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();

      if (result != null && result.files.single.path != null) {
        File file = File(result.files.single.path!);
        String fileName = result.files.single.name;

        // Ask for Title
        if (!context.mounted) return;
        String? title = await showDialog<String>(
          context: context,
          builder: (context) {
            String tempTitle = fileName;
            return AlertDialog(
              title: const Text('Document Title'),
              content: TextFormField(
                initialValue: tempTitle,
                decoration: const InputDecoration(labelText: 'Title'),
                onChanged: (value) => tempTitle = value,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, tempTitle),
                  child: const Text('Upload'),
                ),
              ],
            );
          },
        );

        if (title != null && title.isNotEmpty) {
          if (!mounted) return;
          setState(() => _isLoading = true);
          await CaseService()
              .addAttachment(widget.caseModel.caseId, file, title);

          // Refresh list locally
          final updatedCases = await CaseService()
              .getCasesForClient(widget.caseModel.clientId)
              .first;
          final updatedCase = updatedCases
              .firstWhere((c) => c.caseId == widget.caseModel.caseId);

          if (!mounted) return;
          setState(() {
            _attachments = updatedCase.attachments;
            _isLoading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Document uploaded successfully')),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading document: $e')),
      );
    }
  }

  Future<void> _deleteDocument(CaseAttachment attachment) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Document?'),
        content: Text('Are you sure you want to delete "${attachment.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (!mounted) return;
      setState(() => _isLoading = true);
      try {
        await CaseService()
            .deleteAttachment(widget.caseModel.caseId, attachment);
        if (!mounted) return;
        setState(() {
          _attachments.remove(attachment);
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document deleted')),
        );
      } catch (e) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting document: $e')),
        );
      }
    }
  }

  Future<void> _renameDocument(CaseAttachment attachment) async {
    String? newTitle = await showDialog<String>(
      context: context,
      builder: (context) {
        String tempTitle = attachment.title;
        return AlertDialog(
          title: const Text('Rename Document'),
          content: TextFormField(
            initialValue: tempTitle,
            decoration: const InputDecoration(labelText: 'New Title'),
            onChanged: (value) => tempTitle = value,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, tempTitle),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (newTitle != null &&
        newTitle.isNotEmpty &&
        newTitle != attachment.title) {
      if (!mounted) return;
      setState(() => _isLoading = true);
      try {
        await CaseService().updateAttachmentTitle(
            widget.caseModel.caseId, attachment, newTitle);

        // Refresh local state
        final index = _attachments.indexOf(attachment);
        if (!mounted) return;
        if (index != -1) {
          final newAttachment = CaseAttachment(
            title: newTitle,
            fileUrl: attachment.fileUrl,
            fileType: attachment.fileType,
          );
          setState(() {
            _attachments[index] = newAttachment;
            _isLoading = false;
          });
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document renamed')),
        );
      } catch (e) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error renaming document: $e')),
        );
      }
    }
  }

  Future<void> _downloadDocument(CaseAttachment attachment) async {
    final Uri url = Uri.parse(attachment.fileUrl);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch document URL')),
      );
    }
  }
}

class _AnalyticsCard extends StatelessWidget {
  final String label;
  final String value;
  final PhosphorIconData icon;
  final Color color;

  const _AnalyticsCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.lg, horizontal: AppSpacing.sm),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.grey200),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: PhosphorIcon(icon, color: color, size: 20),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}
