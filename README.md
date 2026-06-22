![Static Badge](https://img.shields.io/badge/BASH-green)
![Static Badge](https://img.shields.io/badge/ТЕСТОВОЕ-ЗАДАНИЕ-grey)
![Version](https://img.shields.io/badge/version-0.1.0-blue)
![License](https://img.shields.io/badge/license-MIT-green)
[![Static Badge](https://img.shields.io/badge/ОРИГИНАЛ-git.cube2.ru-green)](https://git.cube2.ru/erjemin/2026-test-labor-02)

# Тестовое задание от «Интерактивного агентства “Это Легко”»

На соискание должности на вакансию [Python Developer](https://hh.ru/vacancy/134258608)

## Задание

> Написать скрипт-замерятель скорости интернета со своего компьютера.
>
> Он должен принимать адрес, куда стучаться (какая-нибудь тяжелая картинка), запускать последовательно 10 запросов к этому адресу, дожидаться ответа, вычислять среднее время запроса, объем скачанных данных и печатать в консоли скорость мб/с.
> 
> Ответ залить на github и дать репозиторий с инструкциями.

## Решение на Bash

* Реализовано на чистом bash. Основной скрипт: **[speed_test.sh](bash/speed_test.sh)**
* Подробная документация: **[USAGE.md](bash/USAGE.md)**

### Использование

```bash
# Базовое использование
bash speed_test.sh -n 2 https://speedtest.selectel.ru/10MB

# Тихий режим (только число)
bash speed_test.sh -q -n 3 https://speedtest.selectel.ru/10MB

# Справка
bash speed_test.sh --help
```

### Основные возможности

- Замер скорости через N последовательных запросов (`-n N`, по умолчанию 10)
- Два режима: реальная скорость канала (по умолчанию, с защитой от искажений из-за HTTP-сжатия) или эффективная скорость с gzip (`-g`)
- Тихий режим (`-q`) для использования в других скриптах
- **Цветной вывод** для лучшей читаемости (`--no-color` для отключения)
- Подробная статистика по каждому запросу

### Требования

- `bash` (3.0+)
- `curl`
- `bc`

### Дополнительные скрипты

- `bash/compare_servers.sh` — сравнение скорости разных серверов
- `bash/compare_modes.sh` — сравнение режимов (с/без gzip)
- `bash/demo_gzip_problem.sh` — демонстрация проблемы HTTP-сжатия
