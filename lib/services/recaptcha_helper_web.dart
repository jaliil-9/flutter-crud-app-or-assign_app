// Web-only reCAPTCHA helper. Uses `dart:html` to create a container for Firebase reCAPTCHA verifier.
import 'dart:html' as html;

class RecaptchaHelper {
  /// Ensure a container with [id] exists in the DOM for reCAPTCHA.
  /// Returns the Element created or existing.
  static html.Element ensureRecaptchaContainer(String id) {
    final existing = html.document.getElementById(id);
    if (existing != null) return existing;

    final container = html.DivElement()..id = id;
    // It's common to append to body for Firebase reCAPTCHA.
    html.document.body?.append(container);
    return container;
  }
}
