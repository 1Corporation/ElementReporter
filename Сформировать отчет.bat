@echo off
:: [„Ž€‚‹…Ž] à®¢¥àª  ¯à ¢  ¤¬¨­¨áâà â®à 
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo =====================================================
    echo [‚ˆŒ€ˆ…] ‘ªà¨¯â § ¯ãé¥­ …‡ ¯à ¢ €¤¬¨­¨áâà â®à !
    echo "¥ª®â®àë¥ ¤ ­­ë¥ (dxdiag, systeminfo, «®£¨) ¬®£ãâ ¡ëâì ­¥¤®áâã¯­ë."
    echo ¥ª®¬¥­¤ã¥âáï ¯¥à¥§ ¯ãáâ¨âì áªà¨¯â ®â ¨¬¥­¨ €¤¬¨­¨áâà â®à .
    echo =====================================================
    echo.
    timeout /t 5 >nul
)

chcp 866 >nul
setlocal enabledelayedexpansion

:: =====================================================
:: €‘’Ž‰Šˆ ‘Šˆ’€
:: =====================================================
:: ¥¦¨¬ á¡®à  ¨­ä®à¬ æ¨¨:
::   full  - á®¡¨à âì ‚‘ž ¨­ä®à¬ æ¨î (è £¨ 1-8)
::   light - á®¡¨à âì â®«ìª® ¡ §®¢ãî ¨­ä®à¬ æ¨î (è £¨ 1, 2, 7 ¨ 8)
set "COLLECTION_MODE=light"
:: =====================================================

:: Ž¯à¥¤¥«ï¥¬ ¯ãâì ª ãáâà®©áâ¢ã, á ª®â®à®£® § ¯ãé¥­ áªà¨¯â
set "SCRIPT_DRIVE=%~d0"
set "SCRIPT_PATH=%~dp0"

:: “¡¨à ¥¬ § ¢¥àè îé¨© ®¡à â­ë© á«¥è ¤«ï ªà á®âë
if "%SCRIPT_PATH:~-1%"=="\" set "SCRIPT_PATH=%SCRIPT_PATH:~0,-1%"

:: ®«ãç ¥¬ â¥ªãéãî ¤ âã ¢ ä®à¬ â¥ „„ŒŒƒƒ
set "DD=%DATE:~0,2%"
set "MM=%DATE:~3,2%"
set "YY=%DATE:~8,2%"
set "DATE_FOLDER=1C Element report %DD%%MM%%YY%"

:: ®«ãç ¥¬ ¨¬ï ª®¬¯ìîâ¥à 
set "COMPUTER_NAME=%COMPUTERNAME%"

:: ‘®§¤ ¥¬ ¨¥à àå¨î ¯ ¯®ª ­  ãáâà®©áâ¢¥, ®âªã¤  § ¯ãé¥­ áªà¨¯â
set "BASE_PATH=%SCRIPT_PATH%\%DATE_FOLDER%"
set "COMPUTER_PATH=%BASE_PATH%\%COMPUTER_NAME%"
set "LOGS_PATH=%COMPUTER_PATH%\logs"
set "DEPLOYMENT_ERRORS_PATH=%COMPUTER_PATH%\deployment_errors"

:: [„Ž€‚‹…Ž]  áâà®©ª  ä ©«  ¦ãà­ «  ¢ë¯®«­¥­¨ï (â¥å­¨ç¥áª¨© «®£ áªà¨¯â )
set "EXEC_LOG=%COMPUTER_PATH%\script_execution.log"

echo =====================================================
echo       ‘Ž ˆ”ŽŒ€–ˆˆ Ž ‘ˆ‘’…Œ…
echo =====================================================
echo.
echo ‘ªà¨¯â § ¯ãé¥­ á: %SCRIPT_DRIVE%
echo ãâì á®åà ­¥­¨ï: %SCRIPT_PATH%
echo „ â : %DATE_FOLDER%
echo Š®¬¯ìîâ¥à: %COMPUTER_NAME%
echo ¥¦¨¬ á¡®à : %COLLECTION_MODE%


if /i "%COLLECTION_MODE%"=="full" (
    echo ¥¦¨¬ FULL - ¡ã¤¥â á®¡à ­  ‚‘Ÿ ¨­ä®à¬ æ¨ï (è £¨ 1-8)
) else (
    echo ¥¦¨¬ LIGHT - ¡ã¤¥â á®¡à ­  â®«ìª® ¡ §®¢ ï ¨­ä®à¬ æ¨ï (è £¨ 1, 2, 7 ¨ 8)
)

echo.
echo ‘®§¤ ­¨¥ áâàãªâãàë ¯ ¯®ª...

:: ‘®§¤ ¥¬ ­¥®¡å®¤¨¬ë¥ ¯ ¯ª¨
if not exist "%BASE_PATH%" mkdir "%BASE_PATH%"
if not exist "%COMPUTER_PATH%" mkdir "%COMPUTER_PATH%"

:: [„Ž€‚‹…Ž] ˆ­¨æ¨ «¨§ æ¨ï «®£  ¯®á«¥ á®§¤ ­¨ï ¯ ¯ª¨
call :LogMsg "INFO" "‡ ¯ãáª áªà¨¯â  á¡®à  ¨­ä®à¬ æ¨¨. ¥¦¨¬: %COLLECTION_MODE%"
call :LogMsg "INFO" "–¥«¥¢ ï ¯ ¯ª  á®§¤ ­ : %COMPUTER_PATH%"

::  ¯ª¨ «®£®¢ á®§¤ ¥¬ â®«ìª® ¢ FULL à¥¦¨¬¥, çâ®¡ë ­¥ ¬ãá®à¨âì ¯ãáâë¬¨ ¯ ¯ª ¬¨ ¢ LIGHT
if /i "%COLLECTION_MODE%"=="full" (
    if not exist "%LOGS_PATH%" mkdir "%LOGS_PATH%"
    if not exist "%DEPLOYMENT_ERRORS_PATH%" mkdir "%DEPLOYMENT_ERRORS_PATH%"
    :: [„Ž€‚‹…Ž] ‹®£¨à®¢ ­¨¥ á®§¤ ­¨ï ¯®¤¯ ¯®ª
    call :LogMsg "INFO" "‘®§¤ ­ë ¯ ¯ª¨ ¤«ï «®£®¢ ¨ ®è¨¡®ª à §¢¥àâë¢ ­¨ï."
)

