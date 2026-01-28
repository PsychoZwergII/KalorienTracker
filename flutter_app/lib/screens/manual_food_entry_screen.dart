import 'package:flutter/material.dart';
import '../models/food_item.dart';
import '../services/firebase_auth_service.dart';
import '../services/firestore_service.dart';

class ManualFoodEntryScreen extends StatefulWidget {
  final String mealType;

  const ManualFoodEntryScreen({Key? key, required this.mealType}) : super(key: key);

  @override
  State<ManualFoodEntryScreen> createState() => _ManualFoodEntryScreenState();
}

class _ManualFoodEntryScreenState extends State<ManualFoodEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _fatController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fiberController = TextEditingController();

  final _authService = FirebaseAuthService();
  final _firestoreService = FirestoreService();

  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _fatController.dispose();
    _carbsController.dispose();
    _fiberController.dispose();
    super.dispose();
  }

  Future<void> _saveFood() async {
    if (!_formKey.currentState!.validate()) return;

    final user = _authService.currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);

    try {
      final foodItem = FoodItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        label: _nameController.text.trim(),
        calories: double.parse(_caloriesController.text),
        protein: double.parse(_proteinController.text),
        fat: double.parse(_fatController.text),
        carbs: double.parse(_carbsController.text),
        fiber: double.parse(_fiberController.text),
        timestamp: DateTime.now(),
        source: 'manual',
        mealType: widget.mealType,
      );

      await _firestoreService.addFoodItem(user.uid, foodItem);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Lebensmittel gespeichert')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Fehler: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manuell hinzufügen')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) => (value == null || value.isEmpty) ? 'Bitte Name eingeben' : null,
              ),
              const SizedBox(height: 12),
              _numberField(_caloriesController, 'Kalorien (kcal)'),
              const SizedBox(height: 12),
              _numberField(_proteinController, 'Eiweiß (g)'),
              const SizedBox(height: 12),
              _numberField(_fatController, 'Fett (g)'),
              const SizedBox(height: 12),
              _numberField(_carbsController, 'Kohlenhydrate (g)'),
              const SizedBox(height: 12),
              _numberField(_fiberController, 'Ballaststoffe (g)'),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveFood,
                  child: Text(_isSaving ? 'Speichern...' : 'Speichern'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _numberField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Bitte eingeben';
        if (double.tryParse(value) == null) return 'Ungültige Zahl';
        return null;
      },
    );
  }
}
