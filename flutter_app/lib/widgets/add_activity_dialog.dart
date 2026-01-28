import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/activity.dart';
import '../models/user_profile.dart';
import '../services/firestore_service.dart';

class AddActivityDialog extends StatefulWidget {
  final String userId;
  final UserProfile? userProfile;

  const AddActivityDialog({
    Key? key,
    required this.userId,
    this.userProfile,
  }) : super(key: key);

  @override
  State<AddActivityDialog> createState() => _AddActivityDialogState();
}

class _AddActivityDialogState extends State<AddActivityDialog> {
  final FirestoreService _firestoreService = FirestoreService();
  final _formKey = GlobalKey<FormState>();
  final _durationController = TextEditingController();
  final _notesController = TextEditingController();
  
  ActivityType _selectedType = ActivityType.walking;
  bool _isSaving = false;

  @override
  void dispose() {
    _durationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double _calculateCalories() {
    final duration = int.tryParse(_durationController.text) ?? 0;
    final weight = widget.userProfile?.currentWeight ?? 70.0; // Default 70kg
    
    return Activity.calculateCalories(
      type: _selectedType,
      durationMinutes: duration,
      weightKg: weight,
    );
  }

  Future<void> _saveActivity() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final duration = int.parse(_durationController.text);
      final calories = _calculateCalories();
      
      final activity = Activity(
        activityId: const Uuid().v4(),
        userId: widget.userId,
        type: _selectedType,
        durationMinutes: duration,
        caloriesBurned: calories,
        timestamp: DateTime.now(),
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );

      await _firestoreService.addActivity(widget.userId, activity);

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Aktivität hinzufügen',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Aktivitätstyp Dropdown
                DropdownButtonFormField<ActivityType>(
                  value: _selectedType,
                  decoration: InputDecoration(
                    labelText: 'Aktivität',
                    prefixIcon: Text(
                      _selectedType.icon,
                      style: const TextStyle(fontSize: 24),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  items: ActivityType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Row(
                        children: [
                          Text(type.icon, style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 12),
                          Text(type.displayName),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedType = value);
                    }
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Dauer
                TextFormField(
                  controller: _durationController,
                  decoration: InputDecoration(
                    labelText: 'Dauer (Minuten)',
                    prefixIcon: const Icon(Icons.timer),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Bitte Dauer eingeben';
                    }
                    final duration = int.tryParse(value);
                    if (duration == null || duration <= 0) {
                      return 'Ungültige Dauer';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    setState(() {}); // Update calories display
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Geschätzte verbrannte Kalorien
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Verbrannte Kalorien:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '~${_calculateCalories().toStringAsFixed(0)} kcal',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Notizen (optional)
                TextFormField(
                  controller: _notesController,
                  decoration: InputDecoration(
                    labelText: 'Notizen (optional)',
                    prefixIcon: const Icon(Icons.note),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  maxLines: 2,
                ),
                
                const SizedBox(height: 24),
                
                // Speichern Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveActivity,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check),
                    label: Text(_isSaving ? 'Speichern...' : 'Hinzufügen'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
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
