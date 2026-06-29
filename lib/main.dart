import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/adb_client.dart';
import 'pages/connect_page.dart';
import 'pages/apps_page.dart';
import 'pages/terminal_page.dart';
import 'pages/files_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AdbClient(),
      child: MaterialApp(
        title: 'ADB工具',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const HomePage(),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const ConnectPage(),
    const AppsPage(),
    const TerminalPage(),
    const FilesPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.link),
            label: '连接',
          ),
          NavigationDestination(
            icon: Icon(Icons.apps),
            label: '应用',
          ),
          NavigationDestination(
            icon: Icon(Icons.terminal),
            label: '终端',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder),
            label: '文件',
          ),
        ],
      ),
    );
  }
}
