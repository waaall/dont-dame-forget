# 技术设计

Flutter + Dart + Riverpod 负责界面、表单、扫码相机和国际化；MethodChannel 提交命令，EventChannel 通知变化。

Kotlin ReminderEngine 统一串行处理 UI、广播和服务的变更。原生 SQLite 保存计划、本次提醒、任务状态和事件，避免 Dart 与后台各持一份相互竞争的数据。SharedPreferences 保存偏好；应急密码使用 PBKDF2-HMAC-SHA256 与随机盐，不存明文。mobile_scanner 使用随包提供的 ML Kit 模型。

## 状态与校验

`scheduled → ringing → snoozed → ringing` 可无限循环。

通过任务后，若开启复查且未复查，则进入 `reviewPending → ringing`；再次通过后 `completed`。未开启复查直接完成，应急验证后 `skipped` 且不复查。

完成或跳过后，重复计划创建下一次提醒，单次计划停用。每个计划只保留一个未结束的本次提醒，避免跨天推迟时叠加相同闹钟。

本次提醒保存任务配置快照。算题答案只在原生端验证，并以每题 token 防止旧答案重复提交。扫码与应急验证均在原生端执行。等待复查状态不能再次提交原任务来跳过未来复查。

## 系统调度

使用 AlarmManager.setAlarmClock，以 occurrence ID 区分 PendingIntent，并校验预期触发时间；过期广播不能重新激活已推迟或完成的提醒。

广播落库后启动 mediaPlayback 前台服务，使用系统闹钟流循环播放。系统铃声不可用时启用备用音并记录。通知提供进入任务的入口，没有普通关闭按钮。

Android 12 使用精确闹钟特殊权限，Android 13+ 以闹钟用途声明 USE_EXACT_ALARM。应用内诊断通知、全屏提醒、电池限制与闹钟音量。

设备保护存储支持启动恢复。重启、覆盖更新、时间/时区变化后重新安排未结束提醒；开机广播不直接启动媒体前台服务。恢复时过期提醒重新安排到当前时间附近，经标准精确闹钟广播响起。

SQLite 与 AlarmManager 无法构成同一个事务。数据库保留待执行状态，恢复时重新安排相同 PendingIntent。关键权限检查和错误提示避免静默失败。Dart Timer 只显示倒计时，不承担调度。

## 声音播放

`AlarmAudioPlayer` 由主线程管理，供正式响铃服务和试听共同使用。使用原生 `MediaPlayer` 异步准备音源、闹钟音频用途与音频焦点；音量使用播放器增益，不改全局系统音量。滑条百分比转换为感知更自然的增益后渐强。

计划及 occurrence 快照保存 `soundUri`、`soundName`、`volumePercent`、`fadeInSeconds`；SQLite 原有 JSON payload 支持增量字段，缺失字段读取默认值。原生保存时校验范围。系统选择器通过 Activity 返回音源与显示名称，取消不会覆盖原设置。

引擎在每次进入 ringing 状态时保存 `ringStartedAt`，重复广播不更新它。播放期间使用单调时钟推进渐强；服务重建时按已响铃时长恢复，避免页面变化或服务恢复导致反复从小声开始。

`SoundPreview` 只有一份本地播放器，有自动停止时限。Activity 暂停、Flutter 页面被覆盖或销毁、设置变化及实际闹钟开始时停止。原生再次校验正在响铃状态，避免仅依赖界面判断。只读 `soundStatus` 返回播放器准备状态、实际音源、增益及降级级别，供集成验证与调试使用；它不改变提醒状态。

音源打开或播放失败后尝试下一音源，最终用 ToneGenerator 提示音。正式播放只为一次降级记录一个事件；试听降级反馈在界面，不污染提醒历史。

## 阅读器经验

借鉴统一视觉参数、明暗主题、设置即时反馈、异步操作协调、启动错误兜底和增量迁移。没有移植书架业务、FTS5、大文件解析或旧插件版本回退。缺失迁移时明确失败，不静默删除个人数据。

Windows 的 Pub 缓存与项目在不同盘时会导致 Kotlin 测试配置失败。构建脚本采用项目内 .pub-cache，解决根路径不一致。

Flutter 自动生成的 local.properties 在 Windows 上会被 Lint 的 PropertyEscape 误报（值中的盘符冒号符合 Java Properties 语法）。app/lint.xml 仅对这份生成文件忽略该规则，其他维护的配置文件仍保留检查，避免改写 Flutter 管理的配置和残留缓存误报。

## 验证

Flutter 静态检查和交互测试；原生时间规则与任务状态测试；真实 Flutter 页面渲染截图。锁屏、Doze、重启及相机识别需要安卓设备验证，见构建文档。
