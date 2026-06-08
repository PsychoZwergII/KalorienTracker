import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/nutrients.dart';
import 'logger_service.dart';
import 'validation_service.dart';

class CloudFunctionService {
  // Cloud Function URLs per region
  static const String _cloudFunctionUrlEurope =
      'https://europe-west1-kalorientracker-3390e.cloudfunctions.net';
  static const String _cloudFunctionUrlUS =
      'https://us-central1-kalorientracker-3390e.cloudfunctions.net';

  // Request timeout
  static const Duration _timeout = Duration(seconds: 30);

  /// Analyze food image using Gemini API (via Cloud Function)
  /// imageBase64: Base64 encoded image (JPEG/PNG)
  /// idToken: Firebase ID token for authentication
  Future<Nutrients?> analyzeFoodImage(
    String imageBase64,
    String idToken,
  ) async {
    try {
      // Validate image size
      if (imageBase64.isEmpty) {
        LoggerService.warning('Attempted to analyze empty image');
        return null;
      }

      // Warn if image is too large (> 5MB in base64)
      if (imageBase64.length > 6000000) {
        LoggerService.warning('Image size too large: ${imageBase64.length} bytes');
        return null;
      }

      final response = await http
          .post(
            Uri.parse('$_cloudFunctionUrlEurope/analyzeFood'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $idToken',
            },
            body: jsonEncode({
              'imageBase64': imageBase64, // FIX: was 'image', API expects 'imageBase64'
            }),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);

          // FIX: API returns root-level object, not nested under 'nutrients'
          final nutrients = Nutrients.fromJson(data);

          // Validate results
          final error = ValidationService.validateNutrients(
            calories: nutrients.calories,
            protein: nutrients.protein,
            fat: nutrients.fat,
            carbs: nutrients.carbs,
            fiber: nutrients.fiber,
          );

          if (error != null) {
            LoggerService.warning('Nutrient validation failed: $error');
            // Sanitize instead of rejecting
            final sanitized = ValidationService.sanitizeNutrients(
              calories: nutrients.calories,
              protein: nutrients.protein,
              fat: nutrients.fat,
              carbs: nutrients.carbs,
              fiber: nutrients.fiber,
            );
            return Nutrients(
              label: nutrients.label,
              calories: sanitized.calories,
              protein: sanitized.protein,
              fat: sanitized.fat,
              carbs: sanitized.carbs,
              fiber: sanitized.fiber,
            );
          }

          LoggerService.info('Analyzed food: ${nutrients.label}');
          return nutrients;
        } catch (e, st) {
          LoggerService.error('Failed to parse nutrition response', e, st);
          return null;
        }
      } else if (response.statusCode == 401) {
        LoggerService.error('Unauthorized: Invalid or expired token');
        return null;
      } else if (response.statusCode == 429) {
        final resetTime = response.headers['x-ratelimit-reset'];
        LoggerService.error('Rate limit exceeded. Reset at: $resetTime');
        return null;
      } else if (response.statusCode == 400) {
        LoggerService.error('Bad request: ${response.body}');
        return null;
      } else {
        LoggerService.error('Analyze Food Error: ${response.statusCode}');
        return null;
      }
    } on TimeoutException catch (_) {
      LoggerService.warning('Image analysis request timed out after ${_timeout.inSeconds}s');
      return null;
    } catch (e, st) {
      LoggerService.error('Cloud Function Error (analyzeFoodImage)', e, st);
      return null;
    }
  }

  /// Get barcode data from OpenFoodFacts (via Cloud Function)
  /// barcode: EAN/UPC barcode string
  /// idToken: Firebase ID token for authentication
  Future<Nutrients?> getBarcodeData(
    String barcode,
    String idToken,
  ) async {
    try {
      // Validate barcode
      final barcodeError = ValidationService.validateBarcode(barcode);
      if (barcodeError != null) {
        LoggerService.warning('Invalid barcode: $barcodeError');
        return null;
      }

      final response = await http
          .post(
            Uri.parse('$_cloudFunctionUrlEurope/getBarcodeData'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $idToken',
            },
            body: jsonEncode({
              'barcode': barcode,
            }),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);

          // FIX: API returns root-level object, not nested under 'nutrients'
          final nutrients = Nutrients.fromJson(data);

          // Validate results
          final error = ValidationService.validateNutrients(
            calories: nutrients.calories,
            protein: nutrients.protein,
            fat: nutrients.fat,
            carbs: nutrients.carbs,
            fiber: nutrients.fiber,
          );

          if (error != null) {
            LoggerService.warning('Nutrient validation failed: $error');
            // Sanitize instead of rejecting
            final sanitized = ValidationService.sanitizeNutrients(
              calories: nutrients.calories,
              protein: nutrients.protein,
              fat: nutrients.fat,
              carbs: nutrients.carbs,
              fiber: nutrients.fiber,
            );
            return Nutrients(
              label: nutrients.label,
              calories: sanitized.calories,
              protein: sanitized.protein,
              fat: sanitized.fat,
              carbs: sanitized.carbs,
              fiber: sanitized.fiber,
            );
          }

          LoggerService.info('Scanned barcode: $barcode -> ${nutrients.label}');
          return nutrients;
        } catch (e, st) {
          LoggerService.error('Failed to parse barcode response', e, st);
          return null;
        }
      } else if (response.statusCode == 404) {
        LoggerService.info('Product not found for barcode: $barcode');
        return null;
      } else if (response.statusCode == 401) {
        LoggerService.error('Unauthorized: Invalid or expired token');
        return null;
      } else if (response.statusCode == 429) {
        final resetTime = response.headers['x-ratelimit-reset'];
        LoggerService.error('Rate limit exceeded. Reset at: $resetTime');
        return null;
      } else {
        LoggerService.error('Get Barcode Data Error: ${response.statusCode}');
        return null;
      }
    } on TimeoutException catch (_) {
      LoggerService.warning('Barcode lookup timed out after ${_timeout.inSeconds}s');
      return null;
    } catch (e, st) {
      LoggerService.error('Cloud Function Error (getBarcodeData)', e, st);
      return null;
    }
  }
}
