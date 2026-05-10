import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/auth_service.dart';
import '../../cases/services/case_service.dart';
import '../../wallet/services/wallet_service.dart';
import 'package:zakoota/l10n/app_localizations.dart';

/// Create Case Screen - Post a new legal case to marketplace
class CreateCaseScreen extends StatefulWidget {
  const CreateCaseScreen({super.key});

  @override
  State<CreateCaseScreen> createState() => _CreateCaseScreenState();
}

class _CreateCaseScreenState extends State<CreateCaseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _cityController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _budgetController = TextEditingController();
  final _caseService = CaseService();
  final _authService = AuthService();
  final _walletService = WalletService();

  String? _selectedCategory;
  final List<String> _categories = [
    'Criminal',
    'Civil',
    'Family',
    'Corporate',
    'Property',
  ];

  String _meetingPreference = 'in_person'; // Default
  // Each item is { 'file': File, 'title': String, 'controller': TextEditingController }
  final List<Map<String, dynamic>> _attachedFiles = [];
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _cityController.dispose();
    _descriptionController.dispose();
    _budgetController.dispose();
    for (var attachment in _attachedFiles) {
      (attachment['controller'] as TextEditingController).dispose();
    }
    super.dispose();
  }

  Future<void> _pickFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
      );

      if (result != null) {
        setState(() {
          for (var path in result.paths) {
            if (path != null) {
              File file = File(path);
              String fileName = file.path.split(Platform.pathSeparator).last;
              _attachedFiles.add({
                'file': file,
                'title': fileName, // Default title is filename
                'controller': TextEditingController(text: fileName),
              });
            }
          }
        });
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error picking files: $e')));
    }
  }

  void _removeFile(int index) {
    setState(() {
      final attachment = _attachedFiles.removeAt(index);
      (attachment['controller'] as TextEditingController).dispose();
    });
  }

  Future<void> _submitCase() async {
    if (!_formKey.currentState!.validate()) return;

    for (var attachment in _attachedFiles) {
      String title = (attachment['controller'] as TextEditingController).text.trim();
      if (title.isEmpty) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please provide a title for all attachments.')));
        return;
      }
      attachment['title'] = title;
    }

    final user = _authService.currentUser;
    if (user == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You must be logged in to post a case.')));
      return;
    }

    setState(() => _isSubmitting = true);
    String? holdOperationId;

    try {
      final double budget = _budgetController.text.isNotEmpty ? double.tryParse(_budgetController.text) ?? 0.0 : 0.0;

      if (budget > 0) {
        holdOperationId = 'case_post_${user.uid}_${DateTime.now().millisecondsSinceEpoch}';
        await _walletService.holdFunds(
          userId: user.uid,
          amount: budget,
          operationId: holdOperationId,
          reason: 'case_posting_hold',
          referenceType: 'case_posting',
          referenceId: holdOperationId,
          metadata: {
            'title': _titleController.text.trim(),
            'category': _selectedCategory,
          },
        );
      }

      final serviceAttachments = _attachedFiles.map((a) => {'file': a['file'], 'title': a['title']}).toList();

      await _caseService.createCase(
        clientId: user.uid,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory!,
        city: _cityController.text.trim(),
        budgetMin: budget,
        budgetMax: budget,
        meetingPreference: _meetingPreference,
        attachments: serviceAttachments,
        heldAmount: budget > 0 ? budget : null,
        paymentStatus: budget > 0 ? 'held' : 'none',
        holdOperationId: holdOperationId,
      );

      if (!context.mounted) return;

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => _SuccessDialog(),
      );

      if (!context.mounted) return;
      context.go('/client-cases');
    } catch (e) {
      if (holdOperationId != null) {
        try {
          final budget = double.tryParse(_budgetController.text) ?? 0.0;
          if (budget > 0) {
            await _walletService.refundHeldFunds(
              userId: user.uid,
              amount: budget,
              operationId: '${holdOperationId}_refund',
              originalHoldOperationId: holdOperationId,
              refundReason: 'case_posting_refund',
            );
          }
        } catch (_) {}
      }
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to post case: $e'), backgroundColor: AppColors.error));
    } finally {
      if (context.mounted) setState(() => _isSubmitting = false);
    }
  }

  // Common Input Decoration for premium feel
  InputDecoration _buildInputDecoration({required String label, required String hint, required PhosphorIconData icon}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: AppColors.surface,
      prefixIcon: PhosphorIcon(icon, color: AppColors.primary.withValues(alpha: 0.5), size: 20),
      labelStyle: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500),
      floatingLabelStyle: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        borderSide: BorderSide(color: AppColors.grey200, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        borderSide: BorderSide(color: AppColors.grey200, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        borderSide: const BorderSide(color: AppColors.error, width: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final loc = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.05), shape: BoxShape.circle),
          child: IconButton(
            icon: const PhosphorIcon(PhosphorIconsRegular.arrowLeft, size: 20),
            onPressed: () => context.pop(),
          ),
        ),
        title: Text(
          loc.postACase,
          style: textTheme.titleLarge?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w800, letterSpacing: -0.5),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Case Details Section Title
                    Text(
                      loc.caseDetails,
                      style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, color: AppColors.primary, letterSpacing: -0.5),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Case Title
                    TextFormField(
                      controller: _titleController,
                      decoration: _buildInputDecoration(
                        label: '${loc.caseTitleLabel} *',
                        hint: loc.caseTitleHint,
                        icon: PhosphorIconsRegular.textT,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return loc.pleaseEnterCaseTitle;
                        if (value.trim().length < 5) return loc.titleMinLength(5);
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Category Dropdown
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCategory,
                      decoration: _buildInputDecoration(
                        label: '${loc.categoryLabel} *',
                        hint: 'Select Category',
                        icon: PhosphorIconsRegular.folder,
                      ),
                      icon: const PhosphorIcon(PhosphorIconsRegular.caretDown, size: 16, color: AppColors.textSecondary),
                      items: _categories.map((category) => DropdownMenuItem(value: category, child: Text(category))).toList(),
                      onChanged: (value) => setState(() => _selectedCategory = value),
                      validator: (value) => value == null || value.isEmpty ? loc.pleaseSelectCategory : null,
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // City / Location
                    TextFormField(
                      controller: _cityController,
                      decoration: _buildInputDecoration(
                        label: '${loc.cityLabel} *',
                        hint: loc.cityHint,
                        icon: PhosphorIconsRegular.mapPin,
                      ),
                      validator: (value) => value == null || value.trim().isEmpty ? loc.pleaseEnterCity : null,
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      minLines: 5,
                      maxLines: 8,
                      decoration: _buildInputDecoration(
                        label: '${loc.descriptionLabel} *',
                        hint: loc.descriptionHint,
                        icon: PhosphorIconsRegular.article,
                      ).copyWith(alignLabelWithHint: true),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return loc.pleaseDescribeCase;
                        if (value.trim().length < 50) return loc.descriptionMinLength(50);
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Budget Range
                    TextFormField(
                      controller: _budgetController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: _buildInputDecoration(
                        label: 'Budget (Required)',
                        hint: 'e.g., 50000',
                        icon: PhosphorIconsRegular.currencyCircleDollar,
                      ).copyWith(prefixText: 'PKR  ', prefixStyle: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
                      validator: (value) => value == null || value.trim().isEmpty ? 'Please enter a budget' : null,
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Meeting Preference
                    Text('Meeting Preference', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: AppColors.primary)),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(child: _buildChoiceCard(title: 'In-Person', subtitle: 'Visit Office', value: 'in_person', groupValue: _meetingPreference, onChanged: (v) => setState(() => _meetingPreference = v), icon: PhosphorIconsRegular.buildings)),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(child: _buildChoiceCard(title: 'Virtual', subtitle: 'Video Call', value: 'virtual', groupValue: _meetingPreference, onChanged: (v) => setState(() => _meetingPreference = v), icon: PhosphorIconsRegular.videoCamera)),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    // Documents Section
                    Text('Related Documents', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, color: AppColors.primary, letterSpacing: -0.5)),
                    const SizedBox(height: AppSpacing.xs),
                    Text('Upload FIRs, deeds, or any relevant files.', style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                    const SizedBox(height: AppSpacing.md),

                    // Upload Button
                    InkWell(
                      onTap: _pickFiles,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2), width: 1.5, style: BorderStyle.solid),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: AppColors.surface, shape: BoxShape.circle, border: Border.all(color: AppColors.grey200)),
                              child: const PhosphorIcon(PhosphorIconsRegular.uploadSimple, size: 28, color: AppColors.primary),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(loc.tapToUploadDocuments, style: textTheme.titleSmall?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            Text(loc.pdfWordImages, style: textTheme.labelSmall?.copyWith(color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Attached Files List
                    if (_attachedFiles.isNotEmpty) ...[
                      ...List.generate(_attachedFiles.length, (index) {
                        final attachment = _attachedFiles[index];
                        final controller = attachment['controller'] as TextEditingController;

                        return Container(
                          margin: const EdgeInsets.only(bottom: AppSpacing.md),
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                            border: Border.all(color: AppColors.grey200),
                            boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(AppRadius.md)),
                                child: const PhosphorIcon(PhosphorIconsRegular.fileText, size: 24, color: AppColors.primary),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    TextFormField(
                                      controller: controller,
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                      decoration: InputDecoration(
                                        labelText: 'Document Title',
                                        hintText: 'e.g., FIR Copy',
                                        isDense: true,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: BorderSide(color: AppColors.grey200)),
                                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: BorderSide(color: AppColors.grey200)),
                                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: const BorderSide(color: AppColors.primary)),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'File: ${attachment['file'].path.split(Platform.pathSeparator).last}',
                                      style: textTheme.labelSmall?.copyWith(color: AppColors.textLight),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              IconButton(
                                icon: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                                  child: const PhosphorIcon(PhosphorIconsRegular.trash, size: 18, color: AppColors.error),
                                ),
                                onPressed: () => _removeFile(index),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Action Bar
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.grey200)),
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSubmitting ? null : _submitCase,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.surface))
                      : Text(loc.postACase, style: textTheme.titleMedium?.copyWith(color: AppColors.surface, fontWeight: FontWeight.w800)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChoiceCard({
    required String title,
    required String subtitle,
    required String value,
    required String groupValue,
    required ValueChanged<String> onChanged,
    required PhosphorIconData icon,
  }) {
    final isSelected = value == groupValue;
    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.grey200, width: 1.5),
          boxShadow: isSelected ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4))] : [],
        ),
        child: Column(
          children: [
            PhosphorIcon(icon, color: isSelected ? AppColors.secondary : AppColors.primary, size: 28),
            const SizedBox(height: 12),
            Text(title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: isSelected ? AppColors.surface : AppColors.primary)),
            Text(subtitle, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: isSelected ? AppColors.surface.withValues(alpha: 0.8) : AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _SuccessDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      backgroundColor: AppColors.surface,
      contentPadding: const EdgeInsets.all(AppSpacing.xl),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: const PhosphorIcon(PhosphorIconsRegular.checkCircle, color: AppColors.success, size: 48),
          ),
          const SizedBox(height: AppSpacing.lg),
          const Text('Case Posted!', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: AppColors.primary)),
          const SizedBox(height: 8),
          const Text('Your case is now visible to lawyers in the marketplace.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              child: const Text('Go to My Cases'),
            ),
          ),
        ],
      ),
    );
  }
}
