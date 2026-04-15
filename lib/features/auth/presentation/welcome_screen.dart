import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/constants/app_constants.dart';

/// Welcome/Role Selection Screen
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  String? _selectedRole;

  void _selectRole(String role) {
    setState(() {
      _selectedRole = role;
    });

    // Navigate to login with role parameter
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        context.push('/login?role=$role');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.xxl),

              // Header
              Column(
                children: [
                  Text(
                    'Welcome to Zakoota',
                    style: textTheme.displaySmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Choose your role to continue',
                    style: textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.xxl),

              // Role Cards
              Expanded(
                child: Column(
                  children: [
                    // Client Card
                    Expanded(
                      child: _RoleCard(
                        icon: PhosphorIconsRegular.user,
                        title: 'I am a Client',
                        description: 'I need legal help.',
                        isSelected: _selectedRole == UserRoles.client,
                        onTap: () => _selectRole(UserRoles.client),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Lawyer Card
                    Expanded(
                      child: _RoleCard(
                        icon: PhosphorIconsRegular.briefcase,
                        title: 'I am a Lawyer',
                        description: 'I want to find cases.',
                        isSelected: _selectedRole == UserRoles.lawyer,
                        onTap: () => _selectRole(UserRoles.lawyer),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}

/// Role selection card widget
class _RoleCard extends StatelessWidget {
  final PhosphorIconData icon;
  final String title;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: AnimatedContainer(
        duration: AppDurations.fast,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary.withValues(alpha: 0.05)
              : colorScheme.surface,
          border: Border.all(
            color: isSelected ? colorScheme.primary : AppColors.grey300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: isSelected
                    ? colorScheme.secondary.withValues(alpha: 0.15)
                    : AppColors.grey100,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: PhosphorIcon(
                  icon,
                  size: 40,
                  color: isSelected
                      ? colorScheme.secondary
                      : AppColors.textSecondary,
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Title
            Text(
              title,
              style: textTheme.headlineSmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppSpacing.sm),

            // Description
            Text(
              description,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
