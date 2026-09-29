import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/theme.dart';
import '../../l10n/l10n.dart';

/// Kamera ile QR okur ve ilk geçerli adresi geri döndürür.
/// Görüntüler cihazda çözülür; hiçbir kare saklanmaz veya gönderilmez.
class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key});

  static Future<String?> scan(BuildContext context) => Navigator.of(context, rootNavigator: true)
      .push<String>(MaterialPageRoute(builder: (_) => const QrScanScreen()));

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  bool _done = false;

  void _onDetect(BarcodeCapture capture) {
    if (_done) return;
    for (final code in capture.barcodes) {
      final value = code.rawValue?.trim();
      if (value != null && Uri.tryParse(value)?.hasScheme == true) {
        _done = true;
        HapticFeedback.mediumImpact();
        Navigator.of(context).pop(value);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const window = 260.0;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: Text(context.l10n.qrTitle)),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: _onDetect,
            errorBuilder: (context, error) => Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(context.l10n.qrCameraDenied, textAlign: TextAlign.center),
              ),
            ),
          ),
          Center(
            child: Container(
              width: window,
              height: window,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppColors.gold, width: 3),
              ),
            ),
          ),
          Positioned(
            left: 32,
            right: 32,
            bottom: 80,
            child: Text(
              context.l10n.qrHint,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
