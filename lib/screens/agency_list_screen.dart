import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:transport/models/agency.dart';
import 'package:transport/models/api_exception.dart';
import 'package:transport/providers/favorites_provider.dart';
import 'package:transport/services/transit_service.dart';
import 'package:transport/widgets/app_bar.dart';
import 'package:provider/provider.dart';

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

  void _navigateToPlacesScreen() async {
    final selectedPlaceId = await context.push<String>('/places');
    if (selectedPlaceId != null) {
      setState(() {
        _placeOnestopId = selectedPlaceId;
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
      appBar: CustomAppBar(
        title: 'Transit Agencies',
        customActions: [
          if (_placeOnestopId != null)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: _clearPlaceFilter,
              tooltip: 'Clear Place Filter',
            ),
          IconButton(
            icon: const Icon(Icons.public),
            onPressed: _navigateToPlacesScreen,
            tooltip: 'Filter by Place',
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
                                    agency, 
                                  );
                                },
                              ),
                              onTap: () {
                                context.go('/agency/${agency.id}');
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
