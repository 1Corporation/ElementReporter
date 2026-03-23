@echo off
chcp 1251 >nul
setlocal enabledelayedexpansion


:: =====================================================
:: НАСТРОЙКИ СКРИПТА
:: =====================================================
:: Режим сбора информации:
::   full  - собирать ВСЮ информацию (шаги 1-8)
::   light - собирать только базовую информацию (шаги 1, 2 и 8)
set "COLLECTION_MODE=light"
:: =====================================================


:: Определяем путь к устройству, с которого запущен скрипт
set "SCRIPT_DRIVE=%~d0"
set "SCRIPT_PATH=%~dp0"

:: Убираем завершающий обратный слеш для красоты
if "%SCRIPT_PATH:~-1%"=="\" set "SCRIPT_PATH=%SCRIPT_PATH:~0,-1%"

:: Получаем текущую дату в формате ДДММГГ
set "DD=%DATE:~0,2%"
set "MM=%DATE:~3,2%"
set "YY=%DATE:~8,2%"
set "DATE_FOLDER=%DD%%MM%%YY%"

:: Получаем имя компьютера
set "COMPUTER_NAME=%COMPUTERNAME%"

:: Создаем иерархию папок на устройстве, откуда запущен скрипт
set "BASE_PATH=%SCRIPT_PATH%\%DATE_FOLDER%"
set "COMPUTER_PATH=%BASE_PATH%\%COMPUTER_NAME%"
set "LOGS_PATH=%COMPUTER_PATH%\logs"
set "DEPLOYMENT_ERRORS_PATH=%COMPUTER_PATH%\deployment_errors"

echo =====================================================
echo       СБОР ИНФОРМАЦИИ О СИСТЕМЕ
echo =====================================================
echo.
echo Скрипт запущен с: %SCRIPT_DRIVE%
echo Путь сохранения: %SCRIPT_PATH%
echo Дата: %DATE_FOLDER%
echo Компьютер: %COMPUTER_NAME%
echo Режим сбора: %COLLECTION_MODE%

if /i "%COLLECTION_MODE%"=="full" (
    echo Режим FULL - будет собрана ВСЯ информация (шаги 1-8)
) else (
    echo Режим LIGHT - будет собрана только базовая информация (шаги 1, 2 и 8)
)

echo.
echo Создание структуры папок...


:: Создаем необходимые папки
if not exist "%BASE_PATH%" mkdir "%BASE_PATH%"
if not exist "%COMPUTER_PATH%" mkdir "%COMPUTER_PATH%"

:: В FULL режиме создаем дополнительные папки
if /i "%COLLECTION_MODE%"=="full" (
    if not exist "%LOGS_PATH%" mkdir "%LOGS_PATH%"
    if not exist "%DEPLOYMENT_ERRORS_PATH%" mkdir "%DEPLOYMENT_ERRORS_PATH%"
)

echo [1/8] Сбор информации об аппаратной конфигурации и ОС...
:: Запускаем dxdiag и сохраняем результат
start /wait dxdiag /whql:off /t "%COMPUTER_PATH%\%COMPUTER_NAME%_diag.txt"
echo    - Диагностика сохранена в %COMPUTER_NAME%_diag.txt

echo [2/8] Сбор информации о компонентах 1С...
set "COMPONENTS_FILE=%COMPUTER_PATH%\installed_versions.txt"
(
    echo ========================================
    echo Компьютер: %COMPUTER_NAME%
    echo Дата сбора: %DATE% %TIME%
    echo ========================================
    echo.
    echo Компоненты 1С в C:\Program Files\1C\1CE\components:
    echo ----------------------------------------
) > "%COMPONENTS_FILE%"

:: Проверяем существование папки с компонентами
if exist "C:\Program Files\1C\1CE\components" (
    dir "C:\Program Files\1C\1CE\components" /b /ad >> "%COMPONENTS_FILE%" 2>nul
) else (
    echo Папка не найдена: C:\Program Files\1C\1CE\components >> "%COMPONENTS_FILE%"
)
echo    - Список компонентов сохранен в installed_versions.txt

