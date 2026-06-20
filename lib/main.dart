import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'theme_provider.dart';
import 'clock_screen.dart';

/// 应用程序入口
void main() {
  // 确保Flutter绑定初始化
  WidgetsFlutterBinding.ensureInitialized();

  // 强制竖屏方向
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // 强制全屏显示，隐藏状态栏和导航栏
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  runApp(
    // 使用 Provider 管理主题状态
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const FlipClockApp(),
    ),
  );
}

/// 应用根组件
class FlipClockApp extends StatelessWidget {
  const FlipClockApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      title: '翻页时钟番茄钟',
      debugShowCheckedModeBanner: false,
      // 根据主题Provider切换深色/浅色模式
      themeMode: themeProvider.isDark ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF5F0E8), // 浅色暖米色背景
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8B7355),
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF1A1A2E), // 深色背景
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE0C097),
          brightness: Brightness.dark,
        ),
      ),
      home: const ClockScreen(),
    );
  }
}
