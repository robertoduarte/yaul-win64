@ECHO off

SET YAUL_ROOT=%~dp0

if not "%YAUL_ROOT%"=="%YAUL_ROOT: =%" (
    echo "Yaul seems to be installed in a path with spaces, this is not supported, please change it to a path without spaces and try again."
    exit 1
)

SET "YAUL_ROOT=%YAUL_ROOT:\=/%"
SET "PATH=%YAUL_ROOT%msys2/usr/bin;%PATH%"

SET YAUL_INSTALL_ROOT=%YAUL_ROOT%/sh2eb-elf
SET YAUL_ARCH_SH_PREFIX=sh2eb-elf
SET YAUL_ARCH_M68K_PREFIX=m68kelb-elf
SET YAUL_BUILD_ROOT=%YAUL_ROOT%libyaul
SET YAUL_BUILD=build
SET YAUL_CDB=0
SET YAUL_OPTION_DEV_CARTRIDGE=0
SET YAUL_OPTION_MALLOC_IMPL=tlsf
SET YAUL_OPTION_SPIN_ON_ABORT=1
SET YAUL_OPTION_BUILD_GDB=0
SET YAUL_OPTION_BUILD_ASSERT=1
SET SILENT=1
SET MAKE_ISO_XORRISOFS=%YAUL_ROOT%msys2/usr/bin/xorrisofs
