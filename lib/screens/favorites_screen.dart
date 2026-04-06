import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:transport/models/agency.dart';
import 'package:transport/providers/favorites_provider.dart';
import 'package:provider/provider.dart';
import 'package:transport/widgets/app_bar.dart';
import 'package:url_launcher/url_launcher.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  Future<void> _launchURL(BuildContext context, String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch $url')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Favorite Agencies'),
      body: Consumer<FavoritesProvider>(
        builder: (context, favoritesProvider, child) {
          if (favoritesProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final favoriteAgencies = favoritesProvider.favoriteAgencies;

          if (favoriteAgencies.isEmpty) {
            return _buildEmptyState();
          }

          return Column(
            children: [
              _buildMapView(context, favoritesProvider),
              Expanded(
                child: _buildAgencyList(
                  context,
                  favoritesProvider,
                  favoriteAgencies,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
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

  Widget _buildMapView(BuildContext context, FavoritesProvider provider) {
    final List<Marker> markers = [];
    final List<LatLng> allPoints = [];

    for (var agency in provider.favoriteAgencies) {
      final stops = provider.stopsByAgency[agency.id] ?? [];
      final agencyColor = Color(agency.id.hashCode).withAlpha(255);

      for (var stop in stops) {
        if (stop.location != null) {
          allPoints.add(stop.location!);

          final bool isMallorcaStop = stop.id.startsWith('mallorca');
          final bool hasUrl = stop.url != null && stop.url!.isNotEmpty;
          VoidCallback? onTapAction;
          if (hasUrl) {
            onTapAction = () => _launchURL(context, stop.url!);
          } else if (isMallorcaStop) {
            onTapAction = () => context.go('/stop/${stop.id}');
          }

          markers.add(
            Marker(
              width: 40.0,
              height: 40.0,
              point: stop.location!,
              child: GestureDetector(
                onTap: onTapAction,
                child: Icon(
                  Icons.location_pin,
                  color: agencyColor,
                  size: 20.0,
                ),
              ),
            ),
          );
        }
      }
    }

    return SizedBox(
      height: 300, 
      child: FlutterMap(
        options: MapOptions(
          initialCenter: const LatLng(39.6, 2.9),
          initialZoom: 9.0,
          initialCameraFit: allPoints.isNotEmpty
              ? CameraFit.bounds(
                  bounds: LatLngBounds.fromPoints(allPoints),
                  padding: const EdgeInsets.all(50.0),
                )
              : null,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: const ['a', 'b', 'c'],
        userAgentPackageName: 'transport.prosselloe.com',
          ),
          MarkerLayer(markers: markers),
        ],
      ),
    );
  }

  Widget _buildAgencyList(
    BuildContext context,
    FavoritesProvider provider,
    List<Agency> agencies,
  ) {
    return ListView.builder(
      itemCount: agencies.length,
      itemBuilder: (context, index) {
        final agency = agencies[index];
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
                provider.toggleAgencyFavorite(agency);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Removed ${agency.name} from favorites'),
                    duration: const Duration(seconds: 2),
                  ),
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
  }
}
