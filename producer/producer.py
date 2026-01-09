import json
import os
import random
import time
from datetime import datetime, timezone

import clickhouse_connect
from kafka import KafkaProducer


KAFKA_BOOTSTRAP = os.getenv("KAFKA_BOOTSTRAP", "kafka:9092")
KAFKA_TOPIC = os.getenv("KAFKA_TOPIC", "transactions")

CH_HOST = os.getenv("CH_HOST", "ch1")
CH_PORT = int(os.getenv("CH_PORT", "8123"))
CH_USER = os.getenv("CH_USER", "default")
CH_PASSWORD = os.getenv("CH_PASSWORD", "")
CH_DB = os.getenv("CH_DB", "default")

TOTAL = int(os.getenv("TOTAL_RECORDS", "200000"))
BATCH = int(os.getenv("BATCH_SIZE", "10000"))
SLEEP_SEC = float(os.getenv("SLEEP_SEC", "3"))

random.seed(42)

MCC = ["5411", "5812", "5912", "4111", "6011", "5732", "5999", "4121"]
MERCHANTS = ["COFFEE_BAR", "SUPERMARKET", "PHARMACY", "TAXI", "ATM", "ELECTRONICS", "MISC"]


def now_dt_str():
    # ClickHouse DateTime нормально парсит "YYYY-MM-DD HH:MM:SS"
    return datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S")


def main():
    # 1) Забираем существующие счета из ClickHouse
    ch = clickhouse_connect.get_client(
        host=CH_HOST,
        port=CH_PORT,
        username=CH_USER,
        password=CH_PASSWORD,
        database=CH_DB,
    )

    rows = ch.query("SELECT account_id, client_id, currency FROM accounts").result_rows
    if not rows:
        raise RuntimeError("accounts table is empty: cannot generate transactions")

    accounts = [{"account_id": r[0], "client_id": r[1], "currency": r[2]} for r in rows]

    # 2) Поднимаем Kafka producer
    producer = KafkaProducer(
        bootstrap_servers=KAFKA_BOOTSTRAP,
        acks=1,
        linger_ms=50,
        batch_size=1024 * 256,
        value_serializer=lambda v: json.dumps(v, ensure_ascii=False).encode("utf-8"),
    )

    tx_id = 1
    sent = 0

    print(f"Loaded accounts: {len(accounts)}")
    print(f"Producing to {KAFKA_TOPIC} @ {KAFKA_BOOTSTRAP}")
    print(f"Plan: total={TOTAL}, batch={BATCH}, every {SLEEP_SEC}s")

    while sent < TOTAL:
        n = min(BATCH, TOTAL - sent)

        for _ in range(n):
            acc = random.choice(accounts)
            direction = "OUT" if random.random() < 0.7 else "IN"

            # amount: OUT чаще положительное (списание), IN тоже положительное (поступление)
            amount = round(random.uniform(10, 5000), 2)

            msg = {
                "transaction_id": tx_id,
                "account_id": int(acc["account_id"]),
                "client_id": int(acc["client_id"]),
                "ts": now_dt_str(),
                "amount": float(amount),
                "currency": acc["currency"],
                "direction": direction,
                "mcc": random.choice(MCC),
                "merchant": random.choice(MERCHANTS),
            }

            producer.send(KAFKA_TOPIC, msg)
            tx_id += 1

        producer.flush()
        sent += n
        print(f"Sent {sent}/{TOTAL}")

        if sent < TOTAL:
            time.sleep(SLEEP_SEC)

    producer.flush()
    producer.close()
    print("Done. Producer stopped.")


if __name__ == "__main__":
    main()
