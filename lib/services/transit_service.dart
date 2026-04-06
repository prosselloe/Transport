import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:mallorca_transit_services/mallorca_transit_services.dart'
    as mallorca_transit;
import 'package:transport/models/agency.dart';
import 'package:transport/models/api_exception.dart';
import 'package:transport/models/place.dart';
import 'package:transport/models/route.dart';
import 'package:transport/models/stop.dart';
import 'package:polyline_codec/polyline_codec.dart';
import 'package:flutter_map/flutter_map.dart'; // Added import

class TransitService {
  final String _baseUrl = 'https://transit.land/api/v2/rest';
  final String _apiKey = 'UiMWbgxH7E1mmKUJZ6AApHyjVv0GQdYo';

  final List<String> _mallorcaAgencyIds = [
    'o-sp4-consorcidemallorca-consorcidetransportsdemallorca',
    'o-spp-consorcidetransportsdemallorca', // Simplified ID
  ];

  final String _mallorcaIdSeparator = '::';
  final String _mallorcaPrefix = 'mallorca';

  // Helper to create a consistent Mallorca Agency object
  Agency _createMallorcaAgency() {
    return Agency(
      id: 'o-spp-consorcidetransportsdemallorca', // Use a single, consistent ID
      agencyName: 'Consorci de Transports de Mallorca',
      name: 'Consorci de Transports de Mallorca', 
      url: 'https://www.tib.org',
    );
  }

  TransitRoute _fromMallorcaRouteLine(
    mallorca_transit.RouteLine line,
    String agencyId,
  ) {
    int routeType;
    switch (line.type.index) {
      case 0: // bus
        routeType = 3;
        break;
      case 1: // train
        routeType = 2;
        break;
      case 2: // metro
        routeType = 1;
        break;
      default:
        routeType = 3;
    }

    return TransitRoute(
      id: '$_mallorcaPrefix$_mallorcaIdSeparator$agencyId$_mallorcaIdSeparator${line.code}',
      agencyId: agencyId,
      shortName: line.code.toString(),
      longName: line.name,
      color: Color(line.color),
      textColor: Colors.white,
      type: routeType,
    );
  }

  Stop _fromMallorcaStation(mallorca_transit.Station station) {
    return Stop(
      id: '$_mallorcaPrefix$_mallorcaIdSeparator${station.id}',
      name: station.name,
      lat: station.lat,
      lon: station.long,
    );
  }

