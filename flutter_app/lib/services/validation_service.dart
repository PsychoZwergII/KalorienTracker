/// Validation utilities for food, health, and user data
class ValidationService {
  // Nutritional value ranges (per 100g)
  static const double minCalories = 0;
  static const double maxCalories = 1000; // Maximum reasonable kcal per 100g
  static const double minMacro = 0;
  static const double maxMacro = 100; // Maximum grams per 100g

  // Body measurements
  static const double minHeight = 50; // cm
  static const double maxHeight = 300; // cm
  static const double minWeight = 10; // kg
  static const double maxWeight = 500; // kg
  static const int minAge = 1;
  static const int maxAge = 150;

  // Activity duration
  static const int minActivityDuration = 1; // minutes
  static const int maxActivityDuration = 1440 * 7; // 7 days in minutes

  // String validation
  static const int minLabelLength = 1;
  static const int maxLabelLength = 200;

  /// Validate nutrient value
  static String? validateNutrient(
    double value,
    String fieldName, {
    double min = minMacro,
    double max = maxMacro,
  }) {
    if (value.isNaN || value.isInfinite) {
      return '$fieldName contains invalid value';
    }
    if (value < min) {
      return '$fieldName cannot be less than $min';
    }
    if (value > max) {
      return '$fieldName cannot exceed $max';
    }
    return null;
  }

  /// Validate calories
  static String? validateCalories(double calories) {
    if (calories.isNaN || calories.isInfinite) {
      return 'Calories contain invalid value';
    }
    if (calories < minCalories) {
      return 'Calories cannot be negative';
    }
    if (calories > maxCalories) {
      return 'Calories value unreasonable (> $maxCalories)';
    }
    return null;
  }

  /// Validate all nutrients at once
  static String? validateNutrients({
    required double calories,
    required double protein,
    required double fat,
    required double carbs,
    required double fiber,
  }) {
    String? error;

    error = validateCalories(calories);
    if (error != null) return error;

    error = validateNutrient(protein, 'Protein');
    if (error != null) return error;

    error = validateNutrient(fat, 'Fat');
    if (error != null) return error;

    error = validateNutrient(carbs, 'Carbohydrates');
    if (error != null) return error;

    error = validateNutrient(fiber, 'Fiber');
    if (error != null) return error;

    // Macros shouldn't exceed 100g per 100g total
    final totalMacros = protein + fat + carbs;
    if (totalMacros > 105) {
      // Allow 5g buffer for rounding
      return 'Total macronutrients cannot exceed 100g per 100g';
    }

    return null;
  }

  /// Validate food item label
  static String? validateLabel(String label) {
    if (label.trim().isEmpty) {
      return 'Food label cannot be empty';
    }
    if (label.length < minLabelLength) {
      return 'Food label too short';
    }
    if (label.length > maxLabelLength) {
      return 'Food label too long (max $maxLabelLength characters)';
    }
    return null;
  }

  /// Validate height (cm)
  static String? validateHeight(double height) {
    if (height.isNaN || height.isInfinite) {
      return 'Height contains invalid value';
    }
    if (height < minHeight) {
      return 'Height too low (minimum ${minHeight}cm)';
    }
    if (height > maxHeight) {
      return 'Height too high (maximum ${maxHeight}cm)';
    }
    return null;
  }

  /// Validate weight (kg)
  static String? validateWeight(double weight) {
    if (weight.isNaN || weight.isInfinite) {
      return 'Weight contains invalid value';
    }
    if (weight <= minWeight) {
      return 'Weight too low (minimum ${minWeight}kg)';
    }
    if (weight > maxWeight) {
      return 'Weight too high (maximum ${maxWeight}kg)';
    }
    return null;
  }

  /// Validate age (years)
  static String? validateAge(int age) {
    if (age < minAge) {
      return 'Age must be at least $minAge';
    }
    if (age > maxAge) {
      return 'Age must be less than $maxAge';
    }
    return null;
  }

  /// Validate activity duration (minutes)
  static String? validateActivityDuration(int minutes) {
    if (minutes < minActivityDuration) {
      return 'Activity duration must be at least $minActivityDuration minute';
    }
    if (minutes > maxActivityDuration) {
      return 'Activity duration cannot exceed 7 days';
    }
    return null;
  }

  /// Validate barcode format (EAN-13, UPC-A, etc.)
  static String? validateBarcode(String barcode) {
    final clean = barcode.replaceAll(RegExp(r'\s'), '');
    if (clean.isEmpty) {
      return 'Barcode cannot be empty';
    }
    if (!RegExp(r'^\d+$').hasMatch(clean)) {
      return 'Barcode must contain only digits';
    }
    if (clean.length < 8 || clean.length > 14) {
      return 'Barcode length must be between 8 and 14 digits (got ${clean.length})';
    }
    return null;
  }

  /// Validate timestamp (should be <= now)
  static String? validateTimestamp(DateTime timestamp) {
    if (timestamp.isAfter(DateTime.now().add(const Duration(seconds: 60)))) {
      return 'Timestamp cannot be in the future';
    }
    // Check if more than 100 years in past
    if (timestamp.isBefore(DateTime.now().subtract(const Duration(days: 36500)))) {
      return 'Timestamp too far in the past';
    }
    return null;
  }

  /// Sanitize nutrient values (replace NaN/Infinity with 0, clamp to valid range)
  static double sanitizeNutrient(double value) {
    if (value.isNaN || value.isInfinite) {
      return 0;
    }
    return value.clamp(minMacro, maxMacro);
  }

  /// Sanitize all nutrients
  static ({
    double calories,
    double protein,
    double fat,
    double carbs,
    double fiber,
  }) sanitizeNutrients({
    required double calories,
    required double protein,
    required double fat,
    required double carbs,
    required double fiber,
  }) {
    return (
      calories: calories.isNaN || calories.isInfinite
          ? 0
          : calories.clamp(minCalories, maxCalories),
      protein: sanitizeNutrient(protein),
      fat: sanitizeNutrient(fat),
      carbs: sanitizeNutrient(carbs),
      fiber: sanitizeNutrient(fiber),
    );
  }
}
