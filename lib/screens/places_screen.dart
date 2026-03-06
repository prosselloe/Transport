import 'package:flutter/material.dart';
import 'package:myapp/models/place.dart';
import 'package:myapp/services/transit_service.dart';

class PlacesScreen extends StatefulWidget {
  const PlacesScreen({super.key});

  @override
  State<PlacesScreen> createState() => _PlacesScreenState();
}

class _PlacesScreenState extends State<PlacesScreen> {
  final TransitService _transitService = TransitService();
  List<Place> _places = [];
  bool _isLoading = false;

  void _searchPlaces(String query) async {
    if (query.isEmpty) {
      if (mounted) {
        setState(() {
          _places = [];
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final places = await _transitService.searchPlaces(query);
      if (mounted) {
        setState(() {
          _places = places;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error searching places: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Browse Places'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: _searchPlaces,
              decoration: InputDecoration(
                labelText: 'Search for a place',
                suffixIcon: _isLoading ? const CircularProgressIndicator() : null,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _places.length,
              itemBuilder: (context, index) {
                final place = _places[index];
                return ListTile(
                  title: Text(place.name),
                  onTap: () {
                    Navigator.pop(context, place.onestopId);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
