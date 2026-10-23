# Android 构建与分发

创建环境：Flutter 3.44.0 / Dart 3.12.0，模板生成的 AGP 9.0.1、Kotlin 2.3.20、Gradle 9.1.0，最低 API 26。

借鉴阅读器的 APK 流程，不复制旧版本号。Windows 下以项目内 Pub 缓存避免跨盘问题，并在当前进程指定 JDK，不改变全局 Flutter 配置。

```powershell
./scripts/Build-Android.ps1 -JdkPath 'C:\Program Files\Eclipse Adoptium\jdk-21.0.12.101-hotspot'
```

脚本执行依赖安装、国际化、静态检查、Flutter 测试和 release APK 打包，最后执行原生单元测试与 Android Lint。首次检出时，由 Flutter 打包补齐 Gradle 启动器，再调用原生检查；全部通过后才输出最终安装包列表。`-SkipChecks` 用于检查通过后的重复打包；`-Universal` 生成全架构单包，默认按 ABI 分包。

三星 S20 使用 arm64 包：`build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`。

```powershell
adb devices -l
adb install -r build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

也可传 APK 到手机手动安装。当前 release 沿用阅读器的 debug 签名自用流程；保留同一签名以覆盖更新。换机器、换签名或卸载前需安排数据保护。签名材料不进入仓库。

## 真机验证

1. 配置应急密码，开启通知、全屏提醒，检查电池限制与闹钟音量。
2. 设置页创建“30 秒后测试提醒”，锁屏等待，确认响铃与任务入口。
3. 轻点推迟应无效果，长按才推迟；连续推迟不应自动结束。
4. 错误答案/错误二维码不能解除；正确任务可以解除。
5. 开启 1 分钟复查用于测试：完成任务后再次响起，再完成后不继续复查。
6. 错误誓词或错误密码不能应急关闭，两者正确后记为跳过。
7. 响铃后返回桌面、移除最近任务，验证未强制停止情况下的表现。
8. 设置提醒后重启，解锁前后分别验证恢复；测试改时间、时区和覆盖安装。
9. 三星电池设置允许后台运行，移出深度休眠名单；验证省电模式。
10. 切换中英文、主题及较大系统字体，检查所有关键页面。

自动化测试与截图不能代替目标手机的锁屏、重启、省电模式及相机验证。已执行的模拟器测试及其范围见各次测试记录。

## Android 引擎集成测试

`integration_test/engine_test.dart` 使用真实 MethodChannel、SQLite 与 AlarmManager，覆盖计划增删改、密码校验、30 秒触发、活动任务保护、推迟后提前完成、二维码值校验、应急关闭、重复调度和仅一次复查。声音测试还覆盖真实播放器增益、试听自动停止与正式闹钟抢占、无效音源回退、推迟与复查的声音配置。测试包含真实计时，通常需要约 3–5 分钟。声音设置的具体部署验收见 [2026-10-23 测试记录](qa-2026-10-23-sound.md)。

仅在专用 Android 35 模拟器上执行：测试会设置应急密码 `test-only-4729`、修改语言和主题并创建真实闹钟；结束时清理本次创建的计划。不要在保存个人提醒的手机上直接运行。

```powershell
flutter build apk --debug --target-platform android-x64 -t integration_test/engine_test.dart
adb -s emulator-5554 install -r build/app/outputs/flutter-apk/app-debug.apk
adb -s emulator-5554 shell pm grant com.dontforget.dont_forget android.permission.POST_NOTIFICATIONS
flutter test integration_test/engine_test.dart -d emulator-5554 --no-pub
```

测试包以测试代码为入口。完成后重新构建并安装正常入口 `lib/main.dart` 的应用包。

## 界面预览

`flutter test test/preview_test.dart --tags preview`

输出 `build/previews/`，使用测试数据渲染真实 Flutter 页面。Windows 下加载系统微软雅黑字体，普通测试不依赖预览文件。
