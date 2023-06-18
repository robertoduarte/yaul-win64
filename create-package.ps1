
$rootPath = $(Get-Location)
$tmpPath = "$rootPath/temp"

$settings = Get-Content -Raw -Path "settings.json" | ConvertFrom-Json
$version = $settings | Select-Object -ExpandProperty libyaul_version
$libyaul_examples_version = $settings | Select-Object -ExpandProperty libyaul_examples_version

$packageName = "yaul-$version-win64-$(get-date -f yyyyMMdd).zip"
$buildPath = "$tmpPath/yaul-$version"

# Helper functions

Function DownloadFile([String] $address) {
    $fileName = $address.Substring($address.LastIndexOf("/") + 1)
    $filePath = "$tmpPath/$fileName"
    Invoke-WebRequest -URI $address -OutFile $filePath
    return $filePath
}

function Unpack([String] $source, [String] $destination) {

    if (-Not $(Test-Path $destination)) {
        New-Item $destination -ItemType Directory | Out-Null
    }
    $tempExtractPath = $source + "_dir"

    New-Item $tempExtractPath -ItemType Directory

    if ($source.Contains("zip")) { 
        Expand-Archive -Force $source -DestinationPath $tempExtractPath
    }
    else {
        $tempFilePath = $(Split-Path -Path $source)
        7za.exe x $source -o"$tempFilePath"
        $source = $source.replace(".xz", "")
        7za.exe x $source -o"$tempExtractPath"
    }

    if ((Get-ChildItem $tempExtractPath | Measure-Object).Count -gt 1) {
        Copy-Item -Recurse -Force -Path "$tempExtractPath/*" -Destination $destination
    }
    else {
        Copy-Item -Recurse -Force -Path "$tempExtractPath/*/*" -Destination $destination
    }

    if ($(Test-Path $tempExtractPath)) {
        Remove-Item -Path $tempExtractPath -Recurse -Force
    }
}

Set-Location "$rootPath/libyaul"
git checkout tags/$version
Set-Location $rootPath

Set-Location "$rootPath/libyaul-examples"
git checkout $libyaul_examples_version
Set-Location $rootPath

if ($(Test-Path $tmpPath)) {
    Remove-Item $tmpPath -Recurse -Force
}

New-Item $tmpPath -ItemType Directory | Out-Null
New-Item $buildPath -ItemType Directory | Out-Null

$7zip_url = $settings | Select-Object -ExpandProperty 7zip_url
$downloaded_file = DownloadFile $7zip_url
Unpack $downloaded_file "$tmpPath/7zip"

$Env:PATH += ";$tmpPath/7zip"

$base_mingw_url = $settings | Select-Object -ExpandProperty base_mingw_url
$downloaded_file = DownloadFile $base_mingw_url
Unpack $downloaded_file "$buildPath/msys2"

$gcc_mingw_url = $settings | Select-Object -ExpandProperty gcc_mingw_url
$downloaded_file = DownloadFile $gcc_mingw_url
Unpack $downloaded_file "$buildPath/msys2/usr"

$sh2eb_elf_url = $settings | Select-Object -ExpandProperty sh2eb_elf_url
$downloaded_file = DownloadFile $sh2eb_elf_url
Unpack $downloaded_file "$buildPath/sh2eb-elf"

$yabause_url = $settings | Select-Object -ExpandProperty yabause_url
$downloaded_file = DownloadFile $yabause_url
Unpack $downloaded_file "$buildPath/emulators/yabause"

$mednafen_url = $settings | Select-Object -ExpandProperty mednafen_url
$downloaded_file = DownloadFile $mednafen_url
Unpack $downloaded_file "$buildPath/emulators/mednafen"

Copy-Item -Recurse -Path "$rootPath/libyaul" -Destination $buildPath
Copy-Item -Recurse -Path "$rootPath/libyaul-examples" -Destination $buildPath
Copy-Item -Path "$rootPath/setenv.bat" -Destination $buildPath

foreach ($example in $(Get-ChildItem -Directory -Path "$buildPath/libyaul-examples")) { 
    Copy-Item -Recurse -Path "$rootPath/project_template/*" -Destination $example.FullName
}

Set-Location "$buildPath/libyaul"
$Env:PATH += ";$buildPath/sh2eb-elf/bin"
$Env:PATH += ";$buildPath/msys2/usr/bin"
$buildPath = $buildPath.Replace('\', '/')
$Env:YAUL_INSTALL_ROOT = "$buildPath/sh2eb-elf"
$Env:YAUL_ARCH_SH_PREFIX = "sh2eb-elf"
$Env:YAUL_ARCH_M68K_PREFIX = "m68keb-elf"
$Env:YAUL_BUILD_ROOT = "$buildPath/libyaul"
$Env:YAUL_BUILD = "build"
$Env:YAUL_CDB = "0"
$Env:YAUL_OPTION_DEV_CARTRIDGE = "0"
$Env:YAUL_OPTION_MALLOC_IMPL = "tlsf"
$Env:YAUL_OPTION_SPIN_ON_ABORT = "1"
$Env:YAUL_OPTION_BUILD_GDB = "0"
$Env:YAUL_OPTION_BUILD_ASSERT = "1"
$Env:SILENT = "1"
$Env:MAKE_ISO_XORRISO = "$buildPath/msys2/usr/bin/xorrisofs"
make install

Write-Host "Creating package: $packageName..."

Compress-Archive -Path $buildPath -DestinationPath "$rootPath/$packageName"

Write-Host "Finished!"