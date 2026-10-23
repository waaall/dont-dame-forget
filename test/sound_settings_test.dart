import 'package:dont_forget/app.dart';
import 'package:dont_forget/core/reminder_engine.dart';
import 'package:dont_forget/domain/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support/fake_engine.dart';

void main() {
  test(
    'legacy reminders get sound defaults and custom settings round trip',
    () {
      final data =
          (FakeEngine(withPlans: true).data['plans'] as List).first
              as Map<String, dynamic>;
      final legacy = Reminder.fromJson(data);
      expect(legacy.sound.uri, isEmpty);
      expect(legacy.sound.volumePercent, 100);
      expect(legacy.sound.fadeInSeconds, 0);
      final updated = ReminderSound(
        uri: 'content://media/internal/audio/media/42',
        name: 'Bell',
        volumePercent: 60,
        fadeInSeconds: 30,
      );
      final restored = Reminder.fromJson({
        ...legacy.toJson(),
        ...updated.toJson(),
      });
      expect(restored.sound.toJson(), updated.toJson());
    },
  );

  Future<void> scrollTo(WidgetTester tester, Finder target) async {
    for (
      var attempt = 0;
      attempt < 16 && target.hitTestable().evaluate().isEmpty;
      attempt++
    ) {
      await tester.drag(find.byType(ListView).last, const Offset(0, -300));
      await tester.pumpAndSettle();
    }
    expect(target.hitTestable(), findsOneWidget);
  }

  testWidgets('sound selection, fade and volume are saved with the reminder', (
    tester,
  ) async {
    final engine = FakeEngine();
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [engineProvider.overrideWithValue(engine)],
        child: const DontForgetApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('新建提醒'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '声音设置测试');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await scrollTo(tester, find.byKey(const ValueKey('choose-sound')));
    await tester.tap(find.byKey(const ValueKey('choose-sound')));
    await tester.pumpAndSettle();
    expect(find.text('Morning bell'), findsOneWidget);
    await scrollTo(tester, find.byKey(const ValueKey('sound-volume')));
    final slider = tester.widget<Slider>(
      find.byKey(const ValueKey('sound-volume')),
    );
    slider.onChanged!(60);
    await tester.pumpAndSettle();
    await scrollTo(tester, find.byKey(const ValueKey('sound-fade-30')));
    await tester.tap(find.byKey(const ValueKey('sound-fade-30')));
    await tester.pumpAndSettle();
    await scrollTo(tester, find.byKey(const ValueKey('preview-sound')));
    await tester.tap(find.byKey(const ValueKey('preview-sound')));
    await tester.pumpAndSettle();
    expect(find.text('停止试听'), findsOneWidget);
    final preview = engine.calls
        .lastWhere((call) => call.$1 == 'previewSound')
        .$2;
    expect(preview['volumePercent'], 60);
    expect(preview['fadeInSeconds'], 30);
    await scrollTo(tester, find.text('保存提醒'));
    await tester.tap(find.text('保存提醒'));
    await tester.pumpAndSettle();
    final saved = engine.calls
        .singleWhere((call) => call.$1 == 'saveReminder')
        .$2;
    expect(saved['soundUri'], preview['soundUri']);
    expect(saved['soundName'], 'Morning bell');
    expect(saved['volumePercent'], 60);
    expect(saved['fadeInSeconds'], 30);
    expect(engine.data['soundPreviewPlaying'], isFalse);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'English sound settings fit a small screen at twice the text size',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 700));
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      tester.view.padding = const FakeViewPadding(bottom: 120);
      tester.view.viewPadding = const FakeViewPadding(bottom: 120);
      addTearDown(() {
        tester.platformDispatcher.clearTextScaleFactorTestValue();
        tester.view.resetPadding();
        tester.view.resetViewPadding();
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
      await scrollTo(tester, find.text('New reminder').last);
      await tester.tap(find.text('New reminder').last);
      await tester.pumpAndSettle();
      await scrollTo(tester, find.byKey(const ValueKey('choose-sound')));
      await scrollTo(tester, find.byKey(const ValueKey('preview-sound')));
      await tester.drag(find.byType(ListView).last, const Offset(0, -10000));
      await tester.pumpAndSettle();
      final save = find.widgetWithText(FilledButton, 'Save reminder');
      final bottomInset = MediaQuery.viewPaddingOf(tester.element(save)).bottom;
      expect(bottomInset, greaterThan(0));
      expect(
        tester.getBottomRight(save).dy,
        lessThanOrEqualTo(700 - bottomInset),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