if /i "%COLLECTION_MODE%"=="full" (

    echo [3/8] Копирование логов 1С...
    :: Формируем путь к папке с логами
    set "USER_PATH=%HOMEDRIVE%%HOMEPATH%"
    set "LOGS_SOURCE=%USER_PATH%\1c-enterprise-element\.storage\logs"

    if exist "%LOGS_SOURCE%" (
        echo    - Поиск папок с логами в %LOGS_SOURCE%

        :: Переменные для хранения информации о самой свежей папке
        set "LATEST_FOLDER="
        set "LATEST_DATE=0"

        :: Перебираем все подпапки в директории logs
        for /d %%i in ("%LOGS_SOURCE%\*") do (
            :: Получаем информацию о папке
            set "FOLDER_PATH=%%i"
            set "FOLDER_NAME=%%~nxi"

            :: Получаем ДАТУ ИЗМЕНЕНИЯ папки (последние изменения)
            for %%f in ("%%i") do (
                set "FOLDER_DATE=%%~tf"

                :: Преобразуем дату для сравнения (формат: ГГГГММДДЧЧММСС)
                :: Предполагаем формат даты: ДД.ММ.ГГГГ ЧЧ:ММ:СС
                set "DAY=!FOLDER_DATE:~0,2!"
                set "MONTH=!FOLDER_DATE:~3,2!"
                set "YEAR=!FOLDER_DATE:~6,4!"
                set "HOUR=!FOLDER_DATE:~11,2!"
                set "MINUTE=!FOLDER_DATE:~14,2!"
                set "SECOND=!FOLDER_DATE:~17,2!"

                :: Убираем возможные пробелы
                set "YEAR=!YEAR: =0!"
                set "MONTH=!MONTH: =0!"
                set "DAY=!DAY: =0!"
                set "HOUR=!HOUR: =0!"
                set "MINUTE=!MINUTE: =0!"
                set "SECOND=!SECOND: =0!"

                set "DATE_NUM=!YEAR!!MONTH!!DAY!!HOUR!!MINUTE!!SECOND!"

                :: Сравниваем с текущей максимальной датой изменения
                if !DATE_NUM! gtr !LATEST_DATE! (
                    set "LATEST_DATE=!DATE_NUM!"
                    set "LATEST_FOLDER=%%i"
                    set "LATEST_FOLDER_NAME=%%~nxi"
                )
            )
        )

        :: Если нашли подходящие папки, копируем самую свежую целиком
        if defined LATEST_FOLDER (
            echo    - Найдена самая свежая папка: !LATEST_FOLDER_NAME!
            echo    - Дата последнего изменения: !LATEST_DATE!
            echo    - Копирование папки целиком...

            :: Создаем подпапку с именем исходной папки в директории logs
            set "TARGET_FOLDER=%LOGS_PATH%\!LATEST_FOLDER_NAME!"
            if not exist "!TARGET_FOLDER!" mkdir "!TARGET_FOLDER!"

            :: Копируем всю папку целиком со всем содержимым
            xcopy "!LATEST_FOLDER!" "!TARGET_FOLDER!\" /e /i /y /q >nul

            :: Проверяем результат копирования
            if errorlevel 1 (
                echo    - ОШИБКА: Не удалось скопировать папку с логами
                echo Ошибка копирования из !LATEST_FOLDER! > "%LOGS_PATH%\copy_error.txt"
            ) else (
                echo    - Папка !LATEST_FOLDER_NAME! успешно скопирована в %LOGS_PATH%
                echo Источник: !LATEST_FOLDER! > "%LOGS_PATH%\!LATEST_FOLDER_NAME!\copied_from.txt"
                echo Дата копирования: %DATE% %TIME% >> "%LOGS_PATH%\!LATEST_FOLDER_NAME!\copied_from.txt"
                echo Дата последнего изменения исходной папки: !LATEST_DATE! >> "%LOGS_PATH%\!LATEST_FOLDER_NAME!\copied_from.txt"
            )
        ) else (
            echo    - Не найдены папки с логами в %LOGS_SOURCE%
            echo Папки с логами не найдены > "%LOGS_PATH%\no_logs_found.txt"
        )
    ) else (
        echo    - Папка с логами не существует: %LOGS_SOURCE%
        echo Папка %LOGS_SOURCE% не существует > "%LOGS_PATH%\source_not_exists.txt"
    )

    echo [4/8] Копирование deployment_errors (папки 1ce-installer из TEMP)...
    set "TEMP_PATH=%TEMP%"

    :: Копирование папки 1ce-installer-crash (всегда копируем, если существует)
    if exist "%TEMP_PATH%\1ce-installer-crash" (
        echo    - Найдена папка 1ce-installer-crash
        set "TARGET_CRASH=%DEPLOYMENT_ERRORS_PATH%\1ce-installer-crash"
        if not exist "!TARGET_CRASH!" mkdir "!TARGET_CRASH!"
        xcopy "%TEMP_PATH%\1ce-installer-crash" "!TARGET_CRASH!\" /e /i /y /q >nul
        echo    - Папка 1ce-installer-crash скопирована
    ) else (
        echo    - Папка 1ce-installer-crash не найдена в %TEMP_PATH%
        echo Папка 1ce-installer-crash не найдена > "%DEPLOYMENT_ERRORS_PATH%\crash_not_found.txt"
    )

    :: Поиск и копирование самой свежей папки 1ce-installer-20*
    echo    - Поиск папок 1ce-installer-20* в %TEMP_PATH%

    set "LATEST_INSTALLER_FOLDER="
    set "LATEST_INSTALLER_DATE=0"

    for /d %%i in ("%TEMP_PATH%\1ce-installer-20*") do (
        set "FOLDER_PATH=%%i"
        set "FOLDER_NAME=%%~nxi"

        :: Получаем дату изменения папки
        for %%f in ("%%i") do (
            set "FOLDER_DATE=%%~tf"

            :: Преобразуем дату для сравнения
            set "DAY=!FOLDER_DATE:~0,2!"
            set "MONTH=!FOLDER_DATE:~3,2!"
            set "YEAR=!FOLDER_DATE:~6,4!"
            set "HOUR=!FOLDER_DATE:~11,2!"
            set "MINUTE=!FOLDER_DATE:~14,2!"
            set "SECOND=!FOLDER_DATE:~17,2!"

            :: Убираем возможные пробелы
            set "YEAR=!YEAR: =0!"
            set "MONTH=!MONTH: =0!"
            set "DAY=!DAY: =0!"
            set "HOUR=!HOUR: =0!"
            set "MINUTE=!MINUTE: =0!"
            set "SECOND=!SECOND: =0!"

            set "DATE_NUM=!YEAR!!MONTH!!DAY!!HOUR!!MINUTE!!SECOND!"

            :: Сравниваем с текущей максимальной датой
            if !DATE_NUM! gtr !LATEST_INSTALLER_DATE! (
                set "LATEST_INSTALLER_DATE=!DATE_NUM!"
                set "LATEST_INSTALLER_FOLDER=%%i"
                set "LATEST_INSTALLER_NAME=%%~nxi"
            )
        )
    )

    if defined LATEST_INSTALLER_FOLDER (
        echo    - Найдена самая свежая папка: !LATEST_INSTALLER_NAME!
        echo    - Дата последнего изменения: !LATEST_INSTALLER_DATE!

        set "TARGET_INSTALLER=%DEPLOYMENT_ERRORS_PATH%\!LATEST_INSTALLER_NAME!"
        if not exist "!TARGET_INSTALLER!" mkdir "!TARGET_INSTALLER!"

        xcopy "!LATEST_INSTALLER_FOLDER!" "!TARGET_INSTALLER!\" /e /i /y /q >nul

        if errorlevel 1 (
            echo    - ОШИБКА: Не удалось скопировать папку !LATEST_INSTALLER_NAME!
        ) else (
            echo    - Папка !LATEST_INSTALLER_NAME! успешно скопирована
        )
    ) else (
        echo    - Папки 1ce-installer-20* не найдены в %TEMP_PATH%
        echo Папки 1ce-installer-20* не найдены > "%DEPLOYMENT_ERRORS_PATH%\installer_not_found.txt"
    )

    echo [5/8] Сбор информации о запущенных процессах...
    set "PROCESSES_FILE=%COMPUTER_PATH%\processes.txt"

    :: Получаем список процессов в CSV формате (удобно для импорта в Excel)
    (
        echo ====================================================
        echo          ЗАПУЩЕННЫЕ ПРОЦЕССЫ (CSV ФОРМАТ)
        echo ====================================================
        echo Компьютер: %COMPUTER_NAME%
        echo Дата и время сбора: %DATE% %TIME%
        echo ====================================================
        echo.
        echo "Имя_образа","PID","Имя_сессии","Номер_сессии","Память"
        echo ====================================================
    ) > "%PROCESSES_FILE%"

    :: Добавляем данные процессов в CSV формате
    tasklist /fo csv /nh >> "%PROCESSES_FILE%" 2>nul

    :: Добавляем информацию о системе
    (
        echo.
        echo ====================================================
        echo          ИНФОРМАЦИЯ О СИСТЕМЕ
        echo ====================================================
        echo.
    ) >> "%PROCESSES_FILE%"

    :: Используем systeminfo для получения базовой информации
    systeminfo | findstr /c:"Общее количество" /c:"Доступно физической" /c:"Время работы" /c:"Версия ОС" >> "%PROCESSES_FILE%" 2>nul

    :: Добавляем общее количество процессов
    echo. >> "%PROCESSES_FILE%"
    echo Общее количество запущенных процессов: >> "%PROCESSES_FILE%"
    tasklist /fo csv 2>nul | find /c /v "" >> "%PROCESSES_FILE%"

    echo    - Информация о процессах сохранена в processes.txt (CSV формат)

    echo [6/8] Копирование рабочих пространств (recentworkspace)...

    REM === НАСТРОЙКИ ===
    set "INPUT_FILE=%USERPROFILE%\1c-enterprise-element\.storage\recentworkspace.json"
    set "WORKSPACE_DIR=%COMPUTER_PATH%\workspaces"
    REM =================

    if not exist "%WORKSPACE_DIR%" mkdir "%WORKSPACE_DIR%"

    echo    - Поиск конфига: "%INPUT_FILE%"

    if not exist "%INPUT_FILE%" (
        echo    - [ОШИБКА] Файл recentworkspace.json не найден!
        echo Файл recentworkspace.json не найден > "%WORKSPACE_DIR%\not_found.txt"
        goto :SkipWorkspaces
    )

    REM Читаем содержимое файла в переменную (JSON в одну строку)
    for /f "usebackq tokens=*" %%A in ("%INPUT_FILE%") do (
        set "JSON_CONTENT=%%A"
    )

    REM --- РАЗБОР JSON ---
    REM Удаляем шапку {"recentRoots":[ и хвост ]}
    set "JSON_CONTENT=!JSON_CONTENT:*recentRoots=!"
    set "JSON_CONTENT=!JSON_CONTENT:*[=!"
    set "JSON_CONTENT=!JSON_CONTENT:]}=!"
    set "JSON_CONTENT=!JSON_CONTENT:"=!"

    REM Теперь JSON_CONTENT: file:///c%3A/Path1,file:///c%3A/Path2,...

    :ParseLoopWS
    for /f "tokens=1* delims=," %%a in ("!JSON_CONTENT!") do (
        set "RAW_PATH=%%a"
        set "JSON_CONTENT=%%b"

        REM --- ДЕКОДИРОВАНИЕ URI -> WINDOWS-ПУТЬ ---
        set "WIN_PATH=!RAW_PATH:file:///=!"
        set "WIN_PATH=!WIN_PATH:%%3A=:!"
        set "WIN_PATH=!WIN_PATH:%%20= !"
        set "WIN_PATH=!WIN_PATH:/=\!"

        echo    - Обработка: !WIN_PATH!

        REM --- Проверяем: папка или файл? ---
        if exist "!WIN_PATH!\*" (
            REM ===== ЭТО ПАПКА (проект) =====
            for %%F in ("!WIN_PATH!") do set "PROJECT_NAME=%%~nxF"
            set "TARGET_DIR=!WORKSPACE_DIR!\!PROJECT_NAME!"
            if not exist "!TARGET_DIR!" mkdir "!TARGET_DIR!"

            echo      [ПАПКА] Копирование содержимого в "!TARGET_DIR!"
            xcopy "!WIN_PATH!" "!TARGET_DIR!\" /e /i /y /q >nul
            if errorlevel 1 (
                echo      - ОШИБКА при копировании папки
            ) else (
                echo      - Папка скопирована успешно
            )

        ) else if exist "!WIN_PATH!" (
            REM ===== ЭТО ФАЙЛ =====
            for %%F in ("!WIN_PATH!") do set "FILENAME=%%~nxF"
            set "TARGET_FILE=!WORKSPACE_DIR!\!FILENAME!"

            REM Проверяем, существует ли уже файл с таким именем
            if exist "!TARGET_FILE!" (
                REM Если существует, добавляем числовой суффикс
                set "base=!FILENAME:~0,-4!"
                set "ext=!FILENAME:~-4!"
                if "!ext!"==".!ext!" (
                    rem с расширением
                    set "counter=1"
                    :loop_file
                    if exist "!WORKSPACE_DIR!\!base!_!counter!!ext!" (
                        set /a counter+=1
                        goto loop_file
                    )
                    set "TARGET_FILE=!WORKSPACE_DIR!\!base!_!counter!!ext!"
                ) else (
                    rem без расширения
                    set "counter=1"
                    :loop_file_noext
                    if exist "!WORKSPACE_DIR!\!base!_!counter!" (
                        set /a counter+=1
                        goto loop_file_noext
                    )
                    set "TARGET_FILE=!WORKSPACE_DIR!\!base!_!counter!"
                )
            )

            echo      [ФАЙЛ] Копирование в "!TARGET_FILE!"
            copy "!WIN_PATH!" "!TARGET_FILE!" /y >nul
            if errorlevel 1 (
                echo      - ОШИБКА при копировании файла
            ) else (
                echo      - Файл скопирован успешно
            )

        ) else (
            echo      [НЕ НАЙДЕНО] !WIN_PATH!
        )

        if defined JSON_CONTENT goto ParseLoopWS
    )

    echo    - Копирование рабочих пространств завершено

    :SkipWorkspaces
)

