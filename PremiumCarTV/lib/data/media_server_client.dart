import 'dart:convert';

import 'package:http/http.dart' as http;

import 'app_error.dart';
import 'models.dart';

/// Jellyfin / Emby öğesi (kitaplık, film, dizi, sezon veya bölüm).
class ServerItem {
  const ServerItem({
    required this.id,
    required this.name,
    required this.type,
    this.collectionType,
    this.imageTag,
    this.backdropTag,
    this.overview,
    this.year,
    this.runtime,
    this.position,
    this.played = false,
    this.seriesId,
    this.seriesName,
    this.seasonNumber,
    this.episodeNumber,
  });

  final String id;
  final String name;

  /// Movie, Series, Season, Episode, CollectionFolder, Video, Folder...
  final String type;

  /// Kitaplıklar için: movies, tvshows, homevideos, music...
  final String? collectionType;
  final String? imageTag;
  final String? backdropTag;
  final String? overview;
  final int? year;
  final Duration? runtime;
  final Duration? position;
  final bool played;
  final String? seriesId;
  final String? seriesName;
  final int? seasonNumber;
  final int? episodeNumber;

  bool get isFolder =>
      const {'CollectionFolder', 'Folder', 'BoxSet', 'UserView', 'Series', 'Season'}
          .contains(type);
  bool get isPlayable => !isFolder;

  /// 0..1 arası izlenme oranı (izlemeye devam et çubuğu).
  double get progress {
    final r = runtime, p = position;
    if (r == null || p == null || r.inSeconds == 0) return 0;
    return (p.inSeconds / r.inSeconds).clamp(0, 1).toDouble();
  }

  /// "S2 E5 · Bölüm adı" veya film adı (uluslararası kısaltma).
  String get displayTitle {
    if (type != 'Episode') return name;
    final parts = [
      if (seasonNumber != null) 'S$seasonNumber',
      if (episodeNumber != null) 'E$episodeNumber',
    ];
    return parts.isEmpty ? name : '${parts.join(' ')} · $name';
  }

  static const _ticksPerMicro = 10;

  factory ServerItem.fromJson(Map<String, dynamic> j) {
    final userData = j['UserData'] as Map<String, dynamic>?;
    final tags = j['ImageTags'] as Map<String, dynamic>?;
    final backdrops = j['BackdropImageTags'] as List?;
    Duration? ticks(Object? v) =>
        v is num && v > 0 ? Duration(microseconds: v ~/ _ticksPerMicro) : null;
    return ServerItem(
      id: j['Id'] as String,
      name: (j['Name'] as String?) ?? '',
      type: (j['Type'] as String?) ?? 'Video',
      collectionType: j['CollectionType'] as String?,
      imageTag: tags?['Primary'] as String?,
      backdropTag: (backdrops != null && backdrops.isNotEmpty)
          ? backdrops.first as String
          : null,
      overview: j['Overview'] as String?,
      year: j['ProductionYear'] as int?,
      runtime: ticks(j['RunTimeTicks']),
      position: ticks(userData?['PlaybackPositionTicks']),
      played: userData?['Played'] as bool? ?? false,
      seriesId: j['SeriesId'] as String?,
      seriesName: j['SeriesName'] as String?,
      seasonNumber: j['ParentIndexNumber'] as int?,
      episodeNumber: j['IndexNumber'] as int?,
    );
  }
}

class AuthResult {
  const AuthResult({required this.userId, required this.userName, required this.token, this.serverName});
  final String userId;
  final String userName;
  final String token;
  final String? serverName;
}

/// Jellyfin ve Emby için ortak REST istemcisi. İki sunucu aynı kökten
/// geldiği için uç noktalar aynıdır; yalnızca kimlik başlıkları farklıdır.
class MediaServerClient {
  MediaServerClient({
    required this.kind,
    required String baseUrl,
    required this.deviceId,
    this.token,
    this.userId,
    http.Client? client,
  })  : baseUrl = normalizeBaseUrl(baseUrl),
        _http = client ?? http.Client();

  final SourceKind kind;
  final String baseUrl;
  final String deviceId;
  final String? token;
  final String? userId;
  final http.Client _http;

  static const _client = 'OtoTV';
  static const _version = '1.0.0';

  /// "192.168.1.5:8096/" → "http://192.168.1.5:8096"
  static String normalizeBaseUrl(String input) {
    var url = input.trim();
    if (!url.contains('://')) url = 'http://$url';
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    return url;
  }

  /// Hem Jellyfin'in yeni `Authorization` başlığını hem Emby/eski Jellyfin'in
  /// `X-Emby-*` başlıklarını gönderir; hangisini tanırsa onu kullanır.
  Map<String, String> get authHeaders {
    final fields = [
      'Client="$_client"',
      'Device="OtoTV"',
      'DeviceId="$deviceId"',
      'Version="$_version"',
      if (token != null) 'Token="$token"',
    ].join(', ');
    return {
      'Authorization': 'MediaBrowser $fields',
      'X-Emby-Authorization': 'MediaBrowser $fields',
      'X-Emby-Token': ?token,
    };
  }

  Future<AuthResult> authenticate(String username, String password) async {
    final res = await _send('POST', '/Users/AuthenticateByName',
        body: {'Username': username, 'Pw': password}, auth: false);
    final user = res['User'] as Map<String, dynamic>?;
    final accessToken = res['AccessToken'] as String?;
    if (user == null || accessToken == null) {
      throw const AppException(AppErrorCode.serverUnexpected);
    }
    return AuthResult(
      userId: user['Id'] as String,
      userName: (user['Name'] as String?) ?? username,
      token: accessToken,
      serverName: res['ServerName'] as String?,
    );
  }

