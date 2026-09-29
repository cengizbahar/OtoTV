import 'models.dart';

/// M3U / M3U8 çalma listesi ayrıştırıcı.
///
/// Desteklenenler: `#EXTINF` öznitelikleri (tvg-id, tvg-name, tvg-logo,
/// group-title), `#EXTGRP`, `#EXTVLCOPT:http-user-agent / http-referrer`
/// ve başlıksız düz URL listeleri.
class M3uParser {
  const M3uParser();

  static final _attr = RegExp(r'([\w-]+)="([^"]*)"');

  List<Channel> parse(String content) {
    final channels = <Channel>[];
    Map<String, String> attrs = {};
    String? title;
    String? extGroup;
    String? userAgent;
    String? referrer;

    void reset() {
      attrs = {};
      title = null;
      extGroup = null;
      userAgent = null;
      referrer = null;
    }

    for (final raw in content.split(RegExp(r'\r?\n'))) {
      final line = raw.trim();
      if (line.isEmpty) continue;

      if (line.startsWith('#EXTINF')) {
        reset();
        final (a, t) = _parseExtInf(line);
        attrs = a;
        title = t;
      } else if (line.startsWith('#EXTGRP:')) {
        extGroup = line.substring(8).trim();
      } else if (line.startsWith('#EXTVLCOPT:')) {
        final opt = line.substring(11);
        final eq = opt.indexOf('=');
        if (eq > 0) {
          final key = opt.substring(0, eq).trim().toLowerCase();
          final value = opt.substring(eq + 1).trim();
          if (key == 'http-user-agent') userAgent = value;
          if (key == 'http-referrer' || key == 'http-referer') referrer = value;
        }
      } else if (line.startsWith('#')) {
        continue;
      } else {
        final name = _firstNonEmpty([title, attrs['tvg-name']]) ??
            _nameFromUrl(line);
        final group = _firstNonEmpty([attrs['group-title'], extGroup]) ??
            Channel.defaultGroup;
        channels.add(Channel(
          name: name,
          url: line,
          group: group,
          logo: _firstNonEmpty([attrs['tvg-logo'], attrs['logo']]),
          tvgId: _firstNonEmpty([attrs['tvg-id']]),
          userAgent: userAgent ?? attrs['user-agent'],
          referrer: referrer,
        ));
        reset();
      }
    }
    return channels;
  }

  /// `#EXTM3U url-tvg="a.xml,b.xml.gz"` başlığındaki EPG (XMLTV) adresleri.
  static List<String> epgUrls(String content) {
    final header = content.split(RegExp(r'\r?\n')).map((l) => l.trim()).firstWhere(
          (l) => l.isNotEmpty,
          orElse: () => '',
        );
    if (!header.startsWith('#EXTM3U')) return const [];
    final urls = <String>[];
    for (final m in _attr.allMatches(header)) {
      final key = m.group(1)!.toLowerCase();
      if (key == 'url-tvg' || key == 'x-tvg-url' || key == 'tvg-url') {
        urls.addAll(m.group(2)!.split(',').map((u) => u.trim()).where((u) => u.startsWith('http')));
      }
    }
    return urls.toSet().toList();
  }

  /// Kanalları listedeki ilk görünme sırasına göre gruplar.
  static List<ChannelGroup> group(List<Channel> channels) {
    final map = <String, List<Channel>>{};
    for (final c in channels) {
      map.putIfAbsent(c.group, () => []).add(c);
    }
    return [for (final e in map.entries) ChannelGroup(e.key, e.value)];
  }

  /// `#EXTINF:-1 a="b",Başlık` → ({a: b}, Başlık). Tırnak içindeki
  /// virgüller başlık ayracı sayılmaz.
  (Map<String, String>, String?) _parseExtInf(String line) {
    var inQuotes = false;
    var comma = -1;
    for (var i = 0; i < line.length; i++) {
      final ch = line[i];
      if (ch == '"') inQuotes = !inQuotes;
      if (ch == ',' && !inQuotes) {
        comma = i;
        break;
      }
    }
    final head = comma >= 0 ? line.substring(0, comma) : line;
    final title = comma >= 0 ? line.substring(comma + 1).trim() : null;
    final attrs = {
      for (final m in _attr.allMatches(head)) m.group(1)!.toLowerCase(): m.group(2)!,
    };
    return (attrs, title);
  }

  static String? _firstNonEmpty(List<String?> values) {
    for (final v in values) {
      if (v != null && v.trim().isNotEmpty) return v.trim();
    }
    return null;
  }

  static String _nameFromUrl(String url) {
    final uri = Uri.tryParse(url);
    final last = uri?.pathSegments.where((s) => s.isNotEmpty).lastOrNull;
    return (last == null || last.isEmpty) ? url : Uri.decodeComponent(last);
  }
}