echo [7/8] Сбор информации о Java...
set "JAVA_REPORT=%COMPUTER_PATH%\java_report.txt"
(
    echo ========================================
    echo      ИНФОРМАЦИЯ О JAVA
    echo ========================================
    echo Компьютер: %COMPUTER_NAME%
    echo Дата сбора: %DATE% %TIME%
    echo ========================================
    echo.
    java -version 2>&1
    echo.
    echo --- Переменные окружения, связанные с Java ---
    set | findstr /i "java"
) > "%JAVA_REPORT%" 2>nul
echo    - Информация о Java сохранена в java_report.txt

echo [8/8] Создание сводного отчета...
set "SUMMARY_FILE=%COMPUTER_PATH%\summary_report.txt"
(
    echo ====================================================
    echo              СВОДНЫЙ ОТЧЕТ О СИСТЕМЕ
    echo ====================================================
    echo.
    echo Дата сбора: %DATE% %TIME%
    echo Компьютер: %COMPUTER_NAME%
    echo.
    echo ====================================================
    echo 1. АППАРАТНАЯ КОНФИГУРАЦИЯ И ОС
    echo ====================================================
    echo Файл: %COMPUTER_NAME%_diag.txt
    echo Размер:
    if exist "%COMPUTER_PATH%\%COMPUTER_NAME%_diag.txt" (
        for %%f in ("%COMPUTER_PATH%\%COMPUTER_NAME%_diag.txt") do echo    %%~zf байт
    ) else (
        echo    Файл не создан (ошибка dxdiag)
    )
    echo.
    echo ====================================================
    echo 2. КОМПОНЕНТЫ 1С
    echo ====================================================
) >> "%SUMMARY_FILE%"

