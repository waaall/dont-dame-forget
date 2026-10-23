// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Don’t Forget';

  @override
  String get tagline => 'Small things deserve to be remembered.';

  @override
  String get reminders => 'Reminders';

  @override
  String get activity => 'Activity';

  @override
  String get settings => 'Settings';

  @override
  String get nextReminder => 'UP NEXT';

  @override
  String get nothingScheduled => 'Make room for your next reminder.';

  @override
  String get createReminder => 'New reminder';

  @override
  String get editReminder => 'Edit reminder';

  @override
  String get all => 'All';

  @override
  String get pending => 'Pending';

  @override
  String get plans => 'Reminders';

  @override
  String get noReminders => 'Start with one small thing';

  @override
  String get noRemindersBody =>
      'Wake up, hang the laundry, build a habit.\nDismiss a reminder by finishing its mission.';

  @override
  String get noPending => 'You’re all caught up';

  @override
  String get noPendingBody => 'Your next reminder will be here when it’s time.';

  @override
  String get quickStart => 'QUICK START';

  @override
  String get wakeUp => 'Wake up';

  @override
  String get laundry => 'Hang the laundry';

  @override
  String get drinkWater => 'Drink water';

  @override
  String get alarmCategory => 'Wake-up';

  @override
  String get todoCategory => 'To-do';

  @override
  String get habitCategory => 'Habit';

  @override
  String get otherCategory => 'Other';

  @override
  String get scheduled => 'Scheduled';

  @override
  String get ringing => 'Ringing';

  @override
  String get snoozed => 'Snoozed';

  @override
  String get reviewPending => 'Follow-up pending';

  @override
  String get disabled => 'Off';

  @override
  String get enabled => 'Enabled';

  @override
  String get once => 'Once';

  @override
  String get everyDay => 'Every day';

  @override
  String get weekdays => 'Weekdays';

  @override
  String get custom => 'Custom';

  @override
  String get mathMission => 'Solve math';

  @override
  String get qrMission => 'Scan a code';

  @override
  String get mathDescription =>
      'Solve a set of questions to bring your attention back.';

  @override
  String get qrDescription =>
      'Scan a registered QR code or barcode to get where you need to be.';

  @override
  String get nameLabel => 'What do you want to remember?';

  @override
  String get nameHint => 'e.g. Hang the clean laundry';

  @override
  String get noteLabel => 'A little context (optional)';

  @override
  String get category => 'Category';

  @override
  String get schedule => 'Schedule';

  @override
  String get date => 'Date';

  @override
  String get time => 'Time';

  @override
  String get repeat => 'Repeat';

  @override
  String get repeatDays => 'Repeat on';

  @override
  String get mission => 'Dismissal mission';

  @override
  String get difficulty => 'Difficulty';

  @override
  String get easy => 'Easy';

  @override
  String get medium => 'Medium';

  @override
  String get hard => 'Hard';

  @override
  String get questionCount => 'Questions';

  @override
  String get tryMission => 'Try a question';

  @override
  String get previewMission => 'Math preview';

  @override
  String get previewBody =>
      'This is practice. It won’t create or dismiss a reminder.';

  @override
  String get registerCode => 'Register a QR code / barcode';

  @override
  String get changeCode => 'Register another code';

  @override
  String get codeRegistered => 'Code registered';

  @override
  String get codeLabel => 'Location label';

  @override
  String get codeLabelHint => 'e.g. Code on the balcony rack';

  @override
  String get snooze => 'Snooze';

  @override
  String get snoozeDuration => 'Default snooze duration';

  @override
  String get snoozeHelp =>
      'Snooze as many times as you need. Only finishing the mission dismisses this reminder.';

  @override
  String get minutes => 'minutes';

  @override
  String get hours => 'hours';

  @override
  String get duration => 'Duration';

  @override
  String get customDuration => 'Custom duration';

  @override
  String get typicalDurations => 'Quick snooze';

  @override
  String get review => 'Follow up after completion';

  @override
  String get reviewHelp =>
      'Remind you once more after completion, using the same mission.';

  @override
  String get reviewDuration => 'Follow-up interval';

  @override
  String get vibrate => 'Vibrate while ringing';

  @override
  String get save => 'Save reminder';

  @override
  String get saveChanges => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get done => 'Done';

  @override
  String get delete => 'Delete reminder';

  @override
  String get deleteTitle => 'Delete this reminder?';

  @override
  String get deleteBody =>
      'The reminder will be removed. Its activity history will stay.';

  @override
  String get saved => 'Reminder scheduled';

  @override
  String get deleted => 'Reminder deleted';

  @override
  String get language => 'Language';

  @override
  String get system => 'System';

  @override
  String get chinese => '简体中文';

  @override
  String get english => 'English';

  @override
  String get appearance => 'Appearance';

  @override
  String get light => 'Light';

  @override
  String get dark => 'Dark';

  @override
  String get preferences => 'PREFERENCES';

  @override
  String get emergency => 'Emergency dismissal';

  @override
  String get emergencyPassword => 'Emergency password';

  @override
  String get passwordNotSet => 'Not set';

  @override
  String get passwordSet => 'Configured';

  @override
  String get passwordIntro =>
      'To bypass a mission, type the exact pledge and your password.';

  @override
  String get setPassword => 'Set emergency password';

  @override
  String get changePassword => 'Change emergency password';

  @override
  String get currentPassword => 'Current password';

  @override
  String get newPassword => 'New password';

  @override
  String get repeatPassword => 'Confirm new password';

  @override
  String get passwordHint => '4–128 characters. Keep it somewhere safe.';

  @override
  String get passwordSaved => 'Emergency password saved';

  @override
  String get passwordSetupBody =>
      'Set an emergency password before your first reminder, so you can dismiss it if scanning becomes unavailable.';

  @override
  String get pledgeLabel => 'Type the exact pledge below';

  @override
  String get password => 'Password';

  @override
  String get confirmEmergency => 'Verify and dismiss this reminder';

  @override
  String get emergencyHelp =>
      'This occurrence will be recorded as skipped, with no follow-up. Repeating reminders stay enabled.';

  @override
  String get reliability => 'Reminder reliability';

  @override
  String get reliabilityIntro =>
      'These system settings affect whether reminders reach you on time.';

  @override
  String get exactPermission => 'Exact alarms';

  @override
  String get exactHelp => 'Allow reminders to trigger at the time you choose.';

  @override
  String get notificationPermission => 'Notifications';

  @override
  String get notificationHelp =>
      'Show ringing reminders and a way to open their missions.';

  @override
  String get fullScreenPermission => 'Full-screen alarms';

  @override
  String get fullScreenHelp =>
      'Allow full-screen alarms on the lock screen. While using your phone, Android may show a banner.';

  @override
  String get batteryPermission => 'Background battery limits';

  @override
  String get batteryHelp =>
      'Allow unrestricted battery use and remove this app from deep sleeping apps.';

  @override
  String get soundSettings => 'Alarm volume & sound';

  @override
  String get soundHelp =>
      'Set sound for each reminder. The system alarm volume still limits loudness.';

  @override
  String get allowed => 'Allowed';

  @override
  String get needsAttention => 'Needs attention';

  @override
  String get recommended => 'Recommended';

  @override
  String get openSettings => 'Open system settings';

  @override
  String get setupTitle => 'Help reminders reach you';

  @override
  String get setupBody =>
      'Check reminder permissions before scheduling your first reminder.';

  @override
  String get setupPassword => 'Set your emergency password';

  @override
  String get localPrivacy => 'Your data stays on this phone';

  @override
  String get localPrivacyBody =>
      'Works offline. No account, cloud sync, or ads.';

  @override
  String get about => 'ABOUT';

  @override
  String get version => 'Version 0.1.0 · Android';

  @override
  String get activityTitle => 'A little record of showing up.';

  @override
  String get lastSevenDays => 'LAST 7 DAYS';

  @override
  String get completed => 'Completed';

  @override
  String get snoozes => 'Snoozes';

  @override
  String get skipped => 'Skipped';

  @override
  String get recentActivity => 'RECENT ACTIVITY';

  @override
  String get noActivity => 'No activity yet';

  @override
  String get noActivityBody =>
      'Ringing, snoozing and completing reminders will appear here.';

  @override
  String get eventRinging => 'Reminder rang';

  @override
  String get eventCompleted => 'Mission completed';

  @override
  String get eventSnoozed => 'Reminder snoozed';

  @override
  String get eventReview => 'Mission completed; follow-up scheduled';

  @override
  String get eventSkipped => 'Dismissed with password and pledge';

  @override
  String get eventSound => 'Ringtone unavailable; switched to a fallback sound';

  @override
  String get timeToAct => 'TIME TO ACT';

  @override
  String get reviewTime => 'ONE MORE CHECK';

  @override
  String get missionRequired => 'Finish the mission to dismiss this reminder';

  @override
  String get snoozedMission =>
      'You can finish the mission now instead of waiting.';

  @override
  String get answerHint => 'Your answer';

  @override
  String get checkAnswer => 'Check answer';

  @override
  String get wrongAnswer => 'That’s not quite right. Try again.';

  @override
  String get correctAnswer => 'Correct. On to the next one.';

  @override
  String get startScanning => 'Scan your code';

  @override
  String get missionCompleted => 'Reminder completed';

  @override
  String get followUpScheduled =>
      'Mission completed. A follow-up is scheduled.';

  @override
  String get emergencyCompleted => 'Reminder dismissed and recorded as skipped';

  @override
  String get holdHint =>
      'Hold to snooze. Releasing won’t dismiss the reminder.';

  @override
  String get scanTitle => 'Scan a QR code / barcode';

  @override
  String get scanHelp =>
      'Place the code in the frame. It will be detected automatically.';

  @override
  String get cameraDenied => 'Camera permission is needed to scan';

  @override
  String get cameraError =>
      'Camera unavailable. Check its permission and try again.';

  @override
  String get torch => 'Flashlight';

  @override
  String get retry => 'Retry';

  @override
  String get close => 'Back';

  @override
  String get loading => 'Loading…';

  @override
  String get startupFailed => 'Couldn’t load your reminders';

  @override
  String get startupHelp =>
      'Please try again. Your data won’t be cleared to fix this.';

  @override
  String get errorDetails => 'Error details';

  @override
  String get errorGeneric => 'That didn’t work. Please try again.';

  @override
  String get errorStorage =>
      'Couldn’t read or save reminders. Please try again.';

  @override
  String get errorTitle => 'Enter a reminder name.';

  @override
  String get errorDuration => 'Enter a duration between 1 and 1,440 minutes.';

  @override
  String get errorPast => 'Choose a reminder time in the future.';

  @override
  String get errorDays => 'Choose at least one day.';

  @override
  String get errorQrRequired => 'Register the code you want to scan first.';

  @override
  String get errorWrongQr => 'That isn’t the registered code. Keep scanning.';

  @override
  String get errorPassword => 'Incorrect password.';

  @override
  String get errorPasswordLength => 'Use a password with 4–128 characters.';

  @override
  String get errorPasswordMatch => 'The passwords don’t match.';

  @override
  String get errorOath => 'Type the pledge exactly as shown.';

  @override
  String get errorActive =>
      'This reminder is still active. Finish its mission or use emergency dismissal.';

  @override
  String get errorNotActive =>
      'This reminder has changed. Go back to see its current state.';

  @override
  String get errorExact => 'Allow exact alarms first.';

  @override
  String get errorNotifications =>
      'Enable app notifications and the mission reminder channel first.';

  @override
  String get errorStale => 'The question has changed. Please try again.';

  @override
  String get chooseDuration => 'Choose a snooze duration';

  @override
  String get tomorrow => 'Tomorrow';

  @override
  String get today => 'Today';

  @override
  String get waitingReview => 'Your follow-up is scheduled';

  @override
  String get activeLocked => 'Resolve the active reminder first';

  @override
  String get practiceCorrect => 'That’s right!';

  @override
  String get practiceAnswer => 'Answer';

  @override
  String get quickTest => 'Test reminder in 30 seconds';

  @override
  String get testReminderName => 'Test reminder';

  @override
  String get testScheduled =>
      'A test reminder will ring in 30 seconds. Lock your phone to check it.';

  @override
  String minutesLabel(int count) {
    return '$count min';
  }

  @override
  String hoursLabel(int count) {
    return '$count hr';
  }

  @override
  String holdSnooze(String duration) {
    return 'Hold to snooze · $duration';
  }

  @override
  String mathProgress(int done, int total) {
    return '$done of $total complete';
  }

  @override
  String reviewAfter(String duration) {
    return 'Follow up $duration after completion';
  }

  @override
  String nextIn(String duration) {
    return 'In $duration';
  }

  @override
  String get soundAndVibration => 'Sound and vibration';

  @override
  String get alarmSound => 'Alarm sound';

  @override
  String get systemDefaultSound => 'System default alarm sound';

  @override
  String get selectedSound => 'Selected system ringtone';

  @override
  String get useDefaultSound => 'Use system default sound';

  @override
  String reminderVolume(int volume) {
    return 'Reminder volume: $volume%';
  }

  @override
  String get volumeLimitHelp =>
      'Adjust loudness within the system alarm volume. 100% uses the current system level.';

  @override
  String get alarmVolumeZero =>
      'System alarm volume is zero. Raise it and preview to make sure you can hear the alarm.';

  @override
  String get fadeIn => 'Gradually increase volume';

  @override
  String get fadeOff => 'Off';

  @override
  String soundSeconds(int seconds) {
    return '$seconds sec';
  }

  @override
  String get previewSound => 'Preview sound';

  @override
  String get stopSoundPreview => 'Stop preview';

  @override
  String get soundPreviewHelp =>
      'Uses these volume and fade settings, then stops automatically. Leaving this page or a real alarm stops the preview.';

  @override
  String get soundFallbackHelp =>
      'The selected ringtone is unavailable. A fallback sound is playing. Choose another ringtone.';

  @override
  String get errorSound =>
      'Sound settings are unavailable. Choose the ringtone and volume again.';

  @override
  String get errorSoundPicker =>
      'The system ringtone picker is unavailable. You can use the default sound.';

  @override
  String get errorSoundDuringAlarm =>
      'Resolve the ringing reminder before previewing a sound.';

  @override
  String alarmVolume(int volume) {
    return 'System alarm volume step: $volume';
  }
}