echo [1/8] ‘¡®à ¨­ä®à¬ æ¨¨ ®¡  ¯¯ à â­®© ª®­ä¨£ãà æ¨¨ ¨ Ž‘...
:: [„Ž€‚‹…Ž] ‹®£ ­ ç «  è £ 
call :LogMsg "INFO" "[˜€ƒ 1] ‡ ¯ãáª dxdiag..."

:: ‡ ¯ãáª ¥¬ dxdiag ¨ á®åà ­ï¥¬ à¥§ã«ìâ â
start /wait dxdiag /whql:off /t "%COMPUTER_PATH%\%COMPUTER_NAME%_diag.txt"

:: [„Ž€‚‹…Ž] à®¢¥àª  á®§¤ ­¨ï ä ©«  ¤¨ £­®áâ¨ª¨
if exist "%COMPUTER_PATH%\%COMPUTER_NAME%_diag.txt" (
    call :LogMsg "INFO" "DxDiag ãá¯¥è­® § ¢¥àè¥­."
) else (
    call :LogMsg "ERROR" "” ©« ¤¨ £­®áâ¨ª¨ ­¥ á®§¤ ­! ‚®§¬®¦­  ®è¨¡ª  ¯à ¢ ¨«¨ dxdiag."
)

echo    - „¨ £­®áâ¨ª  á®åà ­¥­  ¢ %COMPUTER_NAME%_diag.txt

echo [2/8] ‘¡®à ¨­ä®à¬ æ¨¨ ® ª®¬¯®­¥­â å 1‘...
call :LogMsg "INFO" "[˜€ƒ 2] ®¨áª ãáâ ­®¢«¥­­ëå ¢¥àá¨© 1‘..."
set "COMPONENTS_FILE=%COMPUTER_PATH%\installed_versions.txt"
(
    echo ========================================
    echo Š®¬¯ìîâ¥à: %COMPUTER_NAME%
    echo „ â  á¡®à : %DATE% %TIME%
    echo ========================================
    echo.
    echo Š®¬¯®­¥­âë 1‘ ¢ C:\Program Files\1C\1CE\components:
    echo ----------------------------------------
) > "%COMPONENTS_FILE%"

:: à®¢¥àï¥¬ áãé¥áâ¢®¢ ­¨¥ ¯ ¯ª¨ á ª®¬¯®­¥­â ¬¨
if exist "C:\Program Files\1C\1CE\components" (
    dir "C:\Program Files\1C\1CE\components" /b /ad >> "%COMPONENTS_FILE%" 2>nul
    :: [„Ž€‚‹…Ž] ‹®£ ãá¯¥å 
    call :LogMsg "INFO" " ¯ª  ª®¬¯®­¥­â®¢ ­ ©¤¥­  ¨ ¯à®áª ­¨à®¢ ­ ."
) else (
    echo  ¯ª  ­¥ ­ ©¤¥­ : C:\Program Files\1C\1CE\components >> "%COMPONENTS_FILE%"
    :: [„Ž€‚‹…Ž] ‹®£ ®è¨¡ª¨
    call :LogMsg "WARNING" " ¯ª  ª®¬¯®­¥­â®¢ 1‘ ­¥ ­ ©¤¥­  ¯® áâ ­¤ àâ­®¬ã ¯ãâ¨."
)
echo    - ‘¯¨á®ª ª®¬¯®­¥­â®¢ á®åà ­¥­ ¢ installed_versions.txt

:: =====================================================
:: Ž‚…Š€ …†ˆŒ€ „‹Ÿ ˜€ƒŽ‚ 3-6
:: =====================================================
if /i not "%COLLECTION_MODE%"=="full" (
    echo.
    echo -----------------------------------------------------
    echo ¥¦¨¬ "%COLLECTION_MODE%": ˜ £¨ 3, 4, 5, 6 ¯à®¯ãáª îâáï.
    echo -----------------------------------------------------
    call :LogMsg "INFO" "à®¯ãáª è £®¢ 3-6 á®£« á­® à¥¦¨¬ã LIGHT."
    goto :Step7
)
:: =====================================================

echo [3/8] Š®¯¨à®¢ ­¨¥ «®£®¢ 1‘...
call :LogMsg "INFO" "[˜€ƒ 3]  ç â ¯®¨áª «®£®¢ 1‘..."
:: ”®à¬¨àã¥¬ ¯ãâì ª ¯ ¯ª¥ á «®£ ¬¨
set "USER_PATH=%HOMEDRIVE%%HOMEPATH%"
set "LOGS_SOURCE=%USER_PATH%\1c-enterprise-element\.storage\logs"