:: Добавляем содержимое installed_versions.txt в отчет
if exist "%COMPONENTS_FILE%" (
    type "%COMPONENTS_FILE%" >> "%SUMMARY_FILE%"
) else (
    echo Файл не создан >> "%SUMMARY_FILE%"
)

(
    echo.
    echo ====================================================
    echo 3. ПРОЦЕССЫ
    echo ====================================================
) >> "%SUMMARY_FILE%"

:: Добавляем краткую статистику из processes.txt
if exist "%PROCESSES_FILE%" (
    echo Файл с процессами: processes.txt (CSV формат) >> "%SUMMARY_FILE%"
    echo Размер файла: >> "%SUMMARY_FILE%"
    for %%f in ("%PROCESSES_FILE%") do echo    %%~zf байт >> "%SUMMARY_FILE%"
    echo. >> "%SUMMARY_FILE%"
    echo Первые 10 строк файла (для ознакомления): >> "%SUMMARY_FILE%"
    echo ---------------------------------------- >> "%SUMMARY_FILE%"
    type "%PROCESSES_FILE%" | findstr /n "^" | findstr /b "[1-9]: [1-9]: " 2>nul >> "%SUMMARY_FILE%"
) else (
    echo Файл с процессами не создан >> "%SUMMARY_FILE%"
)

