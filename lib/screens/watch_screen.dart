import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

// ──────────────────────────────────────────────────────────────────────────────
// Embed providers — ordered by quality / ad-free experience
// ──────────────────────────────────────────────────────────────────────────────
class _EmbedProvider {
  final String name;
  final String Function(int tmdbId, {int? season, int? episode, bool isTvShow})
  buildUrl;

  const _EmbedProvider({required this.name, required this.buildUrl});
}

class _SubtitleLanguage {
  final String code;
  final String name;
  final String nativeName;

  const _SubtitleLanguage({
    required this.code,
    required this.name,
    required this.nativeName,
  });
}

const _subtitleOff = _SubtitleLanguage(
  code: '',
  name: 'Off',
  nativeName: 'No subtitles',
);

// A broad, searchable catalog. A language becomes active only when the
// current source supplies a matching native subtitle/caption track.
const List<_SubtitleLanguage> _subtitleLanguages = [
  _SubtitleLanguage(code: 'ar', name: 'Arabic', nativeName: 'العربية'),
  _SubtitleLanguage(code: 'bn', name: 'Bengali', nativeName: 'বাংলা'),
  _SubtitleLanguage(code: 'bg', name: 'Bulgarian', nativeName: 'Български'),
  _SubtitleLanguage(code: 'zh', name: 'Chinese', nativeName: '中文'),
  _SubtitleLanguage(code: 'hr', name: 'Croatian', nativeName: 'Hrvatski'),
  _SubtitleLanguage(code: 'cs', name: 'Czech', nativeName: 'Čeština'),
  _SubtitleLanguage(code: 'da', name: 'Danish', nativeName: 'Dansk'),
  _SubtitleLanguage(code: 'nl', name: 'Dutch', nativeName: 'Nederlands'),
  _SubtitleLanguage(code: 'en', name: 'English', nativeName: 'English'),
  _SubtitleLanguage(code: 'fi', name: 'Finnish', nativeName: 'Suomi'),
  _SubtitleLanguage(code: 'fr', name: 'French', nativeName: 'Français'),
  _SubtitleLanguage(code: 'de', name: 'German', nativeName: 'Deutsch'),
  _SubtitleLanguage(code: 'el', name: 'Greek', nativeName: 'Ελληνικά'),
  _SubtitleLanguage(code: 'he', name: 'Hebrew', nativeName: 'עברית'),
  _SubtitleLanguage(code: 'hi', name: 'Hindi', nativeName: 'हिन्दी'),
  _SubtitleLanguage(code: 'hu', name: 'Hungarian', nativeName: 'Magyar'),
  _SubtitleLanguage(
    code: 'id',
    name: 'Indonesian',
    nativeName: 'Bahasa Indonesia',
  ),
  _SubtitleLanguage(code: 'it', name: 'Italian', nativeName: 'Italiano'),
  _SubtitleLanguage(code: 'ja', name: 'Japanese', nativeName: '日本語'),
  _SubtitleLanguage(code: 'ko', name: 'Korean', nativeName: '한국어'),
  _SubtitleLanguage(code: 'ms', name: 'Malay', nativeName: 'Bahasa Melayu'),
  _SubtitleLanguage(code: 'ml', name: 'Malayalam', nativeName: 'മലയാളം'),
  _SubtitleLanguage(code: 'mr', name: 'Marathi', nativeName: 'मराठी'),
  _SubtitleLanguage(code: 'no', name: 'Norwegian', nativeName: 'Norsk'),
  _SubtitleLanguage(code: 'fa', name: 'Persian', nativeName: 'فارسی'),
  _SubtitleLanguage(code: 'pl', name: 'Polish', nativeName: 'Polski'),
  _SubtitleLanguage(code: 'pt', name: 'Portuguese', nativeName: 'Português'),
  _SubtitleLanguage(
    code: 'pt-BR',
    name: 'Portuguese (Brazil)',
    nativeName: 'Português (Brasil)',
  ),
  _SubtitleLanguage(code: 'ro', name: 'Romanian', nativeName: 'Română'),
  _SubtitleLanguage(code: 'ru', name: 'Russian', nativeName: 'Русский'),
  _SubtitleLanguage(code: 'sr', name: 'Serbian', nativeName: 'Српски'),
  _SubtitleLanguage(code: 'sk', name: 'Slovak', nativeName: 'Slovenčina'),
  _SubtitleLanguage(code: 'es', name: 'Spanish', nativeName: 'Español'),
  _SubtitleLanguage(code: 'sv', name: 'Swedish', nativeName: 'Svenska'),
  _SubtitleLanguage(code: 'ta', name: 'Tamil', nativeName: 'தமிழ்'),
  _SubtitleLanguage(code: 'te', name: 'Telugu', nativeName: 'తెలుగు'),
  _SubtitleLanguage(code: 'th', name: 'Thai', nativeName: 'ไทย'),
  _SubtitleLanguage(code: 'tr', name: 'Turkish', nativeName: 'Türkçe'),
  _SubtitleLanguage(code: 'uk', name: 'Ukrainian', nativeName: 'Українська'),
  _SubtitleLanguage(code: 'ur', name: 'Urdu', nativeName: 'اردو'),
  _SubtitleLanguage(code: 'vi', name: 'Vietnamese', nativeName: 'Tiếng Việt'),
];

