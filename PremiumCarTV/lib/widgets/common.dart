import 'dart:ui';

import 'package:flutter/material.dart';

import '../core/brand.dart';
import '../core/theme.dart';

/// Buzlu cam yüzey: alt menü, mini oynatıcı ve kaplamalarda kullanılır.
class Glass extends StatelessWidget {
  const Glass({
    super.key,
    required this.child,
    this.radius = 26,
    this.padding = EdgeInsets.zero,
    this.opacity = 0.62,
  });

  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: AppColors.surfaceHigh.withValues(alpha: opacity),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: AppColors.stroke),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Altın direksiyon işareti + altın degrade "OtoTV" yazı markası.
class Wordmark extends StatelessWidget {
  const Wordmark({super.key, this.size = 26, this.showMark = true});
  final double size;
  final bool showMark;

  @override
  Widget build(BuildContext context) {
    final text = ShaderMask(
      shaderCallback: (r) => AppColors.goldGradient.createShader(r),
      child: Text(
        Brand.appName,
        style: TextStyle(
          fontSize: size,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.6,
          color: Colors.white,
        ),
      ),
    );
    if (!showMark) return text;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // splash.png'de işaret tuvalin yarısını kaplar; kırpmak için büyütülür.
        ClipRect(
          child: SizedBox.square(
            dimension: size * 1.15,
            child: OverflowBox(
              maxWidth: size * 2.3,
              maxHeight: size * 2.3,
              child: Image.asset('assets/branding/splash.png', width: size * 2.3, height: size * 2.3),
            ),
          ),
        ),
        SizedBox(width: size * 0.3),
        text,
      ],
    );
  }
}

/// Plus rozeti (taç + altın zemin).
class PlusBadge extends StatelessWidget {
  const PlusBadge({super.key, this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          gradient: AppColors.goldGradient,
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: AppColors.gold.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.workspace_premium_rounded, size: 16, color: Color(0xFF1A1206)),
            SizedBox(width: 4),
            Text(
              'PLUS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                color: Color(0xFF1A1206),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Kanal logosu; yoksa veya yüklenemezse baş harflerle monogram.
class ChannelLogo extends StatelessWidget {
  const ChannelLogo({super.key, required this.name, this.url, this.size = 44});
  final String name;
  final String? url;
  final double size;

  @override
  Widget build(BuildContext context) {
    final fallback = Center(
      child: Text(
        _initials(name),
        style: TextStyle(
          fontSize: size * 0.34,
          fontWeight: FontWeight.w800,
          color: AppColors.goldLight,
          letterSpacing: 0.5,
        ),
      ),
    );
    if (url == null) return SizedBox.square(dimension: size, child: fallback);
    return SizedBox.square(
      dimension: size,
      child: Image.network(
        url!,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => fallback,
      ),
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    return parts.take(2).map((p) => p.characters.first.toUpperCase()).join();
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surfaceHigh,
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
              ),
              child: Icon(icon, size: 40, color: AppColors.gold),
            ),
            const SizedBox(height: 24),
            Text(title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary, height: 1.45),
            ),
            if (actionLabel != null) ...[
              const SizedBox(height: 28),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.trailing, this.onTap});
  final String title;
  final String? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 12, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge),
          ),
          if (trailing != null)
            TextButton(
              onPressed: onTap,
              style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(trailing!),
                  const Icon(Icons.chevron_right_rounded, size: 20),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
