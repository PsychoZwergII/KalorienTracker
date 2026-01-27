import 'package:json_annotation/json_annotation.dart';

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
  });

  factory Nutrients.fromJson(Map<String, dynamic> json) =>
      _$NutrientsFromJson(json);

  Map<String, dynamic> toJson() => _$NutrientsToJson(this);

  @override
  String toString() =>
      'Nutrients(label: $label, calories: $calories, protein: $protein, fat: $fat, carbs: $carbs, fiber: $fiber)';
}
