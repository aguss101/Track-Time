import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:track_time/main.dart';

void main() {
  testWidgets('La app arranca y muestra el splash', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: TrackTimeApp()));
    // El splash se renderiza sin lanzar excepciones.
    expect(find.byType(TrackTimeApp), findsOneWidget);
  });
}
