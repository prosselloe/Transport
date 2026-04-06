import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:transport/models/agency.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:transport/models/stop.dart';
import 'package:transport/services/transit_service.dart';

class FavoritesProvider with ChangeNotifier {
  static const _favoritesKey = 'favoriteAgencies';

  final TransitService _transitService = TransitService();
  List<Agency> _favoriteAgencies = [];
  final Map<String, List<Stop>> _stopsByAgency = {};
  bool _isLoading = true;

  List<Agency> get favoriteAgencies => _favoriteAgencies;
  Map<String, List<Stop>> get stopsByAgency => _stopsByAgency;
  bool get isLoading => _isLoading;

  FavoritesProvider() {
    loadFavorites();
  }

  Future<void> loadFavorites() async {
    _isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final favoriteStrings = prefs.getStringList(_favoritesKey) ?? [];

    _favoriteAgencies = favoriteStrings.map((favString) {
      final jsonMap = json.decode(favString) as Map<String, dynamic>;
      return Agency.fromJsonForFavorites(jsonMap);
    }).toList();

    await _loadStopsForFavorites();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadStopsForFavorites() async {
    for (final agency in _favoriteAgencies) {
      final stops = await _transitService.getStopsForAgencies([agency.id]);
      _stopsByAgency[agency.id] = stops;
    }
  }

  Future<void> toggleAgencyFavorite(Agency agency) async {
    final isCurrentlyFavorite = isFavoriteAgency(agency.id);

    if (isCurrentlyFavorite) {
      _favoriteAgencies.removeWhere((a) => a.id == agency.id);
      _stopsByAgency.remove(agency.id);
    } else {
      _favoriteAgencies.add(agency);
      final stops = await _transitService.getStopsForAgencies([agency.id]);
      _stopsByAgency[agency.id] = stops;
    }
    
    await _saveFavorites();
    notifyListeners();
  }

  Future<void> _saveFavorites() async {
     final prefs = await SharedPreferences.getInstance();
     final favoriteStrings = _favoriteAgencies.map((agency) {
       return json.encode(agency.toJson());
     }).toList();
     await prefs.setStringList(_favoritesKey, favoriteStrings);
  }

  bool isFavoriteAgency(String agencyId) {
    return _favoriteAgencies.any((agency) => agency.id == agencyId);
  }
}
