import 'dart:async';
import 'package:flutter/material.dart';
import '../models/food_item.dart';
import '../services/firebase_auth_service.dart';
import '../services/firestore_service.dart';
import '../services/openfoodfacts_service.dart';

class ManualFoodEntryScreen extends StatefulWidget {
  final String mealType;

  const ManualFoodEntryScreen({Key? key, required this.mealType})
      : super(key: key);

  @override
  State<ManualFoodEntryScreen> createState() => _ManualFoodEntryScreenState();
}

class _ManualFoodEntryScreenState extends State<ManualFoodEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _fatController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fiberController = TextEditingController();

  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  final _searchFieldKey = GlobalKey();
  final _searchFieldLink = LayerLink();

  final _authService = FirebaseAuthService();
  final _firestoreService = FirestoreService();
  final _openFoodFactsService = OpenFoodFactsService();

  Timer? _debounce;
  OverlayEntry? _overlayEntry;

  bool _isSaving = false;
  bool _isSearching = false;
  bool _showSearchResults = false;
  List<FoodItem> _searchResults = [];
  String _currentSource = 'manual';
  FoodItem? _selectedProduct;

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(_handleSearchFocusChange);
    _searchController.addListener(_handleSearchTextChange);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _removeOverlay();
    _searchFocusNode.removeListener(_handleSearchFocusChange);
    _searchFocusNode.dispose();
    _searchController.removeListener(_handleSearchTextChange);
    _nameController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _fatController.dispose();
    _carbsController.dispose();
    _fiberController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _handleSearchFocusChange() {
    if (!_searchFocusNode.hasFocus) {
      _showSearchResults = false;
    } else if (_searchController.text.trim().length >= 2) {
      _showSearchResults = true;
    }
    setState(() {});
  }

  void _handleSearchTextChange() {
    if (mounted) setState(() {});
  }

  Future<void> _saveFood() async {
    if (_selectedProduct == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bitte ein Suchergebnis auswählen.')),
        );
      }
      return;
    }

    final user = _authService.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bitte zuerst anmelden.')),
        );
      }
      return;
    }

    setState(() => _isSaving = true);

    try {
      final selected = _selectedProduct!;
      final foodItem = FoodItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        barcode: selected.barcode ?? _inferBarcode(selected),
        label: selected.label,
        calories: selected.calories,
        protein: selected.protein,
        fat: selected.fat,
        carbs: selected.carbs,
        fiber: selected.fiber,
        timestamp: DateTime.now(),
        source: selected.source,
        mealType: widget.mealType,
      );

      await _firestoreService.addFoodItem(user.uid, foodItem);

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Lebensmittel gespeichert'), duration: Duration(seconds: 1)),
      );
      
      // Navigate back after short delay to show snackbar
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Fehler: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _onSearchChanged(String value) {
    final query = value.trim();
    _debounce?.cancel();

    if (query.length < 2) {
      _clearSearchResults();
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 400), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    if (!mounted) return;
    setState(() => _isSearching = true);

    try {
      print('🔍 Manual Food Search started for: "$query"');
      
      final results = await _openFoodFactsService.searchProducts(query);
      if (!mounted) return;

      print('✅ Search returned ${results.length} results');
      
      setState(() {
        _searchResults = results;
        _showSearchResults = true;
      });
    } catch (e) {
      print('❌ Search error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Suche fehlgeschlagen: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _clearSearchResults() {
    setState(() {
      _searchResults = [];
      _showSearchResults = false;
    });
  }

  void _selectProduct(FoodItem item) {
    _selectedProduct = item;
    _currentSource = 'openfoodfacts';
    _nameController.text = item.label;
    _caloriesController.text = _formatNumber(item.calories);
    _proteinController.text = _formatNumber(item.protein);
    _fatController.text = _formatNumber(item.fat);
    _carbsController.text = _formatNumber(item.carbs);
    _fiberController.text = _formatNumber(item.fiber);
    _searchController.text = item.label;
    _searchFocusNode.unfocus();
    _clearSearchResults();
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1);
  }

  double _parseNumber(String value) {
    return double.parse(value.replaceAll(',', '.'));
  }

  String? _inferBarcode(FoodItem? item) {
    if (item == null) return null;
    final candidate = item.id;
    if (RegExp(r'^\d{8,14}$').hasMatch(candidate)) {
      return candidate;
    }
    return null;
  }

  void _showOverlay() {
    if (!_showSearchResults || !_searchFocusNode.hasFocus) return;
    if (_overlayEntry == null) {
      _overlayEntry = _createOverlayEntry();
      Overlay.of(context).insert(_overlayEntry!);
    } else {
      _overlayEntry!.markNeedsBuild();
    }
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _createOverlayEntry() {
    final renderBox =
        _searchFieldKey.currentContext?.findRenderObject() as RenderBox?;
    final size = renderBox?.size ?? Size.zero;

    return OverlayEntry(
      builder: (context) {
        if (!_showSearchResults || !_searchFocusNode.hasFocus) {
          return const SizedBox.shrink();
        }

        return Positioned(
          width: size.width,
          child: CompositedTransformFollower(
            link: _searchFieldLink,
            showWhenUnlinked: false,
            offset: Offset(0, size.height + 6),
            child: Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(8),
              clipBehavior: Clip.antiAlias,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 260),
                child: _buildSearchResults(),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_searchController.text.trim().length < 2) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Tippen Sie mind. 2 Zeichen, um zu suchen.',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('❌ Keine Ergebnisse gefunden'),
            const SizedBox(height: 8),
            Text(
              'Versuchen Sie einen anderen Suchbegriff',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: _searchResults.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = _searchResults[index];
        return ListTile(
          title: Text(item.label),
          subtitle: Text(
            '${_formatNumber(item.calories)} kcal • '
            'P ${_formatNumber(item.protein)} g • '
            'F ${_formatNumber(item.fat)} g • '
            'KH ${_formatNumber(item.carbs)} g',
          ),
          onTap: () => _selectProduct(item),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manuell hinzufügen')),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CompositedTransformTarget(
                  link: _searchFieldLink,
                  child: TextFormField(
                    key: _searchFieldKey,
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      labelText: 'Produkt suchen (mind. 2 Zeichen)',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _clearSearchResults();
                                setState(() {});
                              },
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  height: 260,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _buildSearchResults(),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveFood,
                    child: Text(_isSaving ? 'Speichern...' : 'Speichern'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _numberField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Bitte eingeben';
        if (double.tryParse(value.replaceAll(',', '.')) == null) {
          return 'Ungültige Zahl';
        }
        return null;
      },
      onChanged: (value) {
        if (value.contains(',')) {
          final cleaned = value.replaceAll(',', '.');
          controller.value = controller.value.copyWith(
            text: cleaned,
            selection: TextSelection.collapsed(offset: cleaned.length),
          );
        }
      },
    );
  }
}
