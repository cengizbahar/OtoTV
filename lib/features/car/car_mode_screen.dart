import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../core/theme.dart';
import '../../data/models.dart';
import '../../state/providers.dart';
import '../../widgets/common.dart';
import '../../widgets/programme_line.dart';
import '../../l10n/l10n.dart';
import '../premium/paywall_screen.dart';
import '../../platform/airplay.dart';
import '../player/player_screen.dart';

/// Araç Modu bir Plus özelliğidir; üye değilse önce satış ekranı açılır.
Future<void> openCarModeGated(BuildContext context, WidgetRef ref) async {
  if (!await requirePlus(context, ref)) return;
  if (context.mounted) openCarMode(context);
}

void openCarMode(BuildContext context) {
  Navigator.of(context, rootNavigator: true).push(PageRouteBuilder(
    transitionDuration: const Duration(milliseconds: 420),
    pageBuilder: (_, _, _) => const CarModeScreen(),
    transitionsBuilder: (_, anim, _, child) => FadeTransition(opacity: anim, child: child),
  ));
}

/// Torpido / tutucu için yatay, dev kontrollü oynatma ekranı.
///
/// Hareketler: dokun → kontroller · sağa/sola kaydır → kanal değiştir ·
/// sol yarıda dikey kaydır → parlaklık · sağ yarıda dikey kaydır → ses.
/// Karartma modu ekranı açık tutup siyaha boyar; araç ekranına yansıtma
/// sürerken telefon ekranı dikkat dağıtmaz ve pil tasarrufu sağlar.
class CarModeScreen extends ConsumerStatefulWidget {
  const CarModeScreen({super.key});

  @override
  ConsumerState<CarModeScreen> createState() => _CarModeScreenState();
}

enum _Hud { none, brightness, volume }

class _CarModeScreenState extends ConsumerState<CarModeScreen> {
  bool _controls = true;
  bool _dimmed = false;
  Timer? _hideTimer;
  Timer? _clockTimer;
  DateTime _now = DateTime.now();

  _Hud _hud = _Hud.none;
  double _brightness = 0.7;
  double _volume = 100;
  Timer? _hudTimer;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    WakelockPlus.enable();
    _clockTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
    ScreenBrightness.instance.application.then((v) => _brightness = v).catchError((_) => 0.7);
    _volume = ref.read(playerProvider.notifier).player.state.volume;
    _scheduleHide();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _clockTimer?.cancel();
    _hudTimer?.cancel();
    SystemChrome.setPreferredOrientations(const []);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    WakelockPlus.disable();
    ScreenBrightness.instance.resetApplicationScreenBrightness().catchError((_) {});
    super.dispose();
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 6), () {
      if (mounted) setState(() => _controls = false);
    });
  }

  void _showControls() {
    setState(() => _controls = true);
    _scheduleHide();
  }

  Future<void> _setDimmed(bool value) async {
    HapticFeedback.mediumImpact();
    setState(() => _dimmed = value);
    try {
      if (value) {
        await ScreenBrightness.instance.setApplicationScreenBrightness(0.01);
      } else {
        await ScreenBrightness.instance.setApplicationScreenBrightness(_brightness);
      }
    } catch (_) {}
    if (!value) _showControls();
  }

  void _onVerticalDrag(DragUpdateDetails d, double width) {
    final delta = -d.primaryDelta! / 300;
    final leftSide = d.localPosition.dx < width / 2;
    setState(() {
      if (leftSide) {
        _hud = _Hud.brightness;
        _brightness = (_brightness + delta).clamp(0.02, 1.0);
        ScreenBrightness.instance
            .setApplicationScreenBrightness(_brightness)
            .catchError((_) {});
      } else {
        _hud = _Hud.volume;
        _volume = (_volume + delta * 100).clamp(0, 100);
        ref.read(playerProvider.notifier).player.setVolume(_volume);
      }
    });
    _hudTimer?.cancel();
    _hudTimer = Timer(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _hud = _Hud.none);
    });
  }

  void _onHorizontalEnd(DragEndDetails d) {
    final v = d.primaryVelocity ?? 0;
    if (v.abs() < 400) return;
    HapticFeedback.selectionClick();
    final n = ref.read(playerProvider.notifier);
    v < 0 ? n.next() : n.previous();
    _showControls();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(playerProvider);
    final notifier = ref.read(playerProvider.notifier);
    final channel = state.current;

    return Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder(
        builder: (context, box) => Stack(
          fit: StackFit.expand,
          children: [
            Video(
              controller: notifier.video,
              controls: NoVideoControls,
              pauseUponEnteringBackgroundMode: false,
              subtitleViewConfiguration: const SubtitleViewConfiguration(
                style: TextStyle(
                  fontSize: 34,
                  height: 1.35,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  backgroundColor: Color(0xAA000000),
                ),
              ),
            ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _controls ? setState(() => _controls = false) : _showControls(),
              onVerticalDragUpdate: (d) => _onVerticalDrag(d, box.maxWidth),
              onHorizontalDragEnd: _onHorizontalEnd,
            ),
            IgnorePointer(
              ignoring: !_controls,
              child: AnimatedOpacity(
                opacity: _controls ? 1 : 0,
                duration: const Duration(milliseconds: 260),
                child: channel == null
                    ? const SizedBox.shrink()
                    : _Overlay(
                        channel: channel,
                        queue: state.queue,
                        now: _now,
                        onClose: () => Navigator.of(context).pop(),
                        onDim: () => _setDimmed(true),
                        onInteract: _scheduleHide,
                      ),
              ),
            ),
            if (_hud != _Hud.none)
              Center(
                child: _HudIndicator(
                  icon: _hud == _Hud.brightness
                      ? Icons.brightness_6_rounded
                      : (_volume == 0 ? Icons.volume_off_rounded : Icons.volume_up_rounded),
                  value: _hud == _Hud.brightness ? _brightness : _volume / 100,
                ),
              ),
            if (_dimmed) _DimLayer(onWake: () => _setDimmed(false)),
          ],
        ),
      ),
    );
  }
}

