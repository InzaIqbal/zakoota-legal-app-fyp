import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/widgets/user_avatar.dart';

/// Profile Screen - User account management and settings
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header Section (Navy Background)
            StreamBuilder<DocumentSnapshot<Map<String, dynamic>>?>(
              stream: AuthService().getUserStream(),
              builder: (context, snapshot) {
                final userData = snapshot.data?.data();
                final displayName = userData?['fullName'] as String? ?? 'User';
                final isVerified =
                    (userData?['verificationStatus'] as String? ?? 'none') ==
                        'verified';
                final createdAtTimestamp = userData?['createdAt'];
                String memberSince = 'Member since 2024';

                if (createdAtTimestamp != null &&
                    createdAtTimestamp is Timestamp) {
                  final date = createdAtTimestamp.toDate();
                  // Simple formatting, can use intl package if available
                  final months = [
                    'Jan',
                    'Feb',
                    'Mar',
                    'Apr',
                    'May',
                    'Jun',
                    'Jul',
                    'Aug',
                    'Sep',
                    'Oct',
                    'Nov',
                    'Dec'
                  ];
                  memberSince =
                      'Member since ${months[date.month - 1]} ${date.year}';
                }

                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.xl,
                  ),
                  child: Column(
                    children: [
                      // Large Avatar with Gold Border
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.secondary,
                            width: 3,
                          ),
                        ),
                        child: const CurrentUserAvatar(
                          radius: 50,
                        ),
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // User Name
                      Text(
                        displayName,
                        style: textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: AppSpacing.xs),

                      // Verified Badge
                      if (isVerified)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(AppRadius.full),
                            border: Border.all(
                              color: AppColors.secondary,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              PhosphorIcon(
                                PhosphorIconsFill.sealCheck,
                                size: 16,
                                color: AppColors.secondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Verified Client',
                                style: textTheme.bodySmall?.copyWith(
                                  color: AppColors.secondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: AppSpacing.sm),

                      // Member Since
                      Text(
                        memberSince,
                        style: textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            // Body Section (White Container with Rounded Top)
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(AppRadius.xl),
                    topRight: Radius.circular(AppRadius.xl),
                  ),
                ),
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.lg,
                  ),
                  children: [
                    // Account Section
                    const _SectionHeader(title: 'Account'),
                    _ProfileMenuItem(
                      icon: PhosphorIconsRegular.userCircle,
                      title: 'Edit Profile',
                      onTap: () => context.push('/edit-profile'),
                    ),
                    _ProfileMenuItem(
                      icon: PhosphorIconsRegular.wallet,
                      title: 'Wallet',
                      onTap: () => context.push('/wallet'),
                    ),
                    _ProfileMenuItem(
                      icon: PhosphorIconsRegular.star,
                      title: 'Saved Lawyers',
                      onTap: () => context.push('/saved-lawyers'),
                    ),
                    _ProfileMenuItem(
                      icon: PhosphorIconsRegular.checkCircle,
                      title: 'Completed Cases',
                      onTap: () => context.push('/completed-cases'),
                    ),
                    _ProfileMenuItem(
                      icon: PhosphorIconsRegular.fileText,
                      title: 'My Documents',
                      subtitle: 'All case attachments',
                      onTap: () => context.push('/document-review'),
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // App Settings Section
                    const _SectionHeader(title: 'App Settings'),
                    _ProfileMenuItem(
                      icon: PhosphorIconsRegular.bell,
                      title: 'Notifications',
                      onTap: () => context.push('/notifications'),
                    ),
                    _ProfileMenuItem(
                      icon: PhosphorIconsRegular.lock,
                      title: 'Security / Password',
                      onTap: () => context.push('/security-settings'),
                    ),
                    _ProfileMenuItem(
                      icon: PhosphorIconsRegular.translate,
                      title: 'Language',
                      subtitle: 'English',
                      onTap: () => context.push('/language-settings'),
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // Support Section
                    const _SectionHeader(title: 'Support'),
                    _ProfileMenuItem(
                      icon: PhosphorIconsRegular.lifebuoy,
                      title: 'Help Center',
                      onTap: () => context.push('/help-center'),
                    ),
                    _ProfileMenuItem(
                      icon: PhosphorIconsRegular.fileText,
                      title: 'Terms & Privacy',
                      onTap: () => context.push('/terms'),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // Logout Button
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                      ),
                      child: TextButton(
                        onPressed: () => _showLogoutDialog(context),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.error,
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.md,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const PhosphorIcon(
                              PhosphorIconsRegular.signOut,
                              color: AppColors.error,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              'Logout',
                              style: textTheme.titleMedium?.copyWith(
                                color: AppColors.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // App Version
                    Center(
                      child: Text(
                        'Version 1.0.0',
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.textLight,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog first

              // Sign out from Firebase
              await AuthService().signOut();

              if (context.mounted) {
                context.go('/login');
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

/// Section Header Widget
class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Text(
        title,
        style: textTheme.titleSmall?.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// Profile Menu Item Widget
class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _ProfileMenuItem({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: PhosphorIcon(
                icon,
                size: 20,
                color: AppColors.primary,
              ),
            ),

            const SizedBox(width: AppSpacing.md),

            // Title & Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.bodyLarge?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Trailing Arrow
            const PhosphorIcon(
              PhosphorIconsRegular.caretRight,
              size: 20,
              color: AppColors.textLight,
            ),
          ],
        ),
      ),
    );
  }
}
