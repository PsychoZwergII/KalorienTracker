import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/activity.dart';
import '../models/food_item.dart';
import '../models/user_profile.dart';
import '../models/weight_log.dart';
import '../services/firestore_service.dart';
import '../services/firebase_auth_service.dart';
import '../widgets/add_activity_dialog.dart';
import '../widgets/weight_progress_chart.dart';
import 'meal_add_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  final User user;

  const HomeScreen({
    Key? key,
    required this.user,
  }) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0; // Start auf Coach
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuthService _authService = FirebaseAuthService();
  
  // Kalorienziele und aktuelle Werte
  int _calorieGoal = 2256;
  bool _goalsPersisted = false;
  final Map<String, bool> _expandedMeals = {};
  
  // Cached User Profile
  UserProfile? _cachedProfile;
  bool _profileLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final profile = await _firestoreService.getUserProfile(widget.user.uid);
      if (mounted) {
        setState(() {
          _cachedProfile = profile;
          _profileLoaded = true;
        });
      }
    } catch (e) {
      print('❌ Error loading profile: $e');
      if (mounted) {
        setState(() => _profileLoaded = true);
      }
    }
  }

  void _refreshProfile() {
    _loadUserProfile();
  }


  @override
  Widget build(BuildContext context) {
    final screens = [
      _buildCoachTab(),
      _buildProgressTab(),
      _buildProfileTab(),
    ];
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: const Color(0xFF2C3E50),
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.lightbulb_outline),
            activeIcon: Icon(Icons.lightbulb),
            label: 'Coach',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart),
            activeIcon: Icon(Icons.show_chart),
            label: 'Fortschritt',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  Widget _buildCoachTab() {
    final userId = widget.user.uid;
    final profile = _cachedProfile;
    final calorieGoal = _calculateCalorieGoal(profile);
    final macroGoals = _calculateMacroGoals(calorieGoal);

    if (!_goalsPersisted && profile != null && calorieGoal > 0) {
      _persistGoals(userId, calorieGoal, macroGoals);
    }

    if (!_profileLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    return StreamBuilder<List<FoodItem>>(
      stream: _firestoreService.getTodaysFoods(userId),
      builder: (context, foodSnapshot) {
        final foods = foodSnapshot.data ?? [];
        final foodTotals = _calculateFoodTotals(foods);
        final meals = _buildMealsFromFoods(foods, calorieGoal);

        return StreamBuilder<List<Activity>>(
          stream: _firestoreService.getTodaysActivities(userId),
          builder: (context, activitySnapshot) {
            final activities = activitySnapshot.data ?? [];
            final caloriesBurned = activities.fold<int>(
              0,
              (sum, activity) => sum + activity.caloriesBurned.round(),
            );

                final caloriesConsumed = foodTotals['calories']?.round() ?? 0;
                final caloriesRemaining = calorieGoal - caloriesConsumed + caloriesBurned;

                return CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          // Kalorien-Übersicht Header
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Color(0xFFE8F4F8), Colors.white],
                              ),
                            ),
                            child: Column(
                              children: [
                                if (profile == null)
                                  _buildProfileMissingBanner(),

                                const SizedBox(height: 8),

                                // Hauptanzeige: Kalorien übrig
                                Text(
                                  '$caloriesRemaining',
                                  style: const TextStyle(
                                    fontSize: 64,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2C3E50),
                                    height: 1,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'kcal',
                                  style: TextStyle(
                                    fontSize: 20,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'übrig',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),

                                const SizedBox(height: 30),

                                // Gegessen vs Verbrannt
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Column(
                                      children: [
                                        Text(
                                          '$caloriesConsumed',
                                          style: const TextStyle(
                                            fontSize: 32,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF2C3E50),
                                          ),
                                        ),
                                        const Text(
                                          'Gegessen',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      width: 2,
                                      height: 50,
                                      color: Colors.grey.shade300,
                                    ),
                                    Column(
                                      children: [
                                        Text(
                                          '$caloriesBurned',
                                          style: const TextStyle(
                                            fontSize: 32,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF2C3E50),
                                          ),
                                        ),
                                        const Text(
                                          'Verbrannt',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Makronährstoffe Card
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 20),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Makronährstoffe',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF2C3E50),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  height: 3,
                                  width: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.orange,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildMacroCircle(
                                      'Eiweiß',
                                      foodTotals['protein'] ?? 0,
                                      macroGoals['protein'] ?? 0,
                                      Colors.pink.shade300,
                                    ),
                                    _buildMacroCircle(
                                      'Fett',
                                      foodTotals['fat'] ?? 0,
                                      macroGoals['fat'] ?? 0,
                                      Colors.amber.shade300,
                                    ),
                                    _buildMacroCircle(
                                      'Kohlenh.',
                                      foodTotals['carbs'] ?? 0,
                                      macroGoals['carbs'] ?? 0,
                                      Colors.blue.shade300,
                                    ),
                                    _buildMacroCircle(
                                      'Ballastst.',
                                      foodTotals['fiber'] ?? 0,
                                      macroGoals['fiber'] ?? 0,
                                      Colors.orange.shade300,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),
                        ],
                      ),
                    ),

                    // Mahlzeiten & Aktivitäten
                    SliverToBoxAdapter(
                      child: Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(30),
                            topRight: Radius.circular(30),
                          ),
                        ),
                        child: _buildMealsAndActivities(
                          meals: meals,
                          caloriesBurned: caloriesBurned,
                          userProfile: profile,
                          allFoods: foods,
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildMacroCircle(String name, num current, num goal, Color color) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 70,
              height: 70,
              child: CircularProgressIndicator(
                value: goal > 0 ? (current / goal).clamp(0.0, 1.0) : 0.0,
                strokeWidth: 6,
                backgroundColor: color.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${current.toInt()}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                Text(
                  '/${goal.toInt()}g',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          name,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressTab() {
    final profile = _cachedProfile;
    
    if (!_profileLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    return StreamBuilder<List<WeightLog>>(
      stream: _firestoreService.streamWeightLogs(widget.user.uid, limit: 90),
      builder: (context, weightSnapshot) {
        final logs = weightSnapshot.data ?? [];

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 40, 16, 24),
          children: [
            const Text(
              'Fortschritt',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 16),
            if (profile == null)
              _buildProfileMissingBanner(),
            const SizedBox(height: 16),
            WeightProgressChart(
              weightLogs: logs,
              userProfile: profile,
            ),
          ],
        );
      },
    );
  }

  Widget _buildMealsAndActivities({
    required List<Map<String, dynamic>> meals,
    required int caloriesBurned,
    required UserProfile? userProfile,
    required List<FoodItem> allFoods,
  }) {
    return Column(
      children: [
        // Mahlzeiten
        ...meals.map((meal) {
          final mealFoods = allFoods
              .where((f) => f.mealType == meal['mealType'])
              .toList();
          return _buildMealCard(
            meal['name'],
            meal['icon'],
            meal['mealType'],
            meal['calories'],
            meal['goal'],
            foods: mealFoods,
            userId: widget.user.uid,
          );
        }).toList(),
        
        const SizedBox(height: 16),
        
        // Aktivitäten
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Text('🏆', style: TextStyle(fontSize: 32)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Aktivitäten',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        Text(
                          '$caloriesBurned kcal Verbrannt',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Gehe spazieren oder füge eine Aktivität hinzu, um den Kalorienverbrauch zu messen',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AddActivityDialog(
                        userId: widget.user.uid,
                        userProfile: userProfile,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2C3E50),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Aktivität hinzufügen',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMealCard(
    String name,
    String icon,
    String mealType,
    int calories,
    int goal, {
    required List<FoodItem> foods,
    required String userId,
  }) {
    return StatefulBuilder(
      builder: (context, setState) {
        final isExpanded = _expandedMeals[mealType] ?? false;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              // Header
              GestureDetector(
                onTap: () {
                  setState(() {
                    _expandedMeals[mealType] = !isExpanded;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            icon,
                            style: const TextStyle(fontSize: 28),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2C3E50),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$calories / $goal kcal',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2C3E50),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.add, color: Colors.white, size: 20),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => MealAddScreen(
                                  mealName: name,
                                  mealType: mealType,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: Colors.grey.shade600,
                      ),
                    ],
                  ),
                ),
              ),
              
              // Expanded content - food items
              if (isExpanded)
                Container(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  child: foods.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Keine Mahlzeiten hinzugefügt',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: foods.length,
                        itemBuilder: (context, index) {
                          final food = foods[index];
                          return Container(
                            decoration: BoxDecoration(
                              border: index < foods.length - 1
                                ? Border(
                                    bottom: BorderSide(
                                      color: Colors.grey.shade200,
                                    ),
                                  )
                                : null,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          food.label,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: Color(0xFF2C3E50),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${food.calories.toStringAsFixed(0)} kcal',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                      size: 20,
                                    ),
                                    onPressed: () async {
                                      await _firestoreService
                                        .deleteFoodItem(userId, food.id);
                                      setState(() {});
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                ),
            ],
          ),
        );
      },
    );
  }

  int _calculateCalorieGoal(UserProfile? profile) {
    final goal = profile?.calculateDailyCalorieGoal();
    if (goal == null || goal.isNaN) return _calorieGoal;
    return goal.round();
  }

  Map<String, double> _calculateMacroGoals(int calorieGoal) {
    if (calorieGoal <= 0) {
      return {
        'protein': 0,
        'fat': 0,
        'carbs': 0,
        'fiber': 0,
      };
    }

    final protein = (calorieGoal * 0.30) / 4; // 30% Protein
    final fat = (calorieGoal * 0.25) / 9; // 25% Fett
    final carbs = (calorieGoal * 0.45) / 4; // 45% Kohlenhydrate
    final fiber = (calorieGoal / 1000.0) * 14; // 14g pro 1000 kcal

    return {
      'protein': protein,
      'fat': fat,
      'carbs': carbs,
      'fiber': fiber,
    };
  }

  Map<String, double> _calculateFoodTotals(List<FoodItem> foods) {
    double calories = 0;
    double protein = 0;
    double fat = 0;
    double carbs = 0;
    double fiber = 0;

    for (final food in foods) {
      calories += food.calories;
      protein += food.protein;
      fat += food.fat;
      carbs += food.carbs;
      fiber += food.fiber;
    }

    return {
      'calories': calories,
      'protein': protein,
      'fat': fat,
      'carbs': carbs,
      'fiber': fiber,
    };
  }

  List<Map<String, dynamic>> _buildMealsFromFoods(List<FoodItem> foods, int calorieGoal) {
    final mealTotals = {
      'breakfast': 0.0,
      'lunch': 0.0,
      'dinner': 0.0,
      'snack': 0.0,
    };

    for (final food in foods) {
      final key = food.mealType ?? 'snack';
      if (mealTotals.containsKey(key)) {
        mealTotals[key] = mealTotals[key]! + food.calories;
      }
    }

    final breakfastGoal = (calorieGoal * 0.30).round();
    final lunchGoal = (calorieGoal * 0.30).round();
    final dinnerGoal = (calorieGoal * 0.30).round();
    final snackGoal = (calorieGoal * 0.10).round();

    return [
      {
        'name': 'Frühstück',
        'icon': '🥐',
        'mealType': 'breakfast',
        'calories': mealTotals['breakfast']!.round(),
        'goal': breakfastGoal,
      },
      {
        'name': 'Mittagessen',
        'icon': '🍽️',
        'mealType': 'lunch',
        'calories': mealTotals['lunch']!.round(),
        'goal': lunchGoal,
      },
      {
        'name': 'Abendessen',
        'icon': '🍱',
        'mealType': 'dinner',
        'calories': mealTotals['dinner']!.round(),
        'goal': dinnerGoal,
      },
      {
        'name': 'Snacks',
        'icon': '🍎',
        'mealType': 'snack',
        'calories': mealTotals['snack']!.round(),
        'goal': snackGoal,
      },
    ];
  }

  Future<void> _persistGoals(
    String userId,
    int calorieGoal,
    Map<String, double> macroGoals,
  ) async {
    if (_goalsPersisted) return;
    _goalsPersisted = true;
    try {
      await _firestoreService.saveUserProfile(userId, {
        'dailyCalorieGoal': calorieGoal,
        'macroGoals': {
          'protein': macroGoals['protein'],
          'fat': macroGoals['fat'],
          'carbs': macroGoals['carbs'],
          'fiber': macroGoals['fiber'],
        },
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (_) {
      _goalsPersisted = false;
    }
  }

  Widget _buildProfileMissingBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber, color: Colors.orange),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Bitte Ziele & Körperdaten einstellen, damit Kalorien berechnet werden.',
              style: TextStyle(fontSize: 12),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
            child: const Text('Jetzt'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTab() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 60,
              backgroundColor: Colors.grey.shade300,
              child: Text(
                (widget.user.displayName ?? 'U')[0].toUpperCase(),
                style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              widget.user.displayName ?? 'User',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.user.email ?? '',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildSettingItem(
                    Icons.settings,
                    'Einstellungen',
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SettingsScreen()),
                      );
                      // Refresh profile after settings
                      _refreshProfile();
                    },
                  ),
                  const Divider(),
                  _buildSettingItem(
                    Icons.track_changes,
                    'Ziele anpassen',
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SettingsScreen()),
                      );
                      // Refresh profile after settings
                      _refreshProfile();
                    },
                  ),
                  const Divider(),
                  _buildSettingItem(Icons.help_outline, 'Hilfe & Support'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await _authService.signOut();
                  if (mounted) {
                    Navigator.of(context).pushReplacementNamed('/login');
                  }
                },
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem(IconData icon, String title, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap ??
          () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$title - Coming Soon!')),
            );
          },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF2C3E50)),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mär', 'Apr', 'Mai', 'Jun', 'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Dez'];
    return '${date.day}. ${months[date.month - 1]} ${date.year}';
  }
}
