import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';
import '../../../l10n/app_localizations.dart';

import '../../../core/constants/app_constants.dart';
import '../models/lawyer_ad_model.dart';
import '../services/lawyer_ad_service.dart';

class ManageLawyerAdsScreen extends StatelessWidget {
  const ManageLawyerAdsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(body: Center(child: Text(loc.pleaseLoginToManageAds)));
    }

    final service = LawyerAdService();
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const PhosphorIcon(PhosphorIconsRegular.arrowLeft),
          onPressed: () => context.pop(),
        ),
        title: Text(
          loc.manageAds,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.icon(
              onPressed: () => context.push('/lawyer-create-ad'),
              icon: const Icon(Icons.add, size: 18),
              label: Text(loc.newAd),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<LawyerAdModel>>(
        stream: service.streamMyAds(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const PhosphorIcon(PhosphorIconsRegular.warning, size: 48, color: AppColors.error),
                  const SizedBox(height: 12),
                  Text(loc.errorLoadingAds, style: textTheme.titleMedium),
                ],
              ),
            );
          }

          final ads = snapshot.data ?? [];
          if (ads.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const PhosphorIcon(
                      PhosphorIconsRegular.megaphone,
                      size: 56,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(loc.noAdsYet, style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    loc.createYourFirstAdToAttractClients,
                    style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  FilledButton.icon(
                    onPressed: () => context.push('/lawyer-create-ad'),
                    icon: const Icon(Icons.add),
                    label: Text(loc.createAd),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            );
          }

          final activeAdsCount = ads.where((a) => a.isActive).length;
          final totalBookings = ads.fold<int>(0, (sum, a) => sum + a.bookings);

          return FutureBuilder<int>(
            future: service.getActiveCaseCount(user.uid),
            builder: (context, caseSnapshot) {
              final activeCaseCount = caseSnapshot.data ?? 0;

              return ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  Card(
                    color: activeCaseCount >= 5 ? AppColors.error.withValues(alpha: 0.08) : AppColors.surface,
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Row(
                        children: [
                          const PhosphorIcon(PhosphorIconsRegular.usersThree, color: AppColors.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(loc.activeCasesLimit, style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text(loc.activeCasesInUse(activeCaseCount)),
                                if (activeCaseCount >= 5)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      loc.adsPausedDueToLimit,
                                      style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (activeCaseCount >= 5)
                            const PhosphorIcon(PhosphorIconsRegular.warning, color: AppColors.error),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      _StatCard(
                        label: loc.totalAds,
                        value: ads.length.toString(),
                        icon: PhosphorIconsRegular.megaphone,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _StatCard(
                        label: loc.active,
                        value: activeAdsCount.toString(),
                        icon: PhosphorIconsRegular.checkCircle,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _StatCard(
                        label: loc.bookings,
                        value: totalBookings.toString(),
                        icon: PhosphorIconsRegular.shoppingBag,
                        color: AppColors.info,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    loc.yourAds,
                    style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ...ads.map((ad) => _AdCard(ad: ad, service: service, activeCaseCount: activeCaseCount)),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final PhosphorIconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.grey200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PhosphorIcon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdCard extends StatelessWidget {
  final LawyerAdModel ad;
  final LawyerAdService service;
  final int activeCaseCount;

  const _AdCard({required this.ad, required this.service, required this.activeCaseCount});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final loc = AppLocalizations.of(context);
    final isActive = ad.isActive;
    final dateFormat = DateFormat('MMM d, yyyy');

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Section: Info + Status
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: PhosphorIcon(
                      _getCategoryIcon(ad.category),
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ad.title,
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          _Tag(label: ad.category, color: AppColors.primary),
                          _Tag(label: 'PKR ${ad.price.toInt()}', color: AppColors.secondary),
                          _Tag(label: ad.locationMode, color: AppColors.info),
                        ],
                      ),
                    ],
                  ),
                ),
                _StatusBadge(ad: ad),
              ],
            ),
          ),

          // Divider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Divider(height: 1, color: AppColors.grey200),
          ),

          // Bottom Section: Stats + Actions
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                // Metadata
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const PhosphorIcon(PhosphorIconsRegular.shoppingBag,
                            size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          loc.bookingsCount(ad.bookings),
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      loc.createdDate(dateFormat.format(ad.createdAt)),
                      style: textTheme.labelSmall?.copyWith(
                        color: AppColors.textLight,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                const Spacer(),

                // Action Menu
                PopupMenuButton<String>(
                  icon: const PhosphorIcon(PhosphorIconsRegular.dotsThreeOutline,
                      color: AppColors.textSecondary),
                  onSelected: (value) async {
                    if (value == 'edit') {
                      context.push('/lawyer-edit-ad/${ad.id}');
                    } else if (value == 'toggle') {
                      if (!isActive && ad.isPausedDueToActiveCases && activeCaseCount >= 5) {
                        await _showCaseLimitDialog(context);
                        return;
                      }
                      try {
                        await service.setAdActiveWithValidation(ad.id, !isActive, ad.lawyerId);
                      } catch (_) {
                        if (context.mounted) {
                          await _showCaseLimitDialog(context);
                        }
                      }
                    } else if (value == 'delete') {
                      _showDeleteDialog(context);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          PhosphorIcon(PhosphorIconsRegular.trash, size: 18, color: AppColors.error),
                          const SizedBox(width: 8),
                          Text(loc.deleteAd, style: const TextStyle(color: AppColors.error)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'toggle',
                      child: Row(
                        children: [
                          PhosphorIcon(isActive ? PhosphorIconsRegular.pause : PhosphorIconsRegular.play, size: 18),
                          const SizedBox(width: 8),
                          Text(isActive ? loc.pauseAd : loc.activateAd, style: textTheme.bodyMedium),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          PhosphorIcon(PhosphorIconsRegular.trash, size: 18, color: AppColors.error),
                          const SizedBox(width: 8),
                          Text(loc.deleteAd, style: const TextStyle(color: AppColors.error)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PhosphorIconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'criminal': return PhosphorIconsRegular.gavel;
      case 'property': return PhosphorIconsRegular.buildings;
      case 'family': return PhosphorIconsRegular.users;
      case 'corporate': return PhosphorIconsRegular.briefcase;
      case 'civil': return PhosphorIconsRegular.scales;
      case 'startups': return PhosphorIconsRegular.rocketLaunch;
      default: return PhosphorIconsRegular.megaphone;
    }
  }

  void _showDeleteDialog(BuildContext context) async {
    final loc = AppLocalizations.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.deleteAd),
        content: Text(loc.deleteAdConfirm(ad.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(loc.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(loc.delete),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await service.deleteAd(ad.id);
    }
  }

  Future<void> _showCaseLimitDialog(BuildContext context) async {
    final loc = AppLocalizations.of(context);
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.cannotReactivateAd),
        content: Text(loc.cannotReactivateAdMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(loc.dismiss),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final LawyerAdModel ad;
  const _StatusBadge({required this.ad});

  @override
  Widget build(BuildContext context) {
    final isCaseLimitPaused = ad.isPausedDueToActiveCases;
    final isActive = ad.isActive;
    final backgroundColor = isCaseLimitPaused
        ? AppColors.error.withValues(alpha: 0.08)
        : isActive
            ? AppColors.success.withValues(alpha: 0.08)
            : AppColors.grey200;
    final textColor = isCaseLimitPaused
        ? AppColors.error
        : isActive
            ? AppColors.success
            : AppColors.textSecondary;
    final label = isCaseLimitPaused ? 'Paused (5 cases)' : isActive ? 'Active' : 'Paused';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: textColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;

  const _Tag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
