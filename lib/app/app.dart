import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:artist_dubai/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_strings.dart';
import '../core/di/injection_container.dart';
import '../core/services/locale_provider.dart';
import 'app_theme.dart';
import 'routes/app_router.dart';

class AppCustomScrollBehavior extends MaterialScrollBehavior {
  const AppCustomScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}

class ArtistDubaiApp extends StatefulWidget {
  const ArtistDubaiApp({super.key});

  @override
  State<ArtistDubaiApp> createState() => _ArtistDubaiAppState();
}

class _ArtistDubaiAppState extends State<ArtistDubaiApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Future<bool> didPushRouteInformation(RouteInformation routeInformation) async {
    final uri = routeInformation.uri;
    final target = AppRouter.parseDeepLink(uri);
    if (target != null && target.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        AppRouter.router.go(target);
      });
      return true;
    }
    return super.didPushRouteInformation(routeInformation);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<LocaleProvider>.value(
      value: sl<LocaleProvider>(),
      child: Consumer<LocaleProvider>(
        builder: (context, localeProvider, _) {
          return MaterialApp.router(
            title: AppStrings.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.dark,
            scrollBehavior: const AppCustomScrollBehavior(),
            routerConfig: AppRouter.router,
            locale: localeProvider.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            localeResolutionCallback: (locale, supportedLocales) {
              for (final supported in supportedLocales) {
                if (supported.languageCode == localeProvider.locale.languageCode) {
                  return supported;
                }
              }
              return supportedLocales.first;
            },
          );
        },
      ),
    );
  }
}