final List<_EmbedProvider> _providers = [
  _EmbedProvider(
    name: 'CineSrc',
    buildUrl: (id, {season, episode, isTvShow = false}) {
      const base = 'https://cinesrc.st/embed';
      if (isTvShow) {
        return '$base/tv/$id?s=${season ?? 1}&e=${episode ?? 1}&autoplay=1';
      }
      return '$base/movie/$id?autoplay=1';
    },
  ),
  _EmbedProvider(
    name: 'VidSrc',
    buildUrl: (id, {season, episode, isTvShow = false}) {
      const base = 'https://vidsrc.sbs/embed';
      if (isTvShow) {
        return '$base/tv/$id/${season ?? 1}/${episode ?? 1}?autoplay=1&color=e50914';
      }
      return '$base/movie/$id?autoplay=1&color=e50914';
    },
  ),
  _EmbedProvider(
    name: 'VidSrc v2',
    buildUrl: (id, {season, episode, isTvShow = false}) {
      const base = 'https://vidsrc.in/embed';
      if (isTvShow) {
        return '$base/tv/$id/${season ?? 1}/${episode ?? 1}';
      }
      return '$base/movie/$id';
    },
  ),
  _EmbedProvider(
    name: '2Embed',
    buildUrl: (id, {season, episode, isTvShow = false}) {
      const base = 'https://www.2embed.cc';
      if (isTvShow) {
        return '$base/embedtv/$id&s=${season ?? 1}&e=${episode ?? 1}';
      }
      return '$base/embed/$id';
    },
  ),
];

// ──────────────────────────────────────────────────────────────────────────────
// Ad / popup domain patterns to block (covers 99 % of known ad networks)
// ──────────────────────────────────────────────────────────────────────────────
const List<String> _blockedDomains = [
  // Generic ad networks
  '.*doubleclick\\.net.*',
  '.*googlesyndication\\.com.*',
  '.*googleadservices\\.com.*',
  '.*adservice\\.google\\..*',
  '.*pagead2\\.googlesyndication\\.com.*',
  '.*amazon-adsystem\\.com.*',
  '.*ads\\.yahoo\\.com.*',
  // Popup / redirect networks
  '.*popads\\.net.*',
  '.*popcash\\.net.*',
  '.*propellerads\\.com.*',
  '.*pushnotifications\\..*',
  '.*onclickads\\.net.*',
  '.*clickadu\\.com.*',
  '.*hilltopads\\.net.*',
  '.*juicyads\\.com.*',
  '.*exoclick\\.com.*',
  '.*trafficjunky\\..*',
  '.*adsterra\\.com.*',
  '.*ad-maven\\.com.*',
  '.*admaven\\.com.*',
  '.*bidgear\\.com.*',
  '.*richads\\.com.*',
  '.*betterads\\..*',
  // Betting / casino popup networks (e.g. Melbet, 1xbet, etc.)
  '.*melbet\\..*',
  '.*1xbet\\..*',
  '.*bet365\\..*',
  '.*mostbet\\..*',
  '.*parimatch\\..*',
  '.*betwinner\\..*',
  '.*1win\\..*',
  '.*linebet\\..*',
  '.*casino\\..*',
  '.*vulkan\\..*',
  '.*pin-up\\..*',
  '.*affiliate.*',
  // Common tracker / fingerprinting
  '.*borrowhourglass\\.com.*',
  '.*whos\\.amung\\.us.*',
  '.*sharethis\\.com.*',
  // Generic catch-alls
  '.*\\.doubleclick\\..*',
  '.*\\.adnxs\\..*',
  '.*\\.taboola\\..*',
  '.*\\.outbrain\\..*',
  '.*\\.revcontent\\..*',
];

// CSS selectors to hide overlay / interstitial ad elements and server droplist
const String _adHidingCss = '''
  /* Hide intrusive ads & popups */
  [class*="ad-"]:not([class*="player"]):not([class*="video"]):not([class*="jw-"]):not([class*="plyr"]):not([class*="art-"]),
  [class*="popup"]:not([class*="player"]):not([class*="video"]):not([class*="jw-"]):not([class*="plyr"]):not([class*="art-"]),
  [id*="ad-"]:not([id*="player"]):not([id*="video"]):not([id*="jw-"]):not([id*="plyr"]):not([id*="art-"]),
  [id*="popup"]:not([id*="player"]):not([id*="video"]):not([id*="jw-"]):not([id*="plyr"]):not([id*="art-"]),
  [class*="banner"], [id*="banner"],
  [class*="interstitial"], [id*="interstitial"],
  iframe[src*="ads"], iframe[src*="pop"],
  div[class*="AdSlot"], div[id*="AdSlot"],

  /* Hide server bar and server droplist */
  .embed-server-bar,
  .srv-dropdown,
  .srv-label,
  .srv-btn,
  .srv-btn-label,
  #srvBtn,
  #srvDropdown,
  #srvBtnLabel,
  .srv-dropdown-list,
  .srv-item,
  [class*="embed-server-bar"],
  [class*="server-bar"],
  [id*="server-bar"] {
    display: none !important;
    visibility: hidden !important;
    opacity: 0 !important;
    pointer-events: none !important;
    height: 0 !important;
    width: 0 !important;
    position: absolute !important;
    top: -9999px !important;
  }
''';

