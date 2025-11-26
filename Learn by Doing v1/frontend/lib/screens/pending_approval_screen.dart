/// Pending User Approval Screen
///
/// Displayed to newly signed-up users awaiting admin approval.
/// Features:
/// - Welcome message with Comic Neue font
/// - Dr. Seuss-inspired "Waiting Place" imagery (copyright-compliant)
/// - Seasonal tree images from assets folder (4 images for 4 seasons)
/// - Hamburger menu with Signup and Logout options
/// - Auto-logout after 5 minutes of inactivity
/// - Farewell message upon logout
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import '../services/background_provider.dart';
import '../services/logout_service.dart';
import '../widgets/branded_app_bar.dart';

// Provider for tracking inactivity timer
final inactivityTimerProvider = NotifierProvider<InactivityTimer, Duration>(
  () => InactivityTimer(),
);

class InactivityTimer extends Notifier<Duration> {
  @override
  Duration build() {
    return Duration.zero;
  }

  void reset() {
    state = Duration.zero;
  }

  void increment() {
    state = Duration(seconds: state.inSeconds + 1);
  }
}

class PendingApprovalScreen extends ConsumerStatefulWidget {
  final String? userName;

  const PendingApprovalScreen({super.key, this.userName});

  @override
  ConsumerState<PendingApprovalScreen> createState() =>
      _PendingApprovalScreenState();
}

class _PendingApprovalScreenState extends ConsumerState<PendingApprovalScreen> {
  late BackgroundImage _backgroundImage;
  late Timer _inactivityTimer;
  late Timer _countdownTimer;
  int _secondsRemaining = 300; // 5 minutes in seconds

  @override
  void initState() {
    super.initState();
    _backgroundImage = BackgroundProvider.getTodayBackground();

    // Start inactivity timer (5 minutes = 300 seconds)
    _startInactivityTimer();
  }

  void _startInactivityTimer() {
    _inactivityTimer = Timer(const Duration(minutes: 5), () {
      if (mounted) {
        // Use logout service for consistent UX with snackbar
        final logoutService = ref.read(logoutServiceProvider);
        logoutService.logoutDueToInactivity(
          context,
          ref,
          onBeforeLogout: () {
            _countdownTimer.cancel();
          },
        );
      }
    });

    // Countdown timer for UI updates
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _secondsRemaining--;
        });
      }
      if (_secondsRemaining <= 0) {
        timer.cancel();
      }
    });
  }

  void _resetInactivityTimer() {
    _inactivityTimer.cancel();
    _countdownTimer.cancel();
    _secondsRemaining = 300;
    _startInactivityTimer();
  }

  @override
  void dispose() {
    _inactivityTimer.cancel();
    _countdownTimer.cancel();
    super.dispose();
  }

  String _getSeasonalImagePath() {
    final season = BackgroundProvider.getCurrentSeason();
    switch (season.name) {
      case 'winter':
        return 'assets/images/winter_waiting_place.jpg';
      case 'spring':
        return 'assets/images/spring_waiting_place.jpg';
      case 'summer':
        return 'assets/images/summer_waiting_place.jpg';
      case 'fall':
        return 'assets/images/autumn_waiting_place.jpg';
      default:
        return 'assets/images/summer_waiting_place.jpg';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = _backgroundImage.colors;

    return GestureDetector(
      onTap: _resetInactivityTimer,
      onPanDown: (_) => _resetInactivityTimer(),
      child: Scaffold(
        appBar: BrandedAppBar(
          title: 'Andromeda',
          showMenu: true,
          onLogout: () {
            // Cleanup: cancel timers before logout
            _inactivityTimer.cancel();
            _countdownTimer.cancel();
            // Note: Logout service will handle navigation and snackbar
          },
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colors[0].withValues(alpha: 0.95),
                colors[1].withValues(alpha: 0.90),
                colors[2].withValues(alpha: 0.85),
              ],
            ),
          ),
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: 750),
              child: Column(
                children: [
                  // Welcome Message Section
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 32,
                    ),
                    child: Column(
                      children: [
                        // Welcome Text
                        Text(
                          'Welcome to the Waiting Place',
                          style: GoogleFonts.comicNeue(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: colors[3],
                            shadows: [
                              Shadow(
                                offset: const Offset(2, 2),
                                blurRadius: 4,
                                color: colors[0].withValues(alpha: 0.5),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        // Admin Notification Text
                        Text(
                          'The Admin has been notified that you have signed up',
                          style: GoogleFonts.comicNeue(
                            fontSize: 18,
                            color: colors[3].withValues(alpha: 0.9),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        // Countdown Timer
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: colors[3].withValues(alpha: 0.3),
                              width: 2,
                            ),
                          ),
                          child: Text(
                            'Auto-logout in ${_secondsRemaining ~/ 60}:${(_secondsRemaining % 60).toString().padLeft(2, '0')}',
                            style: GoogleFonts.comicNeue(
                              fontSize: 14,
                              color: colors[3].withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Inspirational Quote and Message (Increased font sizes for WCAG compliance)
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '"There are plenty of places to wait..."\n\nYour approval is on its way!\nWe\'re so glad you joined us.',
                            style: GoogleFonts.comicNeue(
                              fontSize: 18,
                              fontStyle: FontStyle.italic,
                              color: colors[3].withValues(alpha: 0.95),
                              height: 1.8,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Seasonal Tree Image
                  _buildSeasonalMapleTree(colors),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSeasonalMapleTree(List<Color> colors) {
    final season = BackgroundProvider.getCurrentSeason();
    final imagePath = _getSeasonalImagePath();

    // Fixed dimensions to match the smallest image and keep total height <= 800px
    const double imageWidth = 400;
    const double imageHeight = 300;

    return Container(
      height: imageHeight + 70, // Image height + padding + label
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Center(
              child: SizedBox(
                width: imageWidth,
                height: imageHeight,
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: const Center(
                        child: Text('Season image not found'),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Season Label
          Text(
            season.name.toUpperCase(),
            style: GoogleFonts.comicNeue(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: colors[3].withValues(alpha: 0.7),
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }
}
