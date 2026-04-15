import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/auth_service.dart';

class LawyerEditProfileScreen extends StatefulWidget {
  const LawyerEditProfileScreen({super.key});

  @override
  State<LawyerEditProfileScreen> createState() =>
      _LawyerEditProfileScreenState();
}

class _LawyerEditProfileScreenState extends State<LawyerEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  final _firestore = FirebaseFirestore.instance;
  final _imagePicker = ImagePicker();

  // Editable controllers
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _locationController = TextEditingController();
  final _phoneController = TextEditingController();

  // Read-only display vars
  String? _email;
  double _rating = 0.0;
  int _reviewsCount = 0;
  String _verificationStatus = '';
  Map<String, dynamic> _verificationDocuments = {};
  String? _cnicUrl;
  String? _selfieUrl;

  // State
  bool _isLoading = true;
  bool _isSaving = false;
  XFile? _newProfileImage;
  String? _currentPhotoUrl;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = _authService.currentUser;
      if (user == null) return;

      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        _nameController.text = data['fullName'] ?? '';
        _bioController.text = data['aboutMe'] ?? '';
        _locationController.text = data['location'] ?? '';
        _phoneController.text = data['phoneNumber'] ?? '';
        _currentPhotoUrl = data['photoUrl'];
        _email = data['email'] ?? user.email ?? '';
        _rating = (data['rating'] ?? 0.0).toDouble();
        _reviewsCount = (data['reviewsCount'] ?? 0).toInt();
        _verificationStatus = data['verificationStatus'] ?? '';
        _verificationDocuments =
            Map<String, dynamic>.from(data['verificationDocuments'] ?? {});
        _cnicUrl = data['cnicUrl'];
        _selfieUrl = data['selfieUrl'];
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
    } finally {
      if (context.mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1080,
        maxHeight: 1080,
      );
      if (pickedFile != null && context.mounted) setState(() => _newProfileImage = pickedFile);
    } catch (e) {
      _showSnack('Failed to pick image: $e', isError: true);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final user = _authService.currentUser;
      if (user == null) throw Exception('User not logged in');

      if (_newProfileImage != null) {
        await _authService.uploadProfilePhoto(user.uid, _newProfileImage!);
      }

      await _firestore.collection('users').doc(user.uid).update({
        'fullName': _nameController.text.trim(),
        'aboutMe': _bioController.text.trim(),
        'location': _locationController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!context.mounted) return;
      _showSnack('Profile updated successfully!');
      context.pop();
    } catch (e) {
      _showSnack('Failed to update profile: $e', isError: true);
    } finally {
      if (context.mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _submitChangeRequest(String category, String currentValue) async {
    final controller = TextEditingController(text: currentValue);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Request: Change $category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This information requires admin review. Submit a change request and we will review it shortly.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: 'New value for $category',
                border: const OutlineInputBorder(),
              ),
              maxLines: category == 'Bio' ? 3 : 1,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Submit Request'),
          ),
        ],
      ),
    );

    if (!context.mounted) return;
    if (result != null && result.isNotEmpty) {
      try {
        final user = _authService.currentUser!;
        await _firestore.collection('profile_change_requests').add({
          'userId': user.uid,
          'userRole': 'lawyer',
          'field': category,
          'requestedValue': result,
          'status': 'pending',
          'submittedAt': FieldValue.serverTimestamp(),
        });
        _showSnack('Request submitted! Admin will review your change.');
      } catch (e) {
        _showSnack('Failed to submit request: $e', isError: true);
      }
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppColors.error : AppColors.success,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const PhosphorIcon(PhosphorIconsRegular.arrowLeft),
          onPressed: () => context.pop(),
        ),
        title: const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Profile Photo ──────────────────────────────────
                    Center(
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Stack(
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.grey200,
                                border: Border.all(color: AppColors.primary, width: 2.5),
                                image: _newProfileImage != null
                                    ? DecorationImage(
                                        image: kIsWeb
                                            ? NetworkImage(_newProfileImage!.path)
                                            : FileImage(File(_newProfileImage!.path)) as ImageProvider,
                                        fit: BoxFit.cover,
                                      )
                                    : (_currentPhotoUrl != null
                                        ? DecorationImage(
                                            image: NetworkImage(_currentPhotoUrl!),
                                            fit: BoxFit.cover,
                                          )
                                        : null),
                              ),
                              child: (_newProfileImage == null && _currentPhotoUrl == null)
                                  ? const Icon(Icons.person, size: 50, color: AppColors.textLight)
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: const PhosphorIcon(PhosphorIconsRegular.camera, color: Colors.white, size: 16),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text('Tap to change photo',
                          style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                    ),

                    // Rating badge
                    const SizedBox(height: 12),
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded, color: AppColors.secondary, size: 18),
                          const SizedBox(width: 4),
                          Text('${_rating.toStringAsFixed(1)}  •  $_reviewsCount reviews',
                              style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // ── Editable Fields ───────────────────────────────
                    const _SectionHeader(title: 'Basic Information', icon: PhosphorIconsRegular.user),
                    const SizedBox(height: AppSpacing.sm),

                    _buildField(
                      label: 'Full Name',
                      controller: _nameController,
                      icon: PhosphorIconsRegular.user,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildField(
                      label: 'Phone Number',
                      controller: _phoneController,
                      icon: PhosphorIconsRegular.phone,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildField(
                      label: 'City / Location',
                      controller: _locationController,
                      icon: PhosphorIconsRegular.mapPin,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildField(
                      label: 'About Me (Bio)',
                      controller: _bioController,
                      icon: PhosphorIconsRegular.textT,
                      maxLines: 4,
                      hint: 'Tell clients about your expertise and approach...',
                    ),

                    // ── Read-only fields (locked) ─────────────────────
                    const SizedBox(height: AppSpacing.lg),
                    const _SectionHeader(title: 'Email', icon: PhosphorIconsRegular.envelope),
                    const SizedBox(height: AppSpacing.sm),
                    _buildLockedField(
                      label: 'Email Address',
                      value: _email ?? '',
                      icon: PhosphorIconsRegular.envelope,
                      note: 'Email cannot be changed.',
                    ),

                    // ── Admin-controlled fields ───────────────────────
                    const SizedBox(height: AppSpacing.lg),
                    const _SectionHeader(title: 'Professional Details', icon: PhosphorIconsRegular.briefcase),
                    const SizedBox(height: 4),
                    Text(
                      'These fields are verified by admin. Submit a change request to update them.',
                      style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    _buildRequestableField(
                      label: 'Years of Experience',
                      icon: PhosphorIconsRegular.briefcase,
                      onRequest: () => _submitChangeRequest('Years of Experience', ''),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _buildRequestableField(
                      label: 'Hourly Rate (PKR)',
                      icon: PhosphorIconsRegular.currencyDollar,
                      onRequest: () => _submitChangeRequest('Hourly Rate (PKR)', ''),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _buildRequestableField(
                      label: 'Practice Area / Specialization',
                      icon: PhosphorIconsRegular.scales,
                      onRequest: () => _submitChangeRequest('Practice Area / Specialization', ''),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _buildRequestableField(
                      label: 'Bar Council Number',
                      icon: PhosphorIconsRegular.identificationCard,
                      onRequest: () => _submitChangeRequest('Bar Council Number', ''),
                    ),

                    // ── Submitted Documents ───────────────────────────
                    const SizedBox(height: AppSpacing.lg),
                    const _SectionHeader(title: 'Submitted Documents', icon: PhosphorIconsRegular.files),
                    const SizedBox(height: 4),
                    Text(
                      'These are the documents you submitted during verification.',
                      style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    if (_cnicUrl != null)
                      _buildDocTile(label: 'CNIC / National ID', url: _cnicUrl!, icon: PhosphorIconsRegular.identificationCard),
                    if (_selfieUrl != null)
                      _buildDocTile(label: 'Selfie / Photo ID', url: _selfieUrl!, icon: PhosphorIconsRegular.camera),
                    ..._verificationDocuments.entries.map((e) =>
                      _buildDocTile(
                        label: _formatDocLabel(e.key),
                        url: e.value.toString(),
                        icon: PhosphorIconsRegular.filePdf,
                      ),
                    ),
                    if (_cnicUrl == null && _selfieUrl == null && _verificationDocuments.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.grey200,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Row(
                          children: [
                            const PhosphorIcon(PhosphorIconsRegular.warning, color: AppColors.warning, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'No documents submitted yet.',
                                style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // ── Verification Status ───────────────────────────
                    const SizedBox(height: AppSpacing.lg),
                    _buildVerificationStatusCard(),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ),
          ),

          // Save button
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.grey200)),
            ),
            child: SafeArea(
              child: SizedBox(
                height: 50,
                child: FilledButton.icon(
                  onPressed: _isSaving ? null : _saveProfile,
                  icon: _isSaving
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const PhosphorIcon(PhosphorIconsRegular.floppyDisk, size: 18),
                  label: Text(_isSaving ? 'Saving...' : 'Save Changes',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required PhosphorIconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? hint,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: PhosphorIcon(icon, color: AppColors.textSecondary, size: 18),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: const BorderSide(color: AppColors.grey300)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: const BorderSide(color: AppColors.grey300)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildLockedField({
    required String label,
    required String value,
    required PhosphorIconData icon,
    String? note,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.grey200,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.grey300),
          ),
          child: Row(
            children: [
              PhosphorIcon(icon, color: AppColors.textLight, size: 18),
              const SizedBox(width: 10),
              Expanded(child: Text(value, style: const TextStyle(color: AppColors.textSecondary))),
              const PhosphorIcon(PhosphorIconsRegular.lock, color: AppColors.textLight, size: 16),
            ],
          ),
        ),
        if (note != null) ...[
          const SizedBox(height: 4),
          Text(note, style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
        ],
      ],
    );
  }

  Widget _buildRequestableField({
    required String label,
    required PhosphorIconData icon,
    required VoidCallback onRequest,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.grey300),
      ),
      child: Row(
        children: [
          PhosphorIcon(icon, color: AppColors.textSecondary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
          ),
          OutlinedButton.icon(
            onPressed: onRequest,
            icon: const PhosphorIcon(PhosphorIconsRegular.pencilSimple, size: 13),
            label: const Text('Request', style: TextStyle(fontSize: 12)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocTile({required String label, required String url, required PhosphorIconData icon}) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.grey300),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(child: PhosphorIcon(icon, color: AppColors.primary, size: 18)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ),
          IconButton(
            icon: const PhosphorIcon(PhosphorIconsRegular.eye, color: AppColors.primary, size: 20),
            onPressed: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationStatusCard() {
    Color color;
    String label;
    PhosphorIconData icon;
    switch (_verificationStatus) {
      case 'approved':
        color = AppColors.success;
        label = 'Verified Account';
        icon = PhosphorIconsRegular.checkCircle;
        break;
      case 'pending_approval':
        color = AppColors.warning;
        label = 'Verification Pending Review';
        icon = PhosphorIconsRegular.clock;
        break;
      case 'rejected':
        color = AppColors.error;
        label = 'Verification Rejected';
        icon = PhosphorIconsRegular.xCircle;
        break;
      default:
        color = AppColors.textSecondary;
        label = 'Not Verified';
        icon = PhosphorIconsRegular.warning;
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          PhosphorIcon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Account Status', style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
                Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDocLabel(String key) {
    return key
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
        .join(' ');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final PhosphorIconData icon;
  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        PhosphorIcon(icon, color: AppColors.primary, size: 16),
        const SizedBox(width: 6),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary)),
        const SizedBox(width: 8),
        const Expanded(child: Divider()),
      ],
    );
  }
}