// Keep a landscape video centered in its available viewport. A provider that
// cannot fill the display gets a clean black letterbox instead of being pinned
// to the top or bottom of the page.
const String _playerLayoutCss = '''
  html, body {
    width: 100% !important;
    height: 100% !important;
    min-height: 100% !important;
    margin: 0 !important;
    padding: 0 !important;
    overflow: hidden !important;
    background: #000 !important;
  }

  body {
    display: flex !important;
    align-items: center !important;
    justify-content: center !important;
  }

  body > iframe,
  body > video,
  body > #player,
  body > .player,
  body > .video-player,
  body > .video-container {
    max-width: 100vw !important;
    max-height: 100vh !important;
  }

  body > iframe {
    width: 100vw !important;
    height: 100vh !important;
    border: 0 !important;
  }

  video {
    display: block !important;
    width: 100vw !important;
    height: 100vh !important;
    max-width: 100vw !important;
    max-height: 100vh !important;
    object-fit: contain !important;
    background: #000 !important;
  }

  video::cue {
    color: #fff !important;
    background: rgba(0, 0, 0, .72) !important;
    font-size: 1.05em !important;
  }

  /* Fullscreen intentionally crops only the outer edges when needed so the
     video fills every pixel of the device display. */
  html.player-edge-to-edge,
  html.player-edge-to-edge body {
    position: fixed !important;
    inset: 0 !important;
    width: 100vw !important;
    height: 100vh !important;
    min-height: 100vh !important;
    max-width: none !important;
    max-height: none !important;
    margin: 0 !important;
    padding: 0 !important;
    overflow: hidden !important;
    background: #000 !important;
  }

  html.player-edge-to-edge body > *:not(script):not(style):not(link) {
    position: fixed !important;
    inset: 0 !important;
    width: 100vw !important;
    height: 100vh !important;
    min-width: 100vw !important;
    min-height: 100vh !important;
    max-width: none !important;
    max-height: none !important;
    margin: 0 !important;
    padding: 0 !important;
    transform: none !important;
  }

  html.player-edge-to-edge body > iframe,
  html.player-edge-to-edge body > video,
  html.player-edge-to-edge video {
    width: 100vw !important;
    height: 100vh !important;
    min-width: 100vw !important;
    min-height: 100vh !important;
    max-width: none !important;
    max-height: none !important;
    object-fit: cover !important;
    object-position: center center !important;
    transform: none !important;
  }

''';

// Installed before the provider document executes, so popup attempts cannot
// race the post-load CSS cleanup below.
const String _documentStartAdBlockScript = r'''
  (function() {
    if (window.__playerPopupProtectionInstalled) return;
    window.__playerPopupProtectionInstalled = true;

    var blockPopup = function() { return null; };
    try {
      Object.defineProperty(window, 'open', {
        value: blockPopup,
        writable: false,
        configurable: false,
      });
    } catch (_) {
      try { window.open = blockPopup; } catch (_) {}
    }
  })();
''';

