import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/auth_service.dart';

class LawyerProfileSetupScreen extends StatefulWidget {
  const LawyerProfileSetupScreen({super.key});

  @override
  State<LawyerProfileSetupScreen> createState() =>
      _LawyerProfileSetupScreenState();
}

class _LawyerProfileSetupScreenState extends State<LawyerProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  final _firestore = FirebaseFirestore.instance;

  // Controllers
  final _phoneController = TextEditingController();
  final _licenseNoController = TextEditingController();
  final _educationController = TextEditingController();

  // State Variables
  String? _selectedCity;
  String? _selectedLicenseType;
  DateTime? _enrollmentDate;
  int _yearsOfExperience = 0;
  List<String> _selectedSpecializations = [];
  bool _isLoading = false;

  // Options
  final List<String> _cities = [
    'Lahore',
    'Karachi',
    'Islamabad',
    'Rawalpindi',
    'Faisalabad',
    'Multan',
    'Peshawar',
    'Quetta',
    'Sialkot',
    'Gujranwala'
  ];

  final List<String> _licenseTypes = [
    'Lower Courts',
    'High Court',
    'Supreme Court'
  ];

  final List<String> _specializations = [
    'Criminal Law',
    'Civil Law',
    'Family Law',
    'Corporate Law',
    'Tax Law',
    'Property Law',
    'Labor Law',
    'Constitutional Law',
    'Intellectual Property',
    'Banking Law'
  ];

  @override
  void dispose() {
    _phoneController.dispose();
    _licenseNoController.dispose();
    _educationController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.secondary, // Header background color
              onPrimary: Colors.white, // Header text color
              onSurface: AppColors.textPrimary, // Body text color
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _enrollmentDate) {
      setState(() {
        _enrollmentDate = picked;
        // Calculate Experience
        final now = DateTime.now();
        int years = now.year - picked.year;
        if (now.month < picked.month ||
            (now.month == picked.month && now.day < picked.day)) {
          years--;
        }
        _yearsOfExperience = years < 0 ? 0 : years;
      });
    }
  }

  void _toggleSpecialization(String specialization) {
    setState(() {
      if (_selectedSpecializations.contains(specialization)) {
        _selectedSpecializations.remove(specialization);
      } else {
        if (_selectedSpecializations.length < 5) {
          _selectedSpecializations.add(specialization);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('You can select up to 5 specializations')),
          );
        }
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = _authService.currentUser;
    if (user != null) {
      try {
        final userDoc =
            await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists && mounted) {
          final data = userDoc.data();

          // Safety Check: If already approved, redirect to correct flow
          if (data?['verificationStatus'] == 'approved') {
            if (data?['publicProfileCompleted'] == true) {
              context.go('/lawyer-dashboard');
            } else {
              context.go('/lawyer-bio-setup');
            }
            return;
          }

          setState(() {
            if (data != null) {
              _phoneController.text = data['phoneNumber'] ?? '';
              _selectedCity = data['city'];
              _licenseNoController.text = data['barLicenseNo'] ?? '';
              if (data['enrollmentDate'] != null) {
                _enrollmentDate =
                    (data['enrollmentDate'] as Timestamp).toDate();
              }
              _yearsOfExperience = data['experienceYears'] ?? 0;
              _selectedLicenseType = data['licenseType'];
              if (data['specializations'] != null) {
                _selectedSpecializations =
                    List<String>.from(data['specializations']);
              }
              _educationController.text = data['education'] ?? '';
            }
          });
        }
      } catch (e) {
        debugPrint('Error loading user data: $e');
      }
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      // ... (Validation checks remain same) ...
      if (_selectedCity == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a city')),
        );
        return;
      }
      if (_enrollmentDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please select your date of enrollment')),
        );
        return;
      }
      if (_selectedLicenseType == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select your license type')),
        );
        return;
      }
      if (_selectedSpecializations.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please select at least one specialization')),
        );
        return;
      }

      setState(() => _isLoading = true);

      try {
        final userId = _authService.currentUser!.uid;
        // verificationStatus not needed anymore for logic here

        final Map<String, dynamic> updateData = {
          'phoneNumber': _phoneController.text.trim(),
          'city': _selectedCity,
          'barLicenseNo': _licenseNoController.text.trim(),
          'enrollmentDate': Timestamp.fromDate(_enrollmentDate!),
          'experienceYears': _yearsOfExperience,
          'licenseType': _selectedLicenseType,
          'specializations': _selectedSpecializations,
          'education': _educationController.text.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        // Always treat as New/Pending Flow
        updateData['verificationStatus'] = 'pending_docs';
        await _firestore.collection('users').doc(userId).update(updateData);
        if (mounted) context.go('/lawyer-verification');
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving profile: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Professional Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Build Your Profile',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Provide your professional details to get verified.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Phone Number
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: Icon(Icons.phone_outlined),
                    hintText: '03XXXXXXXXX',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Required';
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),

                // City Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedCity,
                  decoration: const InputDecoration(
                    labelText: 'City',
                    prefixIcon: Icon(Icons.location_city_outlined),
                    border: OutlineInputBorder(),
                  ),
                  items: _cities.map((city) {
                    return DropdownMenuItem(value: city, child: Text(city));
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedCity = value),
                  validator: (value) => value == null ? 'Required' : null,
                ),
                const SizedBox(height: AppSpacing.md),

                // License Number
                TextFormField(
                  controller: _licenseNoController,
                  decoration: const InputDecoration(
                    labelText: 'Bar Council License No',
                    prefixIcon: Icon(Icons.badge_outlined),
                    hintText: 'e.g. 12345/LHR',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Required';
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),

                // Enrollment Date & Experience
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: InkWell(
                        onTap: () => _selectDate(context),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Enrollment Date',
                            prefixIcon: Icon(Icons.calendar_today_outlined),
                            border: OutlineInputBorder(),
                          ),
                          child: Text(
                            _enrollmentDate == null
                                ? 'Select Date'
                                : '${_enrollmentDate!.day}/${_enrollmentDate!.month}/${_enrollmentDate!.year}',
                            style: TextStyle(
                              color: _enrollmentDate == null
                                  ? AppColors.textSecondary
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      flex: 1,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Experience',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: AppColors.surface,
                        ),
                        child: Text(
                          '$_yearsOfExperience Years',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // License Type
                DropdownButtonFormField<String>(
                  value: _selectedLicenseType,
                  decoration: const InputDecoration(
                    labelText: 'License Type',
                    prefixIcon: Icon(Icons.gavel_outlined),
                    border: OutlineInputBorder(),
                  ),
                  items: _licenseTypes.map((type) {
                    return DropdownMenuItem(value: type, child: Text(type));
                  }).toList(),
                  onChanged: (value) =>
                      setState(() => _selectedLicenseType = value),
                ),
                const SizedBox(height: AppSpacing.md),

                // Specializations
                Text(
                  'Specializations (Max 5)',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _specializations.map((spec) {
                    final isSelected = _selectedSpecializations.contains(spec);
                    return FilterChip(
                      label: Text(spec),
                      selected: isSelected,
                      onSelected: (_) => _toggleSpecialization(spec),
                      backgroundColor: Colors.white,
                      selectedColor: AppColors.secondary.withValues(alpha: 0.2),
                      checkmarkColor: AppColors.secondary,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? AppColors.secondary
                            : AppColors.textPrimary,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.md),

                // Education
                TextFormField(
                  controller: _educationController,
                  decoration: const InputDecoration(
                    labelText: 'Education',
                    prefixIcon: Icon(Icons.school_outlined),
                    hintText: 'e.g. LL.B (Hons), Panjab University',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Required';
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.xl),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: Colors.white,
                      padding:
                          const EdgeInsets.symmetric(vertical: AppSpacing.md),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Next: Verify Identity',
                                  style: TextStyle(fontSize: 16)),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward, size: 20),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
