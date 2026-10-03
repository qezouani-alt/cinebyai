# iOS development

This app targets iPhone and iPad with bundle identifier `com.cine.by`.
Swift Package Manager remains disabled in `pubspec.yaml`; iOS plugins use CocoaPods.

## Local configuration

Copy `config/ios.example.json` to `config/ios.local.json` and fill in the values
locally. The local file is excluded from Git.

- `GEMINI_API_KEY`: a working Gemini key for development. The previously embedded
  key was blocked by Google after being reported as leaked. Replacing or
  restarting the app cannot unblock that key; generate a replacement in Google
  AI Studio. An empty key uses the app's movie-data fallbacks without calling
  Gemini.

Run on an iOS device/simulator:

```sh
flutter pub get
flutter run --dart-define-from-file=config/ios.local.json
```

Build an iOS archive after configuring production services and signing:

```sh
flutter build ipa --dart-define-from-file=config/ios.local.json
```

`--dart-define` keeps a key out of source files, but does **not** make a key secret
inside a distributed app. Production Gemini requests need a backend that holds
the key and authenticates/rate-limits app requests. No backend is included or
deployed by this audit. Do not distribute a production Gemini key in an IPA.

Google documents the blocked-key response and required replacement here:
[Gemini API troubleshooting](https://ai.google.dev/gemini-api/docs/troubleshooting#api-keys).

## Verification

```sh
flutter analyze
flutter test --concurrency=1
flutter build ios --simulator --debug
```

Automated tests mock external APIs and native ad/notification callbacks. Device
checks are still required for ATT prompts, live AdMob inventory, notification
delivery, and playback of remote video sources.

The Outfit font and its open-source license are bundled in `assets/fonts` so
launch and settings typography work without downloading a font at runtime.
