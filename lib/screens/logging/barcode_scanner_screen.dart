import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/constants/app_colors.dart';
import '../../models/food_suggestion.dart';

import '../../services/usda_service.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  final MobileScannerController controller = MobileScannerController();
  bool _isProcessing = false;
  bool _hasPermission = false;
  bool _isCheckingPermission = true;
  String? _lastFailedBarcode;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final status = await Permission.camera.request();
    if (mounted) {
      if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Camera permission required for barcode scanning.')),
        );
        try {
          context.replace('/log/search');
        } catch (e) {
          context.go('/log/search');
        }
        return;
      }
      setState(() {
        _hasPermission = status.isGranted;
        _isCheckingPermission = false;
      });
    }
  }

  Future<void> _handleBarcode(String barcode) async {
    if (_isProcessing) return;
    // Don't re-query a barcode that already came back empty — the camera
    // keeps detecting the same code every frame, which would loop forever.
    if (barcode == _lastFailedBarcode) return;
    setState(() => _isProcessing = true);

    try {
      final usdaResult =
          await UsdaService.instance.getProductByBarcode(barcode);
      if (!mounted) return;

      if (usdaResult != null) {
        _navigateToPortion(usdaResult);
        return;
      }

      _lastFailedBarcode = barcode;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Product not found in our open databases. Try another barcode or search manually.'),
          duration: Duration(seconds: 5),
        ),
      );
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
      estimatedCalories: 0,
      estimatedProteinG: 0.0,
      estimatedCarbsG: 0.0,
      estimatedFatsG: 0.0,
      estimatedSodiumG: 0.0,
      estimatedSugarG: 0.0,
      confidence: '', // Scanner is certain
      cookingMethod: '',
      myfcdMatch: food,
      resolvedCalories:
          food.caloriesPer100g * (food.portionSizes.mediumGrams / 100.0),
      resolvedProteinG:
          food.proteinPer100g * (food.portionSizes.mediumGrams / 100.0),
      resolvedCarbsG:
          food.carbsPer100g * (food.portionSizes.mediumGrams / 100.0),
      resolvedFatsG: food.fatsPer100g * (food.portionSizes.mediumGrams / 100.0),
      resolvedSodiumG:
          food.sodiumPer100g * (food.portionSizes.mediumGrams / 100.0),
      resolvedSugarG:
          food.sugarPer100g * (food.portionSizes.mediumGrams / 100.0),
      source: food.source,
    );

    if (!mounted) return;
    context.push('/log/portion', extra: suggestion);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingPermission) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title:
              const Text('Scan Barcode', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.black,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body:
            const Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (!_hasPermission) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title:
              const Text('Scan Barcode', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.black,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.camera_alt_rounded,
                  color: Colors.white54, size: 64),
              const SizedBox(height: 16),
              const Text(
                'Camera permission is required',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please enable camera access in settings\nto scan barcodes.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => openAppSettings(),
                child: const Text('Open Settings'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title:
            const Text('Scan Barcode', style: TextStyle(color: Colors.white)),
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
