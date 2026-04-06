import 'package:flutter/material.dart';
import 'package:transport/widgets/app_bar.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      // Handle the error here
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Sobre l\'aplicació'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(context, 'Visió General'),
            const SizedBox(height: 8),
            _buildBodyText(
              'Aquesta és una aplicació Flutter dissenyada per consultar i mostrar informació del transport públic. '
              'L\'aplicació ofereix una interfície neta, moderna i fàcil d\'usar perquè els usuaris explorin agències, '
              'rutes i parades de transport, amb un enfocament especial en les dades de les Illes Balears.',
            ),
            const SizedBox(height: 24),
            _buildSectionTitle(context, 'Característiques'),
            const SizedBox(height: 8),
            _buildFeature('Consultar Agències de Transport'),
            _buildFeature('Cerca d\'Agències en Temps Real'),
            _buildFeature('Sistema de Favorits'),
            _buildFeature('Detalls de l\'Agència'),
            _buildFeature('Llistat de Rutes'),
            _buildFeature('Detalls de la Ruta i Vista del Mapa'),
            _buildFeature('Visualització de Parades'),
            const SizedBox(height: 24),
            _buildSectionTitle(context, 'Crèdits'),
            const SizedBox(height: 16),
            _buildCreditItem(
              'Transit.land (API v2)',
              'Una plataforma de dades obertes per al transport públic.',
              'https://www.transit.land/documentation/rest-api/',
            ),
            const SizedBox(height: 16),
            _buildCreditItem(
              'Mallorca Transport Services API',
              'Un paquet de Dart per accedir a les dades del transport públic de Mallorca.',
              'https://github.com/open-transport-mallorca/mallorca_transit_services',
            ),
            const SizedBox(height: 16),
            _buildCreditItem(
              'Firebase i Gemini',
              'El backend, l\'allotjament i les eines d\'IA generativa han estat proporcionades per Google.',
              'https://firebase.google.com/',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildBodyText(String text) {
    return Text(
      text,
      textAlign: TextAlign.justify,
      style: const TextStyle(fontSize: 16, height: 1.5),
    );
  }

    Widget _buildFeature(String feature) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline, size: 20, color: Colors.green),
          const SizedBox(width: 12),
          Expanded(child: Text(feature, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }

  Widget _buildCreditItem(String title, String description, String url) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(description),
        ),
        trailing: const Icon(Icons.open_in_new),
        onTap: () => _launchURL(url),
      ),
    );
  }
}
