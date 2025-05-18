// ignore: avoid_web_libraries_in_flutter
import 'dart:ui_web' as ui;
import 'dart:html' as html;
import 'dart:js' as js;
import 'package:flutter/widgets.dart';

/// A widget that renders the official Google Sign-In button using HTML/JS interop for Flutter web.
class GoogleSignInWebButton extends StatelessWidget {
  final void Function()? onSignIn;
  final String buttonId;
  static bool _viewFactoryRegistered = false;

  const GoogleSignInWebButton(
      {super.key, required this.onSignIn, this.buttonId = 'gsi_button'});

  @override
  Widget build(BuildContext context) {
    // Register the view factory only once
    if (!_viewFactoryRegistered) {
      // ignore: undefined_prefixed_name
      ui.platformViewRegistry.registerViewFactory(
        buttonId,
        (int viewId) {
          final html.Element elem = html.DivElement()
            ..id = buttonId
            ..style.width = '240px'
            ..style.height = '50px';
          // Only add the script if it doesn't already exist
          if (html.document.getElementById('gsi-client') == null) {
            final script = html.ScriptElement()
              ..id = 'gsi-client'
              ..src = 'https://paymentMethods.google.com/gsi/client'
              ..async = true;
            html.document.body?.append(script);
          }
          void renderButton() {
            final clientId = html.document
                .querySelector('meta[name="google-signin-client_id"]')
                ?.getAttribute('content');
            if (clientId != null && js.context.hasProperty('google')) {
              js.context.callMethod('eval', [
                '''google.paymentMethods.id.initialize({client_id: "$clientId", callback: (response) => window.dispatchEvent(new CustomEvent('gsi-callback', {detail: response}))});'''
              ]);
              js.context.callMethod('eval', [
                '''google.paymentMethods.id.renderButton(document.getElementById('$buttonId'), {theme: 'filled_blue', size: 'large', type: 'standard', text: 'signin_with'});'''
              ]);
            }
          }

          // Always listen for the callback (no static guard)
          html.window.addEventListener('gsi-callback', (event) {
            if (onSignIn != null) onSignIn!();
          });
          // Try to render the button after a short delay to ensure the script is loaded
          Future.delayed(const Duration(milliseconds: 300), renderButton);
          return elem;
        },
      );
      _viewFactoryRegistered = true;
    }
    return HtmlElementView(viewType: buttonId);
  }
}
