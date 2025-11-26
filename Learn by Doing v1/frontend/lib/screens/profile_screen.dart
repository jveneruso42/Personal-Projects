/// Profile Screen Widget
///
/// Allows users to view and edit their profile information including:
/// - First Name
/// - Last Name
/// - Preferred/Desired Name
/// - Email
/// - Phone Number
/// - Password (obfuscated, with change option)
///
/// Features:
/// - Editable form fields
/// - Save/Cancel functionality
/// - Backend persistence
/// - Input validation
library;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:go_router/go_router.dart';
import '../main.dart'; // For UserData
import '../config/api_config.dart'; // For API base URL
import '../widgets/compact_bottom_nav.dart'; // For bottom navigation
import '../widgets/image_cropper_widget.dart'; // For circular image cropping
import '../services/web_file_picker.dart'; // For web file picking
import '../services/dio_service.dart'; // For dio HTTP client
import '../services/auth_service.dart'; // For auth provider

class ProfileScreen extends ConsumerStatefulWidget {
  final String? userName;
  final String? desiredName;

  const ProfileScreen({super.key, this.userName, this.desiredName});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  // Form controllers
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _desiredNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _passwordController;

  // Timezone selection
  String? _selectedTimezone;

  // UI State
  final bool _showPassword = false;
  bool _isSaving = false;
  bool _hasChanges = false;
  String? _errorMessage;
  Uint8List? _profileImage; // User profile image
  bool _isProfileImageHovered = false;
  bool _isProfileImagePressed = false;

