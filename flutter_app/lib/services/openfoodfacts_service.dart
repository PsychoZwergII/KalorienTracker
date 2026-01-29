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
    if (text.isEmpty) return text;
    
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
        final json = jsonDecode(response.body) as Map<String, dynamic>?;
        
        if (json != null) {
          final translatedText = json['responseData']?['translatedText'] as String? ?? text;
          
          // Cache the result
          _translationCache[cacheKey] = translatedText;
          
          return translatedText;
        }
      }
      
      print('⚠️ Translation API returned ${response.statusCode} for "$text"');
      _translationCache[cacheKey] = text; // Cache original as fallback
      return text;
    } catch (e) {
      print('⚠️ Translation API Error for "$text": $e');
      _translationCache[cacheKey] = text; // Cache original as fallback
      return text; // Return original if translation fails
    }
  }
  
  /// Search for products by name or query (BLV API - mit MyMemory Übersetzung)
  Future<List<FoodItem>> searchProducts(String query) async {
    if (query.trim().isEmpty) return [];
    
    try {
      // Übersetzung: Deutsch -> Englisch via MyMemory API
      final englishQuery = await _translateText(query, 'de', 'en');
      print('🔍 BLV API Search: "$query" → "$englishQuery"');
      
      // BLV API Food Search Endpoint
      final url = Uri.parse('$_blvApiUrl/Foods')
          .replace(queryParameters: {'searchTerm': englishQuery});
      
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>?;
        
        if (json == null) {
          print('⚠️ BLV API: Empty response');
          return [];
        }
        
        final foods = json['foods'] as List<dynamic>? ?? [];

        // Parse foods with translation
        final List<FoodItem> results = [];
        for (final food in foods.whereType<Map<String, dynamic>>()) {
          try {
            final item = await _parseBLVFood(food);
            if (item != null) {
              results.add(item);
            }
          } catch (e) {
            print('⚠️ Error parsing individual BLV food: $e');
            continue;
          }
        }
        
        print('✅ Found ${results.length} BLV products');
        return results;
      } else if (response.statusCode == 404) {
        print('⚠️ BLV API: No results found for "$englishQuery"');
        return [];
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
      if (name.isEmpty) {
        print('⚠️ BLV: Empty food name');
        return null;
      }

      // Rückübersetzung: Englisch -> Deutsch via MyMemory API
      final germanLabel = await _translateText(name, 'en', 'de');

      final foodId = food['foodId']?.toString() ?? food['id']?.toString();
      if (foodId == null || foodId.isEmpty) {
        print('⚠️ BLV: No food ID');
        return null;
      }
      
      // BLV gibt Nährwerte pro 100g in verschiedenen Feldern
      final nutrients = food['nutrients'] as Map<String, dynamic>? ?? {};
      
      final energy = _convertToDouble(nutrients['energy'] ?? 
                     nutrients['energyKcal'] ?? 
                     food['energy'] ?? 
                     food['energyKcal'] ?? 0);
      
      final protein = _convertToDouble(nutrients['protein'] ?? 
                      food['protein'] ?? 0);
      
      final fat = _convertToDouble(nutrients['fat'] ?? 
                  food['fat'] ?? 0);
      
      final carbs = _convertToDouble(nutrients['carbohydrates'] ?? 
                    food['carbs'] ?? 
                    food['carbohydrates'] ?? 0);
      
      final fiber = _convertToDouble(nutrients['fiber'] ?? 
                    food['fiber'] ?? 0);

      // Validierung: Mindestens Kalorien sollten > 0 sein
      if (energy <= 0) {
        print('⚠️ BLV: Product "$germanLabel" has no energy value');
        return null;
      }

      return FoodItem(
        id: foodId,
        label: germanLabel,
        calories: energy,
        protein: protein,
        fat: fat,
        carbs: carbs,
        fiber: fiber,
        timestamp: DateTime.now(),
        source: 'blv',
        mealType: 'snack',
      );
    } catch (e) {
      print('❌ Error parsing BLV food: $e');
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
        final json = jsonDecode(response.body) as Map<String, dynamic>?;
        
        if (json == null) {
          print('⚠️ FoodRepo: Empty response');
          return null;
        }
        
        final data = json['data'] as Map<String, dynamic>?;
        
        if (data == null) {
          print('⚠️ FoodRepo: No data field in response');
          return null;
        }
        
        return _parseFoodRepoProduct(data);
      } else if (response.statusCode == 404) {
        print('⚠️ FoodRepo: Product not found for barcode $barcode');
        return null;
      } else {
        print('⚠️ FoodRepo API returned ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ FoodRepo search failed: $e');
      return null;
    }
  }

  /// Parse FoodRepo product data to FoodItem
  FoodItem? _parseFoodRepoProduct(Map<String, dynamic> data) {
    try {
      final name = data['name'] as String? ?? data['display_name'] as String? ?? '';
      if (name.isEmpty) {
        print('⚠️ FoodRepo: Empty product name');
        return null;
      }

      final barcode = data['barcode']?.toString();
      if (barcode == null || barcode.isEmpty) {
        print('⚠️ FoodRepo: No barcode in product data');
        return null;
      }

      final nutrients = data['nutrients'] as Map<String, dynamic>? ?? {};
      
      // FoodRepo Nährwerte (pro 100g)
      // Energy kann in kcal, kJ, oder energy_kcal sein
      final energyValue = nutrients['energy'] ?? 
                         nutrients['energy_kcal'] ?? 
                         nutrients['energyKcal'] ?? 
                         nutrients['kcal'] ?? 0;
      
      final energy = _convertToDouble(energyValue);
      
      // Wenn Energie in kJ ist (> 100), zu kcal konvertieren (kJ / 4.184)
      final calories = energy > 100 ? (energy / 4.184) : energy;
      
      final protein = _convertToDouble(nutrients['protein'] ?? nutrients['proteins'] ?? 0);
      final fat = _convertToDouble(nutrients['fat'] ?? nutrients['lipid'] ?? 0);
      final carbs = _convertToDouble(nutrients['carbohydrates'] ?? nutrients['carbs'] ?? 0);
      final fiber = _convertToDouble(nutrients['fiber'] ?? nutrients['fibers'] ?? 0);

      // Validierung: Mindestens eine Nährwert sollte > 0 sein
      if (calories <= 0 && protein <= 0 && fat <= 0 && carbs <= 0) {
        print('⚠️ FoodRepo: Product has no valid nutrition data');
        return null;
      }

      return FoodItem(
        id: barcode,
        label: '$name 🇨🇭',
        calories: calories,
        protein: protein,
        fat: fat,
        carbs: carbs,
        fiber: fiber,
        mealType: 'snack',
        timestamp: DateTime.now(),
        source: 'foodrepo',
        barcode: barcode,
      );
    } catch (e) {
      print('❌ Error parsing FoodRepo product: $e');
      return null;
    }
  }
  
  /// Helper to safely convert values to double
  double _convertToDouble(dynamic value) {
    try {
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        final parsed = double.tryParse(value);
        return parsed ?? 0.0;
      }
      return 0.0;
    } catch (e) {
      print('⚠️ Error converting $value to double: $e');
      return 0.0;
    }
  }
}
