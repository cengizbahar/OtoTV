import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ototv/data/app_error.dart';
import 'package:ototv/data/media_server_client.dart';
import 'package:ototv/data/models.dart';

void main() {
  MediaServerClient client(MockClientHandler handler, {String? token = 'tok', String? userId = 'u1'}) =>
      MediaServerClient(
        kind: SourceKind.jellyfin,
        baseUrl: '192.168.1.5:8096/',
        deviceId: 'dev',
        token: token,
        userId: userId,
        client: MockClient(handler),
      );

  test('adres normalleştirilir', () {
    expect(MediaServerClient.normalizeBaseUrl('192.168.1.5:8096/'), 'http://192.168.1.5:8096');
    expect(MediaServerClient.normalizeBaseUrl('https://jf.ev.net//'), 'https://jf.ev.net');
  });

  test('giriş: doğru uç nokta ve gövde, anahtar döner', () async {
    late http.Request sent;
    final c = client((req) async {
      sent = req;
      return http.Response(
        jsonEncode({'User': {'Id': 'u1', 'Name': 'Cengiz'}, 'AccessToken': 'abc', 'ServerName': 'Ev'}),
        200,
      );
    }, token: null, userId: null);

    final auth = await c.authenticate('cengiz', 'gizli');
    expect(sent.url.toString(), 'http://192.168.1.5:8096/Users/AuthenticateByName');
    expect(jsonDecode(sent.body), {'Username': 'cengiz', 'Pw': 'gizli'});
    expect(sent.headers['Authorization'], contains('Client="OtoTV"'));
    expect(sent.headers['Authorization'], isNot(contains('Token=')));
    expect((auth.userId, auth.token, auth.serverName), ('u1', 'abc', 'Ev'));
  });

  test('hatalı şifre anlaşılır mesaj verir', () async {
    final c = client((_) async => http.Response('', 401), token: null, userId: null);
    expect(
      () => c.authenticate('a', 'b'),
      throwsA(isA<AppException>().having((e) => e.code, 'code', AppErrorCode.badCredentials)),
    );
  });

  test('film kitaplığı klasörleri atlayıp filmleri getirir', () async {
    late Uri url;
    final c = client((req) async {
      url = req.url;
      expect(req.headers['X-Emby-Token'], 'tok');
      return http.Response(
        jsonEncode({
          'Items': [
            {
              'Id': 'm1',
              'Name': 'Film',
              'Type': 'Movie',
              'ProductionYear': 2024,
              'RunTimeTicks': 72000000000, // 2 saat
              'ImageTags': {'Primary': 'tagX'},
              'UserData': {'PlaybackPositionTicks': 18000000000, 'Played': false},
            }
          ]
        }),
        200,
      );
    });

    final items = await c.libraryItems(
      const ServerItem(id: 'lib', name: 'Filmler', type: 'CollectionFolder', collectionType: 'movies'),
    );
    expect(url.path, '/Users/u1/Items');
    expect(url.queryParameters['IncludeItemTypes'], 'Movie');
    expect(url.queryParameters['Recursive'], 'true');
    final m = items.single;
    expect(m.runtime, const Duration(hours: 2));
    expect(m.position, const Duration(minutes: 30));
    expect(m.progress, closeTo(0.25, 0.001));
    expect(m.isPlayable, isTrue);
  });

  test('toChannel: anahtar URL yerine başlıkta, konum aktarılır', () {
    final c = client((_) async => http.Response('{}', 200));
    const ep = ServerItem(
      id: 'e5',
      name: 'Pilot',
      type: 'Episode',
      seriesName: 'Dizi',
      seasonNumber: 1,
      episodeNumber: 1,
      position: Duration(minutes: 3),
    );
    final ch = c.toChannel(ep, sourceId: 's1');
    expect(ch.url, isNot(contains('tok')));
    expect(ch.httpHeaders['X-Emby-Token'], 'tok');
    expect(ch.name, 'S1 E1 · Pilot');
    expect(ch.group, 'Dizi');
    expect(ch.key, 'srv:s1:e5');
    expect(ch.startAt, const Duration(minutes: 3));
  });

  test('oturum yoksa istek atılmaz', () {
    var called = false;
    final c = client((_) async {
      called = true;
      return http.Response('{}', 200);
    }, token: null);
    expect(c.views(), throwsA(isA<AppException>().having((e) => e.code, 'code', AppErrorCode.noSession)));
    expect(called, isFalse);
  });
}
