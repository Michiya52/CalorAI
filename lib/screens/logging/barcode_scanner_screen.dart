import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/constants/app_colors.dart';
import '../../models/food_suggestion.dart';
import '../../services/open_food_facts_service.dart';
import '../../services/usda_service.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  final MobileScannerController controller = MobileScannerController();
  bool _isProcessing = false;

  Future<void> _handleBarcode(String barcode) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      // 1. Try Open Food Facts
      final offResult = await OpenFoodFactsService.instance.getProductByBarcode(barcode);
      
      if (offResult != null) {
        _navigateToPortion(offResult);
        return;
      }

      // 2. Try USDA FDC
      final usdaResult = await UsdaService.instance.getProductByBarcode(barcode);
      if (usdaResult != null) {
        _navigateToPortion(usdaResult);
        return;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product not found in our open databases.'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _navigateToPortion(dynamic food) {
    final suggestion = FoodSuggestion(
      rank: 1,
      dishNameEn: food.nameEn,
      dishNameMy: food.nameMy,
      mainIngredients: [food.foodGroup],
      estimatedPortionGrams: food.portionSizes.mediumGrams,
      confidence: '', // Scanner is certain
      cookingMethod: '',
      myfcdMatch: food,
      resolvedCalories: food.caloriesPer100g * (food.portionSizes.mediumGrams / 100.0),
      resolvedProteinG: food.proteinPer100g * (food.portionSizes.mediumGrams / 100.0),
      resolvedCarbsG: food.carbsPer100g * (food.portionSizes.mediumGrams / 100.0),
      resolvedFatsG: food.fatsPer100g * (food.portionSizes.mediumGrams / 100.0),
      source: food.source,
    );

    context.push('/log/portion', extra: suggestion);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan Barcode', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  _handleBarcode(barcode.rawValue!);
                  break;
                }
              }
            },
          ),
          
          // Scanning HUD
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primary, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          
          if (_isProcessing)
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
            
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Text(
              'Align barcode within the box',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
            ),
          ),
        ],
      ),
    );
  }
}
