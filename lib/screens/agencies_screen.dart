import 'package:flutter/material.dart';
import 'package:myapp/models/agency.dart';
import 'package:myapp/providers/favorites_provider.dart';
import 'package:myapp/services/transit_service.dart';
import 'package:provider/provider.dart';

class AgenciesScreen extends StatefulWidget {
  const AgenciesScreen({super.key});

  @override
  State<AgenciesScreen> createState() => _AgenciesScreenState();
}

class _AgenciesScreenState extends State<AgenciesScreen> {
  final TransitService _transitService = TransitService();
  List<Agency> _agencies = [];
  bool _isLoading = false;

  void _searchAgencies(String query) async {
    if (query.isEmpty) {
      if (mounted) {
        setState(() {
          _agencies = [];
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
      final agencies = await _transitService.searchAgencies(query);
      if (mounted) {
        setState(() {
          _agencies = agencies;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error searching agencies: $e')));
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
      appBar: AppBar(title: const Text('Browse Agencies')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: _searchAgencies,
              decoration: InputDecoration(
                labelText: 'Search for an agency',
                suffixIcon: _isLoading
                    ? const CircularProgressIndicator()
                    : null,
              ),
            ),
          ),
          Expanded(
            child: Consumer<FavoritesProvider>(
              builder: (context, favoritesProvider, child) {
                return ListView.builder(
                  itemCount: _agencies.length,
                  itemBuilder: (context, index) {
                    final agency = _agencies[index];
                    final isFavorite = favoritesProvider.isFavoriteAgency(
                      agency.id,
                    );
                    return ListTile(
                      title: Text(agency.name),
                      subtitle: Text(agency.id),
                      trailing: IconButton(
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? Colors.red : null,
                        ),
                        onPressed: () {
                          favoritesProvider.toggleAgencyFavorite(agency.id);
                        },
                      ),
                      onTap: () {
                        Navigator.pop(context, agency.id);
                      },
                    );
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
