import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import '../models/food_item.dart';
import '../models/nutrients.dart';
import '../services/cloud_function_service.dart';
import '../services/firebase_auth_service.dart';
import '../services/firestore_service.dart';

class BarcodeScanScreen extends StatefulWidget {
  final String mealType;

  const BarcodeScanScreen({Key? key, required this.mealType}) : super(key: key);

  @override
  State<BarcodeScanScreen> createState() => _BarcodeScanScreenState();
}

class _BarcodeScanScreenState extends State<BarcodeScanScreen> {
  final _picker = ImagePicker();
  final _barcodeScanner = BarcodeScanner();
  final _cloudService = CloudFunctionService();
  final _authService = FirebaseAuthService();
  final _firestoreService = FirestoreService();

  bool _isLoading = false;
  String? _barcode;
  Nutrients? _result;
  File? _imageFile;

  @override
  void dispose() {
    _barcodeScanner.close();
    super.dispose();
  }

  Future<void> _scanBarcode() async {
    final image = await _picker.pickImage(source: ImageSource.camera);
    if (image == null) return;

    setState(() {
      _isLoading = true;
      _imageFile = File(image.path);
      _barcode = null;
      _result = null;
    });

    try {
      final inputImage = InputImage.fromFilePath(image.path);
      final barcodes = await _barcodeScanner.processImage(inputImage);

      if (barcodes.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('❌ Kein Barcode gefunden')),
          );
        }
        return;
      }

      final rawValue = barcodes.first.rawValue;
      if (rawValue == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('❌ Barcode ungültig')),
          );
        }
        return;
      }

      _barcode = rawValue;

      final idToken = await _authService.getIdToken();
      if (idToken == null) throw Exception('Nicht angemeldet');

      final nutrients = await _cloudService.getBarcodeData(rawValue, idToken);
      if (nutrients != null) {
        setState(() => _result = nutrients);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('❌ Produkt nicht gefunden')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Fehler: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveFood() async {
    if (_result == null) return;

    final user = _authService.currentUser;
    if (user == null) return;

    try {
      final foodItem = FoodItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        barcode: _barcode,
        label: _result!.label,
        calories: _result!.calories,
        protein: _result!.protein,
        fat: _result!.fat,
        carbs: _result!.carbs,
        fiber: _result!.fiber,
        timestamp: DateTime.now(),
        source: 'openfoodfacts',
        mealType: widget.mealType,
      );

      await _firestoreService.addFoodItem(user.uid, foodItem);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Produkt gespeichert')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Fehler: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Barcode scannen')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_imageFile != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(_imageFile!, height: 200, fit: BoxFit.cover),
              ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _scanBarcode,
              icon: const Icon(Icons.qr_code_scanner),
              label: Text(_isLoading ? 'Scanne...' : 'Barcode scannen'),
            ),
            const SizedBox(height: 16),
            if (_result != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _result!.label,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      _buildRow('Kalorien', '${_result!.calories.toStringAsFixed(0)} kcal'),
                      _buildRow('Eiweiß', '${_result!.protein.toStringAsFixed(1)} g'),
                      _buildRow('Fett', '${_result!.fat.toStringAsFixed(1)} g'),
                      _buildRow('Kohlenh.', '${_result!.carbs.toStringAsFixed(1)} g'),
                      _buildRow('Ballastst.', '${_result!.fiber.toStringAsFixed(1)} g'),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _saveFood,
                          child: const Text('Speichern'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
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
