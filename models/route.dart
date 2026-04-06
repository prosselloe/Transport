import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:transport/utils/color_utils.dart';

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
    final props = json['properties'] as Map<String, dynamic>? ?? json;

    int routeType = 0;
    final dynamic routeTypeValue = props['route_type'];
    if (routeTypeValue is int) {
      routeType = routeTypeValue;
    } else if (routeTypeValue is String) {
      routeType = int.tryParse(routeTypeValue) ?? 0;
    }

    String? longNameValue;
    if (props['route_long_name'] is String && (props['route_long_name'] as String).isNotEmpty) {
      longNameValue = props['route_long_name'] as String;
    } else if (props['long_name'] is String && (props['long_name'] as String).isNotEmpty) {
      longNameValue = props['long_name'] as String;
    }

    String? agencyId;
    if (json['relationships']?['operator']?['data']?['id'] is String) {
      agencyId = json['relationships']['operator']['data']['id'] as String;
    } else if (json['agency_id'] is String) {
      agencyId = json['agency_id'] as String;
    }

    return TransitRoute(
      id: json['onestop_id'] as String? ?? 'no-id',
      agencyId: agencyId,
      shortName: props['route_short_name'] as String?,
      longName: longNameValue,
      description: props['route_desc'] as String?,
      type: routeType,
      url: props['route_url'] as String?,
      color: props['route_color'] != null ? hexToColor(props['route_color']) : null,
      textColor: props['route_text_color'] != null ? hexToColor(props['route_text_color']) : null,
      bikesAllowed: props['bikes_allowed']?.toString(),
      wheelchairAccessible: props['wheelchair_accessible']?.toString(),
    );
  }

  TransitRoute copyWith({List<LatLng>? points, LatLngBounds? bounds}) {
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

  // For go_router serialization
  Map<String, dynamic> toJson() => {
        'id': id,
        'agencyId': agencyId,
        'shortName': shortName,
        'longName': longName,
        'description': description,
        'type': type,
        'url': url,
        'color': color?.toARGB32(),
        'textColor': textColor?.toARGB32(),
        'bikesAllowed': bikesAllowed,
        'wheelchairAccessible': wheelchairAccessible,
      };

  // For go_router deserialization
  factory TransitRoute.fromJsonForRouter(Map<String, dynamic> json) {
    return TransitRoute(
      id: json['id'] as String,
      agencyId: json['agencyId'] as String?,
      shortName: json['shortName'] as String?,
      longName: json['longName'] as String?,
      description: json['description'] as String?,
      type: json['type'] as int,
      url: json['url'] as String?,
      color: json['color'] != null ? Color(json['color'] as int) : null,
      textColor: json['textColor'] != null ? Color(json['textColor'] as int) : null,
      bikesAllowed: json['bikesAllowed'] as String?,
      wheelchairAccessible: json['wheelchairAccessible'] as String?,
    );
  }
}