// Run in every embedded frame as well as the provider page. Some providers
// own the video inside a cross-origin iframe, so the page-level fullscreen
// callback alone cannot resize that video's layout.
final String _documentStartPlayerLayoutScript =
    '''
  (function() {
    var lastFullscreenState = null;

    function reportFullscreenState(isFullscreen) {
      if (lastFullscreenState === isFullscreen) return;
      lastFullscreenState = isFullscreen;
      try {
        if (window.flutter_inappwebview &&
            window.flutter_inappwebview.callHandler) {
          window.flutter_inappwebview.callHandler(
            'playerFullscreen',
            isFullscreen,
          );
        }
      } catch (_) {}
    }

    function installLayout() {
      var styleId = 'native-player-layout-style';
      if (!document.getElementById(styleId)) {
        var style = document.createElement('style');
        style.id = styleId;
        style.textContent = `$_playerLayoutCss`;
        (document.head || document.documentElement).appendChild(style);
      }
    }

    // A previous player version injected its own blue-icon toolbar. Keep the
    // provider's native controls as the single source of playback controls.
    function removeLegacyPlayerControls() {
      document.querySelectorAll('#native-player-controls').forEach(function(control) {
        control.remove();
      });
    }

    // CineSrc renders the white control bar with Media Chrome. Its default
    // auto-hide delay is three seconds; retain the original controls but use
    // a five-second delay and wake them after every user tap.
    function configureProviderControls() {
      document.querySelectorAll('media-controller').forEach(function(controller) {
        controller.setAttribute('autohide', '5');
        controller.style.setProperty('pointer-events', 'auto', 'important');
        controller.querySelectorAll(
          'media-control-bar, media-play-button, media-seek-backward-button, ' +
          'media-seek-forward-button, media-mute-button, media-time-range, button'
        ).forEach(function(control) {
          control.style.setProperty('pointer-events', 'auto', 'important');
        });
      });
    }

    function wakeProviderControls() {
      configureProviderControls();
      document.querySelectorAll('media-controller').forEach(function(controller) {
        controller.removeAttribute('userinactive');
        var playerRoot = controller.closest('.fixed') || controller.parentElement;
        if (!playerRoot) return;
        playerRoot.dispatchEvent(new MouseEvent('mousemove', {
          bubbles: true,
          cancelable: false,
          view: window,
        }));
        playerRoot.dispatchEvent(new Event('touchstart', {
          bubbles: false,
          cancelable: false,
        }));
        controller.dispatchEvent(new Event('useractive', { bubbles: true }));
      });

      // Not every source uses CineSrc's Media Chrome controller. In those
      // embeds, reveal the platform's standard video controls after the same
      // user gesture so a tap never leaves the viewer without a control bar.
      if (!document.querySelector('media-controller')) {
        document.querySelectorAll('video').forEach(function(video) {
          video.controls = true;
          video.dispatchEvent(new MouseEvent('mousemove', {
            bubbles: true,
            cancelable: false,
            view: window,
          }));
        });
      }

      document.querySelectorAll('[data-controls-visible]').forEach(function(player) {
        player.setAttribute('data-controls-visible', 'true');
      });
    }

    function installProviderControlWakeup() {
      var lastWakeAt = 0;
      function handleUserActivity(event) {
        // Ignore synthetic events emitted by wakeProviderControls itself.
        if (!event.isTrusted) return;
        var now = Date.now();
        if (now - lastWakeAt < 120) return;
        lastWakeAt = now;
        wakeProviderControls();
      }
      document.addEventListener('pointerdown', handleUserActivity, true);
      document.addEventListener('touchstart', handleUserActivity, true);
      configureProviderControls();
    }

    function syncFullscreenLayout() {
      var fullscreenElement = document.fullscreenElement ||
        document.webkitFullscreenElement;
      document.documentElement.classList.toggle(
        'player-edge-to-edge',
        !!fullscreenElement,
      );
      reportFullscreenState(!!fullscreenElement);
    }

    function enterInlineFullscreen() {
      document.documentElement.classList.add('player-edge-to-edge');
      reportFullscreenState(true);
      return Promise.resolve();
    }

    function exitInlineFullscreen() {
      document.documentElement.classList.remove('player-edge-to-edge');
      reportFullscreenState(false);
      return Promise.resolve();
    }

    function hasVideo(element) {
      return !!document.querySelector('video') && !!element && (
        element.tagName === 'VIDEO' ||
        element === document.documentElement ||
        element === document.body ||
        (element.querySelector && element.querySelector('video'))
      );
    }

    // iOS's native WKWebView fullscreen controller always letterboxes video.
    // Keep provider video inline and use our viewport-filling layout instead.
    function installInlineFullscreenOverride() {
      var nativeRequestFullscreen = HTMLElement.prototype.requestFullscreen;
      if (nativeRequestFullscreen && !HTMLElement.prototype.__playerFullscreenPatched) {
        HTMLElement.prototype.__playerFullscreenPatched = true;
        HTMLElement.prototype.requestFullscreen = function() {
          if (hasVideo(this)) {
            return document.documentElement.classList.contains('player-edge-to-edge')
              ? exitInlineFullscreen()
              : enterInlineFullscreen();
          }
          return nativeRequestFullscreen.apply(this, arguments);
        };
      }

      var nativeWebkitEnter = HTMLVideoElement.prototype.webkitEnterFullscreen;
      if (nativeWebkitEnter && !HTMLVideoElement.prototype.__playerWebkitFullscreenPatched) {
        HTMLVideoElement.prototype.__playerWebkitFullscreenPatched = true;
        HTMLVideoElement.prototype.webkitEnterFullscreen = function() {
          return document.documentElement.classList.contains('player-edge-to-edge')
            ? exitInlineFullscreen()
            : enterInlineFullscreen();
        };
      }

      var nativeExitFullscreen = document.exitFullscreen;
      if (nativeExitFullscreen && !document.__playerExitFullscreenPatched) {
        document.__playerExitFullscreenPatched = true;
        document.exitFullscreen = function() {
          if (document.documentElement.classList.contains('player-edge-to-edge')) {
            return exitInlineFullscreen();
          }
          return nativeExitFullscreen.apply(document, arguments);
        };
      }
    }

    installLayout();
    removeLegacyPlayerControls();
    new MutationObserver(function() {
      removeLegacyPlayerControls();
      configureProviderControls();
    }).observe(
      document.documentElement,
      { childList: true, subtree: true },
    );
    installProviderControlWakeup();
    installInlineFullscreenOverride();
    document.addEventListener('fullscreenchange', syncFullscreenLayout);
    document.addEventListener('webkitfullscreenchange', syncFullscreenLayout);
    document.addEventListener('webkitbeginfullscreen', function() {
      document.documentElement.classList.add('player-edge-to-edge');
      reportFullscreenState(true);
    }, true);
    document.addEventListener('webkitendfullscreen', function() {
      document.documentElement.classList.remove('player-edge-to-edge');
      reportFullscreenState(false);
    }, true);
  })();
''';

// ──────────────────────────────────────────────────────────────────────────────
// WatchScreen widget
// ──────────────────────────────────────────────────────────────────────────────
class WatchScreen extends StatefulWidget {
  final int movieId;
  final int? season;
  final int? episode;
  final String title;
  final bool isTvShow;

  const WatchScreen({
    super.key,
    required this.movieId,
    required this.title,
    this.season,
    this.episode,
    this.isTvShow = false,
  });

  @override
  State<WatchScreen> createState() => _WatchScreenState();
}

class _WatchScreenState extends State<WatchScreen> {
  static const MethodChannel _orientationChannel = MethodChannel(
    'newmovie/player_orientation',
  );

