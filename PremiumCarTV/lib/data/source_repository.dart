import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'app_error.dart';
import 'm3u_parser.dart';
import 'models.dart';

/// Kaynakların kalıcı saklanması ve içeriklerinin indirilmesi.
/// Her şey cihazda kalır; hiçbir veri kendi sunucumuza gitmez.
class SourceRepository {
  SourceRepository(this._prefs, {http.Client? client})
      : _client = client ?? http.Client();

  final SharedPreferences _prefs;
  final http.Client _client;
  static const _sourcesKey = 'sources.v1';
  static const _cachePrefix = 'm3u.cache.';
  static const _epgPrefix = 'm3u.epg.';

  /// Listenin başlığında tanımlı rehber adresleri (son başarılı indirmeden).
  List<String> epgUrls(String sourceId) =>
      _prefs.getStringList('$_epgPrefix$sourceId') ?? const [];

  List<MediaSource> loadSources() {
    final raw = _prefs.getString(_sourcesKey);
    if (raw == null) return [];
    try {
      return MediaSource.decodeList(raw);
    } catch (_) {
      return [];
    }
  }

  Future<void> saveSources(List<MediaSource> sources) =>
      _prefs.setString(_sourcesKey, MediaSource.encodeList(sources));

  /// Önce ağdan dener; başarısız olursa son başarılı kopyayı kullanır.
  Future<List<Channel>> fetchChannels(MediaSource source,
      {bool forceRefresh = false}) async {
    final cacheKey = '$_cachePrefix${source.id}';
    try {
      final body = await _download(source.url);
      final channels = const M3uParser().parse(body);
      if (channels.isEmpty) {
        throw const AppException(AppErrorCode.noPlayable);
      }
      await _prefs.setString(cacheKey, body);
      await _prefs.setStringList('$_epgPrefix${source.id}', M3uParser.epgUrls(body));
      return [for (final c in channels) c.withSource(source.id)];
    } catch (e) {
      final cached = forceRefresh ? null : _prefs.getString(cacheKey);
      if (cached != null) {
        return [
          for (final c in const M3uParser().parse(cached)) c.withSource(source.id)
        ];
      }
      if (e is AppException) rethrow;
      throw const AppException(AppErrorCode.download);
    }
  }

  Future<void> clearCache(String sourceId) async {
    await _prefs.remove('$_cachePrefix$sourceId');
    await _prefs.remove('$_epgPrefix$sourceId');
  }

  Future<String> _download(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) {
      throw const AppException(AppErrorCode.invalidAddress);
    }
    final res = await _client
        .get(uri, headers: {'User-Agent': 'OtoTV/1.0'})
        .timeout(const Duration(seconds: 25));
    if (res.statusCode != 200) {
      throw AppException(AppErrorCode.httpStatus, status: res.statusCode);
    }
    // Çoğu IPTV sunucusu charset belirtmez; UTF-8 varsayıp bozuk baytları tolere et.
    return utf8.decode(res.bodyBytes, allowMalformed: true);
  }
}
