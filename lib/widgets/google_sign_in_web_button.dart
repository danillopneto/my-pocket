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
          } // More robust button rendering with retries
          void renderButton([int attempt = 0]) {
            final clientId = html.document
                .querySelector('meta[name="google-signin-client_id"]')
                ?.getAttribute('content');

            if (clientId == null) {
              print('Error: Google Sign-In client ID not found in meta tag');
              return;
            }

            // Check if Google APIs are available
            bool isGoogleLoaded = js.context.hasProperty('google') &&
                js.context['google'].hasProperty('accounts') &&
                js.context['google']['accounts'].hasProperty('id');

            if (!isGoogleLoaded) {
              // Retry with exponential backoff (max 5 attempts)
              if (attempt < 5) {
                int delay = 300 * (attempt + 1); // 300ms, 600ms, 900ms, etc.
                print(
                    'Google API not loaded yet, retrying in ${delay}ms (attempt ${attempt + 1})');
                Future.delayed(Duration(milliseconds: delay),
                    () => renderButton(attempt + 1));
              } else {
                print(
                    'Failed to load Google Sign-In script after multiple attempts');
                // Add a fallback button if the Google button fails to load
                addFallbackButton(elem);
              }
              return;
            }

            try {
              // Initialize Google Identity Services
              final options = js.JsObject.jsify({
                'client_id': clientId,
                'callback': (response) {
                  html.window.dispatchEvent(
                      html.CustomEvent('gsi-callback', detail: response));
                },
                'auto_select': false, // Don't auto-select first account
                'cancel_on_tap_outside': true, // Cancel if user clicks outside
              });

              js.context['google']['accounts']['id']
                  .callMethod('initialize', [options]);

              // Check if the button container exists
              final buttonContainer = html.document.getElementById(buttonId);
              if (buttonContainer == null) {
                print('Button container not found');
                return;
              }

              // Clear any previous content
              buttonContainer.children.clear();

              final buttonOptions = js.JsObject.jsify({
                'theme': 'filled_blue',
                'size': 'large',
                'type': 'standard',
                'text': 'signin_with',
                'width': 240,
              });

              // Render the button
              js.context['google']['accounts']['id']
                  .callMethod('renderButton', [buttonContainer, buttonOptions]);

              print('Google Sign-In button rendered successfully');
            } catch (e) {
              print('Error rendering Google Sign-In button: $e');

              // Try the fallback approach with eval
              try {
                js.context.callMethod('eval', [
                  '''
                  if (google && google.accounts && google.accounts.id) {
                    google.accounts.id.initialize({
                      client_id: "$clientId", 
                      callback: function(response) { 
                        window.dispatchEvent(new CustomEvent('gsi-callback', {detail: response}));
                      },
                      auto_select: false,
                      cancel_on_tap_outside: true
                    });
                    
                    google.accounts.id.renderButton(
                      document.getElementById('$buttonId'), 
                      {theme: 'filled_blue', size: 'large', type: 'standard', text: 'signin_with', width: 240}
                    );
                  }
                  '''
                ]);
                print('Button rendered using eval fallback');
              } catch (evalError) {
                print('Eval fallback also failed: $evalError');
                addFallbackButton(elem);
              }
            }
          }

          // Add a simple HTML button as fallback
          void addFallbackButton(html.Element container) {
            print('Adding fallback button for Google Sign-In');
            final button = html.ButtonElement()
              ..innerText = 'Sign in with Google'
              ..style.width = '240px'
              ..style.height = '40px'
              ..style.backgroundColor = '#4285F4'
              ..style.color = 'white'
              ..style.border = 'none'
              ..style.borderRadius = '4px'
              ..style.padding = '10px'
              ..style.fontFamily = 'Roboto, sans-serif'
              ..style.cursor = 'pointer'
              ..onClick.listen((event) {
                print('Fallback button clicked');
                if (onSignIn != null) onSignIn!();
              });

            container.children.clear();
            container.append(button);
          }

          // Remove any previous listener for this buttonId
          if (_listenerMap[buttonId] != null) {
            html.window
                .removeEventListener('gsi-callback', _listenerMap[buttonId]);
          } // Guard to ensure onSignIn is only called once per buttonId
          _signInTriggeredMap[buttonId] = false;
          html.EventListener? listener;
          listener = (event) {
            if (_signInTriggeredMap[buttonId] == false) {
              _signInTriggeredMap[buttonId] = true;
              // Delay the callback to ensure we're not completing a future too early
              Future.microtask(() {
                if (onSignIn != null) onSignIn!();
              });
              // Remove the listener after it's been triggered
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
