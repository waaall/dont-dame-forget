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
  Future<Map<String, dynamic>> audio(String kind) async =>
      jsonMap(jsonMap(await engine.invoke('soundStatus'))[kind]);
  Future<Map<String, dynamic>> waitForAudio(String kind) async {
    for (var i = 0; i < 40; i++) {
      final status = await audio(kind);
      if (status['ready'] == true) return status;
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    fail('$kind audio did not become ready');
  }

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
    await engine.invoke('stopSoundPreview');
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
    final storedPlan = jsonMap((await occurrence(id))['plan']);
    expect(storedPlan['volumePercent'], 100);
    expect(storedPlan['fadeInSeconds'], 0);
    expect(storedPlan['soundUri'], '');
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
    'native sound preview, gradual gain, fallback and automatic stop',
    (tester) async {
      await engine.invoke('previewSound', {
        'volumePercent': 60,
        'fadeInSeconds': 15,
      });
      final first = await waitForAudio('preview');
      expect(first['volumePercent'], 60);
      expect(first['fadeInSeconds'], 15);
      final gain = (first['gain'] as num).toDouble();
      await Future<void>.delayed(const Duration(seconds: 2));
      expect((await audio('preview'))['gain'] as num, greaterThan(gain));
      await engine.invoke('stopSoundPreview');
      expect((await audio('preview'))['playing'], isFalse);
      await engine.invoke('previewSound', {
        'volumePercent': 100,
        'fadeInSeconds': 0,
        'soundUri': 'content://invalid.dontforget.test/missing',
      });
      final fallback = await waitForAudio('preview');
      expect(fallback['fallbackLevel'], greaterThan(0));
      expect(fallback['gain'], 1.0);
      expect(
        fallback['uri'],
        isNot('content://invalid.dontforget.test/missing'),
      );
      await Future<void>.delayed(const Duration(seconds: 11));
      expect((await audio('preview'))['playing'], isFalse);
      expect((await snapshot())['soundPreviewPlaying'], isFalse);
      await expectLater(
        engine.invoke('previewSound', {'volumePercent': 0}),
        throwsA(rule('invalid_sound')),
      );
    },
  );

  testWidgets(
    'real 30 second alarm, preview preemption, protected state and snooze fade restart',
    (tester) async {
      final id =
          await engine.invoke('testReminder', {
                'volumePercent': 60,
                'fadeInSeconds': 15,
              })
              as String;
      created.add(id);
      debugPrint('DEVICE_TEST_WAITING_FOR_30_SECOND_ALARM');
      await Future<void>.delayed(const Duration(seconds: 23));
      await engine.invoke('previewSound', {
        'volumePercent': 40,
        'fadeInSeconds': 120,
      });
      expect((await audio('preview'))['playing'], isTrue);
      await waitForRinging(id);
      debugPrint('DEVICE_TEST_RINGING_SERVICE_WINDOW');
      final ringingSound = await waitForAudio('alarm');
      expect(ringingSound['volumePercent'], 60);
      expect(ringingSound['fadeInSeconds'], 15);
      expect((await audio('preview'))['playing'], isFalse);
      await expectLater(
        engine.invoke('previewSound', {'volumePercent': 100}),
        throwsA(rule('alarm_ringing')),
      );
      final initialGain = ringingSound['gain'] as num;
      await Future<void>.delayed(const Duration(seconds: 3));
      expect((await audio('alarm'))['gain'] as num, greaterThan(initialGain));
      final item = await occurrence(id);
      final firstRingStartedAt = item['ringStartedAt'];
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
      debugPrint('DEVICE_TEST_WAITING_FOR_SOUND_SNOOZE');
      await waitForRinging(id);
      final snoozedSound = await waitForAudio('alarm');
      expect(snoozedSound['volumePercent'], 60);
      expect(snoozedSound['gain'] as num, lessThan(0.06));
      expect(
        (await occurrence(id))['ringStartedAt'] as num,
        greaterThan(firstRingStartedAt as num),
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
        plan('Device review', nextMinute)
          ..['reviewEnabled'] = true
          ..['volumePercent'] = 70
          ..['fadeInSeconds'] = 15,
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
      await engine.invoke('snooze', {'id': qrOccurrence, 'minutes': 1});
      expect((await occurrence(qrId))['status'], 'snoozed');
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
      final reviewSound = await waitForAudio('alarm');
      expect(reviewSound['volumePercent'], 70);
      expect(reviewSound['fadeInSeconds'], 15);
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
