import 'dart:io';

import 'package:flutter/services.dart';

import '../data/models.dart';

/// iOS: videoyu Apple'ın oynatıcısında (AVPlayer) açar; oradaki AirPlay
/// düğmesiyle CarPlay ekranına (iOS 26+, park halinde, destekleyen araçlar),
/// Apple TV'ye ya da AirPlay TV'ye gönderilir. Park halinde olup olmadığını
/// iOS ve araç denetler. Yerel taraf: ios/Runner/SceneDelegate.swift › AirPlayBridge.
abstract final class AirPlay {
  static const _channel = MethodChannel('ototv/airplay');

  static bool get isSupported => Platform.isIOS;

  /// Oynatır; kullanıcı Apple oynatıcısını kapatınca kaldığı konumu döndürür
  /// (canlı yayında ya da hata durumunda null).
  static Future<Duration?> play(Channel channel, {Duration? start}) async {
    final seconds = await _channel.invokeMethod<double>('play', {
      'url': channel.airplayUrl ?? channel.url,
      'headers': channel.httpHeaders,
      'title': channel.name,
      'subtitle': channel.group,
      'start': (start?.inMilliseconds ?? 0) / 1000,
    });
    if (seconds == null || seconds <= 0 || seconds.isNaN) return null;
    return Duration(milliseconds: (seconds * 1000).round());
  }
}
