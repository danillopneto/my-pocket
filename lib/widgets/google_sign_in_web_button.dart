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
  // Static map to track if sign-in was triggered per buttonId
  static final Map<String, bool> _signInTriggeredMap = {};
  // Static map to keep references to listeners for removal
  static final Map<String, html.EventListener?> _listenerMap = {};

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
              ..src = 'https://accounts.google.com/gsi/client'
              ..async = true;
            html.document.body?.append(script);
          }
          void renderButton() {
            final clientId = html.document
                .querySelector('meta[name="google-signin-client_id"]')
                ?.getAttribute('content');
            if (clientId != null && js.context.hasProperty('google')) {
              js.context.callMethod('eval', [
                '''google.accounts.id.initialize({client_id: "$clientId", callback: (response) => window.dispatchEvent(new CustomEvent('gsi-callback', {detail: response}))});'''
              ]);
              js.context.callMethod('eval', [
                '''google.accounts.id.renderButton(document.getElementById('$buttonId'), {theme: 'filled_blue', size: 'large', type: 'standard', text: 'signin_with'});'''
              ]);
            }
          }

          // Remove any previous listener for this buttonId
          if (_listenerMap[buttonId] != null) {
            html.window
                .removeEventListener('gsi-callback', _listenerMap[buttonId]);
          }
          // Guard to ensure onSignIn is only called once per buttonId
          _signInTriggeredMap[buttonId] = false;
          html.EventListener? listener;
          listener = (event) {
            if (_signInTriggeredMap[buttonId] == false) {
              _signInTriggeredMap[buttonId] = true;
              if (onSignIn != null) onSignIn!();
              if (listener != null) {
                html.window.removeEventListener('gsi-callback', listener);
              }
            }
          };
          _listenerMap[buttonId] = listener;
          html.window.addEventListener('gsi-callback', listener);
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
