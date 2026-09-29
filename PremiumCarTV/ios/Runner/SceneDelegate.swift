import CarPlay
import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {

}

// MARK: - CarPlay

/// Dart tarafındaki CarCatalog ile konuşan kanal (lib/platform/carplay_bridge.dart).
final class CarPlayBridge {
  static let shared = CarPlayBridge()

  private var channel: FlutterMethodChannel?
  private var readyHandlers: [() -> Void] = []

  /// CarPlay ekranı şu an bağlı mı (Araca Yansıt sekmesi bunu gösterir).
  private(set) var carConnected = false

  func setCarConnected(_ connected: Bool) {
    carConnected = connected
    channel?.invokeMethod("carConnected", arguments: connected)
  }

  var isReady: Bool { channel != nil }

  func attach(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "ototv/carplay", binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      if call.method == "ready" {
        self?.readyHandlers.forEach { $0() }
        result(nil)
      } else if call.method == "isCarConnected" {
        result(self?.carConnected ?? false)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
    self.channel = channel
  }

  /// Dart hazır olduğunda (ör. uygulama doğrudan CarPlay'den açıldıysa) çağrılır.
  func onReady(_ handler: @escaping () -> Void) {
    readyHandlers.append(handler)
  }

  func children(of id: String, completion: @escaping ([[String: Any]]) -> Void) {
    guard let channel else { return completion([]) }
    channel.invokeMethod("children", arguments: id) { result in
      completion((result as? [[String: Any]]) ?? [])
    }
  }

  func play(_ id: String, completion: @escaping (Bool) -> Void) {
    guard let channel else { return completion(false) }
    channel.invokeMethod("play", arguments: id) { result in
      completion((result as? Bool) ?? false)
    }
  }
}

/// CarPlay ses uygulaması arayüzü: sekmeler (Favoriler, Kanallar, İzlemeye
/// devam et) → listeler → Şimdi Oynatılıyor. Şimdi Oynatılıyor ekranını iOS,
/// audio_service'in doldurduğu MPNowPlayingInfoCenter bilgisinden çizer.
///
/// Not: Bu sahnenin araçta açılması için Apple'ın CarPlay Audio iznini
/// (com.apple.developer.carplay-audio) onaylaması gerekir; bkz. Runner.entitlements.
class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {
  private var interfaceController: CPInterfaceController?
  private let images = NSCache<NSString, UIImage>()

  func templateApplicationScene(
    _ templateApplicationScene: CPTemplateApplicationScene,
    didConnect interfaceController: CPInterfaceController
  ) {
    self.interfaceController = interfaceController
    CarPlayBridge.shared.setCarConnected(true)
    CarPlayBridge.shared.onReady { [weak self] in self?.loadRoot() }
    loadRoot()
  }

  func templateApplicationScene(
    _ templateApplicationScene: CPTemplateApplicationScene,
    didDisconnectInterfaceController interfaceController: CPInterfaceController
  ) {
    self.interfaceController = nil
    CarPlayBridge.shared.setCarConnected(false)
  }

  private func loadRoot() {
    guard let controller = interfaceController else { return }
    guard CarPlayBridge.shared.isReady else {
      let waiting = CPListTemplate(title: "OtoTV", sections: [
        CPListSection(items: [CPListItem(text: "OtoTV", detailText: "…")]),
      ])
      controller.setRootTemplate(waiting, animated: false, completion: nil)
      return
    }
    CarPlayBridge.shared.children(of: "root") { [weak self] nodes in
      guard let self else { return }
      let folders = nodes.filter { !($0["playable"] as? Bool ?? false) && ($0["id"] as? String) != "empty" }
      if folders.isEmpty {
        let list = self.makeList(title: "OtoTV", nodes: nodes)
        controller.setRootTemplate(list, animated: false, completion: nil)
        return
      }
      let icons = ["heart.fill", "tv.fill", "play.circle.fill", "play.circle.fill"]
      let tabs: [CPTemplate] = folders.prefix(CPTabBarTemplate.maximumTabCount).enumerated().map { index, node in
        let title = node["title"] as? String ?? ""
        let list = CPListTemplate(title: title, sections: [])
        list.tabTitle = title
        list.tabImage = UIImage(systemName: icons[min(index, icons.count - 1)])
        self.fill(list, id: node["id"] as? String ?? "root")
        return list
      }
      controller.setRootTemplate(CPTabBarTemplate(templates: tabs), animated: false, completion: nil)
    }
  }

  private func fill(_ list: CPListTemplate, id: String) {
    CarPlayBridge.shared.children(of: id) { [weak self] nodes in
      guard let self else { return }
      list.updateSections([CPListSection(items: nodes.map(self.makeItem))])
    }
  }

  private func makeList(title: String, nodes: [[String: Any]]) -> CPListTemplate {
    CPListTemplate(title: title, sections: [CPListSection(items: nodes.map(makeItem))])
  }

  private func makeItem(_ node: [String: Any]) -> CPListItem {
    let id = node["id"] as? String ?? ""
    let title = node["title"] as? String ?? ""
    let playable = node["playable"] as? Bool ?? false
    let item = CPListItem(text: title, detailText: node["subtitle"] as? String)
    if !playable && id != "empty" {
      item.accessoryType = .disclosureIndicator
    }
    if let art = node["artUri"] as? String { loadImage(art, into: item) }

    item.handler = { [weak self] _, completion in
      guard let self, let controller = self.interfaceController, id != "empty" else { return completion() }
      if playable {
        CarPlayBridge.shared.play(id) { _ in
          controller.pushTemplate(CPNowPlayingTemplate.shared, animated: true, completion: nil)
          completion()
        }
      } else {
        let list = CPListTemplate(title: title, sections: [])
        self.fill(list, id: id)
        controller.pushTemplate(list, animated: true, completion: nil)
        completion()
      }
    }
    return item
  }

  private func loadImage(_ url: String, into item: CPListItem) {
    if let cached = images.object(forKey: url as NSString) {
      item.setImage(cached)
      return
    }
    guard let u = URL(string: url) else { return }
    URLSession.shared.dataTask(with: u) { [weak self] data, _, _ in
      guard let data, let image = UIImage(data: data) else { return }
      DispatchQueue.main.async {
        self?.images.setObject(image, forKey: url as NSString)
        item.setImage(image)
      }
    }.resume()
  }
}
