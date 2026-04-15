import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_constants.dart';

class LegalArticle {
  final String title;
  final String description;
  final String category;
  final String source;
  final String url;
  final String? image;
  final int readTimeMinutes;

  LegalArticle({
    required this.title,
    required this.description,
    required this.category,
    required this.source,
    required this.url,
    this.image,
    required this.readTimeMinutes,
  });
}

class LegalArticlesScreen extends StatefulWidget {
  const LegalArticlesScreen({super.key});

  @override
  State<LegalArticlesScreen> createState() => _LegalArticlesScreenState();
}

class _LegalArticlesScreenState extends State<LegalArticlesScreen> {
  final List<LegalArticle> articles = [
    LegalArticle(
      title: 'Understanding Your Rights: The Basics of Civil Law',
      description:
          'Learn the fundamental principles of civil law including contracts, property rights, and personal injury claims. This comprehensive guide covers everything you need to know about civil legal matters.',
      category: 'Civil Law',
      source: 'Legal Education Foundation',
      url: 'https://www.legaleducationfoundation.org/civil-law-basics',
      readTimeMinutes: 8,
    ),
    LegalArticle(
      title: 'Family Law: Divorce, Custody, and Alimony Explained',
      description:
          'A detailed guide to family law matters including divorce procedures, child custody arrangements, alimony calculations, and inheritance laws. Know your rights and responsibilities.',
      category: 'Family Law',
      source: 'Family Law Institute',
      url: 'https://www.familylawinstitute.org/divorce-guide',
      readTimeMinutes: 12,
    ),
    LegalArticle(
      title: 'Criminal Law: What Happens When You\'re Arrested',
      description:
          'Understand the criminal justice system from arrest to trial. Learn about your rights, bail conditions, plea agreements, and trial procedures. Essential knowledge for anyone facing criminal charges.',
      category: 'Criminal Law',
      source: 'Bar Association Criminal Law Committee',
      url: 'https://www.criminallaw-guide.org/arrest-procedure',
      readTimeMinutes: 10,
    ),
    LegalArticle(
      title: 'Protecting Your Intellectual Property: Patents and Trademarks',
      description:
          'A guide to protecting your creative work and business ideas. Learn about patents, trademarks, copyrights, and trade secrets. Understand how to register and enforce your intellectual property rights.',
      category: 'Intellectual Property',
      source: 'IP Rights Foundation',
      url: 'https://www.iprights.org/patents-trademarks',
      readTimeMinutes: 9,
    ),
    LegalArticle(
      title: 'Employment Rights: What Your Employer Must Provide',
      description:
          'Know your employment rights including minimum wage, working hours, workplace safety, discrimination protections, and termination procedures. Understand what your employer is legally required to provide.',
      category: 'Employment Law',
      source: 'Workers Rights Coalition',
      url: 'https://www.workersrights.org/employee-protection',
      readTimeMinutes: 11,
    ),
    LegalArticle(
      title: 'Real Estate Law: Buying and Selling Property',
      description:
          'A comprehensive guide to real estate transactions including property searches, due diligence, legal documents, financing, and closing procedures. Essential for anyone buying or selling property.',
      category: 'Property Law',
      source: 'Real Estate Law Society',
      url: 'https://www.realestate-law.org/buying-selling',
      readTimeMinutes: 13,
    ),
    LegalArticle(
      title: 'Business Contracts: Creating and Understanding Agreements',
      description:
          'Learn how to create, negotiate, and understand business contracts. Cover essential contract elements, liability clauses, dispute resolution, and when to seek legal advice for your business transactions.',
      category: 'Corporate Law',
      source: 'Business Law Institute',
      url: 'https://www.businesslaw.org/contracts-guide',
      readTimeMinutes: 10,
    ),
    LegalArticle(
      title: 'Consumer Rights: Protection from Fraud and Unfair Practices',
      description:
          'Understand your rights as a consumer including product liability, false advertising, warranty protections, and your rights in disputes with businesses. Know how to report fraud and seek remedies.',
      category: 'Consumer Law',
      source: 'Consumer Protection Bureau',
      url: 'https://www.consumerprotection.org/rights',
      readTimeMinutes: 7,
    ),
  ];

  late List<LegalArticle> filteredArticles;
  String selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    filteredArticles = articles;
  }

  void _filterArticles(String category) {
    setState(() {
      selectedCategory = category;
      if (category == 'All') {
        filteredArticles = articles;
      } else {
        filteredArticles =
            articles.where((article) => article.category == category).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    final categories = [
      'All',
      ...articles.map((a) => a.category).toSet(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: PhosphorIcon(PhosphorIconsRegular.arrowLeft),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Legal Articles & Guides',
          style: textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          // Category Filter Chips
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
              child: Row(
                children: categories.map((category) {
                  final isSelected = selectedCategory == category;
                  return Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: FilterChip(
                      selected: isSelected,
                      label: Text(category),
                      onSelected: (_) => _filterArticles(category),
                      backgroundColor: AppColors.surface,
                      selectedColor: AppColors.primary,
                      labelStyle: textTheme.labelSmall?.copyWith(
                        color: isSelected
                            ? Colors.white
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                      side: BorderSide(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.grey200,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Article List
          if (filteredArticles.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    PhosphorIcon(
                      PhosphorIconsRegular.magnifyingGlass,
                      size: 48,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'No articles found',
                      style: textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final article = filteredArticles[index];
                    return _ArticleCard(
                      article: article,
                      onTap: () async {
                        await launchUrl(
                          Uri.parse(article.url),
                          mode: LaunchMode.externalApplication,
                        );
                      },
                    );
                  },
                  childCount: filteredArticles.length,
                ),
              ),
            ),

          // Bottom padding
          const SliverToBoxAdapter(
            child: SizedBox(height: AppSpacing.lg),
          ),
        ],
      ),
    );
  }
}

class _ArticleCard extends StatelessWidget {
  final LegalArticle article;
  final VoidCallback onTap;

  const _ArticleCard({
    required this.article,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category and read time
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppRadius.xs),
                      ),
                      child: Text(
                        article.category,
                        style: textTheme.labelSmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Spacer(),
                    PhosphorIcon(
                      PhosphorIconsRegular.clock,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      '${article.readTimeMinutes} min read',
                      style: textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.md),

                // Title
                Text(
                  article.title,
                  style: textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: AppSpacing.sm),

                // Description
                Text(
                  article.description,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: AppSpacing.md),

                // Source and arrow
                Row(
                  children: [
                    Text(
                      article.source,
                      style: textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const Spacer(),
                    PhosphorIcon(
                      PhosphorIconsRegular.arrowUpRight,
                      size: 18,
                      color: colorScheme.primary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
