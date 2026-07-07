import 'package:flutter/material.dart';

class DrawerMenuButton extends StatelessWidget {
  const DrawerMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    // Only show the menu button on mobile/tablet where the drawer is actually used.
    // On desktop, the NavigationRail is always visible.
    return MediaQuery.of(context).size.width >= 850
        ? const SizedBox.shrink()
        : IconButton(
            icon: const Icon(Icons.menu, color: Color(0xFF202124)),
            onPressed: () {
              ScaffoldState? state = context.findAncestorStateOfType<ScaffoldState>();
              while (state != null && !state.hasDrawer) {
                state = state.context.findAncestorStateOfType<ScaffoldState>();
              }
              state?.openDrawer();
            },
          );
  }
}
