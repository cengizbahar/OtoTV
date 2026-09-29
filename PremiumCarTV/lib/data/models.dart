import 'dart:convert';

/// Kullanıcının eklediği içerik kaynağı.
enum SourceKind {
  m3u('M3U'),
  jellyfin('Jellyfin'),
  emby('Emby');

  const SourceKind(this.label);
  final String label;

  bool get isServer => this != m3u;
}

class MediaSource {
  const MediaSource({
    required this.id,
    required this.name,
    required this.kind,
    required this.url,
    this.userId,
    this.userName,
    this.addedAt,
  });

  final String id;
  final String name;
  final SourceKind kind;

  /// M3U için liste adresi, sunucular için temel adres (ör. http://192.168.1.5:8096).
  final String url;

  /// Yalnızca Jellyfin/Emby. Erişim anahtarı burada değil, güvenli kasada durur.
  final String? userId;
  final String? userName;
  final DateTime? addedAt;

  MediaSource copyWith({String? name, String? url}) => MediaSource(
        id: id,
        name: name ?? this.name,
        kind: kind,
        url: url ?? this.url,
        userId: userId,
        userName: userName,
        addedAt: addedAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'kind': kind.name,
        'url': url,
        'userId': userId,
        'userName': userName,
        'addedAt': addedAt?.toIso8601String(),
      };

  factory MediaSource.fromJson(Map<String, dynamic> json) => MediaSource(
        id: json['id'] as String,
        name: json['name'] as String,
        kind: SourceKind.values.byName(json['kind'] as String),
        url: json['url'] as String,
        userId: json['userId'] as String?,
        userName: json['userName'] as String?,
        addedAt: DateTime.tryParse(json['addedAt'] as String? ?? ''),
      );

  static String encodeList(List<MediaSource> list) =>
      jsonEncode(list.map((s) => s.toJson()).toList());

  static List<MediaSource> decodeList(String raw) => (jsonDecode(raw) as List)
      .map((e) => MediaSource.fromJson(e as Map<String, dynamic>))
      .toList();
}

/// Oynatılabilir tek bir öğe: canlı kanal, film veya bölüm.
class Channel {
  const Channel({
    required this.name,
    required this.url,
    this.group = defaultGroup,
    this.logo,
    this.tvgId,
    this.userAgent,
    this.referrer,
    this.sourceId,
    this.serverItemId,
    this.startAt,
    this.extraHeaders = const {},
  });

  static const defaultGroup = 'Diğer';

  final String name;
  final String url;
  final String group;
  final String? logo;
  final String? tvgId;
  final String? userAgent;
  final String? referrer;
  final String? sourceId;

  /// Jellyfin/Emby öğe kimliği; oynatma ilerlemesi sunucuya bildirilir.
  final String? serverItemId;

  /// Sunucunun hatırladığı kaldığın yer (yerel kayıt yoksa kullanılır).
  final Duration? startAt;

  /// Sunucu kimlik doğrulama başlıkları. Anahtar URL'ye yazılmaz; böylece
  /// favoriler/konum kayıtlarına ve günlüklere sızmaz.
  final Map<String, String> extraHeaders;

  bool get isServerItem => serverItemId != null;

  /// Favoriler ve kaldığı yer için kalıcı anahtar.
  String get key => isServerItem ? 'srv:$sourceId:$serverItemId' : url;

  @override
  bool operator ==(Object other) => other is Channel && other.key == key;

  @override
  int get hashCode => key.hashCode;

  Map<String, String> get httpHeaders => {
        'User-Agent': ?userAgent,
        'Referer': ?referrer,
        ...extraHeaders,
      };

  Channel withSource(String id) => Channel(
        name: name,
        url: url,
        group: group,
        logo: logo,
        tvgId: tvgId,
        userAgent: userAgent,
        referrer: referrer,
        sourceId: id,
        serverItemId: serverItemId,
        startAt: startAt,
        extraHeaders: extraHeaders,
      );
}

/// Grup başlığı ve içindeki kanallar; ana sayfadaki her satır bir [ChannelGroup].
class ChannelGroup {
  const ChannelGroup(this.name, this.channels);
  final String name;
  final List<Channel> channels;
}
