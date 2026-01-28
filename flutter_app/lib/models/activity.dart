import 'package:json_annotation/json_annotation.dart';

part 'activity.g.dart';

@JsonSerializable()
class Activity {
  final String activityId;
  final String userId;
  final ActivityType type;
  final String? customName; // Falls "other" gewählt wird
  final int durationMinutes;
  final double caloriesBurned;
  final DateTime timestamp;
  final String? notes;

  Activity({
    required this.activityId,
    required this.userId,
    required this.type,
    this.customName,
    required this.durationMinutes,
    required this.caloriesBurned,
    required this.timestamp,
    this.notes,
  });

  /// Berechnet verbrannte Kalorien basierend auf Aktivitätstyp, Dauer und Gewicht
  /// MET (Metabolic Equivalent of Task) × Gewicht (kg) × Dauer (Stunden)
  static double calculateCalories({
    required ActivityType type,
    required int durationMinutes,
    required double weightKg,
  }) {
    final met = type.metValue;
    final hours = durationMinutes / 60.0;
    return met * weightKg * hours;
  }

  factory Activity.fromJson(Map<String, dynamic> json) => _$ActivityFromJson(json);
  Map<String, dynamic> toJson() => _$ActivityToJson(this);
}

enum ActivityType {
  // Cardio
  walking,
  running,
  cycling,
  swimming,
  
  // Krafttraining
  weightlifting,
  bodyweight,
  
  // Sport
  soccer,
  basketball,
  tennis,
  volleyball,
  
  // Fitness
  yoga,
  pilates,
  dancing,
  aerobics,
  
  // Alltag
  cleaning,
  gardening,
  stairs,
  
  // Sonstiges
  other,
}

extension ActivityTypeExtension on ActivityType {
  /// MET (Metabolic Equivalent of Task) Werte
  /// Quelle: Compendium of Physical Activities
  double get metValue {
    switch (this) {
      // Cardio
      case ActivityType.walking:
        return 3.5; // Gemütliches Gehen
      case ActivityType.running:
        return 9.8; // 8 km/h Jogging
      case ActivityType.cycling:
        return 7.5; // Moderate Geschwindigkeit
      case ActivityType.swimming:
        return 8.0; // Moderates Tempo
      
      // Krafttraining
      case ActivityType.weightlifting:
        return 6.0; // Intensives Training
      case ActivityType.bodyweight:
        return 5.0; // Liegestütze, Klimmzüge, etc.
      
      // Sport
      case ActivityType.soccer:
        return 10.0; // Fußball
      case ActivityType.basketball:
        return 8.0;
      case ActivityType.tennis:
        return 7.0;
      case ActivityType.volleyball:
        return 4.0;
      
      // Fitness
      case ActivityType.yoga:
        return 3.0;
      case ActivityType.pilates:
        return 3.5;
      case ActivityType.dancing:
        return 5.0;
      case ActivityType.aerobics:
        return 7.0;
      
      // Alltag
      case ActivityType.cleaning:
        return 3.5; // Hausarbeit
      case ActivityType.gardening:
        return 4.0;
      case ActivityType.stairs:
        return 8.0; // Treppensteigen
      
      // Sonstiges
      case ActivityType.other:
        return 5.0; // Durchschnitt
    }
  }

  String get displayName {
    switch (this) {
      // Cardio
      case ActivityType.walking:
        return 'Gehen/Spazieren';
      case ActivityType.running:
        return 'Laufen/Joggen';
      case ActivityType.cycling:
        return 'Radfahren';
      case ActivityType.swimming:
        return 'Schwimmen';
      
      // Krafttraining
      case ActivityType.weightlifting:
        return 'Krafttraining (Gewichte)';
      case ActivityType.bodyweight:
        return 'Krafttraining (Körpergewicht)';
      
      // Sport
      case ActivityType.soccer:
        return 'Fußball';
      case ActivityType.basketball:
        return 'Basketball';
      case ActivityType.tennis:
        return 'Tennis';
      case ActivityType.volleyball:
        return 'Volleyball';
      
      // Fitness
      case ActivityType.yoga:
        return 'Yoga';
      case ActivityType.pilates:
        return 'Pilates';
      case ActivityType.dancing:
        return 'Tanzen';
      case ActivityType.aerobics:
        return 'Aerobic';
      
      // Alltag
      case ActivityType.cleaning:
        return 'Hausarbeit';
      case ActivityType.gardening:
        return 'Gartenarbeit';
      case ActivityType.stairs:
        return 'Treppensteigen';
      
      // Sonstiges
      case ActivityType.other:
        return 'Sonstiges';
    }
  }

  String get icon {
    switch (this) {
      case ActivityType.walking:
        return '🚶';
      case ActivityType.running:
        return '🏃';
      case ActivityType.cycling:
        return '🚴';
      case ActivityType.swimming:
        return '🏊';
      case ActivityType.weightlifting:
      case ActivityType.bodyweight:
        return '💪';
      case ActivityType.soccer:
        return '⚽';
      case ActivityType.basketball:
        return '🏀';
      case ActivityType.tennis:
        return '🎾';
      case ActivityType.volleyball:
        return '🏐';
      case ActivityType.yoga:
        return '🧘';
      case ActivityType.pilates:
        return '🤸';
      case ActivityType.dancing:
        return '💃';
      case ActivityType.aerobics:
        return '🏋️';
      case ActivityType.cleaning:
        return '🧹';
      case ActivityType.gardening:
        return '🌱';
      case ActivityType.stairs:
        return '🪜';
      case ActivityType.other:
        return '🏃';
    }
  }
}
