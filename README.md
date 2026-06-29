# Flutter ADB 工具

一个使用Flutter开发的跨平台ADB工具，支持Android和iOS双平台。

## 功能特性

### 🔗 连接管理
- 手动输入IP和端口连接ADB设备
- 局域网设备自动扫描
- 连接状态实时显示
- 历史连接记录

### 📱 应用管理
- 列出设备上所有应用
- 支持显示/隐藏系统应用
- 应用禁用/启用
- 应用卸载
- 清除应用数据

### 💻 终端命令
- 自定义ADB命令执行
- 常用快捷命令
- 命令历史记录
- 实时输出显示

### 📁 文件管理
- 设备文件浏览
- 目录导航
- 文件大小显示
- 支持文件夹图标区分

## 技术实现

- **框架**: Flutter 3.x
- **语言**: Dart
- **状态管理**: Provider
- **核心协议**: 纯Dart实现ADB协议，基于TCP Socket
- **平台支持**: Android 5.0+ / iOS 12.0+

## 项目结构

```
lib/
├── main.dart              # 应用入口
├── core/
│   └── adb_client.dart    # ADB协议核心实现
├── pages/
│   ├── connect_page.dart  # 连接页面
│   ├── apps_page.dart     # 应用管理页面
│   ├── terminal_page.dart # 终端命令页面
│   └── files_page.dart    # 文件管理页面
├── utils/
│   └── network_scanner.dart # 网络扫描工具
└── widgets/               # 通用组件
```

## 编译说明

### Android 编译

```bash
# 安装依赖
flutter pub get

# 编译Debug版本
flutter build apk --debug

# 编译Release版本
flutter build apk --release
```

### iOS 编译

**注意：iOS编译需要macOS + Xcode环境**

```bash
# 安装依赖
flutter pub get

# 编译
flutter build ios

# 或者使用Xcode打开
open ios/Runner.xcworkspace
```

## 使用说明

### 准备工作

1. 确保被控Android设备已开启**无线ADB调试**
2. 两台设备连接到**同一局域网**

### 连接步骤

1. 打开APP，进入"连接"页面
2. 输入设备IP地址和端口（默认5555）
3. 点击"连接"按钮
4. 连接成功后即可使用各项功能

### 开启无线ADB

如果设备已通过USB连接电脑，可以使用以下命令开启无线ADB：

```bash
adb tcpip 5555
adb connect <设备IP>:5555
```

## 注意事项

### iOS平台
- 需要配置本地网络权限
- App Store审核需说明应用用途
- 后台运行有限制
- 仅支持连接Android设备（ADB协议）

### Android平台
- 需要网络权限
- 支持Android 5.0及以上版本
- 无需Root权限

## 许可证

MIT License
