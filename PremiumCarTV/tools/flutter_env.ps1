# Kullanıcı adındaki '&' karakteri Flutter'ın .bat betiklerini bozuyor.
# Bu betik, kullanıcı klasörlerini 8.3 kısa adla (CENGIZ~1) yönlendirir.
# Kullanım:  . .\tools\flutter_env.ps1   ardından   flutter <komut>
$short = 'C:\Users\CENGIZ~1'
$env:USERPROFILE  = $short
$env:HOMEPATH     = '\Users\CENGIZ~1'
$env:LOCALAPPDATA = "$short\AppData\Local"
$env:APPDATA      = "$short\AppData\Roaming"
$env:TEMP         = "$short\AppData\Local\Temp"
$env:TMP          = $env:TEMP
$env:PUB_CACHE    = 'C:\pub-cache'
$env:ANDROID_HOME = "$short\AppData\Local\Android\Sdk"
$env:ANDROID_SDK_ROOT = $env:ANDROID_HOME
$env:JAVA_HOME    = 'C:\Program Files\Android\Android Studio\jbr'
$env:GRADLE_USER_HOME = "$short\.gradle"
# Java'nın iç soket dosyaları '&' içeren TEMP'te "Unable to establish loopback connection" verir.
New-Item -ItemType Directory -Force C:\gradle-tmp | Out-Null
$env:JAVA_TOOL_OPTIONS = '-Djdk.net.unixdomain.tmpdir=C:\gradle-tmp -Djava.io.tmpdir=C:\gradle-tmp'
$env:Path = @(
  'C:\flutter\bin',
  "$env:JAVA_HOME\bin",
  "$env:ANDROID_HOME\platform-tools",
  "$env:ANDROID_HOME\emulator",
  'C:\Program Files\Git\cmd',
  'C:\Program Files\nodejs',
  'C:\Windows\System32',
  'C:\Windows',
  'C:\Windows\System32\WindowsPowerShell\v1.0'
) -join ';'
