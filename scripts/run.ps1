$ErrorActionPreference = 'Stop'

& (Join-Path $PSScriptRoot 'build.ps1')
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$projectRoot = Split-Path -Parent $PSScriptRoot
$classes = Join-Path $projectRoot 'build\classes'

if ($env:JAVA_HOME -and (Test-Path -LiteralPath (Join-Path $env:JAVA_HOME 'bin\java.exe'))) {
    $java = Join-Path $env:JAVA_HOME 'bin\java.exe'
} else {
    $javaCommand = Get-Command java -ErrorAction SilentlyContinue
    if ($javaCommand) {
        $java = $javaCommand.Source
    } else {
        $java = Get-ChildItem -LiteralPath (Join-Path $env:USERPROFILE '.jdks') -Directory |
            Sort-Object LastWriteTime -Descending |
            ForEach-Object { Join-Path $_.FullName 'bin\java.exe' } |
            Where-Object { Test-Path -LiteralPath $_ } |
            Select-Object -First 1
    }
}
if (-not $java) { throw 'Java was not found. Install JDK 17+ or set JAVA_HOME.' }

& $java -cp $classes banque.Main
