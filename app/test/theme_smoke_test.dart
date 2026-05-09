import 'package:altatheeb_mobile_app/app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Light + Dark themes render scaffold without errors', (tester) async {
    for (final theme in [AppTheme.light(), AppTheme.dark()]) {
      await tester.pumpWidget(MaterialApp(
        theme: theme,
        home: const Scaffold(body: Center(child: Text('hello'))),
      ));
      expect(find.text('hello'), findsOneWidget);
    }
  });
}
