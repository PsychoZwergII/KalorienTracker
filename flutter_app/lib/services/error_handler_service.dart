import 'package:flutter/material.dart';
import './logger_service.dart';

/// Service für zentralisierte Fehlerbehandlung, Retry-Logik und User-freundliche Messages
class ErrorHandlerService {
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(milliseconds: 500);
  static const Duration _backoffMultiplier = Duration(milliseconds: 500);

  /// Retry-Logic mit exponential backoff
  /// Beispiel: retry(() => apiCall(), maxRetries: 3)
  static Future<T> retry<T>(
    Future<T> Function() operation, {
    int maxRetries = _maxRetries,
    Duration initialDelay = _retryDelay,
    String? operationName,
  }) async {
    int attempt = 0;
    Duration delay = initialDelay;

    while (true) {
      try {
        attempt++;
        if (operationName != null) {
          LoggerService.debug('📍 $operationName attempt $attempt/$maxRetries');
        }
        return await operation();
      } catch (e) {
        attempt++;
        if (attempt > maxRetries) {
          LoggerService.error(
            'Failed after $maxRetries attempts: $e',
            operationName != null ? '$operationName: $e' : null,
          );
          rethrow;
        }

        LoggerService.warning(
          'Retry $attempt/$maxRetries after ${delay.inMilliseconds}ms: $e',
        );
        await Future.delayed(delay);
        delay *= 2; // Exponential backoff
      }
    }
  }

  /// Convert exception to user-friendly message
  static String getErrorMessage(dynamic error, {String? context}) {
    String userMessage = 'Ein Fehler ist aufgetreten';

    if (error is FirebaseException) {
      userMessage = _getFirebaseErrorMessage(error);
    } else if (error is NetworkException) {
      userMessage = 'Netzwerkfehler - bitte Internetverbindung prüfen';
    } else if (error is TimeoutException) {
      userMessage = 'Anfrage hat zu lange gedauert - bitte erneut versuchen';
    } else if (error is ArgumentError) {
      userMessage = error.message ?? 'Ungültige Eingabe';
    } else if (error is FormatException) {
      userMessage = 'Datenformat-Fehler';
    } else if (error is RangeError) {
      userMessage = 'Wert ist außerhalb des zulässigen Bereichs';
    } else if (error is UnsupportedError) {
      userMessage = 'Diese Funktion wird nicht unterstützt';
    } else if (error is StateError) {
      userMessage = 'Ungültiger App-Status - bitte neu starten';
    }

    if (context != null) {
      LoggerService.error(
        'Error in $context: $error',
        'User message: $userMessage',
      );
    }

    return userMessage;
  }

  /// Firebase spezifische Fehler Behandlung
  static String _getFirebaseErrorMessage(FirebaseException error) {
    switch (error.code) {
      case 'user-not-found':
        return 'Benutzer nicht gefunden';
      case 'wrong-password':
        return 'Passwort ist falsch';
      case 'email-already-in-use':
        return 'E-Mail wird bereits verwendet';
      case 'invalid-email':
        return 'E-Mail-Format ist ungültig';
      case 'weak-password':
        return 'Passwort ist zu schwach (min. 6 Zeichen)';
      case 'operation-not-allowed':
        return 'Diese Authentifizierungsmethode ist nicht aktiviert';
      case 'too-many-requests':
        return 'Zu viele Versuche - bitte später erneut versuchen';
      case 'network-request-failed':
        return 'Netzwerkfehler - bitte Internetverbindung prüfen';
      case 'permission-denied':
        return 'Zugriff verweigert';
      case 'unavailable':
        return 'Service ist aktuell nicht verfügbar - bitte später versuchen';
      default:
        return 'Firebase Fehler: ${error.code}';
    }
  }

  /// Show error SnackBar with retry option
  static void showErrorSnackBar(
    BuildContext context,
    dynamic error, {
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onRetry,
    String? context_,
  }) {
    final message = getErrorMessage(error, context: context_);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        backgroundColor: Colors.red[700],
        action: onRetry != null
            ? SnackBarAction(
                label: 'Erneut versuchen',
                textColor: Colors.white,
                onPressed: onRetry,
              )
            : null,
      ),
    );
  }

  /// Show error dialog
  static Future<void> showErrorDialog(
    BuildContext context,
    dynamic error, {
    String title = '❌ Fehler',
    String? context_,
  }) async {
    final message = getErrorMessage(error, context: context_);

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Timeout wrapper for async operations
  static Future<T> withTimeout<T>(
    Future<T> Function() operation,
    Duration timeout, {
    String? operationName,
  }) {
    return operation().timeout(
      timeout,
      onTimeout: () {
        LoggerService.error(
          'Timeout after ${timeout.inSeconds}s: $operationName',
        );
        throw TimeoutException('Operation timed out after ${timeout.inSeconds}s');
      },
    );
  }
}

/// Custom exception types
class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);

  @override
  String toString() => message;
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);

  @override
  String toString() => message;
}

class FirebaseException implements Exception {
  final String code;
  final String? message;

  FirebaseException(this.code, this.message);

  @override
  String toString() => 'FirebaseException($code): $message';
}
