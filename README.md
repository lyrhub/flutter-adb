# Flutter ADB Tool

ADB 调试工具的 Flutter 跨平台版本。通过 WiFi 连接远程 Android 设备，支持应用管理、文件浏览和命令执行。

## 功能特性

### 🔗 设备连接
- WiFi 连接目标 Android 设备（IP + 端口）
- 局域网自动扫描，逐 IP 探测 5555 端口
- Provider 状态管理，全局共享连接状态

### 📱 应用管理
- 查看已安装应用列表
- 切换显示系统应用/仅第三方应用
- 禁用/启用/卸载/清除数据
- 底部弹窗操作菜单

### 📁 文件管理
- 浏览设备文件系统（默认 /sdcard）
- 目录导航，支持历史回退
- 文件大小自动格式化（B/KB/MB/GB）
- 区分文件夹和文件图标显示

### 💻 终端命令
- Shell 命令输入与执行
- 8 个快捷命令按钮
- 命令历史记录（横向滑动 Chip）
- 终端风格输出界面（深色背景 + 绿色字体）

## 技术栈

- **框架**: Flutter 3.22+
- **语言**: Dart (SDK ≥3.2.0)
- **状态管理**: Provider
- **网络通信**: dart:io Socket（ADB 协议）
- **UI**: Material Design 3

## 依赖

| 包名 | 用途 |
|------|------|
| provider | 状态管理 |
| shared_preferences | 本地存储 |
| connectivity_plus | 网络状态检测 |
| network_info_plus | 获取本机网络信息 |

## 构建

```bash
# 获取依赖
flutter pub get

# 构建 Android APK
flutter build apk --release

# 构建 iOS（需要 macOS）
flutter build ios --release
```

## 项目结构

```
lib/
├── main.dart              # 应用入口，底部导航
├── core/
│   └── adb_client.dart    # ADB 协议客户端实现
├── pages/
│   ├── connect_page.dart  # 连接管理页面
│   ├── apps_page.dart     # 应用管理页面
│   ├── files_page.dart    # 文件浏览器页面
│   └── terminal_page.dart # 终端命令页面
├── utils/
│   └── network_scanner.dart # 局域网设备扫描
└── widgets/               # 可复用组件
```

## 使用说明

1. 目标设备开启「开发者选项」→「网络 ADB 调试」
2. 确保运行本应用的设备与目标设备在同一局域网
3. 输入 IP 地址连接，或使用扫描功能自动发现设备
4. 连接后可在各 Tab 页管理应用、浏览文件、执行命令

## 与原生版本的对比

| 特性 | ADBTool (Kotlin) | Flutter ADB |
|------|-------------------|-------------|
| 平台 | 仅 Android | Android / iOS |
| UI 框架 | Android View | Flutter Material 3 |
| 状态管理 | Activity 传递 | Provider |
| ADB 通信 | Java Socket | Dart Socket |

## License

MIT
