import 'package:json_annotation/json_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  });

  factory FoodItem.fromJson(Map<String, dynamic> json) =>
      _$FoodItemFromJson(json);

  factory FoodItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FoodItem(
      id: doc.id,
      barcode: data['barcode'],
      label: data['label'] ?? 'Unknown',
      calories: (data['calories'] ?? 0).toDouble(),
      protein: (data['protein'] ?? 0).toDouble(),
      fat: (data['fat'] ?? 0).toDouble(),
      carbs: (data['carbs'] ?? 0).toDouble(),
      fiber: (data['fiber'] ?? 0).toDouble(),
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      isFavorite: data['isFavorite'] ?? false,
      source: data['source'] ?? 'manual',
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
    );
  }
}
