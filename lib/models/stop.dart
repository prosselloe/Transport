import 'package:latlong2/latlong.dart';

class Stop {
  final String id;
  final String? name;
  final String? code;
  final String? description;
  final double? lat;
  final double? lon;
  final String? zoneId;
  final String? url;
  final String? locationType;
  final String? parentStation;
  final String? wheelchairBoarding;
  final String? platformCode;

  Stop({
    required this.id,
    this.name,
    this.code,
    this.description,
    this.lat,
    this.lon,
    this.zoneId,
    this.url,
    this.locationType,
    this.parentStation,
    this.wheelchairBoarding,
    this.platformCode,
  });

  // Getter to compute LatLng from lat and lon. This remains useful.
  LatLng? get location {
    if (lat != null && lon != null) {
      return LatLng(lat!, lon!);
    }
    return null;
  }

  factory Stop.fromJson(Map<String, dynamic> json) {
    double? latitude;
    double? longitude;

    // Correctly parse the nested geometry object as you discovered.
    if (json.containsKey('geometry') && json['geometry'] is Map) {
      final geometry = json['geometry'] as Map<String, dynamic>;
      if (geometry.containsKey('coordinates') &&
          geometry['coordinates'] is List &&
          (geometry['coordinates'] as List).length >= 2) {
        final coordinates = geometry['coordinates'] as List;
        // Per the GeoJSON standard, it's [longitude, latitude].
        longitude = (coordinates[0] as num?)?.toDouble();
        latitude = (coordinates[1] as num?)?.toDouble();
      }
    }

    return Stop(
      id: json['onestop_id'] as String? ?? 'no-id',
      name: json['stop_name'] as String?,
      code: json['stop_code'] as String?,
      description: json['stop_desc'] as String?,
      lat: latitude, // Use the correctly parsed latitude
      lon: longitude, // Use the correctly parsed longitude
      zoneId: json['zone_id'] as String?,
      url: json['stop_url'] as String?,
      locationType: json['location_type']?.toString(),
      parentStation: json['parent_station'] as String?,
      wheelchairBoarding: json['wheelchair_boarding']?.toString(),
      platformCode: json['platform_code'] as String?,
    );
  }
}
