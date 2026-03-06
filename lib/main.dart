import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/models/api_exception.dart';
import 'package:myapp/providers/favorites_provider.dart';
import 'package:myapp/screens/agency_details_screen.dart';
import 'package:myapp/screens/favorites_screen.dart';
import 'package:myapp/screens/agencies_screen.dart';
import 'package:myapp/screens/route_details_screen.dart';
import 'package:myapp/services/transit_service.dart';
import 'package:myapp/models/agency.dart';
import 'package:myapp/models/route.dart' as model;
import 'package:myapp/theme.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:myapp/theme_provider.dart';
import 'package:provider/provider.dart';

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
          builder: (context, state) => const AgencyListScreen(),
        ),
        GoRoute(
          path: '/agency_details',
          builder: (context, state) =>
              AgencyDetailsScreen(agency: state.extra as Agency),
        ),
        GoRoute(
          path: '/route_details',
          builder: (context, state) =>
              RouteDetailsScreen(route: state.extra as model.TransitRoute),
        ),
        GoRoute(
          path: '/favorites',
          builder: (context, state) => const FavoritesScreen(),
        ),
        GoRoute(
          path: '/agencies',
          builder: (context, state) => const AgenciesScreen(),
        ),
      ],
    );

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp.router(
          routerConfig: router,
          title: 'Transit App',
          theme: appTheme,
          darkTheme: darkTheme,
          themeMode: themeProvider.themeMode,
        );
      },
    );
  }
}

class AgencyListScreen extends StatefulWidget {
  const AgencyListScreen({super.key});

  @override
  State<AgencyListScreen> createState() => _AgencyListScreenState();
}

class _AgencyListScreenState extends State<AgencyListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TransitService _transitService = TransitService();
  List<Agency> _agencies = [];
  bool _isLoading = true;
  String? _placeOnestopId;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadInitialAgencies();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch(_searchController.text);
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      _loadInitialAgencies();
      return;
    }
    setState(() {
      _isLoading = true;
    });
    try {
      final agencies = await _transitService.searchAgencies(query);
      if (mounted) {
        setState(() {
          _agencies = agencies;
        });
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.message}')));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadInitialAgencies() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final agencies = await _transitService.getAgencies(
        placeOnestopId: _placeOnestopId,
      );
      if (mounted) {
        setState(() {
          _agencies = agencies;
        });
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.message}')));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToAgenciesScreen() async {
    final selectedAgencyId = await context.push<String>('/agencies');
    if (selectedAgencyId != null) {
      setState(() {
        _placeOnestopId = selectedAgencyId;
        _loadInitialAgencies();
      });
    }
  }

  void _clearPlaceFilter() {
    setState(() {
      _placeOnestopId = null;
    });
    _loadInitialAgencies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transit Agencies'),
        actions: [
          if (_placeOnestopId != null)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: _clearPlaceFilter,
              tooltip: 'Clear Agency Filter',
            ),
          IconButton(
            icon: const Icon(Icons.public),
            onPressed: _navigateToAgenciesScreen,
            tooltip: 'Filter by Place',
          ),
          IconButton(
            icon: const Icon(Icons.favorite),
            onPressed: () {
              context.go('/favorites');
            },
          ),
          IconButton(
            icon: const Icon(Icons.brightness_6),
            onPressed: () {
              Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search Agencies',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          _isLoading
              ? const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              : Expanded(
                  child: Consumer<FavoritesProvider>(
                    builder: (context, favoritesProvider, child) {
                      return ListView.builder(
                        itemCount: _agencies.length,
                        itemBuilder: (context, index) {
                          final agency = _agencies[index];
                          final isFavorite = favoritesProvider.isFavoriteAgency(
                            agency.id,
                          );

                          final titleText = agency.name.isNotEmpty
                              ? agency.name
                              : (agency.agencyName ?? agency.id);

                          final subtitleText = agency.id;

                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: ListTile(
                              title: Text(
                                titleText,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              subtitle: Text(subtitleText),
                              trailing: IconButton(
                                icon: Icon(
                                  isFavorite
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: isFavorite ? Colors.red : null,
                                ),
                                onPressed: () {
                                  favoritesProvider.toggleAgencyFavorite(
                                    agency.id,
                                  );
                                },
                              ),
                              onTap: () {
                                context.go('/agency_details', extra: agency);
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }
}