(
    echo.
    echo ====================================================
    echo 4. ЛОГИ
    echo ====================================================
) >> "%SUMMARY_FILE%"

if exist "%LOGS_PATH%" (
    echo Папка с логами: %LOGS_PATH% >> "%SUMMARY_FILE%"
    echo. >> "%SUMMARY_FILE%"
    echo Содержимое папки logs: >> "%SUMMARY_FILE%"

    :: Показываем структуру скопированных папок
    for /d %%d in ("%LOGS_PATH%\*") do (
        echo [ПАПКА] %%~nxd >> "%SUMMARY_FILE%"
        if exist "%%d\copied_from.txt" (
            echo   Информация: >> "%SUMMARY_FILE%"
            for /f "tokens=*" %%l in (%%d\copied_from.txt) do (
                echo     %%l >> "%SUMMARY_FILE%"
            )
        )
        echo. >> "%SUMMARY_FILE%"
    )

    :: Показываем файлы в корне logs, если есть
    dir "%LOGS_PATH%" /b /a-d 2>nul >> "%SUMMARY_FILE%"
) else (
    echo Папка с логами не создана >> "%SUMMARY_FILE%"
)

(
    echo.
    echo ====================================================
    echo 5. DEPLOYMENT ERRORS
    echo ====================================================
) >> "%SUMMARY_FILE%"

