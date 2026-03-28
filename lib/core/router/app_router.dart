import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/food_suggestion.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/register_screen.dart';
import '../../screens/onboarding/profile_setup_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/dashboard/dashboard_screen.dart';
import '../../screens/history/meal_history_screen.dart';
import '../../screens/chatbot/chatbot_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/logging/photo_logging_screen.dart';
import '../../screens/logging/suggestion_cards_screen.dart';
import '../../screens/logging/portion_selection_screen.dart';
import '../../screens/logging/manual_search_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/login',
  redirect: (context, state) {
    final isLoggedIn = context.read<AuthProvider>().isLoggedIn;
    final isAuthRoute = state.matchedLocation.startsWith('/login') ||
        state.matchedLocation.startsWith('/register');
    final isSetupRoute = state.matchedLocation.startsWith('/setup');

    if (!isLoggedIn && !isAuthRoute && !isSetupRoute) return '/login';
    if (isLoggedIn && isAuthRoute) return '/home';
    return null;
  },
  routes: [
    GoRoute(path: '/login', builder: (c, s) => const LoginScreen()),
    GoRoute(path: '/register', builder: (c, s) => const RegisterScreen()),
    GoRoute(path: '/setup', builder: (c, s) => const ProfileSetupScreen()),

    ShellRoute(
      builder: (c, s, child) => HomeScreen(child: child),
      routes: [
        GoRoute(path: '/home', builder: (c, s) => const DashboardScreen()),
        GoRoute(path: '/history', builder: (c, s) => const MealHistoryScreen()),
        GoRoute(path: '/chatbot', builder: (c, s) => const ChatbotScreen()),
        GoRoute(path: '/profile', builder: (c, s) => const ProfileScreen()),
      ],
    ),

    GoRoute(
        path: '/log/photo',
        builder: (c, s) => const PhotoLoggingScreen()),
    GoRoute(
        path: '/log/suggestions',
        builder: (c, s) => SuggestionCardsScreen(
              suggestions: s.extra as List<FoodSuggestion>,
            )),
    GoRoute(
        path: '/log/portion',
        builder: (c, s) => PortionSelectionScreen(
              suggestion: s.extra as FoodSuggestion,
            )),
    GoRoute(
        path: '/log/search',
        builder: (c, s) => const ManualSearchScreen()),
  ],
);
