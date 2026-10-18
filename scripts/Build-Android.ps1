param([string]$JdkPath = $env:JAVA_HOME, [switch]$Universal, [switch]$SkipChecks)
$ErrorActionPreference = 'Stop'
$taskRoot = Split-Path -Parent $PSScriptRoot
$taskOldJava = $env:JAVA_HOME
$taskOldGradleOptions = $env:GRADLE_OPTS
$taskOldPubCache = $env:PUB_CACHE
Push-Location $taskRoot
try {
    $env:PUB_CACHE = Join-Path $taskRoot '.pub-cache'
    if ($JdkPath) {
        if (-not (Test-Path -LiteralPath (Join-Path $JdkPath 'bin/java.exe'))) { throw "JDK not found: $JdkPath" }
        $env:JAVA_HOME = $JdkPath
        $env:GRADLE_OPTS = ($taskOldGradleOptions + ' -Dorg.gradle.java.home="' + $JdkPath + '"').Trim()
    }
    & flutter pub get
    if ($LASTEXITCODE -ne 0) { throw 'flutter pub get failed' }
    & flutter gen-l10n
    if ($LASTEXITCODE -ne 0) { throw 'Localization generation failed' }
    if (-not $SkipChecks) {
        & flutter analyze
        if ($LASTEXITCODE -ne 0) { throw 'Static analysis failed' }
        & flutter test --exclude-tags preview
        if ($LASTEXITCODE -ne 0) { throw 'Flutter tests failed' }
        Push-Location android
        try {
            & .\gradlew.bat :app:testDebugUnitTest :app:lintDebug --console=plain
            if ($LASTEXITCODE -ne 0) { throw 'Android tests failed' }
        } finally { Pop-Location }
    }
    if ($Universal) { & flutter build apk --release }
    else { & flutter build apk --release --split-per-abi }
    if ($LASTEXITCODE -ne 0) { throw 'APK build failed' }
    Get-ChildItem -LiteralPath 'build/app/outputs/flutter-apk' -Filter '*release.apk' | Select-Object FullName, Length
} finally {
    $env:JAVA_HOME = $taskOldJava
    $env:GRADLE_OPTS = $taskOldGradleOptions
    $env:PUB_CACHE = $taskOldPubCache
    Pop-Location
}
