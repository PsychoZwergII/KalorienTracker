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
      
      // BLV API Food Search Endpoint - correct endpoint is /foods with 'search' parameter
      final url = Uri.parse('$_blvApiUrl/foods')
          .replace(queryParameters: {
            'search': englishQuery,
            'limit': '20',
            'lang': 'en',
          });
      
      print('📡 BLV API URL: $url');
      
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as List<dynamic>?;
        
        if (json == null || json.isEmpty) {
          print('⚠️ BLV API: Empty response');
          return [];
        }
        
        print('📦 BLV API returned ${json.length} results');

        // Parse foods with translation
        final List<FoodItem> results = [];
        for (final foodMap in json.whereType<Map<String, dynamic>>()) {
          try {
            final item = await _parseBLVFood(foodMap);
            if (item != null) {
              results.add(item);
            }
          } catch (e) {
            print('⚠️ Error parsing individual BLV food: $e');
            continue;
          }
        }
        
        print('✅ Successfully parsed ${results.length} BLV products');
        return results;
      } else if (response.statusCode == 404) {
        print('⚠️ BLV API: No results found for "$englishQuery"');
        return [];
      } else {
        print('⚠️ BLV API returned ${response.statusCode}');
        print('📝 Response: ${response.body}');
        return [];
      }
    } catch (e) {
      print('❌ BLV API Error: $e');
      return [];
    }
  }
  
  /// Parse BLV Food data to FoodItem (mit MyMemory Rückübersetzung + Nährwerte)
  /// BLV API returns: {id, generic, names: [{id, term}], synonyms, categories}
  Future<FoodItem?> _parseBLVFood(Map<String, dynamic> food) async {
    try {
      final foodId = food['id']?.toString();
      if (foodId == null || foodId.isEmpty) {
        print('⚠️ BLV: No food ID');
        return null;
      }

      // BLV returns names in an array
      final names = food['names'] as List<dynamic>? ?? [];
      String? name;
      
      if (names.isNotEmpty) {
        final firstName = names.first as Map<String, dynamic>?;
        name = firstName?['term'] as String?;
      }
      
      if (name == null || name.isEmpty) {
        print('⚠️ BLV: No food name found');
        return null;
      }

      // Rückübersetzung: Englisch -> Deutsch via MyMemory API
      final germanLabel = await _translateText(name, 'en', 'de');

      // Fetch detailed nutrition data
      final nutrients = await _fetchFoodNutrients(foodId);
      
      // Skip if no useful nutrition data
      if (nutrients['calories']! <= 0) {
        print('⚠️ BLV: No nutrition data for "$germanLabel"');
        return null;
      }

      return FoodItem(
        id: foodId,
        label: germanLabel,
        calories: nutrients['calories']!,
        protein: nutrients['protein']!,
        fat: nutrients['fat']!,
        carbs: nutrients['carbs']!,
        fiber: nutrients['fiber']!,
        timestamp: DateTime.now(),
        source: 'blv',
        mealType: 'snack',
      );
    } catch (e) {
      print('❌ Error parsing BLV food: $e');
      return null;
    }
  }

  
  /// Fetch detailed nutrition data for a specific food by ID
  Future<Map<String, double>> _fetchFoodNutrients(String foodId) async {
    try {
      final url = Uri.parse('$_blvApiUrl/food/$foodId')
          .replace(queryParameters: {
            'lang': 'en',
          });
      
      final response = await http.get(url).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>?;
        if (json != null) {
          return _extractNutrients(json);
        }
      }
      
      return {
        'calories': 0.0,
        'protein': 0.0,
        'fat': 0.0,
        'carbs': 0.0,
        'fiber': 0.0,
      };
    } catch (e) {
      print('⚠️ Error fetching food nutrients: $e');
      return {
        'calories': 0.0,
        'protein': 0.0,
        'fat': 0.0,
        'carbs': 0.0,
        'fiber': 0.0,
      };
    }
  }
  
  /// Extract nutrition values from BLV food response
  Map<String, double> _extractNutrients(Map<String, dynamic> food) {
    try {
      final values = food['values'] as List<dynamic>? ?? [];
      
      final nutrients = <String, double>{
        'calories': 0.0,
        'protein': 0.0,
        'fat': 0.0,
        'carbs': 0.0,
        'fiber': 0.0,
      };
      
      for (final valueMap in values.whereType<Map<String, dynamic>>()) {
        final component = valueMap['component'] as Map<String, dynamic>?;
        final componentName = component?['name']?.toString().toLowerCase() ?? '';
        final value = valueMap['value'];
        final doubleValue = _convertToDouble(value);
        
        // Map BLV component names to our nutrition fields
        if (componentName.contains('energy') || componentName.contains('kcal')) {
          nutrients['calories'] = doubleValue;
        } else if (componentName.contains('protein')) {
          nutrients['protein'] = doubleValue;
        } else if (componentName.contains('fat') || componentName.contains('lipid')) {
          nutrients['fat'] = doubleValue;
        } else if (componentName.contains('carbohydrate')) {
          nutrients['carbs'] = doubleValue;
        } else if (componentName.contains('fiber') || componentName.contains('fibre')) {
          nutrients['fiber'] = doubleValue;
        }
      }
      
      return nutrients;
    } catch (e) {
      print('⚠️ Error extracting nutrients: $e');
      return {
        'calories': 0.0,
        'protein': 0.0,
        'fat': 0.0,
        'carbs': 0.0,
        'fiber': 0.0,
      };
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
