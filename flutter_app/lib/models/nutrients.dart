import 'package:json_annotation/json_annotation.dart';
import '../services/validation_service.dart';

part 'nutrients.g.dart';

@JsonSerializable()
class Nutrients {
  final double calories;
  final double protein;
  final double fat;
  final double carbs;
  final double fiber;
  final String label;

  Nutrients({
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbs,
    required this.fiber,
    required this.label,
  }) {
    // Validate on construction
    _validate();
  }

  /// Validate all nutrient values
  void _validate() {
    ValidationService.validateNutrients(
      calories: calories,
      protein: protein,
      fat: fat,
      carbs: carbs,
      fiber: fiber,
    );
  }

  /// Create from JSON with validation
  factory Nutrients.fromJson(Map<String, dynamic> json) {
    final nutrients = _$NutrientsFromJson(json);
    // Sanitize values
    final sanitized = ValidationService.sanitizeNutrients(
      calories: nutrients.calories,
      protein: nutrients.protein,
      fat: nutrients.fat,
      carbs: nutrients.carbs,
      fiber: nutrients.fiber,
    );
    return Nutrients(
      label: nutrients.label,
      calories: sanitized.calories,
      protein: sanitized.protein,
      fat: sanitized.fat,
      carbs: sanitized.carbs,
      fiber: sanitized.fiber,
    );
  }

  Map<String, dynamic> toJson() => _$NutrientsToJson(this);

  @override
  String toString() =>
      'Nutrients(label: $label, calories: $calories, protein: $protein, fat: $fat, carbs: $carbs, fiber: $fiber)';

  /// Create a copy with optional updates
  Nutrients copyWith({
    double? calories,
    double? protein,
    double? fat,
    double? carbs,
    double? fiber,
    String? label,
  }) {
    return Nutrients(
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      fat: fat ?? this.fat,
      carbs: carbs ?? this.carbs,
      fiber: fiber ?? this.fiber,
      label: label ?? this.label,
    );
  }

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
