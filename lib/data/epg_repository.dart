import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'epg.dart';

/// XMLTV rehberini indirir, ayrıştırır ve süzülmüş sonucu diske yazar.
/// Rehberler büyük olduğu için en fazla [ttl] aralıkla yeniden indirilir.
class EpgRepository {
  EpgRepository({http.Client? client, Future<Directory> Function()? directory, this.ttl = const Duration(hours: 6)})
      : _client = client ?? http.Client(),
        _directory = directory ?? getApplicationSupportDirectory;

  final http.Client _client;
  final Future<Directory> Function() _directory;
  final Duration ttl;

  Future<EpgIndex> load({
    required String sourceId,
    required List<String> urls,
    required Set<String> wantedIds,
    required Set<String> wantedNames,
    bool force = false,
  }) async {
    if (urls.isEmpty) return EpgIndex.empty;
    final file = File('${(await _directory()).path}/epg_$sourceId.json');

    if (!force && await file.exists()) {
      final age = DateTime.now().difference(await file.lastModified());
      if (age < ttl) {
        try {
          return EpgIndex.decode(await file.readAsString());
        } catch (_) {/* bozuk önbellek: yeniden indir */}
      }
    }

    var index = EpgIndex.empty;
    for (final url in urls) {
      try {
        final res = await _client
            .send(http.Request('GET', Uri.parse(url))..headers['User-Agent'] = 'OtoTV/1.0')
            .timeout(const Duration(seconds: 30));
        if (res.statusCode != 200) continue;
        final parsed = await const XmlTvParser().parse(
          decodeXmlTvBytes(res.stream),
          wantedIds: wantedIds,
          wantedNames: wantedNames,
        );
        index = index.merge(parsed);
      } catch (_) {
        // Bir rehber bozuksa diğerleriyle devam et.
      }
    }

    if (!index.isEmpty) {
      await file.writeAsString(index.encode());
    } else if (await file.exists()) {
      // Ağ yoksa eski rehber hiç yoktan iyidir.
      try {
        return EpgIndex.decode(await file.readAsString());
      } catch (_) {}
    }
    return index;
  }
}
