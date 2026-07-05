import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:calor_ai/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Monkey Test with Auth Bypass (Avoids AI)',
      (WidgetTester tester) async {
    // 1. Boot the app
    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // 2. Auth the provided test user dynamically
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: 'zhengyao.chan1@gmail.com',
        password: 'qweasdzxc',
      );
    } catch (e) {
      if (e is FirebaseAuthException && e.code == 'user-not-found') {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: 'zhengyao.chan1@gmail.com',
          password: 'qweasdzxc',
        );
      } else {
        // Try creating it anyway in case it was invalid-credential
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: 'zhengyao.chan1@gmail.com',
          password: 'qweasdzxc',
        );
      }
    }

    // Wait for auth to propagate and app to navigate to Dashboard
    await tester.pumpAndSettle(const Duration(seconds: 4));

    // 3. Monkey Loop
    final random = Random();
    int taps = 0;
    const maxTaps = 500;

    debugPrint('🐒 Starting Monkey Test Loop...');

    while (taps < maxTaps) {
      // Find all potentially tappable widgets on the current screen
      final candidates = find
          .byWidgetPredicate((widget) {
            return widget is InkWell ||
                widget is GestureDetector ||
                widget is ElevatedButton ||
                widget is OutlinedButton ||
                widget is IconButton;
          })
          .evaluate()
          .toList();

      if (candidates.isEmpty) {
        await tester.pump();
        continue;
      }

      // Filter out widgets that launch AI tools or the Chatbot
      final safeCandidates = candidates.where((element) {
        final widget = element.widget;

        // Filter IconButtons
        if (widget is IconButton && widget.icon is Icon) {
          final iconData = (widget.icon as Icon).icon;
          if (iconData == Icons.auto_awesome_outlined ||
              iconData == Icons.auto_awesome ||
              iconData == Icons.add_a_photo_rounded) {
            return false;
          }
        }

        // Filter text labels and inner icons
        var isUnsafe = false;
        void checkChildren(Element el) {
          if (el.widget is Text) {
            final t = (el.widget as Text).data?.toLowerCase() ?? '';
            if (t.contains('ai') ||
                t.contains('scanner') ||
                t.contains('chat')) {
              isUnsafe = true;
            }
          }
          if (el.widget is Icon) {
            final iconData = (el.widget as Icon).icon;
            if (iconData == Icons.auto_awesome_outlined ||
                iconData == Icons.auto_awesome ||
                iconData == Icons.add_a_photo_rounded) {
              isUnsafe = true;
            }
          }
          el.visitChildren(checkChildren);
        }

        element.visitChildren(checkChildren);

        return !isUnsafe;
      }).toList();

      if (safeCandidates.isEmpty) {
        await tester.pump();
        continue;
      }

      // Pick a random SAFE widget and tap it
      final target = safeCandidates[random.nextInt(safeCandidates.length)];

      try {
        await tester.tap(find.byWidget(target.widget));
        await tester.pumpAndSettle(const Duration(milliseconds: 200));
        taps++;

        if (taps % 50 == 0) {
          debugPrint('🐒 Monkey Progress: $taps / $maxTaps taps completed...');
        }
      } catch (e) {
        // Widget might be off-screen or animating, just pump and continue
        await tester.pump();
      }
    }

    debugPrint(
        '✅ Monkey Test Completed Successfully with $taps taps! No crashes detected.');
  });
}
