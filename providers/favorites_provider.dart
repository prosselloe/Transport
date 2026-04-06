import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:transport/models/agency.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesProvider with ChangeNotifier {
  static const _favoritesKey = 'favoriteAgencies';

  List<Agency> _favoriteAgencies = [];
  bool _isLoading = true;

  List<Agency> get favoriteAgencies => _favoriteAgencies;
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

    _isLoading = false;
    notifyListeners();
  }

  Future<void> toggleAgencyFavorite(Agency agency) async {
    final isCurrentlyFavorite = isFavoriteAgency(agency.id);

    if (isCurrentlyFavorite) {
      _favoriteAgencies.removeWhere((a) => a.id == agency.id);
    } else {
      _favoriteAgencies.add(agency);
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
