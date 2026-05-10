import 'package:flutter/foundation.dart'; // For kIsWeb
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:zakoota/l10n/app_localizations.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/auth_service.dart';

class ClientVerificationScreen extends StatefulWidget {
  const ClientVerificationScreen({super.key});

  @override
  State<ClientVerificationScreen> createState() =>
      _ClientVerificationScreenState();
}

class _ClientVerificationScreenState extends State<ClientVerificationScreen> {
  final _authService = AuthService();
  final _imagePicker = ImagePicker();

  XFile? _cnicImage;
  XFile? _selfieImage;

  bool _isUploading = false;
  String? _errorMessage;

  Future<void> _pickImage(bool isCnic) async {
    final XFile? pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (pickedFile != null) {
      if (!mounted) return;
      setState(() {
        if (isCnic) {
          _cnicImage = pickedFile;
        } else {
          _selfieImage = pickedFile;
        }
        _errorMessage = null;
      });
    }
  }

  Future<void> _handleSubmit(AppLocalizations loc) async {
    if (_cnicImage == null || _selfieImage == null) {
      if (!mounted) return;
      setState(() {
        _errorMessage = loc.uploadBothCnicAndSelfie;
      });
      return;
    }

    setState(() {
      _isUploading = true;
      _errorMessage = null;
    });

    try {
      await _authService.uploadVerification(
        cnicStart: _cnicImage!,
        cnicEnd:
            _cnicImage!, // Passing same file for now as per requirement for "CNIC" and "Selfie" boxes only
        selfie: _selfieImage!,
      );
      // Success!
      if (mounted) {
        context.go('/client-home');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(loc.verifyIdentityTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _authService.signOut(),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                loc.identityVerification,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                loc.uploadCnicAndSelfie,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),

              const SizedBox(height: AppSpacing.xl),

              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                ),

              // CNIC Upload Box
              _buildUploadBox(
                label: loc.cnicFrontLabel,
                file: _cnicImage,
                onTap: () => _pickImage(true),
                loc: loc,
              ),

              const SizedBox(height: AppSpacing.lg),

              // Selfie Upload Box
              _buildUploadBox(
                label: loc.yourSelfieLabel,
                file: _selfieImage,
                onTap: () => _pickImage(false),
                loc: loc,
              ),

              const SizedBox(height: AppSpacing.xl),

              // Submit Button
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isUploading ? null : () => _handleSubmit(loc),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  child: _isUploading
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(loc.uploading),
                          ],
                        )
                      : Text(
                          loc.submitVerification,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUploadBox({
    required String label,
    required XFile? file,
    required VoidCallback onTap,
    required AppLocalizations loc,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: file != null ? AppColors.primary : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: file != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.md - 2),
                child: kIsWeb
                    ? Image.network(
                        file.path,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      )
                    : Image.file(
                        File(file.path),
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.cloud_upload_outlined,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    loc.tapToUpload(label),
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