class _Overlay extends ConsumerWidget {
  const _Overlay({
    required this.channel,
    required this.queue,
    required this.now,
    required this.onClose,
    required this.onDim,
    required this.onInteract,
  });

  final Channel channel;
  final List<Channel> queue;
  final DateTime now;
  final VoidCallback onClose;
  final VoidCallback onDim;
  final VoidCallback onInteract;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(playerProvider.notifier);
    final hasQueue = queue.length > 1;
    final time = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xCC000000), Color(0x22000000), Color(0x22000000), Color(0xE6000000)],
          stops: [0, 0.3, 0.6, 1],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
          child: Column(
            children: [
              Row(
                children: [
                  _RoundButton(icon: Icons.close_rounded, onTap: onClose, size: 60),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(channel.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
                        Text(
                          switch (currentProgramme(ref, channel)) {
                            final p? => '${p.title}  ·  ${hhmm(p.start)}–${hhmm(p.stop)}',
                            null => groupLabel(context.l10n, channel.group),
                          },
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 18, color: AppColors.goldLight),
                        ),
                      ],
                    ),
                  ),
                  Text(time,
                      style: const TextStyle(
                          fontSize: 34, fontWeight: FontWeight.w300, letterSpacing: 1)),
                  const SizedBox(width: 20),
                  if (AirPlay.isSupported) ...[
                    _RoundButton(
                      icon: Icons.airplay_rounded,
                      onTap: () => sendToAirPlay(context, ref),
                      size: 60,
                      label: context.l10n.airplayTooltip,
                    ),
                    const SizedBox(width: 12),
                  ],
                  _RoundButton(icon: Icons.dark_mode_rounded, onTap: onDim, size: 60, label: context.l10n.dim),
                ],
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _RoundButton(
                    icon: Icons.skip_previous_rounded,
                    size: 88,
                    onTap: hasQueue ? () { onInteract(); notifier.previous(); } : null,
                  ),
                  const SizedBox(width: 48),
                  StreamBuilder<bool>(
                    stream: notifier.player.stream.playing,
                    initialData: notifier.player.state.playing,
                    builder: (_, snap) => _RoundButton(
                      icon: snap.data == true ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      size: 116,
                      gold: true,
                      onTap: () { onInteract(); notifier.player.playOrPause(); },
                    ),
                  ),
                  const SizedBox(width: 48),
                  _RoundButton(
                    icon: Icons.skip_next_rounded,
                    size: 88,
                    onTap: hasQueue ? () { onInteract(); notifier.next(); } : null,
                  ),
                ],
              ),
              const Spacer(),
              if (hasQueue)
                SizedBox(
                  height: 96,
                  child: _QueueRail(queue: queue, current: channel, onInteract: onInteract),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QueueRail extends ConsumerStatefulWidget {
  const _QueueRail({required this.queue, required this.current, required this.onInteract});
  final List<Channel> queue;
  final Channel current;
  final VoidCallback onInteract;

  @override
  ConsumerState<_QueueRail> createState() => _QueueRailState();
}

class _QueueRailState extends ConsumerState<_QueueRail> {
  static const _itemWidth = 200.0;
  static const _gap = 14.0;
  late final _scroll = ScrollController(initialScrollOffset: _offsetFor(widget.current));

  double _offsetFor(Channel c) {
    final i = widget.queue.indexWhere((q) => q.key == c.key);
    return (i < 1 ? 0 : i - 1) * (_itemWidth + _gap);
  }

  @override
  void didUpdateWidget(covariant _QueueRail old) {
    super.didUpdateWidget(old);
    if (old.current.key != widget.current.key && _scroll.hasClients) {
      _scroll.animateTo(
        _offsetFor(widget.current).clamp(0, _scroll.position.maxScrollExtent),
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      controller: _scroll,
      scrollDirection: Axis.horizontal,
      itemCount: widget.queue.length,
      separatorBuilder: (_, _) => const SizedBox(width: _gap),
      itemBuilder: (_, i) {
        final c = widget.queue[i];
        final active = c.key == widget.current.key;
        return GestureDetector(
          onTap: () {
            widget.onInteract();
            HapticFeedback.selectionClick();
            if (!active) ref.read(playerProvider.notifier).play(c, queue: widget.queue);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: _itemWidth,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: active ? AppColors.gold.withValues(alpha: 0.22) : const Color(0xB3141417),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: active ? AppColors.gold : AppColors.stroke,
                width: active ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                ChannelLogo(name: c.name, url: c.logo, size: 52),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    c.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: active ? AppColors.goldLight : AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.onTap, required this.size, this.gold = false, this.label});
  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final bool gold;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final button = GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: gold ? AppColors.goldGradient : null,
          color: gold ? null : const Color(0x99141417),
          border: gold ? null : Border.all(color: AppColors.stroke),
          boxShadow: gold
              ? [BoxShadow(color: AppColors.gold.withValues(alpha: 0.4), blurRadius: 30)]
              : null,
        ),
        child: Icon(
          icon,
          size: size * 0.52,
          color: gold
              ? const Color(0xFF1A1206)
              : (enabled ? AppColors.textPrimary : AppColors.textSecondary.withValues(alpha: 0.4)),
        ),
      ),
    );
    if (label == null) return button;
    return Tooltip(message: label!, child: button);
  }
}

class _HudIndicator extends StatelessWidget {
  const _HudIndicator({required this.icon, required this.value});
  final IconData icon;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Glass(
      radius: 28,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40, color: AppColors.gold),
          const SizedBox(width: 18),
          SizedBox(
            width: 220,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: value,
                minHeight: 10,
                color: AppColors.gold,
                backgroundColor: AppColors.stroke,
              ),
            ),
          ),
          const SizedBox(width: 18),
          SizedBox(
            width: 60,
            child: Text('${(value * 100).round()}%',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

/// Tam siyah katman. Yanlışlıkla uyanmaması için çift dokunuş gerekir.
class _DimLayer extends StatelessWidget {
  const _DimLayer({required this.onWake});
  final VoidCallback onWake;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onDoubleTap: onWake,
      child: ColoredBox(
        color: Colors.black,
        child: Align(
          alignment: const Alignment(0, 0.85),
          child: Text(
            context.l10n.wakeHint,
            style: const TextStyle(color: Color(0x33FFFFFF), fontSize: 14),
          ),
        ),
      ),
    );
  }
}
