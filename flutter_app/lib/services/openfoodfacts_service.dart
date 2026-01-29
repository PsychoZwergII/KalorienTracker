import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/food_item.dart';

class OpenFoodFactsService {
  // FoodRepo für Barcodes + BLV für manuelle Suche
  
  // Schweizer BLV-Nährwertdatenbank Basis-Lebensmittel (pro 100g)
  static final List<Map<String, dynamic>> _baseFood = [
    // Obst (roh)
    {'name': 'Apfel, roh', 'calories': 52, 'protein': 0.3, 'fat': 0.2, 'carbs': 14, 'fiber': 2.4},
    {'name': 'Apfel, geschält', 'calories': 48, 'protein': 0.3, 'fat': 0.1, 'carbs': 12.8, 'fiber': 2.0},
    {'name': 'Birne, roh', 'calories': 57, 'protein': 0.4, 'fat': 0.3, 'carbs': 15, 'fiber': 3.1},
    {'name': 'Banane', 'calories': 89, 'protein': 1.1, 'fat': 0.3, 'carbs': 23, 'fiber': 2.6},
    {'name': 'Orange', 'calories': 47, 'protein': 0.9, 'fat': 0.1, 'carbs': 12, 'fiber': 2.4},
    {'name': 'Erdbeere', 'calories': 32, 'protein': 0.7, 'fat': 0.4, 'carbs': 7.7, 'fiber': 2.0},
    {'name': 'Trauben', 'calories': 69, 'protein': 0.6, 'fat': 0.3, 'carbs': 18, 'fiber': 1.5},
    {'name': 'Kiwi', 'calories': 61, 'protein': 1.1, 'fat': 0.5, 'carbs': 15, 'fiber': 3.0},
    
    // Gemüse (roh)
    {'name': 'Tomate, roh', 'calories': 18, 'protein': 0.9, 'fat': 0.2, 'carbs': 3.9, 'fiber': 1.2},
    {'name': 'Gurke, roh', 'calories': 15, 'protein': 0.7, 'fat': 0.1, 'carbs': 3.6, 'fiber': 0.5},
    {'name': 'Karotte, roh', 'calories': 41, 'protein': 0.9, 'fat': 0.2, 'carbs': 10, 'fiber': 2.8},
    {'name': 'Paprika, roh', 'calories': 20, 'protein': 0.9, 'fat': 0.3, 'carbs': 4.6, 'fiber': 1.9},
    {'name': 'Salat, grün', 'calories': 14, 'protein': 1.3, 'fat': 0.2, 'carbs': 2.3, 'fiber': 1.5},
    {'name': 'Zwiebel, roh', 'calories': 40, 'protein': 1.1, 'fat': 0.1, 'carbs': 9.3, 'fiber': 1.4},
    {'name': 'Broccoli, roh', 'calories': 34, 'protein': 2.8, 'fat': 0.4, 'carbs': 6.6, 'fiber': 2.6},
    
    // Kartoffeln & Beilagen
    {'name': 'Kartoffeln, gekocht', 'calories': 87, 'protein': 2.0, 'fat': 0.1, 'carbs': 20, 'fiber': 1.8},
    {'name': 'Kartoffeln, roh', 'calories': 77, 'protein': 2.0, 'fat': 0.1, 'carbs': 17, 'fiber': 1.4},
    {'name': 'Pommes Frites', 'calories': 312, 'protein': 3.4, 'fat': 15, 'carbs': 41, 'fiber': 3.3},
    {'name': 'Reis, gekocht', 'calories': 130, 'protein': 2.7, 'fat': 0.3, 'carbs': 28, 'fiber': 0.4},
    {'name': 'Reis, roh', 'calories': 350, 'protein': 7.0, 'fat': 0.6, 'carbs': 77, 'fiber': 1.4},
    {'name': 'Pasta, gekocht', 'calories': 131, 'protein': 5.0, 'fat': 1.1, 'carbs': 25, 'fiber': 1.8},
    {'name': 'Pasta, roh', 'calories': 350, 'protein': 13, 'fat': 1.5, 'carbs': 71, 'fiber': 3.2},
    
    // Brot & Getreide
    {'name': 'Brot, Weiss', 'calories': 265, 'protein': 9.0, 'fat': 3.2, 'carbs': 49, 'fiber': 2.7},
    {'name': 'Brot, Vollkorn', 'calories': 219, 'protein': 7.5, 'fat': 2.2, 'carbs': 42, 'fiber': 6.9},
    {'name': 'Brötchen', 'calories': 276, 'protein': 8.7, 'fat': 3.6, 'carbs': 52, 'fiber': 2.7},
    {'name': 'Haferflocken', 'calories': 368, 'protein': 13, 'fat': 7.0, 'carbs': 58, 'fiber': 10},
    {'name': 'Cornflakes', 'calories': 378, 'protein': 7.9, 'fat': 0.9, 'carbs': 84, 'fiber': 2.4},
    
    // Milchprodukte
    {'name': 'Milch, Vollmilch', 'calories': 64, 'protein': 3.3, 'fat': 3.5, 'carbs': 4.7, 'fiber': 0},
    {'name': 'Milch, fettarm', 'calories': 42, 'protein': 3.4, 'fat': 1.0, 'carbs': 5.0, 'fiber': 0},
    {'name': 'Joghurt, natur', 'calories': 59, 'protein': 10, 'fat': 0.4, 'carbs': 3.6, 'fiber': 0},
    {'name': 'Joghurt, Vollmilch', 'calories': 66, 'protein': 3.5, 'fat': 3.5, 'carbs': 4.0, 'fiber': 0},
    {'name': 'Quark, mager', 'calories': 73, 'protein': 13, 'fat': 0.3, 'carbs': 4.0, 'fiber': 0},
    {'name': 'Käse, Emmentaler', 'calories': 403, 'protein': 28, 'fat': 31, 'carbs': 0.1, 'fiber': 0},
    {'name': 'Käse, Mozzarella', 'calories': 254, 'protein': 19, 'fat': 19, 'carbs': 1.0, 'fiber': 0},
    {'name': 'Butter', 'calories': 717, 'protein': 0.7, 'fat': 81, 'carbs': 0.7, 'fiber': 0},
    
    // Eier
    {'name': 'Ei, roh', 'calories': 155, 'protein': 13, 'fat': 11, 'carbs': 1.1, 'fiber': 0},
    {'name': 'Ei, gekocht', 'calories': 155, 'protein': 13, 'fat': 11, 'carbs': 1.1, 'fiber': 0},
    
    // Fleisch
    {'name': 'Pouletbrust, roh', 'calories': 110, 'protein': 23, 'fat': 1.2, 'carbs': 0, 'fiber': 0},
    {'name': 'Pouletbrust, gebraten', 'calories': 165, 'protein': 31, 'fat': 3.6, 'carbs': 0, 'fiber': 0},
    {'name': 'Rindsfleisch, mager', 'calories': 105, 'protein': 21, 'fat': 2.0, 'carbs': 0, 'fiber': 0},
    {'name': 'Schweinefleisch', 'calories': 143, 'protein': 20, 'fat': 7.0, 'carbs': 0, 'fiber': 0},
    {'name': 'Bratwurst', 'calories': 285, 'protein': 13, 'fat': 25, 'carbs': 1.0, 'fiber': 0},
    
    // Fisch
    {'name': 'Lachs, roh', 'calories': 208, 'protein': 20, 'fat': 13, 'carbs': 0, 'fiber': 0},
    {'name': 'Forelle', 'calories': 103, 'protein': 19, 'fat': 2.7, 'carbs': 0, 'fiber': 0},
    {'name': 'Thunfisch, Dose', 'calories': 128, 'protein': 28, 'fat': 1.0, 'carbs': 0, 'fiber': 0},
    
    // Nüsse
    {'name': 'Mandeln', 'calories': 579, 'protein': 21, 'fat': 50, 'carbs': 22, 'fiber': 12},
    {'name': 'Walnüsse', 'calories': 654, 'protein': 15, 'fat': 65, 'carbs': 14, 'fiber': 6.7},
    {'name': 'Erdnüsse', 'calories': 567, 'protein': 26, 'fat': 49, 'carbs': 16, 'fiber': 8.5},
    
    // Hülsenfrüchte
    {'name': 'Linsen, gekocht', 'calories': 116, 'protein': 9.0, 'fat': 0.4, 'carbs': 20, 'fiber': 7.9},
    {'name': 'Kichererbsen, gekocht', 'calories': 164, 'protein': 8.9, 'fat': 2.6, 'carbs': 27, 'fiber': 7.6},
    {'name': 'Bohnen, grün', 'calories': 31, 'protein': 1.8, 'fat': 0.2, 'carbs': 7.1, 'fiber': 3.4},
  ];

