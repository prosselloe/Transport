import 'package:flutter/material.dart';
import 'package:myapp/models/agency.dart';
import 'package:myapp/models/stop.dart';
import 'package:myapp/services/transit_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesProvider with ChangeNotifier {
  final TransitService _transitService = TransitService();

  List<String> _favoriteAgencyIds = [];
  List<Agency> _favoriteAgencies = [];
  List<Stop> _favoriteStops = [];
  bool _isLoading = false;

  List<String> get favoriteAgencyIds => _favoriteAgencyIds;
  List<Agency> get favoriteAgencies => _favoriteAgencies;
  List<Stop> get favoriteStops => _favoriteStops;
  bool get isLoading => _isLoading;

  FavoritesProvider() {
    loadFavorites();
  }

  Future<void> loadFavorites() async {
    _setLoading(true);
    final prefs = await SharedPreferences.getInstance();
    _favoriteAgencyIds = prefs.getStringList('favoriteAgencies') ?? [];
    if (_favoriteAgencyIds.isNotEmpty) {
      try {
        _favoriteAgencies = await _transitService.getAgenciesByIds(
          _favoriteAgencyIds,
        );
        _favoriteStops = await _transitService.getStopsForAgencies(
          _favoriteAgencyIds,
        );
      } catch (e) {
        _favoriteAgencies = [];
        _favoriteStops = [];
      }
    } else {
      _favoriteAgencies = [];
      _favoriteStops = [];
    }
    _setLoading(false);
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  Future<void> toggleAgencyFavorite(String agencyId) async {
    final prefs = await SharedPreferences.getInstance();

    if (_favoriteAgencyIds.contains(agencyId)) {
      _favoriteAgencyIds.remove(agencyId);
    } else {
      _favoriteAgencyIds.add(agencyId);
    }

    await prefs.setStringList('favoriteAgencies', _favoriteAgencyIds);
    await loadFavorites();
  }

  bool isFavoriteAgency(String agencyId) {
    return _favoriteAgencyIds.contains(agencyId);
  }
}
