import 'package:flutter/material.dart';
import '../core/constants/app_strings.dart';
import 'app_theme.dart';
import 'routes/app_router.dart';

class ArtistDubaiApp extends StatelessWidget {
  const ArtistDubaiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      routerConfig: AppRouter.router,
    );
  }
}
