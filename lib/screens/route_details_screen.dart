import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:myapp/models/route.dart';
import 'package:myapp/models/stop.dart';
import 'package:myapp/services/transit_service.dart';

// A new data class to hold the combined result
class RouteDetailsData {
  final TransitRoute route;
  final List<Stop> stops;

  RouteDetailsData(this.route, this.stops);
}

class RouteDetailsScreen extends StatefulWidget {
  final TransitRoute route;

  const RouteDetailsScreen({super.key, required this.route});

  @override
  State<RouteDetailsScreen> createState() => _RouteDetailsScreenState();
}

class _RouteDetailsScreenState extends State<RouteDetailsScreen> {
  final TransitService _transitService = TransitService();
  late Future<RouteDetailsData> _detailsFuture;

  @override
  void initState() {
    super.initState();
    _detailsFuture = _loadRouteDetails();
  }

  Future<RouteDetailsData> _loadRouteDetails() async {
    // Fetch the base route details and the stops in parallel
    final results = await Future.wait([
      _transitService.getRouteDetails(widget.route.id),
      _transitService.getStops(widget.route.id),
    ]);

    final route = results[0] as TransitRoute;
    final stops = results[1] as List<Stop>;

    // Extract points from stops and calculate bounds
    final List<LatLng> points = stops
        .where((stop) => stop.location != null)
        .map((stop) => stop.location!)
        .toList();

    LatLngBounds? bounds;
    if (points.isNotEmpty) {
      bounds = LatLngBounds.fromPoints(points);
    }

    // Create a new TransitRoute instance with the points and bounds
    final routeWithGeometry = route.copyWith(points: points, bounds: bounds);

    return RouteDetailsData(routeWithGeometry, stops);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<RouteDetailsData>(
        future: _detailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading route details: ${snapshot.error}'),
            );
          }
          if (!snapshot.hasData) {
            return const Center(
              child: Text('No route details found.'),
            );
          }

          final route = snapshot.data!.route;
          final stops = snapshot.data!.stops;

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 250.0,
                floating: false,
                pinned: true,
                backgroundColor: route.color ?? Theme.of(context).primaryColor,
                foregroundColor: route.textColor ?? Colors.white,
                title: Text(
                  route.shortName ?? route.longName ?? 'Route Details',
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: route.points.isNotEmpty && route.bounds != null
                      ? FlutterMap(
                          options: MapOptions(
                            initialCameraFit: CameraFit.bounds(
                              bounds: route.bounds!,
                              padding: const EdgeInsets.all(40.0), // Increased padding
                            ),
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                              subdomains: const ['a', 'b', 'c'],
                            ),
                            PolylineLayer(
                              polylines: [
                                Polyline(
                                  points: route.points,
                                  color: route.color ?? Colors.blue,
                                  strokeWidth: 4,
                                ),
                              ],
                            ),
                          ],
                        )
                      : Container(
                          color: route.color ?? Theme.of(context).primaryColor,
                          child: Center(
                            child: Text(
                              'Map not available',
                              style: TextStyle(
                                  color: route.textColor ?? Colors.white,
                                  fontSize: 16),
                            ),
                          ),
                        ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        route.longName ?? 'No long name',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      if (route.description != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(route.description!),
                        ),
                      const SizedBox(height: 16),
                      const Text(
                        'Stops',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const Divider(),
                    ],
                  ),
                ),
              ),
              if (stops.isEmpty)
                const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text('No stops found for this route.',
                          style: TextStyle(color: Colors.grey, fontSize: 16)),
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final stop = stops[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: route.color?.withAlpha(51) ??
                                Theme.of(context).primaryColorLight,
                            child: const Icon(
                              Icons.directions_bus,
                              size: 20,
                              color: Colors.black54,
                            ),
                          ),
                          title: Text(
                            stop.name ?? 'Unnamed Stop',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          subtitle: stop.code != null
                              ? Text('Code: ${stop.code}')
                              : null,
                          trailing: (stop.wheelchairBoarding == '1' ||
                                  stop.wheelchairBoarding == '2')
                              ? Icon(
                                  Icons.wheelchair_pickup,
                                  color: Colors.blueAccent,
                                  semanticLabel:
                                      (stop.wheelchairBoarding == '2')
                                          ? 'Wheelchair accessible with assistance'
                                          : 'Fully wheelchair accessible',
                                )
                              : null,
                        ),
                      );
                    },
                    childCount: stops.length,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
