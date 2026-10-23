import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../domain/models.dart';
import '../l10n/app_localizations.dart';

extension AppStrings on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
  String durationLabel(int minutes) => minutes % 60 == 0
      ? l10n.hoursLabel(minutes ~/ 60)
      : l10n.minutesLabel(minutes);
  String categoryLabel(String category) => switch (category) {
    'alarm' => l10n.alarmCategory,
    'todo' => l10n.todoCategory,
    'habit' => l10n.habitCategory,
    _ => l10n.otherCategory,
  };
  String statusLabel(String? status) => switch (status) {
    'ringing' => l10n.ringing,
    'snoozed' => l10n.snoozed,
    'reviewPending' => l10n.reviewPending,
    'scheduled' => l10n.scheduled,
    _ => l10n.disabled,
  };
  String repeatLabel(Reminder plan) {
    if (!plan.repeating) return l10n.once;
    if (plan.days.length == 7) return l10n.everyDay;
    if (plan.days.length == 5 && plan.days.every((day) => day <= 5)) {
      return l10n.weekdays;
    }
    final locale = Localizations.localeOf(this).toLanguageTag();
    return plan.days
        .map(
          (day) =>
              DateFormat.E(locale).format(DateTime(2026, 10, 12 + day - 1)),
        )
        .join(' · ');
  }

  String scheduledLabel(DateTime time) {
    final now = DateTime.now();
    final day = DateTime(time.year, time.month, time.day);
    final today = DateTime(now.year, now.month, now.day);
    final prefix = day == today
        ? l10n.today
        : day == today.add(const Duration(days: 1))
        ? l10n.tomorrow
        : DateFormat.MMMd(
            Localizations.localeOf(this).toLanguageTag(),
          ).format(time);
    return '$prefix ${DateFormat.Hm().format(time)}';
  }

  String errorLabel(Object error) {
    final code = error is PlatformException ? error.code : '';
    return switch (code) {
      'invalid_title' => l10n.errorTitle,
      'invalid_duration' => l10n.errorDuration,
      'past_time' => l10n.errorPast,
      'invalid_days' => l10n.errorDays,
      'qr_required' => l10n.errorQrRequired,
      'wrong_qr' => l10n.errorWrongQr,
      'wrong_password' => l10n.errorPassword,
      'invalid_password' => l10n.errorPasswordLength,
      'wrong_oath' => l10n.errorOath,
      'active_locked' => l10n.errorActive,
      'not_active' || 'not_found' => l10n.errorNotActive,
      'exact_required' => l10n.errorExact,
      'notifications_required' => l10n.errorNotifications,
      'password_required' => l10n.passwordSetupBody,
      'stale_question' => l10n.errorStale,
      'storage_error' => l10n.errorStorage,
      'invalid_sound' => l10n.errorSound,
      'sound_picker_unavailable' ||
      'sound_picker_busy' => l10n.errorSoundPicker,
      'alarm_ringing' => l10n.errorSoundDuringAlarm,
      _ => l10n.errorGeneric,
    };
  }

  void message(String text, {bool error = false}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: error ? Theme.of(this).colorScheme.error : null,
      ),
    );
  }
}

IconData categoryIcon(String category) => switch (category) {
  'alarm' => Icons.wb_sunny_outlined,
  'todo' => Icons.checklist_rounded,
  'habit' => Icons.spa_outlined,
  _ => Icons.notifications_none_rounded,
};
