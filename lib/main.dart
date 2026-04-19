import 'package:acervo360/pages/welcome_screen.dart';
import 'package:acervo360/services/theme_service.dart';
import 'package:acervo360/services/api_service.dart';
import 'package:acervo360/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await ThemeService.init();
  await ApiService.init();

  runApp(const Acervo360App());
}

class Acervo360App extends StatelessWidget {
  const Acervo360App({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeService.themeMode,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'Acervo 360',
          debugShowCheckedModeBanner: false,
          locale: const Locale('pt', 'BR'),
          supportedLocales: const [Locale('pt', 'BR')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: mode,
          home: const WelcomePage(),
        );
      },
    );
  }
}

// Removed MissingSupabaseConfigApp
