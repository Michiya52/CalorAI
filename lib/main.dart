import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/router/app_router.dart';
import 'providers/auth_provider.dart';
import 'providers/profile_provider.dart';
import 'providers/meal_provider.dart';
import 'providers/chatbot_provider.dart';
import 'services/firestore_service.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  // Load MyFCD food data from asset
  final firestoreService = FirestoreService();
  try {
    final jsonString = await rootBundle.loadString('assets/data/myfcd_foods.json');
    await firestoreService.loadFoodsFromAsset(jsonString);
  } catch (e) {
    debugPrint('Note: myfcd_foods.json not loaded: $e');
  }

  runApp(const CalorAIApp());
}

class CalorAIApp extends StatelessWidget {
  const CalorAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => MealProvider()),
        ChangeNotifierProvider(create: (_) => ChatbotProvider()),
      ],
      child: MaterialApp.router(
        title: 'CalorAI',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        routerConfig: appRouter,
      ),
    );
  }
}
