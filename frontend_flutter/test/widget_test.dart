import 'package:flutter_test/flutter_test.dart';

import 'package:frontend_flutter/main.dart';

void main() {
  testWidgets('La page de connexion SOCADEL Géoloc s\'affiche', (WidgetTester tester) async {
    await tester.pumpWidget(const SocadelGeolocApp());

    expect(find.text('SOCADEL Géoloc'), findsOneWidget);
    expect(find.text('Se connecter'), findsOneWidget);
  });
}
