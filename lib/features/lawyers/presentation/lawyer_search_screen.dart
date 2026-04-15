import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../../ads/models/lawyer_ad_model.dart';
import '../../ads/services/lawyer_ad_service.dart';
import '../data/lawyer_mock_data.dart';
import '../services/lawyer_service.dart';
import '../../../core/widgets/user_avatar.dart';

/// Lawyer Search Screen - Find and filter lawyers
class LawyerSearchScreen extends StatefulWidget {
  final String? category;

  const LawyerSearchScreen({
    super.key,
    this.category,
  });

  @override
  State<LawyerSearchScreen> createState() => _LawyerSearchScreenState();
}

class _LawyerSearchScreenState extends State<LawyerSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final LawyerService _lawyerService = LawyerService();
  final LawyerAdService _lawyerAdService = LawyerAdService();
  List<LawyerProfile> _filteredLawyers = [];
  List<LawyerAdModel> _filteredAds = [];
  List<_SearchResultItem> _searchResults = [];
  bool _verifiedOnly = false;
  bool _highRating = false;
  String _sortBy = '';
  bool _isLoading = true;
  
  // Available legal service categories
  static const List<String> _categories = [
    'Criminal',
    'Property',
    'Family',
    'Corporate',
    'Civil',
    'Startups',
  ];
  
  late String? _selectedCategory; // Can be changed by user

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.category; // Initialize with passed category
    _applyFilters();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilters() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _lawyerService.searchLawyers(
          category: _selectedCategory,
          query: _searchController.text,
          verifiedOnly: _verifiedOnly,
          minRating: _highRating ? 4.5 : null,
        ),
        _lawyerAdService.searchActiveAds(
          category: _selectedCategory,
          query: _searchController.text,
        ),
      ]);

      final lawyers = results[0] as List<LawyerProfile>;
      final ads = results[1] as List<LawyerAdModel>;

      setState(() {
        _filteredLawyers = lawyers;
        _filteredAds = ads;

        // Sort if needed
        if (_sortBy == 'price_low') {
          _filteredLawyers.sort(
              (a, b) => a.pricePerConsultation.compareTo(b.pricePerConsultation));
        } else if (_sortBy == 'rating') {
          _filteredLawyers.sort((a, b) => (b.rating ?? 0.0).compareTo(a.rating ?? 0.0));
        }

        _searchResults = [
          ..._filteredAds.map((ad) => _SearchResultItem.ad(ad)),
          ..._filteredLawyers.map((lawyer) => _SearchResultItem.lawyer(lawyer)),
        ];
        _isLoading = false;
      });
    } catch (e) {
      print('Error applying filters: $e');
      setState(() => _isLoading = false);
    }
  }

  void _refreshLawyers() {
    // Clear cache and reload
    _lawyerService.clearCache();
    _applyFilters();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Refreshing lawyers...')),
    );
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (context) => SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Filter Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filters',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  IconButton(
                    icon: PhosphorIcon(PhosphorIconsRegular.x),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Legal Service Category
              Text(
                'Legal Service Category',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  FilterChip(
                    label: const Text('All Categories'),
                    selected: _selectedCategory == null || _selectedCategory!.isEmpty,
                    onSelected: (value) {
                      Navigator.pop(context);
                      setState(() => _selectedCategory = null);
                      _applyFilters();
                    },
                    selectedColor: AppColors.primary.withOpacity(0.2),
                    checkmarkColor: AppColors.primary,
                    side: BorderSide(
                      color: _selectedCategory == null || _selectedCategory!.isEmpty
                          ? AppColors.primary
                          : AppColors.grey300,
                    ),
                  ),
                  ..._categories.map((category) {
                    final isSelected = _selectedCategory == category;
                    return FilterChip(
                      label: Text(category),
                      selected: isSelected,
                      onSelected: (value) {
                        Navigator.pop(context);
                        setState(() => _selectedCategory = value ? category : null);
                        _applyFilters();
                      },
                      selectedColor: AppColors.primary.withOpacity(0.2),
                      checkmarkColor: AppColors.primary,
                      side: BorderSide(
                        color: isSelected ? AppColors.primary : AppColors.grey300,
                      ),
                    );
                  }).toList(),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Additional Filters
              Text(
                'More Filters',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  FilterChip(
                    label: const Text('Verified'),
                    selected: _verifiedOnly,
                    onSelected: (value) {
                      setState(() => _verifiedOnly = value);
                      _applyFilters();
                    },
                    selectedColor: AppColors.secondary.withOpacity(0.2),
                    checkmarkColor: AppColors.secondary,
                    side: BorderSide(
                      color: _verifiedOnly ? AppColors.secondary : AppColors.grey300,
                    ),
                  ),
                  FilterChip(
                    label: const Text('Price: Low-High'),
                    selected: _sortBy == 'price_low',
                    onSelected: (value) {
                      setState(() => _sortBy = value ? 'price_low' : '');
                      _applyFilters();
                    },
                    selectedColor: AppColors.secondary.withOpacity(0.2),
                    checkmarkColor: AppColors.secondary,
                    side: BorderSide(
                      color: _sortBy == 'price_low' ? AppColors.secondary : AppColors.grey300,
                    ),
                  ),
                  FilterChip(
                    label: const Text('Rating 4.5+'),
                    selected: _highRating,
                    onSelected: (value) {
                      setState(() => _highRating = value);
                      _applyFilters();
                    },
                    selectedColor: AppColors.secondary.withOpacity(0.2),
                    checkmarkColor: AppColors.secondary,
                    side: BorderSide(
                      color: _highRating ? AppColors.secondary : AppColors.grey300,
                    ),
                  ),
                  FilterChip(
                    label: const Text('Experience'),
                    selected: _sortBy == 'experience',
                    onSelected: (value) {
                      setState(() => _sortBy = value ? 'experience' : '');
                      _applyFilters();
                    },
                    selectedColor: AppColors.secondary.withOpacity(0.2),
                    checkmarkColor: AppColors.secondary,
                    side: BorderSide(
                      color: _sortBy == 'experience' ? AppColors.secondary : AppColors.grey300,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Clear All Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: PhosphorIcon(PhosphorIconsRegular.trash),
                  label: const Text('Clear All Filters'),
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {
                      _selectedCategory = null;
                      _verifiedOnly = false;
                      _highRating = false;
                      _sortBy = '';
                      _searchController.clear();
                    });
                    _applyFilters();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.grey300,
                    foregroundColor: AppColors.textPrimary,
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
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Find a Lawyer',
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          icon: PhosphorIcon(
            PhosphorIconsRegular.arrowLeft,
            color: colorScheme.primary,
          ),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: PhosphorIcon(
              PhosphorIconsRegular.arrowClockwise,
              color: colorScheme.primary,
            ),
            onPressed: _refreshLawyers,
            tooltip: 'Refresh lawyers',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar with Filter Icon
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            color: AppColors.surface,
            child: TextField(
              controller: _searchController,
              onChanged: (_) => _applyFilters(),
              decoration: InputDecoration(
                hintText: 'Search by name or keyword',
                prefixIcon: PhosphorIcon(
                  PhosphorIconsRegular.magnifyingGlass,
                  color: AppColors.textSecondary,
                ),
                suffixIcon: IconButton(
                  icon: PhosphorIcon(
                    PhosphorIconsRegular.funnelSimple,
                    color: AppColors.primary,
                  ),
                  onPressed: _showFilterModal,
                ),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
              ),
            ),
          ),

          // Results Count
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            alignment: Alignment.centerLeft,
            child: Text(
              '${_searchResults.length} results (${_filteredAds.length} ads, ${_filteredLawyers.length} lawyers)${_selectedCategory != null && _selectedCategory!.isNotEmpty ? ' in ${_selectedCategory}' : ''}',
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),

          // Lawyer List
          Expanded(
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          color: colorScheme.primary,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Loading lawyers...',
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : _searchResults.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            PhosphorIcon(
                              PhosphorIconsRegular.magnifyingGlass,
                              size: 64,
                              color: AppColors.textLight,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'No lawyers found',
                              style: textTheme.bodyLarge?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final item = _searchResults[index];
                          if (item.ad != null) {
                            return LawyerAdSearchCard(ad: item.ad!);
                          }

                          final lawyer = item.lawyer!;
                          return LawyerSearchCard(
                            lawyer: lawyer,
                            onTap: () {
                              context.push('/lawyer-profile/${lawyer.id}');
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _SearchResultItem {
  final LawyerAdModel? ad;
  final LawyerProfile? lawyer;

  const _SearchResultItem._({this.ad, this.lawyer});

  factory _SearchResultItem.ad(LawyerAdModel ad) {
    return _SearchResultItem._(ad: ad);
  }

  factory _SearchResultItem.lawyer(LawyerProfile lawyer) {
    return _SearchResultItem._(lawyer: lawyer);
  }
}

class LawyerAdSearchCard extends StatelessWidget {
  final LawyerAdModel ad;

  const LawyerAdSearchCard({super.key, required this.ad});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.secondary.withOpacity(0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              UserAvatar(
                uid: ad.lawyerId,
                radius: 20,
                fallbackName: ad.lawyerName,
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                ),
                child: const Text(
                  'AD',
                  style: TextStyle(
                    color: AppColors.secondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  ad.lawyerName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              Text(
                ad.locationMode,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            ad.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            ad.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _adInfoChip(ad.category),
              _adInfoChip(ad.duration),
              _adInfoChip(
                'PKR ${ad.price.toStringAsFixed(0)} ${ad.pricingType == 'hourly' ? '/hr' : ''}',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                context.push('/book-lawyer-ad/${ad.id}');
              },
              child: const Text('Book This Ad'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _adInfoChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Lawyer Search Card Widget
class LawyerSearchCard extends StatelessWidget {
  final LawyerProfile lawyer;
  final VoidCallback onTap;

  const LawyerSearchCard({
    super.key,
    required this.lawyer,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Avatar + Name + Title + Location
          Row(
            children: [
              // Avatar
              UserAvatar(
                uid: lawyer.id,
                radius: 30,
                fallbackName: lawyer.name,
              ),
              const SizedBox(width: AppSpacing.md),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            lawyer.name,
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                        if (lawyer.isVerified)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(AppRadius.xs),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                PhosphorIcon(
                                  PhosphorIconsRegular.seal,
                                  size: 12,
                                  color: AppColors.success,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  'Verified',
                                  style: textTheme.labelSmall?.copyWith(
                                    color: AppColors.success,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      lawyer.title,
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        PhosphorIcon(
                          PhosphorIconsRegular.mapPin,
                          size: 14,
                          color: AppColors.textLight,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          lawyer.location,
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.textLight,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // Row 2: Specialization Badges
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: lawyer.specializations.take(3).map((spec) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.2),
                  ),
                ),
                child: Text(
                  spec,
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.primary,
                    fontSize: 11,
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: AppSpacing.md),

          // Row 3: Stats + Price
          Row(
            children: [
              // Stats
              Row(
                children: [
                  PhosphorIcon(
                    PhosphorIconsFill.star,
                    size: 16,
                    color: AppColors.secondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${lawyer.rating}',
                    style: textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '• ${lawyer.reviewsCount} Reviews',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.textLight,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),

              const Spacer(),

              // Price
              Text(
                'PKR ${lawyer.pricePerConsultation.toStringAsFixed(0)}/consult',
                style: textTheme.labelLarge?.copyWith(
                  color: colorScheme.secondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // Row 4: View Profile Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: colorScheme.primary, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              ),
              child: const Text('View Profile'),
            ),
          ),
        ],
      ),
    );
  }
}
