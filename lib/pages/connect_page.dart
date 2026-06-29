import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/adb_client.dart';
import '../utils/network_scanner.dart';

class ConnectPage extends StatefulWidget {
  const ConnectPage({super.key});

  @override
  State<ConnectPage> createState() => _ConnectPageState();
}

class _ConnectPageState extends State<ConnectPage> {
  final _ipController = TextEditingController(text: '192.168.1.100');
  final _portController = TextEditingController(text: '5555');
  final List<String> _scannedDevices = [];
  bool _isScanning = false;

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    final ip = _ipController.text.trim();
    final port = int.tryParse(_portController.text.trim()) ?? 5555;

    if (ip.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入IP地址')),
      );
      return;
    }

    final adbClient = context.read<AdbClient>();
    final success = await adbClient.connect(ip, port);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success ? '连接成功' : '连接失败')),
      );
    }
  }

  Future<void> _disconnect() async {
    await context.read<AdbClient>().disconnect();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已断开连接')),
      );
    }
  }

  Future<void> _scanNetwork() async {
    setState(() {
      _isScanning = true;
      _scannedDevices.clear();
    });

    final subnet = await NetworkScanner.getSubnet();
    final devices = await NetworkScanner.scanNetwork(subnet, (ip) {
      if (mounted) {
        setState(() {
          if (!_scannedDevices.contains(ip)) {
            _scannedDevices.add(ip);
          }
        });
      }
    });

    if (mounted) {
      setState(() {
        _isScanning = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ADB连接'),
      ),
      body: Consumer<AdbClient>(
        builder: (context, adbClient, child) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 连接状态
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(
                          adbClient.isConnected
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: adbClient.isConnected
                              ? Colors.green
                              : Colors.grey,
                          size: 32,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                adbClient.isConnected ? '已连接' : '未连接',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (adbClient.isConnected)
                                Text(
                                  '${adbClient.deviceIp}:${adbClient.devicePort}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // IP和端口输入
                if (!adbClient.isConnected) ...[
                  TextField(
                    controller: _ipController,
                    decoration: const InputDecoration(
                      labelText: '设备IP地址',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.computer),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _portController,
                    decoration: const InputDecoration(
                      labelText: '端口',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.settings_ethernet),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: adbClient.isConnecting ? null : _connect,
                    icon: adbClient.isConnecting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.link),
                    label: Text(adbClient.isConnecting ? '连接中...' : '连接'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ] else ...[
                  ElevatedButton.icon(
                    onPressed: _disconnect,
                    icon: const Icon(Icons.link_off),
                    label: const Text('断开连接'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
                const SizedBox(height: 24),

                // 局域网扫描
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        '局域网设备',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _isScanning ? null : _scanNetwork,
                      icon: _isScanning
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh),
                      label: Text(_isScanning ? '扫描中...' : '扫描'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _scannedDevices.isEmpty
                      ? Center(
                          child: Text(
                            _isScanning ? '正在扫描...' : '点击扫描发现设备',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _scannedDevices.length,
                          itemBuilder: (context, index) {
                            final ip = _scannedDevices[index];
                            return ListTile(
                              leading: const Icon(Icons.devices),
                              title: Text(ip),
                              subtitle: const Text('端口 5555'),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                _ipController.text = ip;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('已选择 $ip')),
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
