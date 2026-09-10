import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_strings.dart';
import '../core/di/injection_container.dart';
import '../core/services/locale_provider.dart';
import 'app_theme.dart';
import 'routes/app_router.dart';

class ArtistDubaiApp extends StatelessWidget {
  const ArtistDubaiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<LocaleProvider>.value(
      value: sl<LocaleProvider>(),
      child: Consumer<LocaleProvider>(
        builder: (context, localeProvider, _) {
          return MaterialApp.router(
            key: ValueKey(localeProvider.locale.languageCode),
            title: AppStrings.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.dark,
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
