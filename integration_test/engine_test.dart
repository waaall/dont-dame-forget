import 'package:dont_forget/app.dart';
import 'package:dont_forget/core/reminder_engine.dart';
import 'package:dont_forget/domain/models.dart';
import 'package:dont_forget/features/missions/mission_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:intl/intl.dart';

// Run only on a dedicated emulator: these tests create real alarms and settings.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final engine = AndroidReminderEngine();
  const password = 'test-only-4729';
  final created = <String>[];

  Future<Map<String, dynamic>> snapshot() async =>
      jsonMap(await engine.invoke('snapshot'));
  Future<Map<String, dynamic>> occurrence(String planId) async =>
      ((await snapshot())['occurrences'] as List)
          .map(jsonMap)
          .singleWhere((item) => item['planId'] == planId);
  Matcher rule(String code) =>
      isA<PlatformException>().having((error) => error.code, 'code', code);
  Map<String, dynamic> plan(String title, DateTime time) => {
    'title': title,
    'note': '',
    'category': 'other',
    'mission': 'math',
    'difficulty': 'easy',
    'mathCount': 2,
    'date': DateFormat('yyyy-MM-dd').format(time),
    'hour': time.hour,
    'minute': time.minute,
    'days': <int>[],
    'repeating': false,
    'snoozeMinutes': 1,
    'reviewEnabled': false,
    'reviewMinutes': 1,
    'vibrate': false,
    'qrValue': '',
    'qrLabel': '',
  };
  Future<String> save(Map<String, dynamic> data) async {
    final id = await engine.invoke('saveReminder', data) as String;
    created.add(id);
    return id;
  }

  Future<void> waitForRinging(String id) async {
    final deadline = DateTime.now().add(const Duration(seconds: 85));
    while (DateTime.now().isBefore(deadline)) {
      if ((await occurrence(id))['status'] == 'ringing') return;
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
    fail('Android AlarmManager did not fire $id before $deadline');
  }

  Future<Map<String, dynamic>> solve(String id) async {
    final question = jsonMap(await engine.invoke('challenge', {'id': id}));
    final parts = (question['expression'] as String).split(' ');
    final a = int.parse(parts[0]), b = int.parse(parts[2]);
    final answer = switch (parts[1]) {
      '+' => a + b,
      '−' => a - b,
      '×' => a * b,
      _ => throw StateError('Unknown question: $question'),
    };
    return jsonMap(
      await engine.invoke('answerMath', {
        'id': id,
        'answer': '$answer',
        'token': question['token'],
      }),
    );
  }

  setUpAll(() async {
    final state = await snapshot();
    final permissions = jsonMap(state['permissions']);
    expect(permissions['exact'], isTrue);
    expect(
      permissions['notifications'],
      isTrue,
      reason: 'Grant POST_NOTIFICATIONS on the dedicated emulator first.',
    );
    await engine.invoke('setPassword', {
      'currentPassword': password,
      'password': password,
    });
  });

  tearDownAll(() async {
    for (final id in created) {
      final live = ((await snapshot())['occurrences'] as List)
          .map(jsonMap)
          .where((item) => item['planId'] == id);
      for (final item in live) {
        if (item['status'] != 'scheduled') {
          await engine.invoke('emergencyClose', {
            'id': item['id'],
            'phrase': emergencyPledge,
            'password': password,
          });
        }
      }
      await engine.invoke('deleteReminder', {'id': id});
    }
    await engine.invoke('saveSettings', {'language': 'zh', 'theme': 'light'});
  });

  testWidgets('native startup, settings, password protection and plan CRUD', (
    tester,
  ) async {
    await engine.invoke('saveSettings', {'language': 'en', 'theme': 'dark'});
    await tester.pumpWidget(const ProviderScope(child: DontForgetApp()));
    await tester.pumpAndSettle();
    expect(find.text('Reminders'), findsWidgets);
    expect(jsonMap((await snapshot())['settings'])['theme'], 'dark');
    await expectLater(
      engine.invoke('setPassword', {
        'currentPassword': 'wrong',
        'password': 'new-password',
      }),
      throwsA(rule('wrong_password')),
    );
    final data = plan(
      'Device CRUD',
      DateTime.now().add(const Duration(days: 1)),
    );
    final id = await save(data);
    expect((await occurrence(id))['status'], 'scheduled');
    await engine.invoke('setEnabled', {'id': id, 'enabled': false});
    expect(
      ((await snapshot())['occurrences'] as List).where(
        (item) => item['planId'] == id,
      ),
      isEmpty,
    );
    await engine.invoke('setEnabled', {'id': id, 'enabled': true});
    expect((await occurrence(id))['status'], 'scheduled');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'real 30 second alarm, protected state, snooze and early completion',
    (tester) async {
      final id = await engine.invoke('testReminder') as String;
      created.add(id);
      debugPrint('DEVICE_TEST_WAITING_FOR_30_SECOND_ALARM');
      await waitForRinging(id);
      debugPrint('DEVICE_TEST_RINGING_SERVICE_WINDOW');
      await Future<void>.delayed(const Duration(seconds: 10));
      final item = await occurrence(id);
      final occurrenceId = item['id'] as String;
      for (final method in ['deleteReminder', 'setEnabled']) {
        await expectLater(
          engine.invoke(method, {'id': id, 'enabled': false}),
          throwsA(rule('active_locked')),
        );
      }
      await expectLater(
        engine.invoke(
          'saveReminder',
          jsonMap(item['plan'])..['title'] = 'Changed',
        ),
        throwsA(rule('active_locked')),
      );
      final challenge = jsonMap(
        await engine.invoke('challenge', {'id': occurrenceId}),
      );
      final publicItem = await occurrence(id);
      expect(publicItem.containsKey('answer'), isFalse);
      expect(publicItem.containsKey('questionToken'), isFalse);
      final wrong = jsonMap(
        await engine.invoke('answerMath', {
          'id': occurrenceId,
          'answer': '-999',
          'token': challenge['token'],
        }),
      );
      expect(wrong['correct'], isFalse);
      await engine.invoke('snooze', {'id': occurrenceId, 'minutes': 1});
      expect((await occurrence(id))['status'], 'snoozed');
      expect((await occurrence(id))['snoozeCount'], 1);
      await expectLater(
        engine.invoke('answerMath', {
          'id': occurrenceId,
          'answer': '0',
          'token': challenge['token'],
        }),
        throwsA(rule('stale_question')),
      );
      expect((await solve(occurrenceId))['completed'], isTrue);
      expect(
        ((await snapshot())['occurrences'] as List).where(
          (item) => item['planId'] == id,
        ),
        isEmpty,
      );
    },
  );

  testWidgets(
    'QR, emergency checks, repeat scheduling and exactly one review',
    (tester) async {
      final now = DateTime.now().add(const Duration(seconds: 10));
      final nextMinute = DateTime(
        now.year,
        now.month,
        now.day,
        now.hour,
        now.minute + 1,
      );
      final reviewId = await save(
        plan('Device review', nextMinute)..['reviewEnabled'] = true,
      );
      final qrId = await save(
        plan('Device QR', nextMinute)
          ..['mission'] = 'qr'
          ..['qrValue'] = 'device-test-qr',
      );
      final repeatId = await save(
        plan('Device repeating emergency', nextMinute)
          ..['repeating'] = true
          ..['days'] = [1, 2, 3, 4, 5, 6, 7],
      );
      await waitForRinging(reviewId);
      await waitForRinging(qrId);
      await waitForRinging(repeatId);
      final qrOccurrence = (await occurrence(qrId))['id'] as String;
      await expectLater(
        engine.invoke('scanCode', {'id': qrOccurrence, 'value': 'wrong'}),
        throwsA(rule('wrong_qr')),
      );
      await engine.invoke('scanCode', {
        'id': qrOccurrence,
        'value': 'device-test-qr',
      });
      final repeatOccurrence = (await occurrence(repeatId))['id'] as String;
      await expectLater(
        engine.invoke('emergencyClose', {
          'id': repeatOccurrence,
          'phrase': 'wrong',
          'password': password,
        }),
        throwsA(rule('wrong_oath')),
      );
      await expectLater(
        engine.invoke('emergencyClose', {
          'id': repeatOccurrence,
          'phrase': emergencyPledge,
          'password': 'wrong',
        }),
        throwsA(rule('wrong_password')),
      );
      await engine.invoke('emergencyClose', {
        'id': repeatOccurrence,
        'phrase': emergencyPledge,
        'password': password,
      });
      expect((await occurrence(repeatId))['status'], 'scheduled');
      expect((await occurrence(repeatId))['id'], isNot(repeatOccurrence));
      final reviewOccurrence = (await occurrence(reviewId))['id'] as String;
      expect((await solve(reviewOccurrence))['completed'], isFalse);
      expect((await solve(reviewOccurrence))['completed'], isTrue);
      expect((await occurrence(reviewId))['status'], 'reviewPending');
      await expectLater(
        engine.invoke('challenge', {'id': reviewOccurrence}),
        throwsA(rule('not_active')),
      );
      await expectLater(
        engine.invoke('deleteReminder', {'id': reviewId}),
        throwsA(rule('active_locked')),
      );
      debugPrint('DEVICE_TEST_WAITING_FOR_ONE_MINUTE_REVIEW');
      await waitForRinging(reviewId);
      expect((await occurrence(reviewId))['isReview'], isTrue);
      expect((await solve(reviewOccurrence))['completed'], isFalse);
      expect((await solve(reviewOccurrence))['completed'], isTrue);
      final state = await snapshot();
      expect(
        (state['occurrences'] as List).where(
          (item) => item['planId'] == reviewId,
        ),
        isEmpty,
      );
      expect(
        (state['history'] as List).where(
          (item) =>
              item['kind'] == 'reviewScheduled' &&
              item['occurrenceId'] == reviewOccurrence,
        ),
        hasLength(1),
      );
    },
    timeout: const Timeout(Duration(minutes: 4)),
  );
}
