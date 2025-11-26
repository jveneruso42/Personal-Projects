/// Conditional import for web configuration
/// This file provides a platform-agnostic interface:
/// - web_config_web.dart for web platforms
/// - web_config_stub.dart for non-web platforms (tests, VM)
library;

export 'web_config_stub.dart'
    if (dart.library.js_interop) 'web_config_web.dart';