  InAppWebViewController? _webViewController;
  bool _isLoading = true;
  bool _hasError = false;
  double _loadingProgress = 0;
  int _currentProviderIndex = 0;
  bool _hasInjectedAdProtection = false;
  bool _isChangingSubtitle = false;
  String? _selectedSubtitleCode;
  bool _isPlayerFullscreen = false;

  // ── Build content blockers from the domain list ─────────────────────────
  late final List<ContentBlocker> _contentBlockers = _blockedDomains
      .map((pattern) {
        return ContentBlocker(
          trigger: ContentBlockerTrigger(urlFilter: pattern),
          action: ContentBlockerAction(type: ContentBlockerActionType.BLOCK),
        );
      })
      .toList(growable: false);

  // ── Current embed URL ──────────────────────────────────────────────────
  String get _embedUrl {
    return _providers[_currentProviderIndex].buildUrl(
      widget.movieId,
      season: widget.season,
      episode: widget.episode,
      isTvShow: widget.isTvShow,
    );
  }

  String get _providerName => _providers[_currentProviderIndex].name;

  String get _episodeLabel {
    if (widget.isTvShow && widget.season != null && widget.episode != null) {
      return 'S${widget.season}E${widget.episode.toString().padLeft(2, '0')}';
    }
    return '';
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<void> _reload() async {
    setState(() {
      _hasError = false;
      _isLoading = true;
      _loadingProgress = 0;
    });
    await _webViewController?.loadUrl(
      urlRequest: URLRequest(url: WebUri(_embedUrl)),
    );
  }

  void _switchProvider(int index) {
    if (index == _currentProviderIndex) return;
    setState(() {
      _currentProviderIndex = index;
      _hasError = false;
      _isLoading = true;
      _loadingProgress = 0;
    });
    _webViewController?.loadUrl(urlRequest: URLRequest(url: WebUri(_embedUrl)));
  }

  Future<void> _showSubtitlePicker() async {
    final language = await showModalBottomSheet<_SubtitleLanguage>(
      context: context,
      backgroundColor: const Color(0xFF121212),
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) =>
          _SubtitlePickerSheet(selectedCode: _selectedSubtitleCode),
    );

    if (language == null) return;
    if (language.code.isEmpty) {
      await _disableSubtitles();
      return;
    }
    await _selectSubtitle(language);
  }