if exist "%LOGS_SOURCE%" (
    echo    - ®¨áª ¯ ¯®ª á «®£ ¬¨ ¢ %LOGS_SOURCE%

    :: ¥à¥¬¥­­ë¥ ¤«ï åà ­¥­¨ï ¨­ä®à¬ æ¨¨ ® á ¬®© á¢¥¦¥© ¯ ¯ª¥
    set "LATEST_FOLDER="
    set "LATEST_DATE=0"

    :: ¥à¥¡¨à ¥¬ ¢á¥ ¯®¤¯ ¯ª¨ ¢ ¤¨à¥ªâ®à¨¨ logs
    for /d %%i in ("%LOGS_SOURCE%\*") do (
        :: ®«ãç ¥¬ ¨­ä®à¬ æ¨î ® ¯ ¯ª¥
        set "FOLDER_PATH=%%i"
        set "FOLDER_NAME=%%~nxi"

        :: ®«ãç ¥¬ „€’“ ˆ‡Œ……ˆŸ ¯ ¯ª¨ (¯®á«¥¤­¨¥ ¨§¬¥­¥­¨ï)
        for %%f in ("%%i") do (
            set "FOLDER_DATE=%%~tf"

            :: à¥®¡à §ã¥¬ ¤ âã ¤«ï áà ¢­¥­¨ï (ä®à¬ â: ƒƒƒƒŒŒ„„——ŒŒ‘‘)
            set "DAY=!FOLDER_DATE:~0,2!"
            set "MONTH=!FOLDER_DATE:~3,2!"
            set "YEAR=!FOLDER_DATE:~6,4!"
            set "HOUR=!FOLDER_DATE:~11,2!"
            set "MINUTE=!FOLDER_DATE:~14,2!"
            set "SECOND=!FOLDER_DATE:~17,2!"

            :: “¡¨à ¥¬ ¢®§¬®¦­ë¥ ¯à®¡¥«ë
            set "YEAR=!YEAR: =0!"
            set "MONTH=!MONTH: =0!"
            set "DAY=!DAY: =0!"
            set "HOUR=!HOUR: =0!"
            set "MINUTE=!MINUTE: =0!"
            set "SECOND=!SECOND: =0!"

            set "DATE_NUM=!YEAR!!MONTH!!DAY!!HOUR!!MINUTE!!SECOND!"

            :: ‘à ¢­¨¢ ¥¬ á â¥ªãé¥© ¬ ªá¨¬ «ì­®© ¤ â®© ¨§¬¥­¥­¨ï
            if !DATE_NUM! gtr !LATEST_DATE! (
                set "LATEST_DATE=!DATE_NUM!"
                set "LATEST_FOLDER=%%i"
                set "LATEST_FOLDER_NAME=%%~nxi"
            )
        )
    )

    :: …á«¨ ­ è«¨ ¯®¤å®¤ïé¨¥ ¯ ¯ª¨, ª®¯¨àã¥¬ á ¬ãî á¢¥¦ãî æ¥«¨ª®¬
    if defined LATEST_FOLDER (
        echo    -  ©¤¥­  á ¬ ï á¢¥¦ ï ¯ ¯ª : !LATEST_FOLDER_NAME!
        echo    - „ â  ¯®á«¥¤­¥£® ¨§¬¥­¥­¨ï: !LATEST_DATE!
        echo    - Š®¯¨à®¢ ­¨¥ ¯ ¯ª¨ æ¥«¨ª®¬...
        call :LogMsg "INFO" "Ž¡­ àã¦¥­  á¢¥¦ ï ¯ ¯ª  «®£®¢: !LATEST_FOLDER_NAME!. Š®¯¨àã¥¬..."

        :: ‘®§¤ ¥¬ ¯®¤¯ ¯ªã á ¨¬¥­¥¬ ¨áå®¤­®© ¯ ¯ª¨ ¢ ¤¨à¥ªâ®à¨¨ logs
        set "TARGET_FOLDER=%LOGS_PATH%\!LATEST_FOLDER_NAME!"
        if not exist "!TARGET_FOLDER!" mkdir "!TARGET_FOLDER!"

        :: Š®¯¨àã¥¬ ¢áî ¯ ¯ªã æ¥«¨ª®¬ á® ¢á¥¬ á®¤¥à¦¨¬ë¬
        xcopy "!LATEST_FOLDER!" "!TARGET_FOLDER!\" /e /i /y /q >nul

        :: à®¢¥àï¥¬ à¥§ã«ìâ â ª®¯¨à®¢ ­¨ï
        if errorlevel 1 (
            echo    - Ž˜ˆŠ€: ¥ ã¤ «®áì áª®¯¨à®¢ âì ¯ ¯ªã á «®£ ¬¨
            echo Žè¨¡ª  ª®¯¨à®¢ ­¨ï ¨§ !LATEST_FOLDER! > "%LOGS_PATH%\copy_error.txt"
            call :LogMsg "ERROR" "Žè¨¡ª  xcopy ¯à¨ ª®¯¨à®¢ ­¨¨ «®£®¢ ¨§ !LATEST_FOLDER!."
        ) else (
            echo    -  ¯ª  !LATEST_FOLDER_NAME! ãá¯¥è­® áª®¯¨à®¢ ­  ¢ %LOGS_PATH%
            echo ˆáâ®ç­¨ª: !LATEST_FOLDER! > "%LOGS_PATH%\!LATEST_FOLDER_NAME!\copied_from.txt"
            echo „ â  ª®¯¨à®¢ ­¨ï: %DATE% %TIME% >> "%LOGS_PATH%\!LATEST_FOLDER_NAME!\copied_from.txt"
            echo „ â  ¯®á«¥¤­¥£® ¨§¬¥­¥­¨ï ¨áå®¤­®© ¯ ¯ª¨: !LATEST_DATE! >> "%LOGS_PATH%\!LATEST_FOLDER_NAME!\copied_from.txt"
            call :LogMsg "INFO" "‹®£¨ ãá¯¥è­® áª®¯¨à®¢ ­ë."
        )
    ) else (
        echo    - ¥ ­ ©¤¥­ë ¯ ¯ª¨ á «®£ ¬¨ ¢ %LOGS_SOURCE%
        echo  ¯ª¨ á «®£ ¬¨ ­¥ ­ ©¤¥­ë > "%LOGS_PATH%\no_logs_found.txt"
        call :LogMsg "WARNING" " ¯ª  logs ¯ãáâ  ¨«¨ ­¥ á®¤¥à¦¨â ¯®¤¯ ¯®ª."
    )
) else (
    echo    -  ¯ª  á «®£ ¬¨ ­¥ áãé¥áâ¢ã¥â: %LOGS_SOURCE%
    echo  ¯ª  %LOGS_SOURCE% ­¥ áãé¥áâ¢ã¥â > "%LOGS_PATH%\source_not_exists.txt"
    call :LogMsg "WARNING" "ˆáå®¤­ ï ¯ ¯ª  «®£®¢ 1C ­¥ ­ ©¤¥­  (%LOGS_SOURCE%)."
)

