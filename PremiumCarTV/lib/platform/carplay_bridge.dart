import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

import '../state/car_catalog.dart';

/// iOS CarPlay ekranı ile Dart arasındaki köprü.
///
/// CarPlay arayüzü yerel (Swift, `SceneDelegate.swift` → CarPlaySceneDelegate)
/// şablonlarla çizilir; içerik listesi ve oynatma bu kanal üzerinden
/// [CarCatalog]'tan gelir. Android Auto aynı kataloğu audio_service ile kullanır.
abstract final class CarPlayBridge {
  static const _channel = MethodChannel('ototv/carplay');
  static final _connected = StreamController<int>.broadcast();

  /// CarPlay durumu (yalnızca iOS): 0 bağlı değil · 1 yalnızca ses CarPlay'de ·
  /// 2 OtoTV'nin CarPlay ekranı açık (Apple CarPlay izni gerekir).
  static Stream<int> get connection async* {
    yield await _channel.invokeMethod<int>('isCarConnected').catchError((_) => 0) ?? 0;
    yield* _connected.stream;
  }

  static void attach(CarCatalog catalog) {
    if (!Platform.isIOS) return;
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'children':
          final nodes = await catalog.children(call.arguments as String? ?? CarCatalog.root);
          return [for (final n in nodes) n.toMap()];
        case 'play':
          return catalog.play(call.arguments as String);
        case 'carConnected':
          _connected.add(call.arguments as int? ?? 0);
          return null;
        default:
          throw MissingPluginException(call.method);
      }
    });
    // Dart hazır: CarPlay sahnesi önceden bağlandıysa listesini yenilesin.
    _channel.invokeMethod<void>('ready').catchError((_) {});
  }
}