  Future<void> _selectSubtitle(_SubtitleLanguage language) async {
    if (_webViewController == null || _isChangingSubtitle) return;
    setState(() => _isChangingSubtitle = true);

    try {
      final result = await _webViewController!.evaluateJavascript(
        source:
            '''
          (function() {
            var languageCode = '${language.code}'.toLowerCase();
            var baseCode = languageCode.split('-')[0];
            var languageName = '${language.name}'.toLowerCase();
            var matched = false;
            var tracks = document.querySelectorAll(
              'track[kind="subtitles"], track[kind="captions"]'
            );

            for (var i = 0; i < tracks.length; i++) {
              var track = tracks[i];
              var trackCode = (track.srclang || '').toLowerCase();
              var trackLabel = (track.label || '').toLowerCase();
              var isMatch = trackCode === languageCode ||
                trackCode.split('-')[0] === baseCode ||
                trackLabel.indexOf(languageCode) !== -1 ||
                trackLabel.indexOf(languageName) !== -1;
              try {
                track.track.mode = isMatch ? 'showing' : 'disabled';
                if (isMatch) matched = true;
              } catch (_) {}
            }

            var videos = document.querySelectorAll('video');
            for (var videoIndex = 0; videoIndex < videos.length; videoIndex++) {
              var textTracks = videos[videoIndex].textTracks || [];
              for (var trackIndex = 0; trackIndex < textTracks.length; trackIndex++) {
                var textTrack = textTracks[trackIndex];
                var textTrackCode = (textTrack.language || '').toLowerCase();
                var textTrackLabel = (textTrack.label || '').toLowerCase();
                var isTextTrackMatch = textTrackCode === languageCode ||
                  textTrackCode.split('-')[0] === baseCode ||
                  textTrackLabel.indexOf(languageCode) !== -1 ||
                  textTrackLabel.indexOf(languageName) !== -1;
                textTrack.mode = isTextTrackMatch ? 'showing' : 'disabled';
                if (isTextTrackMatch) matched = true;
              }
            }
            return matched;
          })();
        ''',
      );

      if (!mounted) return;
      final selected = result == true || result.toString() == 'true';
      setState(() {
        _isChangingSubtitle = false;
        if (selected) _selectedSubtitleCode = language.code;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            selected
                ? '${language.name} subtitles enabled'
                : '${language.name} subtitles are not available from $_providerName',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isChangingSubtitle = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not change subtitles right now.')),
      );
    }
  }

  Future<void> _disableSubtitles() async {
    try {
      await _webViewController?.evaluateJavascript(
        source: '''
          (function() {
            document.querySelectorAll('track[kind="subtitles"], track[kind="captions"]')
              .forEach(function(track) { track.track.mode = 'disabled'; });
            document.querySelectorAll('video').forEach(function(video) {
              for (var i = 0; i < video.textTracks.length; i++) {
                video.textTracks[i].mode = 'disabled';
              }
            });
          })();
        ''',
      );
    } catch (_) {
      // The picker state can still be updated; a provider may expose tracks late.
    }
    if (!mounted) return;
    setState(() => _selectedSubtitleCode = null);
  }

  Future<void> _setEdgeToEdgePlayerLayout(bool enabled) async {
    try {
      await _webViewController?.evaluateJavascript(
        source:
            '''
          document.documentElement.classList.toggle(
            'player-edge-to-edge',
            ${enabled ? 'true' : 'false'},
          );
        ''',
      );
    } catch (_) {
      // The provider can still use its own native fullscreen implementation.
    }
  }

  Future<void> _enterPlayerFullscreen() async {
    if (mounted) {
      setState(() => _isPlayerFullscreen = true);
    }
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _setEdgeToEdgePlayerLayout(true);
    try {
      await _orientationChannel.invokeMethod<void>('landscape');
    } catch (_) {
      // Android and web views that already rotate via SystemChrome need no
      // platform-specific orientation request.
    }
  }

  Future<void> _exitPlayerFullscreen() async {
    if (mounted) {
      setState(() => _isPlayerFullscreen = false);
    }
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _setEdgeToEdgePlayerLayout(false);
    try {
      await _orientationChannel.invokeMethod<void>('portrait');
    } catch (_) {
      // See the note in _enterPlayerFullscreen.
    }
  }

  // Inject CSS & JS once per document to hide overlays and block clickjackers.
  Future<void> _injectAdBlockCss() async {
    if (_hasInjectedAdProtection) return;
    _hasInjectedAdProtection = true;

    await _webViewController?.evaluateJavascript(
      source:
          '''
      (function() {
        // 1. Inject hiding CSS rules
        var s = document.getElementById('ad-and-server-hiding-style');
        if (!s) {
          s = document.createElement('style');
          s.id = 'ad-and-server-hiding-style';
          document.head.appendChild(s);
        }
        s.textContent = `$_adHidingCss\n$_playerLayoutCss`;

        // 2. Hide and remove server droplist / server bar elements
        function cleanupServerBar() {
          var selectors = [
            '.embed-server-bar',
            '.srv-dropdown',
            '.srv-label',
            '.srv-btn',
            '.srv-btn-label',
            '#srvBtn',
            '#srvDropdown',
            '#srvBtnLabel',
            '.srv-dropdown-list',
            '.srv-item',
            '[class*="embed-server-bar"]',
            '[class*="server-bar"]'
          ];
          selectors.forEach(function(sel) {
            var els = document.querySelectorAll(sel);
            for (var i = 0; i < els.length; i++) {
              els[i].style.setProperty('display', 'none', 'important');
              els[i].style.setProperty('visibility', 'hidden', 'important');
              els[i].style.setProperty('opacity', '0', 'important');
              els[i].style.setProperty('pointer-events', 'none', 'important');
            }
          });

        }

        // Fallback for Android WebViews that do not support document-start
        // scripts. (The document-start version is intentionally stronger.)
        try { window.open = function() { return null; }; } catch (e) {}

        // 3. Intercept clickjacking and external popup links.
        if (!window.__adProtectionInstalled) {
          window.__adProtectionInstalled = true;
          document.addEventListener('click', function(e) {
            var el = e.target;
            while (el && el !== document.body && el !== document.documentElement) {
              if (el.tagName === 'A') {
                var href = el.getAttribute('href') || el.href || '';
                if (href && !href.startsWith('#') && !href.startsWith('javascript:')) {
                  try {
                    var parsed = new URL(href, window.location.href);
                    var h = parsed.hostname.toLowerCase();
                    var isAllowed = h.includes('cinesrc.st') ||
                                    h.includes('cineflix.st') ||
                                    h.includes('vidsrc') ||
                                    h.includes('nxsha.app') ||
                                    h.includes('febbox');
                    if (!isAllowed) {
                      e.preventDefault();
                      // Keep the player click alive. Stopping propagation in
                      // capture phase also prevents the provider from waking
                      // its own control bar after a user tap.
                      return false;
                    }
                  } catch(err) {
                    e.preventDefault();
                    return false;
                  }
                }
              }
              el = el.parentElement;
            }
          }, true);
        }

        // 4. Remove transparent full-screen overlay clickjackers.
        function removeInvisibleClickjackers() {
          var all = document.querySelectorAll('div, a, span');
          for (var i = 0; i < all.length; i++) {
            var item = all[i];
            if (item.tagName === 'VIDEO' || item.closest('video') || item.closest('media-controller')) {
              continue;
            }
            var st = window.getComputedStyle(item);
            if ((st.position === 'fixed' || st.position === 'absolute') &&
                parseInt(st.zIndex, 10) > 500 &&
                item.offsetWidth >= window.innerWidth * 0.7 &&
                item.offsetHeight >= window.innerHeight * 0.7) {
              if (st.opacity === '0' || st.backgroundColor === 'rgba(0, 0, 0, 0)' || st.backgroundColor === 'transparent') {
                item.remove();
              }
            }
          }
        }

        // WebVTT's default line position differs between providers. Position
        // cues inside the lower part of the video rather than at page bottom.
        function positionSubtitles() {
          var videos = document.querySelectorAll('video');
          for (var videoIndex = 0; videoIndex < videos.length; videoIndex++) {
            var textTracks = videos[videoIndex].textTracks || [];
            for (var trackIndex = 0; trackIndex < textTracks.length; trackIndex++) {
              var textTrack = textTracks[trackIndex];
              try {
                var cues = textTrack.cues || [];
                for (var cueIndex = 0; cueIndex < cues.length; cueIndex++) {
                  cues[cueIndex].line = 90;
                }
              } catch (e) {}
            }
          }
        }

        cleanupServerBar();
        removeInvisibleClickjackers();
        positionSubtitles();
        if (!window.__playerAdCleanupTimer) {
          window.__playerAdCleanupTimer = setInterval(function() {
            cleanupServerBar();
            removeInvisibleClickjackers();
            positionSubtitles();
          }, 300);
          setTimeout(function() {
            clearInterval(window.__playerAdCleanupTimer);
            window.__playerAdCleanupTimer = null;
          }, 6000);
        }
      })();
    ''',
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: _isPlayerFullscreen,
      appBar: _isPlayerFullscreen
          ? null
          : AppBar(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              elevation: 0,
              titleSpacing: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (_episodeLabel.isNotEmpty)
                    Text(
                      _episodeLabel,
                      style: const TextStyle(
                        color: Color(0xFFE50914),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
              actions: [
                IconButton(
                  icon: _isChangingSubtitle
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          Icons.closed_caption_outlined,
                          color: _selectedSubtitleCode == null
                              ? Colors.white
                              : const Color(0xFFE50914),
                        ),
                  tooltip: 'Subtitles',
                  onPressed: _isChangingSubtitle ? null : _showSubtitlePicker,
                ),
                if (!_isLoading && !_hasError)
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, size: 22),
                    tooltip: 'Reload',
                    onPressed: _reload,
                  ),
              ],
            ),

      // ── Body ──────────────────────────────────────────────────────────
      body: Stack(
        children: [
          // ── WebView ────────────────────────────────────────────────
          if (!_hasError)
            InAppWebView(
              initialUrlRequest: URLRequest(url: WebUri(_embedUrl)),
              initialUserScripts: UnmodifiableListView([
                UserScript(
                  groupName: 'player-popup-protection',
                  source: _documentStartAdBlockScript,
                  injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
                  forMainFrameOnly: false,
                ),
                UserScript(
                  groupName: 'player-edge-to-edge-layout',
                  source: _documentStartPlayerLayoutScript,
                  injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
                  forMainFrameOnly: false,
                ),
              ]),
              initialSettings: InAppWebViewSettings(
                // Media
                mediaPlaybackRequiresUserGesture: false,
                allowsInlineMediaPlayback: true,
                allowsPictureInPictureMediaPlayback: true,
                allowsAirPlayForMediaPlayback: true,
                // Mixed content
                mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
                // User-agent (Safari mobile)
                userAgent:
                    'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) '
                    'AppleWebKit/605.1.15 (KHTML, like Gecko) '
                    'Version/17.0 Mobile/15E148 Safari/604.1',
                // JS & storage
                javaScriptEnabled: true,
                domStorageEnabled: true,
                databaseEnabled: true,
                javaScriptCanOpenWindowsAutomatically: false,
                // UX
                supportZoom: false,
                allowsBackForwardNavigationGestures: false,
                useShouldOverrideUrlLoading: true,
                // Ad-blocking via content blockers
                contentBlockers: _contentBlockers,
              ),
              onWebViewCreated: (controller) {
                _webViewController = controller;
                controller.addJavaScriptHandler(
                  handlerName: 'playerFullscreen',
                  callback: (args) {
                    if (args.isNotEmpty && args.first == true) {
                      _enterPlayerFullscreen();
                    } else {
                      _exitPlayerFullscreen();
                    }
                    return null;
                  },
                );
              },
              onLoadStart: (controller, url) {
                if (!mounted) return;
                setState(() {
                  _isLoading = true;
                  _hasError = false;
                  _hasInjectedAdProtection = false;
                });
              },
              onProgressChanged: (controller, progress) {
                if (!mounted) return;
                setState(() {
                  _loadingProgress = progress / 100.0;
                  if (progress >= 100) _isLoading = false;
                });
                if (progress > 30) {
                  _injectAdBlockCss();
                }
              },
              onLoadStop: (controller, url) async {
                if (!mounted) return;
                setState(() => _isLoading = false);
                // Inject CSS to hide any remaining ad overlays
                await _injectAdBlockCss();
              },
              onReceivedError: (controller, request, error) {
                if (request.isForMainFrame == true && mounted) {
                  setState(() {
                    _isLoading = false;
                    _hasError = true;
                  });
                }
              },
              // ── Block popup windows (ads try to open new tabs) ──
              onCreateWindow: (controller, createWindowAction) async {
                // Return false = prevent any new window/tab from opening
                return false;
              },
              // ── Strictly block ad redirects & popup navigations ──
              shouldOverrideUrlLoading: (controller, navigationAction) async {
                final uri = navigationAction.request.url;
                if (uri == null) return NavigationActionPolicy.CANCEL;

                final urlString = uri.toString().toLowerCase();
                final host = uri.host.toLowerCase();

                // Whitelisted streaming domains
                const allowedDomains = [
                  'cinesrc.st',
                  'cineflix.st',
                  'vidsrc.sbs',
                  'vidsrc.in',
                  'vidsrc.dev',
                  '2embed.cc',
                  'nxsha.app',
                  'febbox.com',
                  'fshair.com',
                  'themoviedb.org',
                  'tmdb.org',
                  'cloudflare.com',
                ];

                final isAllowed = allowedDomains.any(
                  (d) => host == d || host.endsWith('.$d'),
                );

                // If navigation is trying to go to an external ad (e.g. Melbet, betting, casino), CANCEL it!
                if (!isAllowed) {
                  return NavigationActionPolicy.CANCEL;
                }

                // Extra safety: block known malicious/ad keywords in URL
                if (urlString.contains('melbet') ||
                    urlString.contains('1xbet') ||
                    urlString.contains('casino') ||
                    urlString.contains('bet365') ||
                    urlString.contains('adclick') ||
                    urlString.contains('popunder') ||
                    urlString.contains('affiliate')) {
                  return NavigationActionPolicy.CANCEL;
                }

                return NavigationActionPolicy.ALLOW;
              },
              onPermissionRequest: (controller, request) async {
                return PermissionResponse(
                  // Playback does not need camera or microphone access.
                  resources: const [],
                  action: PermissionResponseAction.DENY,
                );
              },
              onEnterFullscreen: (controller) {
                _enterPlayerFullscreen();
              },
              onExitFullscreen: (controller) {
                _exitPlayerFullscreen();
              },
            ),

          // ── Error state ────────────────────────────────────────────
          if (_hasError)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFE50914).withValues(alpha: 0.12),
                      ),
                      child: const Icon(
                        Icons.wifi_off_rounded,
                        color: Color(0xFFE50914),
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '$_providerName could not load',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Try another source or check your connection.',
                      style: TextStyle(color: Colors.white54, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    // Try next provider button
                    if (_currentProviderIndex < _providers.length - 1)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                _switchProvider(_currentProviderIndex + 1),
                            icon: const Icon(Icons.swap_horiz_rounded),
                            label: Text(
                              'Try ${_providers[_currentProviderIndex + 1].name}',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1A1A2E),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.1),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _reload,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE50914),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── Loading overlay ────────────────────────────────────────
          if (_isLoading && !_hasError)
            Positioned.fill(
              child: Container(
                color: Colors.black,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const _PulsingPlayIcon(),
                    const SizedBox(height: 24),
                    Text(
                      'Loading $_providerName…',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 48),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: _loadingProgress > 0 ? _loadingProgress : null,
                          backgroundColor: Colors.white12,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFFE50914),
                          ),
                          minHeight: 3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Pulsing play-icon loading animation ──────────────────────────────────────
class _PulsingPlayIcon extends StatefulWidget {
  const _PulsingPlayIcon();

  @override
  State<_PulsingPlayIcon> createState() => _PulsingPlayIconState();
}

class _PulsingPlayIconState extends State<_PulsingPlayIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _scale = Tween<double>(
      begin: 0.88,
      end: 1.12,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _opacity = Tween<double>(
      begin: 0.4,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) => Transform.scale(
        scale: _scale.value,
        child: Opacity(
          opacity: _opacity.value,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFE50914).withValues(alpha: 0.15),
              border: Border.all(
                color: const Color(0xFFE50914).withValues(alpha: 0.5),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.play_arrow_rounded,
              color: Color(0xFFE50914),
              size: 44,
            ),
          ),
        ),
      ),
    );
  }
}

