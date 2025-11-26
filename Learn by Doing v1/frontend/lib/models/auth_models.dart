/// Authentication and user models for Andromeda app
///
/// Includes user information, login/registration responses, and role management
library;

class UserRole {
  /// User role enum
  static const String pending = 'pending';
  static const String paraeducator = 'paraeducator';
  static const String teacher = 'teacher';
  static const String admin = 'admin';
  static const String superAdmin = 'super_admin';

  static const List<String> all = [
    pending,
    paraeducator,
    teacher,
    admin,
    superAdmin,
  ];

  static bool isPending(String role) => role == pending;
  static bool isParaeducator(String role) => role == paraeducator;
  static bool isTeacher(String role) => role == teacher;
  static bool isAdmin(String role) => role == admin;
  static bool isSuperAdmin(String role) => role == superAdmin;

  /// Check if user has admin privileges (admin or super_admin)
  static bool isAdminUser(String role) => role == admin || role == superAdmin;

  /// Check if user is approved (not pending)
  static bool isApproved(String role) => role != pending;
}

/// User information model
class User {
  final int id;
  final String email;
  final String username;
  final String? firstName;
  final String? lastName;
  final String? desiredName;
  final String? phone;
  final String role;
  final bool isApproved;

  User({
    required this.id,
    required this.email,
    required this.username,
    this.firstName,
    this.lastName,
    this.desiredName,
    this.phone,
    required this.role,
    required this.isApproved,
  });

  /// Create User from JSON (API response)
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      email: json['email'] as String,
      username: json['username'] as String? ?? '',
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      desiredName: json['desired_name'] as String?,
      phone: json['phone'] as String?,
      role: json['role'] as String? ?? UserRole.pending,
      isApproved: json['is_approved'] as bool? ?? false,
    );
  }

  /// Convert User to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'first_name': firstName,
      'last_name': lastName,
      'desired_name': desiredName,
      'phone': phone,
      'role': role,
      'is_approved': isApproved,
    };
  }

  /// Get display name (desired > first + last > email)
  String get displayName {
    if (desiredName != null && desiredName!.isNotEmpty) {
      return desiredName!;
    }
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    }
    if (firstName != null) {
      return firstName!;
    }
    return email;
  }

  /// Check if user is pending approval
  bool get isPending => UserRole.isPending(role);

  /// Check if user is teacher
  bool get isTeacher => UserRole.isTeacher(role);

  /// Check if user is paraeducator
  bool get isParaeducator => UserRole.isParaeducator(role);

  /// Check if user is admin (includes both admin and super_admin)
  bool get isAdmin => UserRole.isAdminUser(role);

  /// Check if user can access full app features
  bool get hasFullAccess => isApproved && !isPending;
}

/// Login request model
class LoginRequest {
  final String email;
  final String password;

  LoginRequest({required this.email, required this.password});

  Map<String, dynamic> toJson() {
    return {'email': email, 'password': password};
  }
}

/// Login response model (OAuth2 compliant)
class LoginResponse {
  final String accessToken;
  final String tokenType;
  final User user;

  LoginResponse({
    required this.accessToken,
    required this.tokenType,
    required this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      accessToken: json['access_token'] as String,
      tokenType: json['token_type'] as String? ?? 'bearer',
      user: User.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'token_type': tokenType,
      'user': user.toJson(),
    };
  }
}

/// Registration request model
class RegisterRequest {
  final String email;
  final String password;
  final String firstName;
  final String lastName;
  final String desiredName;

  RegisterRequest({
    required this.email,
    required this.password,
    required this.firstName,
    required this.lastName,
    required this.desiredName,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'first_name': firstName,
      'last_name': lastName,
      'desired_name': desiredName,
    };
  }
}

/// Registration response model
class RegisterResponse {
  final int id;
  final String email;
  final String firstName;
  final String lastName;
  final String desiredName;
  final String role;
  final bool isApproved;
  final DateTime createdAt;
  final String message;

  RegisterResponse({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.desiredName,
    required this.role,
    required this.isApproved,
    required this.createdAt,
    required this.message,
  });

  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    return RegisterResponse(
      id: json['id'] as int,
      email: json['email'] as String,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      desiredName: json['desired_name'] as String,
      role: json['role'] as String? ?? UserRole.pending,
      isApproved: json['is_approved'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      message: json['message'] as String? ?? 'Registration successful',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'desired_name': desiredName,
      'role': role,
      'is_approved': isApproved,
      'created_at': createdAt.toIso8601String(),
      'message': message,
    };
  }
}

/// JWT token payload (decoded)
class TokenPayload {
  final int userId;
  final String email;
  final String role;
  final List<String> permissions;
  final DateTime expiresAt;

  TokenPayload({
    required this.userId,
    required this.email,
    required this.role,
    required this.permissions,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isValid => !isExpired;
}
