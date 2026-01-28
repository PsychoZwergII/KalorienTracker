// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'food_item.dart';

FoodItem _$FoodItemFromJson(Map<String, dynamic> json) {
  return FoodItem(
    id: json['id'] as String,
    barcode: json['barcode'] as String?,
    label: json['label'] as String,
    calories: (json['calories'] as num).toDouble(),
    protein: (json['protein'] as num).toDouble(),
    fat: (json['fat'] as num).toDouble(),
    carbs: (json['carbs'] as num).toDouble(),
    fiber: (json['fiber'] as num).toDouble(),
    timestamp: DateTime.parse(json['timestamp'] as String),
    isFavorite: json['isFavorite'] as bool? ?? false,
    source: json['source'] as String? ?? 'manual',
    mealType: json['mealType'] as String?,
  );
}

Map<String, dynamic> _$FoodItemToJson(FoodItem instance) => <String, dynamic>{
  'id': instance.id,
  'barcode': instance.barcode,
  'label': instance.label,
  'calories': instance.calories,
  'protein': instance.protein,
  'fat': instance.fat,
  'carbs': instance.carbs,
  'fiber': instance.fiber,
  'timestamp': instance.timestamp.toIso8601String(),
  'isFavorite': instance.isFavorite,
  'source': instance.source,
  'mealType': instance.mealType,
};
