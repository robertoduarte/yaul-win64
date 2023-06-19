
$rootPath = $(Get-Location)

$settings = Get-Content -Raw -Path "settings.json" | ConvertFrom-Json
$version = $settings | Select-Object -ExpandProperty libyaul_version
$libyaul_examples_version = $settings | Select-Object -ExpandProperty libyaul_examples_version

$packageName = "yaul-$version-win64-$(get-date -f yyyyMMdd).zip"
$tmpPath = "$rootPath/temp/yaul-$version-win64-$(get-date -f yyyyMMdd)"

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

$7zip_url = $settings | Select-Object -ExpandProperty 7zip_url
$downloaded_file = DownloadFile $7zip_url
Unpack $downloaded_file "$tmpPath/7zip"

$Env:PATH += ";$tmpPath/7zip"

$base_mingw_url = $settings | Select-Object -ExpandProperty base_mingw_url
$downloaded_file = DownloadFile $base_mingw_url
Unpack $downloaded_file "$tmpPath/msys2"

$gcc_mingw_url = $settings | Select-Object -ExpandProperty gcc_mingw_url
$downloaded_file = DownloadFile $gcc_mingw_url
Unpack $downloaded_file "$tmpPath/msys2/usr"

$sh2eb_elf_url = $settings | Select-Object -ExpandProperty sh2eb_elf_url
$downloaded_file = DownloadFile $sh2eb_elf_url
Unpack $downloaded_file "$tmpPath/sh2eb-elf"

$yabause_url = $settings | Select-Object -ExpandProperty yabause_url
$downloaded_file = DownloadFile $yabause_url
Unpack $downloaded_file "$tmpPath/emulators/yabause"

$mednafen_url = $settings | Select-Object -ExpandProperty mednafen_url
$downloaded_file = DownloadFile $mednafen_url
Unpack $downloaded_file "$tmpPath/emulators/mednafen"

Copy-Item -Recurse -Path "$rootPath/libyaul" -Destination $tmpPath
Copy-Item -Recurse -Path "$rootPath/libyaul-examples" -Destination $tmpPath
Copy-Item -Recurse -Path "$rootPath/scripts" -Destination $tmpPath

foreach ($example in $(Get-ChildItem -Directory -Path "$tmpPath/libyaul-examples")) { 
    Copy-Item -Recurse -Path "$rootPath/project_template/*" -Destination $example.FullName
}

Set-Location "$tmpPath/scripts"
cmd.exe /c 'build_libyaul.bat'

Write-Host "Creating package: $packageName..."

Compress-Archive `
        -Path $tmpPath/emulators, `
        $tmpPath/libyaul, `
        $tmpPath/libyaul-examples, `
        $tmpPath/msys2, `
        $tmpPath/scripts, `
        $tmpPath/sh2eb-elf `
        -DestinationPath "$rootPath/$packageName"

Write-Host "Finished!"