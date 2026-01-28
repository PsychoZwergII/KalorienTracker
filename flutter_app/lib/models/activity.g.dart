// GENERATED CODE - DO NOT MODIFY BY HAND
// This is a temporary placeholder file until build_runner generates the real file

part of 'activity.dart';

// Temporary implementations - will be replaced by build_runner
Activity _$ActivityFromJson(Map<String, dynamic> json) {
  return Activity(
    activityId: json['activityId'] as String,
    userId: json['userId'] as String,
    type: ActivityType.values.firstWhere((e) => e.toString() == 'ActivityType.${json['type']}'),
    customName: json['customName'] as String?,
    durationMinutes: json['durationMinutes'] as int,
    caloriesBurned: (json['caloriesBurned'] as num).toDouble(),
    timestamp: DateTime.parse(json['timestamp'] as String),
    notes: json['notes'] as String?,
  );
}

Map<String, dynamic> _$ActivityToJson(Activity instance) => {
  'activityId': instance.activityId,
  'userId': instance.userId,
  'type': instance.type.toString().split('.').last,
  'customName': instance.customName,
  'durationMinutes': instance.durationMinutes,
  'caloriesBurned': instance.caloriesBurned,
  'timestamp': instance.timestamp.toIso8601String(),
  'notes': instance.notes,
};
