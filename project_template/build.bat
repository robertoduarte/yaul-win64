@ECHO Off
if not exist %YAUL_ROOT% (
    echo "YAUL_ROOT environment variable not properly set please check installation."
) else (
    set PATH=%YAUL_ROOT%tool-chain/usr/bin/;%PATH%

    SET YAUL_INSTALL_ROOT=%YAUL_ROOT%tool-chain/usr
    SET YAUL_ARCH_SH_PREFIX=sh2eb-elf
    SET YAUL_ARCH_M68K_PREFIX=m68keb-elf
    SET YAUL_BUILD_ROOT=%YAUL_ROOT%libyaul
    SET YAUL_BUILD=build
    SET YAUL_CDB=0
    SET YAUL_OPTION_DEV_CARTRIDGE=0
    SET YAUL_OPTION_MALLOC_IMPL=tlsf
    SET YAUL_OPTION_SPIN_ON_ABORT=1
    SET YAUL_OPTION_BUILD_GDB=0
    SET YAUL_OPTION_BUILD_ASSERT=1
    SET SILENT=1
    SET MAKE_ISO_XORRISO=%YAUL_ROOT%tool-chain/usr/bin/xorrisofs
    make
)
