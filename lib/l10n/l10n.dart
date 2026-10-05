import 'package:flutter/widgets.dart';

import '../data/app_error.dart';
import '../data/models.dart';
import 'app_localizations.dart';

export 'app_localizations.dart';

extension L10nContext on BuildContext {
  L10n get l10n => L10n.of(this);
}

/// Veri katmanı hatasını seçili dilde okunur metne çevirir.
String describeError(L10n l, Object error) {
  if (error is! AppException) return l.errUnknown;
  return switch (error.code) {
    AppErrorCode.invalidAddress => l.errInvalidAddress,
    AppErrorCode.httpStatus => l.errHttpStatus(error.status ?? 0),
    AppErrorCode.noPlayable => l.errNoPlayable,
    AppErrorCode.download => l.errDownload,
    AppErrorCode.serverUnexpected => l.errServerUnexpected,
    AppErrorCode.noSession => l.errNoSession,
    AppErrorCode.unreachable => l.errUnreachable,
    AppErrorCode.sessionExpired => l.errSessionExpired,
    AppErrorCode.badCredentials => l.errBadCredentials,
    AppErrorCode.serverNotFound => l.errServerNotFound(error.detail ?? ''),
    AppErrorCode.serverStatus => l.errServerStatus(error.status ?? 0),
  };
}

/// Listede grubu olmayan kanalların iç grubu ("Diğer") seçili dilde gösterilir.
String groupLabel(L10n l, String group) => group == Channel.defaultGroup ? l.otherGroup : group;