echo [4/8] Š®¯¨à®¢ ­¨¥ deployment_errors (¯ ¯ª¨ 1ce-installer ¨§ TEMP)...
call :LogMsg "INFO" "[˜€ƒ 4] ®¨áª ®è¨¡®ª à §¢¥àâë¢ ­¨ï ¢ TEMP..."
set "TEMP_PATH=%TEMP%"

:: Š®¯¨à®¢ ­¨¥ ¯ ¯ª¨ 1ce-installer-crash (¢á¥£¤  ª®¯¨àã¥¬, ¥á«¨ áãé¥áâ¢ã¥â)
if exist "%TEMP_PATH%\1ce-installer-crash" (
    echo    -  ©¤¥­  ¯ ¯ª  1ce-installer-crash
    call :LogMsg "INFO" "Ž¡­ àã¦¥­ ªà è-¤ ¬¯ ¨­áâ ««ïâ®à ."
    set "TARGET_CRASH=%DEPLOYMENT_ERRORS_PATH%\1ce-installer-crash"
    if not exist "!TARGET_CRASH!" mkdir "!TARGET_CRASH!"
    xcopy "%TEMP_PATH%\1ce-installer-crash" "!TARGET_CRASH!\" /e /i /y /q >nul
    echo    -  ¯ª  1ce-installer-crash áª®¯¨à®¢ ­ 
) else (
    echo    -  ¯ª  1ce-installer-crash ­¥ ­ ©¤¥­  ¢ %TEMP_PATH%
    echo  ¯ª  1ce-installer-crash ­¥ ­ ©¤¥­  > "%DEPLOYMENT_ERRORS_PATH%\crash_not_found.txt"
)

:: ®¨áª ¨ ª®¯¨à®¢ ­¨¥ á ¬®© á¢¥¦¥© ¯ ¯ª¨ 1ce-installer-20*
echo    - ®¨áª ¯ ¯®ª 1ce-installer-20* ¢ %TEMP_PATH%

set "LATEST_INSTALLER_FOLDER="
set "LATEST_INSTALLER_DATE=0"

for /d %%i in ("%TEMP_PATH%\1ce-installer-20*") do (
    set "FOLDER_PATH=%%i"
    set "FOLDER_NAME=%%~nxi"

    :: ®«ãç ¥¬ ¤ âã ¨§¬¥­¥­¨ï ¯ ¯ª¨
    for %%f in ("%%i") do (
        set "FOLDER_DATE=%%~tf"

        :: à¥®¡à §ã¥¬ ¤ âã ¤«ï áà ¢­¥­¨ï
        set "DAY=!FOLDER_DATE:~0,2!"
        set "MONTH=!FOLDER_DATE:~3,2!"
        set "YEAR=!FOLDER_DATE:~6,4!"
        set "HOUR=!FOLDER_DATE:~11,2!"
        set "MINUTE=!FOLDER_DATE:~14,2!"
        set "SECOND=!FOLDER_DATE:~17,2!"

        :: “¡¨à ¥¬ ¢®§¬®¦­ë¥ ¯à®¡¥«ë
        set "YEAR=!YEAR: =0!"
        set "MONTH=!MONTH: =0!"
        set "DAY=!DAY: =0!"
        set "HOUR=!HOUR: =0!"
        set "MINUTE=!MINUTE: =0!"
        set "SECOND=!SECOND: =0!"

        set "DATE_NUM=!YEAR!!MONTH!!DAY!!HOUR!!MINUTE!!SECOND!"

        :: ‘à ¢­¨¢ ¥¬ á â¥ªãé¥© ¬ ªá¨¬ «ì­®© ¤ â®©
        if !DATE_NUM! gtr !LATEST_INSTALLER_DATE! (
            set "LATEST_INSTALLER_DATE=!DATE_NUM!"
            set "LATEST_INSTALLER_FOLDER=%%i"
            set "LATEST_INSTALLER_NAME=%%~nxi"
        )
    )
)

if defined LATEST_INSTALLER_FOLDER (
    echo    -  ©¤¥­  á ¬ ï á¢¥¦ ï ¯ ¯ª : !LATEST_INSTALLER_NAME!
    echo    - „ â  ¯®á«¥¤­¥£® ¨§¬¥­¥­¨ï: !LATEST_INSTALLER_DATE!

    set "TARGET_INSTALLER=%DEPLOYMENT_ERRORS_PATH%\!LATEST_INSTALLER_NAME!"
    if not exist "!TARGET_INSTALLER!" mkdir "!TARGET_INSTALLER!"

    xcopy "!LATEST_INSTALLER_FOLDER!" "!TARGET_INSTALLER!\" /e /i /y /q >nul

    if errorlevel 1 (
        echo    - Ž˜ˆŠ€: ¥ ã¤ «®áì áª®¯¨à®¢ âì ¯ ¯ªã !LATEST_INSTALLER_NAME!
        call :LogMsg "ERROR" "Žè¨¡ª  ª®¯¨à®¢ ­¨ï ¯ ¯ª¨ ¨­áâ ««ïâ®à ."
    ) else (
        echo    -  ¯ª  !LATEST_INSTALLER_NAME! ãá¯¥è­® áª®¯¨à®¢ ­ 
        call :LogMsg "INFO" " ¯ª  ¨­áâ ««ïâ®à  áª®¯¨à®¢ ­ ."
    )
) else (
    echo    -  ¯ª¨ 1ce-installer-20* ­¥ ­ ©¤¥­ë ¢ %TEMP_PATH%
    echo  ¯ª¨ 1ce-installer-20* ­¥ ­ ©¤¥­ë > "%DEPLOYMENT_ERRORS_PATH%\installer_not_found.txt"
)

