import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/auth_service.dart';

class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  final _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Security',
          style: theme.textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(AppRadius.xl),
            topRight: Radius.circular(AppRadius.xl),
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            _buildSectionHeader('Authentication'),

            // Password Change
            _buildSettingsItem(
              title: 'Change Password',
              subtitle: 'Update your login password',
              icon: PhosphorIconsRegular.key,
              onTap: () => _showChangePasswordDialog(context),
            ),

            const SizedBox(height: AppSpacing.md),

            // Biometric
            _buildFutureWorkItem(
              title: 'Biometric Login',
              subtitle: 'Face ID / Fingerprint (Coming Soon)',
              icon: PhosphorIconsRegular.scan,
            ),

            const SizedBox(height: AppSpacing.md),

            // 2FA
            _buildFutureWorkItem(
              title: 'Two-Factor Authentication',
              subtitle: 'Extra layer of security (Coming Soon)',
              icon: PhosphorIconsRegular.shieldCheck,
            ),

            const SizedBox(height: AppSpacing.xl),

            _buildSectionHeader('Devices'),

            // Devices
            _buildFutureWorkItem(
              title: 'Manage Devices',
              subtitle: 'View active sessions (Coming Soon)',
              icon: PhosphorIconsRegular.deviceMobile,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showChangePasswordDialog(BuildContext context) async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool isLoading = false;
    String? errorMessage;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Change Password'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(8),
                        margin: const EdgeInsets.only(bottom: 16),
                        color: AppColors.error.withValues(alpha: 0.1),
                        child: Text(
                          errorMessage!,
                          style: const TextStyle(color: AppColors.error, fontSize: 12),
                        ),
                      ),
                    TextField(
                      controller: currentPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Current Password',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: newPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'New Password',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: confirmPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Confirm New Password',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          if (newPasswordController.text != confirmPasswordController.text) {
                            setState(() {
                              errorMessage = 'New passwords do not match';
                            });
                            return;
                          }
                          if (newPasswordController.text.length < 6) {
                            setState(() {
                              errorMessage = 'Password must be at least 6 characters';
                            });
                            return;
                          }
                          setState(() {
                            isLoading = true;
                            errorMessage = null;
                          });
                          try {
                            await _authService.changePassword(
                              currentPassword: currentPasswordController.text,
                              newPassword: newPasswordController.text,
                            );
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Password changed successfully')),
                              );
                            }
                          } catch (e) {
                            setState(() {
                              isLoading = false;
                              errorMessage = e.toString().replaceFirst('Exception: ', '');
                            });
                          }
                        },
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding:
          const EdgeInsets.only(bottom: AppSpacing.md, left: AppSpacing.sm),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildSettingsItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: PhosphorIcon(icon, color: AppColors.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle,
            style:
                const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        trailing: const Icon(Icons.arrow_forward_ios,
            size: 16, color: AppColors.textLight),
      ),
    );
  }

  Widget _buildFutureWorkItem({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: ListTile(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$title is planned for future updates')),
          );
        },
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.textLight.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: PhosphorIcon(icon, color: AppColors.textLight),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        subtitle: Text(subtitle,
            style:
                const TextStyle(color: AppColors.textLight, fontSize: 13)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text('Soon', style: TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}
