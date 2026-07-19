import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/constants/app_colors.dart';
import '../../models/food_suggestion.dart';
import '../../models/food_item.dart';
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
    // One-shot: every outcome exits this screen, so never re-arm scanning.
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      await controller.stop();
    } catch (_) {}

    final usdaResult = await UsdaService.instance.getProductByBarcode(barcode);
    if (!mounted) return;

    if (usdaResult != null) {
      _navigateToPortion(usdaResult);
      return;
    }

    if (context.canPop()) {
      context.pop({'notFound': true, 'barcode': barcode});
    }
  }

  void _navigateToPortion(FoodItem food) {
    final factor = food.portionSizes.mediumGrams / 100.0;
    final suggestion = FoodSuggestion(
      rank: 1,
      dishNameEn: food.nameEn,
      dishNameMy: food.nameMy,
      mainIngredients: [food.foodGroup],
      estimatedPortionGrams: food.portionSizes.mediumGrams,
      estimatedCalories: (food.caloriesPer100g * factor).round(),
      estimatedProteinG: food.proteinPer100g * factor,
      estimatedCarbsG: food.carbsPer100g * factor,
      estimatedFatsG: food.fatsPer100g * factor,
      estimatedSodiumG: food.sodiumPer100g * factor,
      estimatedSugarG: food.sugarPer100g * factor,
      confidence: 'high', // Scanner is certain
      cookingMethod: 'Packaged / Scanned',
      myfcdMatch: food,
      resolvedCalories: (food.caloriesPer100g * factor).round(),
      resolvedProteinG: food.proteinPer100g * factor,
      resolvedCarbsG: food.carbsPer100g * factor,
      resolvedFatsG: food.fatsPer100g * factor,
      resolvedSodiumG: food.sodiumPer100g * factor,
      resolvedSugarG: food.sugarPer100g * factor,
      source: food.source,
    );

    if (!mounted) return;
    context.replace('/log/portion', extra: suggestion);
  }

  void _showManualBarcodeEntry() {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enter / Test Barcode'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: textController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'Enter barcode digits',
                labelText: 'Barcode / GTIN Number',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = textController.text.trim();
              Navigator.of(ctx).pop();
              if (val.isNotEmpty) {
                _handleBarcode(val);
              }
            },
            child: const Text('Lookup'),
          ),
        ],
      ),
    );
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
        actions: [
          IconButton(
            icon: const Icon(Icons.keyboard_alt_outlined),
            tooltip: 'Enter barcode manually',
            onPressed: _showManualBarcodeEntry,
          ),
        ],
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
            left: 20,
            right: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Align barcode within the box',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
                ),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: _showManualBarcodeEntry,
                  icon: const Icon(Icons.keyboard_alt_outlined,
                      color: Colors.white),
                  label: const Text('Enter / Test Barcode Number',
                      style: TextStyle(color: Colors.white)),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.black54,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
