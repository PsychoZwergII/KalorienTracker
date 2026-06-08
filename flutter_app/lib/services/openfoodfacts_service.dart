import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/food_item.dart';
import './logger_service.dart';

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
        final json = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>?;
        
        if (json != null) {
          var translatedText = json['responseData']?['translatedText'] as String? ?? text;
          
          // Remove HTML tags that sometimes appear in translations (e.g., <g id="1">p</g>otato)
          translatedText = translatedText.replaceAll(RegExp(r'<[^>]+>'), '');
          
          // Cache the result
          _translationCache[cacheKey] = translatedText;
          
          return translatedText;
        }
      }
      
      LoggerService.warning('Translation API returned ${response.statusCode} for "$text"');
      _translationCache[cacheKey] = text; // Cache original as fallback
      return text;
    } catch (e) {
      LoggerService.warning('Translation API Error for "$text": $e');
      _translationCache[cacheKey] = text; // Cache original as fallback
      return text; // Return original if translation fails
    }
  }
  
  /// Search for products by name or query (BLV API) with parallel parsing
  Future<List<FoodItem>> searchProducts(String query) async {
    if (query.trim().isEmpty) return [];

    try {
      final String searchQuery = query.toLowerCase();
      // Neue Logik: Nur Deutsch, wenn explizit deutsche Sonderzeichen oder typische deutsche Wörter
      final isGerman = _looksExplicitlyGerman(searchQuery);

      String apiQuery = searchQuery;
      String lang = 'en';
      if (isGerman) {
        apiQuery = await _translateText(searchQuery, 'de', 'en');
        lang = 'de';
      }

      LoggerService.debug('🔍 Search: "$query" (German: $isGerman) → Query: "$apiQuery" (lang: $lang)');

      final url = Uri.parse('$_blvApiUrl/foods')
          .replace(queryParameters: {
            'search': apiQuery,
            'limit': '30',
            'lang': lang,
          });

      LoggerService.debug('📡 Calling: $url');

      final response = await http.get(url).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        LoggerService.warning('❌ API returned ${response.statusCode}');
        return [];
      }

      final jsonData = jsonDecode(utf8.decode(response.bodyBytes));

      // BLV returns a direct List
      final foods = (jsonData is List ? jsonData : []) as List<dynamic>;

      LoggerService.debug('📊 Got ${foods.length} results');

      if (foods.isEmpty) {
        return [];
      }

      // Parse up to 15 items, but do it in parallel batches of 5 for performance
      final List<FoodItem> results = [];
      final foodsToProcess = foods.take(15).toList();
      
      // Process in batches of 5 concurrent requests
      for (int batchStart = 0; batchStart < foodsToProcess.length; batchStart += 5) {
        final batchEnd = (batchStart + 5).clamp(0, foodsToProcess.length);
        final batch = foodsToProcess.sublist(batchStart, batchEnd);
        
        try {
          final batchResults = await Future.wait(
            batch.map((food) => _parseBLVFood(
              food as Map<String, dynamic>,
              translateToGerman: isGerman,
            )),
            eagerError: false, // Continue if one fails
          );
          
          for (final item in batchResults) {
            if (item != null) results.add(item);
          }
        } catch (e) {
          LoggerService.warning('⚠️ Parse batch error: $e');
        }
      }

      LoggerService.debug('✅ Created ${results.length} items');
      return results;
    } catch (e) {
      LoggerService.error('❌ Search error: $e');
      return [];
    }
  }

  /// Neue Logik: explizit deutsch, wenn Sonderzeichen oder typische Wörter
  bool _looksExplicitlyGerman(String word) {
    // Enthält deutsche Sonderzeichen?
    if (word.contains('ä') || word.contains('ö') || word.contains('ü') || word.contains('ss')) {
      return true;
    }
    // Enthält typische deutsche Begriffe?
    final germanWords = [
      'apfel', 'kartoffel', 'brot', 'käse', 'milch', 'butter', 'ei', 'fleisch',
      'huhn', 'fisch', 'salat', 'tomate', 'zwiebel', 'knoblauch', 'paprika',
      'nudel', 'reis', 'bohne', 'linse', 'erbse', 'möhre', 'karotte',
      'quark', 'wurst', 'schinken', 'rind', 'schwein', 'pute', 'geflügel',
      'joghurt', 'rahm', 'sahne', 'frischkäse', 'käsekuchen', 'leberwurst',
      'brötchen', 'semmel', 'brezel', 'kohl', 'rotkohl', 'sauerkraut',
      'spaetzle', 'knoedel', 'kloesse', 'gruenkohl', 'weisswurst', 'leberkaese',
      'schupfnudeln', 'schupfnudel', 'schupfnudeln', 'schupfnudel',
    ];
    return germanWords.any((w) => word.contains(w));
  }
  
  /// Check if word looks German
  bool _isGermanWord(String word) {
    final germanWords = {
      'apfel', 'kartoffel', 'brot', 'käse', 'milch', 'butter', 'ei', 'fleisch',
      'huhn', 'fisch', 'salat', 'tomate', 'zwiebel', 'knoblauch', 'paprika',
      'nudel', 'reis', 'bohne', 'linse', 'erbse', 'möhre', 'karotte',
    };
    return germanWords.contains(word);
  }
  
  /// Parse BLV Food data to FoodItem
  Future<FoodItem?> _parseBLVFood(Map<String, dynamic> food, {bool translateToGerman = false}) async {
    try {
      final foodId = food['id']?.toString();
      if (foodId == null || foodId.isEmpty) {
        return null;
      }

      // BLV search response uses 'foodName' directly (not in array)
      final name = food['foodName'] as String? ?? food['name'] as String? ?? '';
      if (name.isEmpty) {
        return null;
      }

      LoggerService.debug('🔄 Parsing: $name (ID: $foodId)');

      // Fetch detailed nutrition data
      final nutrients = await _fetchFoodNutrients(foodId);
      
      // Skip if no calories found
      if (nutrients['calories']! <= 0) {
        LoggerService.warning('⚠️ No calories for "$name"');
        return null;
      }

      // Translate food name to German only if original query was in German
      final displayName = translateToGerman ? await _translateText(name, 'en', 'de') : name;
      LoggerService.debug('✅ Created: $displayName - ${nutrients['calories']!.toStringAsFixed(1)} kcal');

      return FoodItem(
        id: foodId,
        label: displayName,
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
      LoggerService.error('❌ Parse error: $e');
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
        final json = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>?;
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
      LoggerService.warning('⚠️ Error fetching nutrients for $foodId: $e');
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
        final value = _convertToDouble(valueMap['value']);
        
        // Map BLV component names to our nutrition fields
        if (componentName.contains('energy') && componentName.contains('kilocalorie')) {
          // Prefer kilocalories (kcal)
          nutrients['calories'] = value;
        } else if (componentName == 'protein') {
          nutrients['protein'] = value;
        } else if (componentName.contains('carbohydrate')) {
          nutrients['carbs'] = value;
        } else if (componentName == 'fibre' || componentName == 'fiber') {
          nutrients['fiber'] = value;
        } else if (componentName.contains('fatty acid')) {
          // Sum all fatty acids
          nutrients['fat'] = (nutrients['fat'] ?? 0.0) + value;
        }
      }
      
      // If no fat extracted, set to 0
      if (nutrients['fat'] == null) {
        nutrients['fat'] = 0.0;
      }
      
      return nutrients;
    } catch (e) {
      LoggerService.warning('⚠️ Error extracting nutrients: $e');
      return {
        'calories': 0.0,
        'protein': 0.0,
        'fat': 0.0,
        'carbs': 0.0,
        'fiber': 0.0,
      };
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
      LoggerService.warning('⚠️ Error converting $value to double: $e');
      return 0.0;
    }
  }

  /// Get product by barcode (FoodRepo)
  Future<FoodItem?> getProductByBarcode(String barcode) async {
    LoggerService.debug('🔍 FoodRepo Barcode Search: $barcode');
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
        final json = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>?;
        
        if (json == null) {
          LoggerService.warning('⚠️ FoodRepo: Empty response');
          return null;
        }
        
        final data = json['data'] as Map<String, dynamic>?;
        
        if (data == null) {
          LoggerService.warning('⚠️ FoodRepo: No data field in response');
          return null;
        }
        
        return _parseFoodRepoProduct(data);
      } else if (response.statusCode == 404) {
        LoggerService.warning('⚠️ FoodRepo: Product not found for barcode $barcode');
        return null;
      } else {
        LoggerService.warning('⚠️ FoodRepo API returned ${response.statusCode}');
        return null;
      }
    } catch (e) {
      LoggerService.error('❌ FoodRepo search failed: $e');
      return null;
    }
  }

  /// Parse FoodRepo product data to FoodItem
  FoodItem? _parseFoodRepoProduct(Map<String, dynamic> data) {
    try {
      final name = data['name'] as String? ?? data['display_name'] as String? ?? '';
      if (name.isEmpty) {
        LoggerService.warning('⚠️ FoodRepo: Empty product name');
        return null;
      }

      final barcode = data['barcode']?.toString();
      if (barcode == null || barcode.isEmpty) {
        LoggerService.warning('⚠️ FoodRepo: No barcode in product data');
        return null;
      }

      final nutrients = data['nutrients'] as Map<String, dynamic>? ?? {};
      
      // FoodRepo Nährwerte (pro 100g)
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
        LoggerService.warning('⚠️ FoodRepo: Product has no valid nutrition data');
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
      LoggerService.error('❌ Error parsing FoodRepo product: $e');
      return null;
    }
  }
}