class _SubtitlePickerSheet extends StatefulWidget {
  final String? selectedCode;

  const _SubtitlePickerSheet({required this.selectedCode});

  @override
  State<_SubtitlePickerSheet> createState() => _SubtitlePickerSheetState();
}

class _SubtitlePickerSheetState extends State<_SubtitlePickerSheet> {
  String _query = '';

  List<_SubtitleLanguage> get _filteredLanguages {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return _subtitleLanguages;
    return _subtitleLanguages
        .where((language) {
          return language.name.toLowerCase().contains(query) ||
              language.nativeName.toLowerCase().contains(query) ||
              language.code.toLowerCase().contains(query);
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final languages = _filteredLanguages;
    return SafeArea(
      top: false,
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.78,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Subtitles',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Choose a language supplied by this source.',
                style: TextStyle(color: Colors.white60, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                onChanged: (value) => setState(() => _query = value),
                autofocus: false,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search languages',
                  hintStyle: const TextStyle(color: Colors.white38),
                  prefixIcon: const Icon(Icons.search, color: Colors.white60),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.08),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  itemCount: languages.length + 1,
                  separatorBuilder: (_, _) =>
                      const Divider(height: 1, color: Colors.white12),
                  itemBuilder: (context, index) {
                    final language = index == 0
                        ? _subtitleOff
                        : languages[index - 1];
                    final isSelected = language.code.isEmpty
                        ? widget.selectedCode == null
                        : language.code == widget.selectedCode;
                    return ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                      onTap: () => Navigator.pop(context, language),
                      leading: Icon(
                        language.code.isEmpty
                            ? Icons.closed_caption_off_outlined
                            : Icons.closed_caption_outlined,
                        color: isSelected
                            ? const Color(0xFFE50914)
                            : Colors.white70,
                      ),
                      title: Text(
                        language.name,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        language.nativeName,
                        style: const TextStyle(color: Colors.white54),
                      ),
                      trailing: isSelected
                          ? const Icon(
                              Icons.check_rounded,
                              color: Color(0xFFE50914),
                            )
                          : null,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
