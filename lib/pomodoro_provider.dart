import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 番茄钟状态枚举
enum PomodoroPhase { work, shortBreak, longBreak }

/// 番茄钟运行状态
enum PomodoroStatus { idle, running, paused }

/// 番茄钟计时器管理Provider
class PomodoroProvider extends ChangeNotifier {
  // ==================== 默认配置 ====================
  static const int defaultWorkMinutes = 25;       // 默认工作时间25分钟
  static const int defaultShortBreakMinutes = 5;  // 默认短休息5分钟
  static const int defaultLongBreakMinutes = 15;  // 默认长休息15分钟
  static const int defaultRoundsBeforeLongBreak = 4; // 每4轮进入长休息

  // ==================== 可自定义时长 ====================
  int _workMinutes = defaultWorkMinutes;
  int _shortBreakMinutes = defaultShortBreakMinutes;
  int _longBreakMinutes = defaultLongBreakMinutes;

  int get workMinutes => _workMinutes;
  int get shortBreakMinutes => _shortBreakMinutes;
  int get longBreakMinutes => _longBreakMinutes;

  // ==================== 运行时状态 ====================
  PomodoroPhase _currentPhase = PomodoroPhase.work;
  PomodoroStatus _status = PomodoroStatus.idle;
  int _remainingSeconds = defaultWorkMinutes * 60;
  int _completedWorkRounds = 0; // 已完成的工作轮数
  int _totalCompletedPomodoros = 0; // 累计完成的番茄数（持久化）

  PomodoroPhase get currentPhase => _currentPhase;
  PomodoroStatus get status => _status;
  int get remainingSeconds => _remainingSeconds;
  int get completedWorkRounds => _completedWorkRounds;
  int get totalCompletedPomodoros => _totalCompletedPomodoros;

  // ==================== 计时器 ====================
  Timer? _timer;

  // ==================== 回调 ====================
  VoidCallback? onTimerComplete; // 计时结束回调（用于播放铃声、弹出通知）

  PomodoroProvider() {
    _loadData();
  }

