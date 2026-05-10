import '../../cases/models/case_model.dart';

class JobOpportunity {
  final String id;
  final String title;
  final String description;
  final String location;
  final String budgetLabel;
  final double budgetMin;
  final double budgetMax;
  final int proposalCount;
  final double clientRating;
  final String postedAgo;
  final String activity;
  final List<String> attachments;
  final String clientId;
  final String category;
  final DateTime createdAt;

  const JobOpportunity({
    required this.id,
    required this.clientId,
    required this.title,
    required this.description,
    required this.location,
    required this.budgetLabel,
    required this.budgetMin,
    required this.budgetMax,
    required this.proposalCount,
    required this.clientRating,
    required this.postedAgo,
    required this.activity,
    required this.attachments,
    required this.category,
    required this.createdAt,
  });

  factory JobOpportunity.fromCaseModel(CaseModel caseModel) {
    final now = DateTime.now();
    final difference = now.difference(caseModel.createdAt);
    String timeAgo;

    if (difference.inDays > 0) {
      timeAgo = '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      timeAgo = '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      timeAgo = '${difference.inMinutes}m ago';
    } else {
      timeAgo = 'Just now';
    }

    String budget;
    if (caseModel.budgetMin == caseModel.budgetMax) {
      budget = 'Budget: ${caseModel.budgetMin.toInt()}';
    } else {
      budget =
          'Budget: ${caseModel.budgetMin.toInt()} - ${caseModel.budgetMax.toInt()}';
    }

    return JobOpportunity(
      id: caseModel.caseId,
      clientId: caseModel.clientId,
      title: caseModel.title,
      description: caseModel.description,
      location: caseModel.city,
      budgetLabel: budget,
      budgetMin: caseModel.budgetMin,
      budgetMax: caseModel.budgetMax,
      proposalCount: caseModel.proposalCount,
      clientRating: 0.0,
      postedAgo: timeAgo,
      activity: '${caseModel.proposalCount} Proposals',
      attachments: caseModel.attachments.map((a) => a.title).toList(),
      category: caseModel.category,
      createdAt: caseModel.createdAt,
    );
  }
}
