import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../widgets/common.dart';
import 'web_apps.dart';
import 'web_player_screen.dart';
import '../../l10n/l10n.dart';

/// Ana sayfadaki "Uygulamalar" satırı: YouTube (OtoTV içinde), Netflix (kısayol).
class AppsRail extends ConsumerWidget {
  const AppsRail({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: context.l10n.apps),
        SizedBox(
          height: 96,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: WebApps.all.length,
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemBuilder: (context, i) => _AppTile(app: WebApps.all[i]),
          ),
        ),
      ],
    );
  }
}

class _AppTile extends ConsumerWidget {
  const _AppTile({required this.app});
  final WebApp app;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: () => openWebApp(context, ref, app),
        child: Ink(
          width: 216,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.card),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [app.color.withValues(alpha: 0.22), AppColors.surface],
            ),
            border: Border.all(color: AppColors.stroke),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: app.color, borderRadius: BorderRadius.circular(14)),
                child: Icon(app.icon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(app.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    if (app.inApp || app.browser)
                      Row(
                        children: [
                          Icon(app.inApp ? Icons.check_circle_rounded : (app.browser ? Icons.public_rounded : Icons.open_in_new_rounded),
                              size: 12, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(app.inApp ? context.l10n.appInside : context.l10n.appInBrowser,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
