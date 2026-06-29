import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';

class AppInfo {
  final String packageName;
  final String? appName;
  final bool isSystem;
  final bool isEnabled;
  final String? versionName;
  final String? apkPath;

  AppInfo({
    required this.packageName,
    this.appName,
    this.isSystem = false,
    this.isEnabled = true,
    this.versionName,
    this.apkPath,
  });

  String get displayName => appName ?? packageName;
}

class FileItem {
  final String name;
  final String path;
  final bool isDirectory;
  final int size;
  final String? date;
  final String? permission;

  FileItem({
    required this.name,
    required this.path,
    this.isDirectory = false,
    this.size = 0,
    this.date,
    this.permission,
  });
}

class AdbClient extends ChangeNotifier {
  Socket? _socket;
  String? _deviceIp;
  int? _devicePort;
  bool _isConnected = false;
  bool _isConnecting = false;

  String? get deviceIp => _deviceIp;
  int? get devicePort => _devicePort;
  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;

  Future<bool> connect(String ip, int port) async {
    if (_isConnecting) return false;
    
    _isConnecting = true;
    notifyListeners();

    try {
      _socket = await Socket.connect(ip, port, timeout: const Duration(seconds: 5));
      
      // 发送ADB连接握手
      await _sendMessage('host:transport-any');
      final response = await _readMessage();
      
      if (response == 'OKAY') {
        _deviceIp = ip;
        _devicePort = port;
        _isConnected = true;
        _isConnecting = false;
        notifyListeners();
        return true;
      }
      
      await _socket?.close();
      _socket = null;
    } catch (e) {
      debugPrint('连接失败: $e');
    }

    _isConnecting = false;
    notifyListeners();
    return false;
  }

  Future<void> disconnect() async {
    await _socket?.close();
    _socket = null;
    _isConnected = false;
    _deviceIp = null;
    _devicePort = null;
    notifyListeners();
  }

  Future<String> _sendMessage(String message) async {
    if (_socket == null) throw Exception('未连接');
    
    final length = message.length.toRadixString(16).padLeft(4, '0');
    final data = utf8.encode('$length$message');
    _socket!.add(data);
    await _socket!.flush();
    
    return await _readMessage();
  }

  Future<String> _readMessage() async {
    if (_socket == null) throw Exception('未连接');
    
    final header = await _socket!.first.timeout(
      const Duration(seconds: 10),
      onTimeout: () => [],
    );
    
    if (header.isEmpty) return '';
    
    final headerStr = utf8.decode(header);
    if (headerStr.startsWith('OKAY')) {
      return 'OKAY';
    } else if (headerStr.startsWith('FAIL')) {
      return 'FAIL';
    }
    
    return headerStr;
  }

  Future<String> executeCommand(String command) async {
    if (!_isConnected || _socket == null) {
      throw Exception('请先连接设备');
    }

    try {
      // 发送shell命令
      final cmd = 'shell:$command';
      final length = cmd.length.toRadixString(16).padLeft(4, '0');
      _socket!.add(utf8.encode('$length$cmd'));
      await _socket!.flush();

      // 读取响应
      final completer = StringBuffer();
      await for (final data in _socket!) {
        final str = utf8.decode(data);
        if (str.startsWith('OKAY')) {
          continue;
        }
        completer.write(str);
        if (completer.length > 100000) break; // 限制输出大小
      }

      return completer.toString();
    } catch (e) {
      return '错误: $e';
    }
  }

  // 应用管理
  Future<List<AppInfo>> listPackages({bool includeSystem = true}) async {
    final result = await executeCommand('pm list packages ${includeSystem ? '' : '-3'}');
    final packages = <AppInfo>[];
    
    for (final line in result.split('\n')) {
      if (line.startsWith('package:')) {
        final pkg = line.substring(8).trim();
        if (pkg.isNotEmpty) {
          packages.add(AppInfo(packageName: pkg));
        }
      }
    }
    
    return packages;
  }

  Future<bool> disableApp(String packageName) async {
    final result = await executeCommand('pm disable $packageName');
    return result.contains('Success') || result.contains('success');
  }

  Future<bool> enableApp(String packageName) async {
    final result = await executeCommand('pm enable $packageName');
    return result.contains('Success') || result.contains('success');
  }

  Future<bool> uninstallApp(String packageName) async {
    final result = await executeCommand('pm uninstall -k --user 0 $packageName');
    return result.contains('Success') || result.contains('success');
  }

  Future<bool> clearAppData(String packageName) async {
    final result = await executeCommand('pm clear $packageName');
    return result.contains('Success') || result.contains('success');
  }

  /// 推送文件数据到设备（通过 base64 分片写入）
  Future<bool> pushFileData(List<int> data, String remotePath) async {
    if (!_isConnected) return false;

    try {
      const chunkSize = 3072; // 每片原始字节数
      var offset = 0;
      var first = true;

      while (offset < data.length) {
        final end = offset + chunkSize > data.length ? data.length : offset + chunkSize;
        final chunk = data.sublist(offset, end);
        final b64 = base64Encode(chunk);

        final op = first ? '>' : '>>';
        final cmd = "echo '$b64' | base64 -d $op $remotePath";
        await executeCommand(cmd);

        first = false;
        offset = end;
      }
      return true;
    } catch (e) {
      debugPrint('推送文件失败: $e');
      return false;
    }
  }

  /// 安装APK文件（需要先推送到设备）
  Future<String> installApk(String remotePath) async {
    return await executeCommand('pm install -r $remotePath');
  }

  // 文件管理
  Future<List<FileItem>> listFiles(String path) async {
    final result = await executeCommand('ls -la $path');
    final files = <FileItem>[];
    
    for (final line in result.split('\n')) {
      final parts = line.trim().split(RegExp(r'\s+'));
      if (parts.length >= 9 && !line.startsWith('total')) {
        final permission = parts[0];
        final isDir = permission.startsWith('d');
        final size = int.tryParse(parts[4]) ?? 0;
        final name = parts.sublist(8).join(' ');
        
        if (name.isNotEmpty && name != '.' && name != '..') {
          files.add(FileItem(
            name: name,
            path: '$path/$name',
            isDirectory: isDir,
            size: size,
            date: '${parts[5]} ${parts[6]} ${parts[7]}',
            permission: permission,
          ));
        }
      }
    }
    
    return files;
  }

  // 系统命令
  Future<String> getDeviceInfo() async {
    return await executeCommand('getprop | grep -E "ro.product.model|ro.build.version.release|ro.build.version.sdk"');
  }

  Future<String> getBatteryInfo() async {
    return await executeCommand('dumpsys battery');
  }

  Future<bool> reboot() async {
    try {
      await executeCommand('reboot');
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> takeScreenshot() async {
    try {
      await executeCommand('screencap -p /sdcard/screenshot.png');
      return true;
    } catch (e) {
      return false;
    }
  }
}
