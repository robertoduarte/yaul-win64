
$rootPath = $(Get-Location)
$tmpPath = "$rootPath/temp"

$settings = Get-Content -Raw -Path "settings.json" | ConvertFrom-Json
$version = $settings | Select-Object -ExpandProperty libyaul_version
$libyaul_examples_version = $settings | Select-Object -ExpandProperty libyaul_examples_version

$releaseName= "yaul-$version-win64"
$buildPath = "$tmpPath/yaul-$version"

# Helper functions

Function DownloadFile([String] $address) {
    $fileName = $address.Substring($address.LastIndexOf("/") + 1)
    $filePath = "$tmpPath/$fileName"
    Invoke-WebRequest -URI $address -OutFile $filePath
    return $filePath
}

function UnpackZip([String] $source, [String] $destination) {

    if (-Not $(Test-Path $destination)) {
        New-Item $destination -ItemType Directory | Out-Null
    }
    $tempExtractPath = $source + "_dir"

    New-Item $tempExtractPath -ItemType Directory

    Expand-Archive -Force $source -DestinationPath $tempExtractPath

    if ((Get-ChildItem $tempExtractPath | Measure-Object).Count -gt 1) {
        Copy-Item -Recurse -Path "$tempExtractPath/*" -Destination $destination
    }
    else {
        Copy-Item -Recurse -Path "$tempExtractPath/*/*" -Destination $destination
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

Write-Host "Downloading MSYS2 Installer..."

$msys2_installer_url = $settings | Select-Object -ExpandProperty msys2_installer_url
$msysInstaller = DownloadFile $msys2_installer_url

Set-Location $tmpPath
& "$msysInstaller"

Write-Host "Setting up MSYS2..."
$Env:PATH += ";$tmpPath/msys64/usr/bin"
sh -c "/etc/profile"
pacman -Syy
foreach ($tool in ($settings | Select-Object -ExpandProperty install_tools)){
    pacman -S --noconfirm $tool
}

New-Item "$buildPath/tool-chain/tmp" -ItemType Directory | Out-Null
Expand-Archive -Force "$rootPath/sh2eb-elf.zip" -DestinationPath "$buildPath/tool-chain/"
Rename-Item "$buildPath/tool-chain/sh2eb-elf" "usr"

foreach ($file in ($settings | Select-Object -ExpandProperty copy_to_bin)){
    Copy-Item -Path "$tmpPath/msys64/$file" -Destination "$buildPath/tool-chain/usr/bin"
}

Copy-Item -Recurse -Path "$rootPath/libyaul" -Destination $buildPath
Copy-Item -Path "$rootPath/scripts/set_yaul_root.bat" -Destination $buildPath

Set-Location "$rootPath/libyaul"
$Env:PATH += ";$buildPath/tool-chain/usr/bin"
$buildPath = $buildPath.Replace('\', '/')
$Env:YAUL_INSTALL_ROOT = "$buildPath/tool-chain/usr"
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
$Env:MAKE_ISO_XORRISO = "$buildPath/tool-chain/usr/bin/xorrisofs"
make install

$packageName= "$releaseName-slim-$(get-date -f yyyyMMdd).zip"

Write-Host "Creating slim zip package: $packageName..."

Compress-Archive -Path $buildPath -DestinationPath "$rootPath/$packageName"

Copy-Item -Recurse -Path "$rootPath/libyaul-examples" -Destination $buildPath

foreach ($example in $(Get-ChildItem -Directory -Path "$buildPath/libyaul-examples")) { 
    Copy-Item -Recurse -Path "$rootPath/project_template/*" -Destination $example.FullName
}

$packageName= "$releaseName-full-$(get-date -f yyyyMMdd).zip"

Write-Host "Creating full zip package: $packageName..."

Compress-Archive -Path $buildPath -DestinationPath "$rootPath/$packageName"

$yabause_url = $settings | Select-Object -ExpandProperty yabause_url
$downloaded_file = DownloadFile $yabause_url
UnpackZip $downloaded_file "$buildPath/emulators/yabause"

$mednafen_url = $settings | Select-Object -ExpandProperty mednafen_url
$downloaded_file = DownloadFile $mednafen_url
UnpackZip $downloaded_file "$buildPath/emulators/mednafen"

$packageName= "$releaseName-fat-$(get-date -f yyyyMMdd).zip"

Write-Host "Creating fat zip package: $packageName..."

Compress-Archive -Path $buildPath -DestinationPath "$rootPath/$packageName"

Write-Host "Finished!"
