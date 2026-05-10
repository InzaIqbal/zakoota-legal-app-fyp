import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:zakoota/l10n/app_localizations.dart';
import '../../../core/constants/app_constants.dart';

/// Splash Screen with animated logo
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  double _opacity = 0.0;

  @override
  void initState() {
    super.initState();
    _startAnimation();
  }

  Future<void> _startAnimation() async {
    // Start fade-in animation
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      setState(() {
        _opacity = 1.0;
      });
    }

    // Wait for 2 seconds total
    await Future.delayed(const Duration(milliseconds: 1700));

    // Mock auth check (always false for now)
    final isAuthenticated = await _checkAuthentication();

    if (mounted) {
      if (isAuthenticated) {
        // TODO: Navigate to dashboard when auth is implemented
        context.go('/welcome');
      } else {
        context.go('/onboarding');
      }
    }
  }

  Future<bool> _checkAuthentication() async {
    // Mock authentication check
    // TODO: Replace with actual Firebase auth check
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final loc = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.8, end: 1.0),
              duration: const Duration(seconds: 1),
              curve: Curves.elasticOut,
              builder: (context, scale, child) {
                return Transform.scale(
                  scale: scale,
                  child: AnimatedOpacity(
                    opacity: _opacity,
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeIn,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // App Logo
                        Image.asset(
                          'assets/images/logo_white.png',
                          width: 110,
                          height: 110,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: AppSpacing.xl + 10),
                        Text(
                          loc.appBrand,
                          style: textTheme.displaySmall?.copyWith(
                            color: AppColors.primary,
                            letterSpacing: 6,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          loc.appTagline,
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                            letterSpacing: 2.0,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // More "Creative" Loading Animation
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Center(
              child: SizedBox(
                width: 50,
                height: 50,
                child: Stack(
                  children: [
                    const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                    Center(
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 1500),
                        curve: Curves.linear,
                        builder: (context, value, child) {
                          return Transform.rotate(
                            angle: value * 2 * 3.14159,
                            child: Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(bottom: 40),
                              decoration: const BoxDecoration(
                                color: AppColors.secondary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
