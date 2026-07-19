import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tretech_mobile/main.dart';
import 'package:tretech_mobile/shared/theme/theme_mode_provider.dart';

void main() {
  testWidgets('App initializes without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [themeModeProvider.overrideWith(_TestThemeModeNotifier.new)],
        child: const TretechApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 1800));
  });
}

class _TestThemeModeNotifier extends ThemeModeNotifier {
  @override
  ThemeMode build() => ThemeMode.dark;
}
