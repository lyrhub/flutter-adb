# 编译指南

## 环境要求

### Android编译
- Flutter SDK 3.0+
- Android SDK (API 21+)
- Java 17

### iOS编译
- macOS 10.15+
- Xcode 14.0+
- Flutter SDK 3.0+
- CocoaPods

## 快速开始

### 1. 安装Flutter

```bash
# 下载Flutter SDK
git clone https://github.com/flutter/flutter.git -b stable

# 添加到PATH
export PATH="$PATH:`pwd`/flutter/bin"

# 运行flutter doctor检查环境
flutter doctor
```

### 2. 获取项目依赖

```bash
cd flutter_adb
flutter pub get
```

### 3. 编译Android APK

```bash
# Debug版本
flutter build apk --debug

# Release版本
flutter build apk --release

# 输出位置
# build/app/outputs/flutter-apk/app-release.apk
```

### 4. 编译iOS (需要macOS)

```bash
# 安装CocoaPods依赖
cd ios
pod install
cd ..

# 编译
flutter build ios --release

# 或者用Xcode打开
open ios/Runner.xcworkspace
```

## 常见问题

### Q: 连接设备失败？
A: 确保：
1. 设备已开启无线ADB调试
2. 两台设备在同一局域网
3. 防火墙没有阻止5555端口

### Q: 如何开启无线ADB？
A: 先用USB连接设备，然后执行：
```bash
adb tcpip 5555
adb connect <设备IP>:5555
```

### Q: iOS上无法扫描设备？
A: 需要在Info.plist中配置本地网络权限，首次使用时会弹出权限请求。

