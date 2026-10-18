// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appName => '别忘了';

  @override
  String get tagline => '重要的小事，也值得被记住。';

  @override
  String get reminders => '提醒';

  @override
  String get activity => '记录';

  @override
  String get settings => '设置';

  @override
  String get nextReminder => '下一次提醒';

  @override
  String get nothingScheduled => '把下一件事，交给提醒。';

  @override
  String get createReminder => '新建提醒';

  @override
  String get editReminder => '编辑提醒';

  @override
  String get all => '全部';

  @override
  String get pending => '待处理';

  @override
  String get plans => '提醒计划';

  @override
  String get noReminders => '从一件小事开始';

  @override
  String get noRemindersBody => '起床、晾衣服、养成习惯。\n设好提醒，完成任务后再解除。';

  @override
  String get noPending => '现在没有待处理的提醒';

  @override
  String get noPendingBody => '下一次需要行动时，我们会提醒你。';

  @override
  String get quickStart => '快速开始';

  @override
  String get wakeUp => '起床';

  @override
  String get laundry => '晾衣服';

  @override
  String get drinkWater => '喝水';

  @override
  String get alarmCategory => '起床';

  @override
  String get todoCategory => '待办';

  @override
  String get habitCategory => '习惯';

  @override
  String get otherCategory => '其他';

  @override
  String get scheduled => '已安排';

  @override
  String get ringing => '正在提醒';

  @override
  String get snoozed => '已推迟';

  @override
  String get reviewPending => '等待复查';

  @override
  String get disabled => '已关闭';

  @override
  String get enabled => '启用';

  @override
  String get once => '仅一次';

  @override
  String get everyDay => '每天';

  @override
  String get weekdays => '工作日';

  @override
  String get custom => '自定义';

  @override
  String get mathMission => '算题解除';

  @override
  String get qrMission => '指定扫码';

  @override
  String get mathDescription => '完成设定数量的算术题，唤醒注意力。';

  @override
  String get qrDescription => '扫描提前登记的二维码或条形码，走到该去的地方。';

  @override
  String get nameLabel => '提醒什么？';

  @override
  String get nameHint => '例如：把洗好的衣服晾起来';

  @override
  String get noteLabel => '补充说明（可选）';

  @override
  String get category => '场景';

  @override
  String get schedule => '提醒时间';

  @override
  String get date => '日期';

  @override
  String get time => '时间';

  @override
  String get repeat => '重复';

  @override
  String get repeatDays => '重复日期';

  @override
  String get mission => '解除方式';

  @override
  String get difficulty => '算题难度';

  @override
  String get easy => '简单';

  @override
  String get medium => '适中';

  @override
  String get hard => '较难';

  @override
  String get questionCount => '题目数量';

  @override
  String get tryMission => '试做一道';

  @override
  String get previewMission => '算题预览';

  @override
  String get previewBody => '这是练习，不会创建或解除提醒。';

  @override
  String get registerCode => '登记二维码 / 条形码';

  @override
  String get changeCode => '重新登记';

  @override
  String get codeRegistered => '已登记指定码';

  @override
  String get codeLabel => '位置备注';

  @override
  String get codeLabelHint => '例如：阳台衣架上的二维码';

  @override
  String get snooze => '推迟';

  @override
  String get snoozeDuration => '默认推迟时长';

  @override
  String get snoozeHelp => '可无限次推迟。只有完成解除任务，才会结束本次提醒。';

  @override
  String get minutes => '分钟';

  @override
  String get hours => '小时';

  @override
  String get duration => '时长';

  @override
  String get customDuration => '自定义时长';

  @override
  String get typicalDurations => '快捷推迟';

  @override
  String get review => '完成后复查';

  @override
  String get reviewHelp => '解除后再提醒一次，仍需完成原来的任务。';

  @override
  String get reviewDuration => '复查间隔';

  @override
  String get vibrate => '响铃时振动';

  @override
  String get save => '保存提醒';

  @override
  String get saveChanges => '保存';

  @override
  String get cancel => '取消';

  @override
  String get done => '完成';

  @override
  String get delete => '删除提醒';

  @override
  String get deleteTitle => '删除这个提醒？';

  @override
  String get deleteBody => '未触发的提醒将被移除，已有记录会保留。';

  @override
  String get saved => '提醒已安排';

  @override
  String get deleted => '提醒已删除';

  @override
  String get language => '显示语言';

  @override
  String get system => '跟随系统';

  @override
  String get chinese => '简体中文';

  @override
  String get english => 'English';

  @override
  String get appearance => '外观';

  @override
  String get light => '浅色';

  @override
  String get dark => '深色';

  @override
  String get preferences => '偏好设置';

  @override
  String get emergency => '应急关闭';

  @override
  String get emergencyPassword => '应急密码';

  @override
  String get passwordNotSet => '尚未设置';

  @override
  String get passwordSet => '已设置';

  @override
  String get passwordIntro => '需要绕过解除任务时，输入指定誓词和密码。';

  @override
  String get setPassword => '设置应急密码';

  @override
  String get changePassword => '修改应急密码';

  @override
  String get currentPassword => '当前密码';

  @override
  String get newPassword => '新密码';

  @override
  String get repeatPassword => '再次输入新密码';

  @override
  String get passwordHint => '4–128 个字符，请牢记';

  @override
  String get passwordSaved => '应急密码已保存';

  @override
  String get passwordSetupBody => '创建第一个提醒前，先设置应急密码，以便在扫码失效等情况下解除。';

  @override
  String get pledgeLabel => '逐字输入下面的誓词';

  @override
  String get password => '密码';

  @override
  String get confirmEmergency => '验证并关闭本次提醒';

  @override
  String get emergencyHelp => '本次将记录为“应急跳过”，不会继续复查；重复计划保留。';

  @override
  String get reliability => '提醒保障';

  @override
  String get reliabilityIntro => '这些系统设置会影响提醒能否按时响起。';

  @override
  String get exactPermission => '精确闹钟';

  @override
  String get exactHelp => '允许在指定时间触发提醒。';

  @override
  String get notificationPermission => '通知';

  @override
  String get notificationHelp => '显示正在响铃的提醒和进入任务的入口。';

  @override
  String get fullScreenPermission => '锁屏全屏提醒';

  @override
  String get fullScreenHelp => '允许锁屏时显示提醒；正在使用手机时，系统可能显示横幅。';

  @override
  String get batteryPermission => '后台电池限制';

  @override
  String get batteryHelp => '建议将本应用设为不受限制，并移出深度休眠应用名单。';

  @override
  String get soundSettings => '闹钟音量与铃声';

  @override
  String get soundHelp => '响铃使用系统闹钟音量与默认闹钟铃声。';

  @override
  String get allowed => '已开启';

  @override
  String get needsAttention => '需要设置';

  @override
  String get recommended => '建议设置';

  @override
  String get openSettings => '打开系统设置';

  @override
  String get setupTitle => '让提醒准时到达';

  @override
  String get setupBody => '先完成提醒保障设置，再安排你的第一件事。';

  @override
  String get setupPassword => '先设置应急密码';

  @override
  String get localPrivacy => '数据留在这台手机';

  @override
  String get localPrivacyBody => '离线可用，无账号、无云同步、无广告。';

  @override
  String get about => '关于';

  @override
  String get version => '版本 0.1.0 · Android';

  @override
  String get activityTitle => '每一次行动，都有迹可循。';

  @override
  String get lastSevenDays => '最近 7 天';

  @override
  String get completed => '已完成';

  @override
  String get snoozes => '推迟';

  @override
  String get skipped => '应急跳过';

  @override
  String get recentActivity => '最近记录';

  @override
  String get noActivity => '还没有提醒记录';

  @override
  String get noActivityBody => '提醒响起、推迟和完成后，都会记录在这里。';

  @override
  String get eventRinging => '提醒响起';

  @override
  String get eventCompleted => '完成解除任务';

  @override
  String get eventSnoozed => '推迟提醒';

  @override
  String get eventReview => '任务完成，等待复查';

  @override
  String get eventSkipped => '通过密码和誓词应急关闭';

  @override
  String get eventSound => '系统铃声异常，已启用备用提示音';

  @override
  String get timeToAct => '该行动了';

  @override
  String get reviewTime => '再确认一下';

  @override
  String get missionRequired => '完成任务，解除本次提醒';

  @override
  String get snoozedMission => '也可以现在完成任务，提前解除。';

  @override
  String get answerHint => '输入答案';

  @override
  String get checkAnswer => '确认答案';

  @override
  String get wrongAnswer => '答案不对，再试一次。';

  @override
  String get correctAnswer => '答对了，继续下一题。';

  @override
  String get startScanning => '扫描指定码';

  @override
  String get missionCompleted => '本次提醒已完成';

  @override
  String get followUpScheduled => '已完成任务，稍后会再次复查';

  @override
  String get emergencyCompleted => '已应急关闭本次提醒';

  @override
  String get holdHint => '长按推迟，松手不会解除提醒';

  @override
  String get scanTitle => '扫描二维码 / 条形码';

  @override
  String get scanHelp => '将码放入取景框，识别后自动确认。';

  @override
  String get cameraDenied => '需要相机权限才能扫码';

  @override
  String get cameraError => '相机暂时不可用，请检查权限后重试。';

  @override
  String get torch => '手电筒';

  @override
  String get retry => '重试';

  @override
  String get close => '返回';

  @override
  String get loading => '正在加载…';

  @override
  String get startupFailed => '暂时无法读取提醒';

  @override
  String get startupHelp => '请重试。应用不会通过清空数据来修复问题。';

  @override
  String get errorDetails => '错误详情';

  @override
  String get errorGeneric => '操作未成功，请重试。';

  @override
  String get errorStorage => '无法保存或读取提醒，请重试。';

  @override
  String get errorTitle => '请填写提醒名称。';

  @override
  String get errorDuration => '请填写 1–1440 分钟之间的时长。';

  @override
  String get errorPast => '请选择未来的提醒时间。';

  @override
  String get errorDays => '请至少选择一个重复日期。';

  @override
  String get errorQrRequired => '请先登记要扫描的码。';

  @override
  String get errorWrongQr => '不是这个提醒登记的码，请继续扫描。';

  @override
  String get errorPassword => '密码不正确。';

  @override
  String get errorPasswordLength => '密码长度应为 4–128 个字符。';

  @override
  String get errorPasswordMatch => '两次输入的密码不同。';

  @override
  String get errorOath => '请完整、准确地输入指定誓词。';

  @override
  String get errorActive => '本次提醒尚未解除。请完成任务，或通过应急关闭解除。';

  @override
  String get errorNotActive => '这个提醒的状态已变化，请返回查看。';

  @override
  String get errorExact => '请先开启精确闹钟权限。';

  @override
  String get errorNotifications => '请先开启应用通知和任务提醒通知频道。';

  @override
  String get errorStale => '题目已更新，请重试。';

  @override
  String get chooseDuration => '选择推迟时长';

  @override
  String get tomorrow => '明天';

  @override
  String get today => '今天';

  @override
  String get waitingReview => '完成后的复查已安排';

  @override
  String get activeLocked => '请先处理本次提醒';

  @override
  String get practiceCorrect => '答对了！';

  @override
  String get practiceAnswer => '参考答案';

  @override
  String get quickTest => '30 秒后测试提醒';

  @override
  String get testReminderName => '测试提醒';

  @override
  String get testScheduled => '测试提醒将在 30 秒后响起，请锁屏验证。';

  @override
  String minutesLabel(int count) {
    return '$count 分钟';
  }

  @override
  String hoursLabel(int count) {
    return '$count 小时';
  }

  @override
  String holdSnooze(String duration) {
    return '按住推迟 $duration';
  }

  @override
  String mathProgress(int done, int total) {
    return '已完成 $done / $total 题';
  }

  @override
  String reviewAfter(String duration) {
    return '完成后 $duration 再复查';
  }

  @override
  String nextIn(String duration) {
    return '还有 $duration';
  }

  @override
  String alarmVolume(int volume) {
    return '当前闹钟音量：$volume';
  }
}
