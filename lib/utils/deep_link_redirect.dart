/// Stub para plataformas no-web (Android, iOS).
/// En móvil no se necesita redirigir via window.location porque la navegación
/// interna de Flutter maneja todo con GoRouter.
void redirectToDeepLink(String url) {
  // No-op en móvil. La navegación se hace con context.go('/login').
}
