import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/auth_service.dart';

class ClientProfileSetupScreen extends StatefulWidget {
  const ClientProfileSetupScreen({super.key});

  @override
  State<ClientProfileSetupScreen> createState() =>
      _ClientProfileSetupScreenState();
}

class _ClientProfileSetupScreenState extends State<ClientProfileSetupScreen> {
  final _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _addressController = TextEditingController();
  final _cnicController = TextEditingController();

  String? _selectedProfession;
  bool _isLoading = false;
  String? _errorMessage;

  final List<String> _professions = [
    "Student",
    "Business Owner",
    "Employee",
    "Housewife",
    "Other"
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = _authService.currentUser;
    if (user != null) {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (userDoc.exists && mounted) {
          final data = userDoc.data();
          setState(() {
            _nameController.text = data?['fullName'] ?? user.displayName ?? '';
          });
        }
      } catch (e) {
        debugPrint('Error loading user data: $e');
        // Fallback to auth display name if firestore fails
        if (user.displayName != null && mounted) {
          _nameController.text = user.displayName!;
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _addressController.dispose();
    _cnicController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedProfession == null) {
      setState(() {
        _errorMessage = 'Please select a profession.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Also update the full name in case user edited it
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_authService.currentUser!.uid)
          .update({'fullName': _nameController.text.trim()});

      await _authService.completeProfileSetup(
        age: _ageController.text.trim(),
        address: _addressController.text.trim(),
        profession: _selectedProfession!,
        cnicNumber: _cnicController.text.trim(),
      );

      if (mounted) {
        context.go('/client-verification');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Complete Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _authService.signOut();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Step Progress
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Step 1 of 2',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                Text(
                  'Tell us about yourself',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Please provide your details to proceed with verification.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),

                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),

                // Full Name (Pre-filled or Editable)
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: PhosphorIcon(PhosphorIcons.user()),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return 'Enter your full name';
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),

                // Age
                TextFormField(
                  controller: _ageController,
                  decoration: InputDecoration(
                    labelText: 'Age',
                    prefixIcon: PhosphorIcon(PhosphorIcons.hourglass()),
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(3),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Enter your age';
                    final age = int.tryParse(value);
                    if (age == null || age < 18) return 'Must be 18+';
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),

                // Address
                TextFormField(
                  controller: _addressController,
                  decoration: InputDecoration(
                    labelText: 'Address',
                    prefixIcon: PhosphorIcon(PhosphorIcons.mapPin()),
                    border: const OutlineInputBorder(),
                  ),
                  maxLines: 2,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Enter address';
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),

                // Profession Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedProfession,
                  decoration: InputDecoration(
                    labelText: 'Profession',
                    prefixIcon: PhosphorIcon(PhosphorIcons.briefcase()),
                    border: const OutlineInputBorder(),
                  ),
                  items: _professions.map((String profession) {
                    return DropdownMenuItem<String>(
                      value: profession,
                      child: Text(profession),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedProfession = newValue;
                    });
                  },
                  validator: (value) =>
                      value == null ? 'Select profession' : null,
                ),
                const SizedBox(height: AppSpacing.md),

                // CNIC Number
                TextFormField(
                  controller: _cnicController,
                  decoration: InputDecoration(
                    labelText: 'CNIC Number',
                    hintText: 'XXXXX-XXXXXXX-X',
                    prefixIcon:
                        PhosphorIcon(PhosphorIcons.identificationCard()),
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    CnicInputFormatter(),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Enter CNIC';
                    if (value.length != 15) return 'Invalid Format (13 digits)';
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.xl),

                // Submit Button
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Next: Verify Identity',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CnicInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    // 1. Remove any existing formatting characters to get clean digits
    final cleanText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    // 2. Limit length (13 digits max for CNIC)
    if (cleanText.length > 13) {
      return oldValue;
    }

    final buffer = StringBuffer();

    // 3. Rebuild string with hyphens
    for (int i = 0; i < cleanText.length; i++) {
      buffer.write(cleanText[i]);
      // Add hyphen after 5th digit (index 4) if there are more digits
      if (i == 4 && cleanText.length > 5) {
        buffer.write('-');
      }
      // Add hyphen after 12th digit (index 11) if there are more digits
      else if (i == 11 && cleanText.length > 12) {
        buffer.write('-');
      }
    }

    final formattedText = buffer.toString();

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}
