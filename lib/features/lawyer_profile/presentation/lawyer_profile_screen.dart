import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/constants/app_constants.dart';

import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/services/auth_service.dart';
import '../../ads/services/lawyer_ad_service.dart';

import 'package:cloud_firestore/cloud_firestore.dart'; 
import '../../../core/widgets/user_avatar.dart';

class LawyerProfileScreen extends StatefulWidget {
  const LawyerProfileScreen({super.key});

  @override
  State<LawyerProfileScreen> createState() => _LawyerProfileScreenState();
}

class _LawyerProfileScreenState extends State<LawyerProfileScreen> {
  final AuthService _authService = AuthService();
  final LawyerAdService _lawyerAdService = LawyerAdService();
  bool _isAcceptingCase = true;
  bool _isAvailabilityUpdating = false;

  // Pre-fetched initial values so the avatar shows immediately
  String? _cachedPhotoUrl;
  String _cachedName = '';

  @override
  void initState() {
    super.initState();
    _prefetchProfile();
  }

  Future<void> _prefetchProfile() async {
    final user = _authService.currentUser;
    if (user == null) return;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists && context.mounted) {
        final data = doc.data()!;
        setState(() {
          _cachedPhotoUrl = data['photoUrl'] as String?;
          _cachedName = data['fullName'] ?? '';
          final dbAvail = data['isAcceptingCases'];
          if (dbAvail is bool && !_isAvailabilityUpdating) {
            _isAcceptingCase = dbAvail;
          }
        });
      }
    } catch (e) {
      debugPrint('LawyerProfileScreen prefetch error: $e');
    }
  }

  Future<void> _updateAvailability(bool value) async {
    final user = _authService.currentUser;
    if (user == null) return;

    final previousValue = _isAcceptingCase;
    setState(() {
      _isAcceptingCase = value;
      _isAvailabilityUpdating = true;
    });

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'isAcceptingCases': value,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      int pausedAds = 0;
      if (!value) {
        pausedAds = await _lawyerAdService.pauseAllActiveAdsForLawyer(user.uid);
      }

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value
                ? 'You are now accepting new cases.'
                : pausedAds > 0
                    ? 'You stopped accepting cases. $pausedAds ad(s) were paused.'
                    : 'You stopped accepting cases. Your profile is hidden from search.',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      setState(() {
        _isAcceptingCase = previousValue;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update availability: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isAvailabilityUpdating = false;
        });
      }
    }
  }

  Future<void> _openHelpCenter() async {
    final uri = Uri.parse('https://bkxlabs.com/contact');
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open help page')),
      );
    }
  }

  Future<void> _handleLogout() async {
    // ... (keep existing logout logic)
    debugPrint('Logout button pressed');
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Logout',
                  style: TextStyle(color: AppColors.error)),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      if (!context.mounted) return;
      await _authService.signOut();
      if (!context.mounted) return;
      context.go('/login?role=lawyer');
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>?>(
        stream: _authService.getUserStream(),
        builder: (context, snapshot) {
          String fullName = 'Advocate';
          String location = 'Pakistan';
          String badge = 'Associate';
          String? photoUrl;

          // Mock stats for now as we don't have real stats in user doc yet
          String rating = '4.9';
          String cases = '24';
          String experience = '5+ Years';

          if (snapshot.hasData &&
              snapshot.data != null &&
              snapshot.data!.exists) {
            final data = snapshot.data!.data();
            if (data != null) {
              final dbName = data['fullName'] as String?;
              fullName = (dbName != null && dbName.isNotEmpty)
                  ? dbName
                  : (_cachedName.isNotEmpty ? _cachedName : 'Advocate');
              location = data['location'] ?? data['city'] ?? 'Pakistan';
              photoUrl = (data['photoUrl'] as String?)?.isNotEmpty == true
                  ? data['photoUrl'] as String
                  : _cachedPhotoUrl;
              final dbAvailability = data['isAcceptingCases'];
              if (!_isAvailabilityUpdating && dbAvailability is bool) {
                _isAcceptingCase = dbAvailability;
              }
              experience = '${data['experienceYears'] ?? 0}+ Years';
              badge = data['licenseType'] ?? 'Associate';
            }
          } else {
            // Use prefetched values while stream loads
            fullName = _cachedName.isNotEmpty ? _cachedName : 'Advocate';
            photoUrl = _cachedPhotoUrl;
          }

          return Scaffold(
            backgroundColor: Colors.white,
            body: SingleChildScrollView(
              child: Column(
                children: [
                  // Header Section (Navy Background)
                  _buildHeader(fullName, location, badge, photoUrl, rating,
                      cases, experience),

                  // Availability Switch (Floating Card)
                  Transform.translate(
                    offset: const Offset(0, -30),
                    child: _buildAvailabilityCard(_isAcceptingCase),
                  ),

                  // Menu Groups
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: Column(
                      children: [
                        // ... (Keep existing menu groups)
                        _buildMenuGroup(
                          title: 'Practice Management',
                          items: [
                            _MenuItem(
                              icon: PhosphorIconsRegular.wallet,
                              title: 'My Wallet & Earnings',
                              iconColor: AppColors.primary,
                              onTap: () => context.push('/wallet'),
                            ),
                            _MenuItem(
                              icon: PhosphorIconsRegular.megaphone,
                              title: 'Manage Gigs / Ads',
                              iconColor: AppColors.secondary,
                              onTap: () => context.push('/lawyer-manage-ads'),
                            ),
                            _MenuItem(
                              icon: PhosphorIconsRegular.shieldCheck,
                              title: 'Verification Status',
                              iconColor: AppColors.success,
                              subtitle: 'Verified',
                              onTap: () {},
                            ),
                            _MenuItem(
                              icon: PhosphorIconsRegular.checkCircle,
                              title: 'Completed Cases',
                              iconColor: AppColors.primary,
                              onTap: () => context.push('/completed-cases'),
                            ),
                            _MenuItem(
                              icon: PhosphorIconsRegular.fileText,
                              title: 'My Documents',
                              iconColor: Colors.blue,
                              subtitle: 'All case attachments',
                              onTap: () => context.push('/document-review'),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _buildMenuGroup(
                          title: 'Account Settings',
                          items: [
                            _MenuItem(
                              icon: PhosphorIconsRegular.pencilSimple,
                              title: 'Edit Profile',
                              onTap: () => context.push('/lawyer-edit-profile'),
                            ),
                            _MenuItem(
                              icon: PhosphorIconsRegular.bell,
                              title: 'Notifications',
                              onTap: () => context.push('/notifications'),
                            ),
                            _MenuItem(
                              icon: PhosphorIconsRegular.lockKey,
                              title: 'Security & Password',
                              onTap: () => context.push('/lawyer-security-password'),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _buildMenuGroup(
                          title: 'Support',
                          items: [
                            _MenuItem(
                              icon: PhosphorIconsRegular.question,
                              title: 'Help Center',
                              onTap: _openHelpCenter,
                            ),
                            _MenuItem(
                              icon: PhosphorIconsRegular.signOut,
                              title: 'Logout',
                              iconColor: AppColors.error,
                              textColor: AppColors.error,
                              hideChevron: true,
                              onTap: _handleLogout,
                            ),
                          ],
                        ),
                        const SizedBox(height: 40), // Bottom padding
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        });
  }

  Widget _buildHeader(String name, String location, String badge,
      String? photoUrl, String rating, String cases, String experience) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 60, AppSpacing.lg,
          60), // Extra bottom padding for overlap
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          // Avatar
          const CurrentUserAvatar(
            radius: 50,
            borderColor: AppColors.secondary,
            borderWidth: 4,
          ),
          const SizedBox(height: AppSpacing.md),

          // Identity
          Text(
            name,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: Text(
              badge,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            location,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Stats Row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStat(PhosphorIconsFill.star, rating, 'Rating'),
              _buildDivider(),
              _buildStat(PhosphorIconsRegular.briefcase, cases, 'Cases'),
              _buildDivider(),
              _buildStat(PhosphorIconsRegular.medal, experience, 'Exp'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(IconData icon, String value, String label) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Icon(icon, color: AppColors.secondary, size: 20),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 24,
      width: 1,
      color: Colors.white.withValues(alpha: 0.2),
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
    );
  }

  Widget _buildAvailabilityCard(bool isAcceptingCases) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.sm), // Inner padding
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SwitchListTile(
        value: isAcceptingCases,
        activeThumbColor: AppColors.success,
        title: const Text(
          'Accepting New Cases',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: const Text(
          'Turn off to hide your profile from search and pause your ads.',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isAcceptingCases
                ? AppColors.success.withValues(alpha: 0.1)
                : AppColors.grey100,
            shape: BoxShape.circle,
          ),
          child: Icon(
            PhosphorIconsRegular.briefcase,
            color:
                isAcceptingCases ? AppColors.success : AppColors.textSecondary,
          ),
        ),
        onChanged: _isAvailabilityUpdating ? null : _updateAvailability,
      ),
    );
  }

  Widget _buildMenuGroup(
      {required String title, required List<_MenuItem> items}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.grey200),
          ),
          child: Column(
            children: items.map((item) {
              final isLast = items.last == item;
              return Column(
                children: [
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (item.iconColor ?? AppColors.textSecondary)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        item.icon,
                        color: item.iconColor ?? AppColors.textPrimary,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      item.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: item.textColor ?? AppColors.textPrimary,
                      ),
                    ),
                    subtitle: item.subtitle != null
                        ? Text(
                            item.subtitle!,
                            style: const TextStyle(
                                color: AppColors.success,
                                fontWeight: FontWeight.bold,
                                fontSize: 12),
                          )
                        : null,
                    trailing: item.hideChevron
                        ? null
                        : const Icon(PhosphorIconsRegular.caretRight,
                            size: 16, color: AppColors.grey400),
                    onTap: item.onTap,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  ),
                  if (!isLast) const Divider(height: 1, indent: 60),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final String? subtitle;
  final Color? iconColor;
  final Color? textColor;
  final bool hideChevron;

  _MenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.iconColor,
    this.textColor,
    this.hideChevron = false,
  });
}
