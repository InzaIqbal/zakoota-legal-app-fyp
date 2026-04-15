import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import 'widgets/withdraw_dialog.dart';

class WithdrawPage extends StatelessWidget {
  const WithdrawPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Withdraw'),
      ),
      body: const SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(AppSpacing.md),
          child: WithdrawDialog(closeOnSuccess: false),
        ),
      ),
    );
  }
}
