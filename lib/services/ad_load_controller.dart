import 'dart:async';

/// Owns one cached ad and one bounded request, including initialization/retries.
/// Callback generations keep late platform responses from reviving cancelled ads.
class AdLoadController<T extends Object> {
  AdLoadController({
    required this.initialize,
    required this.request,
    required this.disposeAd,
    required this.isPermanentError,
    this.onError,
    this.loadTimeout = const Duration(seconds: 15),
    this.cooldown = const Duration(seconds: 45),
    this.maxAttempts = 3,
  });

  final Future<void> Function() initialize;
  final Future<void> Function(
    void Function(T) loaded,
    void Function(Object) failed,
    void Function(T) trackPending,
  ) request;
  final Future<void> Function(T) disposeAd;
  final bool Function(Object) isPermanentError;
  final void Function(Object)? onError;
  final Duration loadTimeout;
  final Duration cooldown;
  final int maxAttempts;

  T? _ad;
  T? _pendingAd;
  DateTime? loadedAt;
  Completer<bool>? _completion;
  Timer? _deadline;
  Timer? _retry;
  int _generation = 0;
  int _attemptToken = 0;
  int _attempts = 0;

  T? get ad => _ad;

  Future<bool> load() {
    if (_ad != null) return Future.value(true);
    final pending = _completion;
    if (pending != null) return pending.future;
    _retry?.cancel();
    final completion = Completer<bool>();
    _completion = completion;
    _attempts = 0;
    final generation = ++_generation;
    _deadline = Timer(loadTimeout, () {
      onError?.call(TimeoutException('Ad request timed out.', loadTimeout));
      _finish(false, retryLater: true);
    });
    unawaited(_attempt(generation));
    return completion.future;
  }

  bool _isCurrent(int generation, int token) =>
      generation == _generation &&
      token == _attemptToken &&
      _completion != null;

  Future<void> _attempt(int generation) async {
    if (generation != _generation || _completion == null) return;
    final token = ++_attemptToken;
    _attempts++;
    T? acceptedAd;
    void loaded(T ad) {
      // A duplicated SDK success must not dispose the ad already handed out.
      if (identical(ad, acceptedAd)) return;
      if (!_isCurrent(generation, token)) {
        _discard(ad);
        return;
      }
      acceptedAd = ad;
      if (!identical(ad, _pendingAd)) _clearPending();
      _pendingAd = null;
      _ad = ad;
      loadedAt = DateTime.now();
      _finish(true);
    }

    void failed(Object error) {
      if (!_isCurrent(generation, token)) return;
      ++_attemptToken;
      _clearPending();
      onError?.call(error);
      final permanent = isPermanentError(error);
      if (permanent || _attempts >= maxAttempts) {
        _finish(false, retryLater: !permanent);
        return;
      }
      _retry = Timer(Duration(seconds: 2 << (_attempts - 1)), () {
        unawaited(_attempt(generation));
      });
    }

    try {
      await initialize();
      if (!_isCurrent(generation, token)) return;
      await request(loaded, failed, (ad) {
        if (!_isCurrent(generation, token)) {
          _discard(ad);
          return;
        }
        _pendingAd = ad;
      });
    } catch (error) {
      failed(error);
    }
  }

  void _finish(bool success, {bool retryLater = false}) {
    _deadline?.cancel();
    _retry?.cancel();
    final generation = ++_generation;
    final completion = _completion;
    _completion = null;
    if (!success) _clearPending();
    if (completion != null && !completion.isCompleted) {
      completion.complete(success);
    }
    if (retryLater) {
      _retry = Timer(cooldown, () {
        if (generation == _generation) unawaited(load());
      });
    }
  }

  T? take() {
    final result = _ad;
    _ad = null;
    loadedAt = null;
    return result;
  }

  void _discard(T ad) {
    unawaited(Future<void>.sync(() => disposeAd(ad)).catchError((Object error) {
      onError?.call(error);
    }));
  }

  void _clearPending() {
    final pending = _pendingAd;
    _pendingAd = null;
    if (pending != null) _discard(pending);
  }

  /// Cancels this generation; a later explicit load may safely reuse the owner.
  void dispose() {
    _finish(false);
    final ad = take();
    if (ad != null) _discard(ad);
  }
}
