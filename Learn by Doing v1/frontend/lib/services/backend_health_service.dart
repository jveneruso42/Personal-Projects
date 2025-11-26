import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Service to check backend health status
class BackendHealthService {
  static const String _backendUrl = 'http://localhost:8003';
  static const Duration _timeout = Duration(seconds: 5);

  /// Check if the backend API is running and healthy
  static Future<bool> isBackendHealthy() async {
    try {
      final response = await http
          .get(Uri.parse('$_backendUrl/health'))
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['status'] == 'healthy';
      }

      return false;
    } catch (e) {
      debugPrint('❌ Backend health check failed: $e');
      return false;
    }
  }

  /// Display error dialog if backend is not healthy
  static Future<void> showBackendUnavailableDialog(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (BuildContext context) => AlertDialog(
            title: const Text(
              'Backend Service Unavailable',
              style: TextStyle(color: Colors.red),
            ),
            content: const Text(
              'The application backend is not running. Please ensure the Flutter backend service is started before continuing.\n\n'
              'To start the backend, run:\n'
              'python -m uvicorn app.main:app --host 0.0.0.0 --port 8002 --reload',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Redirect back to login
                  if (context.mounted) {
                    GoRouter.of(context).go('/login');
                  }
                },
                child: const Text('Go Back'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  // Retry the health check
                  final isHealthy = await isBackendHealthy();
                  if (context.mounted) {
                    if (isHealthy) {
                      // Backend is now healthy, navigate forward
                      debugPrint('✅ Backend is now healthy');
                    } else {
                      // Still not healthy, show dialog again
                      if (context.mounted) {
                        await showBackendUnavailableDialog(context);
                      }
                    }
                  }
                },
                child: const Text('Retry'),
              ),
            ],
          ),
    );
  }
}
