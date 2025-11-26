/// Authentication service for managing user state, tokens, and authorization
///
/// This module provides Provider-based state management for authentication.
/// Uses Provider's StateNotifier pattern for reactive, scalable state management.
///
/// Handles:
/// - JWT token storage and validation
/// - User role and permission management
/// - Route guards and access control
/// - Auth state persistence
/// - Reactive UI updates via Provider
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../models/auth_models.dart';

/// Exception for authentication errors
class AuthException implements Exception {
  final String message;
  final dynamic originalError;

  AuthException(this.message, {this.originalError});

  @override
  String toString() => 'AuthException: $message';
}

/// Immutable auth state object
class AuthState {
  final String? accessToken;
  final User? currentUser;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.accessToken,
    this.currentUser,
    this.isLoading = false,
    this.error,
  });

  /// Check if user is authenticated
  bool get isAuthenticated => accessToken != null && currentUser != null;

  /// Check if user is in pending state
  bool get isPending => currentUser?.isPending ?? false;

  /// Check if user has full access (not pending)
  bool get hasFullAccess => !isPending && isAuthenticated;

  /// Check if user is admin
  bool get isAdmin => currentUser?.isAdmin ?? false;

  /// Check if user is teacher
  bool get isTeacher => currentUser?.isTeacher ?? false;

  /// Check if user is paraeducator
  bool get isParaeducator => currentUser?.isParaeducator ?? false;

  /// Get current user role
  String get userRole => currentUser?.role ?? 'guest';

  /// Get user's display name
  String get displayName => currentUser?.displayName ?? 'User';

  /// Get user's email
  String? get userEmail => currentUser?.email;

  /// Copy with method for immutable updates
  AuthState copyWith({
    String? accessToken,
    User? currentUser,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      accessToken: accessToken ?? this.accessToken,
      currentUser: currentUser ?? this.currentUser,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  /// Clear error
  AuthState withoutError() => AuthState(
    accessToken: accessToken,
    currentUser: currentUser,
    isLoading: isLoading,
  );
}

/// Service for managing authentication, user state, and authorization
class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    return const AuthState();
  }

  /// Set authenticated state from login response
  void setAuthenticatedUser(LoginResponse response) {
    state = AuthState(
      accessToken: response.accessToken,
      currentUser: response.user,
      isLoading: false,
    );
  }

  /// Clear authentication state
  void clearAuth() {
    state = const AuthState();
  }

  /// Set loading state
  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  /// Set error message
  void setError(String? error) {
    state = state.copyWith(error: error);
  }

  /// Clear error message
  void clearError() {
    state = state.withoutError();
  }

  /// Update user information (called after profile changes)
  void updateUserInfo(User updatedUser) {
    state = state.copyWith(currentUser: updatedUser);
  }

  /// Reset to initial state
  void reset() {
    state = const AuthState();
  }

  // Permission checking methods

  /// Check if user has specific role
  bool hasRole(String role) => state.currentUser?.role == role;

  /// Check if user has any of the specified roles
  bool hasAnyRole(List<String> roles) {
    if (state.currentUser == null) return false;
    return roles.contains(state.currentUser!.role);
  }

  /// Check if user can access a feature based on role
  bool canAccessFeature(String requiredRole) {
    if (state.currentUser == null) return false;

    // Map of feature requirements to allowed roles
    const featureRequirements = {
      'students': ['teacher', 'paraeducator', 'admin'],
      'behaviors': ['teacher', 'paraeducator', 'admin'],
      'admin_dashboard': ['admin'],
      'home': ['pending', 'teacher', 'paraeducator', 'admin'],
      'profile': ['teacher', 'paraeducator', 'admin'],
    };

    final allowedRoles = featureRequirements[requiredRole] ?? [];
    return allowedRoles.contains(state.currentUser!.role);
  }

  /// Get list of accessible features for current user
  List<String> getAccessibleFeatures() {
    if (state.currentUser == null) return [];

    final role = state.currentUser!.role;

    switch (role) {
      case 'pending':
        return ['home']; // Pending users only see home
      case 'paraeducator':
        return ['home', 'students', 'behaviors', 'profile'];
      case 'teacher':
        return ['home', 'students', 'behaviors', 'profile'];
      case 'admin':
        return ['home', 'students', 'behaviors', 'profile', 'admin_dashboard'];
      default:
        return [];
    }
  }

  /// Check if user can view student information
  bool canViewStudents() {
    if (state.currentUser == null) return false;
    if (state.currentUser!.isPending) return false;
    return [
      'teacher',
      'paraeducator',
      'admin',
    ].contains(state.currentUser!.role);
  }

  /// Check if user can create students
  bool canCreateStudents() {
    if (state.currentUser == null) return false;
    return ['teacher', 'admin'].contains(state.currentUser!.role);
  }

  /// Check if user can edit student
  bool canEditStudent() {
    if (state.currentUser == null) return false;
    return ['teacher', 'admin'].contains(state.currentUser!.role);
  }

  /// Check if user can delete student
  bool canDeleteStudent() {
    if (state.currentUser == null) return false;
    return ['admin'].contains(state.currentUser!.role);
  }

  /// Check if user can view behaviors
  bool canViewBehaviors() {
    if (state.currentUser == null) return false;
    if (state.currentUser!.isPending) return false;
    return [
      'teacher',
      'paraeducator',
      'admin',
    ].contains(state.currentUser!.role);
  }

  /// Check if user can record behavior
  bool canRecordBehavior() {
    if (state.currentUser == null) return false;
    return [
      'teacher',
      'paraeducator',
      'admin',
    ].contains(state.currentUser!.role);
  }

  /// Check if user can approve pending users (admin only)
  bool canApprovePendingUsers() {
    if (state.currentUser == null) return false;
    return state.currentUser!.isAdmin;
  }

  /// Check if user is still awaiting approval
  bool isAwaitingApproval() {
    if (state.currentUser == null) return false;
    return state.currentUser!.isPending && !state.currentUser!.isApproved;
  }

  /// Get user's permission level (0-3)
  int getPermissionLevel() {
    switch (state.currentUser?.role) {
      case 'pending':
        return 0;
      case 'paraeducator':
        return 1;
      case 'teacher':
        return 2;
      case 'admin':
        return 3;
      default:
        return 0;
    }
  }

  /// Check if current user can manage another user's role
  bool canManageUserRole(String targetRole) {
    if (state.currentUser == null) return false;

    const roleHierarchy = {
      'pending': 0,
      'paraeducator': 1,
      'teacher': 2,
      'admin': 3,
    };

    final currentLevel = roleHierarchy[state.currentUser!.role] ?? 0;
    final targetLevel = roleHierarchy[targetRole] ?? 0;

    return currentLevel > targetLevel;
  }

  /// Store token for persistence (implement with secure storage)
  Future<void> persistToken() async {
    // TODO: Implement secure token storage with flutter_secure_storage
    debugPrint(
      'Token would be persisted: ${state.accessToken?.substring(0, 20)}...',
    );
  }

  /// Load persisted token (implement with secure storage)
  Future<bool> loadPersistedToken() async {
    // TODO: Implement secure token retrieval from flutter_secure_storage
    return false;
  }

  /// Clear persisted token
  Future<void> clearPersistedToken() async {
    // TODO: Implement token deletion from secure storage
    clearAuth();
  }

  /// Validate token (check expiration, etc)
  bool isTokenValid() {
    if (state.accessToken == null) return false;

    try {
      // Basic check: token should not be empty and should have reasonable length
      if (state.accessToken!.isEmpty || state.accessToken!.length < 20) {
        return false;
      }

      // TODO: Implement JWT parsing to check expiration
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get authorization header for API requests
  Map<String, String> getAuthHeaders() {
    if (state.accessToken == null) return {};
    return {
      'Authorization': 'Bearer ${state.accessToken}',
      'Content-Type': 'application/json',
    };
  }
}

// ============================================================================
// PROVIDERS - Use these in your widgets
// ============================================================================

/// Main auth provider - manages authentication state
/// Usage: ref.watch(authProvider)
final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});

