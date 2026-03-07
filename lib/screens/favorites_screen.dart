import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:myapp/models/stop.dart';
import 'package:myapp/providers/favorites_provider.dart';
import 'package:provider/provider.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  late final MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FavoritesProvider>(
      builder: (context, favoritesProvider, child) {
        return Scaffold(
          appBar: AppBar(title: const Text('Favorite Agencies and Stops')),
          body: _buildBody(context, favoritesProvider),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, FavoritesProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.favoriteAgencies.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border, size: 80, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              'No Favorites Yet',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Tap the heart icon on any agency to add it here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(flex: 3, child: _buildMap(provider.favoriteStops, provider)),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12.0),
          child: Text(
            'Favorite Agencies',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(flex: 2, child: _buildAgencyList(provider)),
      ],
    );
  }

  Widget _buildMap(List<Stop> stops, FavoritesProvider provider) {
    final validStops = stops
        .where((s) => s.lat != null && s.lon != null)
        .toList();

    final markers = validStops.map((stop) {
      return Marker(
        width: 80.0,
        height: 80.0,
        point: LatLng(stop.lat!, stop.lon!),
        child: Tooltip(
          message: stop.name ?? 'Unnamed Stop',
          child: const Icon(Icons.location_pin, color: Colors.red, size: 30),
        ),
      );
    }).toList();

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: const LatLng(39.6, 3.2),
        initialZoom: 8.5,
        onMapReady: () {
          if (validStops.isNotEmpty) {
            final bounds = LatLngBounds.fromPoints(
              validStops.map((s) => LatLng(s.lat!, s.lon!)).toList(),
            );
            _mapController.fitCamera(
              CameraFit.bounds(
                bounds: bounds,
                padding: const EdgeInsets.all(50),
              ),
            );
          }
        },
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c'],
        ),
        MarkerLayer(markers: markers),
      ],
    );
  }

  Widget _buildAgencyList(FavoritesProvider provider) {
    return ListView.builder(
      itemCount: provider.favoriteAgencies.length,
      itemBuilder: (context, index) {
        final agency = provider.favoriteAgencies[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: ListTile(
            title: Text(
              agency.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(agency.id),
            trailing: IconButton(
              icon: const Icon(Icons.favorite, color: Colors.red),
              tooltip: 'Remove from Favorites',
              onPressed: () {
                provider.toggleAgencyFavorite(agency.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Removed ${agency.name} from favorites'),
                    duration: const Duration(seconds: 2),
                  ),
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
  }
}
