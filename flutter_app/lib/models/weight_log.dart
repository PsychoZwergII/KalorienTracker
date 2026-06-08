import 'package:json_annotation/json_annotation.dart';
import '../services/validation_service.dart';

part 'weight_log.g.dart';

@JsonSerializable()
class WeightLog {
  final String logId;
  final String userId;
  final double weight; // kg
  final DateTime timestamp;
  final String? note;

  WeightLog({
    required this.logId,
    required this.userId,
    required this.weight,
    required this.timestamp,
    this.note,
  }) {
    _validate();
  }

  void _validate() {
    // Validate weight
    final weightError = ValidationService.validateWeight(weight);
    if (weightError != null) {
      throw ArgumentError(weightError);
    }

    // Validate timestamp
    final timestampError = ValidationService.validateTimestamp(timestamp);
    if (timestampError != null) {
      throw ArgumentError(timestampError);
    }

    // Validate note if present
    if (note != null && note!.isEmpty) {
      throw ArgumentError('Note cannot be empty string');
    }
    if (note != null && note!.length > 500) {
      throw ArgumentError('Note cannot exceed 500 characters');
    }
  }

  factory WeightLog.fromJson(Map<String, dynamic> json) => _$WeightLogFromJson(json);
  Map<String, dynamic> toJson() => _$WeightLogToJson(this);

  WeightLog copyWith({
    String? logId,
    String? userId,
    double? weight,
    DateTime? timestamp,
    String? note,
  }) {
    return WeightLog(
      logId: logId ?? this.logId,
      userId: userId ?? this.userId,
      weight: weight ?? this.weight,
      timestamp: timestamp ?? this.timestamp,
      note: note ?? this.note,
    );
  }
}
