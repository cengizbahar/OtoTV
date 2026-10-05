import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ototv/data/models.dart';

void main() {
  test('MediaSource JSON gidiş-dönüş', () {
    final s = MediaSource(
      id: '1',
      name: 'Liste',
      kind: SourceKind.m3u,
      url: 'http://a/b.m3u',
      addedAt: DateTime(2026, 9, 28),
    );
    final back = MediaSource.decodeList(MediaSource.encodeList([s])).single;
    expect(back.id, s.id);
    expect(back.kind, SourceKind.m3u);
    expect(back.addedAt, s.addedAt);
  });

  test('Channel.withSource diğer alanları korur', () {
    const c = Channel(name: 'A', url: 'u', group: 'G', logo: 'l');
    final w = c.withSource('src');
    expect((w.name, w.group, w.logo, w.sourceId), ('A', 'G', 'l', 'src'));
    expect(Colors.black, isNotNull);
  });
}
