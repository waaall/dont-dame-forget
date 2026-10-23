import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// No description provided for @appName.
  ///
  /// In zh, this message translates to:
  /// **'别忘了'**
  String get appName;

  /// No description provided for @tagline.
  ///
  /// In zh, this message translates to:
  /// **'重要的小事，也值得被记住。'**
  String get tagline;

  /// No description provided for @reminders.
  ///
  /// In zh, this message translates to:
  /// **'提醒'**
  String get reminders;

  /// No description provided for @activity.
  ///
  /// In zh, this message translates to:
  /// **'记录'**
  String get activity;

  /// No description provided for @settings.
  ///
  /// In zh, this message translates to:
  /// **'设置'**
  String get settings;

  /// No description provided for @nextReminder.
  ///
  /// In zh, this message translates to:
  /// **'下一次提醒'**
  String get nextReminder;

  /// No description provided for @nothingScheduled.
  ///
  /// In zh, this message translates to:
  /// **'把下一件事，交给提醒。'**
  String get nothingScheduled;

  /// No description provided for @createReminder.
  ///
  /// In zh, this message translates to:
  /// **'新建提醒'**
  String get createReminder;

  /// No description provided for @editReminder.
  ///
  /// In zh, this message translates to:
  /// **'编辑提醒'**
  String get editReminder;

  /// No description provided for @all.
  ///
  /// In zh, this message translates to:
  /// **'全部'**
  String get all;

  /// No description provided for @pending.
  ///
  /// In zh, this message translates to:
  /// **'待处理'**
  String get pending;

  /// No description provided for @plans.
  ///
  /// In zh, this message translates to:
  /// **'提醒计划'**
  String get plans;

  /// No description provided for @noReminders.
  ///
  /// In zh, this message translates to:
  /// **'从一件小事开始'**
  String get noReminders;

  /// No description provided for @noRemindersBody.
  ///
  /// In zh, this message translates to:
  /// **'起床、晾衣服、养成习惯。\n设好提醒，完成任务后再解除。'**
  String get noRemindersBody;

  /// No description provided for @noPending.
  ///
  /// In zh, this message translates to:
  /// **'现在没有待处理的提醒'**
  String get noPending;

  /// No description provided for @noPendingBody.
  ///
  /// In zh, this message translates to:
  /// **'下一次需要行动时，我们会提醒你。'**
  String get noPendingBody;

  /// No description provided for @quickStart.
  ///
  /// In zh, this message translates to:
  /// **'快速开始'**
  String get quickStart;

  /// No description provided for @wakeUp.
  ///
  /// In zh, this message translates to:
  /// **'起床'**
  String get wakeUp;

  /// No description provided for @laundry.
  ///
  /// In zh, this message translates to:
  /// **'晾衣服'**
  String get laundry;

  /// No description provided for @drinkWater.
  ///
  /// In zh, this message translates to:
  /// **'喝水'**
  String get drinkWater;

  /// No description provided for @alarmCategory.
  ///
  /// In zh, this message translates to:
  /// **'起床'**
  String get alarmCategory;

  /// No description provided for @todoCategory.
  ///
  /// In zh, this message translates to:
  /// **'待办'**
  String get todoCategory;

  /// No description provided for @habitCategory.
  ///
  /// In zh, this message translates to:
  /// **'习惯'**
  String get habitCategory;

  /// No description provided for @otherCategory.
  ///
  /// In zh, this message translates to:
  /// **'其他'**
  String get otherCategory;

  /// No description provided for @scheduled.
  ///
  /// In zh, this message translates to:
  /// **'已安排'**
  String get scheduled;

  /// No description provided for @ringing.
  ///
  /// In zh, this message translates to:
  /// **'正在提醒'**
  String get ringing;

  /// No description provided for @snoozed.
  ///
  /// In zh, this message translates to:
  /// **'已推迟'**
  String get snoozed;

  /// No description provided for @reviewPending.
  ///
  /// In zh, this message translates to:
  /// **'等待复查'**
  String get reviewPending;

  /// No description provided for @disabled.
  ///
  /// In zh, this message translates to:
  /// **'已关闭'**
  String get disabled;

  /// No description provided for @enabled.
  ///
  /// In zh, this message translates to:
  /// **'启用'**
  String get enabled;

  /// No description provided for @once.
  ///
  /// In zh, this message translates to:
  /// **'仅一次'**
  String get once;

  /// No description provided for @everyDay.
  ///
  /// In zh, this message translates to:
  /// **'每天'**
  String get everyDay;

  /// No description provided for @weekdays.
  ///
  /// In zh, this message translates to:
  /// **'工作日'**
  String get weekdays;

  /// No description provided for @custom.
  ///
  /// In zh, this message translates to:
  /// **'自定义'**
  String get custom;

  /// No description provided for @mathMission.
  ///
  /// In zh, this message translates to:
  /// **'算题解除'**
  String get mathMission;

  /// No description provided for @qrMission.
  ///
  /// In zh, this message translates to:
  /// **'指定扫码'**
  String get qrMission;

  /// No description provided for @mathDescription.
  ///
  /// In zh, this message translates to:
  /// **'完成设定数量的算术题，唤醒注意力。'**
  String get mathDescription;

  /// No description provided for @qrDescription.
  ///
  /// In zh, this message translates to:
  /// **'扫描提前登记的二维码或条形码，走到该去的地方。'**
  String get qrDescription;

  /// No description provided for @nameLabel.
  ///
  /// In zh, this message translates to:
  /// **'提醒什么？'**
  String get nameLabel;

  /// No description provided for @nameHint.
  ///
  /// In zh, this message translates to:
  /// **'例如：把洗好的衣服晾起来'**
  String get nameHint;

  /// No description provided for @noteLabel.
  ///
  /// In zh, this message translates to:
  /// **'补充说明（可选）'**
  String get noteLabel;

  /// No description provided for @category.
  ///
  /// In zh, this message translates to:
  /// **'场景'**
  String get category;

  /// No description provided for @schedule.
  ///
  /// In zh, this message translates to:
  /// **'提醒时间'**
  String get schedule;

  /// No description provided for @date.
  ///
  /// In zh, this message translates to:
  /// **'日期'**
  String get date;

  /// No description provided for @time.
  ///
  /// In zh, this message translates to:
  /// **'时间'**
  String get time;

  /// No description provided for @repeat.
  ///
  /// In zh, this message translates to:
  /// **'重复'**
  String get repeat;

  /// No description provided for @repeatDays.
  ///
  /// In zh, this message translates to:
  /// **'重复日期'**
  String get repeatDays;

  /// No description provided for @mission.
  ///
  /// In zh, this message translates to:
  /// **'解除方式'**
  String get mission;

  /// No description provided for @difficulty.
  ///
  /// In zh, this message translates to:
  /// **'算题难度'**
  String get difficulty;

  /// No description provided for @easy.
  ///
  /// In zh, this message translates to:
  /// **'简单'**
  String get easy;

  /// No description provided for @medium.
  ///
  /// In zh, this message translates to:
  /// **'适中'**
  String get medium;

  /// No description provided for @hard.
  ///
  /// In zh, this message translates to:
  /// **'较难'**
  String get hard;

  /// No description provided for @questionCount.
  ///
  /// In zh, this message translates to:
  /// **'题目数量'**
  String get questionCount;

  /// No description provided for @tryMission.
  ///
  /// In zh, this message translates to:
  /// **'试做一道'**
  String get tryMission;

  /// No description provided for @previewMission.
  ///
  /// In zh, this message translates to:
  /// **'算题预览'**
  String get previewMission;

  /// No description provided for @previewBody.
  ///
  /// In zh, this message translates to:
  /// **'这是练习，不会创建或解除提醒。'**
  String get previewBody;

  /// No description provided for @registerCode.
  ///
  /// In zh, this message translates to:
  /// **'登记二维码 / 条形码'**
  String get registerCode;

  /// No description provided for @changeCode.
  ///
  /// In zh, this message translates to:
  /// **'重新登记'**
  String get changeCode;

  /// No description provided for @codeRegistered.
  ///
  /// In zh, this message translates to:
  /// **'已登记指定码'**
  String get codeRegistered;

  /// No description provided for @codeLabel.
  ///
  /// In zh, this message translates to:
  /// **'位置备注'**
  String get codeLabel;

  /// No description provided for @codeLabelHint.
  ///
  /// In zh, this message translates to:
  /// **'例如：阳台衣架上的二维码'**
  String get codeLabelHint;

  /// No description provided for @snooze.
  ///
  /// In zh, this message translates to:
  /// **'推迟'**
  String get snooze;

  /// No description provided for @snoozeDuration.
  ///
  /// In zh, this message translates to:
  /// **'默认推迟时长'**
  String get snoozeDuration;

  /// No description provided for @snoozeHelp.
  ///
  /// In zh, this message translates to:
  /// **'可无限次推迟。只有完成解除任务，才会结束本次提醒。'**
  String get snoozeHelp;

  /// No description provided for @minutes.
  ///
  /// In zh, this message translates to:
  /// **'分钟'**
  String get minutes;

  /// No description provided for @hours.
  ///
  /// In zh, this message translates to:
  /// **'小时'**
  String get hours;

  /// No description provided for @duration.
  ///
  /// In zh, this message translates to:
  /// **'时长'**
  String get duration;

  /// No description provided for @customDuration.
  ///
  /// In zh, this message translates to:
  /// **'自定义时长'**
  String get customDuration;

  /// No description provided for @typicalDurations.
  ///
  /// In zh, this message translates to:
  /// **'快捷推迟'**
  String get typicalDurations;

  /// No description provided for @review.
  ///
  /// In zh, this message translates to:
  /// **'完成后复查'**
  String get review;

  /// No description provided for @reviewHelp.
  ///
  /// In zh, this message translates to:
  /// **'解除后再提醒一次，仍需完成原来的任务。'**
  String get reviewHelp;

  /// No description provided for @reviewDuration.
  ///
  /// In zh, this message translates to:
  /// **'复查间隔'**
  String get reviewDuration;

  /// No description provided for @vibrate.
  ///
  /// In zh, this message translates to:
  /// **'响铃时振动'**
  String get vibrate;

  /// No description provided for @save.
  ///
  /// In zh, this message translates to:
  /// **'保存提醒'**
  String get save;

  /// No description provided for @saveChanges.
  ///
  /// In zh, this message translates to:
  /// **'保存'**
  String get saveChanges;

  /// No description provided for @cancel.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get cancel;

  /// No description provided for @done.
  ///
  /// In zh, this message translates to:
  /// **'完成'**
  String get done;

  /// No description provided for @delete.
  ///
  /// In zh, this message translates to:
  /// **'删除提醒'**
  String get delete;

  /// No description provided for @deleteTitle.
  ///
  /// In zh, this message translates to:
  /// **'删除这个提醒？'**
  String get deleteTitle;

  /// No description provided for @deleteBody.
  ///
  /// In zh, this message translates to:
  /// **'未触发的提醒将被移除，已有记录会保留。'**
  String get deleteBody;

  /// No description provided for @saved.
  ///
  /// In zh, this message translates to:
  /// **'提醒已安排'**
  String get saved;

  /// No description provided for @deleted.
  ///
  /// In zh, this message translates to:
  /// **'提醒已删除'**
  String get deleted;

  /// No description provided for @language.
  ///
  /// In zh, this message translates to:
  /// **'显示语言'**
  String get language;

  /// No description provided for @system.
  ///
  /// In zh, this message translates to:
  /// **'跟随系统'**
  String get system;

  /// No description provided for @chinese.
  ///
  /// In zh, this message translates to:
  /// **'简体中文'**
  String get chinese;

  /// No description provided for @english.
  ///
  /// In zh, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @appearance.
  ///
  /// In zh, this message translates to:
  /// **'外观'**
  String get appearance;

  /// No description provided for @light.
  ///
  /// In zh, this message translates to:
  /// **'浅色'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In zh, this message translates to:
  /// **'深色'**
  String get dark;

  /// No description provided for @preferences.
  ///
  /// In zh, this message translates to:
  /// **'偏好设置'**
  String get preferences;

  /// No description provided for @emergency.
  ///
  /// In zh, this message translates to:
  /// **'应急关闭'**
  String get emergency;

  /// No description provided for @emergencyPassword.
  ///
  /// In zh, this message translates to:
  /// **'应急密码'**
  String get emergencyPassword;

  /// No description provided for @passwordNotSet.
  ///
  /// In zh, this message translates to:
  /// **'尚未设置'**
  String get passwordNotSet;

  /// No description provided for @passwordSet.
  ///
  /// In zh, this message translates to:
  /// **'已设置'**
  String get passwordSet;

  /// No description provided for @passwordIntro.
  ///
  /// In zh, this message translates to:
  /// **'需要绕过解除任务时，输入指定誓词和密码。'**
  String get passwordIntro;

  /// No description provided for @setPassword.
  ///
  /// In zh, this message translates to:
  /// **'设置应急密码'**
  String get setPassword;

  /// No description provided for @changePassword.
  ///
  /// In zh, this message translates to:
  /// **'修改应急密码'**
  String get changePassword;

  /// No description provided for @currentPassword.
  ///
  /// In zh, this message translates to:
  /// **'当前密码'**
  String get currentPassword;

  /// No description provided for @newPassword.
  ///
  /// In zh, this message translates to:
  /// **'新密码'**
  String get newPassword;

  /// No description provided for @repeatPassword.
  ///
  /// In zh, this message translates to:
  /// **'再次输入新密码'**
  String get repeatPassword;

  /// No description provided for @passwordHint.
  ///
  /// In zh, this message translates to:
  /// **'4–128 个字符，请牢记'**
  String get passwordHint;

  /// No description provided for @passwordSaved.
  ///
  /// In zh, this message translates to:
  /// **'应急密码已保存'**
  String get passwordSaved;

  /// No description provided for @passwordSetupBody.
  ///
  /// In zh, this message translates to:
  /// **'创建第一个提醒前，先设置应急密码，以便在扫码失效等情况下解除。'**
  String get passwordSetupBody;

  /// No description provided for @pledgeLabel.
  ///
  /// In zh, this message translates to:
  /// **'逐字输入下面的誓词'**
  String get pledgeLabel;

  /// No description provided for @password.
  ///
  /// In zh, this message translates to:
  /// **'密码'**
  String get password;

  /// No description provided for @confirmEmergency.
  ///
  /// In zh, this message translates to:
  /// **'验证并关闭本次提醒'**
  String get confirmEmergency;

  /// No description provided for @emergencyHelp.
  ///
  /// In zh, this message translates to:
  /// **'本次将记录为“应急跳过”，不会继续复查；重复计划保留。'**
  String get emergencyHelp;

  /// No description provided for @reliability.
  ///
  /// In zh, this message translates to:
  /// **'提醒保障'**
  String get reliability;

  /// No description provided for @reliabilityIntro.
  ///
  /// In zh, this message translates to:
  /// **'这些系统设置会影响提醒能否按时响起。'**
  String get reliabilityIntro;

  /// No description provided for @exactPermission.
  ///
  /// In zh, this message translates to:
  /// **'精确闹钟'**
  String get exactPermission;

  /// No description provided for @exactHelp.
  ///
  /// In zh, this message translates to:
  /// **'允许在指定时间触发提醒。'**
  String get exactHelp;

  /// No description provided for @notificationPermission.
  ///
  /// In zh, this message translates to:
  /// **'通知'**
  String get notificationPermission;

  /// No description provided for @notificationHelp.
  ///
  /// In zh, this message translates to:
  /// **'显示正在响铃的提醒和进入任务的入口。'**
  String get notificationHelp;

  /// No description provided for @fullScreenPermission.
  ///
  /// In zh, this message translates to:
  /// **'锁屏全屏提醒'**
  String get fullScreenPermission;

  /// No description provided for @fullScreenHelp.
  ///
  /// In zh, this message translates to:
  /// **'允许锁屏时显示提醒；正在使用手机时，系统可能显示横幅。'**
  String get fullScreenHelp;

  /// No description provided for @batteryPermission.
  ///
  /// In zh, this message translates to:
  /// **'后台电池限制'**
  String get batteryPermission;

  /// No description provided for @batteryHelp.
  ///
  /// In zh, this message translates to:
  /// **'建议将本应用设为不受限制，并移出深度休眠应用名单。'**
  String get batteryHelp;

  /// No description provided for @soundSettings.
  ///
  /// In zh, this message translates to:
  /// **'闹钟音量与铃声'**
  String get soundSettings;

  /// No description provided for @soundHelp.
  ///
  /// In zh, this message translates to:
  /// **'每条提醒可单独设置声音。实际响度仍受系统闹钟音量限制。'**
  String get soundHelp;

  /// No description provided for @allowed.
  ///
  /// In zh, this message translates to:
  /// **'已开启'**
  String get allowed;

  /// No description provided for @needsAttention.
  ///
  /// In zh, this message translates to:
  /// **'需要设置'**
  String get needsAttention;

  /// No description provided for @recommended.
  ///
  /// In zh, this message translates to:
  /// **'建议设置'**
  String get recommended;

  /// No description provided for @openSettings.
  ///
  /// In zh, this message translates to:
  /// **'打开系统设置'**
  String get openSettings;

  /// No description provided for @setupTitle.
  ///
  /// In zh, this message translates to:
  /// **'让提醒准时到达'**
  String get setupTitle;

  /// No description provided for @setupBody.
  ///
  /// In zh, this message translates to:
  /// **'先完成提醒保障设置，再安排你的第一件事。'**
  String get setupBody;

  /// No description provided for @setupPassword.
  ///
  /// In zh, this message translates to:
  /// **'先设置应急密码'**
  String get setupPassword;

  /// No description provided for @localPrivacy.
  ///
  /// In zh, this message translates to:
  /// **'数据留在这台手机'**
  String get localPrivacy;

  /// No description provided for @localPrivacyBody.
  ///
  /// In zh, this message translates to:
  /// **'离线可用，无账号、无云同步、无广告。'**
  String get localPrivacyBody;

  /// No description provided for @about.
  ///
  /// In zh, this message translates to:
  /// **'关于'**
  String get about;

  /// No description provided for @version.
  ///
  /// In zh, this message translates to:
  /// **'版本 0.1.0 · Android'**
  String get version;

  /// No description provided for @activityTitle.
  ///
  /// In zh, this message translates to:
  /// **'每一次行动，都有迹可循。'**
  String get activityTitle;

  /// No description provided for @lastSevenDays.
  ///
  /// In zh, this message translates to:
  /// **'最近 7 天'**
  String get lastSevenDays;

  /// No description provided for @completed.
  ///
  /// In zh, this message translates to:
  /// **'已完成'**
  String get completed;

  /// No description provided for @snoozes.
  ///
  /// In zh, this message translates to:
  /// **'推迟'**
  String get snoozes;

  /// No description provided for @skipped.
  ///
  /// In zh, this message translates to:
  /// **'应急跳过'**
  String get skipped;

  /// No description provided for @recentActivity.
  ///
  /// In zh, this message translates to:
  /// **'最近记录'**
  String get recentActivity;

  /// No description provided for @noActivity.
  ///
  /// In zh, this message translates to:
  /// **'还没有提醒记录'**
  String get noActivity;

  /// No description provided for @noActivityBody.
  ///
  /// In zh, this message translates to:
  /// **'提醒响起、推迟和完成后，都会记录在这里。'**
  String get noActivityBody;

  /// No description provided for @eventRinging.
  ///
  /// In zh, this message translates to:
  /// **'提醒响起'**
  String get eventRinging;

  /// No description provided for @eventCompleted.
  ///
  /// In zh, this message translates to:
  /// **'完成解除任务'**
  String get eventCompleted;

  /// No description provided for @eventSnoozed.
  ///
  /// In zh, this message translates to:
  /// **'推迟提醒'**
  String get eventSnoozed;

  /// No description provided for @eventReview.
  ///
  /// In zh, this message translates to:
  /// **'任务完成，等待复查'**
  String get eventReview;

  /// No description provided for @eventSkipped.
  ///
  /// In zh, this message translates to:
  /// **'通过密码和誓词应急关闭'**
  String get eventSkipped;

  /// No description provided for @eventSound.
  ///
  /// In zh, this message translates to:
  /// **'铃声不可用，已切换备用声音'**
  String get eventSound;

  /// No description provided for @timeToAct.
  ///
  /// In zh, this message translates to:
  /// **'该行动了'**
  String get timeToAct;

  /// No description provided for @reviewTime.
  ///
  /// In zh, this message translates to:
  /// **'再确认一下'**
  String get reviewTime;

  /// No description provided for @missionRequired.
  ///
  /// In zh, this message translates to:
  /// **'完成任务，解除本次提醒'**
  String get missionRequired;

  /// No description provided for @snoozedMission.
  ///
  /// In zh, this message translates to:
  /// **'也可以现在完成任务，提前解除。'**
  String get snoozedMission;

  /// No description provided for @answerHint.
  ///
  /// In zh, this message translates to:
  /// **'输入答案'**
  String get answerHint;

  /// No description provided for @checkAnswer.
  ///
  /// In zh, this message translates to:
  /// **'确认答案'**
  String get checkAnswer;

  /// No description provided for @wrongAnswer.
  ///
  /// In zh, this message translates to:
  /// **'答案不对，再试一次。'**
  String get wrongAnswer;

  /// No description provided for @correctAnswer.
  ///
  /// In zh, this message translates to:
  /// **'答对了，继续下一题。'**
  String get correctAnswer;

  /// No description provided for @startScanning.
  ///
  /// In zh, this message translates to:
  /// **'扫描指定码'**
  String get startScanning;

  /// No description provided for @missionCompleted.
  ///
  /// In zh, this message translates to:
  /// **'本次提醒已完成'**
  String get missionCompleted;

  /// No description provided for @followUpScheduled.
  ///
  /// In zh, this message translates to:
  /// **'已完成任务，稍后会再次复查'**
  String get followUpScheduled;

  /// No description provided for @emergencyCompleted.
  ///
  /// In zh, this message translates to:
  /// **'已应急关闭本次提醒'**
  String get emergencyCompleted;

  /// No description provided for @holdHint.
  ///
  /// In zh, this message translates to:
  /// **'长按推迟，松手不会解除提醒'**
  String get holdHint;

  /// No description provided for @scanTitle.
  ///
  /// In zh, this message translates to:
  /// **'扫描二维码 / 条形码'**
  String get scanTitle;

  /// No description provided for @scanHelp.
  ///
  /// In zh, this message translates to:
  /// **'将码放入取景框，识别后自动确认。'**
  String get scanHelp;

  /// No description provided for @cameraDenied.
  ///
  /// In zh, this message translates to:
  /// **'需要相机权限才能扫码'**
  String get cameraDenied;

  /// No description provided for @cameraError.
  ///
  /// In zh, this message translates to:
  /// **'相机暂时不可用，请检查权限后重试。'**
  String get cameraError;

  /// No description provided for @torch.
  ///
  /// In zh, this message translates to:
  /// **'手电筒'**
  String get torch;

  /// No description provided for @retry.
  ///
  /// In zh, this message translates to:
  /// **'重试'**
  String get retry;

  /// No description provided for @close.
  ///
  /// In zh, this message translates to:
  /// **'返回'**
  String get close;

  /// No description provided for @loading.
  ///
  /// In zh, this message translates to:
  /// **'正在加载…'**
  String get loading;

  /// No description provided for @startupFailed.
  ///
  /// In zh, this message translates to:
  /// **'暂时无法读取提醒'**
  String get startupFailed;

  /// No description provided for @startupHelp.
  ///
  /// In zh, this message translates to:
  /// **'请重试。应用不会通过清空数据来修复问题。'**
  String get startupHelp;

  /// No description provided for @errorDetails.
  ///
  /// In zh, this message translates to:
  /// **'错误详情'**
  String get errorDetails;

  /// No description provided for @errorGeneric.
  ///
  /// In zh, this message translates to:
  /// **'操作未成功，请重试。'**
  String get errorGeneric;

  /// No description provided for @errorStorage.
  ///
  /// In zh, this message translates to:
  /// **'无法保存或读取提醒，请重试。'**
  String get errorStorage;

  /// No description provided for @errorTitle.
  ///
  /// In zh, this message translates to:
  /// **'请填写提醒名称。'**
  String get errorTitle;

  /// No description provided for @errorDuration.
  ///
  /// In zh, this message translates to:
  /// **'请填写 1–1440 分钟之间的时长。'**
  String get errorDuration;

  /// No description provided for @errorPast.
  ///
  /// In zh, this message translates to:
  /// **'请选择未来的提醒时间。'**
  String get errorPast;

  /// No description provided for @errorDays.
  ///
  /// In zh, this message translates to:
  /// **'请至少选择一个重复日期。'**
  String get errorDays;

  /// No description provided for @errorQrRequired.
  ///
  /// In zh, this message translates to:
  /// **'请先登记要扫描的码。'**
  String get errorQrRequired;

  /// No description provided for @errorWrongQr.
  ///
  /// In zh, this message translates to:
  /// **'不是这个提醒登记的码，请继续扫描。'**
  String get errorWrongQr;

  /// No description provided for @errorPassword.
  ///
  /// In zh, this message translates to:
  /// **'密码不正确。'**
  String get errorPassword;

  /// No description provided for @errorPasswordLength.
  ///
  /// In zh, this message translates to:
  /// **'密码长度应为 4–128 个字符。'**
  String get errorPasswordLength;

  /// No description provided for @errorPasswordMatch.
  ///
  /// In zh, this message translates to:
  /// **'两次输入的密码不同。'**
  String get errorPasswordMatch;

  /// No description provided for @errorOath.
  ///
  /// In zh, this message translates to:
  /// **'请完整、准确地输入指定誓词。'**
  String get errorOath;

  /// No description provided for @errorActive.
  ///
  /// In zh, this message translates to:
  /// **'本次提醒尚未解除。请完成任务，或通过应急关闭解除。'**
  String get errorActive;

  /// No description provided for @errorNotActive.
  ///
  /// In zh, this message translates to:
  /// **'这个提醒的状态已变化，请返回查看。'**
  String get errorNotActive;

  /// No description provided for @errorExact.
  ///
  /// In zh, this message translates to:
  /// **'请先开启精确闹钟权限。'**
  String get errorExact;

  /// No description provided for @errorNotifications.
  ///
  /// In zh, this message translates to:
  /// **'请先开启应用通知和任务提醒通知频道。'**
  String get errorNotifications;

  /// No description provided for @errorStale.
  ///
  /// In zh, this message translates to:
  /// **'题目已更新，请重试。'**
  String get errorStale;

  /// No description provided for @chooseDuration.
  ///
  /// In zh, this message translates to:
  /// **'选择推迟时长'**
  String get chooseDuration;

  /// No description provided for @tomorrow.
  ///
  /// In zh, this message translates to:
  /// **'明天'**
  String get tomorrow;

  /// No description provided for @today.
  ///
  /// In zh, this message translates to:
  /// **'今天'**
  String get today;

  /// No description provided for @waitingReview.
  ///
  /// In zh, this message translates to:
  /// **'完成后的复查已安排'**
  String get waitingReview;

  /// No description provided for @activeLocked.
  ///
  /// In zh, this message translates to:
  /// **'请先处理本次提醒'**
  String get activeLocked;

  /// No description provided for @practiceCorrect.
  ///
  /// In zh, this message translates to:
  /// **'答对了！'**
  String get practiceCorrect;

  /// No description provided for @practiceAnswer.
  ///
  /// In zh, this message translates to:
  /// **'参考答案'**
  String get practiceAnswer;

  /// No description provided for @quickTest.
  ///
  /// In zh, this message translates to:
  /// **'30 秒后测试提醒'**
  String get quickTest;

  /// No description provided for @testReminderName.
  ///
  /// In zh, this message translates to:
  /// **'测试提醒'**
  String get testReminderName;

  /// No description provided for @testScheduled.
  ///
  /// In zh, this message translates to:
  /// **'测试提醒将在 30 秒后响起，请锁屏验证。'**
  String get testScheduled;

  /// No description provided for @minutesLabel.
  ///
  /// In zh, this message translates to:
  /// **'{count} 分钟'**
  String minutesLabel(int count);

  /// No description provided for @hoursLabel.
  ///
  /// In zh, this message translates to:
  /// **'{count} 小时'**
  String hoursLabel(int count);

  /// No description provided for @holdSnooze.
  ///
  /// In zh, this message translates to:
  /// **'按住推迟 {duration}'**
  String holdSnooze(String duration);

  /// No description provided for @mathProgress.
  ///
  /// In zh, this message translates to:
  /// **'已完成 {done} / {total} 题'**
  String mathProgress(int done, int total);

  /// No description provided for @reviewAfter.
  ///
  /// In zh, this message translates to:
  /// **'完成后 {duration} 再复查'**
  String reviewAfter(String duration);

  /// No description provided for @nextIn.
  ///
  /// In zh, this message translates to:
  /// **'还有 {duration}'**
  String nextIn(String duration);

  /// No description provided for @soundAndVibration.
  ///
  /// In zh, this message translates to:
  /// **'声音与振动'**
  String get soundAndVibration;

  /// No description provided for @alarmSound.
  ///
  /// In zh, this message translates to:
  /// **'闹钟铃声'**
  String get alarmSound;

  /// No description provided for @systemDefaultSound.
  ///
  /// In zh, this message translates to:
  /// **'系统默认闹钟铃声'**
  String get systemDefaultSound;

  /// No description provided for @selectedSound.
  ///
  /// In zh, this message translates to:
  /// **'已选择系统铃声'**
  String get selectedSound;

  /// No description provided for @useDefaultSound.
  ///
  /// In zh, this message translates to:
  /// **'恢复系统默认铃声'**
  String get useDefaultSound;

  /// No description provided for @reminderVolume.
  ///
  /// In zh, this message translates to:
  /// **'本条提醒音量：{volume}%'**
  String reminderVolume(int volume);

  /// No description provided for @volumeLimitHelp.
  ///
  /// In zh, this message translates to:
  /// **'在系统闹钟音量范围内调节本条提醒的响度，100% 为系统当前响度。'**
  String get volumeLimitHelp;

  /// No description provided for @alarmVolumeZero.
  ///
  /// In zh, this message translates to:
  /// **'系统闹钟音量为零，提醒可能无声。请先调整并试听。'**
  String get alarmVolumeZero;

  /// No description provided for @fadeIn.
  ///
  /// In zh, this message translates to:
  /// **'音量渐强'**
  String get fadeIn;

  /// No description provided for @fadeOff.
  ///
  /// In zh, this message translates to:
  /// **'关闭'**
  String get fadeOff;

  /// No description provided for @soundSeconds.
  ///
  /// In zh, this message translates to:
  /// **'{seconds} 秒'**
  String soundSeconds(int seconds);

  /// No description provided for @previewSound.
  ///
  /// In zh, this message translates to:
  /// **'试听铃声'**
  String get previewSound;

  /// No description provided for @stopSoundPreview.
  ///
  /// In zh, this message translates to:
  /// **'停止试听'**
  String get stopSoundPreview;

  /// No description provided for @soundPreviewHelp.
  ///
  /// In zh, this message translates to:
  /// **'按当前音量与渐强设置试听，渐强结束后自动停止；离开页面或正式响铃时停止。'**
  String get soundPreviewHelp;

  /// No description provided for @soundFallbackHelp.
  ///
  /// In zh, this message translates to:
  /// **'所选铃声不可用，正在使用备用声音。请重新选择铃声。'**
  String get soundFallbackHelp;

  /// No description provided for @errorSound.
  ///
  /// In zh, this message translates to:
  /// **'声音设置不可用，请重新选择铃声和音量。'**
  String get errorSound;

  /// No description provided for @errorSoundPicker.
  ///
  /// In zh, this message translates to:
  /// **'系统铃声选择器暂时不可用，可继续使用默认铃声。'**
  String get errorSoundPicker;

  /// No description provided for @errorSoundDuringAlarm.
  ///
  /// In zh, this message translates to:
  /// **'请先处理正在响铃的提醒，再试听。'**
  String get errorSoundDuringAlarm;

  /// No description provided for @alarmVolume.
  ///
  /// In zh, this message translates to:
  /// **'系统闹钟音量档位：{volume}'**
  String alarmVolume(int volume);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
