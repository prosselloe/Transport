import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:myapp/models/agency.dart';
import 'package:myapp/models/route.dart';
import 'package:myapp/models/stop.dart';
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
  late Future<List<TransitRoute>> _transitRoutes;
  late Future<Agency> _agencyDetails;
  late Future<List<Stop>> _agencyStops;

  @override
  void initState() {
    super.initState();
    _transitRoutes = _transitService.getRoutes(widget.agency.id);
    _agencyDetails = _transitService
        .getAgenciesByIds([widget.agency.id]).then((agencies) => agencies.first);
    _agencyStops = _transitService.getStopsForAgencies([widget.agency.id]);
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
        'Location permissions are permanently denied, we cannot request permissions.',
      );
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
  IconData _getRouteIcon(int? routeType) {
    switch (routeType) {
      case 0: // Tram, Streetcar, Light rail
        return Icons.tram;
      case 1: // Subway, Metro
        return Icons.subway;
      case 2: // Rail
        return Icons.train;
      case 3: // Bus
        return Icons.directions_bus;
      case 4: // Ferry
        return Icons.directions_boat;
      case 5: // Cable car
        return Icons.tram;
      case 6: // Gondola, Suspended cable car
        return Icons.local_airport; // Using airport icon as a stand-in
      case 7: // Funicular
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
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: Colors.grey[600]),
                            ),
                            if (agency.url != null && agency.url!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 16.0),
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.public),
                                  label: const Text('Visit Website'),
                                  onPressed: () => _launchURL(agency.url!),
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    backgroundColor: Theme.of(
                                      context,
                                    ).primaryColor,
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
                      child: _buildMapWithStops(),
                    ),

                    const SizedBox(height: 24),

                    // Routes Section
                    Text(
                      'Routes',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(height: 20, thickness: 1),

                    // Routes List
                    FutureBuilder<List<TransitRoute>>(
                      future: _transitRoutes,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
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
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
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
                                    _getRouteIcon(route.type),
                                    color:
                                        route.textColor ??
                                        Theme.of(context).primaryColorDark,
                                  ),
                                ),
                                title: Text(
                                  route.longName ??
                                      route.shortName ??
                                      'Unnamed Route',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
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
                                  context.push('/route_details', extra: route);
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

  Widget _buildMapWithStops() {
    return FutureBuilder<List<dynamic>>(
      future: Future.wait([_agencyStops, _determinePosition()]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Map not available: ${snapshot.error}'));
        }
        if (snapshot.hasData) {
          final stops = snapshot.data![0] as List<Stop>;
          final userPosition = snapshot.data![1] as Position;

          final userLocation = LatLng(userPosition.latitude, userPosition.longitude);

          // Filter out stops that don't have valid coordinates
          final validStops = stops.where((stop) => stop.lat != null && stop.lon != null).toList();

          final List<Marker> markers = validStops.map<Marker>((stop) {
            return Marker(
              width: 80.0,
              height: 80.0,
              point: LatLng(stop.lat!, stop.lon!), // Use ! because we filtered nulls
              child: Icon(
                Icons.location_pin,
                color: Theme.of(context).primaryColor,
                size: 20.0,
              ),
            );
          }).toList();

          // Add user's location marker
          markers.add(
            Marker(
              width: 80.0,
              height: 80.0,
              point: userLocation,
              child: const Icon(
                Icons.person_pin_circle,
                color: Colors.blue,
                size: 40.0,
              ),
            ),
          );
          
          // If there are no stops, just center on the user
          if (validStops.isEmpty) {
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
                MarkerLayer(markers: markers), // Will only contain user marker
              ],
            );
          }

          // Determine bounds to fit all markers
          final List<LatLng> points = validStops.map((s) => LatLng(s.lat!, s.lon!)).toList();
          points.add(userLocation);
          final LatLngBounds bounds = LatLngBounds.fromPoints(points);

          return FlutterMap(
            options: MapOptions(
              initialCameraFit: CameraFit.bounds(
                bounds: bounds,
                padding: const EdgeInsets.all(50.0), // Add padding around the markers
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
              ),
              MarkerLayer(markers: markers),
            ],
          );
        } else {
          return const Center(child: Text('Map not available'));
        }
      },
    );
  }
}