  /// Search for products by name or query (nur BLV-Datenbank)
  Future<List<FoodItem>> searchProducts(String query) async {
    if (query.trim().isEmpty) return [];
    
    print('🔍 BLV Search: "$query"');
    final results = _searchBaseFood(query);
    print('✅ Found ${results.length} BLV products');
    return results;
  }
  
  List<FoodItem> _searchBaseFood(String query) {
    final lowerQuery = query.toLowerCase();
    return _baseFood
        .where((food) => food['name'].toString().toLowerCase().contains(lowerQuery))
        .map((food) => FoodItem(
              id: 'base_${food['name']}',
              label: '${food['name']} (Basis)',
              calories: (food['calories'] as num).toDouble(),
              protein: (food['protein'] as num).toDouble(),
              fat: (food['fat'] as num).toDouble(),
              carbs: (food['carbs'] as num).toDouble(),
              fiber: (food['fiber'] as num).toDouble(),
              timestamp: DateTime.now(),
              source: 'base',
              mealType: 'snack',
            ))
        .toList();
  }


  /// Get product by barcode (nur FoodRepo)
  Future<FoodItem?> getProductByBarcode(String barcode) async {
    print('🔍 FoodRepo Barcode Search: $barcode');
    return await _searchFoodRepo(barcode);
  }
  
