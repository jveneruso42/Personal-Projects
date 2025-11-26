import 'dart:async';
import 'package:flutter/foundation.dart';
import '../config/app_version.dart';

// Conditional import for web-specific localStorage and reload
import 'version_service_stub.dart'
    if (dart.library.html) 'version_service_web.dart'
    as platform;

/// Frontend version management and update checking service
///
/// This service handles:
/// - Reading the current frontend version from AppVersion config
/// - Storing last known version in localStorage
/// - Checking for newer versions by comparing stored vs current version
/// - Triggering a cache clear and page refresh when updates are available
/// - Preventing duplicate update checks within a time window
class VersionService {
  static const Duration _checkCooldown = Duration(minutes: 5);
  static const String _storageKey = 'last_known_version';

  static String? _cachedVersion;
  static DateTime? _lastVersionCheck;

  /// Get the current frontend version from AppVersion config
  static Future<String> getCurrentVersion() async {
    if (_cachedVersion != null) {
      return _cachedVersion!;
    }

    try {
      // Get version from our AppVersion config
      _cachedVersion = AppVersion.fullVersion;
    } catch (e) {
      debugPrint('Error reading current version: $e');
      _cachedVersion = '1.0.0';
    }

    return _cachedVersion!;
  }

  /// Check if a new version is available
  ///
  /// This compares the current AppVersion with the last known version stored
  /// in localStorage. Returns true if the version has changed.
  /// This method is throttled to prevent excessive checks.
  static Future<bool> checkForUpdates({
    required String apiBaseUrl,
    bool forceCheck = false,
  }) async {
    // Skip check if already checked recently (unless forced)
    if (!forceCheck &&
        _lastVersionCheck != null &&
        DateTime.now().difference(_lastVersionCheck!) < _checkCooldown) {
      return false;
    }

    _lastVersionCheck = DateTime.now();

    try {
      final currentVersion = await getCurrentVersion();
      final storedVersion = _getStoredVersion();

      // If no stored version (first run), store current and don't update
      if (storedVersion == null) {
        _storeVersion(currentVersion);
        debugPrint('First run - stored version: $currentVersion');
        return false;
      }

      // If version changed, we need to update
      if (storedVersion != currentVersion) {
        debugPrint('Version change detected: $storedVersion -> $currentVersion');
        _storeVersion(currentVersion);
        return true; // Update available
      }

      return false; // Same version, no update needed
    } catch (e) {
      debugPrint('Error checking for updates: $e');
      return false;
    }
  }

  /// Get stored version from localStorage
  static String? _getStoredVersion() {
    try {
      if (kIsWeb) {
        return platform.getFromLocalStorage(_storageKey);
      }
      return null;
    } catch (e) {
      debugPrint('Error reading stored version: $e');
      return null;
    }
  }

  /// Store version to localStorage
  static void _storeVersion(String version) {
    try {
      if (kIsWeb) {
        platform.saveToLocalStorage(_storageKey, version);
        debugPrint('Stored version: $version');
      }
    } catch (e) {
      debugPrint('Error storing version: $e');
    }
  }

  /// Trigger a cache refresh and reload
  /// This clears the browser cache and reloads the page
  static Future<void> refreshPage() async {
    try {
      if (kIsWeb) {
        debugPrint('Refreshing page to load new version...');
        // Clear service worker cache first
        await platform.webClearServiceWorkerCache();
        // Then reload the page
        platform.webRefreshPage();
      } else {
        debugPrint('Page refresh not available on this platform');
      }
    } catch (e) {
      debugPrint('Error refreshing page: $e');
    }
  }
}
