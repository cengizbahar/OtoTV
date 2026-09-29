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
  static final _connected = StreamController<bool>.broadcast();

  /// CarPlay ekranının bağlanıp kopması (yalnızca iOS).
  static Stream<bool> get connection async* {
    yield await _channel.invokeMethod<bool>('isCarConnected').catchError((_) => false) ?? false;
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
          _connected.add(call.arguments as bool? ?? false);
          return null;
        default:
          throw MissingPluginException(call.method);
      }
    });
    // Dart hazır: CarPlay sahnesi önceden bağlandıysa listesini yenilesin.
    _channel.invokeMethod<void>('ready').catchError((_) {});
  }
}
