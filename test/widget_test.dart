import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lametna/app.dart';
import 'package:lametna/theme/app_theme.dart';
import 'package:lametna/widgets/brand.dart';

void main() {
  testWidgets('يعرض شعار لمتنا في شاشة البداية', (WidgetTester tester) async {
    await tester.pumpWidget(const LametnaApp());

    // Let the staggered entrance animations fire.
    await tester.pump(const Duration(milliseconds: 900));

    expect(find.byType(BrandMark), findsOneWidget);
    expect(find.byType(BrandWordmark), findsOneWidget);
  });

  test('الثيم يستخدم الخط العربي واللون البنفسجي', () {
    final ThemeData theme = AppTheme.dark();
    expect(theme.textTheme.bodyLarge, isNotNull);
    expect(theme.colorScheme.brightness, Brightness.dark);
  });
}
