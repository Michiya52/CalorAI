import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/app_logger.dart';
import '../../services/gemini_service.dart';

class PhotoLoggingScreen extends StatefulWidget {
  const PhotoLoggingScreen({super.key});

  @override
  State<PhotoLoggingScreen> createState() => _PhotoLoggingScreenState();
}

class _PhotoLoggingScreenState extends State<PhotoLoggingScreen> {
  bool _isLoading = false;
  Uint8List? _imageBytes;

  Future<void> _pickImage(ImageSource source) async {
    AppLogger.instance.log('PhotoLoggingScreen: picking image from $source');
    final picker = ImagePicker();
    final XFile? imageFile = await picker.pickImage(
      source: source,
      maxWidth: 1024,
      imageQuality: 85,
    );
    if (imageFile == null) return;
    AppLogger.instance.log('PhotoLoggingScreen: picked file ${imageFile.path}');
    await _processImage(imageFile);
  }

  Future<void> _processImage(XFile imageFile) async {
    setState(() => _isLoading = true);
    _imageBytes = await imageFile.readAsBytes();
    AppLogger.instance.log(
        'PhotoLoggingScreen: loaded image bytes = ${_imageBytes?.length ?? 0}');

    try {
      final gemini = GeminiService();

      final suggestions = await gemini.identifyFoodFromImage(_imageBytes!);
      AppLogger.instance.log(
          'PhotoLoggingScreen: suggestions returned = ${suggestions.length}');

      if (!mounted) return;
      if (suggestions.isEmpty) {
        AppLogger.instance.log(
            'PhotoLoggingScreen: suggestions empty, routing to manual search');
        context.push('/log/search');
        return;
      }
      AppLogger.instance.log(
          'PhotoLoggingScreen: first suggestion = ${suggestions.first.dishNameEn}');
      context.push('/log/suggestions', extra: suggestions);
    } catch (e) {
      AppLogger.instance
          .log('PhotoLoggingScreen: image identification failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 5),
            content: const Text(
                'Could not identify food. Try again or search manually.'),
            action: SnackBarAction(
              label: 'Search',
              onPressed: () => context.push('/log/search'),
            ),
          ),
        );
      }
    } finally {
      _imageBytes = null; // CRITICAL: Always clear image bytes
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Log Meal'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  const SizedBox(height: 24),
                  Text('Identifying your meal...',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('This may take a moment',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  Icon(Icons.camera_alt_outlined,
                      size: 80, color: AppColors.primary),
                  const SizedBox(height: 24),
                  Text(
                    'Snap your meal',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Take a photo or choose from gallery\nand we\'ll identify it for you',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Take Photo',
                          style: TextStyle(fontSize: 16)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 56,
                    child: OutlinedButton.icon(
                      onPressed: () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Choose from Gallery',
                          style: TextStyle(fontSize: 16)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 56,
                    child: OutlinedButton.icon(
                      onPressed: () => context.push('/log/barcode'),
                      icon: const Icon(Icons.qr_code_scanner),
                      label: const Text('Scan Barcode',
                          style: TextStyle(fontSize: 16)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => context.push('/log/search'),
                    icon: const Icon(Icons.search),
                    label: const Text('Search manually instead'),
                    style: TextButton.styleFrom(
                        foregroundColor: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
    );
  }
}