  List<T> _parseList<T>(
    String responseBody,
    String key,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final parsed = json.decode(responseBody);
    final list = parsed[key] as List;
    return list
        .map<T>((json) => fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<http.Response> _get(String url) async {
    developer.log(
      'Fetching from Transit.land: $url',
      name: 'myapp.service.info',
    );
    return http.get(Uri.parse(url));
  }

  Future<List<Agency>> searchAgencies(String query) async {
    final url = '$_baseUrl/agencies?search=$query&limit=50&api_key=$_apiKey';
    try {
      final response = await _get(url);
      if (response.statusCode == 200) {
        final agencies = _parseList(response.body, 'agencies', Agency.fromJson);
        // Special handling for Mallorca search
        if (query.toLowerCase().contains('mallorca')) {
          agencies.insert(0, _createMallorcaAgency());
        }
        return agencies;
      } else {
        throw ApiException(
          'Failed to search agencies. Status: ${response.statusCode}',
        );
      }
    } on SocketException {
      throw ApiException('No internet connection.');
    } catch (e) {
      developer.log('Error in searchAgencies: $e', name: 'myapp.service.error');
      rethrow;
    }
  }

  Future<List<Agency>> getAgencies({String? placeOnestopId}) async {
    String urlStr =
        '$_baseUrl/agencies/?adm1_name=Baleares&limit=100&api_key=$_apiKey';
    if (placeOnestopId != null) {
      urlStr =
          '$_baseUrl/agencies/?place_onestop_id=$placeOnestopId&limit=100&api_key=$_apiKey';
    }
    try {
      final response = await _get(urlStr);
      if (response.statusCode == 200) {
        return _parseList(response.body, 'agencies', Agency.fromJson);
      } else {
        throw ApiException(
          'Failed to load agencies. Status: ${response.statusCode}',
        );
      }
    } on SocketException {
      throw ApiException('No internet connection.');
    } catch (e) {
      developer.log('Error in getAgencies: $e', name: 'myapp.service.error');
      rethrow;
    }
  }

  Future<List<Agency>> getAgenciesByIds(List<String> agencyIds) async {
    if (agencyIds.isEmpty) return [];

    final List<Agency> allAgencies = [];
    final List<String> transitLandIds = [];
    bool needsMallorcaAgency = false;

    for (final id in agencyIds) {
      if (_mallorcaAgencyIds.contains(id)) {
        needsMallorcaAgency = true;
      } else {
        transitLandIds.add(id);
      }
    }

    // Fetch from Mallorca service if needed
    if (needsMallorcaAgency) {
      allAgencies.add(_createMallorcaAgency());
    }

    // Fetch from Transit.land if needed
    if (transitLandIds.isNotEmpty) {
      final url =
          '$_baseUrl/agencies?onestop_id=${transitLandIds.join(',')}&api_key=$_apiKey';
      try {
        final response = await _get(url);
        if (response.statusCode == 200) {
          final agencies = _parseList(response.body, 'agencies', Agency.fromJson);
          allAgencies.addAll(agencies);
        } else {
          developer.log(
            'Failed to load some agencies by IDs. Status: ${response.statusCode}',
            name: 'myapp.service.warning',
          );
        }
      } on SocketException {
         developer.log('No internet connection for Transit.land', name: 'myapp.service.warning');
      } catch (e) {
        developer.log(
          'Error in getAgenciesByIds for Transit.land: $e',
          name: 'myapp.service.error',
        );
      }
    }

    return allAgencies;
  }


  Future<List<TransitRoute>> getRoutes(String agencyId) async {
    if (_mallorcaAgencyIds.contains(agencyId)) {
      try {
        developer.log(
          'Fetching Mallorca routes for agency $agencyId',
          name: 'myapp.service.info',
        );
        final mallorcaLines = await mallorca_transit.RouteLine.getAllLines();
        return mallorcaLines
            .map((line) => _fromMallorcaRouteLine(line, agencyId))
            .toList();
      } catch (e) {
        developer.log(
          'Error getting Mallorca routes: $e',
          name: 'myapp.service.error',
        );
        throw ApiException('Could not fetch Mallorca routes.');
      }
    }
    final url =
        '$_baseUrl/routes?operator_onestop_id=$agencyId&limit=500&api_key=$_apiKey';
    try {
      final response = await _get(url);
      if (response.statusCode == 200) {
        return _parseList(response.body, 'routes', TransitRoute.fromJson);
      } else {
        throw ApiException(
          'Failed to load routes. Status: ${response.statusCode}',
        );
      }
    } on SocketException {
      throw ApiException('No internet connection.');
    } catch (e) {
      developer.log('Error in getRoutes: $e', name: 'myapp.service.error');
      rethrow;
    }
  }

  Future<TransitRoute> getRouteWithGeometry(TransitRoute route) async {
    if (route.id.startsWith(_mallorcaPrefix)) {
      return route; // Mallorca routes already have what they need
    }

    final url =
        '$_baseUrl/routes/${route.id}/?include=geometry&api_key=$_apiKey';

    try {
      final response = await _get(url);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final geometry = json['properties']?['geometry']?['coordinates'];
        final encodedPolyline = json['properties']?['geometry_polyline'] as String?;

        List<LatLng> points = [];
        if (encodedPolyline != null) {
          final decoded = PolylineCodec.decode(encodedPolyline);
          points = decoded.map((p) => LatLng(p[0].toDouble(), p[1].toDouble())).toList();
        } else if (geometry is List) {
          points = geometry
              .map((point) => LatLng(point[1] as double, point[0] as double))
              .toList();
        }

        if (points.isNotEmpty) {
          final bounds = LatLngBounds.fromPoints(points);
          return route.copyWith(points: points, bounds: bounds);
        } else {
          return route;
        }
      } else {
        throw ApiException(
          'Failed to fetch route geometry. Status: ${response.statusCode}',
        );
      }
    } on SocketException {
      throw ApiException('No internet connection.');
    } catch (e) {
      developer.log('Error in getRouteWithGeometry: $e', name: 'myapp.service.error');
      rethrow;
    }
  }

  Future<List<Stop>> getStops(String routeId) async {
    if (routeId.startsWith(_mallorcaPrefix)) {
      try {
        final parts = routeId.split(_mallorcaIdSeparator);
        if (parts.length != 3) {
          throw ApiException('Invalid Mallorca route ID format.');
        }
        final routeCode = parts[2];
        developer.log(
          'Fetching Mallorca stops for route code $routeCode',
          name: 'myapp.service.info',
        );
        final lineDetails = await mallorca_transit.RouteLine.getLine(routeCode);

        final allStations = (lineDetails.sublines ?? [])
            .expand((subLine) => subLine.stations)
            .toList();

        final uniqueStops = <String, Stop>{};
        for (final station in allStations) {
          final stop = _fromMallorcaStation(station);
          uniqueStops[stop.id] = stop;
        }

        return uniqueStops.values.toList();

      } catch (e) {
        developer.log(
          'Error getting Mallorca stops: $e',
          name: 'myapp.service.error',
        );
        throw ApiException('Could not fetch Mallorca stops.');
      }
    }
    final url =
        '$_baseUrl/stops?served_by_onestop_ids=$routeId&limit=1000&api_key=$_apiKey';
    final response = await _get(url);
    if (response.statusCode == 200) {
      return _parseList(response.body, 'stops', Stop.fromJson);
    } else {
      throw ApiException(
        'Failed to load stops. Status: ${response.statusCode}',
      );
    }
  }

  Future<List<Stop>> getStopsForAgencies(List<String> agencyIds) async {
    if (agencyIds.isEmpty) return [];

    List<Stop> allStops = [];
    List<String> nonMallorcaAgencies = [];
    bool processMallorca = false;

    for (var id in agencyIds) {
      if (_mallorcaAgencyIds.contains(id)) {
        processMallorca = true;
      } else {
        nonMallorcaAgencies.add(id);
      }
    }

    if (processMallorca) {
      try {
        List<Future<List<Stop>>> mallorcaStopFutures = [];

        // We only need to fetch Mallorca data once, regardless of how many
        // Mallorca agency IDs were in the input list.
        final routes = await getRoutes(_mallorcaAgencyIds.first);
        for (final route in routes) {
          mallorcaStopFutures.add(getStops(route.id));
        }

        final listOfStopLists = await Future.wait(mallorcaStopFutures);
        final mallorcaStops = listOfStopLists.expand((stopList) => stopList).toList();
        allStops.addAll(mallorcaStops);

      } catch (e) {
        developer.log(
          'Error fetching all stops for Mallorca agencies: $e',
          name: 'myapp.service.error',
        );
      }
    }

    if (nonMallorcaAgencies.isNotEmpty) {
      final url = '$_baseUrl/stops?served_by_onestop_ids=${nonMallorcaAgencies.join(',')}&limit=2000&api_key=$_apiKey';
      try {
        final response = await _get(url);
        if (response.statusCode == 200) {
          final transitLandStops = _parseList(response.body, 'stops', Stop.fromJson);
          allStops.addAll(transitLandStops);
        } else {
           developer.log(
            'Failed to load stops for non-Mallorca agencies. Status: ${response.statusCode}',
            name: 'myapp.service.warning',
          );
        }
      } on SocketException {
         developer.log('No internet connection for Transit.land stops', name: 'myapp.service.warning');
      } catch(e) {
        developer.log(
          'Error fetching stops for non-Mallorca agencies: $e',
          name: 'myapp.service.error',
        );
      }
    }

    // Deduplicate stops before returning
    final stopIds = <String>{};
    allStops.retainWhere((stop) => stopIds.add(stop.id));

    return allStops;
  }
  Future<List<TransitRoute>> getRoutesForStop(String stopId) async {
    if (stopId.startsWith(_mallorcaPrefix)) {
      try {
        final parts = stopId.split(_mallorcaIdSeparator);
        if (parts.length < 2) return []; // Basic validation

        final searchId = int.tryParse(parts[1]);
        if (searchId == null) return []; // Not a valid integer ID

        final allLines = await mallorca_transit.RouteLine.getAllLines();
        final List<TransitRoute> routes = [];

        for (final line in allLines) {
          final lineDetails = await mallorca_transit.RouteLine.getLine(line.code);
          final containsStop = (lineDetails.sublines ?? []).any((subline) => 
              subline.stations.any((station) => station.id == searchId)
          );
          if (containsStop) {
            routes.add(_fromMallorcaRouteLine(line, _mallorcaAgencyIds.first));
          }
        }
        return routes;
      } catch (e) {
        developer.log(
          'Error getting Mallorca routes for stop $stopId: $e',
          name: 'myapp.service.error',
        );
        throw ApiException('Could not fetch Mallorca routes for stop.');
      }
    }

    final url =
        '$_baseUrl/routes?served_by_onestop_ids=$stopId&limit=100&api_key=$_apiKey';
    try {
      final response = await _get(url);
      if (response.statusCode == 200) {
        return _parseList(response.body, 'routes', TransitRoute.fromJson);
      } else {
        throw ApiException(
          'Failed to load routes for stop. Status: ${response.statusCode}',
        );
      }
    } on SocketException {
      throw ApiException('No internet connection.');
    } catch (e) {
      developer.log('Error in getRoutesForStop: $e', name: 'myapp.service.error');
      rethrow;
    }
  }

  Future<List<Place>> getPlaces() async {
    final url =
        '$_baseUrl/places?type=adm1&country=ES&limit=50&api_key=$_apiKey';
    final response = await _get(url);
    if (response.statusCode == 200) {
      return _parseList(response.body, 'places', Place.fromJson);
    } else {
      throw ApiException('Failed to load places');
    }
  }

   Future<Stop> getStopById(String stopId) async {
    // This method is now necessary for the screen to get the stop details
    if (stopId.startsWith(_mallorcaPrefix)) {

      // Since we don't have a direct way to get a single stop from the mallorca library,
      // we might need to iterate or find a workaround. For now, let's assume we can get it.
      // THIS IS A SIMPLIFICATION and might need a better implementation.
      final allRoutes = await getRoutes(_mallorcaAgencyIds.first);
      for (var route in allRoutes) {
        final stops = await getStops(route.id);
        final foundStop = stops.firstWhere((s) => s.id == stopId, orElse: () => Stop(id: '', name: ''));
        if (foundStop.id.isNotEmpty) {
          return foundStop;
        }
      }
       throw ApiException('Mallorca stop not found.');
    }

    final url = '$_baseUrl/stops/$stopId?api_key=$_apiKey';
    final response = await _get(url);

    if (response.statusCode == 200) {
      return Stop.fromJson(json.decode(response.body));
    } else {
      throw ApiException('Failed to load stop details');
    }
  }
}
