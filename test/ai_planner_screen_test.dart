import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newmovie/screens/ai_planner_screen.dart';

void main() {
  testWidgets('planner validates choices and presents a fitting movie', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MaterialApp(home: AIPlannerScreen()));

    await tester.ensureVisible(find.text('Find my perfect fit'));
    await tester.tap(find.text('Find my perfect fit'));
    await tester.pump();
    expect(find.text('Choose at least 45 minutes.'), findsOneWidget);

    await tester.ensureVisible(find.text('90 min'));
    await tester.tap(find.text('90 min'));
    await tester.tap(find.text('Comedy'));
    await tester.ensureVisible(find.text('Find my perfect fit'));
    await tester.tap(find.text('Find my perfect fit'));
    await tester.pumpAndSettle();

    expect(find.text('YOUR CURATED PICK'), findsOneWidget);
    expect(find.text('Palm Springs'), findsOneWidget);
    expect(find.text('90 MIN'), findsOneWidget);

    await tester.ensureVisible(find.text('Refresh pick'));
    await tester.tap(find.text('Refresh pick'));
    await tester.pumpAndSettle();
    expect(find.text('Game Night'), findsOneWidget);
  });

  testWidgets('planner accepts a personalised minute value', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MaterialApp(home: AIPlannerScreen()));

    await tester.enterText(find.byType(TextField), '125');
    await tester.tap(find.text('Action'));
    await tester.ensureVisible(find.text('Find my perfect fit'));
    await tester.tap(find.text('Find my perfect fit'));
    await tester.pumpAndSettle();

    expect(find.text('Mad Max: Fury Road'), findsOneWidget);
    expect(find.text('120 MIN'), findsOneWidget);
  });
}
