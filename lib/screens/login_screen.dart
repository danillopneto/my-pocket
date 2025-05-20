// Login screen
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _signingIn = false;
  bool _isSignUp = false;

  // Controllers for email/password form
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // No need to check button visibility anymore
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  // Handle email/password sign-in
  Future<void> _handleEmailSignIn() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _signingIn = true);
      try {
        final user = await AuthService().signInWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
        );
        if (user != null && context.mounted) {
          Navigator.pushReplacementNamed(context, '/dashboard');
        } else if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('login_failed'.tr())),
          );
        }
      } finally {
        if (mounted) setState(() => _signingIn = false);
      }
    }
  }

  // Handle email/password sign-up
  Future<void> _handleEmailSignUp() async {
    if (_formKey.currentState!.validate()) {
      // Check if passwords match
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('passwords_dont_match'.tr())),
        );
        return;
      }

      setState(() => _signingIn = true);
      try {
        final user = await AuthService().signUpWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
        );
        if (user != null && context.mounted) {
          Navigator.pushReplacementNamed(context, '/dashboard');
        } else if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('signup_failed'.tr())),
          );
        }
      } finally {
        if (mounted) setState(() => _signingIn = false);
      }
    }
  }

  // Handle password reset
  Future<void> _handlePasswordReset() async {
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${'email'.tr()} ${'required'.tr()}')),
      );
      return;
    }

    setState(() => _signingIn = true);
    try {
      final success = await AuthService()
          .sendPasswordResetEmail(_emailController.text.trim());
      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('password_reset_sent'.tr())),
        );
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('password_reset_failed'.tr())),
        );
      }
    } finally {
      if (mounted) setState(() => _signingIn = false);
    }
  }

  // Build the email/password form
  Widget _buildEmailPasswordForm() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Add logo before sign-in fields
          Padding(
            padding: const EdgeInsets.only(bottom: 32.0),
            child: Image.asset(
              'assets/images/logo.png',
              height: 80,
            ),
          ),
          if (_isSignUp) ...[
            TextFormField(
              controller: _firstNameController,
              decoration: InputDecoration(
                labelText: 'first_name'.tr(),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '${'first_name'.tr()} ${'required'.tr()}';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _lastNameController,
              decoration: InputDecoration(
                labelText: 'last_name'.tr(),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '${'last_name'.tr()} ${'required'.tr()}';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
          ],
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: 'email'.tr(),
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '${'email'.tr()} ${'required'.tr()}';
              }
              // Fix: Use correct regex for email validation
              if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) {
                return 'invalid_email_format'.tr();
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: 'password'.tr(),
              border: OutlineInputBorder(),
            ),
            obscureText: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '${'password'.tr()} ${'required'.tr()}';
              }
              if (_isSignUp && value.length < 6) {
                return 'password_min_length'.tr();
              }
              return null;
            },
          ),
          if (_isSignUp) ...[
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmPasswordController,
              decoration: InputDecoration(
                labelText: 'confirm_password'.tr(),
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '${'confirm_password'.tr()} ${'required'.tr()}';
                }
                if (value != _passwordController.text) {
                  return 'passwords_dont_match'.tr();
                }
                return null;
              },
            ),
          ],
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _signingIn
                ? null
                : (_isSignUp ? _handleEmailSignUp : _handleEmailSignIn),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
            ),
            child: _signingIn
                ? const CircularProgressIndicator()
                : Text(_isSignUp ? 'create_account'.tr() : 'login'.tr()),
          ),
          const SizedBox(height: 16),
          if (!_isSignUp)
            TextButton(
              onPressed: _handlePasswordReset,
              child: Text('forgot_password'.tr()),
            ),
          TextButton(
            onPressed: () {
              setState(() => _isSignUp = !_isSignUp);
            },
            child: Text(_isSignUp ? 'login'.tr() : 'sign_up'.tr()),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Always show email/password login form directly
    return Scaffold(
      appBar: AppBar(title: Text('login'.tr())),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: _buildEmailPasswordForm(),
          ),
        ),
      ),
    );
  }
}
