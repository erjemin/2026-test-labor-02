#!/bin/bash

# ==============================================================================
# Скрипт для замера скорости интернета
# ==============================================================================
# Описание:
#   Скрипт выполняет серию последовательных HTTP-запросов к указанному URL,
#   замеряет время выполнения и объём скачанных данных, затем вычисляет
#   среднюю скорость загрузки в МБ/с (мегабайтах в секунду)
#
# Использование:
#   ./speed_test.sh <URL>
#
# Пример:
#   ./speed_test.sh https://example.com/large_image.jpg
# ==============================================================================

# Значения по умолчанию
NUM_REQUESTS=10
URL=""
QUIET_MODE=false
ALLOW_COMPRESSION=false
USE_COLOR=true

# ANSI цветовые коды
# Используем их только если цвета включены
COLOR_RESET='\033[0m'
COLOR_BOLD='\033[1m'
COLOR_RED='\033[0;31m'
COLOR_GREEN='\033[0;32m'
COLOR_YELLOW='\033[0;33m'
COLOR_BLUE='\033[0;34m'
COLOR_MAGENTA='\033[0;35m'
COLOR_CYAN='\033[0;36m'
COLOR_WHITE='\033[1;37m'

# Функция для применения цвета (только если цвета включены)
colorize() {
    local color="$1"
    local text="$2"
    if [ "$USE_COLOR" = true ]; then
        echo -e "${color}${text}${COLOR_RESET}"
    else
        echo "$text"
    fi
}

# Функция для вывода без новой строки с цветом
colorize_n() {
    local color="$1"
    local text="$2"
    if [ "$USE_COLOR" = true ]; then
        echo -ne "${color}${text}${COLOR_RESET}"
    else
        echo -n "$text"
    fi
}

# Функция для вывода справки
show_help() {
    echo "Использование: $0 [ОПЦИИ] <URL>"
    echo ""
    echo "Опции:"
    echo "  -n, --count NUM     Количество запросов (по умолчанию: 10)"
    echo "  -q, --quiet         Тихий режим: выводит только скорость в МБ/с"
    echo "  -g, --gzip          Разрешить HTTP-сжатие (gzip/deflate)"
    echo "  -c, --no-color      Отключить цветной вывод"
    echo "  -h, --help          Показать эту справку"
    echo ""
    echo "Режимы измерения:"
    echo "  По умолчанию (без -g):"
    echo "    Измеряет РЕАЛЬНУЮ скорость интернет-канала"
    echo "    Отключает gzip-сжатие для точного замера трафика"
    echo ""
    echo "  С опцией -g:"
    echo "    Измеряет ЭФФЕКТИВНУЮ скорость передачи данных"
    echo "    Разрешает серверу использовать сжатие"
    echo "    Полезно для оценки реальной производительности при работе"
    echo ""
    echo "Примеры:"
    echo "  $0 https://speedtest.selectel.ru/100MB"
    echo "  $0 --count 5 https://speedtest.selectel.ru/10MB"
    echo "  $0 -n 1 https://example.com/image.jpg"
    echo "  $0 -q -n 3 https://speedtest.selectel.ru/10MB"
    echo "  $0 --gzip -n 5 https://example.com/large.html"
    echo ""
    echo "Тихий режим полезен для использования в других скриптах:"
    echo "  speed=\$($0 -q -n 5 https://speedtest.selectel.ru/10MB)"
    echo "  echo \"Скорость: \${speed} МБ/с\""
    exit 0
}

# Парсинг аргументов командной строки
while [[ $# -gt 0 ]]; do
    case $1 in
        -n|--count)
            # Проверяем, что следующий аргумент существует и является числом
            if [ -z "$2" ] || ! [[ "$2" =~ ^[0-9]+$ ]]; then
                echo "Ошибка: опция $1 требует числовое значение"
                exit 1
            fi
            NUM_REQUESTS="$2"
            shift 2
            ;;
        -q|--quiet)
            QUIET_MODE=true
            shift
            ;;
        -g|--gzip|--allow-compression)
            ALLOW_COMPRESSION=true
            shift
            ;;
        -c|--no-color)
            USE_COLOR=false
            shift
            ;;
        -h|--help)
            show_help
            ;;
        -*)
            echo "Ошибка: неизвестная опция $1"
            echo "Используйте --help для справки"
            exit 1
            ;;
        *)
            # Это должен быть URL
            if [ -z "$URL" ]; then
                URL="$1"
            else
                echo "Ошибка: указано более одного URL"
                exit 1
            fi
            shift
            ;;
    esac
done

# Проверка наличия URL
if [ -z "$URL" ]; then
    echo "Ошибка: не указан URL для тестирования"
    echo "Использование: $0 [ОПЦИИ] <URL>"
    echo "Используйте --help для подробной справки"
    exit 1
fi

# Проверка, что количество запросов больше 0
if [ "$NUM_REQUESTS" -le 0 ]; then
    echo "Ошибка: количество запросов должно быть больше 0"
    exit 1
fi

# Переменные для накопления результатов
total_time=0           # Общее время всех запросов (в секундах)
total_size=0           # Общий объём скачанных данных (в байтах)

# Выводим заголовок только если не в тихом режиме
if [ "$QUIET_MODE" = false ]; then
    colorize "$COLOR_CYAN" "=============================================="
    colorize "$COLOR_BOLD$COLOR_WHITE" "      Замер скорости интернета"
    colorize "$COLOR_CYAN" "=============================================="
    echo "URL: $URL"
    echo "Количество запросов: $NUM_REQUESTS"
    if [ "$ALLOW_COMPRESSION" = true ]; then
        colorize "$COLOR_YELLOW" "Режим: с HTTP-сжатием (эффективная скорость)"
    else
        colorize "$COLOR_GREEN" "Режим: без сжатия (реальная скорость канала)"
    fi
    colorize "$COLOR_CYAN" "=============================================="
    echo ""
