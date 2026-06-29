import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/adb_client.dart';

class TerminalPage extends StatefulWidget {
  const TerminalPage({super.key});

  @override
  State<TerminalPage> createState() => _TerminalPageState();
}

class _TerminalPageState extends State<TerminalPage> {
  final _commandController = TextEditingController();
  final _outputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isExecuting = false;
  final List<String> _history = [];

  final List<Map<String, String>> _quickCommands = [
    {'cmd': 'pm list packages', 'name': '列出所有应用'},
    {'cmd': 'pm list packages -3', 'name': '第三方应用'},
    {'cmd': 'getprop ro.product.model', 'name': '设备型号'},
    {'cmd': 'getprop ro.build.version.release', 'name': '系统版本'},
    {'cmd': 'dumpsys battery', 'name': '电池信息'},
    {'cmd': 'reboot', 'name': '重启设备'},
    {'cmd': 'screencap -p /sdcard/screenshot.png', 'name': '截图'},
    {'cmd': 'ls /sdcard/', 'name': '查看SD卡'},
  ];

  @override
  void dispose() {
    _commandController.dispose();
    _outputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _executeCommand() async {
    final command = _commandController.text.trim();
    if (command.isEmpty) return;

    final adbClient = context.read<AdbClient>();
    if (!adbClient.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先连接设备')),
      );
      return;
    }

    setState(() {
      _isExecuting = true;
    });

    // 添加到历史
    _history.insert(0, command);
    if (_history.length > 20) {
      _history.removeLast();
    }

    try {
      final result = await adbClient.executeCommand(command);
      
      setState(() {
        final output = '> $command\n$result\n\n${_outputController.text}';
        _outputController.text = output;
        _isExecuting = false;
      });

      // 滚动到底部
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      setState(() {
        _outputController.text = '错误: $e\n\n${_outputController.text}';
        _isExecuting = false;
      });
    }

    _commandController.clear();
  }

  void _clearOutput() {
    _outputController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('终端命令'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: _clearOutput,
            tooltip: '清空输出',
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
              // 快捷命令
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _quickCommands.map((cmd) {
                    return ElevatedButton(
                      onPressed: _isExecuting
                          ? null
                          : () {
                              _commandController.text = cmd['cmd']!;
                            },
                      child: Text(cmd['name']!),
                    );
                  }).toList(),
                ),
              ),
              const Divider(height: 1),

              // 输出区域
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  color: Colors.grey[900],
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    child: Text(
                      _outputController.text.isEmpty
                          ? '等待命令...'
                          : _outputController.text,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: Colors.greenAccent,
                      ),
                    ),
                  ),
                ),
              ),

              // 输入区域
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commandController,
                        decoration: const InputDecoration(
                          hintText: '输入ADB命令...',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        onSubmitted: (_) => _executeCommand(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isExecuting ? null : _executeCommand,
                      child: _isExecuting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('执行'),
                    ),
                  ],
                ),
              ),

              // 历史记录
              if (_history.isNotEmpty) ...[
                const Divider(height: 1),
                SizedBox(
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: _history.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8, top: 8),
                        child: ActionChip(
                          label: Text(
                            _history[index],
                            style: const TextStyle(fontSize: 12),
                          ),
                          onPressed: () {
                            _commandController.text = _history[index];
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
