import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/adb_client.dart';

class AppsPage extends StatefulWidget {
  const AppsPage({super.key});

  @override
  State<AppsPage> createState() => _AppsPageState();
}

class _AppsPageState extends State<AppsPage> {
  List<AppInfo> _apps = [];
  bool _isLoading = false;
  bool _showSystemApps = false;
  final Set<String> _selectedApps = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadApps();
    });
  }

  Future<void> _loadApps() async {
    final adbClient = context.read<AdbClient>();
    if (!adbClient.isConnected) {
      setState(() {
        _apps = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final apps = await adbClient.listPackages(includeSystem: _showSystemApps);
      setState(() {
        _apps = apps;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载失败: $e')),
        );
      }
    }
  }

  Future<void> _disableApp(String packageName) async {
    final adbClient = context.read<AdbClient>();
    final success = await adbClient.disableApp(packageName);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success ? '已禁用' : '操作失败')),
      );
    }
    _loadApps();
  }

  Future<void> _enableApp(String packageName) async {
    final adbClient = context.read<AdbClient>();
    final success = await adbClient.enableApp(packageName);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success ? '已启用' : '操作失败')),
      );
    }
    _loadApps();
  }

  Future<void> _uninstallApp(String packageName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认卸载'),
        content: Text('确定要卸载 $packageName 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('卸载', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final adbClient = context.read<AdbClient>();
    final success = await adbClient.uninstallApp(packageName);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success ? '卸载成功' : '卸载失败')),
      );
    }
    _loadApps();
  }

  Future<void> _clearData(String packageName) async {
    final adbClient = context.read<AdbClient>();
    final success = await adbClient.clearAppData(packageName);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success ? '数据已清除' : '操作失败')),
      );
    }
  }

  void _showAppMenu(AppInfo app) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(app.packageName),
              subtitle: Text(app.isSystem ? '系统应用' : '第三方应用'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.block),
              title: const Text('禁用应用'),
              onTap: () {
                Navigator.pop(context);
                _disableApp(app.packageName);
              },
            ),
            ListTile(
              leading: const Icon(Icons.check_circle_outline),
              title: const Text('启用应用'),
              onTap: () {
                Navigator.pop(context);
                _enableApp(app.packageName);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_sweep),
              title: const Text('清除数据'),
              onTap: () {
                Navigator.pop(context);
                _clearData(app.packageName);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('卸载应用', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _uninstallApp(app.packageName);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('应用管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadApps,
          ),
        ],
      ),
      body: Consumer<AdbClient>(
        builder: (context, adbClient, child) {
          if (!adbClient.isConnected) {
            return const Center(
              child: Text('请先连接设备'),
            );
          }

          return Column(
            children: [
              // 工具栏
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Switch(
                      value: _showSystemApps,
                      onChanged: (value) {
                        setState(() {
                          _showSystemApps = value;
                        });
                        _loadApps();
                      },
                    ),
                    const Text('显示系统应用'),
                    const Spacer(),
                    Text('${_apps.length} 个应用'),
                  ],
                ),
              ),
              const Divider(height: 1),

              // 应用列表
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _apps.isEmpty
                        ? const Center(child: Text('没有应用'))
                        : ListView.builder(
                            itemCount: _apps.length,
                            itemBuilder: (context, index) {
                              final app = _apps[index];
                              return ListTile(
                                leading: CircleAvatar(
                                  child: Text(
                                    app.displayName.substring(0, 1).toUpperCase(),
                                  ),
                                ),
                                title: Text(app.displayName),
                                subtitle: Text(app.packageName),
                                trailing: const Icon(Icons.more_vert),
                                onTap: () => _showAppMenu(app),
                              );
                            },
                          ),
              ),
            ],
          );
        },
      ),
    );
  }
}
