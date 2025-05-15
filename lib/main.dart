import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:universal_html/html.dart' as html;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/expenses_screen.dart';
import 'screens/expenses_list_screen.dart';
import 'screens/categories_screen.dart';
import 'screens/accounts_screen.dart';
import 'screens/settings_screen.dart';
import 'firebase_options.dart';
import 'services/user_preferences_service.dart';
import 'screens/bulk_add_expenses.dart';
import 'widgets/app_loading_indicator.dart';
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

  @override
  Widget build(BuildContext context) {
    if (_loadingPrefs) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: AppLoadingIndicator())),
      );
    }
    return BrowserTabTitleUpdater(
      child: Builder(
        builder: (context) => MaterialApp(
          title: 'app_title'.tr(),
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.deepPurple,
              brightness: Brightness.light,
            ),
            useMaterial3: true,
            brightness: Brightness.light,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.deepPurple,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
            brightness: Brightness.dark,
          ),
          themeMode: _themeMode,
          locale: context.locale,
          supportedLocales: context.supportedLocales,
          localizationsDelegates: context.localizationDelegates,
          home: StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: AppLoadingIndicator());
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
            '/expenses': (context) => const ExpensesScreen(),
            '/expenses-list': (context) => const ExpensesListScreen(),
            '/categories': (context) => const CategoriesScreen(),
            '/accounts': (context) => const AccountsScreen(),
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
    html.document.title = 'app_title'.tr();
    return child;
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Replace this with your navigation or main screen
    return Scaffold(
      appBar: AppBar(title: Text('app_title'.tr())),
      body: Center(child: Text('welcome'.tr())),
    );
  }
}
