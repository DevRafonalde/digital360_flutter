import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'ui/screens/splash_screen.dart';

class Digital360App extends StatelessWidget {
  const Digital360App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Digital 360 - Smart HAS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      home: const SplashScreen(),
    );
  }
}
