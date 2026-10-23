# 别忘了 / Don’t Forget

用 Flutter 编写的 Android 强提醒应用，本地离线运行。

- 起床、待办、习惯与其他事项；单次或选择每周重复日期。
- 长按只能推迟，无次数上限。默认时长、每条提醒的时长均可设置，支持常用时长和自定义分钟数。
- 算题或扫描提前登记的二维码 / 条形码后解除本次提醒。
- 每条提醒可开启一次完成后复查，默认 10 分钟，沿用原解除任务。
- 每条提醒可选择系统闹钟铃声、设置 10–100% 播放音量与 15/30/60/120 秒渐强，并试听；实际响度受系统闹钟音量限制。
- 应急关闭同时验证密码和原文誓词：`我发誓我没忘，让我关上吧`。
- 简体中文 / English / 跟随系统；浅色 / 深色主题。
- Android 原生保存与调度，后台响铃，重启与升级后重新安排未完成提醒。
- 无账号、云同步、广告或数据上报，扫码模型随安装包提供。

第一版面向 Android 8.0+（API 26），重点是三星 S20 等较新安卓手机。iOS 尚未实现。

## 开发与构建

```powershell
flutter pub get
flutter gen-l10n
flutter analyze
flutter test --exclude-tags preview
./scripts/Build-Android.ps1
adb install -r build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

Windows 下构建脚本使用项目内 Pub 缓存，避免 C 盘缓存和 D 盘项目的 Kotlin 跨盘错误；仅在当前进程指定 JDK，不改变全局 Flutter 配置。

release APK 暂时沿用阅读器的 debug 签名自用流程。后续覆盖安装应保留同一签名。详细说明：[构建与验证](docs/dev/build-and-release.md)、[产品规则](docs/demand/product-rules.md)、[技术设计](docs/dev/technical-design.md)。

## 首次使用

在设置中配置应急密码，检查通知、全屏提醒、后台电池限制和系统闹钟音量。使用“30 秒后测试提醒”验证锁屏响铃。

Android 系统的强制停止、撤权、关机和卸载会影响提醒，应用不能禁止这些系统操作。应用内的返回、普通点击、删除开关等操作不会作为任务解除方式。

## English

A local-first, mission-based Android reminder app. Dismiss by solving math questions or scanning a registered code; hold to snooze as often as needed. Each reminder can have a one-time follow-up, 10 minutes by default. Emergency dismissal requires a password and the exact Chinese pledge shown above.

Flutter handles the UI. A Kotlin engine owns native SQLite data, alarm scheduling, mission validation and foreground alarm audio. No cloud backend, account or analytics. Chinese and English UI switch immediately; user-created reminder content stays unchanged.

The first release targets Android only. See the linked build guide for APK installation and device verification.
