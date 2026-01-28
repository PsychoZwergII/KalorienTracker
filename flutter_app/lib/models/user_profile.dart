import 'package:json_annotation/json_annotation.dart';

part 'user_profile.g.dart';

@JsonSerializable()
class UserProfile {
  final String userId;
  final String? displayName;
  final String? email;
  
  // Körperdaten
  final double? startWeight; // kg
  final double? currentWeight; // kg
  final double? targetWeight; // kg
  final double? height; // cm
  final int? age; // Jahre
  final Gender? gender;
  
  // Aktivitätslevel für TDEE Berechnung
  final ActivityLevel? activityLevel;
  
  // Ziel (Abnehmen, Zunehmen, Halten)
  final WeightGoal? weightGoal;
  
  // Timestamps
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile({
    required this.userId,
    this.displayName,
    this.email,
    this.startWeight,
    this.currentWeight,
    this.targetWeight,
    this.height,
    this.age,
    this.gender,
    this.activityLevel,
    this.weightGoal,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Berechnet BMR (Basal Metabolic Rate) mit Mifflin-St Jeor Formel
  /// Männer: BMR = (10 × Gewicht in kg) + (6,25 × Größe in cm) - (5 × Alter in Jahren) + 5
  /// Frauen: BMR = (10 × Gewicht in kg) + (6,25 × Größe in cm) - (5 × Alter in Jahren) - 161
  double? calculateBMR() {
    if (currentWeight == null || height == null || age == null || gender == null) {
      return null;
    }
    
    final baseBMR = (10 * currentWeight!) + (6.25 * height!) - (5 * age!);
    
    switch (gender!) {
      case Gender.male:
        return baseBMR + 5;
      case Gender.female:
        return baseBMR - 161;
      case Gender.other:
        return baseBMR - 78; // Durchschnitt
    }
  }

  /// Berechnet TDEE (Total Daily Energy Expenditure)
  /// BMR × Aktivitätsfaktor
  double? calculateTDEE() {
    final bmr = calculateBMR();
    if (bmr == null || activityLevel == null) {
      return null;
    }
    
    return bmr * activityLevel!.multiplier;
  }

  /// Berechnet empfohlene tägliche Kalorienzufuhr basierend auf Ziel
  /// Abnehmen: TDEE - 500 kcal (0.5 kg/Woche)
  /// Zunehmen: TDEE + 300 kcal (0.3 kg/Woche)
  /// Halten: TDEE
  double? calculateDailyCalorieGoal() {
    final tdee = calculateTDEE();
    if (tdee == null || weightGoal == null) {
      return null;
    }
    
    switch (weightGoal!) {
      case WeightGoal.lose:
        return tdee - 500;
      case WeightGoal.gain:
        return tdee + 300;
      case WeightGoal.maintain:
        return tdee;
    }
  }

  /// Berechnet Fortschritt zum Zielgewicht in Prozent
  double? calculateWeightProgress() {
    if (startWeight == null || currentWeight == null || targetWeight == null) {
      return null;
    }
    
    final totalChange = (targetWeight! - startWeight!).abs();
    final currentChange = (currentWeight! - startWeight!).abs();
    
    if (totalChange == 0) return 100.0;
    
    return (currentChange / totalChange * 100).clamp(0.0, 100.0);
  }

  /// Verbleibende kg bis zum Zielgewicht
  double? remainingWeightChange() {
    if (currentWeight == null || targetWeight == null) {
      return null;
    }
    return (targetWeight! - currentWeight!).abs();
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) => _$UserProfileFromJson(json);
  Map<String, dynamic> toJson() => _$UserProfileToJson(this);

  UserProfile copyWith({
    String? userId,
    String? displayName,
    String? email,
    double? startWeight,
    double? currentWeight,
    double? targetWeight,
    double? height,
    int? age,
    Gender? gender,
    ActivityLevel? activityLevel,
    WeightGoal? weightGoal,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      startWeight: startWeight ?? this.startWeight,
      currentWeight: currentWeight ?? this.currentWeight,
      targetWeight: targetWeight ?? this.targetWeight,
      height: height ?? this.height,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      activityLevel: activityLevel ?? this.activityLevel,
      weightGoal: weightGoal ?? this.weightGoal,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

enum Gender {
  male,
  female,
  other,
}

enum ActivityLevel {
  sedentary, // Sitzend (wenig/keine Bewegung)
  light, // Leicht aktiv (1-3 Tage/Woche leichter Sport)
  moderate, // Moderat aktiv (3-5 Tage/Woche)
  active, // Sehr aktiv (6-7 Tage/Woche)
  extreme, // Extrem aktiv (2x täglich Training, physische Arbeit)
}

extension ActivityLevelExtension on ActivityLevel {
  double get multiplier {
    switch (this) {
      case ActivityLevel.sedentary:
        return 1.2;
      case ActivityLevel.light:
        return 1.375;
      case ActivityLevel.moderate:
        return 1.55;
      case ActivityLevel.active:
        return 1.725;
      case ActivityLevel.extreme:
        return 1.9;
    }
  }

  String get displayName {
    switch (this) {
      case ActivityLevel.sedentary:
        return 'Sitzend (wenig Bewegung)';
      case ActivityLevel.light:
        return 'Leicht aktiv (1-3 Tage/Woche)';
      case ActivityLevel.moderate:
        return 'Moderat aktiv (3-5 Tage/Woche)';
      case ActivityLevel.active:
        return 'Sehr aktiv (6-7 Tage/Woche)';
      case ActivityLevel.extreme:
        return 'Extrem aktiv (täglich intensiv)';
    }
  }
}

enum WeightGoal {
  lose, // Abnehmen
  maintain, // Halten
  gain, // Zunehmen
}

extension WeightGoalExtension on WeightGoal {
  String get displayName {
    switch (this) {
      case WeightGoal.lose:
        return 'Abnehmen';
      case WeightGoal.maintain:
        return 'Gewicht halten';
      case WeightGoal.gain:
        return 'Zunehmen';
    }
  }
}
