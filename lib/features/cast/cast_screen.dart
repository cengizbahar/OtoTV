import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../state/providers.dart';
import '../car/car_mode_screen.dart';
import '../../l10n/l10n.dart';
import '../../platform/car_connection.dart';
import '../../state/premium.dart';
import '../premium/paywall_screen.dart';
import '../../platform/airplay.dart';

/// Araç bağlantı merkezi: Android Auto / CarPlay bağlantısını canlı gösterir.
class CastScreen extends ConsumerWidget {
  const CastScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final link = ref.watch(carLinkProvider).value ?? CarLink.none;
    final isPlus = ref.watch(premiumProvider.select((s) => s.isPlus));
    final title = switch (link) {
      CarLink.androidAuto || CarLink.androidAutoDisplay => l.castConnectedAndroidAuto,
      CarLink.automotive => l.castConnectedAutomotive,
      CarLink.carPlay || CarLink.carPlayAudio => l.castConnectedCarPlay,
      CarLink.none => l.castNotConnected,
    };

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.navCast)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 180),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.sheet),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [link.isConnected ? const Color(0xFF3A2C12) : const Color(0xFF1F1A12), AppColors.surface],
              ),
              border: Border.all(color: link.isConnected ? AppColors.gold.withValues(alpha: 0.5) : AppColors.stroke),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _Node(icon: Icons.phone_iphone_rounded, label: context.l10n.castPhone, active: true),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Icon(
                        link.isConnected ? Icons.link_rounded : Icons.arrow_forward_rounded,
                        color: link.isConnected ? AppColors.gold : AppColors.textSecondary,
                      ),
                    ),
                    _Node(icon: Icons.directions_car_filled_rounded, label: context.l10n.castCarScreen, active: link.isConnected),
                  ],
                ),
                const SizedBox(height: 24),
                Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text(
                  switch (link) {
                    CarLink.none => l.castNotConnectedMessage,
                    CarLink.carPlayAudio => l.castConnectedAudioMessage,
                    _ => l.castConnectedMessage,
                  },
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary, height: 1.45),
                ),
              ],
            ),
          ),
          if (link.isConnected && !isPlus) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.workspace_premium_rounded, color: AppColors.gold),
                  const SizedBox(width: 12),
                  Expanded(child: Text(l.castNeedsPlus, style: const TextStyle(height: 1.4))),
                  TextButton(onPressed: () => openPaywall(context), child: Text(l.castGetPlus)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          const _CarModeButton(),
          const SizedBox(height: 28),
          _Step(n: 1, title: context.l10n.castStep1Title, body: context.l10n.castStep1Body),
          _Step(n: 2, title: context.l10n.castStep2Title, body: context.l10n.castStep2Body),
          _Step(n: 3, title: context.l10n.castStep3Title, body: context.l10n.castStep3Body),
          if (AirPlay.isSupported)
            _Step(n: 4, title: l.castAirplayTitle, body: l.castAirplayBody),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.live.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.shield_rounded, color: AppColors.live),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(context.l10n.passengerNotice, style: const TextStyle(height: 1.4)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Node extends StatelessWidget {
  const _Node({required this.icon, required this.label, required this.active});
  final IconData icon;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.gold : AppColors.textSecondary;
    return Column(
      children: [
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            color: AppColors.surfaceHigh,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: color.withValues(alpha: 0.5)),
          ),
          child: Icon(icon, size: 34, color: color),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(color: color, fontSize: 13)),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.n, required this.title, required this.body});
  final int n;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.goldGradient,
            ),
            child: Text('$n',
                style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1A1206))),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 2),
                Text(body, style: const TextStyle(color: AppColors.textSecondary, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Telefonu torpidoya takıp izlemek için Araç Modu girişi.
class _CarModeButton extends ConsumerWidget {
  const _CarModeButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(playerProvider.select((s) => s.isActive));
    return FilledButton.icon(
      onPressed: () {
        if (active) {
          openCarModeGated(context, ref);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(context.l10n.openChannelFirst),
          ));
        }
      },
      icon: const Icon(Icons.directions_car_filled_rounded),
      label: Text(context.l10n.openCarMode),
    );
  }
}
