import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/constants/app_constants.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Help Center',
          style: theme.textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(AppRadius.xl),
            topRight: Radius.circular(AppRadius.xl),
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Contact Support Card
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Need assistance?',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Our support team is available 24/7 to help you.',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 13),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () {},
                            icon:
                                const Icon(Icons.chat_bubble_outline, size: 18),
                            label: const Text('Chat with Support'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.secondary,
                              foregroundColor: AppColors.textPrimary,
                              minimumSize: const Size(120, 36),
                            ),
                          )
                        ],
                      ),
                    ),
                    PhosphorIcon(PhosphorIconsRegular.headset,
                        size: 60, color: Colors.white.withOpacity(0.2)),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              const Text(
                'Frequently Asked Questions',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary),
              ),

              const SizedBox(height: AppSpacing.md),

              _buildFAQItem('How do I book a lawyer?',
                  'You can search for lawyers by specialization, review their profile, and click "Book Consultation" to schedule an appointment.'),
              _buildFAQItem('Is my payment secure?',
                  'Yes, we use bank-level encryption (SSL) and trusted payment gateways like JazzCash and EasyPaisa.'),
              _buildFAQItem('Can I cancel a booking?',
                  'You can cancel up to 24 hours before the appointment for a full refund.'),
              _buildFAQItem('How do I withdraw funds?',
                  'Go to your Wallet section and request a withdrawal to your bank account or mobile wallet.'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.grey200),
      ),
      child: ExpansionTile(
        title: Text(question,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(answer,
                style: const TextStyle(
                    color: AppColors.textSecondary, height: 1.5)),
          ),
        ],
      ),
    );
  }
}
