import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/password_reset_models.dart';
import '../widgets/branded_app_bar.dart';

/// Reset Password Screen
///
/// Allows users to reset their password using a token received via email.
/// Implements security best practices:
/// - Password strength meter with real-time validation
/// - Confirm password field to prevent typos
/// - Token validation and expiration handling
/// - Clear feedback on password requirements
/// - Prevents weak password submission
class ResetPasswordScreen extends StatefulWidget {
  final String? token;

  const ResetPasswordScreen({super.key, this.token});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;
  late TextEditingController _tokenController;
  bool _isLoading = false;
  bool _showSuccess = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _errorMessage;
  PasswordValidation _passwordValidation = PasswordValidation(
    isValid: false,
    errors: [],
    strengthLevel: 'weak',
    strengthScore: 0.0,
  );

  @override
  void initState() {
    super.initState();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _tokenController = TextEditingController();

    // Try to get token from URL parameters
    _extractTokenFromUrl();

    // Add listeners for real-time validation
    _passwordController.addListener(_validatePassword);
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  /// Extract token from URL query parameters
  void _extractTokenFromUrl() {
    // If token passed as parameter, use it
    if (widget.token != null && widget.token!.isNotEmpty) {
      _tokenController.text = widget.token!;
      return;
    }

    // Try to extract from URL query string using WASM-compatible Uri.base
    try {
      final uri = Uri.base;
      final tokenParam = uri.queryParameters['token'];
      if (tokenParam != null && tokenParam.isNotEmpty) {
        _tokenController.text = tokenParam;
      }
    } catch (e) {
      debugPrint('⚠️ Could not extract token from URL: $e');
    }
  }

  /// Get token from parameter or controller
  String get token => widget.token ?? _tokenController.text;

  /// Validate password in real-time
  void _validatePassword() {
    setState(() {
      _passwordValidation = PasswordValidation.validate(
        _passwordController.text,
      );
    });
  }

  /// Check if passwords match
  bool _passwordsMatch() {
    if (_passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      return false;
    }
    return _passwordController.text == _confirmPasswordController.text;
  }

  /// Submit new password
  Future<void> _resetPassword() async {
    // Clear previous errors
    setState(() => _errorMessage = null);

    // Validate token
    if (token.isEmpty) {
      setState(() => _errorMessage = 'Password reset token is missing');
      return;
    }

    // Validate password
    if (!_passwordValidation.isValid) {
      setState(() => _errorMessage = _passwordValidation.errors.first);
      return;
    }

    // Check password confirmation
    if (!_passwordsMatch()) {
      setState(() => _errorMessage = 'Passwords do not match');
      return;
    }

    // Confirm password strength
    if (_passwordValidation.strengthLevel == 'weak') {
      setState(
        () =>
            _errorMessage =
                'Password is too weak. Please use a stronger password',
      );
      return;
    }

    // Start loading
    setState(() => _isLoading = true);

    try {
      final apiService = ApiService();
      await apiService.resetPassword(
        token: token,
        newPassword: _passwordController.text,
      );

      if (!mounted) return;

      // Show success
      setState(() {
        _showSuccess = true;
        _isLoading = false;
        _errorMessage = null;
      });

      debugPrint('✅ Password reset successful');
    } on ApiException catch (e) {
      if (!mounted) return;

      // Handle specific error cases
      String errorMsg = 'Failed to reset password. Please try again';

      if (e.statusCode == 400) {
        errorMsg =
            'Invalid password or token. Please request a new password reset link';
      } else if (e.statusCode == 401 || e.statusCode == 403) {
        errorMsg = 'Password reset link has expired. Please request a new one';
      } else if (e.statusCode == 422) {
        errorMsg =
            'Password does not meet requirements. Please try a stronger password';
      }

      setState(() {
        _errorMessage = errorMsg;
        _isLoading = false;
      });

      debugPrint('❌ Password reset error: ${e.statusCode} - ${e.message}');
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'An unexpected error occurred. Please try again';
        _isLoading = false;
      });

      debugPrint('❌ Unexpected error: $e');
    }
  }

  /// Build token input field (only if not pre-populated from URL)
  Widget _buildTokenField() {
    if (token.isNotEmpty) {
      return const SizedBox.shrink(); // Hide if token already provided
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reset Token',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.95),
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _tokenController,
          enabled: !_isLoading && !_showSuccess,
          keyboardType: TextInputType.text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            hintText: 'Paste token from email',
            hintStyle: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: Icon(
              Icons.vpn_key_outlined,
              color: Colors.white.withValues(alpha: 0.6),
              size: 18,
            ),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.08),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.white, width: 1.5),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  /// Build password input field
  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'New Password',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.95),
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _passwordController,
          enabled: !_isLoading && !_showSuccess,
          obscureText: _obscurePassword,
          keyboardType: TextInputType.visiblePassword,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            hintText: 'Enter new password',
            hintStyle: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: Icon(
              Icons.lock_outline,
              color: Colors.white.withValues(alpha: 0.6),
              size: 18,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: Colors.white.withValues(alpha: 0.6),
                size: 18,
              ),
              onPressed: () {
                setState(() => _obscurePassword = !_obscurePassword);
              },
            ),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.08),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.white, width: 1.5),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Build password strength indicator
  Widget _buildPasswordStrengthIndicator() {
    final strengthColors = {
      'weak': Colors.red.shade400,
      'fair': Colors.orange.shade400,
      'good': Colors.amber.shade400,
      'strong': Colors.green.shade400,
    };

    final strengthColor =
        strengthColors[_passwordValidation.strengthLevel] ?? Colors.grey;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Strength',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              _passwordValidation.strengthLevel.toUpperCase(),
              style: TextStyle(
                color: strengthColor,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: _passwordValidation.strengthScore,
            minHeight: 4,
            backgroundColor: Colors.white.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(strengthColor),
          ),
        ),
        if (_passwordValidation.errors.isNotEmpty) ...[
          SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children:
                _passwordValidation.errors
                    .map(
                      (error) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.close_rounded,
                              color: Colors.red.shade400,
                              size: 14,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                error,
                                style: TextStyle(
                                  color: Colors.red.shade200,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
          ),
        ],
        SizedBox(height: 16),
      ],
    );
  }

  /// Build confirm password field
  Widget _buildConfirmPasswordField() {
    final isMatch = _passwordsMatch();
    final borderColor =
        _confirmPasswordController.text.isEmpty
            ? Colors.white.withValues(alpha: 0.2)
            : isMatch
            ? Colors.green.shade400
            : Colors.red.shade400;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Confirm Password',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.95),
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _confirmPasswordController,
          enabled: !_isLoading && !_showSuccess,
          obscureText: _obscureConfirm,
          keyboardType: TextInputType.visiblePassword,
          onChanged: (_) => setState(() {}), // Trigger UI update
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            hintText: 'Re-enter password',
            hintStyle: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: Icon(
              Icons.lock_outline,
              color: Colors.white.withValues(alpha: 0.6),
              size: 18,
            ),
            suffixIcon: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_confirmPasswordController.text.isNotEmpty)
                    Icon(
                      isMatch
                          ? Icons.check_circle_outlined
                          : Icons.cancel_outlined,
                      color:
                          isMatch ? Colors.green.shade400 : Colors.red.shade400,
                      size: 18,
                    ),
                  IconButton(
                    icon: Icon(
                      _obscureConfirm
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: Colors.white.withValues(alpha: 0.6),
                      size: 18,
                    ),
                    onPressed: () {
                      setState(() => _obscureConfirm = !_obscureConfirm);
                    },
                  ),
                ],
              ),
            ),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.08),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: borderColor, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: borderColor, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: borderColor, width: 1.5),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
          ),
        ),
        if (_confirmPasswordController.text.isNotEmpty && !isMatch) ...[
          SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Passwords do not match',
              style: TextStyle(
                color: Colors.red.shade300,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
        SizedBox(height: 16),
      ],
    );
  }

  /// Build error message
  Widget _buildErrorMessage() {
    if (_errorMessage == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade400, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade600, size: 16),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(
                color: Colors.red.shade100,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build success message
  Widget _buildSuccessMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade400, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.check_circle_outline,
                color: Colors.green.shade400,
                size: 18,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Password Reset Successful!',
                  style: TextStyle(
                    color: Colors.green.shade100,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Your password has been successfully reset. You can now log in with your new password.',
            style: TextStyle(
              color: Colors.green.shade50,
              fontSize: 12,
              fontWeight: FontWeight.w400,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  /// Build reset button
  Widget _buildResetButton() {
    final isEnabled =
        _passwordValidation.isValid &&
        _passwordsMatch() &&
        !_isLoading &&
        token.isNotEmpty;

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: isEnabled ? _resetPassword : null,
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
                      const Color(0xFF1B5E20).withValues(alpha: 0.7),
                    ),
                  ),
                )
                : Text(
                  'Reset Password',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1B5E20),
                    letterSpacing: 0.5,
                  ),
                ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: const Color(0xFF1B5E20),
      appBar: const BrandedAppBar(
        title: 'Reset Password',
        showBackButton: true,
        showMenu: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - 80,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Top spacing
                SizedBox(height: isMobile ? 20 : 40),

                // Logo/Title area
                Column(
                  children: [
                    Icon(
                      Icons.lock_open_outlined,
                      color: Colors.white,
                      size: isMobile ? 48 : 56,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Create New Password',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isMobile ? 28 : 32,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Enter a strong password to secure your account',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),

                // Main form area
                SizedBox(height: isMobile ? 40 : 48),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 0 : 20,
                    vertical: 0,
                  ),
                  child: Column(
                    children: [
                      // Token field (if not pre-populated)
                      _buildTokenField(),

                      // Password field
                      _buildPasswordField(),

                      // Password strength indicator
                      _buildPasswordStrengthIndicator(),

                      // Confirm password field
                      _buildConfirmPasswordField(),

                      // Error message
                      if (_errorMessage != null) ...[
                        _buildErrorMessage(),
                        const SizedBox(height: 16),
                      ],

                      // Success message
                      if (_showSuccess) ...[
                        _buildSuccessMessage(),
                        const SizedBox(height: 20),
                      ],

                      // Button
                      if (!_showSuccess)
                        _buildResetButton()
                      else
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              elevation: 0,
                              shadowColor: Colors.transparent,
                            ),
                            child: const Text(
                              'Back to Login',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1B5E20),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Bottom spacing
                SizedBox(height: isMobile ? 20 : 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
