import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'carplay_bridge.dart';

/// Telefonun bağlı olduğu araç ekranı.
enum CarLink {
  none,

  /// Telefon Android Auto'ya bağlı; OtoTV telefon ekranında.
  androidAuto,

  /// OtoTV, Android Auto park uygulaması olarak ARAÇ EKRANINDA çalışıyor.
  /// Android Auto yalnızca park halindeyken izin verir, sürüşte kapatır.
  androidAutoDisplay,

  /// Aracın kendi Android sistemi (Android Automotive OS).
  automotive,

  /// iPhone, CarPlay ile bağlı.
  carPlay;

  bool get isConnected => this != none;
  bool get isAndroidAuto => this == androidAuto || this == androidAutoDisplay;
}

/// Android: androidx.car.app CarConnection (MainActivity.kt).
/// iOS: CarPlay sahnesinin bağlanıp kopması (SceneDelegate.swift).
final carLinkProvider = StreamProvider<CarLink>((ref) {
  if (Platform.isAndroid) {
    return const EventChannel('ototv/car_connection').receiveBroadcastStream().map(
          (type) => switch (type) {
            3 => CarLink.androidAutoDisplay,
            2 => CarLink.androidAuto,
            1 => CarLink.automotive,
            _ => CarLink.none,
          },
        );
  }
  if (Platform.isIOS) {
    return CarPlayBridge.connection.map((c) => c ? CarLink.carPlay : CarLink.none);
  }
  return Stream.value(CarLink.none);
});
