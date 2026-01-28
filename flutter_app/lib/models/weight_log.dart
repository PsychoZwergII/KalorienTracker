import 'package:json_annotation/json_annotation.dart';

part 'weight_log.g.dart';

@JsonSerializable()
class WeightLog {
  final String logId;
  final String userId;
  final double weight; // kg
  final DateTime timestamp;
  final String? note; // Optional: "Nach Urlaub", "Training gestartet", etc.

  WeightLog({
    required this.logId,
    required this.userId,
    required this.weight,
    required this.timestamp,
    this.note,
  });

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
