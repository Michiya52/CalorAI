import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fuzzywuzzy/fuzzywuzzy.dart';
import '../../core/constants/app_colors.dart';
import '../../models/food_item.dart';
import '../../models/food_suggestion.dart';
import '../../services/firestore_service.dart';
import '../../services/open_food_facts_service.dart';
import '../../services/usda_service.dart';

enum _SearchSource { regional, openFoodFacts, usda }

class ManualSearchScreen extends StatefulWidget {
  const ManualSearchScreen({super.key});

  @override
  State<ManualSearchScreen> createState() => _ManualSearchScreenState();
}

class _ManualSearchScreenState extends State<ManualSearchScreen> {
  final _searchController = TextEditingController();
  final FirestoreService _firestore = FirestoreService();
  final OpenFoodFactsService _off = OpenFoodFactsService.instance;
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;
  List<FoodItem> _results = [];
  bool _isSearching = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String _query = '';
  int _offset = 0;
  _SearchSource _source = _SearchSource.regional;
  String? _searchError;

  static const int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_query.trim().isEmpty || !_hasMore || _isSearching || _isLoadingMore) {
      return;
    }

    final max = _scrollController.position.maxScrollExtent;
    final current = _scrollController.position.pixels;
    if (current >= (max - 200)) {
      _loadMore();
    }
  }

  void _onSearchChanged(String query) {
    setState(() => _query = query);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _performSearch(query, reset: true);
    });
  }

  Future<void> _performSearch(String query, {required bool reset}) async {
    final normalizedQuery = query.trim();

    if (normalizedQuery.isEmpty) {
      if (mounted) {
        setState(() {
          _results = [];
          _isSearching = false;
          _isLoadingMore = false;
          _hasMore = true;
          _offset = 0;
          _searchError = null;
        });
      }
      return;
    }

    if (!reset && (!_hasMore || _isLoadingMore || _isSearching)) {
      return;
    }

    if (reset) {
      setState(() {
        _isSearching = true;
        _isLoadingMore = false;
        _results = [];
        _offset = 0;
        _hasMore = true;
        _searchError = null;
      });
    } else {
      setState(() => _isLoadingMore = true);
    }

    final fetchOffset = reset ? 0 : _offset;
    List<FoodItem> fetched = const [];
    try {
      if (_source == _SearchSource.regional) {
        fetched = await _firestore.searchFoods(
          normalizedQuery,
          offset: fetchOffset,
          limit: _pageSize,
        );
      } else if (_source == _SearchSource.openFoodFacts) {
        final page = (fetchOffset / _pageSize).floor() + 1;
        fetched = await _off.searchFoods(normalizedQuery, page: page);
      } else {
        fetched = await UsdaService.instance.searchFoods(normalizedQuery);
      }
    } catch (_) {
      fetched = const [];
    }

    if (mounted) {
      // Apply strict relevance filtering/ranking to all sources
      var filtered = fetched;
      
      if (normalizedQuery.isNotEmpty) {
        final scored = fetched.map((food) {
          final query = normalizedQuery.toLowerCase().trim();
          final name = food.nameEn.toLowerCase();
          
          int score = 0;
          if (name == query) {
            score = 100;
          } else if (name.startsWith(query)) {
            score = 95;
          } else if (name.split(RegExp(r'\s+')).contains(query)) {
            score = 90;
          } else {
            score = tokenSetRatio(query, name);
          }
          return _ScoredResult(food, score);
        }).where((s) => s.score >= 70).toList();

        scored.sort((a, b) => b.score.compareTo(a.score));
        filtered = scored.map((s) => s.food).toList();
      }

      setState(() {
        if (reset) {
          _results = filtered;
        } else {
          _results = [..._results, ...filtered];
        }

        _offset = fetchOffset + fetched.length;
        _hasMore = fetched.length == _pageSize;
        _isSearching = false;
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _loadMore() async {
    await _performSearch(_query, reset: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Search Food'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SegmentedButton<_SearchSource>(
                  segments: const [
                    ButtonSegment(
                      value: _SearchSource.regional,
                      label: Text('MY+SG Database'),
                    ),
                    ButtonSegment(
                      value: _SearchSource.openFoodFacts,
                      label: Text('OFF'),
                    ),
                    ButtonSegment(
                      value: _SearchSource.usda,
                      label: Text('USDA (FOSS)'),
                    ),
                  ],
                  selected: {_source},
                  onSelectionChanged: (selection) {
                    setState(() {
                      _source = selection.first;
                      _results = [];
                      _offset = 0;
                      _hasMore = true;
                      _searchError = null;
                    });
                    if (_query.trim().isNotEmpty) {
                      _performSearch(_query, reset: true);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Search for a food...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _query = '';
                                _results = [];
                                _offset = 0;
                                _hasMore = true;
                                _isLoadingMore = false;
                                _searchError = null;
                              });
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: _onSearchChanged,
                ),
              ],
            ),
          ),
          if (_isSearching)
            const LinearProgressIndicator()
          else if (_searchError != null)
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    _searchError!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ),
            )
          else if (_results.isEmpty && _query.isNotEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.manage_search,
                        size: 48, color: AppColors.textSecondary),
                    const SizedBox(height: 12),
                    Text(
                        _source == _SearchSource.regional
                            ? 'No results in MY/SG data. Try Open Food Facts.'
                            : 'No results found. Try another keyword.',
                        style: TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _results.length + (_isLoadingMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= _results.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final food = _results[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      title: Text(food.nameEn,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        '${food.nameMy} • ${food.foodGroup} • ${food.caloriesPer100g.toStringAsFixed(0)} kcal/100g',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 12),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: food.source == 'OpenFoodFacts'
                              ? AppColors.primary
                              : AppColors.myfcdBadge,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(_sourceLabel(food.source),
                            style: const TextStyle(
                                color: Colors.white, fontSize: 10)),
                      ),
                      onTap: () {
                        // Create a FoodSuggestion from the FoodItem
                        final suggestion = FoodSuggestion(
                          rank: 1,
                          dishNameEn: food.nameEn,
                          dishNameMy: food.nameMy,
                          mainIngredients: [food.foodGroup],
                          estimatedPortionGrams: food.portionSizes.mediumGrams,
                          confidence: '',
                          confidencePercent: null,
                          cookingMethod: '',
                          myfcdMatch: food,
                          resolvedCalories: (food.caloriesPer100g *
                                  food.portionSizes.mediumGrams /
                                  100)
                              .round(),
                          resolvedProteinG: food.proteinPer100g *
                              food.portionSizes.mediumGrams /
                              100,
                          resolvedCarbsG: food.carbsPer100g *
                              food.portionSizes.mediumGrams /
                              100,
                          resolvedFatsG: food.fatsPer100g *
                              food.portionSizes.mediumGrams /
                              100,
                          source: food.source == 'OpenFoodFacts'
                              ? 'Open Food Facts'
                              : 'MyFCD',
                        );
                        context.push('/log/portion', extra: suggestion);
                      },
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  String _sourceLabel(String source) {
    if (source == 'OpenFoodFacts') return 'OFF';
    if (source.startsWith('MyFCD')) return 'MyFCD';
    if (source.startsWith('USDA')) return 'USDA';
    if (source.startsWith('SG_')) return 'SG';
    if (source.startsWith('AUSNUT')) return 'AUSNUT';
    if (source.startsWith('UK_')) return 'UK';
    return source;
  }
}

class _ScoredResult {
  final FoodItem food;
  final int score;
  _ScoredResult(this.food, this.score);
}
