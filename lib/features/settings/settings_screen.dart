import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/brand.dart';
import '../../core/theme.dart';
import '../../l10n/l10n.dart';
import '../../state/locale.dart';
import '../../state/premium.dart';
import '../premium/paywall_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const _version = '1.0.0';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final isPlus = ref.watch(premiumProvider.select((s) => s.isPlus));
    final locale = ref.watch(localeProvider);

    void open(String url) => launchUrl(Uri.parse(url), mode: LaunchMode.inAppBrowserView);

    return Scaffold(
      appBar: AppBar(title: Text(l.navSettings)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 180),
        children: [
          GestureDetector(
            onTap: () => openPaywall(context),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.sheet),
                gradient: const LinearGradient(colors: [Color(0xFF3A2C12), Color(0xFF1B150B)]),
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  Icon(isPlus ? Icons.verified_rounded : Icons.workspace_premium_rounded,
                      size: 40, color: AppColors.gold),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(isPlus ? l.plusActive : Brand.premiumName,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 2),
                        Text(isPlus ? l.plusActiveSubtitle : l.plusCardSubtitle,
                            style: const TextStyle(color: AppColors.goldLight)),
                        if (PremiumConfig.testUnlock) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.live,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(l.testBuildBadge,
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.gold),
                ],
              ),
            ),
          ),
          _Label(l.sectionPreferences),
          _Group(children: [
            _Row(
              icon: Icons.language_rounded,
              title: l.language,
              value: switch (locale?.languageCode) {
                'tr' => 'Türkçe',
                'en' => 'English',
                _ => l.languageSystem,
              },
              onTap: () => _pickLanguage(context, ref, locale),
            ),
          ]),
          _Label(l.sectionLegal),
          _Group(children: [
            _Row(icon: Icons.privacy_tip_outlined, title: l.privacyPolicy, onTap: () => open(Brand.privacyUrl)),
            _Row(icon: Icons.description_outlined, title: l.terms, onTap: () => open(Brand.termsUrl)),
          ]),
          _Label(l.sectionAbout),
          _Group(children: [
            _Row(icon: Icons.help_outline_rounded, title: l.help, onTap: () => open(Brand.supportUrl)),
            _Row(icon: Icons.info_outline_rounded, title: l.version, value: _version),
          ]),
          const SizedBox(height: 24),
          Text(
            l.disclaimer(Brand.appName),
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );
  }

  static Future<void> _pickLanguage(BuildContext context, WidgetRef ref, Locale? current) {
    final options = <(Locale?, String)>[
      (null, context.l10n.languageSystem),
      (const Locale('tr'), 'Türkçe'),
      (const Locale('en'), 'English'),
    ];
    return showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final (locale, label) in options)
                ListTile(
                  title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
                  trailing: locale?.languageCode == current?.languageCode
                      ? const Icon(Icons.check_rounded, color: AppColors.gold)
                      : null,
                  onTap: () {
                    ref.read(localeProvider.notifier).set(locale);
                    Navigator.pop(ctx);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(6, 26, 0, 10),
        child: Text(text.toUpperCase(),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            )),
      );
}

class _Group extends StatelessWidget {
  const _Group({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const Divider(height: 1, indent: 56, color: AppColors.stroke),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.title, this.value, this.onTap});
  final IconData icon;
  final String title;
  final String? value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (value != null) Text(value!, style: const TextStyle(color: AppColors.textSecondary)),
          if (onTap != null) const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}
