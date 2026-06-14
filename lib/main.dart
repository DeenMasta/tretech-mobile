import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'router/app_router.dart';
import 'shared/theme/app_colors.dart';
import 'shared/theme/app_theme.dart';
import 'shared/theme/theme_mode_provider.dart';
import 'core/constants/app_constants.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── System UI ──────────────────────────────────────────────
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF0F1117),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // Lock to portrait + landscape (allow both for tablet support)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // ── Hive ────────────────────────────────────────────────────
  await Hive.initFlutter();
  await Hive.openBox<dynamic>(AppConstants.hiveBoxUser);
  await Hive.openBox<dynamic>(AppConstants.hiveBoxSettings);

  runApp(
    // Riverpod root — wraps the entire widget tree
    const ProviderScope(
      child: TretechApp(),
    ),
  );
}

class TretechApp extends ConsumerWidget {
  const TretechApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    // Resolve the effective brightness so the runtime AppColors getters
    // (read inside screen widgets) match the ThemeData we hand to MaterialApp.
    final platformBrightness =
        MediaQuery.platformBrightnessOf(context);
    final effectiveBrightness = switch (themeMode) {
      ThemeMode.light => Brightness.light,
      ThemeMode.dark => Brightness.dark,
      ThemeMode.system => platformBrightness,
    };
    final isDark = effectiveBrightness == Brightness.dark;

    // Build the matching theme. _build() also sets AppColors.brightness, but
    // set it here too so it is correct even before the first frame paints.
    AppColors.brightness = effectiveBrightness;
    final theme = isDark ? AppTheme.dark : AppTheme.light;

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: theme,
      routerConfig: router,
    );
  }
}

