import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:transport/models/route.dart';
import 'package:transport/models/stop.dart';
import 'package:transport/services/transit_service.dart';
import 'package:transport/widgets/app_bar.dart';
import 'package:url_launcher/url_launcher.dart';

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
    final results = await Future.wait([
      _transitService.getRouteWithGeometry(widget.route),
      _transitService.getStops(widget.route.id),
    ]);

    TransitRoute routeWithGeometry = results[0] as TransitRoute;
    final stops = results[1] as List<Stop>;

    if (routeWithGeometry.points.isEmpty && stops.isNotEmpty) {
      final List<LatLng> stopPoints = stops
          .where((stop) => stop.location != null)
          .map((stop) => stop.location!)
          .toList();

      if (stopPoints.isNotEmpty) {
        final bounds = LatLngBounds.fromPoints(stopPoints);
        routeWithGeometry = routeWithGeometry.copyWith(
          points: stopPoints,
          bounds: bounds,
        );
      }
    }

    return RouteDetailsData(routeWithGeometry, stops);
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch $url')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<RouteDetailsData>(
      future: _detailsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: CustomAppBar(title: 'Loading Route...'),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            appBar: CustomAppBar(title: 'Error'),
            body: Center(
              child: Text('Error loading route details: ${snapshot.error}'),
            ),
          );
        }
        if (!snapshot.hasData) {
          return Scaffold(
            appBar: CustomAppBar(title: 'No Data'),
            body: const Center(child: Text('No route details found.')),
          );
        }

        final route = snapshot.data!.route;
        final stops = snapshot.data!.stops;
        final title = route.longName != null && route.longName!.isNotEmpty
            ? route.longName!
            : route.shortName ?? 'Route Details';

        return Scaffold(
          appBar: CustomAppBar(title: title),
          body: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 250,
                  child: _buildMap(route, stops),
                ),
              ),
              if (route.longName != null && route.longName!.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 0.0),
                    child: Text(
                      route.longName!,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      textAlign: TextAlign.left,
                    ),
                  ),
                ),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                  child: Text(
                    'Stops',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              _buildSliverStopList(stops, route),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMap(TransitRoute route, List<Stop> stops) {
    if (route.points.isEmpty || route.bounds == null) {
      return Container(
        color: Colors.grey[300],
        child: const Center(
          child: Text(
            'Map data not available.',
            style: TextStyle(color: Colors.black54),
          ),
        ),
      );
    }

    return FlutterMap(
      options: MapOptions(
        initialCameraFit: CameraFit.bounds(
          bounds: route.bounds!,
          padding: const EdgeInsets.all(40.0),
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c'],
          userAgentPackageName: 'transport.prosselloe.com',
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
        MarkerLayer(
          markers: stops
              .where((stop) => stop.location != null)
              .map((stop) {
                final bool isMallorcaStop = stop.id.startsWith('mallorca');
                final bool hasUrl = stop.url != null && stop.url!.isNotEmpty;
                VoidCallback? onTapAction;
                if (hasUrl) {
                  onTapAction = () => _launchURL(stop.url!);
                } else if (isMallorcaStop) {
                  onTapAction = () => context.go('/stop/${stop.id}');
                }
                return Marker(
                  point: stop.location!,
                  width: 40,
                  height: 40,
                  child: GestureDetector(
                    onTap: onTapAction,
                    child: Icon(
                      Icons.location_pin,
                      color: route.color ?? Colors.red,
                      size: 20,
                    ),
                  ),
                );
              })
              .toList(),
        ),
      ],
    );
  }

  Widget _buildSliverStopList(List<Stop> stops, TransitRoute route) {
    if (stops.isEmpty) {
      return const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(32.0),
            child: Text(
              'No stops found for this route.',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final stop = stops[index];
          final isMallorcaStop = stop.id.startsWith('mallorca');
          final hasUrl = stop.url != null && stop.url!.isNotEmpty;

          VoidCallback? onTapAction;
          Widget trailingWidget = const SizedBox.shrink();

          if (hasUrl) {
            onTapAction = () => _launchURL(stop.url!);
            trailingWidget = Icon(Icons.link, size: 20, color: Colors.grey);
          } else if (isMallorcaStop) {
            onTapAction = () => context.go('/stop/${stop.id}');
            trailingWidget =
                const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey);
          }

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor:
                    route.color?.withAlpha(51) ?? Theme.of(context).primaryColorLight,
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
              subtitle: stop.code != null ? Text('Code: ${stop.code}') : null,
              trailing: trailingWidget,
              onTap: onTapAction,
            ),
          );
        },
        childCount: stops.length,
      ),
    );
  }
}
