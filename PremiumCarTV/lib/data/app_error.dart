/// Veri katmanı hataları dilden bağımsızdır; metne arayüz çevirir
/// (bkz. `describeError`).
enum AppErrorCode {
  invalidAddress,
  httpStatus,
  noPlayable,
  download,
  serverUnexpected,
  noSession,
  unreachable,
  sessionExpired,
  badCredentials,
  serverNotFound,
  serverStatus,
}

class AppException implements Exception {
  const AppException(this.code, {this.status, this.detail});

  final AppErrorCode code;

  /// HTTP durum kodu (httpStatus / serverStatus).
  final int? status;

  /// Ek bilgi, ör. sunucu türü (serverNotFound).
  final String? detail;

  @override
  String toString() => 'AppException(${code.name}${status == null ? '' : ', $status'})';
}
