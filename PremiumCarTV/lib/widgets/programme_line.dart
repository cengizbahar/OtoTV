import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../data/epg.dart';
import '../data/models.dart';
import '../state/providers.dart';
import '../l10n/l10n.dart';

String hhmm(DateTime t) {
  final l = t.toLocal();
  return '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
}

/// Kanal kartı altındaki tek satır: şu anki yayın + ince altın ilerleme.
/// Rehber yoksa hiç yer kaplamaz.
class ProgrammeLine extends ConsumerWidget {
  const ProgrammeLine({super.key, required this.channel, this.fontSize = 12});
  final Channel channel;
  final double fontSize;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (now, _) = ref.watch(nowNextProvider(channel));
    if (now == null) return const SizedBox.shrink();
    final t = ref.watch(clockProvider).value ?? DateTime.now();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          now.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: AppColors.textSecondary, fontSize: fontSize),
        ),
        const SizedBox(height: 5),
        _Bar(now.progressAt(t.toUtc())),
      ],
    );
  }
}

/// Oynatıcı ayrıntısı: şimdi (saat aralığı, ilerleme, açıklama) ve sonra.
class ProgrammeDetails extends ConsumerWidget {
  const ProgrammeDetails({super.key, required this.channel});
  final Channel channel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (now, next) = ref.watch(nowNextProvider(channel));
    if (now == null && next == null) return const SizedBox.shrink();
    final t = (ref.watch(clockProvider).value ?? DateTime.now()).toUtc();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (now != null) ...[
            Row(
              children: [
                const _LiveDot(),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(now.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                ),
                Text('${hhmm(now.start)} – ${hhmm(now.stop)}',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 8),
            _Bar(now.progressAt(t)),
            if (now.desc != null) ...[
              const SizedBox(height: 8),
              Text(now.desc!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4)),
            ],
          ],
          if (next != null) ...[
            const SizedBox(height: 10),
            Text.rich(
              TextSpan(children: [
                TextSpan(
                  text: '${context.l10n.epgNext}  ',
                  style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w800, letterSpacing: 1),
                ),
                TextSpan(text: '${hhmm(next.start)}  ${next.title}'),
              ]),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }
}

/// Yalnızca başlık metni (araç modu gibi özel yerleşimler için).
Programme? currentProgramme(WidgetRef ref, Channel c) => ref.watch(nowNextProvider(c)).$1;

class _Bar extends StatelessWidget {
  const _Bar(this.value);
  final double value;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: SizedBox(
        height: 3,
        child: Stack(
          children: [
            const Positioned.fill(child: ColoredBox(color: AppColors.stroke)),
            FractionallySizedBox(
              widthFactor: value,
              child: const DecoratedBox(
                decoration: BoxDecoration(gradient: AppColors.goldGradient),
                child: SizedBox.expand(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveDot extends StatelessWidget {
  const _LiveDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: AppColors.live,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: AppColors.live.withValues(alpha: 0.6), blurRadius: 6)],
      ),
    );
  }
}