if exist "%DEPLOYMENT_ERRORS_PATH%" (
    echo Папка с ошибками развертывания: %DEPLOYMENT_ERRORS_PATH% >> "%SUMMARY_FILE%"
    echo. >> "%SUMMARY_FILE%"
    echo Содержимое папки deployment_errors: >> "%SUMMARY_FILE%"

    :: Показываем структуру скопированных папок
    for /d %%d in ("%DEPLOYMENT_ERRORS_PATH%\*") do (
        echo [ПАПКА] %%~nxd >> "%SUMMARY_FILE%"
        echo. >> "%SUMMARY_FILE%"
    )

    :: Показываем информационные файлы, если есть
    dir "%DEPLOYMENT_ERRORS_PATH%\*.txt" /b 2>nul >> "%SUMMARY_FILE%"
) else (
    echo Папка с ошибками развертывания не создана >> "%SUMMARY_FILE%"
)

(
    echo.
    echo ====================================================
    echo 6. РАБОЧИЕ ПРОСТРАНСТВА (WORKSPACES)
    echo ====================================================
) >> "%SUMMARY_FILE%"

if exist "%WORKSPACE_DIR%" (
    echo Папка: %WORKSPACE_DIR% >> "%SUMMARY_FILE%"
    echo. >> "%SUMMARY_FILE%"
    echo Скопированные элементы: >> "%SUMMARY_FILE%"
    dir "%WORKSPACE_DIR%" /b 2>nul >> "%SUMMARY_FILE%"
) else (
    echo Папка workspaces не создана >> "%SUMMARY_FILE%"
)