fi

# Выполняем серию последовательных запросов
for i in $(seq 1 $NUM_REQUESTS); do
    # Выводим прогресс только если не в тихом режиме
    if [ "$QUIET_MODE" = false ]; then
        colorize_n "$COLOR_BLUE" "Запрос $i/$NUM_REQUESTS... "
    fi
    
    # Используем curl для загрузки файла
    # 
    # Режим сжатия определяется флагом ALLOW_COMPRESSION:
    # 
    # БЕЗ сжатия (по умолчанию):
    #   -H "Accept-Encoding: identity" = отключаем gzip/deflate сжатие
    #   Важно! Без этого сервер может отправить сжатые данные, и мы будем
    #   измерять размер ПОСЛЕ распаковки, что исказит реальную скорость канала.
    #   Используйте этот режим для замера РЕАЛЬНОЙ скорости интернет-канала.
    #
    # С сжатием (опция --gzip):
    #   Без заголовка Accept-Encoding, curl автоматически запросит gzip
    #   Сервер может сжать данные, мы получим меньше байт по сети
    #   Но %{size_download} покажет распакованный размер
    #   Используйте этот режим для замера ЭФФЕКТИВНОЙ скорости передачи данных
    #   (полезно для веб-приложений, где сжатие обычно включено)
    #
    # -s = silent mode (без прогресс-бара)
    # -o /dev/null = не сохраняем файл, отправляем в никуда
    # -w = форматированный вывод статистики
    # %{time_total} = общее время запроса в секундах
    # %{size_download} = размер скачанных данных в байтах
    
    # Формируем команду curl в зависимости от режима
    if [ "$ALLOW_COMPRESSION" = true ]; then
        # Разрешаем сжатие (curl автоматически добавит Accept-Encoding: gzip, deflate)
        output=$(curl -s -o /dev/null -w "%{time_total} %{size_download}" "$URL" 2>&1)
    else
        # Отключаем сжатие для точного замера сетевого трафика
        output=$(curl -H "Accept-Encoding: identity" -s -o /dev/null -w "%{time_total} %{size_download}" "$URL" 2>&1)
    fi
    
    # Проверяем код возврата curl
    if [ $? -ne 0 ]; then
        if [ "$QUIET_MODE" = false ]; then
            colorize "$COLOR_RED" " ОШИБКА! Не удалось выполнить запрос"
            echo "Возможные причины:"
            echo "  - Неверный URL"
            echo "  - Нет подключения к интернету"
            echo "  - Сервер недоступен"
        fi
        exit 1
    fi
    
    # Извлекаем время и размер из вывода curl
    request_time=$(echo "$output" | awk '{print $1}')
    request_size=$(echo "$output" | awk '{print $2}')
    
    # Проверяем, что получили корректные числа
    if [ -z "$request_time" ] || [ -z "$request_size" ]; then
        if [ "$QUIET_MODE" = false ]; then
            colorize "$COLOR_RED" " ОШИБКА! Не удалось получить данные о запросе"
        fi
        exit 1
    fi
    
    # Накапливаем общее время и размер
    total_time=$(echo "$total_time + $request_time" | bc)
    total_size=$(echo "$total_size + $request_size" | bc)
    
    # Вычисляем скорость для текущего запроса в МБ/с (только если нужен вывод)
    if [ "$QUIET_MODE" = false ]; then
        # Размер в байтах / 1048576 = размер в мегабайтах (1 МБ = 1024*1024 байт)
        # Скорость = размер_в_МБ / время_в_секундах
        speed=$(echo "scale=2; ($request_size / 1048576) / $request_time" | bc)
        size_mb=$(echo "scale=2; $request_size / 1048576" | bc)
        colorize "$COLOR_GREEN" "✓ OK (${request_time}s, ${size_mb} МБ, ${speed} МБ/с)"
    fi
done

# Выводим итоговую статистику только если не в тихом режиме
if [ "$QUIET_MODE" = false ]; then
    echo ""
    colorize "$COLOR_CYAN" "=============================================="
    colorize "$COLOR_BOLD$COLOR_WHITE" "         Результаты измерения"
    colorize "$COLOR_CYAN" "=============================================="
fi

# Вычисляем средние значения
avg_time=$(echo "scale=4; $total_time / $NUM_REQUESTS" | bc)
total_size_mb=$(echo "scale=2; $total_size / 1048576" | bc)
avg_size_mb=$(echo "scale=2; $total_size_mb / $NUM_REQUESTS" | bc)

# Вычисляем среднюю скорость
# Способ 1: общий объём / общее время (более точный для последовательных запросов)
avg_speed=$(echo "scale=2; $total_size_mb / $total_time" | bc)

# В тихом режиме выводим только скорость
if [ "$QUIET_MODE" = true ]; then
    echo "$avg_speed"
else
    echo "Выполнено запросов: $NUM_REQUESTS"
    echo "Общее время: ${total_time} сек"
    echo "Среднее время запроса: ${avg_time} сек"
    echo "Общий объём данных: ${total_size_mb} МБ"
    echo "Средний объём на запрос: ${avg_size_mb} МБ"
    echo ""
    colorize "$COLOR_MAGENTA" "=============================================="
    colorize "$COLOR_BOLD$COLOR_YELLOW" " СРЕДНЯЯ СКОРОСТЬ: ${avg_speed} МБ/с"
    colorize "$COLOR_MAGENTA" "=============================================="
    echo ""
fi
