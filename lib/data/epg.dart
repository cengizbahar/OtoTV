import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:xml/xml_events.dart';

import 'models.dart';

/// Tek bir yayın (XMLTV `<programme>`).
class Programme {
  const Programme({required this.title, required this.start, required this.stop, this.desc});

  final String title;
  final DateTime start;
  final DateTime stop;
  final String? desc;

  bool isOnAt(DateTime t) => !t.isBefore(start) && t.isBefore(stop);

  double progressAt(DateTime t) {
    final total = stop.difference(start).inSeconds;
    if (total <= 0) return 0;
    return (t.difference(start).inSeconds / total).clamp(0, 1).toDouble();
  }

  Map<String, dynamic> toJson() => {
        't': title,
        's': start.millisecondsSinceEpoch,
        'e': stop.millisecondsSinceEpoch,
        if (desc != null) 'd': desc,
      };

  factory Programme.fromJson(Map<String, dynamic> j) => Programme(
        title: j['t'] as String,
        start: DateTime.fromMillisecondsSinceEpoch(j['s'] as int, isUtc: true),
        stop: DateTime.fromMillisecondsSinceEpoch(j['e'] as int, isUtc: true),
        desc: j['d'] as String?,
      );
}

/// Kanal → yayın akışı dizini. Eşleşme önce `tvg-id`, sonra kanal adıyla yapılır.
class EpgIndex {
  EpgIndex(this.byChannel, this.idByName);
  static final empty = EpgIndex(const {}, const {});

  /// XMLTV kanal kimliği → başlangıç saatine göre sıralı yayınlar.
  final Map<String, List<Programme>> byChannel;

  /// Normalleştirilmiş görünen ad → XMLTV kanal kimliği.
  final Map<String, String> idByName;

  bool get isEmpty => byChannel.isEmpty;

  List<Programme> programmesFor(Channel c) {
    final direct = c.tvgId == null ? null : byChannel[c.tvgId];
    if (direct != null) return direct;
    final id = idByName[normalizeName(c.name)];
    return id == null ? const [] : (byChannel[id] ?? const []);
  }

  /// (şu anki, sıradaki) yayın.
  (Programme?, Programme?) nowNext(Channel c, DateTime now) {
    final list = programmesFor(c);
    for (var i = 0; i < list.length; i++) {
      if (list[i].isOnAt(now)) return (list[i], i + 1 < list.length ? list[i + 1] : null);
      if (list[i].start.isAfter(now)) return (null, list[i]);
    }
    return (null, null);
  }

  EpgIndex merge(EpgIndex other) => EpgIndex(
        {...byChannel, ...other.byChannel},
        {...idByName, ...other.idByName},
      );

  String encode() => jsonEncode({
        'c': byChannel.map((k, v) => MapEntry(k, [for (final p in v) p.toJson()])),
        'n': idByName,
      });

  factory EpgIndex.decode(String raw) {
    final j = jsonDecode(raw) as Map<String, dynamic>;
    return EpgIndex(
      (j['c'] as Map<String, dynamic>).map((k, v) => MapEntry(
            k,
            [for (final p in v as List) Programme.fromJson(p as Map<String, dynamic>)],
          )),
      (j['n'] as Map<String, dynamic>).cast<String, String>(),
    );
  }

  /// "TRT 1 HD", "trt1 [TR]" ve "TRT-1 FHD" aynı anahtara iner: "trt1".
  static String normalizeName(String name) => name
      .toLowerCase()
      .replaceAll(RegExp(r'\[[^\]]*\]|\([^)]*\)'), '')
      .replaceAll(RegExp(r'\b(uhd|fhd|hd|sd|4k|hevc|h265|tr|turkey)\b'), '')
      .replaceAll(RegExp(r'[^a-z0-9ğüşöçıi]'), '');
}

/// XMLTV akış ayrıştırıcı. Dosya parça parça işlenir; yalnızca istenen
/// kanalların [window] içindeki yayınları bellekte tutulur.
class XmlTvParser {
  const XmlTvParser({this.window = const Duration(hours: 30), this.lookBack = const Duration(hours: 3)});

  final Duration window;
  final Duration lookBack;

