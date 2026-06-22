#!/bin/bash

# ==============================================================================
# Пример использования speed_test.sh в тихом режиме
# Этот скрипт сравнивает скорость загрузки с разных серверов
# и находит самый быстрый
# ==============================================================================

echo "Сравнение скорости загрузки с разных серверов..."
echo ""

# Список серверов для тестирования
# Формат: "Название|URL"
servers=(
    "GitCube|https://git.cube2.ru/erjemin/2026-test-labor-02"
    "GitHub|https://github.com/erjemin/2026-test-labor-02"
)

# Переменные для отслеживания лучшего сервера
best_speed=0
best_server=""

# Тестируем каждый сервер
for server_info in "${servers[@]}"; do
    # Разделяем название и URL
    name=$(echo "$server_info" | cut -d'|' -f1)
    url=$(echo "$server_info" | cut -d'|' -f2)
    
    echo -n "Тестирую $name... "
    
    # Запускаем тест в тихом режиме с 5 запросами
    speed=$(bash speed_test.sh -q -n 5 "$url" 2>/dev/null)
    
    # Проверяем, успешно ли выполнен тест
    if [ $? -eq 0 ] && [ -n "$speed" ]; then
        echo "${speed} МБ/с"
        
        # Сравниваем со скоростью лучшего сервера
        # bc возвращает 1 если первое число больше второго
        is_better=$(echo "$speed > $best_speed" | bc -l)
        if [ "$is_better" -eq 1 ]; then
            best_speed=$speed
            best_server=$name
        fi
    else
        echo "ОШИБКА"
    fi
done

echo ""
echo "=============================================="
echo "Результат:"
if [ -n "$best_server" ]; then
    echo "Самый быстрый сервер: $best_server"
    echo "Скорость: ${best_speed} МБ/с"
else
    echo "Не удалось найти работающий сервер"
fi
echo "=============================================="
