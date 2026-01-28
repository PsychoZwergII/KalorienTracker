import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/food_item.dart';
import '../models/user_profile.dart';
import '../models/activity.dart';
import '../models/weight_log.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = Uuid();

  /// Collection reference for a user's food items
  CollectionReference _foodItemsCollection(String userId) =>
      _firestore.collection('users').doc(userId).collection('foodItems');

  /// Add food item for user
  Future<String> addFoodItem(String userId, FoodItem foodItem) async {
    try {
      final docRef = await _foodItemsCollection(userId).add(
        foodItem.toFirestore(),
      );
      return docRef.id;
    } catch (e) {
      print('Add Food Item Error: $e');
      rethrow;
    }
  }

  /// Get food items for today
  Stream<List<FoodItem>> getTodaysFoods(String userId) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    return _foodItemsCollection(userId)
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => FoodItem.fromFirestore(doc)).toList());
  }

  /// Get favorite foods
  Stream<List<FoodItem>> getFavoriteFoods(String userId) {
    return _foodItemsCollection(userId)
        .where('isFavorite', isEqualTo: true)
        .orderBy('label')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => FoodItem.fromFirestore(doc)).toList());
  }

  /// Update food item
  Future<void> updateFoodItem(String userId, FoodItem foodItem) async {
    try {
      await _foodItemsCollection(userId).doc(foodItem.id).update(
            foodItem.toFirestore(),
          );
    } catch (e) {
      print('Update Food Item Error: $e');
      rethrow;
    }
  }

  /// Delete food item
  Future<void> deleteFoodItem(String userId, String foodId) async {
    try {
      await _foodItemsCollection(userId).doc(foodId).delete();
    } catch (e) {
      print('Delete Food Item Error: $e');
      rethrow;
    }
  }

  /// Toggle favorite
  Future<void> toggleFavorite(String userId, String foodId, bool newState) async {
    try {
      await _foodItemsCollection(userId).doc(foodId).update({
        'isFavorite': newState,
      });
    } catch (e) {
      print('Toggle Favorite Error: $e');
      rethrow;
    }
  }

  /// Get total calories for date
  Future<double> getTotalCaloriesByDate(String userId, DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final snapshot = await _foodItemsCollection(userId)
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .get();

      double total = 0;
      for (var doc in snapshot.docs) {
        total += (doc['calories'] as num).toDouble();
      }
      return total;
    } catch (e) {
      print('Get Total Calories Error: $e');
      return 0;
    }
  }

  /// Get macros for date
  Future<Map<String, double>> getMacrosByDate(String userId, DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final snapshot = await _foodItemsCollection(userId)
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .get();

      double protein = 0, fat = 0, carbs = 0;
      for (var doc in snapshot.docs) {
        protein += (doc['protein'] as num).toDouble();
        fat += (doc['fat'] as num).toDouble();
        carbs += (doc['carbs'] as num).toDouble();
      }
      return {
        'protein': protein,
        'fat': fat,
        'carbs': carbs,
      };
    } catch (e) {
      print('Get Macros Error: $e');
      return {'protein': 0, 'fat': 0, 'carbs': 0};
    }
  }

  /// Save user profile
  Future<void> saveUserProfile(String userId, Map<String, dynamic> profile) async {
    try {
      await _firestore.collection('users').doc(userId).update(profile);
    } catch (e) {
      print('Save User Profile Error: $e');
      rethrow;
    }
  }

  /// Get user profile
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.data();
    } catch (e) {
      print('Get User Profile Error: $e');
      return null;
    }
  }

  // ==================== USER PROFILE METHODS ====================

  /// Save complete user profile
  Future<void> saveCompleteUserProfile(UserProfile profile) async {
    try {
      await _firestore.collection('users').doc(profile.userId).set(
        profile.toJson(),
        SetOptions(merge: true),
      );
    } catch (e) {
      print('Save Complete User Profile Error: $e');
      rethrow;
    }
  }

  /// Get complete user profile
  Future<UserProfile?> getCompleteUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) {
        return null;
      }
      return UserProfile.fromJson(doc.data()!);
    } catch (e) {
      print('Get Complete User Profile Error: $e');
      return null;
    }
  }

  /// Stream user profile for real-time updates
  Stream<UserProfile?> streamUserProfile(String userId) {
    return _firestore.collection('users').doc(userId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserProfile.fromJson(doc.data()!);
    });
  }

  // ==================== ACTIVITY TRACKING METHODS ====================

  CollectionReference _activitiesCollection(String userId) =>
      _firestore.collection('users').doc(userId).collection('activities');

  /// Add activity for user
  Future<String> addActivity(String userId, Activity activity) async {
    try {
      final docRef = await _activitiesCollection(userId).add(
        activity.toJson(),
      );
      return docRef.id;
    } catch (e) {
      print('Add Activity Error: $e');
      rethrow;
    }
  }

  /// Get activities for today
  Stream<List<Activity>> getTodaysActivities(String userId) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    return _activitiesCollection(userId)
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              data['activityId'] = doc.id;
              return Activity.fromJson(data);
            }).toList());
  }

  /// Get activities for specific date
  Future<List<Activity>> getActivitiesByDate(String userId, DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final snapshot = await _activitiesCollection(userId)
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['activityId'] = doc.id;
        return Activity.fromJson(data);
      }).toList();
    } catch (e) {
      print('Get Activities By Date Error: $e');
      return [];
    }
  }

  /// Delete activity
  Future<void> deleteActivity(String userId, String activityId) async {
    try {
      await _activitiesCollection(userId).doc(activityId).delete();
    } catch (e) {
      print('Delete Activity Error: $e');
      rethrow;
    }
  }

  /// Get total calories burned for date
  Future<double> getTotalCaloriesBurnedByDate(String userId, DateTime date) async {
    try {
      final activities = await getActivitiesByDate(userId, date);
      return activities.fold(0.0, (sum, activity) => sum + activity.caloriesBurned);
    } catch (e) {
      print('Get Total Calories Burned Error: $e');
      return 0;
    }
  }

  // ==================== WEIGHT LOG METHODS ====================

  CollectionReference _weightLogsCollection(String userId) =>
      _firestore.collection('users').doc(userId).collection('weightLogs');

  /// Add weight log (checkpoint)
  Future<String> addWeightLog(String userId, WeightLog weightLog) async {
    try {
      final docRef = await _weightLogsCollection(userId).add(
        weightLog.toJson(),
      );
      return docRef.id;
    } catch (e) {
      print('Add Weight Log Error: $e');
      rethrow;
    }
  }

  /// Get all weight logs for user (sorted by date)
  Future<List<WeightLog>> getWeightLogs(String userId, {int? limit}) async {
    try {
      Query query = _weightLogsCollection(userId)
          .orderBy('timestamp', descending: true);
      
      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['logId'] = doc.id;
        return WeightLog.fromJson(data);
      }).toList();
    } catch (e) {
      print('Get Weight Logs Error: $e');
      return [];
    }
  }

  /// Stream weight logs for real-time updates
  Stream<List<WeightLog>> streamWeightLogs(String userId, {int? limit}) {
    Query query = _weightLogsCollection(userId)
        .orderBy('timestamp', descending: true);
    
    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['logId'] = doc.id;
        return WeightLog.fromJson(data);
      }).toList();
    });
  }

  /// Delete weight log
  Future<void> deleteWeightLog(String userId, String logId) async {
    try {
      await _weightLogsCollection(userId).doc(logId).delete();
    } catch (e) {
      print('Delete Weight Log Error: $e');
      rethrow;
    }
  }

  /// Get latest weight log
  Future<WeightLog?> getLatestWeightLog(String userId) async {
    try {
      final snapshot = await _weightLogsCollection(userId)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      final data = snapshot.docs.first.data() as Map<String, dynamic>;
      data['logId'] = snapshot.docs.first.id;
      return WeightLog.fromJson(data);
    } catch (e) {
      print('Get Latest Weight Log Error: $e');
      return null;
    }
  }
}

