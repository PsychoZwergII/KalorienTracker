import 'package:json_annotation/json_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/validation_service.dart';

part 'food_item.g.dart';

@JsonSerializable()
class FoodItem {
  final String id;
  final String? barcode;
  final String label;
  final double calories;
  final double protein;
  final double fat;
  final double carbs;
  final double fiber;
  final DateTime timestamp;
  final bool isFavorite;
  final String source; // "gemini", "openfoodfacts", "manual"
  final String? mealType; // "breakfast", "lunch", "dinner", "snack"

  FoodItem({
    required this.id,
    this.barcode,
    required this.label,
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbs,
    required this.fiber,
    required this.timestamp,
    this.isFavorite = false,
    this.source = "manual",
    this.mealType,
  }) {
    // Validate on construction
    _validate();
  }

  void _validate() {
    // Validate label
    ValidationService.validateLabel(label);

    // Validate nutrients
    ValidationService.validateNutrients(
      calories: calories,
      protein: protein,
      fat: fat,
      carbs: carbs,
      fiber: fiber,
    );

    // Validate timestamp
    ValidationService.validateTimestamp(timestamp);

    // Validate barcode if present
    if (barcode != null && barcode!.isNotEmpty) {
      ValidationService.validateBarcode(barcode!);
    }
  }

  factory FoodItem.fromJson(Map<String, dynamic> json) =>
      _$FoodItemFromJson(json);

  factory FoodItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Sanitize nutrient values
    final sanitized = ValidationService.sanitizeNutrients(
      calories: (data['calories'] ?? 0).toDouble(),
      protein: (data['protein'] ?? 0).toDouble(),
      fat: (data['fat'] ?? 0).toDouble(),
      carbs: (data['carbs'] ?? 0).toDouble(),
      fiber: (data['fiber'] ?? 0).toDouble(),
    );

    return FoodItem(
      id: doc.id,
      barcode: data['barcode'] as String?,
      label: data['label'] ?? 'Unknown',
      calories: sanitized.calories,
      protein: sanitized.protein,
      fat: sanitized.fat,
      carbs: sanitized.carbs,
      fiber: sanitized.fiber,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isFavorite: data['isFavorite'] ?? false,
      source: data['source'] ?? 'manual',
      mealType: data['mealType'] as String?,
    );
  }

  Map<String, dynamic> toJson() => _$FoodItemToJson(this);

  Map<String, dynamic> toFirestore() {
    return {
      'barcode': barcode,
      'label': label,
      'calories': calories,
      'protein': protein,
      'fat': fat,
      'carbs': carbs,
      'fiber': fiber,
      'timestamp': Timestamp.fromDate(timestamp),
      'isFavorite': isFavorite,
      'source': source,
      'mealType': mealType,
    };
  }

  FoodItem copyWith({
    String? id,
    String? barcode,
    String? label,
    double? calories,
    double? protein,
    double? fat,
    double? carbs,
    double? fiber,
    DateTime? timestamp,
    bool? isFavorite,
    String? source,
    String? mealType,
  }) {
    return FoodItem(
      id: id ?? this.id,
      barcode: barcode ?? this.barcode,
      label: label ?? this.label,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      fat: fat ?? this.fat,
      carbs: carbs ?? this.carbs,
      fiber: fiber ?? this.fiber,
      timestamp: timestamp ?? this.timestamp,
      isFavorite: isFavorite ?? this.isFavorite,
      source: source ?? this.source,
      mealType: mealType ?? this.mealType,
    );
  }

  /// Calculate total macronutrients
  double getTotalMacrosGrams() => protein + fat + carbs;

  /// Calculate macro percentages
  ({double proteinPct, double fatPct, double carbsPct}) getMacroPercentages() {
    final totalCals = protein * 4 + fat * 9 + carbs * 4;
    if (totalCals == 0) {
      return (proteinPct: 0, fatPct: 0, carbsPct: 0);
    }
    return (
      proteinPct: (protein * 4 / totalCals) * 100,
      fatPct: (fat * 9 / totalCals) * 100,
      carbsPct: (carbs * 4 / totalCals) * 100,
    );
  }
}
