import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../jobs/models/proposal.dart';

class ClientProposalCard extends StatelessWidget {
  final Proposal proposal;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback? onUnreject;
  final VoidCallback onMessage;
  final VoidCallback onViewProfile;
  final bool isProcessing;

  const ClientProposalCard({
    super.key,
    required this.proposal,
    required this.onAccept,
    required this.onReject,
    required this.onMessage,
    required this.onViewProfile,
    this.onUnreject,
    this.isProcessing = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final isRejected = proposal.status == 'rejected';
    final isAccepted = proposal.status == 'accepted';

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: isRejected
            ? AppColors.grey100
            : (isAccepted ? const Color(0xFFF0FDF4) : Colors.white),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isAccepted
              ? AppColors.success
              : (isRejected ? AppColors.grey300 : AppColors.grey200),
          width: isAccepted ? 2 : 1,
        ),
        boxShadow: isRejected
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Banner (if not pending)
          if (!isRejected && !isAccepted)
            // Optional: New Tag etc
            const SizedBox.shrink()
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  vertical: 4, horizontal: AppSpacing.md),
              decoration: BoxDecoration(
                color: isAccepted ? AppColors.success : AppColors.grey400,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppRadius.md),
                  topRight: Radius.circular(AppRadius.md),
                ),
              ),
              child: Text(
                isAccepted ? 'ACCEPTED PROPOSAL' : 'REJECTED',
                style: textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
                textAlign: TextAlign.center,
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Opacity(
              opacity: isRejected ? 0.6 : 1.0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: Lawyer Info & Bid
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: onViewProfile,
                        child: CircleAvatar(
                          backgroundImage: NetworkImage(proposal.lawyerImage),
                          radius: 24,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: GestureDetector(
                          onTap: onViewProfile,
                          behavior: HitTestBehavior.opaque,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                proposal.lawyerName,
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  PhosphorIcon(PhosphorIconsFill.star,
                                      size: 14, color: Colors.amber),
                                  const SizedBox(width: 4),
                                  Text(
                                    proposal.rating.toStringAsFixed(1),
                                    style: textTheme.bodySmall,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '• ${proposal.location}',
                                    style: textTheme.bodySmall?.copyWith(
                                        color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'PKR ${proposal.bidAmount.toInt()}',
                            style: textTheme.titleMedium?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            proposal.duration,
                            style: textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const Divider(height: 24),

                  // Cover Letter
                  Text(
                    'Cover Letter',
                    style: textTheme.labelMedium?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    proposal.coverLetter,
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                      height: 1.4,
                    ),
                    maxLines: isRejected ? 2 : 4,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Actions
                  Wrap(
                    alignment: WrapAlignment.end,
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      // Message Button (Always visible)
                      OutlinedButton.icon(
                        onPressed: onMessage,
                        icon: PhosphorIcon(PhosphorIconsRegular.chatCircle,
                            size: 18),
                        label: const Text('Message'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                          side: const BorderSide(color: AppColors.grey300),
                        ),
                      ),

                      // Accept/Reject Buttons (Only if pending)
                      if (proposal.status == 'pending') ...[
                        OutlinedButton(
                          onPressed: isProcessing ? null : onReject,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: const BorderSide(color: AppColors.error),
                          ),
                          child: const Text('Reject'),
                        ),
                        FilledButton.icon(
                          onPressed: isProcessing ? null : onAccept,
                          icon: PhosphorIcon(PhosphorIconsRegular.check,
                              size: 18),
                          label: const Text('Accept'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.success,
                          ),
                        ),
                      ],

                      // Un-reject Button (Only if rejected)
                      if (isRejected)
                        OutlinedButton.icon(
                          onPressed: isProcessing ? null : onUnreject,
                          icon: PhosphorIcon(PhosphorIconsRegular.arrowUUpLeft,
                              size: 18),
                          label: const Text('Undo Rejection'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textSecondary,
                            side: const BorderSide(color: AppColors.grey400),
                          ),
                        ),
                    ],
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
