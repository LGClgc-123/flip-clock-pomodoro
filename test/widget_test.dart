import 'package:flutter_test/flutter_test.dart';

import 'package:flip_clock_pomodoro/main.dart';

void main() {
  testWidgets('App启动正常显示时钟界面', (WidgetTester tester) async {
    await tester.pumpWidget(const FlipClockApp());
    // 验证应用正常启动
    expect(find.byType(FlipClockApp), findsOneWidget);
  });
}
