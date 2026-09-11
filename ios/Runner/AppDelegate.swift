import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let orientationChannel = FlutterMethodChannel(
      name: "newmovie/player_orientation",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    orientationChannel.setMethodCallHandler { [weak self] call, result in
      switch call.method {
      case "landscape":
        self?.requestOrientation(landscape: true)
        result(nil)
      case "portrait":
        self?.requestOrientation(landscape: false)
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func requestOrientation(landscape: Bool) {
    DispatchQueue.main.async { [weak self] in
      let orientationMask: UIInterfaceOrientationMask = landscape ? .landscape : .portrait

      if #available(iOS 16.0, *), let windowScene = self?.window?.windowScene {
        let preferences = UIWindowScene.GeometryPreferences.iOS(
          interfaceOrientations: orientationMask
        )
        windowScene.requestGeometryUpdate(preferences) { error in
          NSLog("Could not update player orientation: \(error.localizedDescription)")
        }
        self?.window?.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
      } else {
        let orientation: UIInterfaceOrientation = landscape ? .landscapeRight : .portrait
        UIDevice.current.setValue(orientation.rawValue, forKey: "orientation")
        UIViewController.attemptRotationToDeviceOrientation()
      }
    }
  }
}