echo [5/8] ‘¡®à ¨­ä®à¬ æ¨¨ ® § ¯ãé¥­­ëå ¯à®æ¥áá å...
call :LogMsg "INFO" "[˜€ƒ 5] ‘¡®à á¯¨áª  ¯à®æ¥áá®¢..."
set "PROCESSES_FILE=%COMPUTER_PATH%\processes.txt"

:: ®«ãç ¥¬ á¯¨á®ª ¯à®æ¥áá®¢ ¢ CSV ä®à¬ â¥ (ã¤®¡­® ¤«ï ¨¬¯®àâ  ¢ Excel)
(
    echo ====================================================
    echo          ‡€“™…›… Ž–…‘‘› (CSV ”ŽŒ€’)
    echo ====================================================
    echo Š®¬¯ìîâ¥à: %COMPUTER_NAME%
    echo „ â  ¨ ¢à¥¬ï á¡®à : %DATE% %TIME%
    echo ====================================================
    echo.
    echo "ˆ¬ï_®¡à § ","PID","ˆ¬ï_á¥áá¨¨","®¬¥à_á¥áá¨¨"," ¬ïâì"
    echo ====================================================
) > "%PROCESSES_FILE%"

:: „®¡ ¢«ï¥¬ ¤ ­­ë¥ ¯à®æ¥áá®¢ ¢ CSV ä®à¬ â¥
tasklist /fo csv /nh >> "%PROCESSES_FILE%" 2>nul
:: [„Ž€‚‹…Ž] ‹®£¨à®¢ ­¨¥ ®è¨¡ª¨ tasklist (­ ¯à¨¬¥à, ¥á«¨ ­¥â ¯à ¢)
if %errorlevel% neq 0 call :LogMsg "ERROR" "¥ ã¤ «®áì ¢ë¯®«­¨âì tasklist."

:: „®¡ ¢«ï¥¬ ¨­ä®à¬ æ¨î ® á¨áâ¥¬¥
(
    echo.
    echo ====================================================
    echo          ˆ”ŽŒ€–ˆŸ Ž ‘ˆ‘’…Œ…
    echo ====================================================
    echo.
) >> "%PROCESSES_FILE%"

:: ˆá¯®«ì§ã¥¬ systeminfo ¤«ï ¯®«ãç¥­¨ï ¡ §®¢®© ¨­ä®à¬ æ¨¨
systeminfo | findstr /c:"Ž¡é¥¥ ª®«¨ç¥áâ¢®" /c:"„®áâã¯­® ä¨§¨ç¥áª®©" /c:"‚à¥¬ï à ¡®âë" /c:"‚¥àá¨ï Ž‘" >> "%PROCESSES_FILE%" 2>nul

:: „®¡ ¢«ï¥¬ ®¡é¥¥ ª®«¨ç¥áâ¢® ¯à®æ¥áá®¢
echo. >> "%PROCESSES_FILE%"
echo Ž¡é¥¥ ª®«¨ç¥áâ¢® § ¯ãé¥­­ëå ¯à®æ¥áá®¢: >> "%PROCESSES_FILE%"
tasklist /fo csv 2>nul | find /c /v "" >> "%PROCESSES_FILE%"

echo    - ˆ­ä®à¬ æ¨ï ® ¯à®æ¥áá å á®åà ­¥­  ¢ processes.txt (CSV ä®à¬ â)

echo [6/8] Š®¯¨à®¢ ­¨¥ à ¡®ç¨å ¯à®áâà ­áâ¢ (recentworkspace)...
call :LogMsg "INFO" "[˜€ƒ 6] Ž¡à ¡®âª  à ¡®ç¨å ¯à®áâà ­áâ¢..."

REM === €‘’Ž‰Šˆ ===
set "INPUT_FILE=%USERPROFILE%\1c-enterprise-element\.storage\recentworkspace.json"
set "WORKSPACE_DIR=%COMPUTER_PATH%\workspaces"
REM =================

if not exist "%WORKSPACE_DIR%" mkdir "%WORKSPACE_DIR%"

echo    - ®¨áª ª®­ä¨£ : "%INPUT_FILE%"

if not exist "%INPUT_FILE%" (
    echo    - [Ž˜ˆŠ€] ” ©« recentworkspace.json ­¥ ­ ©¤¥­!
    echo ” ©« recentworkspace.json ­¥ ­ ©¤¥­ > "%WORKSPACE_DIR%\not_found.txt"
    call :LogMsg "WARNING" "Š®­ä¨£ãà æ¨®­­ë© ä ©« workspace ­¥ ­ ©¤¥­."
    goto :SkipWorkspaces
)

REM —¨â ¥¬ á®¤¥à¦¨¬®¥ ä ©«  ¢ ¯¥à¥¬¥­­ãî (JSON ¢ ®¤­ã áâà®ªã)
for /f "usebackq tokens=*" %%A in ("%INPUT_FILE%") do (
    set "JSON_CONTENT=%%A"
)

REM --- €‡Ž JSON ---
REM “¤ «ï¥¬ è ¯ªã {"recentRoots":[ ¨ å¢®áâ ]}
set "JSON_CONTENT=!JSON_CONTENT:*recentRoots=!"
set "JSON_CONTENT=!JSON_CONTENT:*[=!"
set "JSON_CONTENT=!JSON_CONTENT:]}=!"
set "JSON_CONTENT=!JSON_CONTENT:"=!"

REM ’¥¯¥àì JSON_CONTENT: file:///c%3A/Path1,file:///c%3A/Path2,...

