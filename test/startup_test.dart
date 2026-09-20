import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newmovie/screens/splash_screen.dart';
import 'package:newmovie/services/app_data_loader.dart';

class _Loader extends Fake implements AppDataLoader {
  bool failFirst = false;
  Completer<void>? gate;
  int calls = 0;
  int listenerAdds = 0;
  final listeners = <void Function()>[];

  @override
  bool isReady = false;
  @override
  bool hasError = false;
  @override
  String? get errorMessage => hasError ? 'Connection issue' : null;

  @override
  void addListener(void Function() listener) {
    listenerAdds++;
    listeners.add(listener);
  }

  @override
  void removeListener(void Function() listener) => listeners.remove(listener);

  @override
  Future<void> loadAppData({bool forceRefresh = false}) async {
    calls++;
    if (gate != null) await gate!.future;
    hasError = failFirst && calls == 1;
    isReady = !hasError;
    for (final listener in listeners.toList()) {
      listener();
    }
  }
}

void main() {
  testWidgets('splash retry resumes navigation and registers one listener', (
    tester,
  ) async {
    final loader = _Loader()..failFirst = true;
    var adShows = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: SplashScreen(
          dataLoader: loader,
          minimumDisplayDuration: Duration.zero,
          prepareAds: () async {},
          showAppOpenAd: () async {
            adShows++;
          },
          destinationBuilder: (_) => const Scaffold(body: Text('Home ready')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('Home ready'), findsNothing);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Home ready'), findsOneWidget);
    expect(loader.calls, 2);
    expect(loader.listenerAdds, 1);
    expect(adShows, 1);
    expect(loader.listeners, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ad initialization failure does not block entering the app', (
    tester,
  ) async {
    final loader = _Loader();
    await tester.pumpWidget(
      MaterialApp(
        home: SplashScreen(
          dataLoader: loader,
          minimumDisplayDuration: Duration.zero,
          prepareAds: () async {
            throw StateError('SDK unavailable');
          },
          showAppOpenAd: () async {
            throw StateError('Ad unavailable');
          },
          destinationBuilder: (_) => const Scaffold(body: Text('Home ready')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Home ready'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('disposing splash during loading does not navigate or setState', (
    tester,
  ) async {
    final gate = Completer<void>();
    final loader = _Loader()..gate = gate;
    var adShows = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: SplashScreen(
          dataLoader: loader,
          minimumDisplayDuration: Duration.zero,
          prepareAds: () async {},
          showAppOpenAd: () async {
            adShows++;
          },
        ),
      ),
    );
    await tester.pumpWidget(const SizedBox());
    gate.complete();
    await tester.pump();
    expect(adShows, 0);
    expect(loader.listeners, isEmpty);
    expect(tester.takeException(), isNull);
  });
}
