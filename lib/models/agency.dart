import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:myapp/models/feed_version.dart';
import 'package:myapp/models/place.dart';

// Helper function to safely parse a date string.
DateTime? _parseDate(dynamic dateString) {
  if (dateString is String && dateString.isNotEmpty) {
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      return null;
    }
  }
  return null;
}

// Helper function to safely parse a nested JSON object.
T? _parseNested<T>(dynamic json, T Function(Map<String, dynamic>) fromJson) {
  if (json is Map<String, dynamic>) {
    try {
      return fromJson(json);
    } catch (e) {
      return null;
    }
  }
  return null;
}

class Agency {
  final String id; // onestop_id
  final String name;
  final String? agencyName;
  final String? url;
  final String? timezone;
  final String? lang;
  final String? phone;
  final String? fareUrl;
  final String? email;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final LatLngBounds? bounds;
  final LatLng? center;
  final List<LatLng> polygonPoints; // New field to store polygon points

  final FeedVersion? feedVersion;
  final List<Place> places;
  final List<dynamic> alerts;

  Agency({
    required this.id,
    required this.name,
    this.agencyName,
    this.url,
    this.timezone,
    this.lang,
    this.phone,
    this.fareUrl,
    this.email,
    this.createdAt,
    this.updatedAt,
    this.bounds,
    this.center,
    this.polygonPoints = const [], // Initialize with an empty list
    this.feedVersion,
    this.places = const [],
    this.alerts = const [],
  });

  factory Agency.fromJson(Map<String, dynamic> json) {
    LatLngBounds? bounds;
    LatLng? center;
    List<LatLng> polygonPoints = [];

    if (json['geometry'] != null && json['geometry'] is Map<String, dynamic>) {
      final geometry = json['geometry'] as Map<String, dynamic>;
      final type = geometry['type'] as String?;
      final coordinates = geometry['coordinates'] as List?;

      if (type != null && coordinates != null) {
        double minLat = double.infinity, maxLat = double.negativeInfinity;
        double minLng = double.infinity, maxLng = double.negativeInfinity;

        void updateBoundsFromPoint(List point) {
          if (point.length == 2 && point[0] is num && point[1] is num) {
            final lng = (point[0] as num).toDouble();
            final lat = (point[1] as num).toDouble();
            polygonPoints.add(LatLng(lat, lng)); // Store the point
            minLat = (lat < minLat) ? lat : minLat;
            maxLat = (lat > maxLat) ? lat : maxLat;
            minLng = (lng < minLng) ? lng : minLng;
            maxLng = (lng > maxLng) ? lng : maxLng;
          }
        }

        try {
          if (type == 'Polygon') {
            for (final ring in coordinates.cast<List>()) {
              for (final point in ring.cast<List>()) {
                updateBoundsFromPoint(point);
              }
            }
          } else if (type == 'MultiPolygon') {
            for (final polygon in coordinates.cast<List>()) {
              for (final ring in polygon.cast<List>()) {
                for (final point in ring.cast<List>()) {
                  updateBoundsFromPoint(point);
                }
              }
            }
          } else if (type == 'Point') {
            updateBoundsFromPoint(coordinates);
          }
        } catch (e) {
          // Ignore parsing errors
        }

        if (minLat != double.infinity) {
          bounds = LatLngBounds(LatLng(minLat, minLng), LatLng(maxLat, maxLng));
          center = LatLng((minLat + maxLat) / 2, (minLng + maxLng) / 2);
        }
      }
    }

    return Agency(
      id: json['onestop_id']?.toString() ?? '',
      name: json['name']?.toString() ?? json['agency_name']?.toString() ?? '',
      agencyName: json['agency_name']?.toString(),
      url: json['agency_url']?.toString(),
      timezone: json['agency_timezone']?.toString(),
      lang: json['agency_lang']?.toString(),
      phone: json['agency_phone']?.toString(),
      fareUrl: json['agency_fare_url']?.toString(),
      email: json['agency_email']?.toString(),
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
      bounds: bounds,
      center: center,
      polygonPoints: polygonPoints,
      feedVersion: _parseNested(json['feed_version'], FeedVersion.fromJson),
      places:
          (json['places'] as List<dynamic>?)
              ?.map((p) => _parseNested(p, Place.fromJson))
              .whereType<Place>()
              .toList() ??
          [],
      alerts: json['alerts'] as List<dynamic>? ?? [],
    );
  }
}