:ParseLoopWS
for /f "tokens=1* delims=," %%a in ("!JSON_CONTENT!") do (
    set "RAW_PATH=%%a"
    set "JSON_CONTENT=%%b"

    REM --- „…ŠŽ„ˆŽ‚€ˆ… URI -> WINDOWS-“’œ ---
    set "WIN_PATH=!RAW_PATH:file:///=!"
    set "WIN_PATH=!WIN_PATH:%%3A=:!"
    set "WIN_PATH=!WIN_PATH:%%20= !"
    set "WIN_PATH=!WIN_PATH:/=\!"

    echo    - Ž¡à ¡®âª : !WIN_PATH!

    REM --- à®¢¥àï¥¬: ¯ ¯ª  ¨«¨ ä ©«? ---
    if exist "!WIN_PATH!\*" (
        REM ===== ’Ž €Š€ (¯à®¥ªâ) =====
        for %%F in ("!WIN_PATH!") do set "PROJECT_NAME=%%~nxF"
        set "TARGET_DIR=!WORKSPACE_DIR!\!PROJECT_NAME!"
        if not exist "!TARGET_DIR!" mkdir "!TARGET_DIR!"

        echo      [€Š€] Š®¯¨à®¢ ­¨¥ á®¤¥à¦¨¬®£® ¢ "!TARGET_DIR!"
        xcopy "!WIN_PATH!" "!TARGET_DIR!\" /e /i /y /q >nul
        if errorlevel 1 (
            echo      - Ž˜ˆŠ€ ¯à¨ ª®¯¨à®¢ ­¨¨ ¯ ¯ª¨
            call :LogMsg "ERROR" "Žè¨¡ª  ª®¯¨à®¢ ­¨ï ¯ ¯ª¨ workspace: !WIN_PATH!"
        ) else (
            echo      -  ¯ª  áª®¯¨à®¢ ­  ãá¯¥è­®
        )

    ) else if exist "!WIN_PATH!" (
        REM ===== ’Ž ”€‰‹ =====
        for %%F in ("!WIN_PATH!") do set "FILENAME=%%~nxF"
        set "TARGET_FILE=!WORKSPACE_DIR!\!FILENAME!"

        REM à®¢¥àï¥¬, áãé¥áâ¢ã¥â «¨ ã¦¥ ä ©« á â ª¨¬ ¨¬¥­¥¬
        if exist "!TARGET_FILE!" (
            REM …á«¨ áãé¥áâ¢ã¥â, ¤®¡ ¢«ï¥¬ ç¨á«®¢®© áãää¨ªá
            set "base=!FILENAME:~0,-4!"
            set "ext=!FILENAME:~-4!"
            if "!ext!"==".!ext!" (
                rem á à áè¨à¥­¨¥¬
                set "counter=1"
                :loop_file
                if exist "!WORKSPACE_DIR!\!base!_!counter!!ext!" (
                    set /a counter+=1
                    goto loop_file
                )
                set "TARGET_FILE=!WORKSPACE_DIR!\!base!_!counter!!ext!"
            ) else (
                rem ¡¥§ à áè¨à¥­¨ï
                set "counter=1"
                :loop_file_noext
                if exist "!WORKSPACE_DIR!\!base!_!counter!" (
                    set /a counter+=1
                    goto loop_file_noext
                )
                set "TARGET_FILE=!WORKSPACE_DIR!\!base!_!counter!"
            )
        )

        echo      [”€‰‹] Š®¯¨à®¢ ­¨¥ ¢ "!TARGET_FILE!"
        copy "!WIN_PATH!" "!TARGET_FILE!" /y >nul
        if errorlevel 1 (
            echo      - Ž˜ˆŠ€ ¯à¨ ª®¯¨à®¢ ­¨¨ ä ©« 
            call :LogMsg "ERROR" "Žè¨¡ª  ª®¯¨à®¢ ­¨ï ä ©«  workspace: !WIN_PATH!"
        ) else (
            echo      - ” ©« áª®¯¨à®¢ ­ ãá¯¥è­®
        )

    ) else (
        echo      [… €‰„…Ž] !WIN_PATH!
        call :LogMsg "WARNING" "ãâì workspace ­¥ ­ ©¤¥­ ­  ¤¨áª¥: !WIN_PATH!"
    )

    if defined JSON_CONTENT goto ParseLoopWS
)

echo    - Š®¯¨à®¢ ­¨¥ à ¡®ç¨å ¯à®áâà ­áâ¢ § ¢¥àè¥­®

:SkipWorkspaces

:Step7
echo [7/8] ‘¡®à ¨­ä®à¬ æ¨¨ ® Java...
call :LogMsg "INFO" "[˜€ƒ 7] à®¢¥àª  ¢¥àá¨¨ Java..."
set "JAVA_REPORT=%COMPUTER_PATH%\java_report.txt"
(
    echo ========================================
    echo      ˆ”ŽŒ€–ˆŸ Ž JAVA
    echo ========================================
    echo Š®¬¯ìîâ¥à: %COMPUTER_NAME%
    echo „ â  á¡®à : %DATE% %TIME%
    echo ¥¦¨¬ á¡®à : %COLLECTION_MODE%
    echo ========================================
    echo.
    java -version 2>&1
    echo.
    echo --- ¥à¥¬¥­­ë¥ ®ªàã¦¥­¨ï, á¢ï§ ­­ë¥ á Java ---
    set | findstr /i "java"
) > "%JAVA_REPORT%" 2>nul
echo    - ˆ­ä®à¬ æ¨ï ® Java á®åà ­¥­  ¢ java_report.txt

echo [8/8] ‘®§¤ ­¨¥ á¢®¤­®£® ®âç¥â ...
call :LogMsg "INFO" "[˜€ƒ 8] ƒ¥­¥à æ¨ï á¢®¤­®£® ®âç¥â ..."
set "SUMMARY_FILE=%COMPUTER_PATH%\summary_report.txt"
(
    echo ====================================================
    echo              ‘‚Ž„›‰ Ž’—…’ Ž ‘ˆ‘’…Œ…
    echo ====================================================
    echo.
    echo „ â  á¡®à : %DATE% %TIME%
    echo Š®¬¯ìîâ¥à: %COMPUTER_NAME%
    echo.
    echo ====================================================
    echo 1. €€€’€Ÿ ŠŽ”ˆƒ“€–ˆŸ ˆ Ž‘
    echo ====================================================
    echo ” ©«: %COMPUTER_NAME%_diag.txt
    echo  §¬¥à:
    if exist "%COMPUTER_PATH%\%COMPUTER_NAME%_diag.txt" (
        for %%f in ("%COMPUTER_PATH%\%COMPUTER_NAME%_diag.txt") do echo    %%~zf ¡ ©â
    ) else (
        echo    ” ©« ­¥ á®§¤ ­ (®è¨¡ª  dxdiag)
    )
    echo.
    echo ====================================================
    echo 2. ŠŽŒŽ…’› 1‘
    echo ====================================================
) >> "%SUMMARY_FILE%"

