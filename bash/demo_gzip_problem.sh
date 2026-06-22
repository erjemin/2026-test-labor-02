#!/bin/bash

# ==============================================================================
# Демонстрация проблемы с HTTP-сжатием при замере скорости
# ==============================================================================
# Этот скрипт показывает, как gzip-сжатие может исказить результаты измерения
# скорости интернет-соединения
# ==============================================================================

echo "=============================================="
echo "Демонстрация проблемы с gzip-сжатием"
echo "=============================================="
echo ""

# URL для тестирования (любой сервер, который поддерживает gzip)
# Обычно это текстовые файлы, HTML, JSON - они хорошо сжимаются
TEST_URL="https://www.wikipedia.org/"

echo "Тестируем URL: $TEST_URL"
echo ""

# Тест 1: БЕЗ отключения сжатия (по умолчанию curl запрашивает gzip)
echo "1. Запрос БЕЗ отключения gzip (curl по умолчанию):"
echo "   curl -s -o /dev/null -w '...' $TEST_URL"
echo ""

result_with_gzip=$(curl -s -o /dev/null -w "Время: %{time_total}s, Размер: %{size_download} байт" "$TEST_URL" 2>&1)
echo "   Результат: $result_with_gzip"

# Извлекаем размер
size_with_gzip=$(echo "$result_with_gzip" | grep -o 'Размер: [0-9]*' | awk '{print $2}')
echo ""

# Тест 2: С отключением сжатия (как в нашем скрипте)
echo "2. Запрос С отключением gzip (Accept-Encoding: identity):"
echo "   curl -H 'Accept-Encoding: identity' -s -o /dev/null -w '...' $TEST_URL"
echo ""

result_without_gzip=$(curl -H "Accept-Encoding: identity" -s -o /dev/null -w "Время: %{time_total}s, Размер: %{size_download} байт" "$TEST_URL" 2>&1)
echo "   Результат: $result_without_gzip"

# Извлекаем размер
size_without_gzip=$(echo "$result_without_gzip" | grep -o 'Размер: [0-9]*' | awk '{print $2}')
echo ""

echo "=============================================="
echo "Сравнение:"
echo "=============================================="

if [ -n "$size_with_gzip" ] && [ -n "$size_without_gzip" ] && [ "$size_with_gzip" -gt 0 ]; then
    # Вычисляем разницу
    diff=$((size_without_gzip - size_with_gzip))
    
    # Вычисляем коэффициент сжатия
    if [ "$size_without_gzip" -gt 0 ]; then
        ratio=$(echo "scale=2; $size_without_gzip / $size_with_gzip" | bc)
    else
        ratio="?"
    fi
    
    echo "БЕЗ отключения gzip: $size_with_gzip байт"
    echo "С отключением gzip:  $size_without_gzip байт"
    echo "Разница:             $diff байт"
    echo "Коэффициент сжатия:  ${ratio}x"
    echo ""
    
    if (( $(echo "$ratio > 1.5" | bc -l) )); then
        echo "⚠️  ВНИМАНИЕ! Сжатие значительно уменьшило размер данных!"
        echo "   Если бы мы замеряли скорость без отключения gzip,"
        echo "   результат был бы завышен примерно в ${ratio} раз!"
        echo ""
        echo "   Пример: реальная скорость 10 МБ/с,"
        echo "   но curl показал бы $(echo "scale=1; 10 * $ratio" | bc) МБ/с"
    else
        echo "ℹ️  Для этого URL сжатие минимально или отсутствует"
    fi
else
    echo "Не удалось получить корректные данные для сравнения"
fi

echo ""
echo "=============================================="
echo "Вывод:"
echo "=============================================="
echo "Наш скрипт speed_test.sh использует"
echo "  -H 'Accept-Encoding: identity'"
echo "чтобы гарантировать точные измерения"
echo "реальной скорости интернет-соединения!"
echo "=============================================="
