import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:my_pocket/screens/add_multiple_expenses_screen.dart';
import 'package:universal_html/html.dart' as html;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/expenses_list_screen.dart';
import 'screens/categories_screen.dart';
import 'screens/payment_methods_screen.dart';
import 'screens/settings_screen.dart';
import 'firebase_options.dart';
import 'services/user_preferences_service.dart';
import 'screens/bulk_add_expenses.dart';
import 'widgets/splash_screen.dart';
import 'utils/firebase_user_utils.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  await EasyLocalization.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(EasyLocalization(
    supportedLocales: const [Locale('en'), Locale('es'), Locale('pt')],
    path: 'lib/l10n',
    fallbackLocale: const Locale('en'),
    child: const MyApp(),
  ));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light;
  bool _loadingPrefs = true;

  @override
  void initState() {
    super.initState();
    _loadUserPrefs();
  }

  void _loadUserPrefs() async {
    await withCurrentUserAsync((user) async {
      try {
        final prefs = await UserPreferencesService().getPreferences(user.uid);
        setState(() {
          _themeMode = prefs.darkMode ? ThemeMode.dark : ThemeMode.light;
          _loadingPrefs = false;
        });
      } catch (e) {
        setState(() {
          _themeMode = ThemeMode.light;
          _loadingPrefs = false;
        });
      }
    });
    if (FirebaseAuth.instance.currentUser == null) {
      setState(() {
        _themeMode = ThemeMode.light;
        _loadingPrefs = false;
      });
    }
  }

  void setThemeMode(ThemeMode mode) {
    setState(() => _themeMode = mode);
  }

  void setLocale(Locale locale) {
    // No-op: EasyLocalization handles locale
  }

  String _getLoadingMessage() {
    // Fallback message when localization context is not available yet
    return 'Loading preferences...';
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingPrefs) {
      return MaterialApp(
        home: SplashScreen(
          message: _getLoadingMessage(),
        ),
      );
    }
    return BrowserTabTitleUpdater(
      child: Builder(
        builder: (context) => MaterialApp(
          title: 'Meu Bolso',
          theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                  seedColor: Colors.blueAccent,
                  brightness: Brightness.light,
                  surface: Colors.grey[50]),
              useMaterial3: true,
              brightness: Brightness.light,
              cardTheme: const CardTheme(
                color: Colors.white,
              ),
              buttonTheme: const ButtonThemeData(
                buttonColor: Colors.white,
                textTheme: ButtonTextTheme.primary,
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
              ),
              scaffoldBackgroundColor:
                  const Color.fromARGB(255, 241, 243, 249)),
          darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                  seedColor: Colors.deepPurple, brightness: Brightness.dark),
              useMaterial3: true,
              brightness: Brightness.dark),
          themeMode: _themeMode,
          locale: context.locale,
          supportedLocales: context.supportedLocales,
          localizationsDelegates: context.localizationDelegates,
          home: StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return SplashScreen(
                  message: 'loading_app'.tr(),
                );
              }
              if (snapshot.hasData) {
                return DashboardScreen();
              } else {
                return const LoginScreen();
              }
            },
          ),
          routes: {
            '/login': (context) => const LoginScreen(),
            '/dashboard': (context) => DashboardScreen(),
            '/add-expenses': (context) => AddMultipleExpensesScreen(),
            '/expenses-list': (context) => const ExpensesListScreen(),
            '/categories': (context) => const CategoriesScreen(),
            '/paymentMethods': (context) => const PaymentMethodsScreen(),
            '/settings': (context) => SettingsScreen(
                  onThemeChanged: setThemeMode,
                  onLocaleChanged: setLocale,
                  themeMode: _themeMode,
                ),
            '/bulk-add-expenses': (context) => const BulkAddExpensesScreen(),
          },
        ),
      ),
    );
  }
}

class BrowserTabTitleUpdater extends StatelessWidget {
  final Widget child;
  const BrowserTabTitleUpdater({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    // Listen to locale changes and update the browser tab title
    context.locale;
    html.document.title = 'Meu Bolso';
    return child;
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Replace this with your navigation or main screen
    return Scaffold(
      appBar: AppBar(title: Text('Meu Bolso')),
      body: Center(child: Text('welcome'.tr())),
    );
  }
}
