import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/food_item.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
}
