import Flutter
import GoogleMobileAds
import UIKit
import UserNotifications
import AVKit
import google_mobile_ads

private final class NewMovieNativeAdFactory: NSObject, FLTNativeAdFactory {
  private let mediaHeight: CGFloat = 180

  func createNativeAd(
    _ nativeAd: NativeAd,
    customOptions: [AnyHashable: Any]?
  ) -> NativeAdView? {
    let adView = NativeAdView()
    adView.backgroundColor = UIColor(red: 0.10, green: 0.10, blue: 0.10, alpha: 1)
    adView.layer.cornerRadius = 14
    adView.clipsToBounds = true

    let stack = UIStackView()
    stack.axis = .vertical
    stack.spacing = 8
    stack.translatesAutoresizingMaskIntoConstraints = false

    let headlineLabel = UILabel()
    headlineLabel.font = .systemFont(ofSize: 16, weight: .bold)
    headlineLabel.textColor = .white
    headlineLabel.numberOfLines = 2
    headlineLabel.text = nativeAd.headline

    let mediaView = MediaView()
    mediaView.translatesAutoresizingMaskIntoConstraints = false
    mediaView.backgroundColor = UIColor(white: 0.16, alpha: 1)
    mediaView.contentMode = .scaleAspectFit
    mediaView.layer.cornerRadius = 10
    mediaView.clipsToBounds = true
    mediaView.mediaContent = nativeAd.mediaContent

    let bodyLabel = UILabel()
    bodyLabel.font = .systemFont(ofSize: 13)
    bodyLabel.textColor = UIColor(white: 0.8, alpha: 1)
    bodyLabel.numberOfLines = 2
    bodyLabel.text = nativeAd.body
    bodyLabel.isHidden = nativeAd.body == nil

    let callToActionButton = UIButton(type: .system)
    callToActionButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .bold)
    callToActionButton.setTitle(nativeAd.callToAction, for: .normal)
    callToActionButton.setTitleColor(.black, for: .normal)
    callToActionButton.backgroundColor = .white
    callToActionButton.layer.cornerRadius = 8
    callToActionButton.isUserInteractionEnabled = false
    callToActionButton.isHidden = nativeAd.callToAction == nil

    stack.addArrangedSubview(headlineLabel)
    stack.addArrangedSubview(mediaView)
    stack.addArrangedSubview(bodyLabel)
    stack.addArrangedSubview(callToActionButton)
    adView.addSubview(stack)

    NSLayoutConstraint.activate([
      stack.topAnchor.constraint(equalTo: adView.topAnchor, constant: 12),
      stack.leadingAnchor.constraint(equalTo: adView.leadingAnchor, constant: 12),
      stack.trailingAnchor.constraint(equalTo: adView.trailingAnchor, constant: -12),
      stack.bottomAnchor.constraint(lessThanOrEqualTo: adView.bottomAnchor, constant: -12),
      mediaView.heightAnchor.constraint(equalToConstant: mediaHeight),
      callToActionButton.heightAnchor.constraint(equalToConstant: 44),
    ])

