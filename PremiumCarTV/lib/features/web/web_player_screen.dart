import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import '../../core/theme.dart';
import '../../state/providers.dart';
import 'web_apps.dart';
import '../../l10n/l10n.dart';

Future<void> openWebApp(BuildContext context, WidgetRef ref, WebApp app) async {
  if (!app.inApp) {
    final ok = await launchExternalApp(app);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.appOpenFailed(app.name))));
    }
    return;
  }
  // Aynı anda iki ses çalmasın.
  await ref.read(playerProvider.notifier).player.pause();
  if (!context.mounted) return;
  await Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute(builder: (_) => WebPlayerScreen(app: app)),
  );
}

/// Bir hizmetin mobil sitesini OtoTV içinde açar. Video tam ekrana
/// geçtiğinde ekran yataya döner ve kapanmaz.
class WebPlayerScreen extends StatefulWidget {
  const WebPlayerScreen({super.key, required this.app});
  final WebApp app;

  @override
  State<WebPlayerScreen> createState() => _WebPlayerScreenState();
}

class _WebPlayerScreenState extends State<WebPlayerScreen> {
  late final WebViewController _controller;
  double _progress = 0;
  bool _canGoBack = false;
  Widget? _fullscreen;

  @override
  void initState() {
    super.initState();
    final PlatformWebViewControllerCreationParams params =
        WebViewPlatform.instance is WebKitWebViewPlatform
            ? WebKitWebViewControllerCreationParams(
                allowsInlineMediaPlayback: true,
                mediaTypesRequiringUserAction: const {},
              )
            : const PlatformWebViewControllerCreationParams();

    _controller = WebViewController.fromPlatformCreationParams(
      params,
      // Yalnızca kopya korumalı video (DRM) iznine onay; kamera/mikrofon reddedilir.
      onPermissionRequest: (request) {
        final onlyDrm = request.types.isNotEmpty &&
            request.types.every((t) => t == AndroidWebViewPermissionResourceType.protectedMediaId);
        onlyDrm ? request.grant() : request.deny();
      },
    )
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppColors.background)
      ..setNavigationDelegate(NavigationDelegate(
        onProgress: (p) => mounted ? setState(() => _progress = p / 100) : null,
        onPageFinished: (_) => _refreshBack(),
        onUrlChange: (_) => _refreshBack(),
        onNavigationRequest: (req) {
          // Alt çerçeveler (reklam, oynatıcı) serbest; yalnızca sayfa geçişi denetlenir.
          if (!req.isMainFrame) return NavigationDecision.navigate;
          final uri = Uri.tryParse(req.url);
          // "Uygulamada aç" (intent://, vnd.youtube://) ve dış siteler engellenir.
          return uri != null && widget.app.allows(uri)
              ? NavigationDecision.navigate
              : NavigationDecision.prevent;
        },
      ))
      ..loadRequest(Uri.parse(widget.app.url));

    final platform = _controller.platform;
    if (platform is AndroidWebViewController) {
      platform.setMediaPlaybackRequiresUserGesture(false);
      platform.setCustomWidgetCallbacks(
        onShowCustomWidget: (widget, _) => _enterFullscreen(widget),
        onHideCustomWidget: _exitFullscreen,
      );
    } else if (platform is WebKitWebViewController) {
      platform.setAllowsBackForwardNavigationGestures(true);
    }
    WakelockPlus.enable();
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    _restoreOrientation();
    super.dispose();
  }

  Future<void> _refreshBack() async {
    final can = await _controller.canGoBack();
    if (mounted && can != _canGoBack) setState(() => _canGoBack = can);
  }

  void _enterFullscreen(Widget video) {
    setState(() => _fullscreen = video);
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  void _exitFullscreen() {
    setState(() => _fullscreen = null);
    _restoreOrientation();
  }

  void _restoreOrientation() {
    SystemChrome.setPreferredOrientations(const []);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  Future<void> _back() async {
    if (_fullscreen != null) {
      _exitFullscreen();
    } else if (await _controller.canGoBack()) {
      await _controller.goBack();
    } else if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  _Bar(
                    app: widget.app,
                    canGoBack: _canGoBack,
                    progress: _progress,
                    onClose: () => Navigator.of(context).pop(),
                    onBack: _back,
                    onReload: _controller.reload,
                    onHome: () => _controller.loadRequest(Uri.parse(widget.app.url)),
                  ),
                  Expanded(child: WebViewWidget(controller: _controller)),
                ],
              ),
            ),
            if (_fullscreen != null) Positioned.fill(child: ColoredBox(color: Colors.black, child: _fullscreen)),
          ],
        ),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.app,
    required this.canGoBack,
    required this.progress,
    required this.onClose,
    required this.onBack,
    required this.onReload,
    required this.onHome,
  });

  final WebApp app;
  final bool canGoBack;
  final double progress;
  final VoidCallback onClose;
  final VoidCallback onBack;
  final VoidCallback onReload;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.background,
      child: Column(
        children: [
          SizedBox(
            height: 52,
            child: Row(
              children: [
                IconButton(tooltip: context.l10n.close, onPressed: onClose, icon: const Icon(Icons.close_rounded)),
                IconButton(
                  tooltip: context.l10n.back,
                  onPressed: canGoBack ? onBack : null,
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(app.icon, color: app.color, size: 22),
                      const SizedBox(width: 8),
                      Text(app.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    ],
                  ),
                ),
                IconButton(tooltip: context.l10n.homePage, onPressed: onHome, icon: const Icon(Icons.home_outlined)),
                IconButton(tooltip: context.l10n.refresh, onPressed: onReload, icon: const Icon(Icons.refresh_rounded)),
              ],
            ),
          ),
          AnimatedOpacity(
            opacity: progress < 1 ? 1 : 0,
            duration: const Duration(milliseconds: 300),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 2,
              color: AppColors.gold,
              backgroundColor: Colors.transparent,
            ),
          ),
        ],
      ),
    );
  }
}
