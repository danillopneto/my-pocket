// Login screen
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:easy_localization/easy_localization.dart';
import '../services/auth_service.dart';
import '../widgets/google_sign_in_web_button.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      // On web, render the official Google button using HTML/JS interop
      return Scaffold(
        appBar: AppBar(title: Text('login'.tr())),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 240,
                height: 50,
                child: GoogleSignInWebButton(
                  onSignIn: () async {
                    final user =
                        await AuthService().signInWithGoogle(context: context);
                    if (user != null && context.mounted) {
                      Navigator.pushReplacementNamed(context, '/dashboard');
                    } else if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${'login'.tr()} failed')),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      // Mobile/desktop: use the old button
      return Scaffold(
        appBar: AppBar(title: Text('login'.tr())),
        body: Center(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.login),
            label: Text('${'login'.tr()} Google'),
            onPressed: () async {
              final user = await AuthService().signInWithGoogle();
              if (user != null && context.mounted) {
                Navigator.pushReplacementNamed(context, '/dashboard');
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${'login'.tr()} failed')),
                );
              }
            },
          ),
        ),
      );
    }
  }
}
