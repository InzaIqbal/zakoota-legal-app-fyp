import 'package:flutter/foundation.dart'; // For kIsWeb
import 'dart:io'; // Needed for File class on mobile
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/auth_service.dart';

class LawyerVerificationScreen extends StatefulWidget {
  const LawyerVerificationScreen({super.key});

  @override
  State<LawyerVerificationScreen> createState() =>
      _LawyerVerificationScreenState();
}

class _LawyerVerificationScreenState extends State<LawyerVerificationScreen> {
  final _authService = AuthService();
  final _picker = ImagePicker();

  XFile? _cnicFront;
  XFile? _cnicBack;
  XFile? _barCouncilCard;
  XFile? _profilePhoto;

  bool _isLoading = false;

  Future<void> _pickImage(String type) async {
    final XFile? image =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image != null) {
      setState(() {
        switch (type) {
          case 'cnicFront':
            _cnicFront = image;
            break;
          case 'cnicBack':
            _cnicBack = image;
            break;
          case 'barCard':
            _barCouncilCard = image;
            break;
          case 'profile':
            _profilePhoto = image;
            break;
        }
      });
    }
  }

  Future<void> _submitVerification() async {
    if (_cnicFront == null ||
        _cnicBack == null ||
        _barCouncilCard == null ||
        _profilePhoto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload all required documents')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = _authService.currentUser;
      if (user != null) {
        // Upload concurrently
        await Future.wait<void>([
          _authService.uploadVerificationLawyer(
              user.uid, _cnicFront!, 'cnic_front'),
          _authService.uploadVerificationLawyer(
              user.uid, _cnicBack!, 'cnic_back'),
          _authService.uploadVerificationLawyer(
              user.uid, _barCouncilCard!, 'bar_council_card'),
          _authService.uploadProfilePhotoLawyer(user.uid, _profilePhoto!),
        ]);

        if (mounted) {
          // Update status to pending_approval
          await _authService.submitLawyerVerification(user.uid);

          if (mounted) {
            // Show Success Dialog
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                title: const Text('Under Review',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                content: const Text(
                  'Your documents have been submitted. We will notify you once verified.',
                ),
                actions: [
                  TextButton(
                    onPressed: () async {
                      // Sign out and go to login
                      await _authService.signOut();
                      if (context.mounted) {
                        context.go('/login?role=lawyer');
                      }
                    },
                    child: const Text('Continue'),
                  ),
                ],
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildUploadCard(String title, String type, XFile? file) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.grey200),
      ),
      child: InkWell(
        onTap: () => _pickImage(type),
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.grey200,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  image: file != null
                      ? DecorationImage(
                          image: kIsWeb
                              ? NetworkImage(file.path)
                              : FileImage(File(file.path)) as ImageProvider,
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: file == null
                    ? Icon(Icons.camera_alt, color: AppColors.textSecondary)
                    : null,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      file != null ? 'Image selected' : 'Tap to upload',
                      style: TextStyle(
                        color: file != null
                            ? AppColors.success
                            : AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (file != null)
                Icon(Icons.check_circle, color: AppColors.success),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Verify Identity'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Proof of Practice',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Upload clear images of your documents for verification.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: AppSpacing.xl),
              _buildUploadCard(
                  'Profile Photo (Headshot)', 'profile', _profilePhoto),
              _buildUploadCard('CNIC Front', 'cnicFront', _cnicFront),
              _buildUploadCard('CNIC Back', 'cnicBack', _cnicBack),
              _buildUploadCard('Bar Council Card', 'barCard', _barCouncilCard),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitVerification,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Submit for Review',
                          style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
