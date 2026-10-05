import 'package:flutter_test/flutter_test.dart';
import 'package:ototv/data/m3u_parser.dart';

void main() {
  const parser = M3uParser();

  test('EXTINF özniteliklerini ve başlığı okur', () {
    final list = parser.parse('''
#EXTM3U url-tvg="http://epg.example/guide.xml"
#EXTINF:-1 tvg-id="trt1.tr" tvg-logo="http://logo/trt1.png" group-title="Genel",TRT 1 HD
http://stream.example/trt1.m3u8
''');
    expect(list, hasLength(1));
    final c = list.single;
    expect(c.name, 'TRT 1 HD');
    expect(c.group, 'Genel');
    expect(c.logo, 'http://logo/trt1.png');
    expect(c.tvgId, 'trt1.tr');
    expect(c.url, 'http://stream.example/trt1.m3u8');
  });

  test('tırnak içindeki virgül başlığı bölmez', () {
    final c = parser
        .parse('#EXTINF:-1 group-title="Film, Dizi",Başlık, İkinci Kısım\r\nhttp://a/b.mp4')
        .single;
    expect(c.group, 'Film, Dizi');
    expect(c.name, 'Başlık, İkinci Kısım');
  });

  test('EXTGRP ve EXTVLCOPT başlıklarını uygular', () {
    final c = parser.parse('''
#EXTINF:-1,Spor Kanalı
#EXTGRP:Spor
#EXTVLCOPT:http-user-agent=MyAgent/2.0
#EXTVLCOPT:http-referrer=https://ref.example
http://a/spor.ts
''').single;
    expect(c.group, 'Spor');
    expect(c.httpHeaders,
        {'User-Agent': 'MyAgent/2.0', 'Referer': 'https://ref.example'});
  });

  test('başlıksız düz URL listesi', () {
    final list = parser.parse('http://a/film%20bir.mkv\nhttp://a/iki.mp4');
    expect(list.map((c) => c.name), ['film bir.mkv', 'iki.mp4']);
    expect(list.first.group, 'Diğer');
  });

  test('öznitelikler bir sonraki öğeye taşınmaz', () {
    final list = parser.parse('''
#EXTINF:-1 group-title="Haber" tvg-logo="x.png",A
http://a/1
http://a/2
''');
    expect(list[1].group, 'Diğer');
    expect(list[1].logo, isNull);
  });

  test('group ilk görünme sırasını korur', () {
    final groups = M3uParser.group(parser.parse('''
#EXTINF:-1 group-title="Spor",S1
http://a/1
#EXTINF:-1 group-title="Haber",H1
http://a/2
#EXTINF:-1 group-title="Spor",S2
http://a/3
'''));
    expect(groups.map((g) => g.name), ['Spor', 'Haber']);
    expect(groups.first.channels, hasLength(2));
  });
}
