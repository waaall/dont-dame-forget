import 'package:dont_forget/app.dart';
import 'package:dont_forget/core/reminder_engine.dart';
import 'package:dont_forget/features/missions/mission_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support/fake_engine.dart';

Future<void> launch(
  WidgetTester tester,
  FakeEngine engine, {
  Size size = const Size(390, 844),
}) async {
  await tester.binding.setSurfaceSize(size);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [engineProvider.overrideWithValue(engine)],
      child: const DontForgetApp(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the labeled delete key removes the last answer digit', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await launch(tester, FakeEngine(ringing: true, language: 'en'));
      await tester.tap(find.text('1'));
      await tester.tap(find.text('2'));
      await tester.pumpAndSettle();
      expect(find.text('12'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Delete'));
      await tester.pumpAndSettle();
      expect(find.text('12'), findsNothing);
      expect(find.text('1'), findsNWidgets(2));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('first launch has an honest empty state and setup entry', (
    tester,
  ) async {
    await launch(tester, FakeEngine(ready: false));
    expect(find.text('从一件小事开始'), findsOneWidget);
    expect(find.text('先设置应急密码'), findsOneWidget);
    expect(find.text('把洗好的衣服晾起来'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('language switches immediately without changing user content', (
    tester,
  ) async {
    final engine = FakeEngine(withPlans: true);
    await launch(tester, engine);
    await tester.tap(find.text('设置').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButton<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('English').last);
    await tester.pumpAndSettle();
    expect(find.text('Language'), findsOneWidget);
    expect(find.text('Reminders'), findsOneWidget);
    await tester.tap(find.text('Reminders'));
    await tester.pumpAndSettle();
    expect(find.text('把洗好的衣服晾起来'), findsWidgets);
    expect(
      engine.calls.any(
        (call) => call.$1 == 'saveSettings' && call.$2['language'] == 'en',
      ),
      isTrue,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('tap cannot snooze, a hold snoozes without completing', (
    tester,
  ) async {
    final engine = FakeEngine(ringing: true);
    await launch(tester, engine, size: const Size(360, 800));
    expect(find.text('7 + 5 = ?'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(MissionPage), findsOneWidget);
    final hold = find.byKey(const ValueKey('hold-snooze'));
    expect(tester.getRect(hold).bottom, lessThan(800));
    await tester.tap(hold);
    await tester.pumpAndSettle();
    expect(engine.calls.where((call) => call.$1 == 'snooze'), isEmpty);
    await tester.longPress(hold);
    await tester.pumpAndSettle();
    expect(engine.calls.where((call) => call.$1 == 'snooze').single.$2, {
      'id': 'occurrence-0',
      'minutes': 10,
    });
    expect(
      engine.calls.where(
        (call) => call.$1 == 'emergencyClose' || call.$1 == 'answerMath',
      ),
      isEmpty,
    );
    expect(find.byType(MissionPage), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('emergency dismissal requires the exact pledge and password', (
    tester,
  ) async {
    final engine = FakeEngine(ringing: true);
    await launch(tester, engine);
    await tester.tap(find.text('应急关闭'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('emergency-phrase')),
      '我发誓我没忘',
    );
    await tester.enterText(
      find.byKey(const ValueKey('emergency-password')),
      '1234',
    );
    await tester.tap(find.text('验证并关闭本次提醒'));
    await tester.pumpAndSettle();
    expect(engine.calls.where((call) => call.$1 == 'emergencyClose'), isEmpty);
    expect(find.text('请完整、准确地输入指定誓词。'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('emergency-phrase')),
      emergencyPledge,
    );
    await tester.enterText(
      find.byKey(const ValueKey('emergency-password')),
      'wrong',
    );
    await tester.tap(find.text('验证并关闭本次提醒'));
    await tester.pumpAndSettle();
    expect(find.text('密码不正确。'), findsOneWidget);
    expect(find.byType(MissionPage), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('emergency-password')),
      '1234',
    );
    await tester.tap(find.text('验证并关闭本次提醒'));
    await tester.pumpAndSettle();
    expect(find.byType(MissionPage), findsNothing);
    expect(
      (engine.data['occurrences'] as List).any(
        (item) => item['id'] == 'occurrence-0',
      ),
      isFalse,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('small English layout keeps essential actions visible', (
    tester,
  ) async {
    await launch(
      tester,
      FakeEngine(ringing: true, language: 'en', questionCount: 10),
      size: const Size(320, 700),
    );
    final hold = find.byKey(const ValueKey('hold-snooze'));
    expect(tester.getRect(hold).bottom, lessThan(700));
    expect(find.text('Emergency dismissal'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
    'new reminder saves optional follow-up with its ten minute default',
    (tester) async {
      final engine = FakeEngine();
      await launch(tester, engine);
      await tester.tap(find.text('新建提醒'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, '记得晾衣服');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      Future<void> scrollTo(Finder target) async {
        for (
          var attempt = 0;
          attempt < 12 && target.hitTestable().evaluate().isEmpty;
          attempt++
        ) {
          await tester.drag(find.byType(ListView).last, const Offset(0, -360));
          await tester.pumpAndSettle();
        }
        expect(target.hitTestable(), findsOneWidget);
      }

      final review = find.widgetWithText(SwitchListTile, '完成后复查');
      await scrollTo(review);
      await tester.tap(review);
      await tester.pumpAndSettle();
      await scrollTo(find.text('保存提醒'));
      await tester.tap(find.text('保存提醒'));
      await tester.pumpAndSettle();
      final saved = engine.calls
          .where((call) => call.$1 == 'saveReminder')
          .single
          .$2;
      expect(saved['title'], '记得晾衣服');
      expect(saved['reviewEnabled'], isTrue);
      expect(saved['reviewMinutes'], 10);
      expect(saved['snoozeMinutes'], 10);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
