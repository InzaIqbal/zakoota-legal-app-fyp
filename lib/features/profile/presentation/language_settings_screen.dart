import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/constants/app_constants.dart';

class LanguageSettingsScreen extends StatefulWidget {
  const LanguageSettingsScreen({super.key});

  @override
  State<LanguageSettingsScreen> createState() => _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState extends State<LanguageSettingsScreen> {
  String _selectedLanguage = 'en';

  final List<Map<String, String>> _languages = [
    {'code': 'en', 'name': 'English', 'native': 'English'},
    {'code': 'ur', 'name': 'Urdu', 'native': 'اردو'},
  ];

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
          'Language',
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
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.lg),
            ..._languages.map((lang) => _buildLanguageItem(lang)),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageItem(Map<String, String> lang) {
    final isSelected = _selectedLanguage == lang['code'];

    return Container(
      margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: isSelected
            ? Border.all(color: AppColors.secondary, width: 2)
            : null,
      ),
      child: ListTile(
        onTap: () {
          setState(() => _selectedLanguage = lang['code']!);
          // In a real app, this would trigger a localization update
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Language changed to ${lang['name']}'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        leading: CircleAvatar(
          backgroundColor: AppColors.grey100,
          child: Text(
            lang['code']!.toUpperCase(),
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                fontSize: 12),
          ),
        ),
        title: Text(lang['name']!,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(lang['native']!,
            style: const TextStyle(color: AppColors.textSecondary)),
        trailing: isSelected
            ? PhosphorIcon(PhosphorIconsFill.checkCircle,
                color: AppColors.secondary, size: 24)
            : null,
      ),
    );
  }
}
