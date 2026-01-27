import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/nutrients.dart';

class CloudFunctionService {
  // Firebase Cloud Function URLs (nach Deployment)
  static const String _cloudFunctionUrl =
      'https://europe-west1-kalorientracker.cloudfunctions.net';

  /// Analyze food image using Gemini API (via Cloud Function)
  Future<Nutrients?> analyzeFoodImage(
    String imageBase64,
    String idToken,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_cloudFunctionUrl/analyzeFood'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({
          'image': imageBase64,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Nutrients.fromJson(data['nutrients']);
      } else {
        print('Analyze Food Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Cloud Function Error: $e');
      return null;
    }
  }

  /// Get barcode data from OpenFoodFacts (via Cloud Function)
  Future<Nutrients?> getBarcodeData(
    String barcode,
    String idToken,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_cloudFunctionUrl/getBarcodeData'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({
          'barcode': barcode,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Nutrients.fromJson(data['nutrients']);
      } else {
        print('Get Barcode Data Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Cloud Function Error: $e');
      return null;
    }
  }
}
