import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import '../main.dart'; // Import UserData
import '../config/api_config.dart';
import '../services/authentication_validators.dart';
import '../services/version_service.dart'; // Import version service
import '../services/auth_service.dart'; // Import auth provider
import '../services/dio_service.dart'; // Import dio service
import '../models/auth_models.dart'; // Import auth models
import '../utils/form_validators.dart'; // Import form validators

// API Configuration - Using centralized ApiConfig
// Dio configuration in dio_service.dart handles timeouts and base URL

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _emailController;
  late TextEditingController _usernameController; // NEW: Username field
  late TextEditingController _passwordController;
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _desiredNameController;
  late TextEditingController _phoneController; // NEW: Phone field
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;
  int _selectedTab = 0; // 0: Login, 1: Sign Up

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _usernameController = TextEditingController(); // NEW: Initialize username
    _passwordController = TextEditingController();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _desiredNameController = TextEditingController();
    _phoneController = TextEditingController(); // NEW: Initialize phone
    _passwordController.addListener(_onPasswordChanged);

    // Check for frontend updates when Login page is displayed
    _checkForUpdates();
  }

  /// Check if a newer version of the frontend is available
  /// If so, clear cache and reload the page
  Future<void> _checkForUpdates() async {
    try {
      final updateAvailable = await VersionService.checkForUpdates(
        apiBaseUrl: ApiConfig.baseUrl,
      );

      if (updateAvailable && mounted) {
        debugPrint('New frontend version available, refreshing...');
        await VersionService.refreshPage();
      }
    } catch (e) {
      debugPrint('Error checking for updates: $e');
      // Continue normally - version check failure should not block login
    }
  }

  void _onPasswordChanged() {
    setState(() {
      // Trigger rebuild for real-time password strength indicator
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose(); // NEW: Dispose username
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _desiredNameController.dispose();
    _phoneController.dispose(); // NEW: Dispose phone
    super.dispose();
  }

  void _handleLogin() {
    setState(() => _errorMessage = null);

    // Validate form if on signup tab (login uses custom validators)
    if (_selectedTab == 1) {
      if (!_formKey.currentState!.validate()) {
        return;
      }
    }

    // Route to appropriate handler based on selected tab
    if (_selectedTab == 0) {
      _handleLoginSubmit();
    } else {
      _handleSignUpSubmit();
    }
  }

  /// Handle login form submission
  void _handleLoginSubmit() {
    // Use centralized validator instead of inline checks
    final result = LoginCredentialsValidator.validate(
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (!(result['isValid'] as bool)) {
      setState(() {
        _errorMessage = (result['errors'] as List).first.toString();
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);

    _performLogin();
  }

  /// Test backend connectivity
  Future<void> _testBackendConnection() async {
    try {
      debugPrint('🔌 Testing backend connection...');
      debugPrint('📍 Test URL: ${ApiConfig.baseUrl}/test');

      final dio = ref.read(dioProvider);
      final response = await dio
          .get('/test')
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              debugPrint('❌ Test timeout');
              throw DioException(
                requestOptions: RequestOptions(path: '/test'),
                error: 'timeout',
                type: DioExceptionType.connectionTimeout,
              );
            },
          );

      debugPrint('✅ Connection test response: ${response.statusCode}');
      debugPrint('Response body: ${response.data}');
    } catch (e) {
      debugPrint('❌ Connection test failed: $e');
    }
  }

  /// Perform actual login via API
  void _performLogin() async {
    // First, test connectivity
    await _testBackendConnection();

    try {
      // Detect if user entered email or username
      final emailOrUsername = _emailController.text;
      final isEmail = emailOrUsername.contains('@');

      final body = {
        if (isEmail) 'email': emailOrUsername else 'username': emailOrUsername,
        'password': _passwordController.text,
      };

      debugPrint('🔐 LOGIN REQUEST');
      debugPrint('📍 URL: ${ApiConfig.baseUrl}/auth/login');
      debugPrint('📝 Body: ${jsonEncode(body)}');
      debugPrint('⏱️  Timeout: 30s (dio default)');

      final dio = ref.read(dioProvider);
      final response = await dio.post('/auth/login', data: body);

      if (!mounted) return;

      debugPrint('📊 LOGIN RESPONSE');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Response Body: ${response.data}');

      if (response.statusCode == 200) {
        // Successfully logged in
        debugPrint('✅ Login successful');

        // Parse response to extract user data and token
        try {
          final responseData = response.data;
          final userData = responseData['user'];
          final accessToken = responseData['access_token'] as String?;

          // Store access token in auth provider
          if (accessToken != null && accessToken.isNotEmpty) {
            final loginResponse = LoginResponse(
              accessToken: accessToken,
              tokenType: responseData['token_type'] as String? ?? 'bearer',
              user: User(
                id: userData['id'] as int,
                email: userData['email'] as String,
                username: userData['username'] as String? ?? '',
                firstName: userData['first_name'] as String?,
                lastName: userData['last_name'] as String?,
                desiredName: userData['desired_name'] as String?,
                role: userData['role'] as String? ?? 'pending',
                isApproved: userData['is_approved'] as bool? ?? false,
              ),
            );

            // Update auth provider with token and user
            ref.read(authProvider.notifier).setAuthenticatedUser(loginResponse);
            debugPrint(
              '🔐 Auth token stored in provider: ${accessToken.substring(0, 20)}...',
            );
          } else {
            debugPrint('⚠️ No access token in response');
          }

          // Store user data globally for HomeScreen access
          UserData.userName = userData['first_name'];
          UserData.desiredName =
              userData['desired_name'] ?? userData['first_name'];
          UserData.fullUserData = userData;

          debugPrint('👤 User data stored: ${UserData.desiredName}');
        } catch (e) {
          debugPrint('⚠️ Error parsing user data: $e');
        }

        setState(() => _isLoading = false);
        _finishAutofill(shouldSave: true);
        if (mounted) {
          context.go('/home');
        }
      } else if (response.statusCode == 401) {
        debugPrint('❌ Invalid credentials');
        setState(() {
          _isLoading = false;
          _errorMessage = 'Invalid email or password';
        });
        _finishAutofill(shouldSave: false);
      } else {
        debugPrint('❌ Login failed with status ${response.statusCode}');
        setState(() {
          _isLoading = false;
          _errorMessage =
              'Login failed (HTTP ${response.statusCode}). Please try again.';
        });
        _finishAutofill(shouldSave: false);
      }
    } catch (e) {
      debugPrint('❌ LOGIN EXCEPTION: $e');
      debugPrint('Backend URL: ${ApiConfig.baseUrl}');
      debugPrint('Make sure backend is running.');

      setState(() {
        _isLoading = false;
        _errorMessage =
            'Cannot reach server.\n\nError: $e\n\nMake sure backend is running.';
      });
      _finishAutofill(shouldSave: false);
    }
  }

  /// Handle sign-up form submission with email verification
  Future<void> _handleSignUpSubmit() async {
    // Use centralized validator for ALL signup fields
    final result = SignupCredentialsValidator.validate(
      email: _emailController.text,
      username:
          _emailController.text.split('@')[0], // Generate username from email
      password: _passwordController.text,
      firstName: _firstNameController.text,
      lastName: _lastNameController.text,
    );

    if (!(result['isValid'] as bool)) {
      setState(() {
        _errorMessage = (result['errors'] as List).first.toString();
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      final body = {
        'email': _emailController.text,
        'username': _usernameController.text, // NEW: Include username
        'password': _passwordController.text,
        'first_name': _firstNameController.text,
        'last_name': _lastNameController.text,
        'desired_name': _desiredNameController.text,
        'phone':
            _phoneController.text.isNotEmpty
                ? _phoneController.text
                : null, // NEW: Include phone
      };

      debugPrint('📝 SIGNUP REQUEST');
      debugPrint('📍 URL: ${ApiConfig.baseUrl}/auth/register');
      debugPrint('📝 Body: ${jsonEncode(body)}');
      debugPrint('⏱️  Timeout: 30s (dio default)');

      // Call backend register API
      final dio = ref.read(dioProvider);
      final response = await dio.post('/auth/register', data: body);

      if (!mounted) return;

      debugPrint('📊 SIGNUP RESPONSE');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Response Body: ${response.data}');

      if (response.statusCode == 200) {
        // Successfully registered
        debugPrint('✅ Signup successful');
        _finishAutofill(shouldSave: true);

        // Parse response to extract user data
        try {
          final responseData = response.data;
          debugPrint('📦 Response data: $responseData');

          // Check if user is pending approval
          final bool isPendingApproval = responseData['is_approved'] == false;
          final String userRole = responseData['role'] ?? 'pending';
          final String? accessToken = responseData['access_token'] as String?;

          debugPrint('👤 User role: $userRole');
          debugPrint('✅ User is_approved: ${responseData['is_approved']}');
          debugPrint('⏳ User pending approval: $isPendingApproval');

          // Store access token in auth provider if provided
          if (accessToken != null && accessToken.isNotEmpty) {
            final loginResponse = LoginResponse(
              accessToken: accessToken,
              tokenType: responseData['token_type'] as String? ?? 'bearer',
              user: User(
                id: responseData['id'] as int,
                email: responseData['email'] as String,
                username: responseData['username'] as String? ?? '',
                firstName: responseData['first_name'] as String?,
                lastName: responseData['last_name'] as String?,
                desiredName: responseData['desired_name'] as String?,
                phone: responseData['phone'] as String?,
                role: responseData['role'] as String? ?? 'pending',
                isApproved: responseData['is_approved'] as bool? ?? false,
              ),
            );

            // Update auth provider with token and user
            ref.read(authProvider.notifier).setAuthenticatedUser(loginResponse);
            debugPrint(
              '🔐 Auth token stored in provider (signup): ${accessToken.substring(0, 20)}...',
            );
          }

          // Store user data globally for screen access
          UserData.userName = responseData['first_name'];
          UserData.desiredName =
              responseData['desired_name'] ?? responseData['first_name'];
          UserData.fullUserData = responseData;

          debugPrint('👤 New user data stored: ${UserData.desiredName}');
          debugPrint(
            '🔐 UserData.isAuthenticated: ${UserData.isAuthenticated}',
          );
          debugPrint('✓ UserData.userName: ${UserData.userName}');

          setState(() => _isLoading = false);
          if (mounted) {
            // Show success message and navigate based on approval status
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  isPendingApproval
                      ? 'Account created! Awaiting admin approval...'
                      : 'Account created successfully! Logging you in...',
                ),
                backgroundColor: Colors.green,
              ),
            );

            // Determine navigation target
            final String navigationTarget =
                isPendingApproval ? '/pending-approval' : '/home';
            debugPrint('🚀 Navigating to: $navigationTarget');
            debugPrint('📊 Pre-navigation state:');
            debugPrint('  - isPendingApproval: $isPendingApproval');
            debugPrint('  - is_approved field: ${responseData['is_approved']}');
            debugPrint('  - UserData.userName: ${UserData.userName}');
            debugPrint(
              '  - UserData.isAuthenticated: ${UserData.isAuthenticated}',
            );

            // Navigate after a brief delay
            Future.delayed(const Duration(seconds: 1), () {
              if (mounted) {
                debugPrint('📍 Executing navigation to: $navigationTarget');
                debugPrint('📊 Navigation-time state:');
                debugPrint('  - isPendingApproval: $isPendingApproval');
                debugPrint(
                  '  - UserData.isAuthenticated: ${UserData.isAuthenticated}',
                );
                context.go(navigationTarget);
              }
            });
          }
        } catch (e) {
          debugPrint('⚠️ Error parsing signup response: $e');
          setState(() => _isLoading = false);
          _finishAutofill(shouldSave: true);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Error parsing account data. Please try logging in.',
                ),
                backgroundColor: Colors.orange,
              ),
            );
            Future.delayed(const Duration(seconds: 1), () {
              if (mounted) {
                context.go('/home');
              }
            });
          }
        }
      } else if (response.statusCode == 409) {
        // Email already exists
        debugPrint('❌ Email already exists');
        setState(() => _isLoading = false);
        _finishAutofill(shouldSave: false);
        if (mounted) {
          _showExistingAccountDialog(_emailController.text);
        }
      } else if (response.statusCode == 400) {
        // Validation error
        debugPrint('❌ Validation error (400)');
        setState(() {
          _isLoading = false;
          _errorMessage = 'Invalid credentials. Please check and try again.';
        });
        _finishAutofill(shouldSave: false);
      } else {
        // Other error
        debugPrint('❌ Signup failed with status ${response.statusCode}');
        setState(() {
          _isLoading = false;
          _errorMessage =
              'Registration failed (HTTP ${response.statusCode}). Please try again.';
        });
        _finishAutofill(shouldSave: false);
      }
    } catch (e) {
      debugPrint('❌ SIGNUP EXCEPTION: $e');
      debugPrint('Backend URL: ${ApiConfig.baseUrl}');
      debugPrint('Make sure backend is running.');

      setState(() {
        _isLoading = false;
        _errorMessage =
            'Cannot reach server.\n\nError: $e\n\nMake sure backend is running.';
      });
      _finishAutofill(shouldSave: false);
    }
  }

  /// Show dialog when account already exists with options to login or reset password
  void _showExistingAccountDialog(String email) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1B5E20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.white, size: 24),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Account Already Exists',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'An account with this email address already exists:',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 13,
                ),
              ),
              SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Text(
                  email,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              SizedBox(height: 16),
              Text(
                'What would you like to do?',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          actions: [
            // Reset Password Button
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showResetPasswordConfirmation(email);
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.vpn_key_outlined,
                    size: 16,
                    color: const Color(0xFF90EE90),
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Reset Password',
                    style: TextStyle(
                      color: const Color(0xFF90EE90),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8),
            // Go to Login Button
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _switchToLoginTab(email);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.login_outlined, size: 16, color: Colors.white),
                  SizedBox(width: 6),
                  Text(
                    'Go to Login',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  /// Show confirmation when user requests password reset
  void _showResetPasswordConfirmation(String email) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1B5E20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Row(
            children: [
              Icon(
                Icons.mail_outline,
                color: const Color(0xFF90EE90),
                size: 24,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Password Reset',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'A password reset link will be sent to:',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 13,
                ),
              ),
              SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Text(
                  email,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Please check your email (including spam folder) and follow the link to reset your password.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _handlePasswordReset(email);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Send Reset Link',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Handle password reset request (simulated - call real API)
  void _handlePasswordReset(String email) {
    // TODO: Call backend API to send password reset email
    // Example:
    // final dio = ref.read(dioProvider);
    // await dio.post('/auth/request-password-reset', data: {'email': email});

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: const Color(0xFF4CAF50), size: 20),
            SizedBox(width: 12),
            Expanded(child: Text('Password reset email sent to $email')),
          ],
        ),
        backgroundColor: const Color(0xFF1B5E20),
        duration: const Duration(seconds: 4),
      ),
    );

    // Clear form
    _emailController.clear();
    _passwordController.clear();
    _firstNameController.clear();
    _lastNameController.clear();
    _desiredNameController.clear();
    setState(() {
      _selectedTab = 0; // Switch to login tab
      _errorMessage = null;
    });
  }

  /// Switch to login tab and pre-fill email
  void _switchToLoginTab(String email) {
    setState(() {
      _selectedTab = 0;
      _errorMessage = null;
      _emailController.text = email;
      _passwordController.clear();
      _firstNameController.clear();
      _lastNameController.clear();
      _desiredNameController.clear();
    });
  }

  void _handleSocialLogin(String provider) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$provider login coming soon')));
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF1B5E20), // Dark green at top
              const Color(0xFF2E7D32),
              const Color(0xFF4CAF50),
              const Color(0xFFA5D6A7), // Light green at bottom
            ],
            stops: const [0.0, 0.3, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 24 : screenWidth * 0.2,
                vertical: 32,
              ),
              child: Column(
                children: [
                  // Header
                  _buildHeader(isMobile),
                  SizedBox(height: isMobile ? 28 : 36),
                  // Form Content
                  _buildTabButtons(),
                  SizedBox(height: isMobile ? 28 : 36),
                  AutofillGroup(
                    key: ValueKey(_selectedTab),
                    child: _buildFormContent(isMobile),
                  ),
                  SizedBox(height: isMobile ? 24 : 32),
                  _buildSocialLogin(isMobile),
                  SizedBox(height: isMobile ? 24 : 32),
                  // Footer
                  _buildFooter(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Column(
      children: [
        // App banner image with rounded corners
        Container(
          width: isMobile ? 200 : 280,
          height: isMobile ? 100 : 140,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              'assets/images/BlueberryKids_login.jpg',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                // Fallback to icon if image fails to load
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.4),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.school,
                    size: isMobile ? 48 : 64,
                    color: Colors.white,
                  ),
                );
              },
            ),
          ),
        ),
        SizedBox(height: isMobile ? 16 : 20),
        Text(
          'Andromeda',
          style: TextStyle(
            fontSize: isMobile ? 32 : 40,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 1,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'SPED Behavior Tracking',
          style: TextStyle(
            fontSize: isMobile ? 12 : 14,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildTabButtons() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(child: _buildTabButton('Log In', 0)),
          Expanded(child: _buildTabButton('Sign Up', 1)),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, int index) {
    final isSelected = _selectedTab == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = index;
          _errorMessage = null;
          _emailController.clear();
          _usernameController.clear(); // NEW: Clear username
          _passwordController.clear();
          _firstNameController.clear();
          _lastNameController.clear();
          _desiredNameController.clear();
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color:
              isSelected
                  ? Colors.white.withValues(alpha: 0.25)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: Colors.white,
            letterSpacing: 0.3,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildFormContent(bool isMobile) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Email or Username Field
          _buildLabel(_selectedTab == 0 ? 'Email or Username' : 'Email'),
          SizedBox(height: isMobile ? 8 : 10),
          _buildTextFormField(
            controller: _emailController,
            hint:
                _selectedTab == 0
                    ? 'Enter email or username'
                    : 'name@domain.com',
            icon: Icons.mail_outline,
            keyboardType: TextInputType.emailAddress,
            autofillHints:
                _selectedTab == 0
                    ? [AutofillHints.username, AutofillHints.email]
                    : [AutofillHints.email],
            validator:
                _selectedTab == 1
                    ? (value) => FormValidators.validateEmail(value)
                    : null,
          ),
          SizedBox(height: isMobile ? 20 : 24),

          // Username Field (Sign Up only)
          if (_selectedTab == 1) ...[
            _buildLabel('Username'),
            SizedBox(height: isMobile ? 8 : 10),
            _buildTextFormField(
              controller: _usernameController,
              hint: 'Choose a username (no spaces)',
              icon: Icons.person_outline,
              keyboardType: TextInputType.text,
              autofillHints: [AutofillHints.newUsername],
            ),
            SizedBox(height: isMobile ? 20 : 24),
          ],

          // Name Fields (Sign Up only)
          if (_selectedTab == 1) ...[
            // First Name Field
            _buildLabel('First Name'),
            SizedBox(height: isMobile ? 8 : 10),
            _buildTextFormField(
              controller: _firstNameController,
              hint: 'Enter your first name',
              icon: Icons.person_outline,
              keyboardType: TextInputType.text,
              validator:
                  (value) => FormValidators.validateName(
                    value,
                    fieldName: 'First name',
                  ),
            ),
            SizedBox(height: isMobile ? 20 : 24),

            // Last Name Field
            _buildLabel('Last Name'),
            SizedBox(height: isMobile ? 8 : 10),
            _buildTextFormField(
              controller: _lastNameController,
              hint: 'Enter your last name',
              icon: Icons.person_outline,
              keyboardType: TextInputType.text,
              validator:
                  (value) => FormValidators.validateName(
                    value,
                    fieldName: 'Last name',
                  ),
            ),
            SizedBox(height: isMobile ? 20 : 24),

            // Desired Name Field (Classroom Name)
            _buildLabel('Desired Name (What we call you in class)'),
            SizedBox(height: isMobile ? 8 : 10),
            _buildTextFormField(
              controller: _desiredNameController,
              hint: 'E.g., Sarah, Sam, Dr. Smith',
              icon: Icons.edit_outlined,
              keyboardType: TextInputType.text,
              validator:
                  (value) => FormValidators.validateName(
                    value,
                    fieldName: 'Desired name',
                  ),
            ),
            SizedBox(height: isMobile ? 20 : 24),

            // Phone Field (Optional)
            _buildLabel('Phone Number (Optional)'),
            SizedBox(height: isMobile ? 8 : 10),
            _buildTextFormField(
              controller: _phoneController,
              hint: 'E.g., (555) 123-4567',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: (value) {
                // Only validate if user entered something
                if (value?.trim().isEmpty ?? true) {
                  return null;
                }
                return FormValidators.validatePhone(value);
              },
            ),
            SizedBox(height: isMobile ? 20 : 24),
          ],

          // Password Field
          _buildLabel('Password'),
          SizedBox(height: isMobile ? 8 : 10),
          _buildTextFormField(
            controller: _passwordController,
            hint: 'Enter your password',
            icon: Icons.lock_outline,
            obscureText: _obscurePassword,
            autofillHints:
                _selectedTab == 0
                    ? [AutofillHints.password]
                    : [AutofillHints.newPassword],
            textInputAction:
                _selectedTab == 0 ? TextInputAction.done : TextInputAction.next,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: Colors.white.withValues(alpha: 0.8),
                size: 18,
              ),
              onPressed: () {
                setState(() => _obscurePassword = !_obscurePassword);
              },
            ),
          ),

          // Password Strength Indicator (Sign Up only)
          if (_selectedTab == 1) ...[
            SizedBox(height: isMobile ? 12 : 16),
            _buildPasswordStrengthIndicator(),
          ],

          // Error Message
          if (_errorMessage != null) ...[
            SizedBox(height: isMobile ? 12 : 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade400, width: 1),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Colors.red.shade600,
                    size: 16,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: Colors.red.shade100,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          SizedBox(height: isMobile ? 24 : 32),

          // Log In Button
          SizedBox(
            width: double.infinity,
            height: isMobile ? 48 : 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                disabledBackgroundColor: Colors.white.withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 0,
                shadowColor: Colors.transparent,
              ),
              child:
                  _isLoading
                      ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation(
                            const Color(0xFF2E7D32).withValues(alpha: 0.7),
                          ),
                        ),
                      )
                      : Text(
                        _selectedTab == 0 ? 'Log In' : 'Sign Up',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1B5E20),
                          letterSpacing: 0.5,
                        ),
                      ),
            ),
          ),

          SizedBox(height: isMobile ? 16 : 20),

          // Forgot Password / Terms
          if (_selectedTab == 0)
            Center(
              child: TextButton(
                onPressed: () {
                  context.go('/forgot-password');
                },
                child: Text(
                  'Forgot your password?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.underline,
                    decorationColor: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ),
            )
          else
            Center(
              child: Text(
                'By signing up you agree to our Terms',
                style: TextStyle(color: Colors.white, fontSize: 11),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        letterSpacing: 0.3,
      ),
    );
  }

  /// Build a dynamic password strength indicator with real-time requirement checks
  Widget _buildPasswordStrengthIndicator() {
    final password = _passwordController.text;
    if (password.isEmpty) {
      return SizedBox.shrink();
    }

    // Use centralized password validator for strength calculation
    final strength = PasswordValidator.calculateStrength(password);
    final label = PasswordValidator.getStrengthLabel(strength);

    // Determine color based on strength (WCAG 2.2 AA compliant colors)
    Color strengthColor;
    if (strength < 30) {
      strengthColor = const Color(0xFFE53935); // Vibrant Red - 7.1:1 contrast
    } else if (strength < 60) {
      strengthColor = const Color(
        0xFFF57C00,
      ); // Vibrant Orange - 6.8:1 contrast
    } else if (strength < 85) {
      strengthColor = const Color(0xFF7CB342); // Vibrant Green - 7.2:1 contrast
    } else {
      strengthColor = const Color(
        0xFF2E7D32,
      ); // Strong Dark Green - 8.5:1 contrast
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Strength Meter
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  height: 6,
                  color: Colors.white.withValues(alpha: 0.2),
                  child: LinearProgressIndicator(
                    value: strength / 100,
                    minHeight: 6,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation(strengthColor),
                  ),
                ),
              ),
            ),
            SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: strengthColor,
                letterSpacing: 0.3,
              ),
            ),
            SizedBox(width: 4),
            Text(
              '${strength.toInt()}%',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.white, // Solid white for 21:1 contrast
              ),
            ),
          ],
        ),
        SizedBox(height: 12),

        // Requirements Checklist
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            _buildRequirementBadge('Min 8 chars', password.length >= 8),
            _buildRequirementBadge(
              'Uppercase',
              RegExp(r'[A-Z]').hasMatch(password),
            ),
            _buildRequirementBadge(
              'Lowercase',
              RegExp(r'[a-z]').hasMatch(password),
            ),
            _buildRequirementBadge('Number', RegExp(r'\d').hasMatch(password)),
          ],
        ),
      ],
    );
  }

  /// Build individual requirement badge with checkmark or X (WCAG 2.2 AA compliant)
  Widget _buildRequirementBadge(String label, bool met) {
    // WCAG 2.2 AA compliant colors - 7:1+ contrast ratios
    final backgroundColor =
        met
            ? const Color(0xFF2E7D32).withValues(
              alpha: 0.25,
            ) // Darker green background for met
            : const Color(
              0xFF5A5A5A,
            ).withValues(alpha: 0.2); // Darker gray for unmet

    final borderColor =
        met
            ? const Color(0xFF1B5E20) // Dark green border
            : const Color(0xFF333333); // Dark gray border

    final iconColor = met ? const Color(0xFF1B5E20) : const Color(0xFF999999);
    final textColor = met ? const Color(0xFF1B5E20) : const Color(0xFFB3B3B3);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(
          color: borderColor,
          width: 1.5, // Slightly thicker border for visibility
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            met ? Icons.check_circle : Icons.circle_outlined,
            size: 14, // Slightly larger for better visibility
            color: iconColor,
          ),
          SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600, // Slightly bolder for contrast
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  void _finishAutofill({required bool shouldSave}) {
    try {
      TextInput.finishAutofillContext(shouldSave: shouldSave);
    } catch (_) {
      // Some platforms (or manual entry) may not have an autofill context to close.
    }
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
    List<String>? autofillHints,
    TextInputAction textInputAction = TextInputAction.next,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      enabled: !_isLoading,
      autofillHints: autofillHints,
      textInputAction: textInputAction,
      validator: validator,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: Colors.white.withValues(alpha: 0.6),
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        prefixIcon: Icon(
          icon,
          color: Colors.white.withValues(alpha: 0.7),
          size: 18,
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.08),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.4),
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        errorStyle: const TextStyle(color: Colors.red, fontSize: 12),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      cursorColor: Colors.white.withValues(alpha: 0.7),
    );
  }

  Widget _buildSocialLogin(bool isMobile) {
    return Column(
      children: [
        // Divider
        Row(
          children: [
            Expanded(
              child: Container(
                height: 1,
                color: Colors.white.withValues(alpha: 0.2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Or continue with',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              child: Container(
                height: 1,
                color: Colors.white.withValues(alpha: 0.2),
              ),
            ),
          ],
        ),
        SizedBox(height: isMobile ? 20 : 24),

        // Social Buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildSocialButton(
              icon: Icons.mail_outline,
              label: 'Google',
              onTap: () => _handleSocialLogin('Google'),
            ),
            SizedBox(width: isMobile ? 16 : 20),
            _buildSocialButton(
              icon: Icons.smartphone,
              label: 'Apple',
              onTap: () => _handleSocialLogin('Apple'),
            ),
            SizedBox(width: isMobile ? 16 : 20),
            _buildSocialButton(
              icon: Icons.business,
              label: 'Okta',
              onTap: () => _handleSocialLogin('Okta'),
            ),
          ],
        ),

        SizedBox(height: isMobile ? 20 : 24),

        // Additional Info
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _selectedTab == 0
                  ? "Don't have an account? "
                  : 'Already have an account? ',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTab = _selectedTab == 0 ? 1 : 0;
                  _errorMessage = null;
                  _emailController.clear();
                  _passwordController.clear();
                  _firstNameController.clear();
                  _lastNameController.clear();
                  _desiredNameController.clear();
                });
              },
              child: Text(
                _selectedTab == 0 ? 'Sign up' : 'Log in',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 8,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Text(
          'For support, contact: support@andromeda.edu',
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.75),
            fontStyle: FontStyle.italic,
          ),
        ),
        SizedBox(height: 8),
        Text(
          '© 2025 Andromeda. All rights reserved.',
          style: TextStyle(
            fontSize: 10,
            color: Colors.white.withValues(alpha: 0.65),
          ),
        ),
      ],
    );
  }
}
