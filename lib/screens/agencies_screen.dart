import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:transport/models/agency.dart';
import 'package:transport/providers/favorites_provider.dart';
import 'package:transport/services/transit_service.dart';
import 'package:provider/provider.dart';
import 'package:transport/widgets/app_bar.dart';

class AgenciesScreen extends StatefulWidget {
  const AgenciesScreen({super.key});

  @override
  State<AgenciesScreen> createState() => _AgenciesScreenState();
}

class _AgenciesScreenState extends State<AgenciesScreen> {
  final TransitService _transitService = TransitService();
  Future<List<Agency>>? _agenciesFuture;

  @override
  void initState() {
    super.initState();
    // Load initial agencies (e.g., from a default location)
    _agenciesFuture = _transitService.getAgencies();
  }

  void _searchAgencies(String query) {
    final future = query.isEmpty
        ? _transitService.getAgencies() // Reset to default if query is empty
        : _transitService.searchAgencies(query);
    setState(() {
      _agenciesFuture = future;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Use a Consumer to get the latest state of favorites
    final favoritesProvider = Provider.of<FavoritesProvider>(context);

    return Scaffold(
      appBar: const CustomAppBar(title: 'Browse Transit Agencies'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: _searchAgencies,
              decoration: const InputDecoration(
                labelText: 'Search (e.g., Mallorca, EMT)',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(25.0)),
                ),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Agency>>(
              future: _agenciesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final agencies = snapshot.data ?? [];

                if (agencies.isEmpty) {
                  return const Center(child: Text('No agencies found.'));
                }

                return ListView.builder(
                  itemCount: agencies.length,
                  itemBuilder: (context, index) {
                    final agency = agencies[index];
                    final isFavorite = favoritesProvider.isFavoriteAgency(agency.id);

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      elevation: 2,
                      child: ListTile(
                        title: Text(agency.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(agency.id, style: const TextStyle(color: Colors.grey)),
                        trailing: IconButton(
                          icon: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: isFavorite ? Colors.red : Colors.grey,
                            size: 28,
                          ),
                          tooltip: isFavorite ? 'Remove from Favorites' : 'Add to Favorites',
                          onPressed: () {
                            favoritesProvider.toggleAgencyFavorite(agency); // Pass the whole object
                             ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isFavorite
                                  ? 'Removed ${agency.name} from favorites'
                                  : 'Added ${agency.name} to favorites',
                                ),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                        onTap: () {
                           // Use the robust ID-based route
                           context.go('/agency/${agency.id}');
                        },
                      ),
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
