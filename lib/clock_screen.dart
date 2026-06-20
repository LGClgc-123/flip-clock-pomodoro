import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'theme_provider.dart';
import 'pomodoro_provider.dart';
import 'flip_digit_card.dart';
import 'pomodoro_panel.dart';
import 'quote_scroll.dart';

/// 主时钟界面 - 包含翻页时钟、日期、番茄钟控制面板和励志标语
class ClockScreen extends StatefulWidget {
  const ClockScreen({super.key});

  @override
  State<ClockScreen> createState() => _ClockScreenState();
}

class _ClockScreenState extends State<ClockScreen> {
  DateTime _currentTime = DateTime.now();
  Timer? _clockTimer;

  // ==================== 励志标语列表 ====================
  static const List<String> motivationalQuotes = [
    '专注当下，成就未来',
    '每一次专注，都是对梦想的投资',
    '时间是最公平的资源，善用每一秒',
    '坚持就是胜利，番茄见证你的努力',
    '心无旁骛，方能致远',
    '今天多一份专注，明天多一份收获',
    '把大目标拆成小任务，一步步实现',
    '休息是为了走更远的路',
    '高效工作，快乐生活',
    '自律给你自由',
    '积少成多，聚沙成塔',
    '行动是治愈焦虑的良药',
    '不积跬步，无以至千里',
    '每一个番茄都是一次小小的胜利',
    '保持节奏，稳步前进',
  ];

