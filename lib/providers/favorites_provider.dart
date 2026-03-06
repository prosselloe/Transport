import 'package:flutter/material.dart';
import 'package:myapp/models/agency.dart';
import 'package:myapp/services/transit_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesProvider with ChangeNotifier {
  final TransitService _transitService = TransitService();

  List<String> _favoriteAgencyIds = [];
  List<Agency> _favoriteAgencies = [];
  bool _isLoading = false;

  List<String> get favoriteAgencyIds => _favoriteAgencyIds;
  List<Agency> get favoriteAgencies => _favoriteAgencies;
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
      } catch (e) {
        _favoriteAgencies = []; // Clear list on error
      }
    } else {
      _favoriteAgencies = []; // Ensure list is cleared if no favorites
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
    
    // Always reload to ensure the list is consistent
    await loadFavorites();
  }

  bool isFavoriteAgency(String agencyId) {
    return _favoriteAgencyIds.contains(agencyId);
  }
}
