/// Unauthenticated Access Screen
///
/// Displays when an unauthenticated user tries to access a protected page.
/// Shows a sad Golden Retriever with his toy just out of reach.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class UnauthenticatedScreen extends StatelessWidget {
  const UnauthenticatedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    // Responsive image size (smaller on mobile)
    final imageSize = screenWidth < 600 ? 240.0 : 320.0;

    return Scaffold(
      body: GestureDetector(
        onTap: () {
          // Redirect to login on tap
          context.go('/login');
        },
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: const Color(0xFFF5F5F5),
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: screenHeight),
              child: IntrinsicHeight(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 48),
                    // Golden Retriever image with toy (responsive size)
                    SizedBox(
                      width: imageSize,
                      height: imageSize,
                      child: Image.asset(
                        'assets/images/sad_dog_with_toy.jpg',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[300],
                            child: const Center(child: Text('Image not found')),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Sad message
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Oops! Please log in first',
                        style: Theme.of(
                          context,
                        ).textTheme.headlineSmall?.copyWith(
                          color: const Color(0xFF424242),
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'You need to be logged in to access this page',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: const Color(0xFF757575),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Tap to login button
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E7D32),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        'Tap here to log in',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
