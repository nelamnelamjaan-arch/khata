import 'dart:html' as html;

/// Always boot through splash so Firebase + auth init before protected routes.
void resetWebHashToSplash() {
  html.window.location.hash = '#/splash';
}