  @override
  void initState() {
    super.initState();
    // 每秒更新时钟
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _currentTime = DateTime.now();
      });
    });

    // 初始化番茄钟完成回调
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pomodoroProvider = context.read<PomodoroProvider>();
      pomodoroProvider.onTimerComplete = _onPomodoroComplete;
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  /// 番茄钟计时完成回调 - 播放铃声并显示通知
  void _onPomodoroComplete() {
    _playNotificationSound();
    _showCompletionDialog();
  }

  /// 播放提示铃声（使用系统音效）
  void _playNotificationSound() {
    // 使用HapticFeedback提供触觉反馈
    HapticFeedback.heavyImpact();
    // 延迟后再震动一次，模拟铃声节奏
    Future.delayed(const Duration(milliseconds: 300), () {
      HapticFeedback.heavyImpact();
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      HapticFeedback.heavyImpact();
    });
  }

  /// 显示计时完成弹窗
  void _showCompletionDialog() {
    final pomodoroProvider = context.read<PomodoroProvider>();
    final phaseName = pomodoroProvider.phaseName;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          '⏰ $phaseName结束！',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        content: Text(
          pomodoroProvider.currentPhase == PomodoroPhase.work
              ? '太棒了！你已完成一个番茄！\n累计完成 ${pomodoroProvider.totalCompletedPomodoros} 个番茄'
              : '休息结束，准备开始新一轮工作！',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('好的', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  /// 获取中文星期
  String _getChineseWeekday(DateTime date) {
    const weekdays = ['星期日', '星期一', '星期二', '星期三', '星期四', '星期五', '星期六'];
    return weekdays[date.weekday % 7];
  }

  /// 格式化日期为 YYYY年MM月DD日
  String _formatDate(DateTime date) {
    return '${date.year}年${date.month.toString().padLeft(2, '0')}月${date.day.toString().padLeft(2, '0')}日';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pomodoroProvider = context.watch<PomodoroProvider>();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ========== 顶部：主题切换按钮 ==========
            _buildTopBar(isDark),

            // ========== 日期和星期显示 ==========
            const SizedBox(height: 16),
            _buildDateSection(isDark),

            // ========== 翻页时钟主体 ==========
            const Spacer(flex: 2),
            _buildFlipClock(isDark),

            // ========== 番茄钟计时显示 ==========
            const SizedBox(height: 24),
            _buildPomodoroInfo(pomodoroProvider, isDark),

            // ========== 番茄钟控制面板（可收起/展开）==========
            const SizedBox(height: 16),
            PomodoroPanel(),

            // ========== 底部励志标语滚动 ==========
            const Spacer(),
            QuoteScroll(quotes: motivationalQuotes),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// 构建顶部栏（主题切换按钮）
  Widget _buildTopBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // 主题切换按钮
          GestureDetector(
            onTap: () {
              context.read<ThemeProvider>().toggleTheme();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF3D3D5C)
                    : const Color(0xFFE8DFD0),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isDark ? Icons.dark_mode : Icons.light_mode,
                    size: 20,
                    color: isDark ? const Color(0xFFE0C097) : const Color(0xFF8B7355),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isDark ? '深色' : '浅色',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? const Color(0xFFE0C097) : const Color(0xFF8B7355),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建日期区域
  Widget _buildDateSection(bool isDark) {
    return Column(
      children: [
        Text(
          _formatDate(_currentTime),
          style: TextStyle(
            fontSize: 18,
            color: isDark ? const Color(0xFFB0A090) : const Color(0xFF6B5B4B),
            fontWeight: FontWeight.w500,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _getChineseWeekday(_currentTime),
          style: TextStyle(
            fontSize: 16,
            color: isDark ? const Color(0xFF908070) : const Color(0xFF8B7B6B),
          ),
        ),
      ],
    );
  }

  /// 构建翻页时钟（时:分:秒，六张独立卡片）
  Widget _buildFlipClock(bool isDark) {
    final hour = _currentTime.hour;
    final minute = _currentTime.minute;
    final second = _currentTime.second;

    // 分离各位数字
    final h1 = hour ~/ 10; // 时的十位
    final h2 = hour % 10;  // 时的个位
    final m1 = minute ~/ 10;
    final m2 = minute % 10;
    final s1 = second ~/ 10;
    final s2 = second % 10;

    // 根据屏幕宽度自适应卡片大小
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth - 80) / 6; // 6张卡片 + 间距
    final cardHeight = cardWidth * 1.4;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 时 - 十位
        FlipDigitCard(digit: h1, width: cardWidth, height: cardHeight),
        const SizedBox(width: 6),
        // 时 - 个位
        FlipDigitCard(digit: h2, width: cardWidth, height: cardHeight),

        // 冒号分隔符
        _buildColon(isDark, cardHeight),

        // 分 - 十位
        FlipDigitCard(digit: m1, width: cardWidth, height: cardHeight),
        const SizedBox(width: 6),
        // 分 - 个位
        FlipDigitCard(digit: m2, width: cardWidth, height: cardHeight),

        // 冒号分隔符
        _buildColon(isDark, cardHeight),

        // 秒 - 十位
        FlipDigitCard(digit: s1, width: cardWidth, height: cardHeight),
        const SizedBox(width: 6),
        // 秒 - 个位
        FlipDigitCard(digit: s2, width: cardWidth, height: cardHeight),
      ],
    );
  }

  /// 构建冒号分隔符（带闪烁效果）
  Widget _buildColon(bool isDark, double height) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? const Color(0xFFE0C097) : const Color(0xFF8B7355),
            ),
          ),
          SizedBox(height: height * 0.2),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? const Color(0xFFE0C097) : const Color(0xFF8B7355),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建番茄钟信息区域
  Widget _buildPomodoroInfo(PomodoroProvider provider, bool isDark) {
    return Column(
      children: [
        // 当前阶段标签
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: provider.phaseColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: provider.phaseColor.withValues(alpha: 0.5)),
          ),
          child: Text(
            '${provider.phaseName}模式',
            style: TextStyle(
              fontSize: 14,
              color: provider.phaseColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 8),
        // 倒计时显示
        Text(
          provider.formattedRemainingTime,
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF2C2C2C),
            letterSpacing: 4,
          ),
        ),
        const SizedBox(height: 4),
        // 番茄计数
        Text(
          '🍅 累计完成 ${provider.totalCompletedPomodoros} 个番茄',
          style: TextStyle(
            fontSize: 14,
            color: isDark ? const Color(0xFF908070) : const Color(0xFF8B7B6B),
          ),
        ),
      ],
    );
  }
}
