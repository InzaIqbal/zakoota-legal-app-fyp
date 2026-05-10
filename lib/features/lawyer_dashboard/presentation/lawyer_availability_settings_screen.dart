import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../lawyer_auth/models/lawyer_availability_model.dart';
import '../../lawyer_auth/services/lawyer_availability_service.dart';

class LawyerAvailabilitySettingsScreen extends StatefulWidget {
  const LawyerAvailabilitySettingsScreen({super.key});

  @override
  State<LawyerAvailabilitySettingsScreen> createState() =>
      _LawyerAvailabilitySettingsScreenState();
}

class _LawyerAvailabilitySettingsScreenState
    extends State<LawyerAvailabilitySettingsScreen> {
  final LawyerAvailabilityService _service = LawyerAvailabilityService();
  LawyerAvailability? _availability;
  bool _isLoading = true;
  bool _isSaving = false;
  List<DayAvailability> _dayAvailabilities = [];

  @override
  void initState() {
    super.initState();
    _loadAvailability();
  }

  Future<void> _loadAvailability() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final availability = await _service.getAvailability(user.uid);
    if (!mounted) return;
    setState(() {
      _availability = availability;
      _dayAvailabilities = List<DayAvailability>.from(availability.dayAvailabilities);
      _isLoading = false;
    });
  }

  Future<void> _saveAvailability() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);
    try {
      await _service.setAvailability(user.uid, _dayAvailabilities);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Availability updated successfully')),
      );
      await _loadAvailability();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save availability: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _resetToDefault() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);
    try {
      await _service.resetToDefaultAvailability(user.uid);
      await _loadAvailability();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reset to default availability')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to reset availability: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _updateDay(int index, {bool? isAvailable, TimeOfDay? start, TimeOfDay? end}) {
    final current = _dayAvailabilities[index];
    final updated = current.copyWith(
      isAvailable: isAvailable,
      startTime: start != null ? _formatTime(start) : current.startTime,
      endTime: end != null ? _formatTime(end) : current.endTime,
    );

    setState(() {
      _dayAvailabilities[index] = updated;
    });
  }

  String _formatTime(TimeOfDay timeOfDay) {
    final hour = timeOfDay.hour.toString().padLeft(2, '0');
    final minute = timeOfDay.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _pickTime(int index, bool isStart) async {
    final current = _dayAvailabilities[index];
    final initial = isStart ? current.startTimeOfDay : current.endTimeOfDay;
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;
    _updateDay(index, start: isStart ? picked : null, end: isStart ? null : picked);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Availability'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _resetToDefault,
            child: const Text('Reset'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Current Settings',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _availability == null
                        ? 'Using default availability: Monday-Friday, 9 AM - 5 PM'
                        : 'Custom availability is active',
                  ),
                  const SizedBox(height: 4),
                  Text('Availability version: ${_availability?.availabilityVersionId ?? 'default'}'),
                  const SizedBox(height: 4),
                  const Text('Changes apply to NEW consultations only.'),
                  const Text('Already booked consultations remain unaffected.'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Customize Availability',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  for (var i = 0; i < _dayAvailabilities.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(_dayAvailabilities[i].dayOfWeek.displayName),
                            value: _dayAvailabilities[i].isAvailable,
                            onChanged: (value) => _updateDay(i, isAvailable: value),
                          ),
                          if (_dayAvailabilities[i].isAvailable)
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => _pickTime(i, true),
                                    child: Text('Start: ${_dayAvailabilities[i].startTime}'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => _pickTime(i, false),
                                    child: Text('End: ${_dayAvailabilities[i].endTime}'),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 8),
                  const Text('Validation: start time must be before end time.'),
                  const Text('Validation: use 15-minute intervals.'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _isSaving ? null : _saveAvailability,
            child: _isSaving
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save Changes'),
          ),
        ],
      ),
    );
  }
}