  static const _fields =
      'Overview,PrimaryImageAspectRatio,ProductionYear,BasicSyncInfo';

  Future<List<ServerItem>> views() =>
      _items('/Users/$userId/Views', const {});

  Future<List<ServerItem>> resume({int limit = 20}) => _items(
        '/Users/$userId/Items/Resume',
        {'Limit': '$limit', 'MediaTypes': 'Video', 'Fields': _fields},
      );

  /// Bir kitaplığın içeriği. Film ve dizi kitaplıklarında klasör yapısını
  /// atlayıp doğrudan film/dizileri getirir.
  Future<List<ServerItem>> libraryItems(ServerItem library) {
    final types = switch (library.collectionType) {
      'movies' => 'Movie',
      'tvshows' => 'Series',
      _ => null,
    };
    return _items('/Users/$userId/Items', {
      'ParentId': library.id,
      'SortBy': 'SortName',
      'SortOrder': 'Ascending',
      'Fields': _fields,
      'ImageTypeLimit': '1',
      if (types != null) ...{'IncludeItemTypes': types, 'Recursive': 'true'},
    });
  }

  Future<List<ServerItem>> seasons(String seriesId) =>
      _items('/Shows/$seriesId/Seasons', {'UserId': ?userId});

  Future<List<ServerItem>> episodes(String seriesId, String seasonId) =>
      _items('/Shows/$seriesId/Episodes', {
        'SeasonId': seasonId,
        'UserId': ?userId,
        'Fields': _fields,
      });

  String? imageUrl(String itemId, String? tag, {int maxWidth = 480, String type = 'Primary'}) {
    if (tag == null) return null;
    return '$baseUrl/Items/$itemId/Images/$type?maxWidth=$maxWidth&tag=$tag&quality=90';
  }

  /// Doğrudan akış: dosya olduğu gibi gelir, çözme işini cihazdaki mpv yapar
  /// (MKV, HEVC, DTS dahil). Sunucuda dönüştürme yükü oluşmaz.
  String streamUrl(String itemId) =>
      '$baseUrl/Videos/$itemId/stream?static=true&MediaSourceId=$itemId&DeviceId=$deviceId';

  /// AirPlay / Apple oynatıcısı için HLS: sunucu, cihazın çözemeyeceği
  /// biçimleri (MKV, DTS) H.264/AAC'ye dönüştürür.
  String hlsUrl(String itemId) {
    final q = {
      'MediaSourceId': itemId,
      'DeviceId': deviceId,
      'VideoCodec': 'h264,hevc',
      'AudioCodec': 'aac,ac3,eac3',
      'SegmentContainer': 'ts',
      'api_key': ?token,
    };
    return Uri.parse('$baseUrl/Videos/$itemId/master.m3u8').replace(queryParameters: q).toString();
  }

  Channel toChannel(ServerItem item, {required String sourceId, String? group}) => Channel(
        name: item.displayTitle,
        url: streamUrl(item.id),
        group: group ?? item.seriesName ?? kind.label,
        logo: imageUrl(item.id, item.imageTag),
        sourceId: sourceId,
        serverItemId: item.id,
        startAt: item.played ? null : item.position,
        extraHeaders: authHeaders,
        airplayUrl: hlsUrl(item.id),
      );

  Future<void> reportStart(String itemId, Duration position) => _report(
      '/Sessions/Playing', itemId, position);

  Future<void> reportStopped(String itemId, Duration position) => _report(
      '/Sessions/Playing/Stopped', itemId, position);

  /// İlerleme bildirimi kritik değil; ağ hatası oynatmayı bozmamalı.
  Future<void> _report(String path, String itemId, Duration position) async {
    try {
      await _send('POST', path, body: {
        'ItemId': itemId,
        'PositionTicks': position.inMicroseconds * 10,
        'CanSeek': true,
      });
    } catch (_) {}
  }

  Future<List<ServerItem>> _items(String path, Map<String, String> query) async {
    final res = await _send('GET', path, query: query);
    final items = (res['Items'] as List?) ?? const [];
    return [for (final i in items) ServerItem.fromJson(i as Map<String, dynamic>)];
  }

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, String>? query,
    Map<String, dynamic>? body,
    bool auth = true,
  }) async {
    if (auth && (token == null || userId == null)) {
      throw const AppException(AppErrorCode.noSession);
    }
    final uri = Uri.parse('$baseUrl$path').replace(
      queryParameters: (query == null || query.isEmpty) ? null : query,
    );
    final headers = {
      ...authHeaders,
      'Accept': 'application/json',
      if (body != null) 'Content-Type': 'application/json',
    };
    final http.Response res;
    try {
      final req = http.Request(method, uri)..headers.addAll(headers);
      if (body != null) req.body = jsonEncode(body);
      res = await http.Response.fromStream(
          await _http.send(req).timeout(const Duration(seconds: 20)));
    } catch (_) {
      throw const AppException(AppErrorCode.unreachable);
    }
    switch (res.statusCode) {
      case >= 200 && < 300:
        if (res.body.isEmpty) return const {};
        final decoded = jsonDecode(utf8.decode(res.bodyBytes));
        return decoded is Map<String, dynamic> ? decoded : {'Items': decoded};
      case 401:
        throw AppException(auth ? AppErrorCode.sessionExpired : AppErrorCode.badCredentials);
      case 404:
        throw AppException(AppErrorCode.serverNotFound, detail: kind.label);
      default:
        throw AppException(AppErrorCode.serverStatus, status: res.statusCode);
    }
  }
}
