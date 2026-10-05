# OtoTV Android APK derleyici.
#
# Kullanım (Android Studio › Terminal veya PowerShell, proje klasöründe):
#   .\tools\build_apk.ps1            # Test: hızlı, Plus açık, araç ekranı testi
#   .\tools\build_apk.ps1 -Store     # Mağaza: Plus kapalı, RevenueCat anahtarlarıyla
#
# Çıktı: dist\OtoTV-test.apk  veya  dist\OtoTV-store.apk
param([switch]$Store)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

# Kullanıcı adındaki '&' karakteri Flutter betiklerini bozar; kısa yollarla çalıştır.
. (Join-Path $PSScriptRoot 'flutter_env.ps1')

$flutterArgs = @('build', 'apk')
if ($Store) {
    $flutterArgs += '--release'
    if (Test-Path '.env.json') { $flutterArgs += '--dart-define-from-file=.env.json' }
    else { Write-Warning '.env.json yok: satın alma bu derlemede çalışmaz.' }
    $out = 'OtoTV-store.apk'
} else {
    # profile: sürüm kadar hızlı, ama geliştirme ayarlarına izin verir.
    $flutterArgs += @('--profile', '--dart-define=PLUS_TEST_UNLOCK=true', '-PcarAppCategory=game')
    $out = 'OtoTV-test.apk'
}

Write-Host "flutter $($flutterArgs -join ' ')" -ForegroundColor DarkGray
flutter @flutterArgs
if ($LASTEXITCODE -ne 0) { throw "Derleme başarısız (kod $LASTEXITCODE)." }

$mode = if ($Store) { 'release' } else { 'profile' }
New-Item -ItemType Directory -Force dist | Out-Null
Copy-Item "build\app\outputs\flutter-apk\app-$mode.apk" "dist\$out" -Force
$mb = [math]::Round((Get-Item "dist\$out").Length / 1MB, 1)
Write-Host "`nHazır: $root\dist\$out ($mb MB)" -ForegroundColor Green
