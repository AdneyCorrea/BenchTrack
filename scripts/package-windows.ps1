param(
    [string]$ReleaseDirectory = 'build/windows/x64/runner/Release',
    [string]$OutputPath = 'dist/BenchTrack-windows-x64.zip'
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
if (-not [IO.Path]::IsPathRooted($ReleaseDirectory)) {
    $ReleaseDirectory = Join-Path $projectRoot $ReleaseDirectory
}
$release = (Resolve-Path -LiteralPath $ReleaseDirectory).ProviderPath
foreach ($required in @('benchtrack.exe', 'flutter_windows.dll', 'data')) {
    if (-not (Test-Path -LiteralPath (Join-Path $release $required))) {
        throw "Arquivo de build ausente: $required. Execute flutter build windows --release."
    }
}

# App-local Visual C++ runtime: the user does not need Visual Studio or a separate installer.
$vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio/Installer/vswhere.exe'
$installation = & $vswhere -latest -products '*' -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
if ($LASTEXITCODE -ne 0 -or -not $installation) { throw 'Visual Studio C++ não encontrado.' }
$redistRoot = Join-Path $installation 'VC/Redist/MSVC'
$runtime = Get-ChildItem -LiteralPath $redistRoot -Directory |
    Where-Object { $_.Name -match '^\d+\.\d+\.\d+$' } |
    Sort-Object { [version]$_.Name } -Descending |
    ForEach-Object { Get-ChildItem -LiteralPath (Join-Path $_.FullName 'x64') -Directory -Filter 'Microsoft.VC*.CRT' } |
    Select-Object -First 1
if (-not $runtime) { throw 'Runtime redistribuível C++ x64 não encontrado.' }
Get-ChildItem -LiteralPath $runtime.FullName -Filter '*.dll' |
    ForEach-Object { Copy-Item -LiteralPath $_.FullName -Destination $release }
foreach ($dll in @('msvcp140.dll', 'vcruntime140.dll', 'vcruntime140_1.dll')) {
    if (-not (Test-Path -LiteralPath (Join-Path $release $dll))) { throw "Runtime ausente: $dll" }
}

if (-not [IO.Path]::IsPathRooted($OutputPath)) {
    $OutputPath = Join-Path $projectRoot $OutputPath
}
$output = [IO.Path]::GetFullPath($OutputPath)
New-Item -ItemType Directory -Force -Path (Split-Path $output) | Out-Null
$files = @(Get-ChildItem -LiteralPath $release | ForEach-Object { $_.FullName })
Compress-Archive -LiteralPath $files -DestinationPath $output -Force
Write-Output "Pacote criado: $output"