:: „®¡ ¢«ï¥¬ á®¤¥à¦¨¬®¥ installed_versions.txt ¢ ®âç¥â
if exist "%COMPONENTS_FILE%" (
    type "%COMPONENTS_FILE%" >> "%SUMMARY_FILE%"
) else (
    echo ” ©« ­¥ á®§¤ ­ >> "%SUMMARY_FILE%"
)

(
    echo.
    echo ====================================================
    echo 3. Ž–…‘‘›
    echo ====================================================
) >> "%SUMMARY_FILE%"

:: „®¡ ¢«ï¥¬ ªà âªãî áâ â¨áâ¨ªã ¨§ processes.txt
if exist "%PROCESSES_FILE%" (
    echo ” ©« á ¯à®æ¥áá ¬¨: processes.txt (CSV ä®à¬ â) >> "%SUMMARY_FILE%"
    echo  §¬¥à ä ©« : >> "%SUMMARY_FILE%"
    for %%f in ("%PROCESSES_FILE%") do echo    %%~zf ¡ ©â >> "%SUMMARY_FILE%"
    echo. >> "%SUMMARY_FILE%"
    echo ¥à¢ë¥ 10 áâà®ª ä ©«  (¤«ï ®§­ ª®¬«¥­¨ï): >> "%SUMMARY_FILE%"
    echo ---------------------------------------- >> "%SUMMARY_FILE%"
    type "%PROCESSES_FILE%" | findstr /n "^" | findstr /b "[1-9]: [1-9]: " 2>nul >> "%SUMMARY_FILE%"
) else (
    if /i "%COLLECTION_MODE%"=="full" (
        echo ” ©« á ¯à®æ¥áá ¬¨ ­¥ á®§¤ ­ >> "%SUMMARY_FILE%"
    ) else (
        echo Ž“™…Ž (¥¦¨¬ Light) >> "%SUMMARY_FILE%"
    )
)

(
    echo.
    echo ====================================================
    echo 4. ‹Žƒˆ
    echo ====================================================
) >> "%SUMMARY_FILE%"

if exist "%LOGS_PATH%" (
    echo  ¯ª  á «®£ ¬¨: %LOGS_PATH% >> "%SUMMARY_FILE%"
    echo. >> "%SUMMARY_FILE%"
    echo ‘®¤¥à¦¨¬®¥ ¯ ¯ª¨ logs: >> "%SUMMARY_FILE%"

    :: ®ª §ë¢ ¥¬ áâàãªâãàã áª®¯¨à®¢ ­­ëå ¯ ¯®ª
    for /d %%d in ("%LOGS_PATH%\*") do (
        echo [€Š€] %%~nxd >> "%SUMMARY_FILE%"
        if exist "%%d\copied_from.txt" (
            echo   ˆ­ä®à¬ æ¨ï: >> "%SUMMARY_FILE%"
            for /f "tokens=*" %%l in (%%d\copied_from.txt) do (
                echo     %%l >> "%SUMMARY_FILE%"
            )
        )
        echo. >> "%SUMMARY_FILE%"
    )

    :: ®ª §ë¢ ¥¬ ä ©«ë ¢ ª®à­¥ logs, ¥á«¨ ¥áâì
    dir "%LOGS_PATH%" /b /a-d 2>nul >> "%SUMMARY_FILE%"
) else (
    if /i "%COLLECTION_MODE%"=="full" (
        echo  ¯ª  á «®£ ¬¨ ­¥ á®§¤ ­  >> "%SUMMARY_FILE%"
    ) else (
        echo Ž“™…Ž (¥¦¨¬ Light) >> "%SUMMARY_FILE%"
    )
)

(
    echo.
    echo ====================================================
    echo 5. DEPLOYMENT ERRORS
    echo ====================================================
) >> "%SUMMARY_FILE%"

if exist "%DEPLOYMENT_ERRORS_PATH%" (
    echo  ¯ª  á ®è¨¡ª ¬¨ à §¢¥àâë¢ ­¨ï: %DEPLOYMENT_ERRORS_PATH% >> "%SUMMARY_FILE%"
    echo. >> "%SUMMARY_FILE%"
    echo ‘®¤¥à¦¨¬®¥ ¯ ¯ª¨ deployment_errors: >> "%SUMMARY_FILE%"

    :: ®ª §ë¢ ¥¬ áâàãªâãàã áª®¯¨à®¢ ­­ëå ¯ ¯®ª
    for /d %%d in ("%DEPLOYMENT_ERRORS_PATH%\*") do (
        echo [€Š€] %%~nxd >> "%SUMMARY_FILE%"
        echo. >> "%SUMMARY_FILE%"
    )

    :: ®ª §ë¢ ¥¬ ¨­ä®à¬ æ¨®­­ë¥ ä ©«ë, ¥á«¨ ¥áâì
    dir "%DEPLOYMENT_ERRORS_PATH%\*.txt" /b 2>nul >> "%SUMMARY_FILE%"
) else (
    if /i "%COLLECTION_MODE%"=="full" (
        echo  ¯ª  á ®è¨¡ª ¬¨ à §¢¥àâë¢ ­¨ï ­¥ á®§¤ ­  >> "%SUMMARY_FILE%"
    ) else (
        echo Ž“™…Ž (¥¦¨¬ Light) >> "%SUMMARY_FILE%"
    )
)

