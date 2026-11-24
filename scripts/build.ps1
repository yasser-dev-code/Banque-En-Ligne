$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$sourceRoot = Join-Path $projectRoot 'BanqueEnLigne\src'
$outputRoot = Join-Path $projectRoot 'build\classes'

function Find-JavaTool([string]$toolName) {
    if ($env:JAVA_HOME) {
        $candidate = Join-Path $env:JAVA_HOME "bin\$toolName.exe"
        if (Test-Path -LiteralPath $candidate) { return $candidate }
    }

    $command = Get-Command $toolName -ErrorAction SilentlyContinue
    if ($command) { return $command.Source }

    $jdks = Join-Path $env:USERPROFILE '.jdks'
    if (Test-Path -LiteralPath $jdks) {
        $candidate = Get-ChildItem -LiteralPath $jdks -Directory |
            Sort-Object LastWriteTime -Descending |
            ForEach-Object { Join-Path $_.FullName "bin\$toolName.exe" } |
            Where-Object { Test-Path -LiteralPath $_ } |
            Select-Object -First 1
        if ($candidate) { return $candidate }
    }

    throw "Java tool '$toolName' was not found. Install JDK 17+ or set JAVA_HOME."
}

$javac = Find-JavaTool 'javac'
if (Test-Path -LiteralPath $outputRoot) {
    Remove-Item -LiteralPath $outputRoot -Recurse -Force
}
New-Item -ItemType Directory -Path $outputRoot -Force | Out-Null

$sources = @(Get-ChildItem -LiteralPath $sourceRoot -Recurse -Filter '*.java' |
    ForEach-Object { $_.FullName })
if ($sources.Count -eq 0) { throw 'No Java sources were found.' }

& $javac -encoding UTF-8 -d $outputRoot $sources
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "Compiled $($sources.Count) source files to $outputRoot"
