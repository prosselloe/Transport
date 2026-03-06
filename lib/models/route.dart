import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';

class TransitRoute {
  final String id;
  final String? agencyId;
  final String? shortName;
  final String? longName;
  final String? description;
  final int type;
  final String? url;
  final Color? color;
  final Color? textColor;
  final String? bikesAllowed;
  final String? wheelchairAccessible;

  final List<LatLng> points;
  final LatLngBounds? bounds;

  TransitRoute({
    required this.id,
    this.agencyId,
    this.shortName,
    this.longName,
    this.description,
    required this.type,
    this.url,
    this.color,
    this.textColor,
    this.bikesAllowed,
    this.wheelchairAccessible,
    this.points = const [],
    this.bounds,
  });

  factory TransitRoute.fromJson(Map<String, dynamic> json) {
    Color? parseColor(String? colorString) {
      if (colorString == null || colorString.isEmpty) return null;
      final buffer = StringBuffer();
      if (colorString.length == 6 || colorString.length == 7) buffer.write('ff');
      buffer.write(colorString.replaceFirst('#', ''));
      try {
        return Color(int.parse(buffer.toString(), radix: 16));
      } catch (e) {
        return null;
      }
    }

    int routeType = 0;
    final dynamic routeTypeValue = json['route_type'];
    if (routeTypeValue is int) {
      routeType = routeTypeValue;
    } else if (routeTypeValue is String) {
      routeType = int.tryParse(routeTypeValue) ?? 0;
    }

    return TransitRoute(
      id: json['onestop_id'] as String? ?? 'no-id',
      agencyId: json['agency_id'] as String?,
      shortName: json['route_short_name'] as String?,
      longName: json['route_long_name'] as String?,
      description: json['route_desc'] as String?,
      type: routeType,
      url: json['route_url'] as String?,
      color: parseColor(json['route_color'] as String?),
      textColor: parseColor(json['route_text_color'] as String?),
      bikesAllowed: json['bikes_allowed']?.toString(),
      wheelchairAccessible: json['wheelchair_accessible']?.toString(),
      // points and bounds will be populated later
    );
  }

  // Method to create a new instance with updated points and bounds
  TransitRoute copyWith({
    List<LatLng>? points,
    LatLngBounds? bounds,
  }) {
    return TransitRoute(
      id: id,
      agencyId: agencyId,
      shortName: shortName,
      longName: longName,
      description: description,
      type: type,
      url: url,
      color: color,
      textColor: textColor,
      bikesAllowed: bikesAllowed,
      wheelchairAccessible: wheelchairAccessible,
      points: points ?? this.points,
      bounds: bounds ?? this.bounds,
    );
  }
}