  /// 从本地存储加载持久化数据
  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    _totalCompletedPomodoros = prefs.getInt('total_pomodoros') ?? 0;
    _workMinutes = prefs.getInt('work_minutes') ?? defaultWorkMinutes;
    _shortBreakMinutes = prefs.getInt('short_break_minutes') ?? defaultShortBreakMinutes;
    _longBreakMinutes = prefs.getInt('long_break_minutes') ?? defaultLongBreakMinutes;
    _remainingSeconds = _workMinutes * 60;
    notifyListeners();
  }

  /// 保存累计番茄数到本地
  Future<void> _saveTotalPomodoros() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('total_pomodoros', _totalCompletedPomodoros);
  }

  /// 保存自定义时长配置
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('work_minutes', _workMinutes);
    await prefs.setInt('short_break_minutes', _shortBreakMinutes);
    await prefs.setInt('long_break_minutes', _longBreakMinutes);
  }

  // ==================== 控制方法 ====================

  /// 开始计时
  void start() {
    if (_status == PomodoroStatus.running) return;
    _status = PomodoroStatus.running;

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        notifyListeners();
      } else {
        _onPhaseComplete();
      }
    });
    notifyListeners();
  }

  /// 暂停计时
  void pause() {
    if (_status != PomodoroStatus.running) return;
    _status = PomodoroStatus.paused;
    _timer?.cancel();
    notifyListeners();
  }

  /// 重置当前计时
  void reset() {
    _timer?.cancel();
    _status = PomodoroStatus.idle;
    _remainingSeconds = _getPhaseDuration(_currentPhase);
    notifyListeners();
  }

  /// 手动切换到工作模式
  void switchToWork() {
    _timer?.cancel();
    _currentPhase = PomodoroPhase.work;
    _status = PomodoroStatus.idle;
    _remainingSeconds = _workMinutes * 60;
    notifyListeners();
  }

  /// 手动切换到休息模式
  void switchToBreak() {
    _timer?.cancel();
    // 根据已完成轮数判断是短休息还是长休息
    if (_completedWorkRounds >= defaultRoundsBeforeLongBreak) {
      _currentPhase = PomodoroPhase.longBreak;
      _remainingSeconds = _longBreakMinutes * 60;
    } else {
      _currentPhase = PomodoroPhase.shortBreak;
      _remainingSeconds = _shortBreakMinutes * 60;
    }
    _status = PomodoroStatus.idle;
    notifyListeners();
  }

  /// 获取当前阶段的总时长（秒）
  int _getPhaseDuration(PomodoroPhase phase) {
    switch (phase) {
      case PomodoroPhase.work:
        return _workMinutes * 60;
      case PomodoroPhase.shortBreak:
        return _shortBreakMinutes * 60;
      case PomodoroPhase.longBreak:
        return _longBreakMinutes * 60;
    }
  }

  /// 当前阶段计时完成
  void _onPhaseComplete() {
    _timer?.cancel();

    if (_currentPhase == PomodoroPhase.work) {
      // 工作阶段完成
      _completedWorkRounds++;
      _totalCompletedPomodoros++;
      _saveTotalPomodoros();

      // 判断是否进入长休息
      if (_completedWorkRounds >= defaultRoundsBeforeLongBreak) {
        _currentPhase = PomodoroPhase.longBreak;
        _remainingSeconds = _longBreakMinutes * 60;
        _completedWorkRounds = 0; // 重置轮数
      } else {
        _currentPhase = PomodoroPhase.shortBreak;
        _remainingSeconds = _shortBreakMinutes * 60;
      }
    } else {
      // 休息阶段完成，回到工作模式
      _currentPhase = PomodoroPhase.work;
      _remainingSeconds = _workMinutes * 60;
    }

    _status = PomodoroStatus.idle;
    notifyListeners();

    // 触发完成回调（铃声+通知）
    onTimerComplete?.call();
  }

  // ==================== 自定义时长 ====================

  /// 设置工作时长（分钟）
  Future<void> setWorkMinutes(int minutes) async {
    _workMinutes = minutes.clamp(1, 120);
    if (_status == PomodoroStatus.idle && _currentPhase == PomodoroPhase.work) {
      _remainingSeconds = _workMinutes * 60;
    }
    await _saveSettings();
    notifyListeners();
  }

  /// 设置短休息时长（分钟）
  Future<void> setShortBreakMinutes(int minutes) async {
    _shortBreakMinutes = minutes.clamp(1, 60);
    if (_status == PomodoroStatus.idle && _currentPhase == PomodoroPhase.shortBreak) {
      _remainingSeconds = _shortBreakMinutes * 60;
    }
    await _saveSettings();
    notifyListeners();
  }

  /// 设置长休息时长（分钟）
  Future<void> setLongBreakMinutes(int minutes) async {
    _longBreakMinutes = minutes.clamp(1, 60);
    if (_status == PomodoroStatus.idle && _currentPhase == PomodoroPhase.longBreak) {
      _remainingSeconds = _longBreakMinutes * 60;
    }
    await _saveSettings();
    notifyListeners();
  }

  /// 格式化剩余时间为 MM:SS
  String get formattedRemainingTime {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// 获取当前阶段中文名称
  String get phaseName {
    switch (_currentPhase) {
      case PomodoroPhase.work:
        return '工作';
      case PomodoroPhase.shortBreak:
        return '短休息';
      case PomodoroPhase.longBreak:
        return '长休息';
    }
  }

  /// 获取当前阶段对应颜色
  Color get phaseColor {
    switch (_currentPhase) {
      case PomodoroPhase.work:
        return const Color(0xFFFF6B6B); // 红色-工作
      case PomodoroPhase.shortBreak:
        return const Color(0xFF4ECDC4); // 青色-短休息
      case PomodoroPhase.longBreak:
        return const Color(0xFF45B7D1); // 蓝色-长休息
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