(
    echo.
    echo ====================================================
    echo 6. €Ž—ˆ… Ž‘’€‘’‚€ (WORKSPACES)
    echo ====================================================
) >> "%SUMMARY_FILE%"

if exist "%WORKSPACE_DIR%" (
    echo  ¯ª : %WORKSPACE_DIR% >> "%SUMMARY_FILE%"
    echo. >> "%SUMMARY_FILE%"
    echo ‘ª®¯¨à®¢ ­­ë¥ í«¥¬¥­âë: >> "%SUMMARY_FILE%"
    dir "%WORKSPACE_DIR%" /b 2>nul >> "%SUMMARY_FILE%"
) else (
    if /i "%COLLECTION_MODE%"=="full" (
        echo  ¯ª  workspaces ­¥ á®§¤ ­  >> "%SUMMARY_FILE%"
    ) else (
        echo Ž“™…Ž (¥¦¨¬ Light) >> "%SUMMARY_FILE%"
    )
)

(
    echo.
    echo ====================================================
    echo 7. JAVA
    echo ====================================================
) >> "%SUMMARY_FILE%"

if exist "%JAVA_REPORT%" (
    echo ” ©«: java_report.txt >> "%SUMMARY_FILE%"
    echo ‘®¤¥à¦¨¬®¥: >> "%SUMMARY_FILE%"
    echo ---------------------------------------- >> "%SUMMARY_FILE%"
    type "%JAVA_REPORT%" >> "%SUMMARY_FILE%"
) else (
    echo ” ©« java_report.txt ­¥ á®§¤ ­ >> "%SUMMARY_FILE%"
)

(
    echo.
    echo ====================================================
    echo Š®­¥æ ®âç¥â 
    echo ====================================================
) >> "%SUMMARY_FILE%"

:: ‘®§¤ ¥¬ ä ©« á ¨­ä®à¬ æ¨¥© ® ª®¬¯ìîâ¥à å ¢ ¯ ¯ª¥ á ¤ â®©
set "COMPUTERS_LIST_FILE=%BASE_PATH%\computers_list.txt"

:: …á«¨ ä ©« ­¥ áãé¥áâ¢ã¥â, á®§¤ ¥¬ ¥£® á § £®«®¢ª®¬
if not exist "%COMPUTERS_LIST_FILE%" (
    echo ==================================================== > "%COMPUTERS_LIST_FILE%"
    echo       ‘ˆ‘ŽŠ ŠŽŒœž’…Ž‚ ‡€ %DATE_FOLDER% >> "%COMPUTERS_LIST_FILE%"
    echo ==================================================== >> "%COMPUTERS_LIST_FILE%"
    echo „ â  á¡®à  ^| ‚à¥¬ï ^| ˆ¬ï ª®¬¯ìîâ¥à  >> "%COMPUTERS_LIST_FILE%"
    echo ==================================================== >> "%COMPUTERS_LIST_FILE%"
)

:: „®¡ ¢«ï¥¬ § ¯¨áì ® â¥ªãé¥¬ ª®¬¯ìîâ¥à¥
echo %DATE% ^| %TIME% ^| %COMPUTER_NAME% ^| %COLLECTION_MODE% >> "%COMPUTERS_LIST_FILE%"

call :LogMsg "INFO" "‘¡®à ¤ ­­ëå § ¢¥àè¥­. Žâç¥â ®¡­®¢«¥­."

echo.
echo =====================================================
echo            ‘Ž ˆ”ŽŒ€–ˆˆ ‡€‚…˜…
echo =====================================================
echo.
echo „ ­­ë¥ á®åà ­¥­ë ¢:
echo %COMPUTER_PATH%
echo.
echo ‘âàãªâãà  ¯ ¯®ª ­  ãáâà®©áâ¢¥ %SCRIPT_DRIVE%:

if /i "%COLLECTION_MODE%"=="full" (
    echo %DATE_FOLDER%\
    echo   ÃÄÄ computers_list.txt
    echo   ÀÄÄ %COMPUTER_NAME%\
    echo       ÃÄÄ %COMPUTER_NAME%_diag.txt
    echo       ÃÄÄ installed_versions.txt
    echo       ÃÄÄ processes.txt
    echo       ÃÄÄ summary_report.txt
    echo       ÃÄÄ logs\
    echo       ³   ÀÄÄ [¯ ¯ª _á_á ¬ë¬¨_á¢¥¦¨¬¨_«®£ ¬¨]\
    echo       ÀÄÄ deployment_errors\
    echo           ÃÄÄ 1ce-installer-crash\ (¥á«¨ ­ ©¤¥­ )
    echo           ÀÄÄ 1ce-installer-20*\ (á ¬ ï á¢¥¦ ï)
) else (
    echo %DATE_FOLDER%\
    echo   ÃÄÄ computers_list.txt
    echo   ÀÄÄ %COMPUTER_NAME%\
    echo       ÃÄÄ %COMPUTER_NAME%_diag.txt
    echo       ÃÄÄ installed_versions.txt
    echo       ÀÄÄ summary_report.txt
)

echo.
echo ‘¢®¤­ë© ®âç¥â: %SUMMARY_FILE%
echo.
echo ‘¯¨á®ª ª®¬¯ìîâ¥à®¢ §  %DATE_FOLDER%: %COMPUTERS_LIST_FILE%

:: [„Ž€‚‹…Ž] ‚ëå®¤ ¨§ áªà¨¯â , çâ®¡ë ­¥ ¯®¯ áâì ¢ äã­ªæ¨î «®££¥à 
pause
exit /b

:: =====================================================
:: [„Ž€‚‹…Ž] ”“Š–ˆŸ ‹ŽƒˆŽ‚€ˆŸ
:: =====================================================
:LogMsg
:: %1 - ’¨¯ (INFO, ERROR, WARNING)
:: %2 - ‘®®¡é¥­¨¥
if defined EXEC_LOG (
    echo [%DATE% %TIME%] [%~1] %~2 >> "%EXEC_LOG%"
)
exit /b