  /// FoodRepo API (Schweizer Barcodes)
  Future<FoodItem?> _searchFoodRepo(String barcode) async {
    try {
      final url = Uri.parse('https://www.foodrepo.org/api/v3/products/$barcode');
      final response = await http.get(
        url,
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final data = json['data'] as Map<String, dynamic>?;
        
        if (data != null) {
          return _parseFoodRepoProduct(data);
        }
      }
      return null;
    } catch (e) {
      print('⚠️ FoodRepo search failed: $e');
      return null;
    }
  }


  
  /// Parse FoodRepo product data to FoodItem
  FoodItem? _parseFoodRepoProduct(Map<String, dynamic> data) {
    try {
      final name = data['name'] as String? ?? data['display_name'] as String? ?? '';
      if (name.isEmpty) return null;

      final nutrients = data['nutrients'] as Map<String, dynamic>? ?? {};
      
      // FoodRepo gibt Werte pro 100g an
      final energy = (nutrients['energy'] ?? nutrients['energyKcal'] ?? 0) as num;
      final proteins = (nutrients['protein'] ?? 0) as num;
      final fat = (nutrients['fat'] ?? 0) as num;
      final carbs = (nutrients['carbohydrates'] ?? 0) as num;
      final fiber = (nutrients['fibers'] ?? nutrients['fiber'] ?? 0) as num;

      return FoodItem(
        id: data['barcode']?.toString() ?? DateTime.now().toString(),
        label: '$name 🇨🇭', // CH-Flag für Schweizer Produkte
        calories: energy.toDouble(),
        protein: proteins.toDouble(),
        fat: fat.toDouble(),
        carbs: carbs.toDouble(),
        fiber: fiber.toDouble(),
        mealType: 'snack',
        timestamp: DateTime.now(),
        source: 'foodrepo',
        barcode: data['barcode']?.toString(),
      );
    } catch (e) {
      print('Error parsing FoodRepo product: $e');
      return null;
    }
  }
}
