import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/adb_client.dart';

class FilesPage extends StatefulWidget {
  const FilesPage({super.key});

  @override
  State<FilesPage> createState() => _FilesPageState();
}

class _FilesPageState extends State<FilesPage> {
  List<FileItem> _files = [];
  String _currentPath = '/sdcard';
  bool _isLoading = false;
  final List<String> _pathHistory = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFiles();
    });
  }

  Future<void> _loadFiles() async {
    final adbClient = context.read<AdbClient>();
    if (!adbClient.isConnected) {
      setState(() {
        _files = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final files = await adbClient.listFiles(_currentPath);
      setState(() {
        _files = files;
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

  void _navigateTo(String path) {
    _pathHistory.add(_currentPath);
    setState(() {
      _currentPath = path;
    });
    _loadFiles();
  }

  void _goBack() {
    if (_pathHistory.isNotEmpty) {
      setState(() {
        _currentPath = _pathHistory.removeLast();
      });
      _loadFiles();
    } else {
      final parent = _currentPath.substring(0, _currentPath.lastIndexOf('/'));
      if (parent.isNotEmpty) {
        setState(() {
          _currentPath = parent;
        });
        _loadFiles();
      }
    }
  }

  void _goHome() {
    _pathHistory.clear();
    setState(() {
      _currentPath = '/sdcard';
    });
    _loadFiles();
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('文件管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: _goHome,
            tooltip: '主目录',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFiles,
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
              // 路径导航
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: Colors.grey[100],
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_upward),
                      onPressed: _goBack,
                      tooltip: '上级目录',
                    ),
                    Expanded(
                      child: Text(
                        _currentPath,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // 文件列表
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _files.isEmpty
                        ? const Center(child: Text('目录为空'))
                        : ListView.builder(
                            itemCount: _files.length,
                            itemBuilder: (context, index) {
                              final file = _files[index];
                              return ListTile(
                                leading: Icon(
                                  file.isDirectory
                                      ? Icons.folder
                                      : Icons.insert_drive_file,
                                  color: file.isDirectory
                                      ? Colors.orange
                                      : Colors.blueGrey,
                                ),
                                title: Text(file.name),
                                subtitle: Text(
                                  file.isDirectory
                                      ? '文件夹'
                                      : _formatSize(file.size),
                                ),
                                trailing: file.isDirectory
                                    ? const Icon(Icons.chevron_right)
                                    : null,
                                onTap: file.isDirectory
                                    ? () => _navigateTo(file.path)
                                    : null,
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
