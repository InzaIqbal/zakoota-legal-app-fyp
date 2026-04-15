import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../models/job_opportunity.dart';

class JobOpportunityCard extends StatelessWidget {
  final JobOpportunity job;

  const JobOpportunityCard({super.key, required this.job});

  bool get _isHighBudget {
    final match = RegExp(r'(\d+)').firstMatch(job.budgetLabel);
    final value = match == null ? 0 : int.tryParse(match.group(1)!) ?? 0;
    return value > 50;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isHighBudget = _isHighBudget;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Budget Badge + Posted Time
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: isHighBudget
                  ? AppColors.secondary.withValues(alpha: 0.1)
                  : AppColors.grey100,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.lg),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isHighBudget ? AppColors.secondary : AppColors.grey300,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    isHighBudget ? 'HIGH BUDGET' : 'STANDARD',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Text(
                  job.postedAgo,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  job.title,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                // Tags
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _TagChip(
                      label: job.location,
                      icon: Icons.location_on_outlined,
                    ),
                    _TagChip(
                      label: _formatBudget(job.budgetLabel),
                      icon: Icons.attach_money,
                      isHighlight: true,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Description
                Text(
                  job.description,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.lg),

                Divider(height: 1, color: AppColors.grey200),
                const SizedBox(height: AppSpacing.md),

                // Footer: Proposals + Action
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Proposals',
                          style: textTheme.labelSmall?.copyWith(
                            color: AppColors.textLight,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.people_outline,
                                size: 14, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Text(
                              '${job.proposalCount}',
                              style: textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(width: AppSpacing.xl),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Client Rating',
                          style: textTheme.labelSmall?.copyWith(
                            color: AppColors.textLight,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded,
                                size: 16, color: AppColors.warning),
                            const SizedBox(width: 4),
                            Text(
                              job.clientRating.toString(),
                              style: textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Spacer(),
                    FilledButton(
                      onPressed: () {
                        context.push('/job-details/${job.id}', extra: job);
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: 12,
                        ),
                      ),
                      child: const Text('Apply Now'),
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

  String _formatBudget(String budgetLabel) {
    // Extract the first number found
    final match = RegExp(r'(\d+)').firstMatch(budgetLabel);
    if (match == null) return budgetLabel;

    final amountStr = match.group(1) ?? '0';
    final amount = int.tryParse(amountStr) ?? 0;

    if (amount >= 1000) {
      // If it's an exact thousand (e.g. 10000 -> 10k)
      if (amount % 1000 == 0) {
        return 'PKR ${amount ~/ 1000}k';
      }
      // If it's not exact (e.g. 10500 -> 10.5k)
      return 'PKR ${(amount / 1000).toStringAsFixed(1)}k';
    }

    return 'PKR $amount';
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isHighlight;

  const _TagChip({
    required this.label,
    this.icon,
    this.isHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isHighlight
            ? AppColors.primary.withValues(alpha: 0.05)
            : AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isHighlight
              ? AppColors.primary.withValues(alpha: 0.2)
              : AppColors.grey200,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 14,
              color: isHighlight ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isHighlight ? FontWeight.w600 : FontWeight.w500,
              color: isHighlight ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
