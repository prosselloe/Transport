import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/main.dart';
import 'package:myapp/providers/favorites_provider.dart';
import 'package:myapp/theme_provider.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('Renders AgencyListScreen with title after loading', (
    WidgetTester tester,
  ) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => ThemeProvider()),
          ChangeNotifierProvider(create: (context) => FavoritesProvider()),
        ],
        child: const MyApp(),
      ),
    );

    // At first, a loading indicator should be visible while agencies are being fetched.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Settle the frame after the futures have completed.
    await tester.pumpAndSettle();

    // After loading, the title should be visible and the indicator should be gone.
    expect(find.text('Transit Agencies'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
