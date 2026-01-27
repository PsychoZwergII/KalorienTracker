import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import '../services/firebase_auth_service.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({Key? key}) : super(key: key);

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuthService _authService = FirebaseAuthService();

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    if (user == null) {
      return const Center(child: Text('Not authenticated'));
    }

    return StreamBuilder(
      stream: _firestoreService.getFavoriteFoods(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final favorites = snapshot.data ?? [];

        if (favorites.isEmpty) {
          return const Center(
            child: Text('No favorite foods yet'),
          );
        }

        return ListView.builder(
          itemCount: favorites.length,
          itemBuilder: (context, index) {
            final food = favorites[index];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: Card(
                child: ListTile(
                  title: Text(food.label),
                  subtitle: Text(
                    '${food.calories.toStringAsFixed(0)} kcal | P: ${food.protein.toStringAsFixed(0)}g | F: ${food.fat.toStringAsFixed(0)}g',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      _firestoreService.deleteFoodItem(user.uid, food.id);
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
