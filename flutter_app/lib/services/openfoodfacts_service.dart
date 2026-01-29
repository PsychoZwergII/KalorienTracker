import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/food_item.dart';

class OpenFoodFactsService {
  static const String _baseUrl = 'https://world.openfoodfacts.org';

  /// Search for products by name or query
  Future<List<FoodItem>> searchProducts(String query) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/cgi/search.pl?search_terms=$query&page_size=20&action=process&json=1',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final products = json['products'] as List<dynamic>? ?? [];

        return products
            .whereType<Map<String, dynamic>>()
            .map((p) => _parseProductToFoodItem(p))
            .where((item) => item != null)
            .cast<FoodItem>()
            .toList();
      }
      return [];
    } catch (e) {
      print('Error searching products: $e');
      return [];
    }
  }

  /// Get product by barcode
  Future<FoodItem?> getProductByBarcode(String barcode) async {
    try {
      final url = Uri.parse('$_baseUrl/api/v0/product/$barcode.json');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final product = json['product'] as Map<String, dynamic>?;

        if (product != null) {
          return _parseProductToFoodItem(product);
        }
      }
      return null;
    } catch (e) {
      print('Error fetching product: $e');
      return null;
    }
  }

  /// Parse API product data to FoodItem
  FoodItem? _parseProductToFoodItem(Map<String, dynamic> product) {
    try {
      final name =
          product['product_name'] as String? ?? product['name'] as String? ?? '';
      if (name.isEmpty) return null;

      final serving = (product['serving_size'] as String? ?? '100g')
          .replaceAll(RegExp(r'[^\d.]'), '')
          .isEmpty
          ? 100.0
          : double.tryParse(
                  product['serving_size']
                      .replaceAll(RegExp(r'[^\d.]'), '')
                      .toString()) ??
              100.0;

      final nutrients = product['nutriments'] as Map<String, dynamic>? ?? {};

      final energy = (nutrients['energy-kcal'] ??
              nutrients['energy-kcal_100g'] ??
              nutrients['energy'] ??
              nutrients['energy_100g'] ??
              0) as num;

      final proteins = (nutrients['proteins'] ??
              nutrients['proteins_100g'] ??
              0) as num;

      final fat = (nutrients['fat'] ??
              nutrients['fat_100g'] ??
              0) as num;

      final carbs = (nutrients['carbohydrates'] ??
              nutrients['carbohydrates_100g'] ??
              0) as num;

      final fiber =
          (nutrients['fiber'] ?? nutrients['fiber_100g'] ?? 0) as num;

      // Calculate for actual serving size if different from 100g
      final multiplier = serving / 100.0;

      return FoodItem(
        id: product['code']?.toString() ?? DateTime.now().toString(),
        label: name,
        calories: (energy * multiplier).toDouble(),
        protein: (proteins * multiplier).toDouble(),
        fat: (fat * multiplier).toDouble(),
        carbs: (carbs * multiplier).toDouble(),
        fiber: (fiber * multiplier).toDouble(),
        mealType: 'snack', // Default meal type, user can change this
        timestamp: DateTime.now(),
        userId: '', // Will be set by the app
      );
    } catch (e) {
      print('Error parsing product: $e');
      return null;
    }
  }
}
