import 'package:character_lens/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app launches to a blank scaffold', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: CharacterLensApp()));

    expect(find.byType(Scaffold), findsOneWidget);
  });
}
