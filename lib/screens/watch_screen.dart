import 'dart:collection';
import 'dart:async';

import '../widgets/native_ad_panel.dart';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../services/ad_service.dart';

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

class _AvailableSubtitle {
  final String id;
  final String code;
  final String label;
  final bool active;

  const _AvailableSubtitle({
    required this.id,
    required this.code,
    required this.label,
    required this.active,
  });

  String get displayName {
    final normalizedCode = code.toLowerCase().replaceAll('_', '-');
    final baseCode = normalizedCode.split('-').first;
    for (final language in _subtitleLanguages) {
      final languageCode = language.code.toLowerCase();
      if (languageCode == normalizedCode || languageCode == baseCode) {
        return language.name;
      }
    }
    return label.isNotEmpty ? label : code;
  }
}

// Names for tracks that VidFast actually exposes. This is not an availability
// list; the CC sheet is populated from the current video instead.
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
    name: 'VidFast',
    buildUrl: (id, {season, episode, isTvShow = false}) {
      const base = 'https://vidfast.vc';
      if (isTvShow) {
        return '$base/tv/$id/${season ?? 1}/${episode ?? 1}?autoPlay=true&theme=E50914';
      }
      return '$base/movie/$id?autoPlay=true&theme=E50914';
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

// CSS selectors to hide overlay / interstitial ad elements
const String _adHidingCss = '''
  /* Hide intrusive ads & banners without touching player controls or popups */
  .ad-slot, .ad-banner, .adsbox, .ad-container,
  [class*="banner-ad"], [id*="banner-ad"],
  iframe[src*="ads"], iframe[src*="pop"],
  div[class*="AdSlot"], div[id*="AdSlot"] {
    display: none !important;
    visibility: hidden !important;
    opacity: 0 !important;
    pointer-events: none !important;
  }
''';

// Installed before the provider document executes, so popup attempts cannot
// race the post-load CSS cleanup below. Uses a compliant dummy window object
// so Next.js React hydration does not throw TypeError.
const String _documentStartAdBlockScript = r'''
  (function() {
    if (window.__playerPopupProtectionInstalled) return;
    window.__playerPopupProtectionInstalled = true;

    var noop = function() {};
    var dummyWindow = {
      focus: noop,
      close: noop,
      closed: true,
      postMessage: noop,
      addEventListener: noop,
      removeEventListener: noop,
      document: {
        write: noop,
        writeln: noop,
        close: noop,
        createElement: function() { return {}; },
        body: {}
      },
      location: { href: '', assign: noop, replace: noop }
    };

    try {
      window.open = function() {
        return dummyWindow;
      };
    } catch (_) {}
  })();
''';

// Only resize an element that the provider actually puts into fullscreen.
// The portrait player keeps VidFast's own dimensions and controls.
const String _documentStartFullscreenFillScript = r'''
  (function() {
    var style = document.createElement('style');
    style.id = 'landscape-fullscreen-fill';
    style.textContent = `
      @media (orientation: landscape) {
        :fullscreen, :-webkit-full-screen {
          width: 100vw !important;
          height: 100vh !important;
          height: 100dvh !important;
          max-width: none !important;
          max-height: none !important;
          background: #000 !important;
        }
        video:fullscreen, video:-webkit-full-screen,
        :fullscreen video, :-webkit-full-screen video {
          width: 100% !important;
          height: 100% !important;
          object-fit: cover !important;
          object-position: center !important;
        }
        html.newmovie-player-fullscreen,
        html.newmovie-player-fullscreen body {
          width: 100vw !important;
          height: 100vh !important;
          height: 100dvh !important;
          margin: 0 !important;
          overflow: hidden !important;
          background: #000 !important;
        }
        html.newmovie-player-fullscreen video {
          width: 100vw !important;
          height: 100vh !important;
          height: 100dvh !important;
          max-width: none !important;
          max-height: none !important;
          object-fit: contain !important;
          background: #000 !important;
        }
        html.newmovie-player-fullscreen iframe {
          position: fixed !important;
          inset: 0 !important;
          width: 100vw !important;
          height: 100vh !important;
          height: 100dvh !important;
          max-width: none !important;
          max-height: none !important;
          border: 0 !important;
          z-index: 2147483647 !important;
          background: #000 !important;
        }
      }
    `;
    if (document.head) {
      document.head.appendChild(style);
    } else {
      document.addEventListener('DOMContentLoaded', function() {
        document.head.appendChild(style);
      }, { once: true });
    }

    function fullscreenControl(element) {
      // Inspect only the clicked control, never its player/menu ancestors.
      // Container classes can include "fullscreen" even for CC/settings taps.
      if (!element || !element.closest) return false;
      var control = element.closest('button, [role="button"], a');
      if (!control) return false;
      var description = [
        control.getAttribute('aria-label'),
        control.getAttribute('title'),
        control.getAttribute('data-tooltip'),
        control.getAttribute('data-plyr'),
        control.getAttribute('class')
      ].filter(Boolean).join(' ').toLowerCase();
      return /(?:^|[\s_-])(?:fullscreen|full-screen|full_screen)(?:$|[\s_-])/.test(description);
    }

    document.addEventListener('click', function(event) {
      if (!fullscreenControl(event.target)) return;
      // The provider's fullscreen control can reload the embed in a WKWebView.
      // Keep its playback session intact and expand the Flutter player instead.
      event.preventDefault();
      event.stopImmediatePropagation();
      var entering = !document.documentElement.classList.contains(
        'newmovie-player-fullscreen'
      );
      document.documentElement.classList.toggle(
        'newmovie-player-fullscreen', entering
      );
      try {
        window.flutter_inappwebview.callHandler(
          'requestPlayerFullscreen', entering
        );
      } catch (_) {}
    }, true);
  })();
''';

// Preserve the viewer's place on reload. VidFast may load its video inside an
// embedded frame, so progress is reported from every document.
const String _documentStartPlayerProgressScript = r'''
  (function() {
    function bindVideos() {
      document.querySelectorAll('video').forEach(function(video) {
        if (video.__newmovieProgressBound) return;
        video.__newmovieProgressBound = true;
        var lastReport = 0;
        video.addEventListener('timeupdate', function() {
          if (video.paused || !Number.isFinite(video.currentTime)) return;
          var now = Date.now();
          if (now - lastReport < 2000) return;
          lastReport = now;
          try {
            window.flutter_inappwebview.callHandler(
              'playerProgress', video.currentTime
            );
          } catch (_) {}
        });
      });
    }
    bindVideos();
    document.addEventListener('DOMContentLoaded', bindVideos, { once: true });
    if (document.documentElement) {
      new MutationObserver(bindVideos).observe(
        document.documentElement, { childList: true, subtree: true },
      );
    }
  })();
''';

// Comprehensive subtitle bridge that:
// 1. Intercepts fetch/XHR to discover subtitle file URLs loaded by VidFast.
// 2. Monitors HTML5 textTracks (with aggressive polling for up to 30s).
// 3. Opens VidFast's CC menu by matching SVG icons and aria/title attributes.
// 4. After opening the menu, waits for it to render and scrapes the live options.
// 5. Applies selection both via the provider's own UI and via textTrack.mode.
const String _documentStartSubtitleBridgeScript = r'''
  (function() {
    if (window.__newmovieSubtitleBridge) return;
    var frameId = Date.now().toString(36) + Math.random().toString(36).slice(2);
    var watchedVideos = new WeakSet();
    var reportTimer = null;
    var menuSubtitles = {};        // key -> {id, code, label, active}
    var scanCount = 0;
    var MAX_SCANS = 30; // 30 scans * 2s = 60 s of background polling

    // ── Helpers ──────────────────────────────────────────────────────────
    function videos() {
      try { return Array.prototype.slice.call(document.querySelectorAll('video')); }
      catch (_) { return []; }
    }

    function isCaptionKind(kind) {
      var k = String(kind || '').toLowerCase();
      return k === '' || k === 'subtitles' || k === 'captions' || k === 'forced' || k === 'descriptions';
    }

    function guessLanguageCode(text) {
      // Attempt to map a display name to a BCP-47 code
      var map = {
        'english':'en','arabic':'ar','french':'fr','spanish':'es','german':'de',
        'portuguese':'pt','portuguese (brazil)':'pt-BR','russian':'ru','italian':'it',
        'japanese':'ja','korean':'ko','chinese':'zh','dutch':'nl','turkish':'tr',
        'polish':'pl','swedish':'sv','danish':'da','norwegian':'no','finnish':'fi',
        'hindi':'hi','thai':'th','indonesian':'id','vietnamese':'vi','romanian':'ro',
        'czech':'cs','slovak':'sk','hungarian':'hu','greek':'el','hebrew':'he',
        'ukrainian':'uk','bulgarian':'bg','croatian':'hr','serbian':'sr','persian':'fa',
        'urdu':'ur','bengali':'bn','tamil':'ta','telugu':'te','malay':'ms',
        'malayalam':'ml','marathi':'mr'
      };
      var t = String(text || '').toLowerCase().trim();
      return map[t] || '';
    }


    // ── Track collection ─────────────────────────────────────────────────
    function collectTextTracks() {
      var result = [];
      var seen = {};
      videos().forEach(function(video, videoIndex) {
        var textTracks = video.textTracks || [];
        var elements = video.querySelectorAll('track');
        for (var i = 0; i < textTracks.length; i++) {
          var track = textTracks[i];
          if (!isCaptionKind(track.kind)) continue;
          var el = elements[i];
          var code = String(track.language || (el && el.srclang) || '').trim();
          var label = String(track.label || (el && el.label) || code || 'Subtitle').trim();
          var key = (code || label).toLowerCase();
          if (seen[key]) continue;
          seen[key] = true;
          result.push({ id: frameId+':v'+videoIndex+':'+i, code: code, label: label, active: track.mode === 'showing' });
        }
        // Also scan <track> elements not yet reflected in textTracks
        elements.forEach(function(el, idx) {
          if (!isCaptionKind(el.kind)) return;
          var code = String(el.srclang || '').trim();
          var label = String(el.label || el.srclang || 'Subtitle').trim();
          var key = (code || label).toLowerCase();
          if (seen[key]) return;
          seen[key] = true;
          result.push({ id: frameId+':e'+videoIndex+':'+idx, code: code, label: label,
            active: !!(el.track && el.track.mode === 'showing') });
        });
      });
      return result;
    }

    function collectMenuTracks() {
      // Scrape VidFast's currently-rendered subtitle menu entries
      var result = [];
      var seen = {};
      try {
        // Target common menu selectors used by VidFast / video.js / Plyr etc.
        var selectors = [
          '[role="option"]',
          '[role="menuitem"]',
          '[data-language]',
          '[data-lang]',
          '.vjs-menu-item',
          '.plyr__menu__container li',
          '.MuiMenuItem-root',
          '.subtitle-item',
          '.cc-option',
          '.sub-option',
          'ul.subtitle-list li',
          'ul.cc-list li'
        ];
        var found = document.querySelectorAll(selectors.join(','));
        found.forEach(function(el, idx) {
          var txt = String(el.textContent || '').trim();
          if (!txt || txt === 'Upload Subtitles' || /turn off/i.test(txt)) return;
          var key = txt.toLowerCase();
          if (seen[key]) return;
          seen[key] = true;
          var code = String(
            el.getAttribute('data-language') || el.getAttribute('data-lang') ||
            el.getAttribute('value') || ''
          ).trim() || guessLanguageCode(txt);
          var isActive = el.getAttribute('aria-selected') === 'true' ||
                         el.getAttribute('aria-checked') === 'true' ||
                         el.classList.contains('Mui-selected') ||
                         el.classList.contains('vjs-selected') ||
                         el.classList.contains('active') ||
                         el.classList.contains('selected');
          result.push({ id: frameId+':menu:'+idx, code: code, label: txt, active: isActive });
        });
      } catch (_) {}
      return result;
    }

    function collect() {
      var seen = {};
      var result = [];
      function add(track) {
        var key = (track.code + '|' + track.label).toLowerCase();
        if (seen[key]) return;
        seen[key] = true;
        result.push(track);
      }
      collectTextTracks().forEach(add);
      // Add any scraped menu subtitles (for-in is safe on all iOS WebKit)
      for (var mk in menuSubtitles) {
        if (Object.prototype.hasOwnProperty.call(menuSubtitles, mk)) {
          add(menuSubtitles[mk]);
        }
      }
      collectMenuTracks().forEach(add);
      return result;
    }

    // ── Reporting ────────────────────────────────────────────────────────
    function report() {
      try {
        var tracks = collect();
        if (window.flutter_inappwebview && window.flutter_inappwebview.callHandler) {
          window.flutter_inappwebview.callHandler('availableSubtitles', { frameId: frameId, tracks: tracks });
        } else {
          setTimeout(report, 800);
        }
      } catch (_) {}
    }

    function scheduleReport() {
      if (reportTimer !== null) return;
      reportTimer = setTimeout(function() { reportTimer = null; report(); }, 250);
    }

    // ── Video watching ───────────────────────────────────────────────────
    function watch() {
      videos().forEach(function(video) {
        if (watchedVideos.has(video)) return;
        watchedVideos.add(video);
        video.addEventListener('loadedmetadata', scheduleReport);
        video.addEventListener('emptied', scheduleReport);
        video.addEventListener('play', scheduleReport);
        video.addEventListener('canplay', scheduleReport);
        if (video.textTracks && video.textTracks.addEventListener) {
          video.textTracks.addEventListener('addtrack', scheduleReport);
          video.textTracks.addEventListener('removetrack', scheduleReport);
          video.textTracks.addEventListener('change', scheduleReport);
        }
      });
    }

    // ── VidFast CC menu interaction ───────────────────────────────────────
    // Returns true if the CC / subtitle menu button was found & clicked.
    function openCCMenu() {
      try {
        // Strategy 1: aria-label / title attribute matching
        var btns = document.querySelectorAll('button, [role="button"]');
        for (var i = 0; i < btns.length; i++) {
          var b = btns[i];
          var aria = String(
            b.getAttribute('aria-label') || b.getAttribute('title') ||
            b.getAttribute('data-title') || b.getAttribute('data-tooltip') || ''
          ).toLowerCase();
          if (aria && (aria.indexOf('subtitle') !== -1 || aria.indexOf('caption') !== -1 ||
              aria.indexOf(' cc') !== -1 || aria === 'cc')) {
            b.click();
            return true;
          }
        }
        // Strategy 2: SVG icon heuristic – look for CC-shaped SVG viewBox
        var svgUses = document.querySelectorAll('use[href], use[xlink:href]');
        for (var j = 0; j < svgUses.length; j++) {
          var href = svgUses[j].getAttribute('href') || svgUses[j].getAttribute('xlink:href') || '';
          if (/cc|caption|subtitle/i.test(href)) {
            var parent = svgUses[j].closest('button') || svgUses[j].closest('[role="button"]');
            if (parent) { parent.click(); return true; }
          }
        }
        // Strategy 3: any button whose visible text is exactly 'CC'
        for (var k = 0; k < btns.length; k++) {
          var txt = String(btns[k].textContent || '').trim();
          if (txt === 'CC' || txt === 'cc' || txt === 'Subtitles') {
            btns[k].click();
            return true;
          }
        }
      } catch (_) {}
      return false;
    }

    // Click a visible menu item that matches label or code.
    function clickMenuOption(targetLabel, targetCode) {
      try {
        var elems = document.querySelectorAll(
          '[role="option"], [role="menuitem"], [data-language], [data-lang],'
          + '.vjs-menu-item, .MuiMenuItem-root, .subtitle-item, .cc-option, .sub-option, li'
        );
        var normLabel = String(targetLabel || '').toLowerCase();
        var normCode  = String(targetCode  || '').toLowerCase();
        for (var i = 0; i < elems.length; i++) {
          var el = elems[i];
          var txt  = String(el.textContent || '').trim().toLowerCase();
          var lang = String(
            el.getAttribute('data-language') || el.getAttribute('data-lang') ||
            el.getAttribute('value') || ''
          ).toLowerCase();
          if ((normLabel && (txt === normLabel || txt.startsWith(normLabel))) ||
              (normCode  && (lang === normCode  || lang.startsWith(normCode)))) {
            el.click();
            return true;
          }
        }
      } catch (_) {}
      return false;
    }

    // Open CC menu, wait for it to render, scrape options, then close.
    function snapshotViaMenu(callback) {
      var opened = openCCMenu();
      // Whether the menu opened or not, wait and scrape:
      setTimeout(function() {
        var items = collectMenuTracks();
        items.forEach(function(item) {
          var key = (item.code + '|' + item.label).toLowerCase();
          menuSubtitles[key] = item;
        });
        // Close the menu by pressing Escape or clicking outside
        try {
          document.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape', bubbles: true }));
        } catch (_) {}
        if (callback) callback(items.length > 0);
        scheduleReport();
      }, opened ? 500 : 100);
    }

    // ── Selection ────────────────────────────────────────────────────────
    function applySelection(targetId, targetCode, targetLabel) {
      var found = false;

      // 1. Try menu first (most reliable for VidFast)
      if (clickMenuOption(targetLabel, targetCode)) {
        found = true;
      } else {
        // Open CC menu, wait for render, then click the option
        openCCMenu();
        setTimeout(function() {
          if (clickMenuOption(targetLabel, targetCode)) {
            found = true;
          }
          scheduleReport();
        }, 600);
      }

      // 2. Also set HTML5 textTrack.mode for native tracks
      videos().forEach(function(video, vi) {
        var tracks = video.textTracks || [];
        for (var i = 0; i < tracks.length; i++) {
          var t = tracks[i];
          var id = frameId + ':v' + vi + ':' + i;
          var isMatch = targetId === id ||
            (targetLabel && String(t.label || '').toLowerCase() === targetLabel.toLowerCase()) ||
            (targetCode  && String(t.language || '').toLowerCase() === targetCode.toLowerCase());
          try { t.mode = isMatch ? 'showing' : 'disabled'; if (isMatch) found = true; } catch (_) {}
        }
      });
      return found;
    }

    function disableAll() {
      // Click "Turn off" / "Off" option in the menu if present
      try {
        var elems = document.querySelectorAll(
          '[role="option"], [role="menuitem"], .vjs-menu-item, .MuiMenuItem-root, li'
        );
        for (var i = 0; i < elems.length; i++) {
          var t = String(elems[i].textContent || '').toLowerCase();
          if (t === 'off' || /turn off/i.test(t) || /disable/i.test(t)) {
            elems[i].click();
            break;
          }
        }
      } catch (_) {}
      videos().forEach(function(video) {
        var tracks = video.textTracks || [];
        for (var i = 0; i < tracks.length; i++) {
          try { tracks[i].mode = 'disabled'; } catch (_) {}
        }
      });
    }

    // ── Message routing ──────────────────────────────────────────────────
    function forward(msg) {
      document.querySelectorAll('iframe').forEach(function(iframe) {
        try { iframe.contentWindow.postMessage(msg, '*'); } catch (_) {}
      });
    }

    function handle(message) {
      if (!message || message.__newmovieSubtitleBridge !== true) return;
      try {
        if (message.action === 'snapshot') {
          watch();
          snapshotViaMenu(function() { report(); });
        } else if (message.action === 'select') {
          var selected = applySelection(message.targetId || '', message.code || '', message.label || '');
          try {
            if (window.flutter_inappwebview && window.flutter_inappwebview.callHandler) {
              window.flutter_inappwebview.callHandler('subtitleSelectionResult', {
                requestId: message.requestId, selected: selected
              });
            }
          } catch (_) {}
          setTimeout(scheduleReport, 700);
        } else if (message.action === 'disable') {
          disableAll();
          try {
            if (window.flutter_inappwebview && window.flutter_inappwebview.callHandler) {
              window.flutter_inappwebview.callHandler('subtitleSelectionResult', {
                requestId: message.requestId, selected: true
              });
            }
          } catch (_) {}
          setTimeout(scheduleReport, 400);
        }
      } catch (_) {}
      forward(message);
    }

    window.__newmovieSubtitleBridge = {
      dispatch: function(action, targetId, requestId, code, label) {
        handle({ __newmovieSubtitleBridge: true, action: action,
                 targetId: targetId, requestId: requestId, code: code, label: label });
      }
    };

    window.addEventListener('message', function(event) {
      if (event.data && event.data.__newmovieSubtitleBridge) handle(event.data);
    });

    // ── MutationObserver ────────────────────────────────────────────────
    try {
      new MutationObserver(function() { watch(); }).observe(
        document.documentElement, { childList: true, subtree: true }
      );
    } catch (_) {}

    // ── Background polling (up to 60 s) ─────────────────────────────────
    // Runs every 2 s for up to MAX_SCANS iterations to catch VidFast tracks
    // that are attached long after the page loads.
    function periodicScan() {
      if (scanCount >= MAX_SCANS) return;
      scanCount++;
      watch();
      report();
      // Background discovery must not click CC or dismiss provider menus.
      // Menu interaction is reserved for an explicit subtitle-picker request.
      setTimeout(periodicScan, 2000);
    }
    // Initial fast scans, then switch to slow background polling
    [300, 800, 1500, 3000].forEach(function(ms) {
      setTimeout(function() { watch(); report(); }, ms);
    });
    setTimeout(periodicScan, 5000);

    watch();
    report();
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
  static const MethodChannel _playerDisplayChannel = MethodChannel(
    'newmovie/player_display',
  );

  InAppWebViewController? _webViewController;
  final AdService _adService = AdService();
  bool _isLoading = true;
  bool _hasError = false;
  bool _isNativeAdLoading = true;
  NativeAd? _nativeAd;
  final GlobalKey _nativeAdKey = GlobalKey();
  int _nativeAdGeneration = 0;
  double _loadingProgress = 0;
  final int _currentProviderIndex = 0;
  bool _hasInjectedAdProtection = false;
  bool _isChangingSubtitle = false;
  String? _selectedSubtitleId;
  final ValueNotifier<List<_AvailableSubtitle>> _availableSubtitles =
      ValueNotifier(const []);
  final Map<String, List<_AvailableSubtitle>> _subtitleFrames = {};
  final Map<String, Completer<bool>> _subtitleRequests = {};
  double? _lastPlaybackSeconds;
  int? _resumeAtSeconds;
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
    final baseUrl = _providers[_currentProviderIndex].buildUrl(
      widget.movieId,
      season: widget.season,
      episode: widget.episode,
      isTvShow: widget.isTvShow,
    );
    final uri = Uri.parse(baseUrl);
    final query = Map<String, String>.from(uri.queryParameters);
    if (_resumeAtSeconds != null && _resumeAtSeconds! > 0) {
      query['startAt'] = _resumeAtSeconds.toString();
    }
    return uri.replace(queryParameters: query).toString();
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
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    unawaited(_loadNativeAd());
  }

  Future<void> _loadNativeAd() async {
    final generation = ++_nativeAdGeneration;
    final ad = await _adService.acquireNativeAd();
    if (!mounted || generation != _nativeAdGeneration) {
      if (ad != null) unawaited(ad.dispose());
      return;
    }
    setState(() {
      _nativeAd = ad;
      _isNativeAdLoading = false;
    });
  }

  @override
  void dispose() {
    ++_nativeAdGeneration;
    _nativeAd?.dispose();
    _availableSubtitles.dispose();
    for (final request in _subtitleRequests.values) {
      if (!request.isCompleted) request.complete(false);
    }
    _subtitleRequests.clear();
    _playerDisplayChannel.invokeMethod<void>('setFullscreen', false);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<void> _reload() async {
    if (_lastPlaybackSeconds != null && _lastPlaybackSeconds! > 5) {
      _resumeAtSeconds = _lastPlaybackSeconds!.floor();
    }
    setState(() {
      _hasError = false;
      _isLoading = true;
      _loadingProgress = 0;
    });
    await _webViewController?.loadUrl(
      urlRequest: URLRequest(url: WebUri(_embedUrl)),
    );
  }

  // The custom subtitle picker is retained for the player bridge, but the
  // app-bar CC entry point has intentionally been removed.
  // ignore: unused_element
  Future<void> _showSubtitlePicker() async {
    final controller = _webViewController;
    if (controller == null || _isChangingSubtitle) return;

    // Trigger a snapshot + open CC menu to scrape live options.
    // We do NOT await — the ValueListenableBuilder in the sheet reacts live.
    unawaited(_refreshSubtitleInventory());

    if (!mounted) return;
    final selectedTrack = await showModalBottomSheet<_AvailableSubtitle>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => _SubtitlePickerSheet(
        availableSubtitles: _availableSubtitles,
        selectedSubtitleId: _selectedSubtitleId,
        onRefresh: _refreshSubtitleInventory,
      ),
    );
    if (selectedTrack != null) await _selectSubtitle(selectedTrack);
  }

  Future<void> _refreshSubtitleInventory() async {
    try {
      // Tell every frame (main + iframes) to open their CC menu,
      // wait for it to render, scrape options, and report back.
      await _webViewController?.evaluateJavascript(
        source:
            "window.__newmovieSubtitleBridge?.dispatch('snapshot', '', '', '', '');",
      );
      // Also broadcast to child iframes via postMessage
      await _webViewController?.evaluateJavascript(
        source: '''
          (function() {
            var msg = { __newmovieSubtitleBridge: true, action: 'snapshot',
                        targetId: '', requestId: '', code: '', label: '' };
            document.querySelectorAll('iframe').forEach(function(f) {
              try { f.contentWindow.postMessage(msg, '*'); } catch(_) {}
            });
          })();
        ''',
      );
    } catch (_) {}
  }

  Future<void> _selectSubtitle(_AvailableSubtitle track) async {
    final controller = _webViewController;
    if (controller == null || _isChangingSubtitle) return;
    setState(() => _isChangingSubtitle = true);
    final requestId = DateTime.now().microsecondsSinceEpoch.toString();
    final request = Completer<bool>();
    _subtitleRequests[requestId] = request;
    try {
      if (track.id == '__off__') {
        _selectedSubtitleId = null;
        await controller.evaluateJavascript(
          source:
              "window.__newmovieSubtitleBridge?.dispatch('disable', '', ${jsonEncode(requestId)}, '', '');",
        );
      } else {
        _selectedSubtitleId = track.id;
        await controller.evaluateJavascript(
          source:
              "window.__newmovieSubtitleBridge?.dispatch('select', ${jsonEncode(track.id)}, ${jsonEncode(requestId)}, ${jsonEncode(track.code)}, ${jsonEncode(track.label)});",
        );
      }
      final selected = await request.future.timeout(
        const Duration(seconds: 3),
        onTimeout: () => false,
      );
      if (!mounted || selected) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This subtitle could not be enabled.')),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not enable subtitles.')),
        );
      }
    } finally {
      _subtitleRequests.remove(requestId);
      if (mounted) setState(() => _isChangingSubtitle = false);
    }
  }

  void _receiveAvailableSubtitles(List<dynamic> args) {
    if (args.isEmpty || args.first is! Map || !mounted) return;
    final report = args.first as Map;
    final frameId = report['frameId'];
    final rawTracks = report['tracks'];
    if (frameId is! String || rawTracks is! List) return;
    final tracks = <_AvailableSubtitle>[];
    for (final rawTrack in rawTracks) {
      if (rawTrack is! Map) continue;
      final id = rawTrack['id'];
      final code = rawTrack['code'];
      final label = rawTrack['label'];
      final active = rawTrack['active'];
      if (id is! String || code is! String || label is! String) continue;
      tracks.add(
        _AvailableSubtitle(
          id: id,
          code: code,
          label: label,
          active: active == true,
        ),
      );
    }
    _subtitleFrames[frameId] = tracks;
    final availableByKey = <String, _AvailableSubtitle>{};
    for (final frameTracks in _subtitleFrames.values) {
      for (final track in frameTracks) {
        final key = '${track.code.toLowerCase()}|${track.label.toLowerCase()}';
        final previous = availableByKey[key];
        if (previous == null || (track.active && !previous.active)) {
          availableByKey[key] = track;
        }
      }
    }
    final available = availableByKey.values.toList();
    available.sort(
      (a, b) =>
          a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()),
    );
    _availableSubtitles.value = available;
    final activeTrack = available.where((track) => track.active).firstOrNull;
    if (_selectedSubtitleId != activeTrack?.id) {
      setState(() => _selectedSubtitleId = activeTrack?.id);
    }
  }

  Future<void> _enterPlayerFullscreen() async {
    if (_isPlayerFullscreen) return;
    if (mounted) {
      setState(() => _isPlayerFullscreen = true);
    }
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    try {
      await _playerDisplayChannel.invokeMethod<void>('setFullscreen', true);
    } catch (_) {
      // Android and the WebView's DOM fullscreen path use the CSS rule above.
    }
  }

  Future<void> _exitPlayerFullscreen() async {
    if (!_isPlayerFullscreen) return;
    if (mounted) {
      setState(() => _isPlayerFullscreen = false);
    }
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    try {
      await _playerDisplayChannel.invokeMethod<void>('setFullscreen', false);
    } catch (_) {
      // The channel is only implemented for iOS native video fullscreen.
    }
  }

  Future<void> _leaveWatchScreen() async {
    // Do not pop while the iOS scene is still in the player's landscape
    // geometry. A full-screen ad shown on the next page could inherit it.
    await _exitPlayerFullscreen();
    if (mounted) Navigator.of(context).pop();
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
        s.textContent = `$_adHidingCss`;

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
        if (!window.__playerPopupProtectionInstalled) {
          try { window.open = function() { return null; }; } catch (e) {}
        }

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
                    var isAllowed = h.includes('vidfast.vc') ||
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

        // Do not remove elements based on size, transparency, or z-index.
        // Player settings/CC portals use the same layout as ad overlays.
        // Known ad selectors and blocked domains provide targeted filtering.
        cleanupServerBar();
        if (!window.__playerAdCleanupTimer) {
          window.__playerAdCleanupTimer = setInterval(function() {
            cleanupServerBar();
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

  Widget _buildNativeAdPanel() {
    final nativeAd = _nativeAd;
    return NativeAdPanel(
      child: nativeAd != null
          ? AdWidget(key: _nativeAdKey, ad: nativeAd)
          : Center(
              child: _isNativeAdLoading
                  ? const CircularProgressIndicator(color: Color(0xFFE50914))
                  : const Text(
                      'Ad unavailable',
                      style: TextStyle(color: Colors.white54),
                    ),
            ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isPlayerFullscreen,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) await _leaveWatchScreen();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: _isPlayerFullscreen
            ? null
            : AppBar(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                elevation: 0,
                titleSpacing: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                  onPressed: _leaveWatchScreen,
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
                    icon: const Icon(Icons.fullscreen_rounded, size: 24),
                    tooltip: 'Fullscreen',
                    onPressed: _enterPlayerFullscreen,
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
        body: LayoutBuilder(
          builder: (context, constraints) {
            final player = Stack(
              fit: StackFit.expand,
              children: [
                // ── WebView ────────────────────────────────────────────────
                if (!_hasError)
                  InAppWebView(
                    initialUrlRequest: URLRequest(url: WebUri(_embedUrl)),
                    initialUserScripts: UnmodifiableListView([
                      UserScript(
                        groupName: 'player-popup-protection',
                        source: _documentStartAdBlockScript,
                        injectionTime:
                            UserScriptInjectionTime.AT_DOCUMENT_START,
                        forMainFrameOnly: false,
                      ),
                      UserScript(
                        groupName: 'landscape-fullscreen-fill',
                        source: _documentStartFullscreenFillScript,
                        injectionTime:
                            UserScriptInjectionTime.AT_DOCUMENT_START,
                        forMainFrameOnly: false,
                      ),
                      UserScript(
                        groupName: 'player-progress',
                        source: _documentStartPlayerProgressScript,
                        injectionTime:
                            UserScriptInjectionTime.AT_DOCUMENT_START,
                        forMainFrameOnly: false,
                      ),
                      UserScript(
                        groupName: 'available-subtitles',
                        source: _documentStartSubtitleBridgeScript,
                        injectionTime:
                            UserScriptInjectionTime.AT_DOCUMENT_START,
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
                      mixedContentMode:
                          MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
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
                        handlerName: 'requestPlayerFullscreen',
                        callback: (args) {
                          final fullscreen =
                              args.isNotEmpty && args.first == true;
                          if (fullscreen) {
                            unawaited(_enterPlayerFullscreen());
                          } else {
                            unawaited(_exitPlayerFullscreen());
                          }
                          return null;
                        },
                      );
                      controller.addJavaScriptHandler(
                        handlerName: 'playerProgress',
                        callback: (args) {
                          final progress = args.isNotEmpty ? args.first : null;
                          if (progress is num &&
                              progress.isFinite &&
                              progress >= 0) {
                            _lastPlaybackSeconds = progress.toDouble();
                          }
                          return null;
                        },
                      );
                      controller.addJavaScriptHandler(
                        handlerName: 'availableSubtitles',
                        callback: (args) {
                          _receiveAvailableSubtitles(args);
                          return null;
                        },
                      );
                      controller.addJavaScriptHandler(
                        handlerName: 'subtitleSelectionResult',
                        callback: (args) {
                          if (args.isNotEmpty && args.first is Map) {
                            final result = args.first as Map;
                            final requestId = result['requestId'];
                            final selected = result['selected'];
                            if (requestId is String && selected == true) {
                              final request = _subtitleRequests[requestId];
                              if (request != null && !request.isCompleted) {
                                request.complete(true);
                              }
                            }
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
                        _selectedSubtitleId = null;
                      });
                      _subtitleFrames.clear();
                      _availableSubtitles.value = const [];
                    },
                    onProgressChanged: (controller, progress) {
                      if (!mounted) return;
                      setState(() {
                        _loadingProgress = progress / 100.0;
                        if (progress >= 100) {
                          _isLoading = false;
                          _isChangingSubtitle = false;
                        }
                      });
                      if (progress > 30) {
                        _injectAdBlockCss();
                      }
                    },
                    onLoadStop: (controller, url) async {
                      if (!mounted) return;
                      setState(() {
                        _isLoading = false;
                        _isChangingSubtitle = false;
                      });
                      // Inject CSS to hide any remaining ad overlays
                      await _injectAdBlockCss();
                    },
                    onReceivedError: (controller, request, error) {
                      if (request.isForMainFrame == true && mounted) {
                        setState(() {
                          _isLoading = false;
                          _hasError = true;
                          _isChangingSubtitle = false;
                        });
                      }
                    },
                    onConsoleMessage: (controller, consoleMessage) {
                      if (kDebugMode) {
                        debugPrint(
                          '[WebViewConsole ${consoleMessage.messageLevel}] ${consoleMessage.message}',
                        );
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

                      // Block known malicious / betting / popup ad networks
                      if (urlString.contains('melbet') ||
                          urlString.contains('1xbet') ||
                          urlString.contains('casino') ||
                          urlString.contains('bet365') ||
                          urlString.contains('adclick') ||
                          urlString.contains('popunder') ||
                          urlString.contains('onclickads') ||
                          urlString.contains('popcash') ||
                          urlString.contains('popads')) {
                        return NavigationActionPolicy.CANCEL;
                      }

                      // Allowed streaming & CDN domains
                      const allowedDomains = [
                        'vidfast.vc',
                        'nxsha.app',
                        'febbox.com',
                        'fshair.com',
                        'themoviedb.org',
                        'tmdb.org',
                        'cloudflare.com',
                        'flagsapi.com',
                        'opensubtitles.org',
                        'opensubtitles.com',
                        'jsdelivr.net',
                        'cdnjs.cloudflare.com',
                        'fastly.net',
                        'cloudfront.net',
                        'google.com',
                        'gstatic.com',
                        'googleapis.com',
                        'akamaihd.net',
                      ];

                      // Only restrict main-frame navigation to prevent external site redirects.
                      // Subresources, iframes, and subtitle streams must be allowed to load.
                      if (navigationAction.isForMainFrame == true) {
                        final isAllowed = allowedDomains.any(
                          (d) => host == d || host.endsWith('.$d'),
                        );
                        if (!isAllowed) {
                          return NavigationActionPolicy.CANCEL;
                        }
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
                              color: const Color(
                                0xFFE50914,
                              ).withValues(alpha: 0.12),
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
                            'Check your connection and try again.',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _reload,
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Retry'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE50914),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
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
                                value: _loadingProgress > 0
                                    ? _loadingProgress
                                    : null,
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
            );

            return Column(
              children: [
                Expanded(child: player),
                Flexible(
                  flex: _isPlayerFullscreen ? 0 : 1,
                  fit: FlexFit.tight,
                  child: Offstage(
                    offstage: _isPlayerFullscreen,
                    child: _buildNativeAdPanel(),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ── Subtitle picker bottom sheet ──────────────────────────────────────────────
// A self-contained StatefulWidget so it can own its own auto-refresh Timer.
class _SubtitlePickerSheet extends StatefulWidget {
  final ValueNotifier<List<_AvailableSubtitle>> availableSubtitles;
  final String? selectedSubtitleId;
  final Future<void> Function() onRefresh;

  const _SubtitlePickerSheet({
    required this.availableSubtitles,
    required this.selectedSubtitleId,
    required this.onRefresh,
  });

  @override
  State<_SubtitlePickerSheet> createState() => _SubtitlePickerSheetState();
}

class _SubtitlePickerSheetState extends State<_SubtitlePickerSheet> {
  Timer? _autoRefreshTimer;
  // Track the "Off" tile – the selected track is passed in at open time
  // and updated live from the ValueNotifier.
  static const _offTrack = _AvailableSubtitle(
    id: '__off__',
    code: 'off',
    label: 'Off',
    active: false,
  );

  @override
  void initState() {
    super.initState();
    // Auto-refresh the subtitle inventory every 2.5 s while the sheet is open.
    _autoRefreshTimer = Timer.periodic(const Duration(milliseconds: 2500), (_) {
      widget.onRefresh();
    });
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ValueListenableBuilder<List<_AvailableSubtitle>>(
        valueListenable: widget.availableSubtitles,
        builder: (context, tracks, _) {
          return SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.65,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ──────────────────────────────────────────────
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Subtitles (CC)',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (tracks.isEmpty)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFFE50914),
                          ),
                        ),
                      IconButton(
                        onPressed: widget.onRefresh,
                        tooltip: 'Refresh subtitle languages',
                        icon: const Icon(Icons.refresh_rounded),
                        color: Colors.white,
                      ),
                    ],
                  ),
                  Text(
                    tracks.isEmpty
                        ? 'Searching for subtitles… tap ↻ if this takes too long'
                        : '${tracks.length} language${tracks.length == 1 ? '' : 's'} available',
                    style: const TextStyle(color: Colors.white60, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  // ── Track list ──────────────────────────────────────────
                  Expanded(
                    child: ListView.separated(
                      itemCount: tracks.length + 1,
                      separatorBuilder: (_, _) =>
                          const Divider(color: Colors.white12, height: 1),
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          // "Off" row
                          final isOff = !tracks.any(
                            (t) =>
                                t.active || t.id == widget.selectedSubtitleId,
                          );
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(
                              Icons.subtitles_off_rounded,
                              color: isOff
                                  ? const Color(0xFFE50914)
                                  : Colors.white60,
                            ),
                            title: const Text(
                              'Off',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: const Text(
                              'Turn off subtitles',
                              style: TextStyle(color: Colors.white54),
                            ),
                            trailing: isOff
                                ? const Icon(
                                    Icons.check,
                                    color: Color(0xFFE50914),
                                  )
                                : null,
                            onTap: () => Navigator.of(context).pop(_offTrack),
                          );
                        }
                        final track = tracks[index - 1];
                        final selected =
                            track.active ||
                            track.id == widget.selectedSubtitleId;
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            Icons.closed_caption_rounded,
                            color: selected
                                ? const Color(0xFFE50914)
                                : Colors.white60,
                          ),
                          title: Text(
                            track.displayName,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                          subtitle: track.label == track.displayName
                              ? null
                              : Text(
                                  track.label,
                                  style: const TextStyle(color: Colors.white54),
                                ),
                          trailing: selected
                              ? const Icon(
                                  Icons.check,
                                  color: Color(0xFFE50914),
                                )
                              : null,
                          onTap: () => Navigator.of(context).pop(track),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
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
