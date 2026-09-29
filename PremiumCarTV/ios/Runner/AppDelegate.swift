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
    // CarPlay sahnesi Dart'taki içerik kataloğuna bu kanaldan ulaşır.
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "OtoCarPlay") {
      CarPlayBridge.shared.attach(messenger: registrar.messenger())
    }
  }
}
