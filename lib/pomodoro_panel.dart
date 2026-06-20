import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'pomodoro_provider.dart';

/// 番茄钟控制面板 - 可收起/展开，包含开始、暂停、重置、模式切换按钮
class PomodoroPanel extends StatefulWidget {
  const PomodoroPanel({super.key});

  @override
  State<PomodoroPanel> createState() => _PomodoroPanelState();
}

class _PomodoroPanelState extends State<PomodoroPanel>
    with SingleTickerProviderStateMixin {
  /// 面板是否展开
  bool _isExpanded = false;

  /// 展开/收起动画控制器
  late AnimationController _expandController;
  late Animation<double> _expandAnimation;

  /// 是否显示设置弹窗
  bool _showSettings = false;

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _expandController.dispose();
    super.dispose();
  }

  /// 切换面板展开/收起
  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _expandController.forward();
      } else {
        _expandController.reverse();
      }
    });
  }

  /// 显示时长设置弹窗
  void _showSettingsDialog() {
    final provider = context.read<PomodoroProvider>();

    showDialog(
      context: context,
      builder: (context) => _SettingsDialog(provider: provider),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<PomodoroProvider>();

    return Column(
      children: [
        // ========== 收起/展开按钮 ==========
        GestureDetector(
          onTap: _toggleExpand,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF3D3D5C) : const Color(0xFFE8DFD0),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  size: 20,
                  color: isDark ? const Color(0xFFE0C097) : const Color(0xFF8B7355),
                ),
                const SizedBox(width: 4),
                Text(
                  _isExpanded ? '收起控制面板' : '展开控制面板',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? const Color(0xFFE0C097) : const Color(0xFF8B7355),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ========== 展开后的控制面板 ==========
        SizeTransition(
          sizeFactor: _expandAnimation,
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Column(
              children: [
                // 主控制按钮行
                _buildControlButtons(provider, isDark),
                const SizedBox(height: 10),
                // 辅助按钮行（模式切换 + 设置）
                _buildSecondaryButtons(provider, isDark),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 构建主控制按钮（开始/暂停 + 重置）
  Widget _buildControlButtons(PomodoroProvider provider, bool isDark) {
    final isRunning = provider.status == PomodoroStatus.running;
    final isPaused = provider.status == PomodoroStatus.paused;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 开始/暂停按钮
        _buildActionButton(
          icon: isRunning ? Icons.pause : Icons.play_arrow,
          label: isRunning ? '暂停' : (isPaused ? '继续' : '开始'),
          color: isRunning
              ? const Color(0xFFFFA726)
              : const Color(0xFF66BB6A),
          onTap: () {
            if (isRunning) {
              provider.pause();
            } else {
              provider.start();
            }
          },
          isDark: isDark,
        ),
        const SizedBox(width: 16),
        // 重置按钮
        _buildActionButton(
          icon: Icons.refresh,
          label: '重置',
          color: const Color(0xFFEF5350),
          onTap: () => provider.reset(),
          isDark: isDark,
        ),
      ],
    );
  }

  /// 构建辅助按钮（工作/休息切换 + 设置）
  Widget _buildSecondaryButtons(PomodoroProvider provider, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 工作模式按钮
        _buildSmallButton(
          icon: Icons.work,
          label: '工作',
          isActive: provider.currentPhase == PomodoroPhase.work,
          onTap: () => provider.switchToWork(),
          isDark: isDark,
        ),
        const SizedBox(width: 10),
        // 休息模式按钮
        _buildSmallButton(
          icon: Icons.coffee,
          label: '休息',
          isActive: provider.currentPhase == PomodoroPhase.shortBreak ||
              provider.currentPhase == PomodoroPhase.longBreak,
          onTap: () => provider.switchToBreak(),
          isDark: isDark,
        ),
        const SizedBox(width: 10),
        // 设置按钮
        _buildSmallButton(
          icon: Icons.settings,
          label: '设置',
          isActive: false,
          onTap: _showSettingsDialog,
          isDark: isDark,
        ),
      ],
    );
  }

  /// 构建大圆角操作按钮
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建小圆角辅助按钮
  Widget _buildSmallButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    final activeColor = const Color(0xFFE0C097);
    final inactiveColor = isDark ? const Color(0xFF606080) : const Color(0xFFA09080);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? activeColor.withValues(alpha: 0.2)
              : (isDark ? const Color(0xFF2D2D44) : const Color(0xFFF0E8D8)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? activeColor : inactiveColor,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? activeColor : inactiveColor,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isActive ? activeColor : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 时长设置弹窗
class _SettingsDialog extends StatefulWidget {
  final PomodoroProvider provider;
  const _SettingsDialog({required this.provider});

  @override
  State<_SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<_SettingsDialog> {
  late TextEditingController _workCtrl;
  late TextEditingController _shortBreakCtrl;
  late TextEditingController _longBreakCtrl;

  @override
  void initState() {
    super.initState();
    _workCtrl = TextEditingController(text: widget.provider.workMinutes.toString());
    _shortBreakCtrl = TextEditingController(text: widget.provider.shortBreakMinutes.toString());
    _longBreakCtrl = TextEditingController(text: widget.provider.longBreakMinutes.toString());
  }

  @override
  void dispose() {
    _workCtrl.dispose();
    _shortBreakCtrl.dispose();
    _longBreakCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('⏱️ 自定义时长', textAlign: TextAlign.center),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSettingRow('工作时长（分钟）', _workCtrl),
          const SizedBox(height: 12),
          _buildSettingRow('短休息时长（分钟）', _shortBreakCtrl),
          const SizedBox(height: 12),
          _buildSettingRow('长休息时长（分钟）', _longBreakCtrl),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () {
            // 保存设置
            final work = int.tryParse(_workCtrl.text) ?? 25;
            final short = int.tryParse(_shortBreakCtrl.text) ?? 5;
            final long = int.tryParse(_longBreakCtrl.text) ?? 15;
            widget.provider.setWorkMinutes(work);
            widget.provider.setShortBreakMinutes(short);
            widget.provider.setLongBreakMinutes(long);
            Navigator.pop(context);
          },
          child: const Text('保存'),
        ),
      ],
    );
  }

  Widget _buildSettingRow(String label, TextEditingController controller) {
    return Row(
      children: [
        Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
        SizedBox(
          width: 60,
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
