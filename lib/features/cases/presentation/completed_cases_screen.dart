import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_constants.dart';
import '../models/case_model.dart';
import '../services/case_service.dart';

class CompletedCasesScreen extends StatelessWidget {
  const CompletedCasesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text('Please log in.')));

    return FutureBuilder<String?>(
      future: _getUserRole(user.uid),
      builder: (context, roleSnapshot) {
        if (roleSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        
        final role = roleSnapshot.data ?? 'client';
        final isLawyer = role == 'lawyer';

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Completed Cases'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: StreamBuilder<List<CaseModel>>(
            stream: isLawyer 
              ? CaseService().getCompletedCasesForLawyer(user.uid)
              : CaseService().getCompletedCasesForClient(user.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final cases = snapshot.data ?? [];

              if (cases.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      PhosphorIcon(
                        PhosphorIconsRegular.archive,
                        size: 64,
                        color: AppColors.textLight,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No completed cases yet.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: cases.length,
                itemBuilder: (context, index) {
                  final caseModel = cases[index];
                  return _CompletedCaseCard(caseModel: caseModel);
                },
              );
            },
          ),
        );
      },
    );
  }

  Future<String?> _getUserRole(String uid) async {
    final doc = await CaseService().getFirestore().collection('users').doc(uid).get();
    return doc.data()?['role'];
  }
}

class _CompletedCaseCard extends StatelessWidget {
  final CaseModel caseModel;

  const _CompletedCaseCard({required this.caseModel});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  caseModel.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'COMPLETED',
                  style: TextStyle(
                    color: AppColors.success,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            caseModel.description,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Completed on ${_formatDate(caseModel.completedAt ?? caseModel.createdAt)}',
                style: const TextStyle(color: AppColors.textLight, fontSize: 11),
              ),
              TextButton(
                onPressed: () {
                  final isClient = caseModel.clientId == FirebaseAuth.instance.currentUser?.uid;
                  context.push('/case-workspace?caseId=${caseModel.caseId}&isClient=$isClient', extra: {
                    'caseModel': caseModel,
                    'isClient': isClient,
                  });
                },
                child: const Text('View Workspace'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

extension on CaseService {
  // Helper to access firestore if needed, though better to avoid exposing it
  // But for the _getUserRole helper it's easier
  dynamic getFirestore() => FirebaseFirestore.instance;
}
