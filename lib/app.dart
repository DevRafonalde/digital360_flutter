import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/navigation/navigator_key.dart';
import 'core/theme/app_theme.dart';
import 'providers/settings_provider.dart';
import 'ui/screens/splash_screen.dart';

class Digital360App extends StatelessWidget {
  const Digital360App({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Digital 360 - Smart HAS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: settings.themeMode,
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            textScaler: TextScaler.linear(settings.fontScale),
          ),
          child: child!,
        );
      },
      home: const SplashScreen(),
    );
  }
}