  Future<EpgIndex> parse(
    Stream<String> xml, {
    required Set<String> wantedIds,
    required Set<String> wantedNames,
    DateTime? now,
  }) async {
    final t0 = (now ?? DateTime.now()).toUtc();
    final from = t0.subtract(lookBack), until = t0.add(window);
    final byChannel = <String, List<Programme>>{};
    final idByName = <String, String>{};
    final keep = {...wantedIds};

    // Ayrıştırma durumu.
    String? element; // şu an metni okunan alt öğe
    String? channelId; // <channel id=...>
    String? progChannel;
    DateTime? progStart, progStop;
    String? title, desc;
    final text = StringBuffer();

    await for (final event in xml.toXmlEvents().flatten()) {
      switch (event) {
        case XmlStartElementEvent(name: 'channel', :final attributes):
          channelId = _attr(attributes, 'id');
        case XmlStartElementEvent(name: 'programme', :final attributes):
          progChannel = _attr(attributes, 'channel');
          progStart = parseXmlTvTime(_attr(attributes, 'start'));
          progStop = parseXmlTvTime(_attr(attributes, 'stop'));
          title = null;
          desc = null;
        case XmlStartElementEvent(:final name, isSelfClosing: false)
            when name == 'display-name' || name == 'title' || name == 'desc':
          element = name;
          text.clear();
        case XmlTextEvent(:final value) || XmlCDATAEvent(:final value) when element != null:
          text.write(value);
        case XmlEndElementEvent(:final name) when name == element:
          final value = text.toString().trim();
          element = null;
          if (name == 'display-name' && channelId != null) {
            final key = EpgIndex.normalizeName(value);
            if (wantedNames.contains(key)) {
              idByName.putIfAbsent(key, () => channelId!);
              keep.add(channelId);
            }
          } else if (name == 'title') {
            title ??= value;
          } else if (name == 'desc') {
            desc ??= value;
          }
        case XmlEndElementEvent(name: 'channel'):
          channelId = null;
        case XmlEndElementEvent(name: 'programme'):
          final ch = progChannel, s = progStart, e = progStop, t = title;
          if (ch != null && s != null && e != null && t != null && t.isNotEmpty &&
              keep.contains(ch) && e.isAfter(from) && s.isBefore(until)) {
            byChannel.putIfAbsent(ch, () => []).add(
                Programme(title: t, start: s, stop: e, desc: (desc?.isEmpty ?? true) ? null : desc));
          }
          progChannel = null;
        default:
          break;
      }
    }
    for (final list in byChannel.values) {
      list.sort((a, b) => a.start.compareTo(b.start));
    }
    return EpgIndex(byChannel, idByName);
  }

  static String? _attr(List<XmlEventAttribute> attrs, String name) {
    for (final a in attrs) {
      if (a.name == name) return a.value;
    }
    return null;
  }
}

/// "20260928200000 +0300" → UTC DateTime. Saat dilimi yoksa UTC kabul edilir.
DateTime? parseXmlTvTime(String? raw) {
  if (raw == null) return null;
  final m = RegExp(r'^(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})?\s*([+-])?(\d{2})?(\d{2})?').firstMatch(raw.trim());
  if (m == null) return null;
  int g(int i) => int.parse(m.group(i) ?? '0');
  final local = DateTime.utc(g(1), g(2), g(3), g(4), g(5), g(6));
  if (m.group(7) == null) return local;
  final offset = Duration(hours: g(8), minutes: g(9));
  return m.group(7) == '+' ? local.subtract(offset) : local.add(offset);
}

/// Gzip ile sıkıştırılmış (.xml.gz) ya da düz XMLTV baytlarını metne çevirir.
/// Sıkıştırma, ilk baytlardaki imzadan anlaşılır.
Stream<String> decodeXmlTvBytes(Stream<List<int>> bytes) async* {
  final it = StreamIterator(bytes);
  if (!await it.moveNext()) return;
  final first = it.current;
  Stream<List<int>> all() async* {
    yield first;
    while (await it.moveNext()) {
      yield it.current;
    }
  }

  final gz = first.length >= 2 && first[0] == 0x1f && first[1] == 0x8b;
  final raw = gz ? all().transform(gzip.decoder) : all();
  yield* raw.transform(const Utf8Decoder(allowMalformed: true));
}
