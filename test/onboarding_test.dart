// The guided tour shown the first time a player opens the game.
import 'package:emplake/l10n/app_localizations.dart';
import 'package:emplake/onboarding.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final a = GlobalKey(), b = GlobalKey(), missing = GlobalKey(), c = GlobalKey();
  final steps = [
    TourStep(a, (_) => 'First', (_) => 'About the first box'),
    TourStep(b, (_) => 'Second', (_) => 'About the second box'),
    TourStep(missing, (_) => 'Ghost', (_) => 'Not on screen'),
    TourStep(c, (_) => 'Third', (_) => 'About the third box'),
  ];

  Future<void> open(WidgetTester t, {Size size = const Size(400, 700), String lang = 'en'}) async {
    t.view.physicalSize = size;
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(MaterialApp(
      locale: Locale(lang),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(
        body: SingleChildScrollView(
          child: Column(children: [
            SizedBox(key: a, height: 120, width: 200),
            const SizedBox(height: 900),
            SizedBox(key: b, height: 60, width: 100),
            const SizedBox(height: 900),
            SizedBox(key: c, height: 60, width: 100),
          ]),
        ),
      ),
    ));
    showTour(t.element(find.byType(Scaffold)), steps);
    await t.pumpAndSettle();
  }

  testWidgets('walks through every step, skipping targets that are not on screen', (t) async {
    await open(t);
    expect(find.text('First'), findsOneWidget);
    expect(find.text('1 of 4'), findsOneWidget);
    expect(find.text('Back'), findsNothing);

    await t.tap(find.text('Next'));
    await t.pumpAndSettle();
    expect(find.text('Second'), findsOneWidget);

    await t.tap(find.text('Next'));
    await t.pumpAndSettle();
    expect(find.text('Ghost'), findsNothing);
    expect(find.text('Third'), findsOneWidget);
    expect(find.text('Start playing'), findsOneWidget);

    await t.tap(find.text('Back'));
    await t.pumpAndSettle();
    expect(find.text('Second'), findsOneWidget, reason: 'going back also skips the missing target');

    await t.tap(find.text('Next'));
    await t.pumpAndSettle();
    await t.tap(find.text('Start playing'));
    await t.pumpAndSettle();
    expect(find.text('Third'), findsNothing, reason: 'the tour closed');
  });

  testWidgets('scrolls each target into view and keeps the card on screen', (t) async {
    for (final size in const [Size(320, 480), Size(400, 700), Size(1280, 720)]) {
      await open(t, size: size);
      for (final key in [a, b, c]) {
        final target = t.getRect(find.byKey(key));
        expect(target.top >= 0 && target.bottom <= size.height, isTrue, reason: '$size $key visible');
        final card = t.getRect(find.byType(Card));
        expect(card.left >= 0 && card.right <= size.width, isTrue, reason: '$size card inside');
        expect(card.top >= 0 && card.bottom <= size.height, isTrue, reason: '$size card inside');
        if (find.text('Next').evaluate().isNotEmpty) {
          await t.tap(find.text('Next'));
          await t.pumpAndSettle();
        }
      }
      await t.tap(find.text('Start playing'));
      await t.pumpAndSettle();
    }
  });

  testWidgets('can be skipped at any step, and is translated', (t) async {
    await open(t, lang: 'pt');
    expect(find.text('1 de 4'), findsOneWidget);
    await t.tap(find.text('Pular tour'));
    await t.pumpAndSettle();
    expect(find.text('First'), findsNothing);
  });
}
