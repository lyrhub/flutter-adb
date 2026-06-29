import 'dart:io';

class NetworkScanner {
  static Future<String> getSubnet() async {
    try {
      final interfaces = await NetworkInterface.list();
      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          if (!addr.isLoopback && addr.type == InternetAddressType.IPv4) {
            final ip = addr.address;
            return ip.substring(0, ip.lastIndexOf('.'));
          }
        }
      }
    } catch (e) {
      // ignore
    }
    return '192.168.1';
  }

  static Future<List<String>> scanNetwork(
    String subnet,
    void Function(String) onDeviceFound,
  ) async {
    final devices = <String>[];

    for (int i = 1; i <= 254; i++) {
      final ip = '$subnet.$i';
      try {
        final socket = await Socket.connect(
          ip,
          5555,
          timeout: const Duration(milliseconds: 300),
        );
        devices.add(ip);
        onDeviceFound(ip);
        await socket.close();
      } catch (e) {
        // 连接失败，跳过
      }
    }

    return devices;
  }
}
