# =========================
# Config (можно переопределять)
# =========================
CH_CONTAINER ?= ch1
CH_DB        ?= antifraud

# ВАЖНО: по умолчанию работаем под default, чтобы schema могла накатиться даже без antifraud user
CH_USER      ?= default
CH_PASS      ?= clickhouse

KAFKA_CONTAINER ?= kafka
KAFKA_BOOTSTRAP ?= kafka:9092
KAFKA_TOPIC     ?= transactions
KAFKA_PARTS     ?= 3

CSV_DIR     ?= scripts
CLIENTS_CSV ?= $(CSV_DIR)/clients.csv
ACCOUNTS_CSV?= $(CSV_DIR)/accounts.csv

# =========================
# Compose
# =========================
.PHONY: up down reset logs

up:
	docker compose up -d

down:
	docker compose down

reset:
	docker compose down
	rm -rf ./ch1_volume

logs:
	docker compose logs -f

# =========================
# ClickHouse helpers
# =========================
.PHONY: ping ch
ping:
	curl -sS "http://localhost:8123/?user=$(CH_USER)&password=$(CH_PASS)&query=SELECT%201" ; echo

# =========================
# Schema
# =========================
.PHONY: schema
schema:
	@echo "📐 Применяю schema в БД $(CH_DB)..."
	docker exec -i $(CH_CONTAINER) clickhouse-client --user $(CH_USER) --password "$(CH_PASS)" --multiquery < sql/schema.antifraud.sql
	@echo "✅ schema применена"

# =========================
# CSV
# =========================
.PHONY: gencsv loadcsv
gencsv:
	@echo "🧪 Генерирую CSV..."
	python3 scripts/gen_csv.py
	@echo "✅ CSV готовы: $(CLIENTS_CSV), $(ACCOUNTS_CSV)"

loadcsv:
	@echo "🐳 🔕 Загружаю CSV данные в ClickHouse ($(CH_DB))..."
	docker exec -i $(CH_CONTAINER) clickhouse-client --user $(CH_USER) --password "$(CH_PASS)" --query \
	"TRUNCATE TABLE $(CH_DB).clients"
	docker exec -i $(CH_CONTAINER) clickhouse-client --user $(CH_USER) --password "$(CH_PASS)" --query \
	"INSERT INTO $(CH_DB).clients FORMAT CSVWithNames" < $(CLIENTS_CSV)

	docker exec -i $(CH_CONTAINER) clickhouse-client --user $(CH_USER) --password "$(CH_PASS)" --query \
	"TRUNCATE TABLE $(CH_DB).accounts"
	docker exec -i $(CH_CONTAINER) clickhouse-client --user $(CH_USER) --password "$(CH_PASS)" --query \
	"INSERT INTO $(CH_DB).accounts FORMAT CSVWithNames" < $(ACCOUNTS_CSV)
	@echo "✅ Всё ОК"

# =========================
# Kafka + streaming ingest
# =========================
.PHONY: kafka-topic ingest-ddl producer-restart stream-up

kafka-topic:
	@echo "🧩 Создаю топик Kafka $(KAFKA_TOPIC)..."
	docker exec -it $(KAFKA_CONTAINER) kafka-topics --bootstrap-server $(KAFKA_BOOTSTRAP) \
		--create --if-not-exists --topic $(KAFKA_TOPIC) --partitions $(KAFKA_PARTS) --replication-factor 1
	@echo "✅ Topic OK"

ingest-ddl:
	@echo "🧱 Создаю Kafka ingest таблицы в ClickHouse ($(CH_DB))..."
	docker exec -i $(CH_CONTAINER) clickhouse-client --user $(CH_USER) --password "$(CH_PASS)" --multiquery < sql/transactions_kafka_ingest.sql
	@echo "✅ DDL OK"

producer-restart:
	@echo "🔁 Перезапускаю producer..."
	# пересоздаём, чтобы точно применились свежие build/env
	docker compose up -d --build --force-recreate producer
	@echo "✅ producer перезапущен"

stream-up: kafka-topic ingest-ddl producer-restart
	@echo "🚀 Запускаю стриминг (kafka + ch1 + producer)..."
	docker compose up -d kafka ch1
	@echo "✅ Запущено"

# =========================
# Convenience: "всё сразу"
# =========================
.PHONY: bootstrap
bootstrap: up schema gencsv loadcsv stream-up
	@echo "🎉 Готово: schema + csv + kafka + producer + ingest"
