
## 1. Общее описание проекта

Данный проект — учебный прототип антифрод-системы, реализованный в рамках дисциплины **АСОБД**.
Цель проекта — продемонстрировать минимальный end-to-end pipeline обработки данных:

- загрузка справочных данных из CSV;
- потоковая генерация транзакций;
- ingestion через Kafka;
- аналитическое хранение в ClickHouse;
- визуализация и аналитика в Superset.

Архитектура проекта (логическая схема компонентов и потоков данных):
https://board.vk.com/?utm_campaign=board.vk.company&utm_content=&utm_medium=login_header&utm_source=board.vk.company&utm_term=&uid=1753c4c5-43ee-4903-b550-50092d2f430d

### Используемые компоненты
- ClickHouse — аналитическое хранилище
- Kafka — транспорт событий (transactions)
- Python producer — генерация транзакций
- Apache Superset — аналитический UI
- Docker Compose — оркестрация окружения

---

## 2. Правила запуска проекта

### 2.1 Запуск инфраструктуры

```bash
make up
```

Поднимаются контейнеры:
- ClickHouse (`ch1`)
- Kafka
- Zookeeper
- Superset

Контейнер `producer` на этом этапе может завершиться с ошибкой — это ожидаемое поведение,
так как Kafka-топики и Kafka-ingest таблицы в ClickHouse ещё не созданы.

---

### 2.2 Пароль для ClickHouse

В проекте используется пользователь `default` с паролем:

```
login: default
password: clickhouse
```

HTTP endpoint ClickHouse:

```
http://localhost:8123
```

---

### 2.3 Создание схемы данных

```bash
make schema
```

Команда создаёт схему `antifraud` и таблицы:
- clients
- accounts
- transactions
- Kafka ingest таблицы и materialized view

---

### 2.4 Генерация и загрузка CSV

```bash
make gencsv
make loadcsv
```

- `gencsv` — генерация синтетических данных клиентов и счетов
- `loadcsv` — загрузка CSV в ClickHouse

После выполнения данные доступны в таблицах:
- antifraud.clients
- antifraud.accounts

---

### 2.5 Запуск стриминга (Kafka → ClickHouse)

```bash
make stream-up
```

В рамках этой команды:
1. Создаётся Kafka topic `transactions`
2. Создаются Kafka ingest таблицы в ClickHouse
3. Контейнер `producer` пересоздаётся и запускается повторно

Producer:
- читает существующие accounts из ClickHouse;
- генерирует поток транзакций;
- пишет события в Kafka;
- данные автоматически попадают в antifraud.transactions.

---

### 2.6 Создание администратора Superset

```bash
docker exec -it superset superset fab create-admin   --username admin   --firstname admin   --lastname admin   --email admin@local   --password admin

docker exec -it superset superset db upgrade
docker exec -it superset superset init
```

Доступ к Superset:

```
URL: http://localhost:8088
login: admin
password: admin
```

---

### 2.7 Подключение ClickHouse в Superset

SQLAlchemy URI:

```
clickhousedb://default:clickhouse@ch1:8123/antifraud
```

---

## 3. Соответствие требованиям проекта

| Критерий | Баллы | Статус | Комментарий |
|---------|-------|--------|-------------|
| Проект запускается | 3 | ✅ | make up, make stream-up |
| Соответствие бизнес-требованиям | 5 | ✅ | Реализован end-to-end pipeline |
| Отказоустойчивость | 2 | ⚠️ | Producer перезапускается вручную |
| Мониторинг | 3 | ❌ | Не реализован |
| README по шаблону | 3 | ✅ | Данный файл |
| Покрытие тестами ≥ 60% | 2 | ❌ | Не реализовано |
| Postman запросы | 2 | ❌ | Не реализовано |
| Чистый код | 2 | ✅ | Код читаем и минимален |
| Защита проекта | 3 | ✅ | Проект демонстрируем |

---

## 4. Что реализовано и что нет

### Реализовано
- Docker-based окружение
- CSV → ClickHouse загрузка
- Kafka streaming ingestion
- Антифрод SQL-правила
- Superset визуализация

### Не реализовано (осознанно)
- Unit / integration тесты
- Monitoring / alerting
- REST API / Postman
- Production hardening

---

## 5. Итог

Проект представляет собой минимальный, но полностью рабочий учебный антифрод-прототип.
Фокус сделан на архитектуре, потоковой обработке и аналитике.

