import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:myapp/models/agency.dart';
import 'package:myapp/models/api_exception.dart';
import 'package:myapp/models/route.dart';
import 'package:myapp/models/stop.dart';

class TransitService {
  final String _baseUrl = 'https://transit.land/api/v2/rest';
  final String _apiKey = 'UiMWbgxH7E1mmKUJZ6AApHyjVv0GQdYo';

  List<T> _parseList<T>(
    String responseBody,
    String key,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final List<T> results = [];
    try {
      final data = json.decode(responseBody);
      if (data.containsKey(key) && data[key] is List) {
        final items = data[key] as List;
        for (final item in items) {
          try {
            if (item is Map<String, dynamic>) {
              results.add(fromJson(item));
            }
          } catch (e, s) {
            developer.log(
              'Skipping an item for key $key due to a parsing error.',
              name: 'myapp.service.parser',
              error: e,
              stackTrace: s,
            );
          }
        }
      }
    } catch (e, s) {
      developer.log(
        'Failed to decode or parse the main response for key $key.',
        name: 'myapp.service.parser',
        error: e,
        stackTrace: s,
      );
    }
    return results;
  }

  Future<List<Agency>> searchAgencies(String query) async {
    final url = Uri.parse('$_baseUrl/agencies/?search=$query&api_key=$_apiKey');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return _parseList(response.body, 'agencies', Agency.fromJson);
      } else {
        throw ApiException(
          'Failed to search agencies. Status: ${response.statusCode}',
        );
      }
    } on SocketException {
      throw ApiException('No internet connection.');
    } catch (e) {
      developer.log('Error in searchAgencies: $e', name: 'myapp.service.error');
      throw ApiException('An unexpected error occurred during agency search.');
    }
  }

  Future<List<Agency>> getAgencies({String? placeOnestopId}) async {
    String urlStr =
        '$_baseUrl/agencies/?adm1_name=Baleares&limit=100&api_key=$_apiKey';
    if (placeOnestopId != null) {
      urlStr =
          '$_baseUrl/agencies/?place_onestop_id=$placeOnestopId&limit=100&api_key=$_apiKey';
    }

    final url = Uri.parse(urlStr);
    try {
      final response = await http.get(url);
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
      developer.log(
        'Fatal error in getAgencies: $e',
        name: 'myapp.service.error',
      );
      throw ApiException(
        'An unexpected error occurred while fetching agencies.',
      );
    }
  }

  Future<List<Agency>> getAgenciesByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    final onestopIds = ids.join(',');
    final url = Uri.parse(
      '$_baseUrl/agencies/?onestop_id=$onestopIds&include=geometry&api_key=$_apiKey',
    );
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final agencies = (data['agencies'] as List)
            .map((agencyJson) {
              final newJson = Map<String, dynamic>.from(agencyJson);
              if (data.containsKey('meta') &&
                  data['meta'].containsKey('included') &&
                  data['meta']['included'].containsKey('geometries')) {
                final geometriesMap =
                    data['meta']['included']['geometries'] as Map<String, dynamic>;
                if (newJson.containsKey('represented_in_geometries') &&
                    (newJson['represented_in_geometries'] as List).isNotEmpty) {
                  final geometryId =
                      (newJson['represented_in_geometries'] as List).first as String;
                  if (geometriesMap.containsKey(geometryId)) {
                    newJson['geometry'] = geometriesMap[geometryId];
                  }
                }
              }
              return Agency.fromJson(newJson);
            })
            .toList();
        return agencies;
      } else {
        throw ApiException(
          'Failed to load agencies by IDs. Status: ${response.statusCode}',
        );
      }
    } on SocketException {
      throw ApiException('No internet connection.');
    } catch (e) {
      developer.log(
        'Error in getAgenciesByIds: $e',
        name: 'myapp.service.error',
      );
      throw ApiException(
        'An unexpected error occurred while fetching agencies by ID.',
      );
    }
  }

  Future<List<TransitRoute>> getRoutes(String agencyId) async {
    final url = Uri.parse(
      '$_baseUrl/routes/?operator_onestop_id=$agencyId&api_key=$_apiKey',
    );
    try {
      final response = await http.get(url);
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
      throw ApiException('An unexpected error occurred while fetching routes.');
    }
  }

  Future<TransitRoute> getRouteDetails(String routeId) async {
    final url = Uri.parse(
      '$_baseUrl/routes?onestop_id=$routeId&api_key=$_apiKey', // Removed include=geometry
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] is List && (data['routes'] as List).isNotEmpty) {
          final routeJson = Map<String, dynamic>.from((data['routes'] as List).first);
          return TransitRoute.fromJson(routeJson);
        } else {
          throw ApiException('Route with ID $routeId not found.');
        }
      } else {
        throw ApiException(
          'Failed to load route details. Status: ${response.statusCode}',
        );
      }
    } on SocketException {
      throw ApiException('No internet connection.');
    } catch (e) {
      developer.log(
        'Error in getRouteDetails: $e',
        name: 'myapp.service.error',
      );
      throw ApiException(
        'An unexpected error occurred while fetching route details.',
      );
    }
  }

  Future<List<Stop>> getStops(String routeId) async {
    final url = Uri.parse(
      '$_baseUrl/stops/?served_by_onestop_ids=$routeId&limit=500&api_key=$_apiKey', // Added limit
    );
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return _parseList(response.body, 'stops', Stop.fromJson);
      } else {
        throw ApiException(
          'Failed to load stops. Status: ${response.statusCode}',
        );
      }
    } on SocketException {
      throw ApiException('No internet connection.');
    } catch (e) {
      developer.log('Error in getStops: $e', name: 'myapp.service.error');
      throw ApiException('An unexpected error occurred while fetching stops.');
    }
  }
}
