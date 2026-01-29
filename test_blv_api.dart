import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  print('🧪 Testing BLV API directly...\n');
  
  // Test 1: Apple
  print('='*60);
  print('Test 1: BLV /foods search for "apple"');
  print('='*60);
  
  final url1 = Uri.parse('https://api.webapp.prod.blv.foodcase-services.com/BLV_WebApp_WS/webresources/BLV-api/foods')
      .replace(queryParameters: {
        'search': 'apple',
        'limit': '10',
        'lang': 'en',
      });
  
  print('URL: $url1\n');
  
  try {
    final response = await http.get(url1).timeout(const Duration(seconds: 15));
    print('Status: ${response.statusCode}');
    print('Headers: ${response.headers}');
    print('Body length: ${response.body.length}');
    print('Body (first 500 chars):');
    print(response.body.substring(0, (response.body.length > 500 ? 500 : response.body.length)));
    print('\n');
    
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      print('Type: ${json.runtimeType}');
      if (json is List) {
        print('List length: ${json.length}');
        if (json.isNotEmpty) {
          print('First item: ${jsonEncode(json[0])}');
        }
      } else {
        print('Full JSON: ${jsonEncode(json)}');
      }
    }
  } catch (e) {
    print('ERROR: $e');
  }
  
  print('\n');
  print('='*60);
  print('Test 2: BLV /foods search for "kartoffel"');
  print('='*60);
  
  final url2 = Uri.parse('https://api.webapp.prod.blv.foodcase-services.com/BLV_WebApp_WS/webresources/BLV-api/foods')
      .replace(queryParameters: {
        'search': 'kartoffel',
        'limit': '10',
        'lang': 'en',
      });
  
  print('URL: $url2\n');
  
  try {
    final response = await http.get(url2).timeout(const Duration(seconds: 15));
    print('Status: ${response.statusCode}');
    print('Body length: ${response.body.length}');
    if (response.body.length > 100) {
      print('Body (first 500 chars):');
      print(response.body.substring(0, (response.body.length > 500 ? 500 : response.body.length)));
    } else {
      print('Body: ${response.body}');
    }
    
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      print('Type: ${json.runtimeType}');
      if (json is List) {
        print('List length: ${json.length}');
      }
    }
  } catch (e) {
    print('ERROR: $e');
  }
  
  print('\n');
  print('='*60);
  print('Test 3: Check if food ID 123 has nutrients');
  print('='*60);
  
  final url3 = Uri.parse('https://api.webapp.prod.blv.foodcase-services.com/BLV_WebApp_WS/webresources/BLV-api/food/123')
      .replace(queryParameters: {
        'lang': 'en',
      });
  
  print('URL: $url3\n');
  
  try {
    final response = await http.get(url3).timeout(const Duration(seconds: 15));
    print('Status: ${response.statusCode}');
    if (response.statusCode == 200) {
      print('Body (first 800 chars):');
      print(response.body.substring(0, (response.body.length > 800 ? 800 : response.body.length)));
    } else {
      print('Body: ${response.body}');
    }
  } catch (e) {
    print('ERROR: $e');
  }
}
