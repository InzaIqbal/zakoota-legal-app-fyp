import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
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
                      'Refine Results',
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
                    Text('Sort By',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm, // Added vertical spacing
                      children: [
                        'Newest',
                        'Budget: High to Low',
                        'Budget: Low to High'
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
                    Text('Job Type',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        'Corporate',
                        'Criminal',
                        'Civil',
                        'Property',
                        'Family'
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
                    Text('Budget Range (PKR)',
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
                        Text('0k',
                            style: Theme.of(context).textTheme.bodySmall),
                        Text('1000k+',
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
                    child: const Text('Show Results',
                        style: TextStyle(fontWeight: FontWeight.bold)),
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

    return Scaffold(
      backgroundColor: AppColors.background,
      body: StreamBuilder<List<CaseModel>>(
        stream: _caseService.getOpenCases(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
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
              // Assuming filters match categories. Note: JobMockData had categories mapping.
              // CaseModel has 'category' field. JobOpportunity also has 'category'.
              // If filter is "Corporate", check if job.category == "Corporate"
              // The current filters in modal are: Corporate, Criminal, Civil, Property, Family
              if (!_selectedFilters.contains(job.category)) {
                return false;
              }
            }

            // 3. Budget (Optional enhancement, not strictly enforced in current UI logic)

            return true;
          }).toList();

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
                  'Find Work',
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
                                    hintText: 'Search jobs...',
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
                                      'Filter',
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
              if (filteredJobs.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(PhosphorIconsRegular.briefcase,
                            size: 48, color: AppColors.textSecondary),
                        const SizedBox(height: AppSpacing.md),
                        const Text(
                          'No jobs found',
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
                        final job = filteredJobs[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: JobOpportunityCard(job: job),
                        );
                      },
                      childCount: filteredJobs.length,
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
