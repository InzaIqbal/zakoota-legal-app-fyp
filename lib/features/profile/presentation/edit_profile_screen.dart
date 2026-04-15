import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/auth_service.dart';

/// Edit Profile Screen - Client
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  final _firestore = FirebaseFirestore.instance;
  final _imagePicker = ImagePicker();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _professionController = TextEditingController();
  final _ageController = TextEditingController();

  String? _email;
  String? _currentPhotoUrl;
  XFile? _newProfileImage;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final user = _authService.currentUser;
      if (user == null) return;

      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        _nameController.text = data['fullName'] ?? '';
        _phoneController.text = data['phoneNumber'] ?? data['phone'] ?? '';
        _addressController.text = data['address'] ?? '';
        _professionController.text = data['profession'] ?? '';
        _ageController.text = (data['age'] ?? '').toString();
        _email = data['email'] ?? user.email ?? '';
        _currentPhotoUrl = data['photoUrl'];
      } else {
        _email = user.email ?? '';
      }
    } catch (e) {
      debugPrint('Error loading client profile: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1080,
        maxHeight: 1080,
      );
      if (!context.mounted) return;
      if (picked != null) setState(() => _newProfileImage = picked);
    } catch (e) {
      _showSnack('Failed to pick image: $e', isError: true);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final user = _authService.currentUser;
      if (user == null) throw Exception('Not logged in');

      // Upload photo if changed
      if (_newProfileImage != null) {
        await _authService.uploadProfilePhoto(user.uid, _newProfileImage!);
      }
      if (!context.mounted) return;

      await _firestore.collection('users').doc(user.uid).update({
        'fullName': _nameController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'profession': _professionController.text.trim(),
        'age': int.tryParse(_ageController.text.trim()) ?? 0,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!context.mounted) return;
      _showSnack('Profile updated successfully!');
      context.pop();
    } catch (e) {
      _showSnack('Failed to update: $e', isError: true);
    } finally {
      if (context.mounted) setState(() => _isSaving = false);
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
                                border: Border.all(color: AppColors.secondary, width: 3),
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
                                  color: AppColors.secondary,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: const PhosphorIcon(PhosphorIconsRegular.camera, color: AppColors.textPrimary, size: 16),
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

                    const SizedBox(height: AppSpacing.lg),

                    // ── Personal Info ─────────────────────────────────
                    _SectionHeader(title: 'Personal Information', icon: PhosphorIconsRegular.user),
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
                      hint: '+92 300 1234567',
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: _buildField(
                            label: 'Address / City',
                            controller: _addressController,
                            icon: PhosphorIconsRegular.mapPin,
                            hint: 'e.g. Lahore, Pakistan',
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: _buildField(
                            label: 'Age',
                            controller: _ageController,
                            icon: PhosphorIconsRegular.calendarBlank,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildField(
                      label: 'Profession / Occupation',
                      controller: _professionController,
                      icon: PhosphorIconsRegular.briefcase,
                      hint: 'e.g. Business Owner, Engineer',
                    ),

                    // ── Email (locked) ────────────────────────────────
                    const SizedBox(height: AppSpacing.lg),
                    _SectionHeader(title: 'Account', icon: PhosphorIconsRegular.shieldCheck),
                    const SizedBox(height: AppSpacing.sm),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Email Address',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
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
                              const PhosphorIcon(PhosphorIconsRegular.envelope, color: AppColors.textLight, size: 18),
                              const SizedBox(width: 10),
                              Expanded(child: Text(_email ?? '', style: const TextStyle(color: AppColors.textSecondary))),
                              const PhosphorIcon(PhosphorIconsRegular.lock, color: AppColors.textLight, size: 16),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text('Email cannot be changed.',
                            style: TextStyle(fontSize: 11, color: AppColors.textLight)),
                      ],
                    ),

                    // ── Note ─────────────────────────────────────────
                    const SizedBox(height: AppSpacing.lg),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.info.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const PhosphorIcon(PhosphorIconsRegular.info, color: AppColors.info, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Your name and contact information may be shared with lawyers when you post or accept a case.',
                              style: textTheme.bodySmall?.copyWith(color: AppColors.info),
                            ),
                          ),
                        ],
                      ),
                    ),

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
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.grey200)),
            ),
            child: SafeArea(
              child: SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveProfile,
                  icon: _isSaving
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const PhosphorIcon(PhosphorIconsRegular.floppyDisk, size: 18),
                  label: Text(_isSaving ? 'Saving...' : 'Save Changes',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: AppColors.textPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.full)),
                    disabledBackgroundColor: AppColors.secondary.withValues(alpha: 0.5),
                  ),
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
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: BorderSide(color: AppColors.grey300)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: BorderSide(color: AppColors.grey300)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: const BorderSide(color: AppColors.secondary, width: 1.5)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _professionController.dispose();
    _ageController.dispose();
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
        PhosphorIcon(icon, color: AppColors.secondary, size: 16),
        const SizedBox(width: 6),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary)),
        const SizedBox(width: 8),
        const Expanded(child: Divider()),
      ],
    );
  }
}
