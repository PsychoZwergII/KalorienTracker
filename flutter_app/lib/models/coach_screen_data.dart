import '../models/activity.dart';
import '../models/food_item.dart';

/// Combined data model für CoachTab - reduziert nested StreamBuilders
class CoachScreenData {
  final List<FoodItem> foods;
  final List<Activity> activities;
  final bool isLoading;
  final String? error;

  CoachScreenData({
    required this.foods,
    required this.activities,
    this.isLoading = false,
    this.error,
  });

  CoachScreenData copyWith({
    List<FoodItem>? foods,
    List<Activity>? activities,
    bool? isLoading,
    String? error,
  }) {
    return CoachScreenData(
      foods: foods ?? this.foods,
      activities: activities ?? this.activities,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  /// Berechnet verbrannte Kalorien aus Activities
  int get caloriesBurned => activities.fold<int>(
    0,
    (sum, activity) => sum + activity.caloriesBurned.round(),
  );

  /// Berechnet Gesamt-Nährwerte aus FoodItems
  Map<String, double> get foodTotals {
    final totals = {
      'calories': 0.0,
      'protein': 0.0,
      'fat': 0.0,
      'carbs': 0.0,
      'fiber': 0.0,
    };

    for (final food in foods) {
      totals['calories'] = (totals['calories'] ?? 0) + food.calories;
      totals['protein'] = (totals['protein'] ?? 0) + food.protein;
      totals['fat'] = (totals['fat'] ?? 0) + food.fat;
      totals['carbs'] = (totals['carbs'] ?? 0) + food.carbs;
      totals['fiber'] = (totals['fiber'] ?? 0) + food.fiber;
    }

    return totals;
  }
}