/// Provider for checking if user is authenticated
/// Usage: ref.watch(isAuthenticatedProvider)
final isAuthenticatedProvider = Provider<bool>((ref) {
  final auth = ref.watch(authProvider);
  return auth.isAuthenticated;
});

/// Provider for checking if user is pending
/// Usage: ref.watch(isPendingProvider)
final isPendingProvider = Provider<bool>((ref) {
  final auth = ref.watch(authProvider);
  return auth.isPending;
});

/// Provider for checking if user has full access (not pending)
/// Usage: ref.watch(hasFullAccessProvider)
final hasFullAccessProvider = Provider<bool>((ref) {
  final auth = ref.watch(authProvider);
  return auth.hasFullAccess;
});

/// Provider for checking if user is admin
/// Usage: ref.watch(isAdminProvider)
final isAdminProvider = Provider<bool>((ref) {
  final auth = ref.watch(authProvider);
  return auth.isAdmin;
});

/// Provider for checking if user is teacher
/// Usage: ref.watch(isTeacherProvider)
final isTeacherProvider = Provider<bool>((ref) {
  final auth = ref.watch(authProvider);
  return auth.isTeacher;
});

/// Provider for checking if user is paraeducator
/// Usage: ref.watch(isParaeducatorProvider)
final isParaeducatorProvider = Provider<bool>((ref) {
  final auth = ref.watch(authProvider);
  return auth.isParaeducator;
});

