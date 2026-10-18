// This is a basic Flutter widget test.
//
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pickdrop/main.dart';

void main() {
  testWidgets('App starts without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: PickDropApp()));
    await tester.pumpAndSettle();
    // Verify the app starts and shows the splash screen
    expect(find.text('PickDrop'), findsOneWidget);
  });
}