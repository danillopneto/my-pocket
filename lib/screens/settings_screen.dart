import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';
import '../services/user_preferences_service.dart';
import '../widgets/drawer_widget.dart';
import '../widgets/app_loading_indicator.dart';
import '../utils/firebase_user_utils.dart';
import '../widgets/scaffold_with_drawer.dart';

class SettingsScreen extends StatefulWidget {
  final void Function(ThemeMode)? onThemeChanged;
  final void Function(Locale)? onLocaleChanged;
  final ThemeMode themeMode;
  final Locale? locale;
  const SettingsScreen({
    this.onThemeChanged,
    this.onLocaleChanged,
    this.themeMode = ThemeMode.light,
    this.locale,
    super.key,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _darkMode;
  late String _language;
  late String _currencySymbol;
  late String _currencyFormat;
  final UserPreferencesService _prefsService = UserPreferencesService();
  bool _loadingPrefs = true;

  @override
  void initState() {
    super.initState();
    _darkMode = widget.themeMode == ThemeMode.dark;
    _language = widget.locale?.languageCode ?? 'en';
    _currencySymbol = 'R\$';
    _currencyFormat = '0.000,00';
    _loadPrefs();
  }

  void _loadPrefs() async {
    await withCurrentUserAsync((user) async {
      final prefs = await _prefsService.getPreferences(user.uid);
      setState(() {
        _darkMode = prefs.darkMode;
        _language = prefs.language;
        _currencySymbol = prefs.currencySymbol;
        _currencyFormat = prefs.currencyFormat;
        _loadingPrefs = false;
      });
    });
  }

  void _savePrefs() async {
    await withCurrentUserAsync((user) async {
      final prefs = UserPreferences(
        language: _language,
        currencySymbol: _currencySymbol,
        currencyFormat: _currencyFormat,
        darkMode: _darkMode,
      );
      await _prefsService.setPreferences(user.uid, prefs);
      setState(() {});
    });
  }

  void _onThemeChanged(bool dark) {
    setState(() => _darkMode = dark);
    widget.onThemeChanged?.call(dark ? ThemeMode.dark : ThemeMode.light);
    _savePrefs();
  }

  void _onLanguageChanged(String lang) {
    setState(() => _language = lang);
    widget.onLocaleChanged?.call(Locale(lang));
    if (!mounted) return;
    context.setLocale(Locale(lang)); // Ensure EasyLocalization updates
    _savePrefs();
  }

  void _onCurrencyChanged(String symbol) {
    setState(() => _currencySymbol = symbol);
    _savePrefs();
  }

  void _onCurrencyFormatChanged(String format) {
    setState(() => _currencyFormat = format);
    _savePrefs();
  }

  @override
  Widget build(BuildContext context) {
    final result = withCurrentUser<Widget>((user) {
      return ScaffoldWithDrawer(
        selected: 'settings',
        titleKey: 'settings',
        body: _loadingPrefs
            ? const AppLoadingIndicator()
            : ListView(
                // Removed redundant padding, now handled by ScaffoldWithDrawer
                children: [
                  ListTile(
                    title: Text('user'.tr()),
                    subtitle:
                        Text("${user.displayName ?? user.uid} (${user.email})"),
                    leading: const Icon(Icons.person),
                  ),
                  SwitchListTile(
                    title:
                        Text(_darkMode ? 'dark_mode'.tr() : 'light_mode'.tr()),
                    value: _darkMode,
                    onChanged: _onThemeChanged,
                    secondary: const Icon(Icons.dark_mode),
                  ),
                  ListTile(
                    title: Text('language'.tr()),
                    trailing: DropdownButton<String>(
                      value: _language,
                      items: [
                        DropdownMenuItem(
                            value: 'en', child: Text('English'.tr())),
                        DropdownMenuItem(
                            value: 'es', child: Text('Español'.tr())),
                        DropdownMenuItem(
                            value: 'pt', child: Text('Português'.tr())),
                      ],
                      onChanged: (val) {
                        if (val != null) _onLanguageChanged(val);
                      },
                    ),
                    leading: const Icon(Icons.language),
                  ),
                  ListTile(
                    title: Text('currency_symbol'.tr()),
                    trailing: SizedBox(
                      width: 100,
                      child: TextField(
                        controller:
                            TextEditingController(text: _currencySymbol),
                        onChanged: (val) {
                          _onCurrencyChanged(val);
                        },
                        decoration: InputDecoration(
                          hintText: 'e.g. R\$, \$, €',
                          border: const OutlineInputBorder(),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 8),
                        ),
                      ),
                    ),
                    leading: const Icon(Icons.attach_money),
                  ),
                  ListTile(
                    title: Text('currency_format'.tr()),
                    trailing: SizedBox(
                      width: 120,
                      child: TextField(
                        controller:
                            TextEditingController(text: _currencyFormat),
                        onChanged: (val) {
                          _onCurrencyFormatChanged(val);
                        },
                        decoration: InputDecoration(
                          hintText: 'e.g. 0.000,00',
                          border: const OutlineInputBorder(),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 8),
                        ),
                      ),
                    ),
                    leading: const Icon(Icons.format_list_numbered),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.logout),
                    label: Text('logout'.tr()),
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      if (!context.mounted) return;
                      Navigator.of(context)
                          .pushNamedAndRemoveUntil('/login', (route) => false);
                    },
                  ),
                ],
              ),
      );
    });
    return result ??
        Scaffold(
          appBar: AppBar(
              title: Builder(builder: (context) => Text('settings'.tr()))),
          drawer: AppDrawer(selected: 'settings'),
          body: Center(child: Text('login'.tr())),
        );
  }
}
