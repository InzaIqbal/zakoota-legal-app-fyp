import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/constants/app_constants.dart';
import '../../cases/models/case_model.dart';
import '../../cases/services/case_service.dart';
import '../../jobs/models/job_opportunity.dart';
import 'widgets/job_opportunity_card.dart';

/// Job Board Screen
class JobBoardScreen extends StatefulWidget {
  const JobBoardScreen({super.key});

  @override
  State<JobBoardScreen> createState() => _JobBoardScreenState();
}

class _JobBoardScreenState extends State<JobBoardScreen> {
  final _searchController = TextEditingController();
  final _caseService = CaseService();

  // Filter States
  String _selectedSort = 'Newest';
  final Set<String> _selectedFilters = {};
  RangeValues _budgetRange = const RangeValues(0, 500);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showFilterModal() {
    final loc = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) => Column(
            children: [
              // Modal Header
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      loc.refineResults,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Filter Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    // Sort By
                    Text(loc.sortBy,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm, // Added vertical spacing
                      children: [
                        loc.newest,
                        loc.budgetHighToLow,
                        loc.budgetLowToHigh
                      ].map((sort) {
                        final isSelected = _selectedSort == sort;
                        return ChoiceChip(
                          label: Text(sort),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setModalState(() => _selectedSort = sort);
                              setState(
                                  () => _selectedSort = sort); // Update parent
                            }
                          },
                          // Standardize Selected Color
                          selectedColor: AppColors.primary,
                          backgroundColor: AppColors.surface,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : AppColors.textPrimary,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.full),
                            side: BorderSide(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.grey300,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Job Type
                    Text(loc.jobType,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        loc.corporate,
                        loc.criminal,
                        loc.civil,
                        loc.property,
                        loc.family
                      ].map((filter) {
                        final isSelected = _selectedFilters.contains(filter);
                        return FilterChip(
                          label: Text(filter),
                          selected: isSelected,
                          onSelected: (selected) {
                            setModalState(() {
                              selected
                                  ? _selectedFilters.add(filter)
                                  : _selectedFilters.remove(filter);
                            });
                            setState(
                                () {}); // Update parent to reflect count or active state
                          },
                          // Standardize Selected Color
                          selectedColor: AppColors.primary,
                          checkmarkColor: Colors.white,
                          backgroundColor: AppColors.surface,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : AppColors.textPrimary,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.full),
                            side: BorderSide(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.grey300,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Budget Range
                    Text(loc.budgetRangePkr,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.md),
                    RangeSlider(
                      values: _budgetRange,
                      min: 0,
                      max: 1000,
                      divisions: 20,
                      activeColor: AppColors.primary,
                      inactiveColor: AppColors.grey300,
                      labels: RangeLabels('${_budgetRange.start.round()}k',
                          '${_budgetRange.end.round()}k'),
                      onChanged: (values) {
                        setModalState(() => _budgetRange = values);
                        setState(() => _budgetRange = values);
                      },
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(loc.zeroK,
                            style: Theme.of(context).textTheme.bodySmall),
                        Text(loc.thousandKPlus,
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ],
                ),
              ),

              // Apply Button
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      // Apply logic here
                      Navigator.pop(context);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                    ),
                    child: Text(loc.showResults,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final loc = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: StreamBuilder<List<CaseModel>>(
        stream: _caseService.getOpenCases(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('${loc.error}: ${snapshot.error}'));
          }

          final allCases = snapshot.data ?? [];
          final jobs =
              allCases.map((c) => JobOpportunity.fromCaseModel(c)).toList();

          // Apply Filters
          final filteredJobs = jobs.where((job) {
            // 1. Search Query
            if (_searchController.text.isNotEmpty) {
              final query = _searchController.text.toLowerCase();
              if (!job.title.toLowerCase().contains(query) &&
                  !job.description.toLowerCase().contains(query)) {
                return false;
              }
            }

            // 2. Filters (Category/Job Type)
            if (_selectedFilters.isNotEmpty) {
              if (!_selectedFilters.contains(job.category)) {
                return false;
              }
            }

            // 3. Budget Range Filter
            final budgetMin = _budgetRange.start * 1000; // Convert k to actual value
            final budgetMax = _budgetRange.end * 1000;
            final jobBudget = job.budgetMax; // Using max budget for comparison
            if (jobBudget < budgetMin || jobBudget > budgetMax) {
              return false;
            }

            return true;
          }).toList();

          // Apply Sorting
          final sortedJobs = [...filteredJobs];
          if (_selectedSort == loc.newest) {
            sortedJobs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          } else if (_selectedSort == loc.budgetHighToLow) {
            sortedJobs.sort((a, b) => b.budgetMax.compareTo(a.budgetMax));
          } else if (_selectedSort == loc.budgetLowToHigh) {
            sortedJobs.sort((a, b) => a.budgetMax.compareTo(b.budgetMax));
          }

          final displayJobs = sortedJobs;

          return CustomScrollView(
            slivers: [
              // 1. Simplified Header
              SliverAppBar(
                pinned: true,
                floating: false,
                backgroundColor: AppColors.primary, // Updated to lighter color
                elevation: 0,
                collapsedHeight: 60,
                toolbarHeight: 60,
                automaticallyImplyLeading: false, // Remove back button
                title: Text(
                  loc.findWork,
                  style: textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                centerTitle: false,
              ),

              // 2. Search & Filter Bar (Pinned)
              SliverToBoxAdapter(
                child: Container(
                  color: AppColors.primary, // Updated to lighter color
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 50,
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(AppRadius.full),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(PhosphorIconsRegular.magnifyingGlass,
                                  color: AppColors.textSecondary),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  onChanged: (value) => setState(
                                      () {}), // Trigger rebuild on search
                                  decoration: InputDecoration(
                                    hintText: loc.searchJobs,
                                    hintStyle: TextStyle(
                                        color: AppColors.textSecondary
                                            .withValues(alpha: 0.6)),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                              Container(
                                height: 24,
                                width: 1,
                                color: AppColors.grey300,
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 8),
                              ),
                              InkWell(
                                onTap: _showFilterModal,
                                borderRadius: BorderRadius.circular(4),
                                child: Row(
                                  children: [
                                    const Icon(PhosphorIconsRegular.faders,
                                        size: 18, color: AppColors.primary),
                                    const SizedBox(width: 4),
                                    Text(
                                      loc.filter,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 3. Job List
              if (displayJobs.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(PhosphorIconsRegular.briefcase,
                            size: 48, color: AppColors.textSecondary),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          loc.noJobsFound,
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final job = displayJobs[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: JobOpportunityCard(job: job),
                        );
                      },
                      childCount: displayJobs.length,
                    ),
                  ),
                ),

              // Bottom Padding
              const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
            ],
          );
        },
      ),
    );
  }
}
