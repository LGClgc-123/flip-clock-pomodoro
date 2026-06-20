import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 主题管理Provider - 管理深色/浅色主题切换
class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'is_dark_theme';

  bool _isDark = true; // 默认深色主题

  bool get isDark => _isDark;

  ThemeProvider() {
    _loadTheme();
  }

  /// 从本地存储加载主题偏好
  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDark = prefs.getBool(_themeKey) ?? true; // 默认深色
    notifyListeners();
  }

  /// 切换深色/浅色主题
  Future<void> toggleTheme() async {
    _isDark = !_isDark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, _isDark);
    notifyListeners();
  }
}
