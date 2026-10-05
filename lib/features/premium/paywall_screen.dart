import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart' show PeriodUnit;
import 'package:url_launcher/url_launcher.dart';

import '../../core/brand.dart';
import '../../core/theme.dart';
import '../../l10n/l10n.dart';
import '../../state/premium.dart';
import '../../widgets/common.dart';

Future<void> openPaywall(BuildContext context) => Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(fullscreenDialog: true, builder: (_) => const PaywallScreen()),
    );

/// Plus gerektiren bir işlemden önce çağrılır. Üye değilse satış ekranını
/// açar; ekran kapandığında üyelik durumunu döndürür.
Future<bool> requirePlus(BuildContext context, WidgetRef ref) async {
  if (ref.read(premiumProvider).isPlus) return true;
  await openPaywall(context);
  return ref.read(premiumProvider).isPlus;
}

class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  PlanKind? _selected;
  bool _busy = false;

  Plan? _current(List<Plan> plans) {
    if (plans.isEmpty) return null;
    return plans.firstWhere(
      (p) => p.kind == (_selected ?? PlanKind.annual),
      orElse: () => plans.first,
    );
  }

  void _toast(String text) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));

  Future<void> _buy(Plan plan) async {
    final l = context.l10n;
    setState(() => _busy = true);
    final outcome = await ref.read(premiumProvider.notifier).purchase(plan);
    if (!mounted) return;
    setState(() => _busy = false);
    switch (outcome) {
      case PurchaseSucceeded():
        _toast(l.purchaseSuccess);
        Navigator.of(context).pop();
      case PurchaseCancelled():
        break;
      case PurchaseFailed(:final message):
        _toast(l.purchaseFailed(message.isEmpty ? l.errUnknown : message));
      case PurchasePreviewOnly():
        _toast(l.previewPurchase);
    }
  }

  Future<void> _restore() async {
    final l = context.l10n;
    setState(() => _busy = true);
    try {
      final restored = await ref.read(premiumProvider.notifier).restore();
      if (!mounted) return;
      _toast(restored ? l.restoreSuccess : l.restoreNone);
      if (restored) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) _toast(l.storeUnavailable);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final premium = ref.watch(premiumProvider);
    final plans = premium.plans;
    final current = _current(plans);

    final features = [
      (Icons.directions_car_filled_rounded, l.paywallCarModeTitle, l.paywallCarModeBody),
      (Icons.all_inclusive_rounded, l.paywallSourcesTitle, l.paywallSourcesBody),
      (Icons.cast_connected_rounded, l.paywallCarPlayTitle, l.paywallCarPlayBody),
      (Icons.auto_awesome_rounded, l.paywallFutureTitle, l.paywallFutureBody),
    ];

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -1.1),
                  radius: 1.3,
                  colors: [Color(0xFF3B2D14), AppColors.background],
                ),
              ),
            ),
          ),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 32),
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    tooltip: l.close,
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ),
                const Icon(Icons.workspace_premium_rounded, size: 64, color: AppColors.gold),
                const SizedBox(height: 12),
                const Center(child: Wordmark(size: 34, showMark: false)),
                const SizedBox(height: 4),
                ShaderMask(
                  shaderCallback: (r) => AppColors.goldGradient.createShader(r),
                  child: const Text(
                    'PLUS',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, letterSpacing: 8, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  l.appTagline,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 15),
                ),
                const SizedBox(height: 28),
                for (final (icon, title, body) in features) _Feature(icon: icon, title: title, body: body),
                const SizedBox(height: 12),
                if (premium.isPlus)
                  _Notice(icon: Icons.verified_rounded, text: l.plusActiveSubtitle)
                else if (!premium.ready)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator(color: AppColors.gold)),
                  )
                else if (plans.isEmpty)
                  _Notice(
                    icon: Icons.storefront_outlined,
                    text: premium.configured ? l.storeUnavailable : l.storeNotConfigured,
                  )
                else ...[
                  if (plans.first.isPreview) ...[
                    _Notice(icon: Icons.visibility_outlined, text: l.previewNotice),
                    const SizedBox(height: 12),
                  ],
                  for (final p in plans)
                    _PlanTile(
                      plan: p,
                      selected: p.kind == current!.kind,
                      onTap: () => setState(() => _selected = p.kind),
                    ),
                  const SizedBox(height: 18),
                  FilledButton(
                    onPressed: _busy ? null : () => _buy(current!),
                    child: _busy
                        ? const SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2.4))
                        : Text(current!.hasFreeTrial ? l.paywallCtaTrial : l.paywallCta),
                  ),
                ],
                const SizedBox(height: 14),
                Text(
                  l.paywallLegal,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
                ),
                const SizedBox(height: 6),
                Wrap(
                  alignment: WrapAlignment.center,
                  children: [
                    if (premium.configured && !premium.isPlus)
                      TextButton(onPressed: _busy ? null : _restore, child: Text(l.restorePurchases)),
                    TextButton(
                      onPressed: () => launchUrl(Uri.parse(Brand.termsUrl), mode: LaunchMode.inAppBrowserView),
                      child: Text(l.terms),
                    ),
                    TextButton(
                      onPressed: () => launchUrl(Uri.parse(Brand.privacyUrl), mode: LaunchMode.inAppBrowserView),
                      child: Text(l.privacyPolicy),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  const _Feature({required this.icon, required this.title, required this.body});
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.gold),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                Text(body, style: const TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.gold),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(height: 1.4))),
        ],
      ),
    );
  }
}

class _PlanTile extends StatelessWidget {
  const _PlanTile({required this.plan, required this.selected, required this.onTap});
  final Plan plan;
  final bool selected;
  final VoidCallback onTap;

  static String _period(L10n l, TrialPeriod trial) {
    final n = trial.count;
    return switch (trial.unit) {
      PeriodUnit.day => l.periodDays(n),
      PeriodUnit.week => l.periodWeeks(n),
      PeriodUnit.month => l.periodMonths(n),
      PeriodUnit.year => l.periodYears(n),
      PeriodUnit.unknown => l.periodDays(n),
    };
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final (title, desc) = switch (plan.kind) {
      PlanKind.monthly => (l.planMonthly, l.planMonthlyDesc),
      PlanKind.annual => (l.planAnnual, plan.hasFreeTrial ? l.planTrial(_period(l, plan.trial!)) : l.planAnnualDesc),
      PlanKind.lifetime => (l.planLifetime, l.planLifetimeDesc),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: selected ? AppColors.gold.withValues(alpha: 0.10) : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: selected ? AppColors.gold : AppColors.stroke, width: selected ? 1.6 : 1),
          ),
          child: Row(
            children: [
              Icon(
                selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                color: selected ? AppColors.gold : AppColors.textSecondary,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                        ),
                        if (plan.kind == PlanKind.annual) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              gradient: AppColors.goldGradient,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(l.bestValue,
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF1A1206))),
                          ),
                        ],
                      ],
                    ),
                    Text(desc, style: const TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(plan.price, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
            ],
          ),
        ),
      ),
    );
  }
}
