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

    required this.createdAt,
    required this.updatedAt,
  });

  /// Berechnet BMR (Basal Metabolic Rate) mit Mifflin-St Jeor Formel
  /// Männer: BMR = (10 × Gewicht in kg) + (6,25 × Groesse in cm) - (5 × Alter in Jahren) + 5
  /// Frauen: BMR = (10 × Gewicht in kg) + (6,25 × Groesse in cm) - (5 × Alter in Jahren) - 161
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

enum WeightGoal {
extension WeightGoalExtension on WeightGoal {

