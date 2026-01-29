import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import '../services/cloud_function_service.dart';
import '../services/firestore_service.dart';
import '../services/firebase_auth_service.dart';
import '../models/nutrients.dart';
import '../models/food_item.dart';

class ScannerScreen extends StatefulWidget {
  final String? mealType;

  const ScannerScreen({Key? key, this.mealType}) : super(key: key);

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final ImagePicker _picker = ImagePicker();
  final CloudFunctionService _cloudFunctionService = CloudFunctionService();
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuthService _authService = FirebaseAuthService();
  bool _isLoading = false;
  Nutrients? _result;

  Future<void> _captureImage() async {
    try {
      final image = await _picker.pickImage(source: ImageSource.camera);
      if (image != null) {
        await _analyzeImage(image);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }


  Future<void> _analyzeImage(XFile image) async {
    setState(() => _isLoading = true);
    try {
      final bytes = await image.readAsBytes();
      final base64 = base64Encode(bytes);
      final idToken = await _authService.getIdToken();

      if (idToken == null) throw Exception('Not authenticated');

      final result = await _cloudFunctionService.analyzeFoodImage(
        base64,
        idToken,
      );

      if (result != null && mounted) {
        setState(() => _result = result);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to analyze image')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveFood() async {
    if (_result == null) return;

    try {
      final user = _authService.currentUser;
      if (user == null) throw Exception('Not authenticated');

      final foodItem = FoodItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        label: _result!.label,
        calories: _result!.calories,
        protein: _result!.protein,
        fat: _result!.fat,
        carbs: _result!.carbs,
        fiber: _result!.fiber,
        timestamp: DateTime.now(),
        source: 'gemini',
        mealType: widget.mealType,
      );

      await _firestoreService.addFoodItem(user.uid, foodItem);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Food saved!')),
        );
        setState(() => _result = null);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_result == null) ...[
              const SizedBox(height: 24),
              const Text(
                'Scan or Analyze Food',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _captureImage,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Take Photo'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ] else ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _result!.label,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      _buildNutrientRow('Calories', '${_result!.calories.toStringAsFixed(0)} kcal'),
                      _buildNutrientRow('Protein', '${_result!.protein.toStringAsFixed(1)}g'),
                      _buildNutrientRow('Fat', '${_result!.fat.toStringAsFixed(1)}g'),
                      _buildNutrientRow('Carbs', '${_result!.carbs.toStringAsFixed(1)}g'),
                      _buildNutrientRow('Fiber', '${_result!.fiber.toStringAsFixed(1)}g'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _saveFood,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Save Food'),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => setState(() => _result = null),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                ),
                child: const Text('Cancel'),
              ),
            ],
            if (_isLoading) ...[
              const SizedBox(height: 32),
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 16),
              const Center(child: Text('Analyzing...')),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNutrientRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
