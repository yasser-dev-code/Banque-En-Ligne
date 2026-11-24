$ErrorActionPreference = 'Stop'

& (Join-Path $PSScriptRoot 'build.ps1')
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$projectRoot = Split-Path -Parent $PSScriptRoot
$appClasses = Join-Path $projectRoot 'build\classes'
$testClasses = Join-Path $projectRoot 'build\test-classes'
$testRoot = Join-Path $projectRoot 'tests'

if ($env:JAVA_HOME) {
    $javac = Join-Path $env:JAVA_HOME 'bin\javac.exe'
    $java = Join-Path $env:JAVA_HOME 'bin\java.exe'
} else {
    $jdk = Get-ChildItem -LiteralPath (Join-Path $env:USERPROFILE '.jdks') -Directory |
        Sort-Object LastWriteTime -Descending |
        Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName 'bin\javac.exe') } |
        Select-Object -First 1
    if ($jdk) {
        $javac = Join-Path $jdk.FullName 'bin\javac.exe'
        $java = Join-Path $jdk.FullName 'bin\java.exe'
    } else {
        $javac = (Get-Command javac -ErrorAction Stop).Source
        $java = (Get-Command java -ErrorAction Stop).Source
    }
}

if (Test-Path -LiteralPath $testClasses) {
    Remove-Item -LiteralPath $testClasses -Recurse -Force
}
New-Item -ItemType Directory -Path $testClasses -Force | Out-Null
$tests = @(Get-ChildItem -LiteralPath $testRoot -Recurse -Filter '*.java' |
    ForEach-Object { $_.FullName })

& $javac -encoding UTF-8 -cp $appClasses -d $testClasses $tests
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& $java -ea -cp "$appClasses;$testClasses" banque.SmokeTest
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
