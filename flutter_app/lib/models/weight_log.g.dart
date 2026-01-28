// GENERATED CODE - DO NOT MODIFY BY HAND
// This is a temporary placeholder file until build_runner generates the real file

part of 'weight_log.dart';

// Temporary implementations - will be replaced by build_runner
WeightLog _$WeightLogFromJson(Map<String, dynamic> json) {
  return WeightLog(
    logId: json['logId'] as String,
    userId: json['userId'] as String,
    weight: (json['weight'] as num).toDouble(),
    timestamp: DateTime.parse(json['timestamp'] as String),
    note: json['note'] as String?,
  );
}

Map<String, dynamic> _$WeightLogToJson(WeightLog instance) => {
  'logId': instance.logId,
  'userId': instance.userId,
  'weight': instance.weight,
  'timestamp': instance.timestamp.toIso8601String(),
  'note': instance.note,
};
