import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// OtoTV Plus yapılandırması. Anahtarlar koda yazılmaz; derlemede verilir:
///
///   flutter build apk --dart-define-from-file=.env.json
///
/// `.env.json` örneği için `.env.example.json` dosyasına bak.
abstract final class PremiumConfig {
  static const androidKey = String.fromEnvironment('RC_ANDROID_KEY');
  static const iosKey = String.fromEnvironment('RC_IOS_KEY');

  /// RevenueCat panelindeki yetki (entitlement) kimliği.
  static const entitlement = 'plus';

  /// Yalnızca geliştirme: mağaza olmadan Plus özelliklerini dener.
  static const debugUnlock = bool.fromEnvironment('PLUS_DEBUG_UNLOCK') && !kReleaseMode;

  /// Ücretsiz sürümde eklenebilecek kaynak sayısı.
  static const freeSourceLimit = 2;

  /// App Store Connect ve Google Play Console'da BİREBİR bu kimliklerle
  /// oluşturulacak ürünler (bkz. docs/ODEME_KURULUM.md).
  static const productMonthly = 'ototv_plus_monthly';
  static const productAnnual = 'ototv_plus_annual';
  static const productLifetime = 'ototv_plus_lifetime';

  /// Mağaza bağlı değilken geliştirme derlemesinde örnek fiyatlarla satış
  /// ekranını göster. Mağaza sürümünde hiçbir zaman çalışmaz.
  static bool get previewPlans => !kReleaseMode && !isConfigured;

  static String get apiKey => Platform.isIOS ? iosKey : androidKey;
  static bool get isConfigured => apiKey.isNotEmpty;
}

enum PlanKind { monthly, annual, lifetime }

/// Ücretsiz deneme süresi (ör. 7 gün).
typedef TrialPeriod = ({PeriodUnit unit, int count});

class Plan {
  const Plan({required this.kind, required this.price, this.trial, this.package});

  factory Plan.fromPackage(PlanKind kind, Package package) {
    final intro = package.storeProduct.introductoryPrice;
    return Plan(
      kind: kind,
      price: package.storeProduct.priceString,
      trial: intro != null && intro.price == 0
          ? (unit: intro.periodUnit, count: intro.periodNumberOfUnits)
          : null,
      package: package,
    );
  }

  final PlanKind kind;

  /// Mağazanın kullanıcının para biriminde biçimlendirdiği fiyat ("₺99,99").
  final String price;
  final TrialPeriod? trial;

  /// null: önizleme planı (mağaza bağlı değil, satın alınamaz).
  final Package? package;

  bool get hasFreeTrial => trial != null;
  bool get isPreview => package == null;

  /// Geliştirme önizlemesi; önerilen fiyatlar (docs/ODEME_KURULUM.md).
  static const previews = [
    Plan(kind: PlanKind.monthly, price: '₺99,99'),
    Plan(kind: PlanKind.annual, price: '₺499,99', trial: (unit: PeriodUnit.day, count: 7)),
    Plan(kind: PlanKind.lifetime, price: '₺999,99'),
  ];
}

class PremiumState {
  const PremiumState({
    this.isPlus = false,
    this.ready = false,
    this.configured = false,
    this.plans = const [],
  });

  final bool isPlus;

  /// Mağaza bilgisi yüklendi (ya da yapılandırma yok).
  final bool ready;
  final bool configured;
  final List<Plan> plans;

  PremiumState copyWith({bool? isPlus, bool? ready, List<Plan>? plans}) => PremiumState(
        isPlus: isPlus ?? this.isPlus,
        ready: ready ?? this.ready,
        configured: configured,
        plans: plans ?? this.plans,
      );
}

sealed class PurchaseOutcome {
  const PurchaseOutcome();
}

class PurchaseSucceeded extends PurchaseOutcome {
  const PurchaseSucceeded();
}

class PurchaseCancelled extends PurchaseOutcome {
  const PurchaseCancelled();
}

class PurchaseFailed extends PurchaseOutcome {
  const PurchaseFailed(this.message);
  final String message;
}

/// Önizleme planına basıldı; gerçek satın alma yapılmadı.
class PurchasePreviewOnly extends PurchaseOutcome {
  const PurchasePreviewOnly();
}

final premiumProvider = NotifierProvider<PremiumNotifier, PremiumState>(PremiumNotifier.new);

/// Plus üyeliği: RevenueCat ile App Store / Google Play satın alma,
/// geri yükleme ve yetki takibi. Makbuz doğrulaması RevenueCat'te yapılır.
class PremiumNotifier extends Notifier<PremiumState> {
  bool _started = false;

  @override
  PremiumState build() {
    if (PremiumConfig.debugUnlock) {
      return const PremiumState(isPlus: true, ready: true);
    }
    if (!PremiumConfig.isConfigured) {
      return PremiumState(ready: true, plans: PremiumConfig.previewPlans ? Plan.previews : const []);
    }
    scheduleMicrotask(_start);
    return const PremiumState(configured: true);
  }

  Future<void> _start() async {
    if (_started) return;
    _started = true;
    try {
      await Purchases.setLogLevel(kDebugMode ? LogLevel.debug : LogLevel.warn);
      await Purchases.configure(PurchasesConfiguration(PremiumConfig.apiKey));
      Purchases.addCustomerInfoUpdateListener(_apply);
      _apply(await Purchases.getCustomerInfo());
      await loadPlans();
    } catch (e) {
      debugPrint('Plus başlatılamadı: $e');
      state = state.copyWith(ready: true);
    }
  }

  void _apply(CustomerInfo info) {
    state = state.copyWith(
      isPlus: info.entitlements.active.containsKey(PremiumConfig.entitlement),
    );
  }

  /// RevenueCat "current offering" paketlerini aylık / yıllık / ömür boyu sırasıyla alır.
  Future<void> loadPlans() async {
    try {
      final offering = (await Purchases.getOfferings()).current;
      final plans = [
        if (offering?.monthly case final p?) Plan.fromPackage(PlanKind.monthly, p),
        if (offering?.annual case final p?) Plan.fromPackage(PlanKind.annual, p),
        if (offering?.lifetime case final p?) Plan.fromPackage(PlanKind.lifetime, p),
      ];
      state = state.copyWith(plans: plans, ready: true);
    } catch (e) {
      debugPrint('Plus planları alınamadı: $e');
      state = state.copyWith(ready: true);
    }
  }

  Future<PurchaseOutcome> purchase(Plan plan) async {
    final package = plan.package;
    if (package == null) return const PurchasePreviewOnly();
    try {
      final result = await Purchases.purchase(PurchaseParams.package(package));
      _apply(result.customerInfo);
      return state.isPlus ? const PurchaseSucceeded() : const PurchaseFailed('');
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      if (code == PurchasesErrorCode.purchaseCancelledError) return const PurchaseCancelled();
      return PurchaseFailed(e.message ?? code.name);
    }
  }

  /// true: geri yüklenen bir Plus yetkisi bulundu.
  Future<bool> restore() async {
    final info = await Purchases.restorePurchases();
    _apply(info);
    return state.isPlus;
  }
}
