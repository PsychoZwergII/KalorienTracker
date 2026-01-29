import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/food_item.dart';

class OpenFoodFactsService {
  // BLV Swiss Food Composition Database API + FoodRepo für Barcodes
  static const String _blvApiUrl = 'https://api.webapp.prod.blv.foodcase-services.com/BLV_WebApp_WS/webresources/BLV-api';
  static const String _mymemoryApiUrl = 'https://api.mymemory.translated.net/get';
  
  // Cache für Übersetzungen um API-Calls zu sparen
  static final Map<String, String> _translationCache = {};
  
  /// Translate text using MyMemory API (kostenlos, keine Authentifizierung)
  Future<String> _translateText(String text, String fromLang, String toLang) async {
    final cacheKey = '$text|$fromLang|$toLang';
    
    // Check cache first
    if (_translationCache.containsKey(cacheKey)) {
      return _translationCache[cacheKey]!;
    }
    
    try {
      final url = Uri.parse(_mymemoryApiUrl)
          .replace(queryParameters: {
            'q': text,
            'langpair': '$fromLang|$toLang',
          });
      
      final response = await http.get(url).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final translatedText = json['responseData']?['translatedText'] as String? ?? text;
        
        // Cache the result
        _translationCache[cacheKey] = translatedText;
        
        return translatedText;
      }
      return text;
    } catch (e) {
      print('⚠️ Translation API Error: $e');
      return text; // Return original if translation fails
    }
  }
  
  /// Search for products by name or query (BLV API - mit MyMemory Übersetzung)
  Future<List<FoodItem>> searchProducts(String query) async {
    if (query.trim().isEmpty) return [];
    
    // Übersetzung: Deutsch -> Englisch via MyMemory API
    final englishQuery = await _translateText(query, 'de', 'en');
    print('🔍 BLV API Search: "$query" → "$englishQuery"');
    
    try {
      // BLV API Food Search Endpoint
      final url = Uri.parse('$_blvApiUrl/Foods')
          .replace(queryParameters: {'searchTerm': englishQuery});
      
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final foods = json['foods'] as List<dynamic>? ?? [];

        // Parse foods with translation
        final List<FoodItem> results = [];
        for (final food in foods.whereType<Map<String, dynamic>>()) {
          final item = await _parseBLVFood(food);
          if (item != null) {
            results.add(item);
          }
        }
        
        print('✅ Found ${results.length} BLV products');
        return results;
      } else {
        print('⚠️ BLV API returned ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ BLV API Error: $e');
      return [];
    }
  }
  
  
  /// Parse BLV Food data to FoodItem (mit MyMemory Rückübersetzung)
  Future<FoodItem?> _parseBLVFood(Map<String, dynamic> food) async {
    try {
      final name = food['foodName'] as String? ?? 
                   food['name'] as String? ?? '';
      if (name.isEmpty) return null;

      // Rückübersetzung: Englisch -> Deutsch via MyMemory API
      final germanLabel = await _translateText(name, 'en', 'de');

      final foodId = food['foodId']?.toString() ?? DateTime.now().toString();
      
      // BLV gibt Nährwerte pro 100g in verschiedenen Feldern
      final nutrients = food['nutrients'] as Map<String, dynamic>? ?? {};
      
      final energy = (nutrients['energy'] ?? 
                     nutrients['energyKcal'] ?? 
                     food['energy'] ?? 
                     food['energyKcal'] ?? 0) as num;
      
      final protein = (nutrients['protein'] ?? 
                      food['protein'] ?? 0) as num;
      
      final fat = (nutrients['fat'] ?? 
                  food['fat'] ?? 0) as num;
      
      final carbs = (nutrients['carbohydrates'] ?? 
                    food['carbs'] ?? 
                    food['carbohydrates'] ?? 0) as num;
      
      final fiber = (nutrients['fiber'] ?? 
                    food['fiber'] ?? 0) as num;

      return FoodItem(
        id: foodId,
        label: germanLabel,
        calories: energy.toDouble(),
        protein: protein.toDouble(),
        fat: fat.toDouble(),
        carbs: carbs.toDouble(),
        fiber: fiber.toDouble(),
        timestamp: DateTime.now(),
        source: 'blv',
        mealType: 'snack',
      );
    } catch (e) {
      print('Error parsing BLV food: $e');
      return null;
    }
  }

  /// Get product by barcode (FoodRepo)
  Future<FoodItem?> getProductByBarcode(String barcode) async {
    print('🔍 FoodRepo Barcode Search: $barcode');
    return await _searchFoodRepo(barcode);
  }
  
  /// FoodRepo API (Schweizer Barcodes mit 14,000+ Produkten)
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
