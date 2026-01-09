#!/usr/bin/env python3
import csv
import os
import random
from datetime import datetime, timedelta, date

OUT_DIR = "scripts"
CLIENTS_FILE = os.path.join(OUT_DIR, "clients.csv")
ACCOUNTS_FILE = os.path.join(OUT_DIR, "accounts.csv")

random.seed(42)

FIRST_NAMES = ["Andrei", "Ivan", "Petr", "Anna", "Olga", "Maria", "Dmitry", "Sergey", "Elena", "Nikita"]
LAST_NAMES = ["Ivanov", "Petrov", "Sidorov", "Smirnov", "Volkova", "Kuznetsova", "Popov", "Sokolov", "Lebedev", "Morozova"]
COUNTRIES = ["RU", "KZ", "AM", "BY", "GE"]
CURRENCIES = ["RUB", "USD", "EUR"]
STATUSES = ["active", "blocked", "closed"]

def rand_date(start: date, end: date) -> date:
    delta = (end - start).days
    return start + timedelta(days=random.randint(0, delta))

def rand_dt(start: datetime, end: datetime) -> datetime:
    delta = int((end - start).total_seconds())
    return start + timedelta(seconds=random.randint(0, delta))

def gen_iban(account_id: int) -> str:
    # Упрощённый "псевдо-IBAN" (строка). Для ClickHouse это просто String.
    return f"RU{account_id:02d}{random.randint(10**18, 10**19 - 1)}"

def ensure_dir(path: str) -> None:
    os.makedirs(path, exist_ok=True)

def main():
    ensure_dir(OUT_DIR)

    # Параметры генерации
    n_clients = 2000
    min_accounts_per_client = 1
    max_accounts_per_client = 3

    today = date.today()
    now = datetime.now()

    # CLIENTS
    clients = []
    for client_id in range(1, n_clients + 1):
        first_name = random.choice(FIRST_NAMES)
        last_name = random.choice(LAST_NAMES)
        birth_date = rand_date(date(1960, 1, 1), date(2005, 12, 31))
        country = random.choice(COUNTRIES)
        created_at = rand_dt(datetime(2022, 1, 1), now)

        clients.append({
            "client_id": client_id,
            "first_name": first_name,
            "last_name": last_name,
            "birth_date": birth_date.isoformat(),
            "country": country,
            "created_at": created_at.strftime("%Y-%m-%d %H:%M:%S"),
        })

    with open(CLIENTS_FILE, "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(
            f,
            fieldnames=["client_id", "first_name", "last_name", "birth_date", "country", "created_at"],
        )
        w.writeheader()
        w.writerows(clients)

    # ACCOUNTS (FK на client_id)
    accounts = []
    account_id = 1
    for c in clients:
        k = random.randint(min_accounts_per_client, max_accounts_per_client)
        for _ in range(k):
            opened_at = rand_dt(datetime(2022, 1, 1), now)
            status = random.choices(STATUSES, weights=[0.90, 0.07, 0.03], k=1)[0]
            currency = random.choice(CURRENCIES)

            accounts.append({
                "account_id": account_id,
                "client_id": c["client_id"],
                "iban": gen_iban(account_id),
                "currency": currency,
                "opened_at": opened_at.strftime("%Y-%m-%d %H:%M:%S"),
                "status": status,
            })
            account_id += 1

    with open(ACCOUNTS_FILE, "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(
            f,
            fieldnames=["account_id", "client_id", "iban", "currency", "opened_at", "status"],
        )
        w.writeheader()
        w.writerows(accounts)

    print(f"OK: {CLIENTS_FILE} ({len(clients)} rows)")
    print(f"OK: {ACCOUNTS_FILE} ({len(accounts)} rows)")

if __name__ == "__main__":
    main()
