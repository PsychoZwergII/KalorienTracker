import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_auth_service.dart';
import '../services/firestore_service.dart';
import '../models/user_profile.dart';
import '../models/weight_log.dart';
import 'package:fl_chart/fl_chart.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final FirebaseAuthService _authService = FirebaseAuthService();
  final FirestoreService _firestoreService = FirestoreService();
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _startWeightController = TextEditingController();
  final TextEditingController _currentWeightController = TextEditingController();
  final TextEditingController _targetWeightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();

  // State
  bool _isLoading = true;
  bool _isSaving = false;
  UserProfile? _currentProfile;
  Gender? _selectedGender;
  ActivityLevel? _selectedActivityLevel;
  WeightGoal? _selectedWeightGoal;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _startWeightController.dispose();
    _currentWeightController.dispose();
    _targetWeightController.dispose();
    _heightController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    try {
      setState(() => _isLoading = true);
      final userId = _authService.currentUser?.uid;
      if (userId == null) return;

      final profile = await _firestoreService.getUserProfile(userId);
      
      if (profile != null && mounted) {
        setState(() {
          _currentProfile = profile;
          _startWeightController.text = profile.startWeight?.toString() ?? '';
          _currentWeightController.text = profile.currentWeight?.toString() ?? '';
          _targetWeightController.text = profile.targetWeight?.toString() ?? '';
          _heightController.text = profile.height?.toString() ?? '';
          _ageController.text = profile.age?.toString() ?? '';
          _selectedGender = profile.gender;
          _selectedActivityLevel = profile.activityLevel;
          _selectedWeightGoal = profile.weightGoal;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Laden: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() => _isSaving = true);
      final userId = _authService.currentUser?.uid;
      if (userId == null) return;

      final updatedProfile = UserProfile(
        userId: userId,
        email: _currentProfile?.email ?? _authService.currentUser?.email ?? '',
        startWeight: double.tryParse(_startWeightController.text),
        currentWeight: double.tryParse(_currentWeightController.text),
        targetWeight: double.tryParse(_targetWeightController.text),
        height: double.tryParse(_heightController.text),
        age: int.tryParse(_ageController.text),
        gender: _selectedGender,
        activityLevel: _selectedActivityLevel,
        weightGoal: _selectedWeightGoal,
        createdAt: _currentProfile?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestoreService.saveUserProfile(userId, updatedProfile.toJson());
      
      if (mounted) {
        setState(() => _currentProfile = updatedProfile);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Profil gespeichert'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ziele & Fortschritt'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Gewichtsverlauf Chart
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Gewichtsverlauf',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),
                          StreamBuilder<List<WeightLog>>(
                            stream: _firestoreService.streamWeightLogs(_authService.currentUser?.uid ?? ''),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                return const SizedBox(
                                  height: 200,
                                  child: Center(
                                    child: Text('Noch keine Gewichtseinträge'),
                                  ),
                                );
                              }

                              final logs = snapshot.data!;
                              logs.sort((a, b) => a.timestamp.compareTo(b.timestamp));

                              return SizedBox(
                                height: 200,
                                child: LineChart(
                                  LineChartData(
                                    gridData: const FlGridData(show: true),
                                    titlesData: FlTitlesData(
                                      leftTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: 40,
                                          getTitlesWidget: (value, meta) {
                                            return Text(
                                              value.toStringAsFixed(0),
                                              style: const TextStyle(fontSize: 10),
                                            );
                                          },
                                        ),
                                      ),
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: 30,
                                          getTitlesWidget: (value, meta) {
                                            if (value.toInt() >= logs.length) return const Text('');
                                            final date = logs[value.toInt()].timestamp;
                                            return Padding(
                                              padding: const EdgeInsets.only(top: 8),
                                              child: Text(
                                                '${date.day}.${date.month}',
                                                style: const TextStyle(fontSize: 10),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      rightTitles: const AxisTitles(
                                        sideTitles: SideTitles(showTitles: false),
                                      ),
                                      topTitles: const AxisTitles(
                                        sideTitles: SideTitles(showTitles: false),
                                      ),
                                    ),
                                    borderData: FlBorderData(show: true),
                                    lineBarsData: [
                                      LineChartBarData(
                                        spots: logs.asMap().entries.map((entry) {
                                          return FlSpot(
                                            entry.key.toDouble(),
                                            entry.value.weight,
                                          );
                                        }).toList(),
                                        isCurved: true,
                                        color: Colors.blue,
                                        barWidth: 3,
                                        dotData: const FlDotData(show: true),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Körperdaten Formular
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Körperdaten & Ziele',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 16),
                            
                            // Gewichtsdaten
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _startWeightController,
                                    decoration: const InputDecoration(
                                      labelText: 'Startgewicht (kg)',
                                      prefixIcon: Icon(Icons.flag),
                                    ),
                                    keyboardType: TextInputType.number,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Bitte eingeben';
                                      }
                                      if (double.tryParse(value) == null) {
                                        return 'Ungültige Zahl';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextFormField(
                                    controller: _currentWeightController,
                                    decoration: const InputDecoration(
                                      labelText: 'Aktuell (kg)',
                                      prefixIcon: Icon(Icons.monitor_weight),
                                    ),
                                    keyboardType: TextInputType.number,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Bitte eingeben';
                                      }
                                      if (double.tryParse(value) == null) {
                                        return 'Ungültige Zahl';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 12),
                            
                            TextFormField(
                              controller: _targetWeightController,
                              decoration: const InputDecoration(
                                labelText: 'Zielgewicht (kg)',
                                prefixIcon: Icon(Icons.track_changes),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Bitte eingeben';
                                }
                                if (double.tryParse(value) == null) {
                                  return 'Ungültige Zahl';
                                }
                                return null;
                              },
                            ),
                            
                            const SizedBox(height: 12),
                            
                            // Körpergröße und Alter
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _heightController,
                                    decoration: const InputDecoration(
                                      labelText: 'Größe (cm)',
                                      prefixIcon: Icon(Icons.height),
                                    ),
                                    keyboardType: TextInputType.number,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Bitte eingeben';
                                      }
                                      if (double.tryParse(value) == null) {
                                        return 'Ungültige Zahl';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextFormField(
                                    controller: _ageController,
                                    decoration: const InputDecoration(
                                      labelText: 'Alter (Jahre)',
                                      prefixIcon: Icon(Icons.cake),
                                    ),
                                    keyboardType: TextInputType.number,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Bitte eingeben';
                                      }
                                      if (int.tryParse(value) == null) {
                                        return 'Ungültige Zahl';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Geschlecht
                            DropdownButtonFormField<Gender>(
                              value: _selectedGender,
                              decoration: const InputDecoration(
                                labelText: 'Geschlecht',
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                              items: Gender.values.map((gender) {
                                return DropdownMenuItem(
                                  value: gender,
                                  child: Text(
                                    gender == Gender.male ? 'Männlich' : 
                                    gender == Gender.female ? 'Weiblich' : 'Divers'
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() => _selectedGender = value);
                              },
                              validator: (value) {
                                if (value == null) {
                                  return 'Bitte auswählen';
                                }
                                return null;
                              },
                            ),
                            
                            const SizedBox(height: 12),
                            
                            // Aktivitätslevel
                            DropdownButtonFormField<ActivityLevel>(
                              value: _selectedActivityLevel,
                              decoration: const InputDecoration(
                                labelText: 'Aktivitätslevel',
                                prefixIcon: Icon(Icons.directions_run),
                              ),
                              items: ActivityLevel.values.map((level) {
                                return DropdownMenuItem(
                                  value: level,
                                  child: Text(level.displayName),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() => _selectedActivityLevel = value);
                              },
                              validator: (value) {
                                if (value == null) {
                                  return 'Bitte auswählen';
                                }
                                return null;
                              },
                            ),
                            
                            const SizedBox(height: 12),
                            
                            // Gewichtsziel
                            DropdownButtonFormField<WeightGoal>(
                              value: _selectedWeightGoal,
                              decoration: const InputDecoration(
                                labelText: 'Ziel',
                                prefixIcon: Icon(Icons.emoji_events),
                              ),
                              items: WeightGoal.values.map((goal) {
                                return DropdownMenuItem(
                                  value: goal,
                                  child: Text(goal.displayName),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() => _selectedWeightGoal = value);
                              },
                              validator: (value) {
                                if (value == null) {
                                  return 'Bitte auswählen';
                                }
                                return null;
                              },
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // Speichern Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _isSaving ? null : _saveProfile,
                                icon: _isSaving
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Icon(Icons.save),
                                label: Text(_isSaving ? 'Speichern...' : 'Profil speichern'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                            
                            // Info Box mit berechneten Werten
                            if (_currentProfile != null) ...[
                              const SizedBox(height: 24),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Berechnungen',
                                      style: Theme.of(context).textTheme.titleMedium,
                                    ),
                                    const SizedBox(height: 12),
                                    if (_currentProfile!.calculateBMR() != null)
                                      _buildInfoRow(
                                        'BMR (Grundumsatz):',
                                        '${_currentProfile!.calculateBMR()!.toStringAsFixed(0)} kcal',
                                      ),
                                    if (_currentProfile!.calculateTDEE() != null)
                                      _buildInfoRow(
                                        'TDEE (Gesamtumsatz):',
                                        '${_currentProfile!.calculateTDEE()!.toStringAsFixed(0)} kcal',
                                      ),
                                    if (_currentProfile!.calculateDailyCalorieGoal() != null)
                                      _buildInfoRow(
                                        'Empfohlene Kalorienzufuhr:',
                                        '${_currentProfile!.calculateDailyCalorieGoal()!.toStringAsFixed(0)} kcal/Tag',
                                      ),
                                    if (_currentProfile!.remainingWeightChange() != null)
                                      _buildInfoRow(
                                        'Verbleibend zum Ziel:',
                                        '${_currentProfile!.remainingWeightChange()!.toStringAsFixed(1)} kg',
                                      ),
                                    if (_currentProfile!.calculateWeightProgress() != null)
                                      _buildInfoRow(
                                        'Fortschritt:',
                                        '${_currentProfile!.calculateWeightProgress()!.toStringAsFixed(0)}%',
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
