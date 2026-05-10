import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:zakoota/l10n/app_localizations.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/auth_service.dart';

/// Login Screen
class LoginScreen extends StatefulWidget {
  final String role;

  const LoginScreen({super.key, required this.role});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
  }

  Future<void> _handleLogin() async {
    debugPrint('Login attempt started');
    if (_formKey.currentState?.validate() ?? false) {
      debugPrint('Form valid, proceeding with login');
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        debugPrint(
            'Calling AuthService.signIn with email: ${_emailController.text.trim()}');
        final userCredential = await _authService.signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        debugPrint('AuthService.signIn completed successfully');

        if (userCredential.user != null) {
          final role = await _authService.getUserRole(userCredential.user!.uid);

          // Strict Role Check
          if (role != widget.role) {
            await _authService.signOut();
            throw Exception(AppLocalizations.of(context).invalidCredentialsMessage);
          }
        }

        if (!mounted) return;
        // Explicitly navigate to dashboard after successful login
        // The router redirect might be slow or not triggering immediately
        if (widget.role == 'lawyer') {
          context.go('/lawyer-dashboard');
        } else {
          context.go('/client-home');
        }
      } catch (e) {
        debugPrint('Login error caught: $e');
        if (!mounted) return;
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else {
      debugPrint('Form validation failed');
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _authService.signInWithGoogle(role: widget.role);
      if (!mounted) return;

      final status = result['status'];
      final role = result['role'];

      if (status == 'cancelled') return;

      // Smart Redirection Check
      if (role != null && role != widget.role) {
        // Show redirection message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).accountRedirecting(
                role == 'client' ? 'client' : 'lawyer',
                role == 'client' ? 'Client' : 'Lawyer',
              ),
            ),
            backgroundColor: AppColors.secondary,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      if (status == 'dashboard') {
        if (role == 'lawyer') {
          context.go('/lawyer-dashboard');
        } else {
          context.go('/client-home');
        }
      } else if (status == 'profile_setup') {
        // Only lawyers go here, but good to be explicit
        context.go('/lawyer-profile-setup');
      } else if (status == 'profile_pending') {
        // New Client -> Profile Setup
        context.go('/client-profile-setup');
      } else if (status == 'verification') {
        // Legacy or direct to verification
        context.go('/client-verification');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String? _validateEmail(String? value) {
    final loc = AppLocalizations.of(context);
    if (value == null || value.isEmpty) {
      return loc.pleaseEnterYourEmail;
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return loc.pleaseEnterValidEmail;
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final loc = AppLocalizations.of(context);
    if (value == null || value.isEmpty) {
      return loc.pleaseEnterYourPassword;
    }
    if (value.length < 6) {
      return loc.passwordMinLength(6);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final loc = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: PhosphorIcon(
            PhosphorIconsRegular.arrowLeft,
            color: colorScheme.primary,
          ),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/welcome');
            }
          },
        ),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppSpacing.lg),

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

                    // Header
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc.signInTitle,
                          style: textTheme.headlineLarge?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          loc.continueAs(widget.role),
                          style: textTheme.bodyLarge?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // Email Field
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      validator: _validateEmail,
                        decoration: InputDecoration(
                        labelText: loc.emailLabel,
                        hintText: loc.emailHint,
                        prefixIcon: PhosphorIcon(
                          PhosphorIconsRegular.envelope,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // Password Field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: !_isPasswordVisible,
                      validator: _validatePassword,
                        decoration: InputDecoration(
                        labelText: loc.passwordLabel,
                        hintText: loc.passwordHint,
                        prefixIcon: PhosphorIcon(
                          PhosphorIconsRegular.lock,
                          color: AppColors.textSecondary,
                        ),
                        suffixIcon: IconButton(
                          icon: PhosphorIcon(
                            _isPasswordVisible
                                ? PhosphorIconsRegular.eyeSlash
                                : PhosphorIconsRegular.eye,
                            color: AppColors.textSecondary,
                          ),
                          onPressed: _togglePasswordVisibility,
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.sm),

                    // Forgot Password
                    Align(
                      alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            // TODO: Implement forgot password
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(loc.forgotPasswordComingSoon),
                              ),
                            );
                          },
                          child: Text(
                            loc.forgotPassword,
                            style: textTheme.labelMedium?.copyWith(
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Login Button
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.secondary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                        ),
                        child: Text(
                          loc.loginButton,
                          style: textTheme.labelLarge?.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // Sign Up Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          loc.dontHaveAccount,
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            if (widget.role == 'lawyer') {
                              context.push('/lawyer-signup');
                            } else {
                              context.push('/signup');
                            }
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            loc.signUp,
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Divider
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: Colors.grey.shade300,
                            thickness: 1,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md),
                          child: Text(
                            loc.orContinueWith,
                            style: textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: Colors.grey.shade300,
                            thickness: 1,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Google Sign In Button
                    SizedBox(
                      height: 56,
                      child: OutlinedButton.icon(
                        onPressed: _isLoading ? null : _handleGoogleSignIn,
                        icon: PhosphorIcon(
                          PhosphorIcons.googleLogo(),
                          color: Colors.red,
                          size: 24,
                        ),
                        label: Text(
                          loc.signInWithGoogle,
                          style: textTheme.labelLarge?.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
