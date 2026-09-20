import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:newmovie/models/movie_model.dart';
import 'package:newmovie/providers/movie_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

Movie _movie(int id) =>
    Movie(id: id, title: 'Film $id', overview: 'Overview', voteAverage: 8);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('watchlist restores items after a notifier restart', () async {
    final first = WatchlistNotifier();
    await first.ready;
    first.addMovie(_movie(1));
    await Future<void>.delayed(Duration.zero);
    first.dispose();

    final restored = WatchlistNotifier();
    await restored.ready;
    expect(restored.state.single.title, 'Film 1');
    restored.dispose();
  });

  test('watchlist ignores malformed and duplicate saved movies', () async {
    final valid = _movie(1).toJson();
    SharedPreferences.setMockInitialValues({
      WatchlistNotifier.storageKey: jsonEncode([
        valid,
        valid,
        {'id': 'bad'},
      ]),
    });
    final notifier = WatchlistNotifier();
    await notifier.ready;
    expect(notifier.state, hasLength(1));
    notifier.dispose();
  });
}
