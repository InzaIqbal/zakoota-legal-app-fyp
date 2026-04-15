import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/auth_service.dart';
import '../models/wallet_transaction_model.dart';
import '../services/wallet_service.dart';
import 'widgets/add_funds_dialog.dart';

/// Wallet Screen - View balance and transactions
class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final AuthService _authService = AuthService();
  final WalletService _walletService = WalletService();

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please login to access wallet')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: PhosphorIcon(
            PhosphorIconsRegular.arrowLeft,
            color: Colors.white,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'My Wallet',
          style: textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Column(
        children: [
          // Top Section - Navy Background with Balance
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.xl,
              horizontal: AppSpacing.lg,
            ),
            decoration: const BoxDecoration(
              color: AppColors.primary,
            ),
            child: Column(
              children: [
                // Balance Display
                Text(
                  'Total Balance',
                  style: textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                StreamBuilder<double>(
                  stream: _walletService.streamWalletBalance(user.uid),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Text(
                        'PKR 0.00',
                        style: textTheme.displaySmall?.copyWith(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w700,
                        ),
                      );
                    }
                    final balance = snapshot.data ?? 0;
                    return Text(
                      'PKR ${balance.toStringAsFixed(2)}',
                      style: textTheme.displaySmall?.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w700,
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.lg),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => const AddFundsDialog(),
                          );
                        },
                        icon: PhosphorIcon(
                          PhosphorIconsRegular.plus,
                          size: 20,
                        ),
                        label: const Text('Add Money'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          foregroundColor: AppColors.textPrimary,
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.md,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          context.push('/withdraw');
                        },
                        icon: PhosphorIcon(
                          PhosphorIconsRegular.bank,
                          size: 20,
                          color: Colors.white,
                        ),
                        label: const Text('Withdraw'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white),
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.md,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Bottom Section - White Container with Transactions
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(AppRadius.xl),
                  topRight: Radius.circular(AppRadius.xl),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Text(
                      'Recent Transactions',
                      style: textTheme.titleLarge?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),

                  // Transactions List
                  Expanded(
                    child: StreamBuilder<List<WalletTransactionModel>>(
                        stream: _walletService.streamWalletTransactions(user.uid),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(AppSpacing.lg),
                                child: Text(
                                  'Unable to load transactions right now.',
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            );
                          }
                          final transactions = snapshot.data ?? [];
                          if (transactions.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  PhosphorIcon(
                                    PhosphorIconsRegular.wallet,
                                    size: 64,
                                    color: AppColors.textLight,
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  Text(
                                    'No transactions yet',
                                    style: textTheme.bodyLarge?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                          return ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                            ),
                            itemCount: transactions.length,
                            itemBuilder: (context, index) {
                              return TransactionTile(
                                transaction: transactions[index],
                              );
                            },
                          );
                        },
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

/// Transaction Tile Widget
class TransactionTile extends StatelessWidget {
  final WalletTransactionModel transaction;

  const TransactionTile({
    super.key,
    required this.transaction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final isCredit = transaction.type == WalletTxType.credit;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          // Leading Icon
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: isCredit
                  ? AppColors.success.withValues(alpha: 0.1)
                  : AppColors.error.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: PhosphorIcon(
              isCredit
                  ? PhosphorIconsRegular.arrowDown
                  : PhosphorIconsRegular.arrowUp,
              size: 20,
              color: isCredit ? AppColors.success : AppColors.error,
            ),
          ),

          const SizedBox(width: AppSpacing.md),

          // Title & Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _displayReason(transaction.reason),
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDate(transaction.createdAt),
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Amount
          Text(
            '${isCredit ? '+' : '-'} PKR ${transaction.amount.toStringAsFixed(0)}',
            style: textTheme.titleMedium?.copyWith(
              color: isCredit ? AppColors.success : AppColors.error,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _displayReason(String reason) {
    switch (reason) {
      case 'deposit_dummy':
        return 'Wallet Deposit';
      case 'withdrawal_request':
        return 'Withdrawal Request';
      case 'consultation_booking':
        return 'Consultation Booking';
      case 'invoice_payment':
        return 'Invoice Payment';
      default:
        return reason.replaceAll('_', ' ').trim().isEmpty
            ? 'Wallet Transaction'
            : reason.replaceAll('_', ' ');
    }
  }
}
