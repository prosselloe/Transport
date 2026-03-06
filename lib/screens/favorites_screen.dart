import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/providers/favorites_provider.dart';
import 'package:provider/provider.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {

  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to ensure the provider is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Use listen: false to avoid unnecessary rebuilds in initState
      Provider.of<FavoritesProvider>(context, listen: false).loadFavorites();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Use a Consumer to listen to changes in the provider
    return Consumer<FavoritesProvider>(
      builder: (context, favoritesProvider, child) {
        return Scaffold(
          appBar: AppBar(title: const Text('Favorite Agencies')),
          body: _buildBody(context, favoritesProvider),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, FavoritesProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.favoriteAgencies.isEmpty) {
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

    return ListView.builder(
      itemCount: provider.favoriteAgencies.length,
      itemBuilder: (context, index) {
        final agency = provider.favoriteAgencies[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
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
                provider.toggleAgencyFavorite(agency.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Removed ${agency.name} from favorites'),
                  ),
                );
              },
            ),
            onTap: () {
              context.go('/agency_details', extra: agency);
            },
          ),
        );
      },
    );
  }
}
