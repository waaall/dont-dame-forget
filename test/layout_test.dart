import 'package:dont_forget/app.dart';
import 'package:dont_forget/core/reminder_engine.dart';
import 'package:dont_forget/l10n/app_localizations.dart';
import 'package:dont_forget/shared/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_engine.dart';

void main() {
  for (final ringing in [false, true]) {
    testWidgets(
      '${ringing ? 'Mission' : 'Home'} fits a small screen at twice the text size',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(320, 700));
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(() {
          tester.platformDispatcher.clearTextScaleFactorTestValue();
          return tester.binding.setSurfaceSize(null);
        });
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              engineProvider.overrideWithValue(
                FakeEngine(withPlans: true, ringing: ringing, language: 'en'),
              ),
            ],
            child: const DontForgetApp(),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }

  testWidgets('custom duration fits a small screen with the keyboard open', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(viewInsets: const EdgeInsets.only(bottom: 280)),
          child: child!,
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => chooseDuration(context, 10),
              child: const Text('Open duration'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open duration'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('English settings fit a small screen at twice the text size', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(() {
      tester.platformDispatcher.clearTextScaleFactorTestValue();
      return tester.binding.setSurfaceSize(null);
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          engineProvider.overrideWithValue(FakeEngine(language: 'en')),
        ],
        child: const DontForgetApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Settings').last);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
