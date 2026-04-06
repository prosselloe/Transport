import 'package:google_maps_flutter/google_maps_flutter.dart';

class Place {
  final String id;
  final String? name;
  final String? description;
  final LatLngBounds? bbox;

  Place({required this.id, this.name, this.description, this.bbox});

  factory Place.fromJson(Map<String, dynamic> json) {
    LatLngBounds? bounds;
    if (json['bbox'] is List && (json['bbox'] as List).length == 4) {
      final bboxList = json['bbox'] as List;
      bounds = LatLngBounds(
        southwest: LatLng(bboxList[1].toDouble(), bboxList[0].toDouble()),
        northeast: LatLng(bboxList[3].toDouble(), bboxList[2].toDouble()),
      );
    }

    return Place(
      // Defensive toString() conversion for all string fields
      id: json['id']?.toString() ?? '', // id is required, ensure it's a string
      name: json['name']?.toString(),
      description: json['description']?.toString(),
      bbox: bounds,
    );
  }
}
