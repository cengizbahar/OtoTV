# Test APK'sını bağlı emülatöre / telefona kurar ve OtoTV'yi açar.
#
# Kullanım (proje klasöründe):
#   .\tools\install_apk.ps1                 # dist\OtoTV-test.apk
#   .\tools\install_apk.ps1 -Build          # önce derle, sonra kur
#   .\tools\install_apk.ps1 -Apk yol\x.apk  # başka bir APK
param([switch]$Build, [string]$Apk)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root
. (Join-Path $PSScriptRoot 'flutter_env.ps1')

if ($Build) { & (Join-Path $PSScriptRoot 'build_apk.ps1') }
if (-not $Apk) { $Apk = Join-Path $root 'dist\OtoTV-test.apk' }
if (-not (Test-Path $Apk)) { throw "APK bulunamadı: $Apk  (önce .\tools\build_apk.ps1)" }

# Emülatörün kendi adb yolu '&' içeren klasörde olduğu için kısa yoldaki adb kullanılır.
$adb = Join-Path $env:ANDROID_HOME 'platform-tools\adb.exe'
$devices = (& $adb devices) | Select-String "`tdevice$"
if (-not $devices) { throw 'Bağlı cihaz yok. Emülatörü aç ya da telefonu USB hata ayıklama ile bağla.' }

Write-Host "Kuruluyor: $Apk" -ForegroundColor DarkGray
& $adb install -r $Apk
if ($LASTEXITCODE -ne 0) { throw 'Kurulum başarısız.' }
& $adb shell am force-stop com.ototv.app
& $adb shell monkey -p com.ototv.app -c android.intent.category.LAUNCHER 1 | Out-Null
Write-Host 'OtoTV kuruldu ve açıldı.' -ForegroundColor Green
