import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zakoota/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../providers/locale_provider.dart';

class LanguageSettingsScreen extends ConsumerStatefulWidget {
  const LanguageSettingsScreen({super.key});

  @override
  ConsumerState<LanguageSettingsScreen> createState() =>
      _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState extends ConsumerState<LanguageSettingsScreen> {
  String _selectedLanguage = 'en';

  final List<Map<String, String>> _languages = [
    {'code': 'en', 'name': 'English', 'native': 'English'},
    {'code': 'ur', 'name': 'Urdu', 'native': 'اردو'},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final current = ref.watch(localeNotifierProvider);
    if (current != null && _selectedLanguage != current.languageCode) {
      _selectedLanguage = current.languageCode;
    }

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
          loc.languageTitle,
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
            ..._languages.map((lang) => _buildLanguageItem(lang, loc)),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageItem(Map<String, String> lang, AppLocalizations loc) {
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
        onTap: () async {
          final code = lang['code']!;
          setState(() => _selectedLanguage = code);
          await ref.read(localeNotifierProvider.notifier).setLocale(Locale(code));

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${loc.languageTitle}: ${lang['name']}'),
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
