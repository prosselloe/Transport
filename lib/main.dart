import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:transport/models/route.dart' as model;
import 'package:transport/providers/favorites_provider.dart';
import 'package:transport/screens/about_screen.dart';
import 'package:transport/screens/agencies_screen.dart';
import 'package:transport/screens/agency_details_screen.dart';
import 'package:transport/screens/favorites_screen.dart';
import 'package:transport/screens/route_details_screen.dart';
import 'package:transport/theme.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:transport/theme_provider.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => FavoritesProvider()),
      ],
      child: const MyApp(),
    ),
  );
  FlutterNativeSplash.remove();
}

class ErrorApp extends StatelessWidget {
  final String errorMessage;

  const ErrorApp({super.key, required this.errorMessage});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, color: Colors.red, size: 50),
              const SizedBox(height: 10),
              Text('Error', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 10),
              Text(
                errorMessage,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const AgenciesScreen(),
          routes: [
            GoRoute(
              path: 'agency/:agencyId',
              builder: (context, state) {
                final agencyId = state.pathParameters['agencyId']!;
                return AgencyDetailsScreen(agencyId: agencyId);
              },
            ),
            GoRoute(
              path: 'stop/:stopId',
              builder: (context, state) {
                final stopId = state.pathParameters['stopId']!;
                return AgencyDetailsScreen(stopId: stopId);
              },
            ),
            GoRoute(
              path: 'route_details',
              builder: (context, state) {
                final routeJson = state.uri.queryParameters['route'];
                if (routeJson != null) {
                  final route = model.TransitRoute.fromJsonForRouter(
                      jsonDecode(routeJson) as Map<String, dynamic>);
                  return RouteDetailsScreen(route: route);
                } else {
                  return const Scaffold(
                    body: Center(
                      child: Text('Error: Route data not provided.'),
                    ),
                  );
                }
              },
            ),
            GoRoute(
              path: 'favorites',
              builder: (context, state) => const FavoritesScreen(),
            ),
             GoRoute(
              path: 'about',
              builder: (context, state) => const AboutScreen(),
            ),
          ],
        ),
      ],
    );

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp.router(
          routerConfig: router,
          title: 'Transport Balears',
          theme: appTheme,
          darkTheme: darkTheme,
          themeMode: themeProvider.themeMode,
        );
      },
    );
  }
}
