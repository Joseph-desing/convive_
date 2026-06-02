// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// En Flutter Web: redirige el navegador al deep link del APK.
/// En Android Chrome, si el APK está instalado y tiene el intent-filter
/// registrado para el scheme (com.example.convive_://login), Android lo abre.
void redirectToDeepLink(String url) {
  html.window.location.href = url;
}
