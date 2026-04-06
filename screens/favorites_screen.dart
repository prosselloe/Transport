import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:transport/models/agency.dart';
import 'package:transport/providers/favorites_provider.dart';
import 'package:provider/provider.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Favorite Agencies')),
      body: Consumer<FavoritesProvider>(
        builder: (context, favoritesProvider, child) {
          if (favoritesProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final favoriteAgencies = favoritesProvider.favoriteAgencies;

          if (favoriteAgencies.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 80, color: Colors.grey),
                  SizedBox(height: 20),
                  Text(
                    'No Favorites Yet',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Tap the heart icon on any agency to add it here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return _buildAgencyList(context, favoritesProvider, favoriteAgencies);
        },
      ),
    );
  }

  Widget _buildAgencyList(
    BuildContext context,
    FavoritesProvider provider,
    List<Agency> agencies,
  ) {
    return ListView.builder(
      itemCount: agencies.length,
      itemBuilder: (context, index) {
        final agency = agencies[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: ListTile(
            title: Text(
              agency.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(agency.id),
            trailing: IconButton(
              icon: const Icon(Icons.favorite, color: Colors.red),
              tooltip: 'Remove from Favorites',
              onPressed: () {
                // Pass the whole agency object to the provider
                provider.toggleAgencyFavorite(agency);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Removed ${agency.name} from favorites'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
            onTap: () {
              // Navigate using the robust ID-based route
              context.go('/agency/${agency.id}');
            },
          ),
        );
      },
    );
  }
}
