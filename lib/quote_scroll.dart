import 'dart:async';
import 'package:flutter/material.dart';

/// 底部励志标语横向滚动组件
/// 缓慢从右向左滚动，循环播放
class QuoteScroll extends StatefulWidget {
  /// 标语文案列表
  final List<String> quotes;

  const QuoteScroll({super.key, required this.quotes});

  @override
  State<QuoteScroll> createState() => _QuoteScrollState();
}

class _QuoteScrollState extends State<QuoteScroll> {
  /// 滚动控制器
  late ScrollController _scrollController;

  /// 当前滚动位置
  double _scrollOffset = 0.0;

  /// 滚动速度（像素/帧）
  static const double _scrollSpeed = 0.5;

  /// 是否正在滚动
  bool _isScrolling = true;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController(initialScrollOffset: 0);
    // 启动定时滚动
    _startScrolling();
  }

  /// 启动滚动定时器
  void _startScrolling() {
    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted && _isScrolling) {
        final maxScroll = _scrollController.position.maxScrollExtent;
        if (_scrollOffset >= maxScroll) {
          // 滚动到末尾后重置到开头
          _scrollOffset = 0;
          _scrollController.jumpTo(0);
        } else {
          _scrollOffset += _scrollSpeed;
          _scrollController.jumpTo(_scrollOffset);
        }
        _startScrolling(); // 递归调用实现持续滚动
      }
    });
  }

  @override
  void dispose() {
    _isScrolling = false;
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 32,
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(), // 禁止手动滚动
        itemCount: 100, // 重复多次实现无缝循环效果
        itemBuilder: (context, index) {
          final quoteIndex = index % widget.quotes.length;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Center(
              child: Text(
                '✨ ${widget.quotes[quoteIndex]} ✨',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? const Color(0xFF706050)
                      : const Color(0xFF9B8B7B),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
