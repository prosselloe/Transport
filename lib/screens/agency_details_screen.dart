import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:transport/models/agency.dart';
import 'package:transport/models/route.dart';
import 'package:transport/models/stop.dart';
import 'package:transport/services/transit_service.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:transport/widgets/app_bar.dart';
import 'package:url_launcher/url_launcher.dart';

// A new data class to hold the combined result
class AgencyDetailsData {
  final Agency? agency;
  final Stop? stop;
  final List<TransitRoute> routes;
  final List<Stop> stops;
  final Position? userPosition;

  AgencyDetailsData({
    this.agency,
    this.stop,
    required this.routes,
    required this.stops,
    this.userPosition,
  });
}

class AgencyDetailsScreen extends StatefulWidget {
  final String? agencyId;
  final String? stopId;

  const AgencyDetailsScreen({super.key, this.agencyId, this.stopId})
      : assert(agencyId != null || stopId != null);

  @override
  State<AgencyDetailsScreen> createState() => _AgencyDetailsScreenState();
}

class _AgencyDetailsScreenState extends State<AgencyDetailsScreen> {
  final TransitService _transitService = TransitService();
  late Future<AgencyDetailsData> _detailsFuture;
  String _appName = 'Unknown App';

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
    _detailsFuture = _loadDetails();
  }

  Future<void> _initPackageInfo() async {
    final PackageInfo info = await PackageInfo.fromPlatform();
    setState(() {
      _appName = info.appName;
    });
  }

  Future<AgencyDetailsData> _loadDetails() async {
    final userPosition = await _determinePosition();

    if (widget.stopId != null) {
      final stop = await _transitService.getStopById(widget.stopId!);
      final routes = await _transitService.getRoutesForStop(widget.stopId!);
      return AgencyDetailsData(
        stop: stop,
        routes: routes,
        stops: [stop], // The map will show only this stop
        userPosition: userPosition,
      );
    } else {
      final results = await Future.wait([
        _transitService.getAgenciesByIds([widget.agencyId!]),
        _transitService.getRoutes(widget.agencyId!),
        _transitService.getStopsForAgencies([widget.agencyId!]),
      ]);

      final agency = (results[0] as List<Agency>).first;
      final routes = results[1] as List<TransitRoute>;
      final stops = results[2] as List<Stop>;

      return AgencyDetailsData(
        agency: agency,
        routes: routes,
        stops: stops,
        userPosition: userPosition,
      );
    }
  }

  Future<Position?> _determinePosition() async {
    try {
      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null; // Don't block if location is off
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition();
    } catch (e) {
      return null; // Handle any other errors gracefully
    }
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
    return FutureBuilder<AgencyDetailsData>(
        future: _detailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(
              appBar: CustomAppBar(title: 'Loading...'),
              body: const Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasError) {
            return Scaffold(
              appBar: CustomAppBar(title: 'Error'),
              body: Center(child: Text('Error: ${snapshot.error}')),
            );
          }
          if (!snapshot.hasData) {
            return Scaffold(
              appBar: CustomAppBar(title: 'No Data'),
              body: const Center(child: Text('No data found')),
            );
          }

          final data = snapshot.data!;
          final String title = data.agency?.name ?? data.stop?.name ?? 'Details';
          final routes = data.routes;

          return Scaffold(
            appBar: CustomAppBar(title: title),
            body: Column(
              children: [
                SizedBox(
                  height: 300,
                  child: _buildMapWithStops(data.stops, data.userPosition),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      _buildDetailsCard(data),
                      const SizedBox(height: 24),
                      Text(
                        'Routes',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const Divider(height: 20, thickness: 1),
                      if (routes.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: Text(
                              'No routes found.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        )
                      else
                        ...routes.map((route) => Card(
                              margin: const EdgeInsets.symmetric(vertical: 8.0),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: route.color ??
                                      Theme.of(context).primaryColorLight,
                                  child: Icon(
                                    _getRouteIcon(route.type),
                                    color: route.textColor ??
                                        Theme.of(context).primaryColorDark,
                                  ),
                                ),
                                title: Text(
                                  route.longName ?? route.shortName ?? 'Unnamed Route',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                subtitle: route.longName != null
                                    ? Text(route.shortName ?? '')
                                    : null,
                                trailing: const Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                                onTap: () {
                                  final routeJson = jsonEncode(route.toJson());
                                  context.go(
                                      '/route_details?route=${Uri.encodeQueryComponent(routeJson)}');
                                },
                              ),
                            )),
                    ],
                  ),
                ),
              ],
            ),
          );
        });
  }


  Widget _buildDetailsCard(AgencyDetailsData data) {
    if (data.agency != null) {
      final agency = data.agency!;
      return Card(
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
      );
    } else if (data.stop != null) {
      final stop = data.stop!;
       return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                stop.name ?? 'Stop Details',
                 style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Stop ID: ${stop.id}',
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    } else {
      return const SizedBox.shrink(); // Return empty widget if no data
    }
  }

  Widget _buildMapWithStops(List<Stop> stops, Position? userPosition) {
    final List<Marker> markers = [];
    final List<LatLng> allPoints = [];

    if (userPosition != null) {
      final userLocation = LatLng(userPosition.latitude, userPosition.longitude);
      allPoints.add(userLocation);
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
    }

    for (final stop in stops) {
      if (stop.lat != null && stop.lon != null) {
        final stopLocation = LatLng(stop.lat!, stop.lon!); 
        allPoints.add(stopLocation);

        final bool isMallorcaStop = stop.id.startsWith('mallorca');
        final bool hasUrl = stop.url != null && stop.url!.isNotEmpty;
        VoidCallback? onTapAction;
        if (hasUrl) {
          onTapAction = () => _launchURL(stop.url!);
        } else if (isMallorcaStop) {
          onTapAction = () => context.go('/stop/${stop.id}');
        }

        markers.add(
          Marker(
            width: 40.0,
            height: 40.0,
            point: stopLocation,
            child: GestureDetector(
              onTap: onTapAction,
              child: Icon(
                Icons.location_pin,
                color: Colors.red,
                size: 20.0,
              ),
            ),
          ),
        );
      }
    }

    final tileLayer = TileLayer(
      urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
      subdomains: const ['a', 'b', 'c'],
      tileProvider: NetworkTileProvider(
        headers: {'User-Agent': _appName},
      ),
    );

    LatLng initialCenter;
    LatLngBounds? bounds;

    if (allPoints.isNotEmpty) {
      if (allPoints.length > 1) {
        bounds = LatLngBounds.fromPoints(allPoints);
        initialCenter = bounds.center;
      } else {
        initialCenter = allPoints.first;
      }
    } else {
      initialCenter = const LatLng(39.6, 2.9);
    }

    return FlutterMap(
      options: MapOptions(
        initialCenter: initialCenter,
        initialZoom: 13.0,
        initialCameraFit: bounds != null 
            ? CameraFit.bounds(
                bounds: bounds,
                padding: const EdgeInsets.all(50.0), 
              ) 
            : null,
      ),
      children: [
        tileLayer,
        MarkerLayer(markers: markers),
      ],
    );
  }
}
