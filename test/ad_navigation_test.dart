import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newmovie/services/ad_navigation_service.dart';

void main() {
  testWidgets('repeated taps open only one page', (tester) async {
    var routesBuilt = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () {
              for (var i = 0; i < 2; i++) {
                AdNavigationService.pushAfterInterstitial(context, () {
                  routesBuilt++;
                  return MaterialPageRoute<void>(
                    builder: (_) => const Scaffold(body: Text('Destination')),
                  );
                });
              }
            },
            child: const Text('Open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(routesBuilt, 1);
    expect(find.text('Destination'), findsOneWidget);
  });

  testWidgets('navigation action skips an unmounted page', (tester) async {
    late BuildContext pageContext;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            pageContext = context;
            return const SizedBox();
          },
        ),
      ),
    );
    await tester.pumpWidget(const SizedBox());
    var actions = 0;
    await AdNavigationService.runAfterInterstitial(
      pageContext,
      () => actions++,
    );
    expect(actions, 0);
  });
}
