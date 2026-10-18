import 'package:flutter/material.dart';

Map<String, dynamic> jsonMap(dynamic value) =>
    Map<String, dynamic>.from(value as Map);
int integer(dynamic value, [int fallback = 0]) =>
    (value as num?)?.toInt() ?? fallback;

class Reminder {
  final String id,
      title,
      note,
      category,
      mission,
      difficulty,
      qrValue,
      qrLabel,
      date;
  final int hour, minute, mathCount, snoozeMinutes, reviewMinutes;
  final bool enabled, repeating, reviewEnabled, vibrate;
  final List<int> days;
  final DateTime? nextAt;
  final String? occurrenceStatus;
  const Reminder({
    required this.id,
    required this.title,
    required this.note,
    required this.category,
    required this.mission,
    required this.difficulty,
    required this.qrValue,
    required this.qrLabel,
    required this.date,
    required this.hour,
    required this.minute,
    required this.mathCount,
    required this.snoozeMinutes,
    required this.reviewMinutes,
    required this.enabled,
    required this.repeating,
    required this.reviewEnabled,
    required this.vibrate,
    required this.days,
    this.nextAt,
    this.occurrenceStatus,
  });
  factory Reminder.fromJson(Map<String, dynamic> data) => Reminder(
    id: data['id'] as String,
    title: data['title'] as String,
    note: data['note'] as String? ?? '',
    category: data['category'] as String? ?? 'other',
    mission: data['mission'] as String? ?? 'math',
    difficulty: data['difficulty'] as String? ?? 'easy',
    qrValue: data['qrValue'] as String? ?? '',
    qrLabel: data['qrLabel'] as String? ?? '',
    date: data['date'] as String,
    hour: integer(data['hour']),
    minute: integer(data['minute']),
    mathCount: integer(data['mathCount'], 3),
    snoozeMinutes: integer(data['snoozeMinutes'], 10),
    reviewMinutes: integer(data['reviewMinutes'], 10),
    enabled: data['enabled'] == true,
    repeating: data['repeating'] == true,
    reviewEnabled: data['reviewEnabled'] == true,
    vibrate: data['vibrate'] != false,
    days: (data['days'] as List? ?? []).map((value) => integer(value)).toList(),
    nextAt: data['nextAt'] == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(integer(data['nextAt'])),
    occurrenceStatus: data['occurrenceStatus'] as String?,
  );
  bool get protected =>
      const ['ringing', 'snoozed', 'reviewPending'].contains(occurrenceStatus);
  TimeOfDay get time => TimeOfDay(hour: hour, minute: minute);
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'note': note,
    'category': category,
    'mission': mission,
    'difficulty': difficulty,
    'qrValue': qrValue,
    'qrLabel': qrLabel,
    'date': date,
    'hour': hour,
    'minute': minute,
    'mathCount': mathCount,
    'snoozeMinutes': snoozeMinutes,
    'reviewMinutes': reviewMinutes,
    'enabled': enabled,
    'repeating': repeating,
    'reviewEnabled': reviewEnabled,
    'vibrate': vibrate,
    'days': days,
  };
}

class Occurrence {
  final String id, planId, status;
  final Reminder plan;
  final DateTime nextAt;
  final bool isReview;
  final int snoozeCount;
  const Occurrence({
    required this.id,
    required this.planId,
    required this.status,
    required this.plan,
    required this.nextAt,
    required this.isReview,
    required this.snoozeCount,
  });
  factory Occurrence.fromJson(Map<String, dynamic> data) => Occurrence(
    id: data['id'] as String,
    planId: data['planId'] as String,
    status: data['status'] as String,
    plan: Reminder.fromJson(jsonMap(data['plan'])),
    nextAt: DateTime.fromMillisecondsSinceEpoch(integer(data['nextAt'])),
    isReview: data['isReview'] == true,
    snoozeCount: integer(data['snoozeCount']),
  );
  bool get canResolve => status == 'ringing' || status == 'snoozed';
}

