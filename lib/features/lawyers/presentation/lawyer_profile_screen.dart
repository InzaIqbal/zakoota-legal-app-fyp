import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
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
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _lawyer == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error ?? 'Lawyer not found',
                  style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchLawyer,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final lawyer = _lawyer!;

    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // A. Large SliverAppBar with Photo
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                backgroundColor: AppColors.primary,
                leading: IconButton(
                  icon: const PhosphorIcon(
                    PhosphorIconsRegular.arrowLeft,
                    color: Colors.white,
                  ),
                  onPressed: () => context.pop(),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Navy Background
                      Container(color: AppColors.primary),

                      // Lawyer Photo & Info
                      Padding(
                        padding: const EdgeInsets.only(
                          top: 80,
                          left: AppSpacing.lg,
                          right: AppSpacing.lg,
                        ),
                        child: Column(
                          children: [
                            // Photo
                            UserAvatar(
                              uid: lawyer.id,
                              radius: 50,
                              fallbackName: lawyer.name,
                            ),
                            const SizedBox(height: AppSpacing.sm),

                            // Name
                            Text(
                              lawyer.name,
                              style: textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),

                            // Verified Badge
                            if (lawyer.isVerified)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const PhosphorIcon(
                                    PhosphorIconsFill.seal,
                                    size: 16,
                                    color: AppColors.secondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Verified Lawyer',
                                    style: textTheme.bodySmall?.copyWith(
                                      color: AppColors.secondary,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // B. Quick Stats Cards
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: PhosphorIconsRegular.briefcase,
                          value: '${lawyer.experience}+',
                          label: 'Years Exp',
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _StatCard(
                          icon: PhosphorIconsRegular.trophy,
                          value: '${lawyer.casesWon}',
                          label: 'Cases Won',
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _StatCard(
                          icon: PhosphorIconsRegular.star,
                          value: lawyer.ratingDouble.toStringAsFixed(1),
                          label: 'Rating',
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // C. About Me Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'About Me',
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        lawyer.aboutMe,
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.6,
                        ),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                  ),
                ),
              ),

              // D. Specializations
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Specializations',
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: lawyer.specializations.map((spec) {
                          return Chip(
                            label: Text(spec),
                            backgroundColor:
                                AppColors.secondary.withValues(alpha: 0.1),
                            labelStyle: textTheme.labelMedium?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                            side: const BorderSide(
                              color: AppColors.secondary,
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                  ),
                ),
              ),

              // E. Education & Credentials
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Education & Credentials',
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      ...lawyer.education.map((edu) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              PhosphorIcon(
                                PhosphorIconsRegular.graduationCap,
                                size: 18,
                                color: colorScheme.secondary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  edu,
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          PhosphorIcon(
                            PhosphorIconsRegular.scales,
                            size: 18,
                            color: colorScheme.secondary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              lawyer.barLicenseNo,
                              style: textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                  ),
                ),
              ),

              // F. Client Reviews
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Client Reviews',
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: colorScheme.primary,
                            ),
                          ),
                          Text(
                            '${lawyer.reviewsCount} reviews',
                            style: textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: colorScheme.primary,
                                  child: Text(
                                    review.clientName[0],
                                    style: textTheme.labelMedium?.copyWith(
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        review.clientName,
                                        style: textTheme.labelLarge?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          ...List.generate(5, (i) {
                                            return PhosphorIcon(
                                              i < review.rating.floor()
                                                  ? PhosphorIconsFill.star
                                                  : PhosphorIconsRegular.star,
                                              size: 12,
                                              color: AppColors.secondary,
                                            );
                                          }),
                                          const SizedBox(width: 4),
                                          Text(
                                            review.date,
                                            style:
                                                textTheme.bodySmall?.copyWith(
                                              color: AppColors.textLight,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              review.comment,
                              style: textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
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
              const SliverToBoxAdapter(
                child: SizedBox(height: 180),
              ),
            ],
          ),

          // Bottom Action Bar (Fixed)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Message Button
                  OutlinedButton.icon(
                    onPressed: _isMessageLoading
                        ? null
                        : () async {
                            try {
                              setState(() => _isMessageLoading = true);
                              final userData = await _authService.getUserData(
                                  _authService.currentUser!.uid);

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
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text('Error starting chat: $e')),
                            );
                            } finally {
                              if (mounted) {
                                setState(() => _isMessageLoading = false);
                              }
                            }
                          },
                    icon: _isMessageLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const PhosphorIcon(
                            PhosphorIconsRegular.chatCircleText,
                            size: 20,
                          ),
                    label: const Text('Message'),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: colorScheme.primary),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.md,
                      ),
                    ),
                  ),

                  const SizedBox(width: AppSpacing.md),

                  // Book Consultation Button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        context.push('/booking/${lawyer.id}');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        foregroundColor: AppColors.textPrimary,
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.md,
                        ),
                      ),
                      child: Text(
                        'Book Consultation - PKR ${lawyer.pricePerConsultation}',
                        style: textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Quick Stat Card Widget
class _StatCard extends StatelessWidget {
  final PhosphorIconData icon;
  final String value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: AppColors.grey200,
        ),
      ),
      child: Column(
        children: [
          PhosphorIcon(
            icon,
            size: 28,
            color: AppColors.secondary,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          Text(
            label,
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
