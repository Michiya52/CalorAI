import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../services/ingredient_library_service.dart';
import '../../models/meal_entry.dart';
import '../../models/food_item.dart';

class IngredientLibraryBrowser extends StatefulWidget {
  final ValueChanged<IngredientDetail> onIngredientSelected;

  const IngredientLibraryBrowser({
    super.key,
    required this.onIngredientSelected,
  });

  @override
  State<IngredientLibraryBrowser> createState() =>
      _IngredientLibraryBrowserState();
}

class _IngredientLibraryBrowserState extends State<IngredientLibraryBrowser> {
  final IngredientLibraryService _libraryService =
      IngredientLibraryService.instance;
  bool _isLoading = true;
  String _searchQuery = '';
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      await _libraryService.loadLibrary();
    } catch (_) {}
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ingredient Library')),
        body: const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Ingredient Library'),
          centerTitle: true,
          bottom: const TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(text: 'Raw Ingredients'),
              Tab(text: 'Branded Foods'),
            ],
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search library...',
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.grey.withValues(alpha: 0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (val) => setState(() => _searchQuery = val),
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildTabContent(isBranded: false),
                  _buildTabContent(isBranded: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent({required bool isBranded}) {
    if (_searchQuery.trim().isNotEmpty) {
      final searchResults =
          _libraryService.searchLibrary(_searchQuery, isBranded: isBranded);
      if (searchResults.isEmpty) {
        return const Center(
            child: Text('No matching items found.',
                style: TextStyle(color: Colors.grey)));
      }
      return ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: searchResults.length,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (context, index) => _buildItemTile(searchResults[index]),
      );
    }

    final sourceMap = isBranded
        ? _libraryService.brandedCategorizedItems
        : _libraryService.rawCategorizedItems;

    final categories = sourceMap.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final items = sourceMap[category]!;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              title: Text(
                category,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              subtitle: Text(
                '${items.length} items',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: items.length,
                    separatorBuilder: (context, idx) =>
                        const Divider(height: 1),
                    itemBuilder: (context, itemIndex) =>
                        _buildItemTile(items[itemIndex]),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildItemTile(FoodItem item) {
    return ListTile(
      title: Text(
        item.nameEn,
        style: const TextStyle(fontSize: 14),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${item.caloriesPer100g} kcal/100g',
        style: const TextStyle(color: AppColors.primary, fontSize: 12),
      ),
      trailing: const Icon(Icons.add_circle, color: AppColors.primary),
      onTap: () {
        HapticFeedback.lightImpact();
        final detail = IngredientDetail(
          name: item.nameEn,
          grams: 100.0,
          calories: item.caloriesPer100g.round(),
          proteinG: item.proteinPer100g,
          carbsG: item.carbsPer100g,
          fatsG: item.fatsPer100g,
          sourceId: item.myfcdCode,
        );
        widget.onIngredientSelected(detail);
        Navigator.pop(context); // Return to Meal Creator
      },
    );
  }
}