  // Track initial values for change detection
  late String _initialFirstName;
  late String _initialLastName;
  late String _initialDesiredName;
  late String _initialEmail;
  late String _initialPhone;
  late Uint8List? _initialProfileImage;
  late String? _initialTimezone;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _storeInitialValues();
    _setupChangeListeners();
  }

  void _initializeControllers() {
    // Get data from UserData singleton or from parameters
    final userData = UserData.fullUserData ?? {};

    _firstNameController = TextEditingController(
      text: userData['first_name'] as String? ?? '',
    );
    _lastNameController = TextEditingController(
      text: userData['last_name'] as String? ?? '',
    );
    _desiredNameController = TextEditingController(
      text: UserData.desiredName ?? userData['desired_name'] as String? ?? '',
    );
    _emailController = TextEditingController(
      text: userData['email'] as String? ?? '',
    );
    _phoneController = TextEditingController(
      text: userData['phone'] as String? ?? '',
    );
    _passwordController = TextEditingController(text: '••••••••');

    // Load profile image from UserData if available
    if (userData['profile_image'] != null) {
      try {
        final profileImageStr = userData['profile_image'] as String;
        _profileImage = base64Decode(profileImageStr);
        debugPrint('✅ Profile image loaded: ${_profileImage!.length} bytes');
      } catch (e) {
        debugPrint('❌ Error decoding profile image: $e');
      }
    }

    // Initialize timezone from UserData
    _selectedTimezone = userData['timezone'] as String?;
  }

  /// Store initial values for change detection
  void _storeInitialValues() {
    _initialFirstName = _firstNameController.text;
    _initialLastName = _lastNameController.text;
    _initialDesiredName = _desiredNameController.text;
    _initialEmail = _emailController.text;
    _initialPhone = _phoneController.text;
    _initialProfileImage = _profileImage;
    _initialTimezone = _selectedTimezone;
  }

  /// Setup listeners on text controllers to detect changes
  void _setupChangeListeners() {
    _firstNameController.addListener(_checkForChanges);
    _lastNameController.addListener(_checkForChanges);
    _desiredNameController.addListener(_checkForChanges);
    _emailController.addListener(_checkForChanges);
    _phoneController.addListener(_checkForChanges);
  }

  /// Check if any form field has changed from initial value
  void _checkForChanges() {
    final hasChanges =
        _firstNameController.text != _initialFirstName ||
        _lastNameController.text != _initialLastName ||
        _desiredNameController.text != _initialDesiredName ||
        _emailController.text != _initialEmail ||
        _phoneController.text != _initialPhone ||
        _profileImage != _initialProfileImage ||
        _selectedTimezone != _initialTimezone;

    if (hasChanges != _hasChanges) {
      setState(() => _hasChanges = hasChanges);
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _desiredNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Pick and crop user profile image
  void _pickImage() async {
    if (!kIsWeb) {
      debugPrint('⚠️ Image picking not available on this platform');
      return;
    }

    try {
      final bytes = await pickImageBytesWeb();
      if (bytes == null) return;

      if (mounted) {
        // Show image cropper dialog
        final croppedImage = await showDialog<Uint8List?>(
          context: context,
          builder:
              (context) => ImageCropperWidget(
                imageBytes: bytes,
                imageName: 'user_profile.jpg',
              ),
        );

        if (croppedImage != null && mounted) {
          setState(() {
            _profileImage = croppedImage;
          });
          _checkForChanges();
        }
      }
    } catch (e) {
      debugPrint('⚠️ Error picking image: $e');
      setState(() {
        _errorMessage = 'Failed to upload image. Please try again.';
      });
    }
  }

  Future<void> _saveProfile() async {
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      // Validate inputs
      if (_firstNameController.text.isEmpty) {
        throw Exception('First name is required');
      }
      if (_lastNameController.text.isEmpty) {
        throw Exception('Last name is required');
      }
      if (_emailController.text.isEmpty) {
        throw Exception('Email is required');
      }
      if (!_isValidEmail(_emailController.text)) {
        throw Exception('Please enter a valid email address');
      }
      if (_phoneController.text.isNotEmpty &&
          !_isValidPhone(_phoneController.text)) {
        throw Exception('Please enter a valid phone number');
      }

      // Get user ID from fullUserData
      final userId = UserData.fullUserData?['id'];
      if (userId == null) {
        throw Exception('User ID not found. Please login again.');
      }

      // Get access token (we'll need to get this from auth state or UserData)
      // For now, we'll make a basic request. In a real app, use AuthProvider
      final String? token = UserData.fullUserData?['access_token'];

      // Encode profile image to base64 if present
      String? encodedProfileImage;
      if (_profileImage != null) {
        try {
          encodedProfileImage = base64Encode(_profileImage!);
          debugPrint(
            '✅ Profile image encoded: ${encodedProfileImage.length} characters',
          );
        } catch (e) {
          debugPrint('❌ Error encoding profile image: $e');
          throw Exception('Failed to encode profile image');
        }
      }

      // Call API to update profile
      final String apiUrl = '${ApiConfig.baseUrl}/users/$userId';

      final requestBody = {
        'first_name': _firstNameController.text,
        'last_name': _lastNameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'timezone': _selectedTimezone,
        // Note: desired_name and password are not typically updated via this endpoint
        // Password should be updated through a separate /change-password endpoint
      };

      // Add profile image to request if it exists
      if (encodedProfileImage != null) {
        requestBody['profile_image'] = encodedProfileImage;
      }

      final dio = ref.read(dioProvider);
      final response = await dio.put('/users/$userId', data: requestBody);

      debugPrint('📡 Profile Update Response:');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Response Body: ${response.data}');

      if (response.statusCode == 200) {
        // Successfully updated profile

        // Update local UserData with response
        UserData.fullUserData ??= {};
        UserData.fullUserData!['first_name'] = _firstNameController.text;
        UserData.fullUserData!['last_name'] = _lastNameController.text;
        UserData.fullUserData!['email'] = _emailController.text;
        UserData.fullUserData!['phone'] = _phoneController.text;
        UserData.fullUserData!['timezone'] = _selectedTimezone;
        UserData.desiredName = _desiredNameController.text;

        // Update profile image in UserData if it was changed
        if (encodedProfileImage != null) {
          UserData.fullUserData!['profile_image'] = encodedProfileImage;
        }

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );

          // Reset initial values and clear hasChanges flag
          _storeInitialValues();
          setState(() => _hasChanges = false);
        }
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized. Please login again.');
      } else if (response.statusCode == 409) {
        throw Exception(
          'Email already in use. Please choose a different email.',
        );
      } else if (response.statusCode == 422) {
        // Validation error
        try {
          final errorData = response.data;
          final details = errorData['error']?['details'] as List?;
          if (details != null && details.isNotEmpty) {
            final firstError = details[0];
            throw Exception(firstError['message'] ?? 'Validation error');
          }
        } catch (e) {
          // If we can't parse error details, use generic message
          throw Exception('Validation error. Please check your input.');
        }
      } else {
        throw Exception(
          'Failed to update profile (HTTP ${response.statusCode})',
        );
      }
    } catch (e) {
      debugPrint('❌ Error saving profile: $e');
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(email);
  }

  bool _isValidPhone(String phone) {
    // Simple validation - at least 10 digits
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    return digits.length >= 10;
  }

  void _openPasswordChangeScreen() {
    context.go('/profile/change-password');
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(
          isMobile ? 84 : 104,
        ), // Exact height: AppBar + padding
        child: Stack(
          children: [
            // Background banner image covering full appBar area
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: const AssetImage('assets/images/BlueberryKids.jpg'),
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    colorFilter: ColorFilter.mode(
                      Colors.black.withValues(alpha: 0.5),
                      BlendMode.darken,
                    ),
                  ),
                ),
              ),
            ),
            // AppBar layered on top
            Column(
              children: [
                // Compact AppBar - NY Times style
                AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  toolbarHeight:
                      isMobile ? 44 : kToolbarHeight, // Compact on mobile
                  leading: null, // Menu moved to bottom nav
                  title: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'My Profile',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isMobile ? 16 : 20,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        UserData.fullUserData?['role']?.toString().replaceFirst(
                              UserData.fullUserData!['role'].toString()[0],
                              UserData.fullUserData!['role']
                                  .toString()[0]
                                  .toUpperCase(),
                            ) ??
                            'User',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: isMobile ? 12 : 14,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                  centerTitle: true,
                  actions: [
                    // Update button - only show when changes detected
                    if (_isSaving)
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                      )
                    else if (_hasChanges)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8.0,
                          vertical: 8.0,
                        ),
                        child: FilledButton.icon(
                          key: const Key('profile_update_button'),
                          onPressed: _saveProfile,
                          icon: const Icon(Icons.check, size: 20),
                          label: const Text('Update'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.green[700],
                            foregroundColor: Colors.white,
                            elevation: 2,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 13,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: const CompactBottomNav(currentRoute: '/profile'),
      body: Container(
        // Explicitly fill the available space between appBar and bottomNav
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              const Color(0xFF3D7A40), // Darker green at left edge
              const Color(0xFF2E7D32), // Darker green in center
              const Color(0xFF1B5E20), // Darkest green in center
              const Color(0xFF2E7D32), // Darker green in center
              const Color(0xFF3D7A40), // Darker green at right edge
            ],
            stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
          ),
        ),
        child: _buildProfileContent(isMobile),
      ),
    );
  }

  /// Build the main profile content
  Widget _buildProfileContent(bool isMobile) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: isMobile ? double.infinity : 600,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Header - Row with timezone picker and profile image
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Timezone picker (1/4 width)
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Time Zone',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButton<String>(
                            value: _selectedTimezone,
                            isExpanded: true,
                            underline: const SizedBox(),
                            dropdownColor: const Color(0xFF1B5E20),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                            icon: Icon(
                              Icons.arrow_drop_down,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                            hint: Text(
                              'Select',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 14,
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'America/New_York',
                                child: Text('Eastern'),
                              ),
                              DropdownMenuItem(
                                value: 'America/Chicago',
                                child: Text('Central'),
                              ),
                              DropdownMenuItem(
                                value: 'America/Denver',
                                child: Text('Mountain'),
                              ),
                              DropdownMenuItem(
                                value: 'America/Phoenix',
                                child: Text('Arizona'),
                              ),
                              DropdownMenuItem(
                                value: 'America/Los_Angeles',
                                child: Text('Pacific'),
                              ),
                              DropdownMenuItem(
                                value: 'America/Anchorage',
                                child: Text('Alaska'),
                              ),
                              DropdownMenuItem(
                                value: 'Pacific/Honolulu',
                                child: Text('Hawaii'),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedTimezone = value;
                                _checkForChanges();
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),

                  // Profile image section (3/4 width)
                  Expanded(
                    flex: 3,
                    child: Center(
                      child: Column(
                        children: [
                          // User name above profile image
                          Text(
                            '${_firstNameController.text} ${_lastNameController.text}',
                            style: Theme.of(
                              context,
                            ).textTheme.bodyLarge?.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),

                          // Editable Profile Image with hover and click animation
                          MouseRegion(
                            onEnter: (_) {
                              if (mounted) {
                                setState(() => _isProfileImageHovered = true);
                              }
                            },
                            onExit: (_) {
                              if (mounted) {
                                setState(() => _isProfileImageHovered = false);
                              }
                            },
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTapDown: (_) {
                                if (mounted) {
                                  setState(() => _isProfileImagePressed = true);
                                }
                              },
                              onTapUp: (_) {
                                if (mounted) {
                                  setState(
                                    () => _isProfileImagePressed = false,
                                  );
                                }
                                _pickImage();
                              },
                              onTapCancel: () {
                                if (mounted) {
                                  setState(
                                    () => _isProfileImagePressed = false,
                                  );
                                }
                              },
                              child: AnimatedScale(
                                scale:
                                    _isProfileImagePressed
                                        ? 0.92
                                        : (_isProfileImageHovered ? 1.08 : 1.0),
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeOutCubic,
                                child: Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withValues(alpha: 0.9),
                                    boxShadow:
                                        _isProfileImageHovered ||
                                                _isProfileImagePressed
                                            ? [
                                              BoxShadow(
                                                color: Colors.white.withValues(
                                                  alpha: 0.4,
                                                ),
                                                blurRadius: 15,
                                                spreadRadius: 3,
                                              ),
                                            ]
                                            : null,
                                    image:
                                        _profileImage != null
                                            ? DecorationImage(
                                              image: MemoryImage(
                                                _profileImage!,
                                              ),
                                              fit: BoxFit.contain,
                                            )
                                            : null,
                                  ),
                                  child:
                                      _profileImage == null
                                          ? Icon(
                                            Icons.person,
                                            size: 40,
                                            color: const Color(0xFF1B5E20),
                                          )
                                          : Stack(
                                            alignment: Alignment.bottomRight,
                                            children: [
                                              Container(),
                                              Container(
                                                decoration: const BoxDecoration(
                                                  color: Colors.white,
                                                  shape: BoxShape.circle,
                                                ),
                                                padding: const EdgeInsets.all(
                                                  6,
                                                ),
                                                child: const Icon(
                                                  Icons.edit,
                                                  color: Color(0xFF1B5E20),
                                                  size: 16,
                                                ),
                                              ),
                                            ],
                                          ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Error Message
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    border: Border.all(color: Colors.red[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error, color: Colors.red[700]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: Colors.red[700],
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (_errorMessage != null) const SizedBox(height: 16),

              // Form Fields
              _buildTextField(
                label: 'First Name',
                controller: _firstNameController,
                icon: Icons.person,
                enabled: true,
                required: true,
              ),
              const SizedBox(height: 16),

              _buildTextField(
                label: 'Last Name',
                controller: _lastNameController,
                icon: Icons.person,
                enabled: true,
                required: true,
              ),
              const SizedBox(height: 16),

              _buildTextField(
                label: 'Preferred Name',
                controller: _desiredNameController,
                icon: Icons.label,
                enabled: true,
                hint: 'Optional - How you\'d like to be called',
              ),
              const SizedBox(height: 16),

              _buildTextField(
                label: 'Email',
                controller: _emailController,
                icon: Icons.email,
                enabled: true,
                keyboardType: TextInputType.emailAddress,
                required: true,
              ),
              const SizedBox(height: 16),

              _buildTextField(
                label: 'Phone Number',
                controller: _phoneController,
                icon: Icons.phone,
                enabled: true,
                keyboardType: TextInputType.phone,
                hint: 'Optional - (123) 456-7890',
              ),
              const SizedBox(height: 16),

              _buildPasswordField(),
              const SizedBox(height: 32),

              // Change Password Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _openPasswordChangeScreen,
                  icon: const Icon(Icons.lock, color: Colors.white),
                  label: const Text(
                    'Change Password',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 32), // Bottom padding
            ],
          ),
        ),
      ),
    );
  }

  /// Build a text field widget
  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required bool enabled,
    TextInputType keyboardType = TextInputType.text,
    String? hint,
    bool required = false,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      style: TextStyle(
        color: enabled ? Colors.white : Colors.white.withValues(alpha: 0.7),
      ),
      decoration: InputDecoration(
        label:
            required
                ? Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: label),
                      const TextSpan(
                        text: ' *',
                        style: TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
                )
                : Text(
                  label,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
                ),
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
        prefixIcon: Icon(icon, color: Colors.white.withValues(alpha: 0.8)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.white, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
        ),
        filled: !enabled,
        fillColor:
            !enabled
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.white.withValues(alpha: 0.08),
      ),
      cursorColor: Colors.white,
    );
  }

  /// Build password field widget
  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      enabled: false, // Password cannot be edited inline
      obscureText: !_showPassword,
      style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
      decoration: InputDecoration(
        label: Text(
          'Password',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
        ),
        prefixIcon: Icon(
          Icons.lock,
          color: Colors.white.withValues(alpha: 0.8),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        hintText: 'Use "Change Password" button to update',
        hintStyle: TextStyle(
          fontSize: 12,
          color: Colors.white.withValues(alpha: 0.5),
        ),
      ),
      cursorColor: Colors.white,
    );
  }
}
