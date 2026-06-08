import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/theme_provider.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/home_screen.dart';
import 'services/logger_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set log level to warning in release builds
  assert(() {
    LoggerService.setMinLevel(LogLevel.debug);
    return true;
  }());
  
  try {
    // Robust Firebase initialization with fallback logic
    FirebaseApp? app;
    
    try {
      // Try to get existing app first
      app = Firebase.app();
      LoggerService.info('Firebase already initialized (existing app)');
    } catch (e) {
      try {
        app = await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        LoggerService.info('Firebase initialized successfully');
      } catch (initError) {
        if (initError.toString().contains('duplicate-app')) {
          app = Firebase.app();
          LoggerService.info('Firebase already initialized (duplicate caught)');
        } else {
          rethrow;
        }
      }
    }
    
    runApp(
      ChangeNotifierProvider(
        create: (_) => ThemeProvider(),
        child: const MyApp(),
      ),
    );
  } catch (e, stackTrace) {
    LoggerService.critical('Firebase initialization failed', e, stackTrace);
    runApp(ErrorApp(error: e.toString()));
  }
}

// Error Screen wenn Firebase nicht startet
class ErrorApp extends StatelessWidget {
  final String error;
  const ErrorApp({Key? key, required this.error}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.red.shade50,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 100, color: Colors.red),
                SizedBox(height: 24),
                Text(
                  'App Fehler',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                Text(
                  'Firebase konnte nicht initialisiert werden.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 8),
                Text(
                  error,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.red.shade700),
                ),
                SizedBox(height: 24),
                Text(
                  'Bitte überprüfen Sie:\n'
                  '• Internet-Verbindung\n'
                  '• Firebase-Konfiguration\n'
                  '• App-Berechtigungen',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return MaterialApp(
      title: 'KalorienTracker',
      theme: ThemeProvider.lightTheme,
      darkTheme: ThemeProvider.darkTheme,
      themeMode: themeProvider.themeMode,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasData && snapshot.data != null) {
            return HomeScreen(user: snapshot.data!);
          }

          return const LoginScreen();
        },
      ),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/home': (context) {
          final user = FirebaseAuth.instance.currentUser;
          return user != null ? HomeScreen(user: user) : const LoginScreen();
        },
      },
    );
  }
}
