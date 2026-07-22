import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slang_bible/logic/bookmarks_provider.dart';
import 'package:slang_bible/logic/launcher.dart';
import 'package:slang_bible/ui/home/support_card.dart';
import 'package:slang_bible/ui/theme/arcade_cabinet.dart';

class FakeLauncher implements Launcher {
  final launched = <Uri>[];

  @override
  Future<void> launch(Uri uri) async {
    launched.add(uri);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<FakeLauncher> pump(
    WidgetTester tester, {
    Map<String, Object> initialPrefs = const {},
  }) async {
    SharedPreferences.setMockInitialValues(initialPrefs);
    final prefs = await SharedPreferences.getInstance();
    final launcher = FakeLauncher();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          launcherProvider.overrideWithValue(launcher),
        ],
        child: const MaterialApp(home: Scaffold(body: SupportCard())),
      ),
    );
    return launcher;
  }

  testWidgets('shows welcome and in-progress messaging', (tester) async {
    await pump(tester);

    expect(find.textContaining("Welcome to the '80s"), findsOneWidget);
    expect(find.textContaining('Old Testament is still in the works'), findsOneWidget);
  });

  testWidgets('tapping PayPal launches the paypal link', (tester) async {
    final launcher = await pump(tester);

    await tester.tap(find.byKey(const Key('support-paypal-button')));
    await tester.pump();

    expect(launcher.launched, [Uri.parse('https://paypal.me/slangbibledev')]);
  });

  testWidgets('tapping Venmo launches the venmo link', (tester) async {
    final launcher = await pump(tester);

    await tester.tap(find.byKey(const Key('support-venmo-button')));
    await tester.pump();

    expect(launcher.launched, [Uri.parse('https://venmo.com/u/slangbibledev')]);
  });

  testWidgets('copy button copies the bitcoin address to the clipboard', (tester) async {
    await pump(tester);

    final calls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        calls.add(call);
        return null;
      },
    );

    await tester.tap(find.byKey(const Key('support-bitcoin-copy-button')));
    await tester.pump();

    final copyCall = calls.firstWhere((c) => c.method == 'Clipboard.setData');
    expect(copyCall.arguments['text'], 'bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh');

    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    );
  });

  group('retro arcade theme', () {
    Future<FakeLauncher> pumpRetro(WidgetTester tester) =>
        pump(tester, initialPrefs: {'app_theme_id': 'retroArcade'});

    testWidgets('renders as an arcade cabinet with the welcome messaging', (
      tester,
    ) async {
      await pumpRetro(tester);

      expect(find.byType(ArcadeCabinet), findsOneWidget);
      expect(find.textContaining("Welcome to the '80s"), findsOneWidget);
      expect(find.textContaining('Old Testament is still in the works'), findsOneWidget);
    });

    testWidgets('tapping PayPal launches the paypal link', (tester) async {
      final launcher = await pumpRetro(tester);

      await tester.tap(find.byKey(const Key('support-paypal-button')));
      await tester.pump();

      expect(launcher.launched, [Uri.parse('https://paypal.me/slangbibledev')]);
    });

    testWidgets('copy button copies the bitcoin address to the clipboard', (
      tester,
    ) async {
      await pumpRetro(tester);

      final calls = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          calls.add(call);
          return null;
        },
      );

      await tester.tap(find.byKey(const Key('support-bitcoin-copy-button')));
      await tester.pump();

      final copyCall = calls.firstWhere((c) => c.method == 'Clipboard.setData');
      expect(copyCall.arguments['text'], 'bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh');

      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
    });
  });
}
