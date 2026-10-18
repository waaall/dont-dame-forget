# Android 构建与分发

创建环境：Flutter 3.44.0 / Dart 3.12.0，模板生成的 AGP 9.0.1、Kotlin 2.3.20、Gradle 9.1.0，最低 API 26。

借鉴阅读器的 APK 流程，不复制旧版本号。Windows 下以项目内 Pub 缓存避免跨盘问题，并在当前进程指定 JDK，不改变全局 Flutter 配置。

```powershell
./scripts/Build-Android.ps1 -JdkPath 'C:\Program Files\Eclipse Adoptium\jdk-21.0.12.101-hotspot'
```

脚本执行依赖安装、国际化、静态检查、Flutter 测试、原生单元测试和 release APK 打包。`-SkipChecks` 用于检查通过后的重复打包；`-Universal` 生成全架构单包，默认按 ABI 分包。

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

本机未连接安卓真机，也没有配置 AVD；自动化测试与截图不代表设备场景已经验证。

## 界面预览

`flutter test test/preview_test.dart --tags preview`

输出 `build/previews/`，使用测试数据渲染真实 Flutter 页面。Windows 下加载系统微软雅黑字体，普通测试不依赖预览文件。