    adView.headlineView = headlineLabel
    adView.mediaView = mediaView
    adView.bodyView = bodyLabel
    adView.callToActionView = callToActionButton
    adView.nativeAd = nativeAd
    return adView
  }
}

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let nativeAdFactory = NewMovieNativeAdFactory()
  private var isPlayerFullscreen = false
  private var videoWindowObserver: NSObjectProtocol?
  private var orientationObserver: NSObjectProtocol?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    UNUserNotificationCenter.current().delegate = self
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Full-screen Google ads are UIKit controllers and consult the application
  // orientation mask. Allow landscape only for the video player itself; every
  // ad is therefore constrained to a vertical presentation.
  override func application(
    _ application: UIApplication,
    supportedInterfaceOrientationsFor window: UIWindow?
  ) -> UIInterfaceOrientationMask {
    isPlayerFullscreen
      ? [.landscapeLeft, .landscapeRight]
      : .portrait
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    FLTGoogleMobileAdsPlugin.registerNativeAdFactory(
      engineBridge.pluginRegistry,
      factoryId: "newmovieNativeAd",
      nativeAdFactory: nativeAdFactory
    )

    let playerDisplayChannel = FlutterMethodChannel(
      name: "newmovie/player_display",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    playerDisplayChannel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "setFullscreen", let fullscreen = call.arguments as? Bool else {
        result(FlutterMethodNotImplemented)
        return
      }
      DispatchQueue.main.async {
        self?.isPlayerFullscreen = fullscreen
        self?.scheduleVideoGravityUpdate()
        result(nil)
      }
    }

    let adDisplayChannel = FlutterMethodChannel(
      name: "newmovie/ad_display",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    adDisplayChannel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "preparePortrait" else {
        result(FlutterMethodNotImplemented)
        return
      }
      DispatchQueue.main.async {
        self?.preparePortraitForAd(completion: result)
      }
    }

    if videoWindowObserver == nil {
      videoWindowObserver = NotificationCenter.default.addObserver(
        forName: UIWindow.didBecomeVisibleNotification,
        object: nil,
        queue: .main
      ) { [weak self] _ in
        self?.scheduleVideoGravityUpdate()
      }
    }
    if orientationObserver == nil {
      orientationObserver = NotificationCenter.default.addObserver(
        forName: UIDevice.orientationDidChangeNotification,
        object: nil,
        queue: .main
      ) { [weak self] _ in
        self?.scheduleVideoGravityUpdate()
      }
    }
  }

  private func scheduleVideoGravityUpdate() {
    updateVideoGravity()
    // WKWebView can present its video window after the Flutter callback.
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
      self?.updateVideoGravity()
    }
  }

  /// Google full-screen ads are presented by UIKit, outside Flutter's widget
  /// tree. Explicitly settle the active scene in portrait before presenting an
  /// ad so it cannot inherit a just-dismissed landscape player geometry.
  private func preparePortraitForAd(completion: @escaping FlutterResult) {
    // Set this before UIKit queries our supportedInterfaceOrientationsFor
    // mask while constructing the Google ad's presentation controller.
    isPlayerFullscreen = false
    scheduleVideoGravityUpdate()

    let scenes = UIApplication.shared.connectedScenes.compactMap {
      $0 as? UIWindowScene
    }.filter { $0.activationState == .foregroundActive }

    guard let scene = scenes.first else {
      completion(nil)
      return
    }

    if #available(iOS 16.0, *) {
      scene.windows.forEach {
        $0.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
      }
      let preferences = UIWindowScene.GeometryPreferences.iOS(
        interfaceOrientations: .portrait
      )
      var didComplete = false
      func finish() {
        guard !didComplete else { return }
        didComplete = true
        completion(nil)
      }
      scene.requestGeometryUpdate(preferences) { _ in
        // Flutter's SystemChrome request remains the fallback if UIKit refuses
        // a geometry update during a transition.
        finish()
      }
      // UIKit's completion handler is invoked only for a failed geometry
      // request. A successful request has no callback, so always release the
      // Dart caller after the scene has had a chance to process it.
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
        finish()
      }
    } else {
      completion(nil)
    }
  }

  private func updateVideoGravity() {
    let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
    let isLandscape = UIDevice.current.orientation.isLandscape ||
      scenes.contains { $0.interfaceOrientation.isLandscape }
    let gravity: AVLayerVideoGravity = isPlayerFullscreen && isLandscape
      ? .resizeAspectFill : .resizeAspect

    for scene in scenes where scene.activationState == .foregroundActive {
      for window in scene.windows where !window.isHidden {
        updatePlayerControllers(in: window.rootViewController, gravity: gravity)
        updatePlayerLayers(in: window.layer, gravity: gravity)
      }
    }
  }

  private func updatePlayerControllers(
    in controller: UIViewController?, gravity: AVLayerVideoGravity
  ) {
    guard let controller else { return }
    if let player = controller as? AVPlayerViewController {
      player.videoGravity = gravity
    }
    for child in controller.children {
      updatePlayerControllers(in: child, gravity: gravity)
    }
    updatePlayerControllers(in: controller.presentedViewController, gravity: gravity)
  }

  private func updatePlayerLayers(in layer: CALayer, gravity: AVLayerVideoGravity) {
    if let playerLayer = layer as? AVPlayerLayer {
      playerLayer.videoGravity = gravity
    }
    for sublayer in layer.sublayers ?? [] {
      updatePlayerLayers(in: sublayer, gravity: gravity)
    }
  }
}
