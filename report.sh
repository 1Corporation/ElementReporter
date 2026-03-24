#!/bin/bash
# -*- coding: utf-8 -*-

# ====================================================================
#  Скрипт сбора информации о системе (Linux-версия)
#  Адаптирован под режимы Full/Light
# ====================================================================

# [ДОБАВЛЕНО] Проверка прав root
if [ "$EUID" -ne 0 ]; then
    echo ""
    echo "====================================================="
    echo "[ВНИМАНИЕ] Скрипт запущен БЕЗ прав root!"
    echo "Некоторые данные (dmidecode, lspci, системные логи) могут быть недоступны."
    echo "Рекомендуется перезапустить скрипт через sudo."
    echo "====================================================="
    echo ""
    sleep 3
fi

# Настройка кодировки
export LANG=ru_RU.UTF-8 2>/dev/null
export LC_ALL=ru_RU.UTF-8 2>/dev/null

# [ДОБАВЛЕНО] Функция логирования (должна быть определена до использования)
log_msg() {
    local level="$1"
    local msg="$2"
    # Пишем только если переменная лога задана и файл доступен для записи
    if [ -n "$EXEC_LOG" ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $msg" >> "$EXEC_LOG"
    fi
}

# =====================================================
# НАСТРОЙКИ СКРИПТА
# =====================================================
# Режим сбора информации:
#   full  - собирать ВСЮ информацию (шаги 1-8)
#   light - собирать только базовую информацию (шаги 1, 2, 7 и 8)
COLLECTION_MODE="light"
SCRIPT_VERSION="1.1"
# =====================================================

# ---- Определяем путь к устройству, с которого запущен скрипт ----
SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ---- Дата в формате ДДММГГ ----
DATE_FOLDER=1CScript_$(date +%d%m%y)
CURRENT_DATE=$(date +%d.%m.%Y)
CURRENT_TIME=$(date +%H:%M:%S)
FULL_DATETIME="$CURRENT_DATE $CURRENT_TIME"

# ---- Имя компьютера ----
COMPUTER_NAME=$(hostname)

# ---- Иерархия папок ----
BASE_PATH="$SCRIPT_PATH/$DATE_FOLDER"
COMPUTER_PATH="$BASE_PATH/$COMPUTER_NAME"
LOGS_PATH="$COMPUTER_PATH/logs"
DEPLOYMENT_ERRORS_PATH="$COMPUTER_PATH/deployment_errors"

# [ДОБАВЛЕНО] Определение файла технического журнала
EXEC_LOG="$COMPUTER_PATH/script_execution.log"


# Инфо о скрипте
SCRIPT_INFO_FILE="$COMPUTER_PATH/script_info.txt"

echo "Версия скрипта: $SCRIPT_VERSION"

{
  echo "Версия скрипта: $SCRIPT_VERSION"
} > "$SCRIPT_INFO_FILE"

echo "====================================================="
echo "       СБОР ИНФОРМАЦИИ О СИСТЕМЕ (Linux)"
echo "====================================================="
echo ""
echo "Путь сохранения: $SCRIPT_PATH"
echo "Дата: $DATE_FOLDER"
echo "Компьютер: $COMPUTER_NAME"
echo "Режим сбора: $COLLECTION_MODE"
echo ""

if [ "$COLLECTION_MODE" == "full" ]; then
    echo "Режим FULL - будет собрана ВСЯ информация (шаги 1-8)"
else
    echo "Режим LIGHT - будет собрана только базовая информация (шаги 1, 2, 7 и 8)"
fi

echo ""
echo "Создание структуры папок..."

# ---- Создаём необходимые папки ----
mkdir -p "$BASE_PATH"
mkdir -p "$COMPUTER_PATH"

# [ДОБАВЛЕНО] Инициализация лога
log_msg "INFO" "Запуск скрипта сбора информации (Linux). Режим: $COLLECTION_MODE"
log_msg "INFO" "Целевая папка создана: $COMPUTER_PATH"

# Папки для логов создаем только в FULL режиме
if [ "$COLLECTION_MODE" == "full" ]; then
    mkdir -p "$LOGS_PATH"
    mkdir -p "$DEPLOYMENT_ERRORS_PATH"
    # [ДОБАВЛЕНО] Лог создания папок
    log_msg "INFO" "Созданы папки для логов и ошибок."
fi

# ====================================================================
#  [1/8] Аппаратная конфигурация и ОС (замена dxdiag)
# ====================================================================
echo "[1/8] Сбор информации об аппаратной конфигурации и ОС..."
# [ДОБАВЛЕНО] Лог шага 1
log_msg "INFO" "[ШАГ 1] Сбор диагностики системы..."

DIAG_FILE="$COMPUTER_PATH/${COMPUTER_NAME}_diag.txt"
{
    echo "========================================================"
    echo "  ДИАГНОСТИКА СИСТЕМЫ — $COMPUTER_NAME"
    echo "  Дата сбора: $FULL_DATETIME"
    echo "========================================================"
    echo ""

    echo "--- ЯДРО / ОС ---"
    uname -a 2>/dev/null
    echo ""

    echo "--- ДИСТРИБУТИВ ---"
    if [ -f /etc/os-release ]; then
        cat /etc/os-release
    elif [ -f /etc/lsb-release ]; then
        cat /etc/lsb-release
    elif command -v lsb_release &>/dev/null; then
        lsb_release -a 2>/dev/null
    else
        echo "(информация о дистрибутиве не найдена)"
    fi
    echo ""

    echo "--- ПРОЦЕССОР ---"
    if [ -f /proc/cpuinfo ]; then
        grep -m1 'model name' /proc/cpuinfo 2>/dev/null
        grep -c '^processor' /proc/cpuinfo 2>/dev/null | xargs -I{} echo "Логических ядер: {}"
    fi
    if command -v lscpu &>/dev/null; then
        echo ""
        lscpu 2>/dev/null
    fi
    echo ""

    echo "--- ОПЕРАТИВНАЯ ПАМЯТЬ ---"
    if [ -f /proc/meminfo ]; then
        grep -E 'MemTotal|MemFree|MemAvailable|SwapTotal|SwapFree' /proc/meminfo 2>/dev/null
    fi
    if command -v free &>/dev/null; then
        echo ""
        free -h 2>/dev/null
    fi
    echo ""

    echo "--- ВИДЕОКАРТА ---"
    if command -v lspci &>/dev/null; then
        lspci 2>/dev/null | grep -iE 'vga|3d|display'
    else
        echo "(lspci не установлен)"
    fi
    echo ""

    echo "--- ДИСКИ ---"
    if command -v lsblk &>/dev/null; then
        lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT 2>/dev/null
    fi
    echo ""
    df -hT 2>/dev/null
    echo ""

    echo "--- СЕТЬ ---"
    if command -v ip &>/dev/null; then
        ip addr show 2>/dev/null
    elif command -v ifconfig &>/dev/null; then
        ifconfig 2>/dev/null
    fi
    echo ""

    echo "--- PCI-УСТРОЙСТВА ---"
    if command -v lspci &>/dev/null; then
        lspci 2>/dev/null
    fi
    echo ""

    echo "--- USB-УСТРОЙСТВА ---"
    if command -v lsusb &>/dev/null; then
        lsusb 2>/dev/null
    fi
    echo ""

    echo "--- UPTIME ---"
    uptime 2>/dev/null

} > "$DIAG_FILE"

# [ДОБАВЛЕНО] Проверка создания файла
if [ -s "$DIAG_FILE" ]; then
    log_msg "INFO" "Файл диагностики успешно создан."
else
    log_msg "ERROR" "Файл диагностики пуст или не создан."
fi

echo "   - Диагностика сохранена в ${COMPUTER_NAME}_diag.txt"

# ====================================================================
#  [2/8] Компоненты 1С
# ====================================================================
echo "[2/8] Сбор информации о компонентах 1С..."
# [ДОБАВЛЕНО] Лог шага 2
log_msg "INFO" "[ШАГ 2] Поиск компонентов 1С..."

COMPONENTS_FILE="$COMPUTER_PATH/installed_versions.txt"

# Возможные пути установки компонентов 1С на Linux
COMPONENTS_DIRS=(
    "/opt/1C/1CE/components"
    "/opt/1c/1ce/components"
    "/opt/1C/v8.3"
    "$HOME/.1CE/components"
    "$HOME/1c-enterprise-element/.storage/components"
)

{
    echo "========================================"
    echo "Компьютер: $COMPUTER_NAME"
    echo "Дата сбора: $FULL_DATETIME"
    echo "========================================"
    echo ""

    FOUND_ANY=0
    for COMP_DIR in "${COMPONENTS_DIRS[@]}"; do
        echo "Компоненты 1С в $COMP_DIR:"
        echo "----------------------------------------"
        if [ -d "$COMP_DIR" ]; then
            ls -1d "$COMP_DIR"/*/ 2>/dev/null | xargs -I{} basename "{}"
            if [ $? -ne 0 ] || [ -z "$(ls -A "$COMP_DIR" 2>/dev/null)" ]; then
                echo "(папка пуста)"
            fi
            FOUND_ANY=1
        else
            echo "Папка не найдена: $COMP_DIR"
        fi
        echo ""
    done

    # Дополнительно: ищем установленные пакеты 1С
    echo "Установленные пакеты 1С (из менеджера пакетов):"
    echo "----------------------------------------"
    if command -v dpkg &>/dev/null; then
        dpkg -l 2>/dev/null | grep -i "1c\|1С" || echo "(не найдены через dpkg)"
    fi
    if command -v rpm &>/dev/null; then
        rpm -qa 2>/dev/null | grep -i "1c\|1С" || echo "(не найдены через rpm)"
    fi
    if command -v snap &>/dev/null; then
        snap list 2>/dev/null | grep -i "1c\|1С" || echo "(не найдены через snap)"
    fi
    if command -v flatpak &>/dev/null; then
        flatpak list 2>/dev/null | grep -i "1c\|1С" || echo "(не найдены через flatpak)"
    fi

} > "$COMPONENTS_FILE"

# [ДОБАВЛЕНО] Лог завершения шага 2
log_msg "INFO" "Список компонентов сохранен."

echo "   - Список компонентов сохранен в installed_versions.txt"

# ====================================================================
#  ПРОВЕРКА РЕЖИМА ДЛЯ ШАГОВ 3-6
# ====================================================================
if [ "$COLLECTION_MODE" != "full" ]; then
    echo ""
    echo "-----------------------------------------------------"
    echo "Режим \"$COLLECTION_MODE\": Шаги 3, 4, 5, 6 пропускаются."
    echo "-----------------------------------------------------"
    # [ДОБАВЛЕНО] Лог пропуска
    log_msg "INFO" "Пропуск шагов 3-6 (режим Light)."
else
    # ====================================================================
    #  [3/8] Копирование логов 1С
    # ====================================================================
    echo "[3/8] Копирование логов 1С..."
    # [ДОБАВЛЕНО] Лог шага 3
    log_msg "INFO" "[ШАГ 3] Поиск логов 1С..."

    USER_HOME="$HOME"
    LOGS_SOURCE="$USER_HOME/1c-enterprise-element/.storage/logs"

    if [ -d "$LOGS_SOURCE" ]; then
        echo "   - Поиск папок с логами в $LOGS_SOURCE"

        # Находим самую свежую папку по дате модификации
        LATEST_FOLDER=$(find "$LOGS_SOURCE" -maxdepth 1 -mindepth 1 -type d \
            -printf '%T@ %p\n' 2>/dev/null | sort -rn | head -1 | cut -d' ' -f2-)

        # Если -printf не поддерживается (не GNU find), пробуем альтернативу
        if [ -z "$LATEST_FOLDER" ]; then
            LATEST_FOLDER=$(find "$LOGS_SOURCE" -maxdepth 1 -mindepth 1 -type d \
                -exec stat --format='%Y %n' {} \; 2>/dev/null | sort -rn | head -1 | cut -d' ' -f2-)
        fi

        if [ -n "$LATEST_FOLDER" ] && [ -d "$LATEST_FOLDER" ]; then
            LATEST_FOLDER_NAME=$(basename "$LATEST_FOLDER")
            LATEST_DATE=$(stat --format='%y' "$LATEST_FOLDER" 2>/dev/null || stat -f '%Sm' "$LATEST_FOLDER" 2>/dev/null)

            echo "   - Найдена самая свежая папка: $LATEST_FOLDER_NAME"
            echo "   - Дата последнего изменения: $LATEST_DATE"
            echo "   - Копирование папки целиком..."
            # [ДОБАВЛЕНО] Лог находки
            log_msg "INFO" "Найдена свежая папка логов: $LATEST_FOLDER_NAME. Копируем..."

            TARGET_FOLDER="$LOGS_PATH/$LATEST_FOLDER_NAME"
            mkdir -p "$TARGET_FOLDER"

            if cp -r "$LATEST_FOLDER"/* "$TARGET_FOLDER/" 2>/dev/null; then
                echo "   - Папка $LATEST_FOLDER_NAME успешно скопирована в $LOGS_PATH"
                {
                    echo "Источник: $LATEST_FOLDER"
                    echo "Дата копирования: $FULL_DATETIME"
                    echo "Дата последнего изменения исходной папки: $LATEST_DATE"
                } > "$TARGET_FOLDER/copied_from.txt"
                # [ДОБАВЛЕНО] Лог успеха
                log_msg "INFO" "Логи успешно скопированы."
            else
                echo "   - ОШИБКА: Не удалось скопировать папку с логами"
                echo "Ошибка копирования из $LATEST_FOLDER" > "$LOGS_PATH/copy_error.txt"
                # [ДОБАВЛЕНО] Лог ошибки
                log_msg "ERROR" "Ошибка cp при копировании логов из $LATEST_FOLDER"
            fi
        else
            echo "   - Не найдены папки с логами в $LOGS_SOURCE"
            echo "Папки с логами не найдены" > "$LOGS_PATH/no_logs_found.txt"
            # [ДОБАВЛЕНО] Лог предупреждение
            log_msg "WARNING" "Папка logs пуста или не содержит подпапок."
        fi
    else
        echo "   - Папка с логами не существует: $LOGS_SOURCE"
        echo "Папка $LOGS_SOURCE не существует" > "$LOGS_PATH/source_not_exists.txt"
        # [ДОБАВЛЕНО] Лог предупреждение
        log_msg "WARNING" "Исходная папка логов не найдена ($LOGS_SOURCE)."
    fi

    # ====================================================================
    #  [4/8] Копирование deployment_errors (папки 1ce-installer из /tmp)
    # ====================================================================
    echo "[4/8] Копирование deployment_errors (папки 1ce-installer из /tmp)..."
    # [ДОБАВЛЕНО] Лог шага 4
    log_msg "INFO" "[ШАГ 4] Поиск ошибок развертывания в TMP..."

    TEMP_PATH="${TMPDIR:-/tmp}"

    # Копирование папки 1ce-installer-crash
    if [ -d "$TEMP_PATH/1ce-installer-crash" ]; then
        echo "   - Найдена папка 1ce-installer-crash"
        # [ДОБАВЛЕНО] Лог краша
        log_msg "INFO" "Обнаружен краш-дамп инсталлятора."
        TARGET_CRASH="$DEPLOYMENT_ERRORS_PATH/1ce-installer-crash"
        mkdir -p "$TARGET_CRASH"
        cp -r "$TEMP_PATH/1ce-installer-crash"/* "$TARGET_CRASH/" 2>/dev/null
        echo "   - Папка 1ce-installer-crash скопирована"
    else
        echo "   - Папка 1ce-installer-crash не найдена в $TEMP_PATH"
        echo "Папка 1ce-installer-crash не найдена" > "$DEPLOYMENT_ERRORS_PATH/crash_not_found.txt"
    fi

    # Поиск и копирование самой свежей папки 1ce-installer-20*
    echo "   - Поиск папок 1ce-installer-20* в $TEMP_PATH"

    LATEST_INSTALLER_FOLDER=$(find "$TEMP_PATH" -maxdepth 1 -mindepth 1 -type d \
        -name '1ce-installer-20*' -printf '%T@ %p\n' 2>/dev/null | sort -rn | head -1 | cut -d' ' -f2-)

    # Альтернатива без -printf
    if [ -z "$LATEST_INSTALLER_FOLDER" ]; then
        LATEST_INSTALLER_FOLDER=$(find "$TEMP_PATH" -maxdepth 1 -mindepth 1 -type d \
            -name '1ce-installer-20*' -exec stat --format='%Y %n' {} \; 2>/dev/null \
            | sort -rn | head -1 | cut -d' ' -f2-)
    fi

    if [ -n "$LATEST_INSTALLER_FOLDER" ] && [ -d "$LATEST_INSTALLER_FOLDER" ]; then
        LATEST_INSTALLER_NAME=$(basename "$LATEST_INSTALLER_FOLDER")
        LATEST_INSTALLER_DATE=$(stat --format='%y' "$LATEST_INSTALLER_FOLDER" 2>/dev/null)

        echo "   - Найдена самая свежая папка: $LATEST_INSTALLER_NAME"
        echo "   - Дата последнего изменения: $LATEST_INSTALLER_DATE"

        TARGET_INSTALLER="$DEPLOYMENT_ERRORS_PATH/$LATEST_INSTALLER_NAME"
        mkdir -p "$TARGET_INSTALLER"

        if cp -r "$LATEST_INSTALLER_FOLDER"/* "$TARGET_INSTALLER/" 2>/dev/null; then
            echo "   - Папка $LATEST_INSTALLER_NAME успешно скопирована"
            # [ДОБАВЛЕНО] Лог успеха
            log_msg "INFO" "Папка инсталлятора скопирована."
        else
            echo "   - ОШИБКА: Не удалось скопировать папку $LATEST_INSTALLER_NAME"
            # [ДОБАВЛЕНО] Лог ошибки
            log_msg "ERROR" "Ошибка копирования папки инсталлятора."
        fi
    else
        echo "   - Папки 1ce-installer-20* не найдены в $TEMP_PATH"
        echo "Папки 1ce-installer-20* не найдены" > "$DEPLOYMENT_ERRORS_PATH/installer_not_found.txt"
    fi

    # ====================================================================
    #  [5/8] Сбор информации о запущенных процессах
    # ====================================================================
    echo "[5/8] Сбор информации о запущенных процессах..."
    # [ДОБАВЛЕНО] Лог шага 5
    log_msg "INFO" "[ШАГ 5] Сбор списка процессов..."

    PROCESSES_FILE="$COMPUTER_PATH/processes.txt"

    {
        echo "===================================================="
        echo "         ЗАПУЩЕННЫЕ ПРОЦЕССЫ"
        echo "===================================================="
        echo "Компьютер: $COMPUTER_NAME"
        echo "Дата и время сбора: $FULL_DATETIME"
        echo "===================================================="
        echo ""
        echo "--- Полный список процессов (ps aux) ---"
        echo ""
        ps aux 2>/dev/null
        echo ""
        echo "===================================================="
        echo "         ИНФОРМАЦИЯ О СИСТЕМЕ"
        echo "===================================================="
        echo ""

        echo "--- Память ---"
        free -h 2>/dev/null
        echo ""

        echo "--- Время работы ---"
        uptime 2>/dev/null
        echo ""

        echo "--- Версия ОС ---"
        uname -a 2>/dev/null
        echo ""

        TOTAL_PROCS=$(ps aux 2>/dev/null | tail -n +2 | wc -l)
        echo "Общее количество запущенных процессов: $TOTAL_PROCS"

    } > "$PROCESSES_FILE"

    # Дополнительно: CSV-формат для совместимости
    PROCESSES_CSV="$COMPUTER_PATH/processes.csv"
    {
        echo "\"USER\",\"PID\",\"%CPU\",\"%MEM\",\"VSZ\",\"RSS\",\"TTY\",\"STAT\",\"START\",\"TIME\",\"COMMAND\""
        ps aux --no-headers 2>/dev/null | awk '{
            cmd = "";
            for(i=11; i<=NF; i++) cmd = cmd (i>11?" ":"") $i;
            printf "\"%s\",\"%s\",\"%s\",\"%s\",\"%s\",\"%s\",\"%s\",\"%s\",\"%s\",\"%s\",\"%s\"\n",
                $1,$2,$3,$4,$5,$6,$7,$8,$9,$10,cmd
        }'
    } > "$PROCESSES_CSV" 2>/dev/null

    echo "   - Информация о процессах сохранена в processes.txt и processes.csv"

    # ====================================================================
    #  [6/8] Копирование рабочих пространств (recentworkspace)
    # ====================================================================
    echo "[6/8] Копирование рабочих пространств (recentworkspace)..."
    # [ДОБАВЛЕНО] Лог шага 6
    log_msg "INFO" "[ШАГ 6] Обработка рабочих пространств..."

    INPUT_FILE="$HOME/1c-enterprise-element/.storage/recentworkspace.json"
    WORKSPACE_DIR="$COMPUTER_PATH/workspaces"
    mkdir -p "$WORKSPACE_DIR"

    echo "   - Поиск конфига: $INPUT_FILE"

    if [ ! -f "$INPUT_FILE" ]; then
        echo "   - [ОШИБКА] Файл recentworkspace.json не найден!"
        echo "Файл recentworkspace.json не найден" > "$WORKSPACE_DIR/not_found.txt"
        # [ДОБАВЛЕНО] Лог ошибки
        log_msg "WARNING" "Конфигурационный файл workspace не найден."
    else
        # ---- Разбор JSON ----
        JSON_CONTENT=$(cat "$INPUT_FILE" 2>/dev/null)

        # Пробуем использовать jq, если доступен
        if command -v jq &>/dev/null; then
            PATHS_LIST=$(jq -r '.recentRoots[]' "$INPUT_FILE" 2>/dev/null)
        elif command -v python3 &>/dev/null; then
            PATHS_LIST=$(python3 -c "
import json, sys
with open('$INPUT_FILE', 'r') as f:
    data = json.load(f)
for uri in data.get('recentRoots', []):
    print(uri)
" 2>/dev/null)
        else
            # Ручной разбор без внешних инструментов
            PATHS_LIST=$(echo "$JSON_CONTENT" \
                | sed 's/.*"recentRoots":\[//;s/\].*//' \
                | tr ',' '\n' \
                | sed 's/^"//;s/"$//' \
                | sed 's/^ *//;s/ *$//')
        fi

        if [ -z "$PATHS_LIST" ]; then
            echo "   - Не удалось извлечь пути из recentworkspace.json"
            echo "Не удалось разобрать JSON" > "$WORKSPACE_DIR/parse_error.txt"
            # [ДОБАВЛЕНО] Лог парсинга
            log_msg "ERROR" "Ошибка парсинга recentworkspace.json."
        else
            # Функция декодирования URI
            decode_uri() {
                local uri="$1"
                # Убираем file:///
                local path="${uri#file:///}"
                # Для Linux пути: file:///home/... → /home/...
                # Проверяем, начинается ли с /
                if [[ "$path" != /* ]]; then
                    path="/$path"
                fi
                # Декодируем URL-кодированные символы
                if command -v python3 &>/dev/null; then
                    path=$(python3 -c "import urllib.parse; print(urllib.parse.unquote('$path'))" 2>/dev/null)
                else
                    # Ручное декодирование частых случаев
                    path=$(echo "$path" | sed 's/%20/ /g; s/%3A/:/g; s/%23/#/g; s/%25/%/g; s/%2F/\//g')
                fi
                echo "$path"
            }

            # Обрабатываем каждый путь
            while IFS= read -r RAW_PATH; do
                [ -z "$RAW_PATH" ] && continue

                WIN_PATH=$(decode_uri "$RAW_PATH")
                echo "   - Обработка: $WIN_PATH"

                if [ -d "$WIN_PATH" ]; then
                    # ===== ЭТО ПАПКА (проект) =====
                    PROJECT_NAME=$(basename "$WIN_PATH")
                    TARGET_DIR="$WORKSPACE_DIR/$PROJECT_NAME"
                    mkdir -p "$TARGET_DIR"

                    echo "     [ПАПКА] Копирование содержимого в $TARGET_DIR"
                    # Копируем всё содержимое папки рекурсивно
                    cp -r "$WIN_PATH"/* "$TARGET_DIR/" 2>/dev/null
                    if [ $? -eq 0 ]; then
                        echo "     - Папка скопирована успешно"
                    else
                        echo "     - ОШИБКА при копировании папки"
                        # [ДОБАВЛЕНО] Лог ошибки копирования
                        log_msg "ERROR" "Ошибка копирования папки workspace: $WIN_PATH"
                    fi

                elif [ -f "$WIN_PATH" ]; then
                    # ===== ЭТО ФАЙЛ =====
                    FILENAME=$(basename "$WIN_PATH")
                    TARGET_FILE="$WORKSPACE_DIR/$FILENAME"

                    # Проверяем, существует ли уже файл с таким именем
                    if [ -e "$TARGET_FILE" ]; then
                        # Если существует, добавляем числовой суффикс
                        base="${FILENAME%.*}"
                        ext="${FILENAME##*.}"
                        if [ "$base" = "$FILENAME" ]; then
                            # нет расширения
                            counter=1
                            while [ -e "$WORKSPACE_DIR/${base}_$counter" ]; do
                                ((counter++))
                            done
                            TARGET_FILE="$WORKSPACE_DIR/${base}_$counter"
                        else
                            counter=1
                            while [ -e "$WORKSPACE_DIR/${base}_$counter.$ext" ]; do
                                ((counter++))
                            done
                            TARGET_FILE="$WORKSPACE_DIR/${base}_$counter.$ext"
                        fi
                    fi

                    echo "     [ФАЙЛ] Копирование в $TARGET_FILE"
                    cp "$WIN_PATH" "$TARGET_FILE" 2>/dev/null
                    if [ $? -eq 0 ]; then
                        echo "     - Файл скопирован успешно"
                    else
                        echo "     - ОШИБКА при копировании файла"
                        # [ДОБАВЛЕНО] Лог ошибки копирования
                        log_msg "ERROR" "Ошибка копирования файла workspace: $WIN_PATH"
                    fi

                else
                    echo "     [НЕ НАЙДЕНО] $WIN_PATH"
                    # [ДОБАВЛЕНО] Лог отсутствия
                    log_msg "WARNING" "Путь workspace не найден на диске: $WIN_PATH"
                fi

            done <<< "$PATHS_LIST"
        fi

        echo "   - Копирование рабочих пространств завершено"
    fi
fi
# ====================================================================
#  КОНЕЦ БЛОКА УСЛОВНОГО ВЫПОЛНЕНИЯ
# ====================================================================

# ====================================================================
#  [7/8] Сбор информации о Java
# ====================================================================
echo "[7/8] Сбор информации о Java..."
# [ДОБАВЛЕНО] Лог шага 7
log_msg "INFO" "[ШАГ 7] Проверка версии Java..."

JAVA_REPORT="$COMPUTER_PATH/java_report.txt"
{
    echo "========================================"
    echo "      ИНФОРМАЦИЯ О JAVA"
    echo "========================================"
    echo "Компьютер: $COMPUTER_NAME"
    echo "Дата сбора: $FULL_DATETIME"
    echo "Режим сбора: $COLLECTION_MODE"
    echo "========================================"
    echo ""

    if command -v java &>/dev/null; then
        java -version 2>&1
    else
        echo "Java не найдена в системе"
    fi

    echo ""
    echo "--- Переменные окружения, связанные с Java ---"
    env | grep -i java 2>/dev/null || echo "(нет переменных JAVA_*)"

} > "$JAVA_REPORT"

echo "   - Информация о Java сохранена в java_report.txt"

# ====================================================================
#  [8/8] Создание сводного отчёта
# ====================================================================
echo "[8/8] Создание сводного отчета..."
# [ДОБАВЛЕНО] Лог шага 8
log_msg "INFO" "[ШАГ 8] Генерация сводного отчета..."

SUMMARY_FILE="$COMPUTER_PATH/summary_report.txt"

{
    echo "===================================================="
    echo "              СВОДНЫЙ ОТЧЁТ О СИСТЕМЕ"
    echo "===================================================="
    echo ""
    echo "Дата сбора: $FULL_DATETIME"
    echo "Компьютер: $COMPUTER_NAME"
    echo ""
    echo "===================================================="
    echo "1. АППАРАТНАЯ КОНФИГУРАЦИЯ И ОС"
    echo "===================================================="
    echo "Файл: ${COMPUTER_NAME}_diag.txt"

    if [ -f "$DIAG_FILE" ]; then
        FILE_SIZE=$(stat --format='%s' "$DIAG_FILE" 2>/dev/null || stat -f '%z' "$DIAG_FILE" 2>/dev/null)
        echo "Размер: ${FILE_SIZE} байт"
    else
        echo "Файл не создан"
    fi

    echo ""
    echo "===================================================="
    echo "2. КОМПОНЕНТЫ 1С"
    echo "===================================================="

    if [ -f "$COMPONENTS_FILE" ]; then
        cat "$COMPONENTS_FILE"
    else
        echo "Файл не создан"
    fi

    echo ""
    echo "===================================================="
    echo "3. ПРОЦЕССЫ"
    echo "===================================================="

    if [ -f "$PROCESSES_FILE" ]; then
        FILE_SIZE=$(stat --format='%s' "$PROCESSES_FILE" 2>/dev/null || stat -f '%z' "$PROCESSES_FILE" 2>/dev/null)
        echo "Файл с процессами: processes.txt"
        echo "Размер файла: ${FILE_SIZE} байт"
        echo ""
        echo "Первые 15 строк файла (для ознакомления):"
        echo "----------------------------------------"
        head -15 "$PROCESSES_FILE"
    else
        if [ "$COLLECTION_MODE" == "full" ]; then
             echo "Файл с процессами не создан"
        else
             echo "ПРОПУЩЕНО (Режим Light)"
        fi
    fi

    echo ""
    echo "===================================================="
    echo "4. ЛОГИ"
    echo "===================================================="

    if [ -d "$LOGS_PATH" ]; then
        echo "Папка с логами: $LOGS_PATH"
        echo ""
        echo "Содержимое папки logs:"

        for d in "$LOGS_PATH"/*/; do
            [ -d "$d" ] || continue
            DIR_NAME=$(basename "$d")
            echo "[ПАПКА] $DIR_NAME"
            if [ -f "$d/copied_from.txt" ]; then
                echo "  Информация:"
                while IFS= read -r line; do
                    echo "    $line"
                done < "$d/copied_from.txt"
            fi
            echo ""
        done

        find "$LOGS_PATH" -maxdepth 1 -type f -exec basename {} \; 2>/dev/null
    else
        if [ "$COLLECTION_MODE" == "full" ]; then
             echo "Папка с логами не создана"
        else
             echo "ПРОПУЩЕНО (Режим Light)"
        fi
    fi

    echo ""
    echo "===================================================="
    echo "5. DEPLOYMENT ERRORS"
    echo "===================================================="

    if [ -d "$DEPLOYMENT_ERRORS_PATH" ]; then
        echo "Папка с ошибками развертывания: $DEPLOYMENT_ERRORS_PATH"
        echo ""
        echo "Содержимое папки deployment_errors:"

        for d in "$DEPLOYMENT_ERRORS_PATH"/*/; do
            [ -d "$d" ] || continue
            echo "[ПАПКА] $(basename "$d")"
            echo ""
        done

        find "$DEPLOYMENT_ERRORS_PATH" -maxdepth 1 -name '*.txt' -exec basename {} \; 2>/dev/null
    else
        if [ "$COLLECTION_MODE" == "full" ]; then
             echo "Папка с ошибками развертывания не создана"
        else
             echo "ПРОПУЩЕНО (Режим Light)"
        fi
    fi

    echo ""
    echo "===================================================="
    echo "6. РАБОЧИЕ ПРОСТРАНСТВА (WORKSPACES)"
    echo "===================================================="

    if [ -d "$WORKSPACE_DIR" ]; then
        echo "Папка: $WORKSPACE_DIR"
        echo ""
        echo "Скопированные элементы:"
        ls -1 "$WORKSPACE_DIR" 2>/dev/null
    else
        if [ "$COLLECTION_MODE" == "full" ]; then
             echo "Папка workspaces не создана"
        else
             echo "ПРОПУЩЕНО (Режим Light)"
        fi
    fi

    echo ""
    echo "===================================================="
    echo "7. JAVA"
    echo "===================================================="

    if [ -f "$JAVA_REPORT" ]; then
        echo "Файл: java_report.txt"
        echo "Содержимое:"
        echo "----------------------------------------"
        cat "$JAVA_REPORT"
    else
        echo "Файл java_report.txt не создан"
    fi

    echo ""
    echo "===================================================="
    echo "Конец отчёта"
    echo "===================================================="

} > "$SUMMARY_FILE"

# ---- Список компьютеров в папке с датой ----
COMPUTERS_LIST_FILE="$BASE_PATH/computers_list.txt"

if [ ! -f "$COMPUTERS_LIST_FILE" ]; then
    {
        echo "===================================================="
        echo "       СПИСОК КОМПЬЮТЕРОВ ЗА $DATE_FOLDER"
        echo "===================================================="
        echo "Дата сбора | Время | Имя компьютера"
        echo "===================================================="
    } > "$COMPUTERS_LIST_FILE"
fi

echo "$CURRENT_DATE | $CURRENT_TIME | $COMPUTER_NAME | $COLLECTION_MODE" >> "$COMPUTERS_LIST_FILE"
# [ДОБАВЛЕНО] Лог завершения
log_msg "INFO" "Сбор данных завершен. Отчет сформирован."

# ====================================================================
#  ИТОГОВЫЙ ВЫВОД
# ====================================================================
echo ""
echo "====================================================="
echo "            СБОР ИНФОРМАЦИИ ЗАВЕРШЁН"
echo "====================================================="
echo ""
echo "Данные сохранены в:"
echo "$COMPUTER_PATH"
echo ""
echo "Структура папок:"

if [ "$COLLECTION_MODE" == "full" ]; then
    echo "$DATE_FOLDER/"
    echo "  +-- computers_list.txt"
    echo "  +-- $COMPUTER_NAME/"
    echo "      +-- ${COMPUTER_NAME}_diag.txt"
    echo "      +-- installed_versions.txt"
    echo "      +-- processes.txt"
    echo "      +-- summary_report.txt"
    echo "      +-- logs/"
    echo "      |   +-- [папка_с_самыми_свежими_логами]/"
    echo "      +-- deployment_errors/"
    echo "      |   +-- 1ce-installer-crash/ (если найдена)"
    echo "      |   +-- 1ce-installer-20*/ (самая свежая)"
    echo "      +-- workspaces/"
else
    echo "$DATE_FOLDER/"
    echo "  +-- computers_list.txt"
    echo "  +-- $COMPUTER_NAME/"
    echo "      +-- ${COMPUTER_NAME}_diag.txt"
    echo "      +-- installed_versions.txt"
    echo "      +-- summary_report.txt"
fi

echo ""
echo "Сводный отчёт: $SUMMARY_FILE"
echo "Список компьютеров за $DATE_FOLDER: $COMPUTERS_LIST_FILE"
read -p "Press enter to continue"