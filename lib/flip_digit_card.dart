import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 翻页时钟单个数字卡片组件
/// 实现上下翻转动画效果，模拟机械翻页时钟
class FlipDigitCard extends StatefulWidget {
  /// 当前显示的数字
  final int digit;

  /// 卡片宽度
  final double width;

  /// 卡片高度
  final double height;

  const FlipDigitCard({
    super.key,
    required this.digit,
    this.width = 72,
    this.height = 100,
  });

  @override
  State<FlipDigitCard> createState() => _FlipDigitCardState();
}

class _FlipDigitCardState extends State<FlipDigitCard>
    with SingleTickerProviderStateMixin {
  /// 上一次显示的数字
  int _previousDigit = 0;

  /// 动画控制器
  late AnimationController _controller;

  /// 翻页动画（0.0 = 未翻转, 1.0 = 完全翻转）
  late Animation<double> _flipAnimation;

  /// 是否正在执行翻转动画
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _previousDigit = widget.digit;

    // 创建翻页动画控制器，时长600毫秒
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // 创建翻转角度动画曲线（带回弹效果）
    _flipAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutBack, // 回弹曲线
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // 动画完成后更新状态
        setState(() {
          _isAnimating = false;
          _previousDigit = widget.digit;
        });
      }
    });
  }

  @override
  void didUpdateWidget(FlipDigitCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 当数字变化时触发翻转动画
    if (oldWidget.digit != widget.digit && !_isAnimating) {
      _previousDigit = oldWidget.digit;
      _isAnimating = true;
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 深色/浅色主题颜色配置
    final cardBgColor = isDark ? const Color(0xFF2D2D44) : const Color(0xFFFFFFFF);
    final cardDividerColor = isDark ? const Color(0xFF1A1A2E) : const Color(0xFFD4C5A9);
    final textColor = isDark ? Colors.white : const Color(0xFF2C2C2C);
    final shadowColor = isDark ? Colors.black54 : Colors.black26;

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Stack(
        children: [
          // ========== 底层：静态显示当前数字 ==========
          _buildDigitFace(
            digit: widget.digit,
            color: cardBgColor,
            textColor: textColor,
            shadowColor: shadowColor,
          ),

          // ========== 中间分割线 ==========
          Positioned(
            left: 0,
            right: 0,
            top: widget.height / 2 - 0.5,
            child: Container(
              height: 1,
              color: cardDividerColor,
            ),
          ),

          // ========== 翻页动画层 ==========
          if (_isAnimating)
            _FlipAnimationWidget(
              animation: _flipAnimation,
              previousDigit: _previousDigit,
              currentDigit: widget.digit,
              cardBgColor: cardBgColor,
              textColor: textColor,
              shadowColor: shadowColor,
              width: widget.width,
              height: widget.height,
            ),

          // ========== 卡片边框和阴影 ==========
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark ? const Color(0xFF3D3D5C) : const Color(0xFFC0B090),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: shadowColor,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建单个数字面（上半+下半）
  Widget _buildDigitFace({
    required int digit,
    required Color color,
    required Color textColor,
    required Color shadowColor,
  }) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          digit.toString(),
          style: TextStyle(
            fontSize: widget.height * 0.55,
            fontWeight: FontWeight.bold,
            color: textColor,
            letterSpacing: 2,
            shadows: [
              Shadow(
                color: shadowColor,
                blurRadius: 2,
                offset: const Offset(1, 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 上半部分裁剪器
class _TopClipper extends CustomClipper<Rect> {
  final double height;
  _TopClipper({required this.height});

  @override
  Rect getClip(Size size) => Rect.fromLTRB(0, 0, size.width, height / 2);

  @override
  bool shouldReclip(covariant _TopClipper oldClipper) => false;
}

/// 下半部分裁剪器
class _BottomClipper extends CustomClipper<Rect> {
  final double height;
  _BottomClipper({required this.height});

  @override
  Rect getClip(Size size) =>
      Rect.fromLTRB(0, height / 2, size.width, height);

  @override
  bool shouldReclip(covariant _BottomClipper oldClipper) => false;
}

/// 翻页动画组件 - 使用 AnimatedWidget 实现高性能动画
class _FlipAnimationWidget extends AnimatedWidget {
  final int previousDigit;
  final int currentDigit;
  final Color cardBgColor;
  final Color textColor;
  final Color shadowColor;
  final double width;
  final double height;

  const _FlipAnimationWidget({
    required Animation<double> animation,
    required this.previousDigit,
    required this.currentDigit,
    required this.cardBgColor,
    required this.textColor,
    required this.shadowColor,
    required this.width,
    required this.height,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    final flipValue = (listenable as Animation<double>).value;

    return Stack(
      children: [
        // --- 上半部分：旧数字向下翻出 ---
        ClipRect(
          clipper: _TopClipper(height: height),
          child: Transform(
            alignment: Alignment.bottomCenter,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001) // 透视效果
              ..rotateX(flipValue * math.pi / 2), // 翻转0~90度
            child: _buildStaticDigitFace(
              digit: previousDigit,
              width: width,
              height: height,
              color: cardBgColor,
              textColor: textColor,
              shadowColor: shadowColor,
            ),
          ),
        ),

        // --- 下半部分：新数字翻入 ---
        ClipRect(
          clipper: _BottomClipper(height: height),
          child: Transform(
            alignment: Alignment.topCenter,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001) // 透视效果
              ..rotateX(-(1 - flipValue) * math.pi / 2), // 翻转-90~0度
            child: _buildStaticDigitFace(
              digit: currentDigit,
              width: width,
              height: height,
              color: cardBgColor,
              textColor: textColor,
              shadowColor: shadowColor,
            ),
          ),
        ),
      ],
    );
  }
}

/// 构建静态数字面（供动画组件使用）
Widget _buildStaticDigitFace({
  required int digit,
  required double width,
  required double height,
  required Color color,
  required Color textColor,
  required Color shadowColor,
}) {
  return Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Center(
      child: Text(
        digit.toString(),
        style: TextStyle(
          fontSize: height * 0.55,
          fontWeight: FontWeight.bold,
          color: textColor,
          letterSpacing: 2,
          shadows: [
            Shadow(
              color: shadowColor,
              blurRadius: 2,
              offset: const Offset(1, 1),
            ),
          ],
        ),
      ),
    ),
  );
}
