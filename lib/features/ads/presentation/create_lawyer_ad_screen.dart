import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../models/lawyer_ad_model.dart';
import '../services/lawyer_ad_service.dart';

class CreateLawyerAdScreen extends StatefulWidget {
  final String? adId;

  const CreateLawyerAdScreen({super.key, this.adId});

  @override
  State<CreateLawyerAdScreen> createState() => _CreateLawyerAdScreenState();
}

class _CreateLawyerAdScreenState extends State<CreateLawyerAdScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _durationController = TextEditingController();
  final _docsController = TextEditingController();

  final LawyerAdService _adService = LawyerAdService();

  static const List<String> _categories = [
    'Criminal',
    'Property',
    'Family',
    'Corporate',
    'Civil',
    'Startups',
  ];

  String _selectedCategory = 'Criminal';
  String _pricingType = 'fixed';
  String _locationMode = 'Remote';
  bool _isSubmitting = false;
  bool _isEditing = false;
  bool _isLoading = false;
  DateTime? _existingCreatedAt;
  bool _existingIsActive = true;
  int _existingViews = 0;
  int _existingBookings = 0;

  @override
  void initState() {
    super.initState();
    if (widget.adId != null && widget.adId!.isNotEmpty) {
      _isEditing = true;
      _loadAdForEdit();
    }
  }

  Future<void> _loadAdForEdit() async {
    setState(() => _isLoading = true);
    final ad = await _adService.getAdById(widget.adId!);
    if (!context.mounted || ad == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    setState(() {
      _titleController.text = ad.title;
      _descriptionController.text = ad.description;
      _priceController.text = ad.price.toStringAsFixed(0);
      _durationController.text = ad.duration;
      _docsController.text = ad.requiredClientDocs.join(', ');
      _selectedCategory = ad.category;
      _pricingType = ad.pricingType;
      _locationMode = ad.locationMode;
      _existingCreatedAt = ad.createdAt;
      _existingIsActive = ad.isActive;
      _existingViews = ad.views;
      _existingBookings = ad.bookings;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    _docsController.dispose();
    super.dispose();
  }

  Future<void> _saveAd() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isSubmitting = true);
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final lawyerName = userDoc.data()?['fullName'] ?? 'Lawyer';

      final id = widget.adId ?? FirebaseFirestore.instance.collection('lawyer_ads').doc().id;
      final now = DateTime.now();

      final docs = _docsController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final ad = LawyerAdModel(
        id: id,
        lawyerId: user.uid,
        lawyerName: lawyerName,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        pricingType: _pricingType,
        price: double.tryParse(_priceController.text.trim()) ?? 0,
        duration: _durationController.text.trim(),
        locationMode: _locationMode,
        requiredClientDocs: docs,
        isActive: _isEditing ? _existingIsActive : true,
        views: _isEditing ? _existingViews : 0,
        bookings: _isEditing ? _existingBookings : 0,
        createdAt: _isEditing ? (_existingCreatedAt ?? now) : now,
        updatedAt: now,
      );

      if (_isEditing) {
        await _adService.updateAd(ad);
      } else {
        await _adService.createAd(ad);
      }

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? 'Ad updated successfully' : 'Ad published successfully'),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save ad: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const PhosphorIcon(PhosphorIconsRegular.arrowLeft),
          onPressed: () => context.pop(),
        ),
        title: Text(
          _isEditing ? 'Edit Service Ad' : 'Create New Service',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  // Section: Basic Info
                  _SectionHeader(title: 'Basic Information', icon: PhosphorIconsRegular.info),
                  const SizedBox(height: AppSpacing.sm),
                  _field(
                    child: TextFormField(
                      controller: _titleController,
                      decoration: _inputDecoration('Ad Title', hint: 'e.g. Criminal Defense Consultation'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Title is required' : null,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _field(
                    child: TextFormField(
                      controller: _descriptionController,
                      maxLines: 4,
                      decoration: _inputDecoration('Description', hint: 'Describe your service in detail...'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Description is required' : null,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _field(
                    child: DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: _inputDecoration('Practice Area'),
                      items: _categories
                          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedCategory = v ?? _selectedCategory),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),
                  _SectionHeader(title: 'Pricing & Duration', icon: PhosphorIconsRegular.currencyDollar),
                  const SizedBox(height: AppSpacing.sm),

                  Row(
                    children: [
                      Expanded(
                        child: _field(
                          child: DropdownButtonFormField<String>(
                            value: _pricingType,
                            decoration: _inputDecoration('Pricing Type'),
                            items: const [
                              DropdownMenuItem(value: 'fixed', child: Text('Fixed Price')),
                              DropdownMenuItem(value: 'hourly', child: Text('Per Hour')),
                            ],
                            onChanged: (v) => setState(() => _pricingType = v ?? 'fixed'),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _field(
                          child: TextFormField(
                            controller: _priceController,
                            keyboardType: TextInputType.number,
                            decoration: _inputDecoration('Price (PKR)'),
                            validator: (v) {
                              final parsed = double.tryParse(v ?? '');
                              if (parsed == null || parsed <= 0) return 'Enter valid price';
                              return null;
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _field(
                    child: TextFormField(
                      controller: _durationController,
                      decoration: _inputDecoration('Estimated Duration', hint: 'e.g. 1-2 weeks, 3 sessions'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Duration is required' : null,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),
                  _SectionHeader(title: 'Location & Requirements', icon: PhosphorIconsRegular.mapPin),
                  const SizedBox(height: AppSpacing.sm),

                  _field(
                    child: DropdownButtonFormField<String>(
                      value: _locationMode,
                      decoration: _inputDecoration('Service Mode'),
                      items: const [
                        DropdownMenuItem(value: 'Remote', child: Text('🖥  Remote / Online')),
                        DropdownMenuItem(value: 'In-Person', child: Text('🏢  In-Person')),
                        DropdownMenuItem(value: 'Hybrid', child: Text('⚡  Hybrid')),
                      ],
                      onChanged: (v) => setState(() => _locationMode = v ?? 'Remote'),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _field(
                    child: TextFormField(
                      controller: _docsController,
                      decoration: _inputDecoration(
                        'Required Client Documents',
                        hint: 'e.g. CNIC, FIR copy, property docs (comma-separated)',
                      ),
                      maxLines: 2,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Please list required documents'
                          : null,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  SizedBox(
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: _isSubmitting ? null : _saveAd,
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : PhosphorIcon(
                              _isEditing ? PhosphorIconsRegular.floppyDisk : PhosphorIconsRegular.megaphone,
                              size: 18,
                            ),
                      label: Text(
                        _isEditing ? 'Save Changes' : 'Publish Ad',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
    );
  }

  Widget _field({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.grey200),
      ),
      child: child,
    );
  }

  InputDecoration _inputDecoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textLight, fontSize: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final PhosphorIconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: PhosphorIcon(icon, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: AppColors.textPrimary,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(child: Divider(thickness: 1, color: AppColors.grey200)),
        ],
      ),
    );
  }
}
