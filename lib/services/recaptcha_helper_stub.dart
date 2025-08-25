/// Stub Recaptcha helper for non-web platforms.
/// No-op implementation so imports remain safe on mobile/desktop.
class RecaptchaHelper {
  static void ensureRecaptchaContainer(String id) {
    // No-op on non-web platforms
  }
}
