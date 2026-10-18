import 'dart:async';
import 'package:flutter/services.dart';
import 'package:dont_forget/core/reminder_engine.dart';
import 'package:dont_forget/features/missions/mission_page.dart';

class FakeEngine extends ReminderEngine {
  final calls = <(String, Map<String, dynamic>)>[];
  late Map<String, dynamic> data;
  FakeEngine({
    bool withPlans = false,
    bool ringing = false,
    String language = 'zh',
    bool ready = true,
    int questionCount = 3,
  }) {
    final now = DateTime.now();
    final plans = <Map<String, dynamic>>[];
    final occurrences = <Map<String, dynamic>>[];
    if (withPlans || ringing) {
      for (var index = 0; index < 3; index++) {
        final next = now.add(Duration(minutes: 25 + index * 180));
        final status = index == 0 && ringing
            ? 'ringing'
            : index == 0
            ? 'snoozed'
            : 'scheduled';
        final plan = <String, dynamic>{
          'id': 'plan-$index',
          'title': ['把洗好的衣服晾起来', '留一点时间读书', '明天，也要好好起床'][index],
          'note': '',
          'category': ['todo', 'habit', 'alarm'][index],
          'mission': 'math',
          'difficulty': 'easy',
          'qrValue': '',
          'qrLabel': '',
          'date':
              '${next.year}-${next.month.toString().padLeft(2, '0')}-${next.day.toString().padLeft(2, '0')}',
          'hour': next.hour,
          'minute': next.minute,
          'mathCount': questionCount,
          'snoozeMinutes': 10,
          'reviewMinutes': 10,
          'reviewEnabled': index == 1,
          'repeating': index > 0,
          'vibrate': true,
          'enabled': true,
          'days': [1, 2, 3, 4, 5, 6, 7],
          'nextAt': next.millisecondsSinceEpoch,
          'occurrenceStatus': status,
        };
        plans.add(plan);
        occurrences.add({
          'id': 'occurrence-$index',
          'planId': 'plan-$index',
          'status': status,
          'plan': plan,
          'nextAt': next.millisecondsSinceEpoch,
          'originalAt': next.millisecondsSinceEpoch,
          'isReview': false,
          'snoozeCount': index == 0 ? 2 : 0,
        });
      }
    }
    data = {
      'plans': plans,
      'occurrences': occurrences,
      'history': [],
      'weeklyStats': {'completed': 12, 'snoozed': 4, 'skipped': 0},
      'settings': {
        'language': language,
        'theme': 'light',
        'hasPassword': ready,
        'defaultSnoozeMinutes': 10,
      },
      'permissions': {
        'exact': ready,
        'notifications': ready,
        'fullScreen': ready,
        'battery': ready,
        'alarmVolume': 7,
      },
    };
  }
  @override
  Stream<void> get changes => const Stream.empty();
  @override
  Future<dynamic> invoke(
    String method, [
    Map<String, dynamic> arguments = const {},
  ]) async {
    if (method == 'snapshot') return data;
    calls.add((method, {...arguments}));
    switch (method) {
      case 'saveSettings':
        for (final entry in arguments.entries) {
          (data['settings'] as Map)[entry.key] = entry.value;
        }
        return null;
      case 'challenge':
        return {
          'expression': '7 + 5',
          'token': 'question-1',
          'done': 0,
          'total': (data['plans'] as List).first['mathCount'],
        };
      case 'snooze':
        final occurrence =
            (data['occurrences'] as List).firstWhere(
                  (item) => item['id'] == arguments['id'],
                )
                as Map;
        occurrence['status'] = 'snoozed';
        occurrence['nextAt'] = DateTime.now()
            .add(Duration(minutes: arguments['minutes'] as int))
            .millisecondsSinceEpoch;
        occurrence['plan']['occurrenceStatus'] = 'snoozed';
        return null;
      case 'emergencyClose':
        if (arguments['phrase'] != emergencyPledge) {
          throw PlatformException(code: 'wrong_oath');
        }
        if (arguments['password'] != '1234') {
          throw PlatformException(code: 'wrong_password');
        }
        (data['occurrences'] as List).removeWhere(
          (item) => item['id'] == arguments['id'],
        );
        return null;
      case 'answerMath':
        return {'correct': false, 'completed': false};
      case 'setPassword':
        (data['settings'] as Map)['hasPassword'] = true;
        return null;
      default:
        return null;
    }
  }
}
