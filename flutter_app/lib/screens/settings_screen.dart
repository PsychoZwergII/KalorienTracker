import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../services/firebase_auth_service.dart';
import '../services/firestore_service.dart';
import '../models/user_profile.dart';
import '../models/weight_log.dart';
import '../providers/theme_provider.dart';
import '../widgets/weight_progress_chart.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FirebaseAuthService _authService = FirebaseAuthService();
  final FirestoreService _firestoreService = FirestoreService();
  
  final _formKey = GlobalKey<FormState>();
  
  // Form controllers
  final _startWeightController = TextEditingController();
  final _currentWeightController = TextEditingController();
  final _targetWeightController = TextEditingController();
  final _heightController = TextEditingController();
  final _ageController = TextEditingController();
  
  Gender? _selectedGender;
  ActivityLevel? _selectedActivityLevel;
  WeightGoal? _selectedWeightGoal;
  
  bool _isLoading = false;
  bool _isSaving = false;
  UserProfile? _currentProfile;

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
    setState(() => _isLoading = true);
    
    try {
      final user = _authService.currentUser;
      if (user == null) return;
      
      final profile = await _firestoreService.getCompleteUserProfile(user.uid);
      
      if (profile != null) {
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
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final user = _authService.currentUser;
      if (user == null) throw Exception('Nicht angemeldet');

      final newCurrentWeight = double.tryParse(_currentWeightController.text);
      final oldCurrentWeight = _currentProfile?.currentWeight;

      final profile = UserProfile(
        userId: user.uid,
        displayName: user.displayName,
        email: user.email,
        startWeight: double.tryParse(_startWeightController.text),
        currentWeight: newCurrentWeight,
        targetWeight: double.tryParse(_targetWeightController.text),
        height: double.tryParse(_heightController.text),
        age: int.tryParse(_ageController.text),
        gender: _selectedGender,
        activityLevel: _selectedActivityLevel,
        weightGoal: _selectedWeightGoal,
        createdAt: _currentProfile?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestoreService.saveCompleteUserProfile(profile);

      // Erstelle Weight-Log Checkpoint wenn Gewicht geändert wurde
      if (newCurrentWeight != null && newCurrentWeight != oldCurrentWeight) {
        final weightLog = WeightLog(
          logId: const Uuid().v4(),
          userId: user.uid,
          weight: newCurrentWeight,
          timestamp: DateTime.now(),
          note: oldCurrentWeight == null 
              ? 'Startgewicht' 
              : 'Aktualisierung',
        );
        await _firestoreService.addWeightLog(user.uid, weightLog);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Profil erfolgreich gespeichert'),
            backgroundColor: Colors.green,
          ),
        );
        _loadUserProfile();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Fehler beim Speichern: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    if (user == null) {
      return const Center(child: Text('Nicht angemeldet'));
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Gewichts-Chart
        StreamBuilder<List<WeightLog>>(
          stream: _firestoreService.streamWeightLogs(user.uid, limit: 30),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const SizedBox.shrink();
            }
            return WeightProgressChart(
              weightLogs: snapshot.data!,
              userProfile: _currentProfile,
            );
          },
        ),
        
        const SizedBox(height: 16),
        
        // Benutzerprofil Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Benutzerkonto',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(user.displayName ?? 'Nicht gesetzt'),
                  subtitle: const Text('Name'),
                ),
                ListTile(
                  leading: const Icon(Icons.email),
                  title: Text(user.email ?? 'Nicht gesetzt'),
                  subtitle: const Text('E-Mail'),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Dark Mode Toggle
        Card(
          child: SwitchListTile(
            secondary: Icon(
              themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
            ),
            title: const Text('Dark Mode'),
            subtitle: Text(
              themeProvider.isDarkMode ? 'Aktiviert' : 'Deaktiviert',
            ),
            value: themeProvider.isDarkMode,
            onChanged: (value) {
              themeProvider.toggleTheme();
            },
          ),
        ),

        const SizedBox(height: 16),

        // Körperdaten Form
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
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

        const SizedBox(height: 16),

        // App Info
        Card(
          child: ListTile(
            leading: const Icon(Icons.info),
            title: const Text('App Version'),
            subtitle: const Text('1.0.0'),
          ),
        ),

        const SizedBox(height: 16),

        // Logout Button
        ElevatedButton.icon(
          onPressed: () async {
            await _authService.signOut();
            if (mounted) {
              Navigator.of(context).pushReplacementNamed('/login');
            }
          },
          icon: const Icon(Icons.logout),
          label: const Text('Abmelden'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ],
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
