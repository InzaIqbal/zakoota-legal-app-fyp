import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:zakoota/l10n/app_localizations.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/auth_service.dart';
import '../../chat/services/chat_service.dart';
import '../data/lawyer_mock_data.dart';
import '../services/lawyer_service.dart';
import '../../../core/widgets/user_avatar.dart';

/// Lawyer Profile Screen - Detailed lawyer portfolio
class LawyerProfileScreen extends StatefulWidget {
  final String lawyerId;

  const LawyerProfileScreen({
    super.key,
    required this.lawyerId,
  });

  @override
  State<LawyerProfileScreen> createState() => _LawyerProfileScreenState();
}

class _LawyerProfileScreenState extends State<LawyerProfileScreen> {
  final _lawyerService = LawyerService();
  final _authService = AuthService();
  final _chatService = ChatService();
  LawyerProfile? _lawyer;
  bool _isLoading = true;
  bool _isMessageLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchLawyer();
  }

  Future<void> _fetchLawyer() async {
    try {
      final lawyer = await _lawyerService.getLawyerById(widget.lawyerId);

      LawyerProfile? completeLawyer = lawyer;
      if (lawyer != null) {
        // Fetch accurate reviews and rating dynamically
        final reviewsData = await _lawyerService.getLawyerReviews(widget.lawyerId);
        final dynamicReviews = reviewsData['reviews'] as List<LawyerReview>;
        final dynamicRating = reviewsData['rating'] as double;
        final dynamicCount = reviewsData['count'] as int;

        // Create a new instance merging the dynamic reviews data
        completeLawyer = LawyerProfile(
          id: lawyer.id,
          fullName: lawyer.fullName,
          professionalHeading: lawyer.professionalHeading,
          location: lawyer.location,
          photoUrl: lawyer.photoUrl,
          specializations: lawyer.specializations,
          experienceYears: lawyer.experienceYears,
          rating: dynamicReviews.isNotEmpty ? dynamicRating : lawyer.rating,
          reviewsCount: dynamicReviews.isNotEmpty ? dynamicCount : lawyer.reviewsCount,
          hourlyRate: lawyer.hourlyRate,
          verificationStatus: lawyer.verificationStatus,
          accountStatus: lawyer.accountStatus,
          isAcceptingCases: lawyer.isAcceptingCases,
          education: lawyer.education,
          barLicenseNo: lawyer.barLicenseNo,
          bio: lawyer.bio,
          reviews: dynamicReviews.isNotEmpty ? dynamicReviews : lawyer.reviews,
        );
      }

      if (mounted) {
        setState(() {
          _lawyer = completeLawyer;
          _isLoading = false;
          if (completeLawyer == null) {
            _error = 'Lawyer not found: ${widget.lawyerId}';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error loading profile: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (_error != null || _lawyer == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(loc.profileTitle, style: const TextStyle(color: AppColors.primary)),
          backgroundColor: AppColors.surface,
          elevation: 0,
          iconTheme: const IconThemeData(color: AppColors.primary),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const PhosphorIcon(PhosphorIconsRegular.warningCircle, color: AppColors.error, size: 48),
              ),
              const SizedBox(height: 16),
              Text(_error ?? loc.lawyerNotFound, style: const TextStyle(fontSize: 16, color: AppColors.textPrimary)),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _fetchLawyer,
                style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                child: Text(loc.retry),
              ),
            ],
          ),
        ),
      );
    }

    final lawyer = _lawyer!;
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // A. Clean Solid Navy Header
              SliverAppBar(
                expandedHeight: 320,
                pinned: true,
                backgroundColor: AppColors.primary,
                elevation: 0,
                leading: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.surface.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const PhosphorIcon(PhosphorIconsRegular.arrowLeft, color: Colors.white, size: 20),
                    onPressed: () => context.pop(),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(color: AppColors.primary),
                      // Subtle decorative element
                      Positioned(
                        right: -50,
                        top: -50,
                        child: CircleAvatar(
                          radius: 100,
                          backgroundColor: Colors.white.withValues(alpha: 0.03),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 90, left: AppSpacing.lg, right: AppSpacing.lg),
                        child: Column(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.secondary, width: 3),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.secondary.withValues(alpha: 0.2),
                                    blurRadius: 15,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: UserAvatar(
                                uid: lawyer.id,
                                radius: 55,
                                fallbackName: lawyer.name,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              lawyer.name,
                              style: textTheme.headlineMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              lawyer.professionalHeading,
                              style: textTheme.bodyMedium?.copyWith(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            if (lawyer.isVerified)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.secondary.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(AppRadius.full),
                                  border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const PhosphorIcon(PhosphorIconsFill.sealCheck, size: 16, color: AppColors.secondary),
                                    const SizedBox(width: 6),
                                    Text(
                                      loc.verifiedLawyer.toUpperCase(),
                                      style: textTheme.labelSmall?.copyWith(
                                        color: AppColors.secondary,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // B. Quick Stats Cards (Elevated slightly over background)
              SliverToBoxAdapter(
                child: Transform.translate(
                  offset: const Offset(0, -20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    child: Row(
                      children: [
                        Expanded(child: _StatCard(icon: PhosphorIconsRegular.briefcase, value: '${lawyer.experience}+', label: loc.yearsExperience)),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(child: _StatCard(icon: PhosphorIconsRegular.trophy, value: '${lawyer.casesWon}', label: loc.casesWon)),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(child: _StatCard(icon: PhosphorIconsFill.star, value: lawyer.ratingDouble.toStringAsFixed(1), label: loc.ratingLabel)),
                      ],
                    ),
                  ),
                ),
              ),

              // C. About Me Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionTitle(title: loc.aboutMe),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        lawyer.bio ?? 'No bio available',
                        style: textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                    ],
                  ),
                ),
              ),

              // D. Specializations
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionTitle(title: loc.specializationsLabel),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: 8,
                        runSpacing: 10,
                        children: lawyer.specializations.map((spec) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(AppRadius.full),
                              border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
                              boxShadow: [
                                BoxShadow(color: AppColors.primary.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2)),
                              ],
                            ),
                            child: Text(
                              spec,
                              style: textTheme.labelMedium?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                    ],
                  ),
                ),
              ),

              // E. Education & Credentials
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionTitle(title: loc.educationAndCredentials),
                      const SizedBox(height: AppSpacing.md),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          border: Border.all(color: AppColors.grey200),
                        ),
                        child: Column(
                          children: [
                            ...lawyer.education.map((edu) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(color: AppColors.secondary.withValues(alpha: 0.1), shape: BoxShape.circle),
                                      child: const PhosphorIcon(PhosphorIconsRegular.graduationCap, size: 18, color: AppColors.secondary),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.only(top: 6.0),
                                        child: Text(edu, style: textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                            const Divider(height: 16),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.05), shape: BoxShape.circle),
                                  child: const PhosphorIcon(PhosphorIconsRegular.scales, size: 18, color: AppColors.primary),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text('Bar License: ${lawyer.barLicenseNo}', style: textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                    ],
                  ),
                ),
              ),

              // F. Client Reviews
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _SectionTitle(title: loc.clientReviews),
                          Text(
                            loc.reviewsCount(lawyer.reviewsCount),
                            style: textTheme.labelLarge?.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                  ),
                ),
              ),

              // Review List
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final review = lawyer.reviews[index];
                    return Padding(
                      padding: const EdgeInsets.only(left: AppSpacing.lg, right: AppSpacing.lg, bottom: AppSpacing.md),
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          border: Border.all(color: AppColors.grey200),
                          boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                  child: Text(
                                    review.clientName[0].toUpperCase(),
                                    style: textTheme.titleMedium?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(review.clientName, style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                                      const SizedBox(height: 2),
                                      Text(review.date, style: textTheme.labelSmall?.copyWith(color: AppColors.textLight)),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: AppColors.secondary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                                  child: Row(
                                    children: [
                                      Text(review.rating.toStringAsFixed(1), style: textTheme.labelMedium?.copyWith(color: AppColors.secondary, fontWeight: FontWeight.w800)),
                                      const SizedBox(width: 4),
                                      const PhosphorIcon(PhosphorIconsFill.star, size: 12, color: AppColors.secondary),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              review.comment,
                              style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary, height: 1.5),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: lawyer.reviews.length,
                ),
              ),

              // Bottom Padding for Action Bar
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),

          // Bottom Action Bar (Fixed, Solid, Clean)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: const Border(top: BorderSide(color: AppColors.grey200)),
                boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, -5))],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    // Message Button
                    Expanded(
                      flex: 2,
                      child: OutlinedButton(
                        onPressed: _isMessageLoading
                            ? null
                            : () async {
                                try {
                                  setState(() => _isMessageLoading = true);
                                  final userData = await _authService.getUserData(_authService.currentUser!.uid);
                                  final chat = await _chatService.getOrCreateChat(
                                    clientId: _authService.currentUser!.uid,
                                    clientName: userData?['fullName'] ?? 'Client',
                                    clientAvatar: userData?['photoUrl'] ?? '',
                                    lawyerId: lawyer.id,
                                    lawyerName: lawyer.name,
                                    lawyerAvatar: lawyer.photoUrl,
                                  );

                                  if (!context.mounted) return;
                                  context.push('/chat/${chat.id}', extra: {
                                    'lawyerId': lawyer.id,
                                    'lawyerName': lawyer.name,
                                    'lawyerAvatar': lawyer.photoUrl,
                                    'isOnline': true,
                                  });
                                } catch (e) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${loc.error} $e')));
                                } finally {
                                  if (mounted) setState(() => _isMessageLoading = false);
                                }
                              },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.grey300, width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isMessageLoading
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                            : const PhosphorIcon(PhosphorIconsRegular.chatCircleText, size: 24),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    // Book Consultation Button
                    Expanded(
                      flex: 5,
                      child: FilledButton(
                        onPressed: () => context.push('/booking/${lawyer.id}'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          foregroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: Text(
                          'Book Consult - PKR ${lawyer.pricePerConsultation}',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                        ),
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

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w800,
        color: AppColors.primary,
        letterSpacing: -0.5,
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final PhosphorIconData icon;
  final String value;
  final String label;

  const _StatCard({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.grey200),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: PhosphorIcon(icon, size: 20, color: AppColors.secondary),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