/// Provider for current user
/// Usage: ref.watch(currentUserProvider)
final currentUserProvider = Provider<User?>((ref) {
  final auth = ref.watch(authProvider);
  return auth.currentUser;
});

/// Provider for current user role
/// Usage: ref.watch(userRoleProvider)
final userRoleProvider = Provider<String>((ref) {
  final auth = ref.watch(authProvider);
  return auth.userRole;
});

/// Provider for user display name
/// Usage: ref.watch(displayNameProvider)
final displayNameProvider = Provider<String>((ref) {
  final auth = ref.watch(authProvider);
  return auth.displayName;
});

/// Provider for user email
/// Usage: ref.watch(userEmailProvider)
final userEmailProvider = Provider<String?>((ref) {
  final auth = ref.watch(authProvider);
  return auth.userEmail;
});

/// Provider for accessible features
/// Usage: ref.watch(accessibleFeaturesProvider)
final accessibleFeaturesProvider = Provider<List<String>>((ref) {
  final authNotifier = ref.read(authProvider.notifier);
  return authNotifier.getAccessibleFeatures();
});

/// Provider for permission level (0-3)
/// Usage: ref.watch(permissionLevelProvider)
final permissionLevelProvider = Provider<int>((ref) {
  final authNotifier = ref.read(authProvider.notifier);
  return authNotifier.getPermissionLevel();
});

/// Provider for checking if can view students
/// Usage: ref.watch(canViewStudentsProvider)
final canViewStudentsProvider = Provider<bool>((ref) {
  final authNotifier = ref.read(authProvider.notifier);
  return authNotifier.canViewStudents();
});

/// Provider for checking if can create students
/// Usage: ref.watch(canCreateStudentsProvider)
final canCreateStudentsProvider = Provider<bool>((ref) {
  final authNotifier = ref.read(authProvider.notifier);
  return authNotifier.canCreateStudents();
});

/// Provider for checking if can record behavior
/// Usage: ref.watch(canRecordBehaviorProvider)
final canRecordBehaviorProvider = Provider<bool>((ref) {
  final authNotifier = ref.read(authProvider.notifier);
  return authNotifier.canRecordBehavior();
});

/// Provider for checking if can approve pending users
/// Usage: ref.watch(canApprovePendingUsersProvider)
final canApprovePendingUsersProvider = Provider<bool>((ref) {
  final authNotifier = ref.read(authProvider.notifier);
  return authNotifier.canApprovePendingUsers();
});
