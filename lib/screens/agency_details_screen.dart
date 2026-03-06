import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:myapp/models/agency.dart';
import 'package:myapp/models/route.dart' as model;
import 'package:myapp/services/transit_service.dart';
import 'package:url_launcher/url_launcher.dart';

class AgencyDetailsScreen extends StatefulWidget {
  final Agency agency;

  const AgencyDetailsScreen({super.key, required this.agency});

  @override
  State<AgencyDetailsScreen> createState() => _AgencyDetailsScreenState();
}

class _AgencyDetailsScreenState extends State<AgencyDetailsScreen> {
  final TransitService _transitService = TransitService();
  late Future<List<model.TransitRoute>> _transitRoutes;
  late Future<Agency> _agencyDetails;

  @override
  void initState() {
    super.initState();
    _transitRoutes = _transitService.getRoutes(widget.agency.id);
    _agencyDetails = _transitService.getAgenciesByIds([widget.agency.id]).then((agencies) => agencies.first);
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.');
    }

    return await Geolocator.getCurrentPosition();
  }


  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      if (!mounted) return; // Check if the widget is still in the tree
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not launch $url')));
    }
  }

  // Helper function to get an icon based on the route type
  IconData _getRouteIcon(String? routeType) {
    switch (routeType) {
      case '0': // Tram, Streetcar, Light rail
        return Icons.tram;
      case '1': // Subway, Metro
        return Icons.subway;
      case '2': // Rail
        return Icons.train;
      case '3': // Bus
        return Icons.directions_bus;
      case '4': // Ferry
        return Icons.directions_boat;
      case '5': // Cable car
        return Icons.tram;
      case '6': // Gondola, Suspended cable car
        return Icons.local_airport; // Using airport icon as a stand-in
      case '7': // Funicular
        return Icons.directions_railway;
      default:
        return Icons.directions;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.agency.name), elevation: 4),
      body: FutureBuilder<Agency>(
        future: _agencyDetails,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.hasData) {
            final agency = snapshot.data!;
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Agency Info Card
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              agency.name,
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Agency ID: ${agency.id}',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                            if (agency.url != null &&
                                agency.url!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 16.0),
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.public),
                                  label: const Text('Visit Website'),
                                  onPressed: () => _launchURL(agency.url!),
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    backgroundColor: Theme.of(context).primaryColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Map Section
                    SizedBox(
                      height: 300,
                      child: _buildMap(agency),
                    ),

                    const SizedBox(height: 24),

                    // Routes Section
                    Text(
                      'Routes',
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const Divider(height: 20, thickness: 1),

                    // Routes List
                    FutureBuilder<List<model.TransitRoute>>(
                      future: _transitRoutes,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              'Error loading routes: ${snapshot.error}',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          );
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32.0),
                              child: Text(
                                'No routes found for this agency.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 16, color: Colors.grey),
                              ),
                            ),
                          );
                        }

                        final routes = snapshot.data!;

                        return ListView.builder(
                          shrinkWrap: true, // Important for nested lists
                          physics:
                              const NeverScrollableScrollPhysics(), // Disable scrolling of the inner list
                          itemCount: routes.length,
                          itemBuilder: (context, index) {
                            final route = routes[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8.0),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor:
                                      route.color ??
                                      Theme.of(context).primaryColorLight,
                                  child: Icon(
                                    _getRouteIcon(route.type.toString()),
                                    color:
                                        route.textColor ??
                                        Theme.of(context).primaryColorDark,
                                  ),
                                ),
                                title: Text(
                                  route.longName ??
                                      route.shortName ??
                                      'Unnamed Route',
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                                subtitle: route.shortName != null
                                    ? Text(route.shortName!)
                                    : null,
                                trailing: const Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                                onTap: () {
                                  context.go('/route_details', extra: route);
                                },
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          } else {
            return const Center(child: Text('Agency not found'));
          }
        },
      ),
    );
  }

  Widget _buildMap(Agency agency) {
    // If there is a polygon, show it
    if (agency.polygonPoints.isNotEmpty && agency.bounds != null) {
      return FlutterMap(
        options: MapOptions(
          initialCameraFit: CameraFit.bounds(
            bounds: agency.bounds!,
            padding: const EdgeInsets.all(20.0), // Add some padding
          ),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: const ['a', 'b', 'c'],
          ),
          PolygonLayer(
            polygons: [
              Polygon(
                points: agency.polygonPoints,
                color: Theme.of(context).primaryColor.withOpacity(0.3),
                borderColor: Theme.of(context).primaryColor,
                borderStrokeWidth: 2,
              ),
            ],
          ),
        ],
      );
    } 
    // If there is just a center point, show a marker
    else if (agency.center != null) {
      return FlutterMap(
        options: MapOptions(
          initialCenter: agency.center!,
          initialZoom: 13.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: const ['a', 'b', 'c'],
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: agency.center!,
                child: Icon(
                  Icons.location_pin,
                  color: Theme.of(context).primaryColor,
                  size: 40.0,
                ),
              ),
            ],
          ),
        ],
      );
    } 
    // As a fallback, try showing the user's location
    else {
      return FutureBuilder<Position>(
        future: _determinePosition(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Map not available: ${snapshot.error}'));
          }
          if (snapshot.hasData) {
            final userLocation = LatLng(snapshot.data!.latitude, snapshot.data!.longitude);
            return FlutterMap(
              options: MapOptions(
                initialCenter: userLocation,
                initialZoom: 13.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c'],
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: userLocation,
                      child: const Icon(
                        Icons.person_pin_circle,
                        color: Colors.blue,
                        size: 40.0,
                      ),
                    ),
                  ],
                ),
              ],
            );
          }
          return const Center(child: Text('Map not available'));
        },
      );
    }
  }
}