class ActivityEvent {
  final String kind, title, category, occurrenceId;
  final DateTime at;
  final int? minutes;
  final bool isReview;
  const ActivityEvent({
    required this.kind,
    required this.title,
    required this.category,
    required this.occurrenceId,
    required this.at,
    required this.minutes,
    required this.isReview,
  });
  factory ActivityEvent.fromJson(Map<String, dynamic> data) => ActivityEvent(
    kind: data['kind'] as String,
    title: data['title'] as String,
    category: data['category'] as String,
    occurrenceId: data['occurrenceId'] as String,
    at: DateTime.fromMillisecondsSinceEpoch(integer(data['at'])),
    minutes: (data['minutes'] as num?)?.toInt(),
    isReview: data['isReview'] == true,
  );
}

class UserSettings {
  final String language, theme;
  final int defaultSnoozeMinutes;
  final bool hasPassword;
  const UserSettings({
    this.language = 'system',
    this.theme = 'system',
    this.defaultSnoozeMinutes = 10,
    this.hasPassword = false,
  });
  factory UserSettings.fromJson(Map<String, dynamic> data) => UserSettings(
    language: data['language'] as String? ?? 'system',
    theme: data['theme'] as String? ?? 'system',
    defaultSnoozeMinutes: integer(data['defaultSnoozeMinutes'], 10),
    hasPassword: data['hasPassword'] == true,
  );
  Locale? get locale => language == 'system' ? null : Locale(language);
  ThemeMode get themeMode => switch (theme) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };
}

class ReminderPermissions {
  final bool exact, notifications, fullScreen, battery;
  final int alarmVolume;
  const ReminderPermissions({
    required this.exact,
    required this.notifications,
    required this.fullScreen,
    required this.battery,
    required this.alarmVolume,
  });
  factory ReminderPermissions.fromJson(Map<String, dynamic> data) =>
      ReminderPermissions(
        exact: data['exact'] == true,
        notifications: data['notifications'] == true,
        fullScreen: data['fullScreen'] == true,
        battery: data['battery'] == true,
        alarmVolume: integer(data['alarmVolume']),
      );
  bool get ready => exact && notifications;
  bool get needsAttention => !ready || !fullScreen || alarmVolume == 0;
}

class AppSnapshot {
  final List<Reminder> plans;
  final List<Occurrence> occurrences;
  final List<ActivityEvent> history;
  final UserSettings settings;
  final ReminderPermissions permissions;
  final Map<String, int> weeklyStats;
  const AppSnapshot({
    required this.plans,
    required this.occurrences,
    required this.history,
    required this.settings,
    required this.permissions,
    this.weeklyStats = const {},
  });
  factory AppSnapshot.fromJson(Map<String, dynamic> data) => AppSnapshot(
    plans: (data['plans'] as List)
        .map((item) => Reminder.fromJson(jsonMap(item)))
        .toList(),
    occurrences:
        (data['occurrences'] as List)
            .map((item) => Occurrence.fromJson(jsonMap(item)))
            .toList()
          ..sort((a, b) {
            if (a.status == 'ringing' && b.status != 'ringing') return -1;
            if (b.status == 'ringing' && a.status != 'ringing') return 1;
            return a.nextAt.compareTo(b.nextAt);
          }),
    history: (data['history'] as List)
        .map((item) => ActivityEvent.fromJson(jsonMap(item)))
        .toList(),
    settings: UserSettings.fromJson(jsonMap(data['settings'])),
    permissions: ReminderPermissions.fromJson(jsonMap(data['permissions'])),
    weeklyStats:
        (data['weeklyStats'] == null
                ? <String, dynamic>{}
                : jsonMap(data['weeklyStats']))
            .map((key, value) => MapEntry(key, integer(value))),
  );
  Occurrence? occurrenceFor(String planId) {
    for (final item in occurrences) {
      if (item.planId == planId) return item;
    }
    return null;
  }
}