(
    echo.
    echo ====================================================
    echo 7. JAVA
    echo ====================================================
) >> "%SUMMARY_FILE%"

if exist "%JAVA_REPORT%" (
    echo Файл: java_report.txt >> "%SUMMARY_FILE%"
    echo Содержимое: >> "%SUMMARY_FILE%"
    echo ---------------------------------------- >> "%SUMMARY_FILE%"
    type "%JAVA_REPORT%" >> "%SUMMARY_FILE%"
) else (
    echo Файл java_report.txt не создан >> "%SUMMARY_FILE%"
)

(
    echo.
    echo ====================================================
    echo Конец отчета
    echo ====================================================
) >> "%SUMMARY_FILE%"

:: Создаем файл с информацией о компьютерах в папке с датой
set "COMPUTERS_LIST_FILE=%BASE_PATH%\computers_list.txt"

:: Если файл не существует, создаем его с заголовком
if not exist "%COMPUTERS_LIST_FILE%" (
    echo ==================================================== > "%COMPUTERS_LIST_FILE%"
    echo       СПИСОК КОМПЬЮТЕРОВ ЗА %DATE_FOLDER% >> "%COMPUTERS_LIST_FILE%"
    echo ==================================================== >> "%COMPUTERS_LIST_FILE%"
    echo Дата сбора ^| Время ^| Имя компьютера >> "%COMPUTERS_LIST_FILE%"
    echo ==================================================== >> "%COMPUTERS_LIST_FILE%"
)

:: Добавляем запись о текущем компьютере
echo %DATE% ^| %TIME% ^| %COMPUTER_NAME% ^| %COLLECTION_MODE% >> "%COMPUTERS_LIST_FILE%"

echo.
echo =====================================================
echo            СБОР ИНФОРМАЦИИ ЗАВЕРШЕН
echo =====================================================
echo.
echo Данные сохранены в:
echo %COMPUTER_PATH%
echo.
echo Структура папок на устройстве %SCRIPT_DRIVE%:

if /i "%COLLECTION_MODE%"=="full" (
    echo %DATE_FOLDER%\
    echo   ├── computers_list.txt
    echo   └── %COMPUTER_NAME%\
    echo       ├── %COMPUTER_NAME%_diag.txt
    echo       ├── installed_versions.txt
    echo       ├── processes.txt
    echo       ├── summary_report.txt
    echo       ├── logs\
    echo       │   └── [папка_с_самыми_свежими_логами]\
    echo       └── deployment_errors\
    echo           ├── 1ce-installer-crash\ (если найдена)
    echo           └── 1ce-installer-20*\ (самая свежая)
) else (
    echo %DATE_FOLDER%\
    echo   ├── computers_list.txt
    echo   └── %COMPUTER_NAME%\
    echo       ├── %COMPUTER_NAME%_diag.txt
    echo       ├── installed_versions.txt
    echo       └── summary_report.txt
)

echo.
echo Сводный отчет: %SUMMARY_FILE%
echo.
echo Список компьютеров за %DATE_FOLDER%: %COMPUTERS_LIST_FILE%
