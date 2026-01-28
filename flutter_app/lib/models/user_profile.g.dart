// GENERATED CODE - DO NOT MODIFY BY HAND
// This is a temporary placeholder file until build_runner generates the real file

part of 'user_profile.dart';

// Temporary implementations - will be replaced by build_runner
UserProfile _$UserProfileFromJson(Map<String, dynamic> json) {
  return UserProfile(
    userId: json['userId'] as String,
    displayName: json['displayName'] as String?,
    email: json['email'] as String?,
    startWeight: (json['startWeight'] as num?)?.toDouble(),
    currentWeight: (json['currentWeight'] as num?)?.toDouble(),
    targetWeight: (json['targetWeight'] as num?)?.toDouble(),
    height: (json['height'] as num?)?.toDouble(),
    age: json['age'] as int?,
    gender: json['gender'] == null ? null : Gender.values.firstWhere((e) => e.toString() == 'Gender.${json['gender']}'),
    activityLevel: json['activityLevel'] == null ? null : ActivityLevel.values.firstWhere((e) => e.toString() == 'ActivityLevel.${json['activityLevel']}'),
    weightGoal: json['weightGoal'] == null ? null : WeightGoal.values.firstWhere((e) => e.toString() == 'WeightGoal.${json['weightGoal']}'),
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );
}

Map<String, dynamic> _$UserProfileToJson(UserProfile instance) => {
  'userId': instance.userId,
  'displayName': instance.displayName,
  'email': instance.email,
  'startWeight': instance.startWeight,
  'currentWeight': instance.currentWeight,
  'targetWeight': instance.targetWeight,
  'height': instance.height,
  'age': instance.age,
  'gender': instance.gender?.toString().split('.').last,
  'activityLevel': instance.activityLevel?.toString().split('.').last,
  'weightGoal': instance.weightGoal?.toString().split('.').last,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
};
