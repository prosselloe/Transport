import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:transport/theme_provider.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? customActions;

  const CustomAppBar({super.key, required this.title, this.customActions});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final canPop = context.canPop();

    return AppBar(
      title: Text(title),
      leading: canPop
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
              tooltip: 'Back',
            )
          : null,
      actions: [
        if (customActions != null) ...customActions!,
        IconButton(
          icon: const Icon(Icons.home),
          onPressed: () => context.go('/'),
          tooltip: 'Home',
        ),
        IconButton(
          icon: const Icon(Icons.favorite),
          onPressed: () => context.go('/favorites'),
          tooltip: 'Favorites',
        ),
        IconButton(
          icon: const Icon(Icons.info_outline),
          onPressed: () => context.go('/about'),
          tooltip: 'About',
        ),
        IconButton(
          icon: Icon(themeProvider.themeMode == ThemeMode.dark
              ? Icons.light_mode
              : Icons.dark_mode),
          onPressed: () => themeProvider.toggleTheme(),
          tooltip: 'Toggle Theme',
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
