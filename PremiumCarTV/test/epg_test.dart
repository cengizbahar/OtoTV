import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ototv/data/epg.dart';
import 'package:ototv/data/m3u_parser.dart';
import 'package:ototv/data/models.dart';

const _xml = '''<?xml version="1.0" encoding="UTF-8"?>
<tv>
  <channel id="trt1.tr"><display-name>TRT 1 HD</display-name></channel>
  <channel id="atv.tr"><display-name lang="tr">ATV</display-name></channel>
  <channel id="other.de"><display-name>Das Erste</display-name></channel>
  <programme start="20260928190000 +0300" stop="20260928200000 +0300" channel="trt1.tr">
    <title lang="tr">Ana Haber</title><desc>Günün önemli gelişmeleri &amp; hava durumu</desc>
  </programme>
  <programme start="20260928200000 +0300" stop="20260928220000 +0300" channel="trt1.tr">
    <title><![CDATA[Dizi: Kuruluş]]></title>
  </programme>
  <programme start="20260928190000 +0300" stop="20260928210000 +0300" channel="atv.tr">
    <title>Film Kuşağı</title>
  </programme>
  <programme start="20260928190000 +0300" stop="20260928210000 +0300" channel="other.de">
    <title>Tagesschau</title>
  </programme>
  <programme start="20260920100000 +0300" stop="20260920110000 +0300" channel="trt1.tr">
    <title>Eski yayın</title>
  </programme>
</tv>''';

void main() {
  // 28 Eylül 19:30 Türkiye saati.
  final now = DateTime.utc(2026, 9, 28, 16, 30);

  test('XMLTV saati UTC\'ye çevrilir', () {
    expect(parseXmlTvTime('20260928190000 +0300'), DateTime.utc(2026, 9, 28, 16));
    expect(parseXmlTvTime('20260928190000 -0130'), DateTime.utc(2026, 9, 28, 20, 30));
    expect(parseXmlTvTime('202609281900'), DateTime.utc(2026, 9, 28, 19));
    expect(parseXmlTvTime('bozuk'), isNull);
  });

  test('isim normalleştirme kalite eklerini atar', () {
    expect(EpgIndex.normalizeName('TRT 1 HD'), 'trt1');
    expect(EpgIndex.normalizeName('trt-1 [TR] FHD'), 'trt1');
    expect(EpgIndex.normalizeName('Show TV (1080p)'), 'showtv');
  });

  Future<EpgIndex> parse({Set<String> ids = const {}, Set<String> names = const {}}) =>
      const XmlTvParser().parse(Stream.value(_xml), wantedIds: ids, wantedNames: names, now: now);

  test('yalnızca istenen kanallar ve pencere içindeki yayınlar tutulur', () async {
    final idx = await parse(ids: {'trt1.tr'}, names: {'atv'});
    expect(idx.byChannel.keys, unorderedEquals(['trt1.tr', 'atv.tr']));
    expect(idx.byChannel['trt1.tr']!.map((p) => p.title), ['Ana Haber', 'Dizi: Kuruluş']);
    expect(idx.byChannel['trt1.tr']!.first.desc, 'Günün önemli gelişmeleri & hava durumu');
  });

  test('şimdi/sonra: tvg-id ile ve isimle eşleşir', () async {
    final idx = await parse(ids: {'trt1.tr'}, names: {'atv'});
    final (n1, x1) = idx.nowNext(const Channel(name: 'TRT 1', url: 'u1', tvgId: 'trt1.tr'), now);
    expect(n1!.title, 'Ana Haber');
    expect(n1.progressAt(now), closeTo(0.5, 0.001));
    expect(x1!.title, 'Dizi: Kuruluş');

    final (n2, _) = idx.nowNext(const Channel(name: 'ATV HD', url: 'u2'), now);
    expect(n2!.title, 'Film Kuşağı');

    final (n3, x3) = idx.nowNext(const Channel(name: 'Bilinmeyen', url: 'u3'), now);
    expect((n3, x3), (null, null));
  });

  test('önbellek kodlama gidiş-dönüş', () async {
    final idx = await parse(ids: {'trt1.tr'});
    final back = EpgIndex.decode(idx.encode());
    expect(back.byChannel['trt1.tr']!.length, 2);
    expect(back.byChannel['trt1.tr']!.first.start, DateTime.utc(2026, 9, 28, 16));
  });

  test('gzip imzası otomatik algılanır', () async {
    final plain = utf8.encode('<tv>ğüş</tv>');
    final gz = gzip.encode(plain);
    expect(await decodeXmlTvBytes(Stream.value(gz)).join(), '<tv>ğüş</tv>');
    expect(await decodeXmlTvBytes(Stream.value(plain)).join(), '<tv>ğüş</tv>');
  });

  test('M3U başlığından rehber adresleri', () {
    expect(
      M3uParser.epgUrls('#EXTM3U url-tvg="http://a/epg.xml, http://b/epg.xml.gz" x-tvg-url="http://a/epg.xml"\n#EXTINF:-1,A\nhttp://s'),
      ['http://a/epg.xml', 'http://b/epg.xml.gz'],
    );
    expect(M3uParser.epgUrls('#EXTINF:-1,A\nhttp://s'), isEmpty);
  });
}
