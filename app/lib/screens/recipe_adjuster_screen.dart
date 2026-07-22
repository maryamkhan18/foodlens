import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/firebase_service.dart';

class RecipeAdjusterScreen extends StatefulWidget {
  const RecipeAdjusterScreen({super.key});

  @override
  State<RecipeAdjusterScreen> createState() => _RecipeAdjusterScreenState();
}

class _RecipeAdjusterScreenState extends State<RecipeAdjusterScreen>
    with TickerProviderStateMixin {
  int _step = 0;
  bool _loading = false;

  final _searchCtrl = TextEditingController();

  Map<String, dynamic>? _recipe;
  final Map<String, TextEditingController> _qtyControllers = {};

  Map<String, dynamic>? _analysis;
  Map<String, dynamic>? _subSuggestions;
  Map<String, dynamic>? _adjustedRecipe;
  final Map<String, String> _chosenSubs = {};

  // suggestions when recipe not found
  List<String> _suggestions = [];

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

static const String _baseUrl = 'https://foodlens-production-9e4f.up.railway.app';
  static const _bg       = Color(0xFFFDF6EC);
  static const _surface  = Color(0xFFFCEEDD);
  static const _card     = Color(0xFFFFFFFF);
  static const _accent   = Color(0xFFE8734A);
  static const _accentSoft = Color(0x26E8734A);
  static const _green    = Color(0xFF7C9A62);
  static const _yellow   = Color(0xFFE0A458);
  static const _red      = Color(0xFFD9695B);
  static const _textPri  = Color(0xFF3A2E28);
  static const _textSec  = Color(0xFF8C7A6E);
  static const _border   = Color(0xFFEBDDC9);

  // ─── Lifecycle ───────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _searchCtrl.dispose();
    for (final c in _qtyControllers.values) c.dispose();
    _qtyControllers.clear();
    super.dispose();
  }

  void _animate() {
    _fadeCtrl.reset();
    _fadeCtrl.forward();
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  TextEditingController _getController(String name) =>
      _qtyControllers.putIfAbsent(name, () => TextEditingController());

  Map<String, dynamic> _getAvailableIngredients() {
    final Map<String, dynamic> available = {};
    for (final ing in _recipe?['ingredients'] ?? []) {
      final name = ing['name'];
      final ctrl = _qtyControllers[name];
      final val  = double.tryParse(ctrl?.text.trim() ?? '');
      if (val != null && val > 0) available[name] = val;
    }
    return available;
  }

  void _snack(String msg, {Color color = _accent}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: _textPri)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  // ─── API Calls ───────────────────────────────────────────────────────────

  Future<void> _searchRecipe() async {
    final q = _searchCtrl.text.trim();
    if (q.isEmpty) return;

    setState(() { _loading = true; _suggestions = []; });

    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/recipe-search'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'query': q}),
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode != 200) throw Exception("Server error ${res.statusCode}");

      final data = jsonDecode(res.body);

      if (data['found'] == true) {
        final recipe = Map<String, dynamic>.from(data['recipe']);
        _qtyControllers.clear();
        for (final ing in recipe['ingredients']) {
          _qtyControllers[ing['name']] = TextEditingController();
        }
        setState(() { _recipe = recipe; _step = 1; _loading = false; });
        _animate();
      } else {
        final sugg = List<String>.from(data['suggestions'] ?? []);
        setState(() { _suggestions = sugg; _loading = false; });
        _snack('Recipe not found. Try suggestions below.', color: _yellow);
      }
    } catch (e) {
      setState(() => _loading = false);
      _snack('Connection error. Is Flask running?', color: _red);
    }
  }

  Future<void> _analyzeIngredients() async {
    if (_recipe == null) return;

    final available = _getAvailableIngredients();
    if (available.isEmpty) {
      _snack('Enter at least one ingredient quantity!', color: _yellow);
      return;
    }

    setState(() => _loading = true);

    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/recipe-adjust'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'recipe_name': _recipe!['name'],
          'available': available,
          'substitutions': {},
        }),
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode != 200) throw Exception("Server error ${res.statusCode}");

      final data = jsonDecode(res.body);
      final subs = (data['sub_suggestions'] as Map?) ?? {};

      _chosenSubs.clear();
      subs.forEach((key, value) {
        if (value is List && value.isNotEmpty) {
          final first = value.first;
          if (first is Map && first['sub'] != null) {
            _chosenSubs[key] = first['sub'] as String;
          }
        }
      });

      setState(() {
        _analysis       = Map<String, dynamic>.from(data['analysis'] ?? {});
        _subSuggestions = Map<String, dynamic>.from(subs);
        _adjustedRecipe = Map<String, dynamic>.from(data['adjusted_recipe'] ?? {});
        _step           = 2;
        _loading        = false;
      });
      _animate();

      // Firebase save — fire and forget, don't block UI
      FirebaseService.saveRecipeAdjustment({
        'recipe_name'    : _recipe!['name'],
        'recipe_category': _recipe!['category'] ?? 'Unknown',
        'available'      : available,
      }).catchError((_) {});

    } catch (e) {
      setState(() => _loading = false);
      _snack('Analysis failed: ${e.toString()}', color: _red);
    }
  }

  Future<void> _applySubstitutes() async {
    if (_recipe == null) return;
    setState(() => _loading = true);

    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/recipe-adjust'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'recipe_name'  : _recipe!['name'],
          'available'    : _getAvailableIngredients(),
          'substitutions': _chosenSubs,
        }),
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode != 200) throw Exception("Server error");

      final data = jsonDecode(res.body);
      setState(() {
        _adjustedRecipe = Map<String, dynamic>.from(data['adjusted_recipe'] ?? {});
        _loading        = false;
      });
      _snack('Substitutes applied!', color: _green);
    } catch (e) {
      setState(() => _loading = false);
      _snack('Failed to apply substitutes.', color: _red);
    }
  }

  void _goBack() {
    setState(() {
      if (_step == 2) {
        _step = 1;
      } else if (_step == 1) {
        _step = 0;
        _recipe = null;
        _suggestions = [];
        for (final c in _qtyControllers.values) c.dispose();
        _qtyControllers.clear();
      }
    });
    _animate();
  }

  void _reset() {
    setState(() {
      _step           = 0;
      _recipe         = null;
      _analysis       = null;
      _subSuggestions = null;
      _adjustedRecipe = null;
      _suggestions    = [];
      _chosenSubs.clear();
      _searchCtrl.clear();
      for (final c in _qtyControllers.values) c.dispose();
      _qtyControllers.clear();
    });
    _animate();
  }

  // ─── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        foregroundColor: _textPri,
        elevation: 0,
        leading: _step > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                onPressed: _goBack,
              )
            : null,
        title: Text(
          _step == 0
              ? 'Recipe Adjuster'
              : _step == 1
                  ? (_recipe?['name'] ?? 'Ingredients')
                  : 'Adjusted Recipe',
          style: const TextStyle(
            color: _textPri,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        actions: [
          if (_step > 0)
            IconButton(
              icon: const Icon(Icons.refresh, color: _textSec),
              tooltip: 'Start over',
              onPressed: _reset,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _accent))
          : FadeTransition(
              opacity: _fadeAnim,
              child: _step == 0
                  ? _buildSearch()
                  : _step == 1
                      ? _buildIngredientInput()
                      : _buildResults(),
            ),
    );
  }

  // ─── Step 0 : Search ─────────────────────────────────────────────────────

  Widget _buildSearch() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          // Header
          const Text('What do you want to cook?',
              style: TextStyle(color: _textPri, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Search from 400+ recipes',
              style: TextStyle(color: _textSec, fontSize: 14)),
          const SizedBox(height: 24),

          // Search field
          Container(
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _border),
            ),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(color: _textPri),
              decoration: const InputDecoration(
                hintText: 'e.g. biryani, pasta, halwa...',
                hintStyle: TextStyle(color: _textSec),
                prefixIcon: Icon(Icons.search, color: _textSec),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              ),
              onSubmitted: (_) => _searchRecipe(),
              textInputAction: TextInputAction.search,
            ),
          ),
          const SizedBox(height: 14),

          // Search button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _searchRecipe,
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Search Recipe', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),

          // Suggestions when not found
          if (_suggestions.isNotEmpty) ...[
            const SizedBox(height: 28),
            const Text('Did you mean?',
                style: TextStyle(color: _textSec, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _suggestions.map((s) => GestureDetector(
                onTap: () {
                  _searchCtrl.text = s;
                  _searchRecipe();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: _card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _border),
                  ),
                  child: Text(s, style: const TextStyle(color: _textPri, fontSize: 13)),
                ),
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Step 1 : Ingredient Input ────────────────────────────────────────────

  Widget _buildIngredientInput() {
    if (_recipe == null) return const SizedBox();

    final ingredients = List<Map<String, dynamic>>.from(_recipe!['ingredients']);
    final category    = _recipe!['category'] ?? '';

    return Column(
      children: [
        // Recipe info banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: _surface,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _accentSoft,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(category,
                    style: const TextStyle(color: _accent, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 10),
              Text('${_recipe!['servings']} servings',
                  style: const TextStyle(color: _textSec, fontSize: 13)),
              const Spacer(),
              const Icon(Icons.info_outline, color: _textSec, size: 16),
              const SizedBox(width: 4),
              const Text('Enter qty you have',
                  style: TextStyle(color: _textSec, fontSize: 12)),
            ],
          ),
        ),

        // Ingredient list
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            itemCount: ingredients.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final ing  = ingredients[i];
              final name = ing['name'] as String;
              final ctrl = _getController(name);

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _border),
                ),
                child: Row(
                  children: [
                    // Ingredient name
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name,
                              style: const TextStyle(
                                  color: _textPri, fontWeight: FontWeight.w500, fontSize: 15)),
                          const SizedBox(height: 3),
                          Text('Need: ${ing['qty']} ${ing['unit']}',
                              style: const TextStyle(color: _textSec, fontSize: 12)),
                        ],
                      ),
                    ),
                    // Quantity input
                    SizedBox(
                      width: 80,
                      child: TextField(
                        controller: ctrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(color: _textPri, fontSize: 14),
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          hintText: ing['unit'],
                          hintStyle: const TextStyle(color: _textSec, fontSize: 12),
                          filled: true,
                          fillColor: _surface,
                          contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: _border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: _border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: _accent),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        // Analyze button pinned at bottom
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          decoration: const BoxDecoration(
            color: _bg,
            border: Border(top: BorderSide(color: _border)),
          ),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _analyzeIngredients,
              icon: const Icon(Icons.auto_fix_high, size: 18),
              label: const Text('Analyze & Adjust Recipe',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Step 2 : Results ────────────────────────────────────────────────────

  Widget _buildResults() {
    if (_analysis == null || _adjustedRecipe == null) {
      return const Center(child: Text('No data', style: TextStyle(color: _textSec)));
    }

    final missing  = List.from(_analysis!['missing']  ?? []);
    final lowQty   = List.from(_analysis!['low_qty']   ?? []);
    final scale    = (_analysis!['scale_factor'] as num?)?.toDouble() ?? 1.0;
    final adjIngs  = List.from(_adjustedRecipe!['ingredients'] ?? []);
    final steps    = List<String>.from(_adjustedRecipe!['steps'] ?? []);
    final servings = _adjustedRecipe!['servings'];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
      children: [

        // ── Scale Summary Card ──
        _sectionCard(
          child: Row(
            children: [
              _scalePill(scale),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${(scale * 100).round()}% of full recipe',
                        style: const TextStyle(color: _textPri, fontWeight: FontWeight.bold, fontSize: 15)),
                    Text('≈ $servings servings',
                        style: const TextStyle(color: _textSec, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── Missing Ingredients ──
        if (missing.isNotEmpty) ...[
          _label('Missing Ingredients', icon: Icons.cancel_outlined, color: _red),
          const SizedBox(height: 8),
          ...missing.map((ing) {
            final name = ing['name'] as String;
            final subs = (_subSuggestions?[name] as List?) ?? [];
            return _missingIngCard(name, ing, subs);
          }),
          const SizedBox(height: 12),
        ],

        // ── Low Quantity ──
        if (lowQty.isNotEmpty) ...[
          _label('Low Quantity', icon: Icons.warning_amber_outlined, color: _yellow),
          const SizedBox(height: 8),
          ...lowQty.map((ing) => _lowQtyCard(ing)),
          const SizedBox(height: 12),
        ],

        // ── Adjusted Ingredients ──
        _label('Adjusted Ingredients', icon: Icons.check_circle_outline, color: _green),
        const SizedBox(height: 8),
        _sectionCard(
          child: Column(
            children: adjIngs.asMap().entries.map((e) {
              final i   = e.key;
              final ing = e.value as Map;
              final substituted = ing['substituted'];
              return Column(
                children: [
                  if (i > 0) const Divider(color: _border, height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        const Icon(Icons.circle, size: 6, color: _accent),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(ing['name'],
                                  style: const TextStyle(color: _textPri, fontWeight: FontWeight.w500)),
                              if (substituted != null)
                                Text('→ $substituted',
                                    style: const TextStyle(color: _accent, fontSize: 12)),
                            ],
                          ),
                        ),
                        Text('${ing['qty']} ${ing['unit']}',
                            style: const TextStyle(color: _green, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),

        // ── Steps ──
        if (steps.isNotEmpty) ...[
          _label('Steps', icon: Icons.format_list_numbered, color: _textSec),
          const SizedBox(height: 8),
          _sectionCard(
            child: Column(
              children: steps.asMap().entries.map((e) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 24, height: 24,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(color: _accentSoft, shape: BoxShape.circle),
                        child: Text('${e.key + 1}',
                            style: const TextStyle(color: _accent, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(e.value,
                            style: const TextStyle(color: _textPri, fontSize: 14, height: 1.4)),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // ── Apply Substitutes button (only if there are subs to choose) ──
        if (_subSuggestions != null && _subSuggestions!.isNotEmpty)
          ElevatedButton.icon(
            onPressed: _applySubstitutes,
            icon: const Icon(Icons.swap_horiz, size: 18),
            label: const Text('Apply Selected Substitutes',
                style: TextStyle(fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _green,
              foregroundColor: Colors.black87,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
      ],
    );
  }

  // ─── Reusable Widgets ────────────────────────────────────────────────────

  Widget _sectionCard({required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _border),
        ),
        child: child,
      );

  Widget _label(String text, {required IconData icon, required Color color}) => Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(text,
              style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13)),
        ],
      );

  Widget _scalePill(double scale) {
    final color = scale >= 0.9 ? _green : scale >= 0.5 ? _yellow : _red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text('${(scale * 100).round()}%',
          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 22)),
    );
  }

  Widget _missingIngCard(String name, Map ing, List subs) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _red.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.close, color: _red, size: 16),
              const SizedBox(width: 6),
              Text(name,
                  style: const TextStyle(color: _textPri, fontWeight: FontWeight.w600, fontSize: 15)),
              const Spacer(),
              Text('${ing['qty']} ${ing['unit']}',
                  style: const TextStyle(color: _red, fontSize: 13)),
            ],
          ),
          if (subs.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Text('Substitutes:',
                style: TextStyle(color: _textSec, fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            ...subs.map((s) {
              final subText  = s['sub']   as String;
              final level    = s['level'] as String;
              final isChosen = _chosenSubs[name] == subText;
              final badgeColor = level == 'best'
                  ? _green
                  : level == 'good'
                      ? _yellow
                      : _red;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isChosen) {
                      _chosenSubs.remove(name);
                    } else {
                      _chosenSubs[name] = subText;
                    }
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: isChosen ? _accentSoft : _surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: isChosen ? _accent : _border),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isChosen ? Icons.check_circle : Icons.radio_button_unchecked,
                        color: isChosen ? _accent : _textSec,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(subText,
                              style: TextStyle(
                                  color: isChosen ? _accent : _textPri,
                                  fontSize: 13))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(level,
                            style: TextStyle(
                                color: badgeColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _lowQtyCard(Map ing) {
    final have = (ing['have'] as num).toDouble();
    final need = (ing['qty']  as num).toDouble();
    final pct  = (have / need).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _yellow.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber, color: _yellow, size: 16),
              const SizedBox(width: 6),
              Expanded(
                  child: Text(ing['name'],
                      style: const TextStyle(color: _textPri, fontWeight: FontWeight.w600))),
              Text('$have / $need ${ing['unit']}',
                  style: const TextStyle(color: _yellow, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: _border,
              valueColor: AlwaysStoppedAnimation(
                  pct > 0.7 ? _green : pct > 0.4 ? _yellow : _red),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}