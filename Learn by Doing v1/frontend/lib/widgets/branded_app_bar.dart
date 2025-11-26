/// Branded App Bar with BlueberryKids.jpg Background
///
/// Provides a consistent, WCAG 2.2 AA compliant app bar across all screens
/// with the BlueberryKids.jpg image as the background.
///
/// Features:
/// - Background image with darkening overlay for sufficient contrast
/// - White icons and text meeting WCAG contrast requirements (4.5:1 minimum)
/// - Optional hamburger menu with customizable items
/// - Optional back button
/// - Reusable across all app screens
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../services/logout_service.dart';

class BrandedAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String title;
  final bool showMenu;
  final bool showBackButton;
  final bool showBackground;
  final List<Widget>? additionalActions;
  final VoidCallback? onLogout;

  const BrandedAppBar({
    super.key,
    required this.title,
    this.showMenu = true,
    this.showBackButton = false,
    this.showBackground = true,
    this.additionalActions,
    this.onLogout,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(isAdminProvider);

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace:
          showBackground
              ? Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: const AssetImage('assets/images/BlueberryKids.jpg'),
                    fit:
                        BoxFit
                            .cover, // Cover fills entire width, may crop top/bottom
                    alignment:
                        Alignment
                            .topCenter, // Align to top to show more of the upper portion
                    // Darken image for WCAG contrast compliance
                    // This overlay ensures white text/icons have 4.5:1+ contrast ratio
                    colorFilter: ColorFilter.mode(
                      Colors.black.withValues(alpha: 0.5),
                      BlendMode.darken,
                    ),
                  ),
                ),
              )
              : null,
      leading:
          showBackButton
              ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/login');
                  }
                },
                tooltip: 'Back',
              )
              : null,
      title: Text(
        title,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          shadows: [
            // Text shadow for additional contrast enhancement
            const Shadow(
              offset: Offset(1, 1),
              blurRadius: 3,
              color: Colors.black54,
            ),
          ],
        ),
      ),
      actions: [
        ...?additionalActions,
        if (showMenu)
          PopupMenuButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                // Semi-transparent background for additional contrast
                color: Colors.black.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.menu, color: Colors.white, size: 24),
            ),
            tooltip: 'Menu',
            offset: const Offset(0, 56),
            itemBuilder:
                (BuildContext context) => [
                  if (isAdmin)
                    PopupMenuItem(
                      child: const Row(
                        children: [
                          Icon(Icons.admin_panel_settings),
                          SizedBox(width: 8),
                          Text('Admin Dashboard'),
                        ],
                      ),
                      onTap: () {
                        context.go('/admin');
                      },
                    ),
                  PopupMenuItem(
                    child: const Row(
                      children: [
                        Icon(Icons.logout),
                        SizedBox(width: 8),
                        Text('Logout'),
                      ],
                    ),
                    onTap: () {
                      final logoutService = ref.read(logoutServiceProvider);
                      if (onLogout != null) {
                        // Execute custom cleanup before logout
                        onLogout!();
                      }
                      // Perform logout
                      logoutService.logout(context);
                    },
                  ),
                ],
          ),
      ],
    );
  }
}

/// Branded SliverAppBar variant for scrollable content
class BrandedSliverAppBar extends ConsumerWidget {
  final String title;
  final bool showMenu;
  final bool floating;
  final bool pinned;
  final double expandedHeight;
  final List<Widget>? additionalActions;
  final VoidCallback? onLogout;

  const BrandedSliverAppBar({
    super.key,
    required this.title,
    this.showMenu = true,
    this.floating = false,
    this.pinned = true,
    this.expandedHeight = 200.0,
    this.additionalActions,
    this.onLogout,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(isAdminProvider);

    return SliverAppBar(
      expandedHeight: expandedHeight,
      floating: floating,
      pinned: pinned,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                offset: Offset(1, 1),
                blurRadius: 3,
                color: Colors.black54,
              ),
            ],
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: const AssetImage('assets/images/BlueberryKids.jpg'),
              fit:
                  BoxFit.cover, // Cover fills entire width, may crop top/bottom
              alignment:
                  Alignment
                      .topCenter, // Align to top to show more of the upper portion
              // Darken image for WCAG contrast compliance
              colorFilter: ColorFilter.mode(
                Colors.black.withValues(alpha: 0.5),
                BlendMode.darken,
              ),
            ),
          ),
        ),
      ),
      actions: [
        ...?additionalActions,
        if (showMenu)
          PopupMenuButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.menu, color: Colors.white, size: 24),
            ),
            tooltip: 'Menu',
            offset: const Offset(0, 56),
            itemBuilder:
                (BuildContext context) => [
                  if (isAdmin)
                    PopupMenuItem(
                      child: const Row(
                        children: [
                          Icon(Icons.admin_panel_settings),
                          SizedBox(width: 8),
                          Text('Admin Dashboard'),
                        ],
                      ),
                      onTap: () {
                        context.go('/admin');
                      },
                    ),
                  PopupMenuItem(
                    child: const Row(
                      children: [
                        Icon(Icons.logout),
                        SizedBox(width: 8),
                        Text('Logout'),
                      ],
                    ),
                    onTap: () {
                      final logoutService = ref.read(logoutServiceProvider);
                      if (onLogout != null) {
                        // Execute custom cleanup before logout
                        onLogout!();
                      }
                      // Perform logout
                      logoutService.logout(context);
                    },
                  ),
                ],
          ),
      ],
    );
  }
}
