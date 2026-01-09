/* =========================================
   DB (можешь оставить default, но отдельная удобнее)
   ========================================= */
CREATE DATABASE IF NOT EXISTS antifraud;

/* =========================================
   1) Clients (CSV source)
   CSV: client_id,first_name,last_name,birth_date,country,created_at
   ========================================= */
CREATE TABLE IF NOT EXISTS antifraud.clients
(
    client_id   UInt64,
    first_name  String,
    last_name   String,
    birth_date  Date,
    country     LowCardinality(String),
    created_at  DateTime64(3, 'UTC'),

    ingested_at DateTime64(3, 'UTC') DEFAULT now64(3)
)
ENGINE = MergeTree
ORDER BY (client_id);


/* =========================================
   2) Accounts (CSV source)
   CSV: account_id,client_id,iban,currency,opened_at,status
   ========================================= */
CREATE TABLE IF NOT EXISTS antifraud.accounts
(
    account_id  UInt64,
    client_id   UInt64,                  -- FK-логика: accounts.client_id -> clients.client_id (не enforced)
    iban        String,
    currency    LowCardinality(String),  -- 'RUB'/'USD'/'EUR'
    opened_at   DateTime64(3, 'UTC'),
    status      LowCardinality(String),  -- e.g. 'ACTIVE'/'CLOSED'/...

    ingested_at DateTime64(3, 'UTC') DEFAULT now64(3)
)
ENGINE = MergeTree
ORDER BY (account_id, client_id);

/* =========================================
   3) Transactions (Kafka source)
   - основная “факт” таблица
   ========================================= */
CREATE TABLE IF NOT EXISTS antifraud.transactions
(
    id             UInt64,                      -- внутренний суррогатный ключ (можно генерить снаружи)
    transaction_id String,                      -- UUID/ид из внешней системы
    created_at     DateTime64(3, 'UTC'),        -- время операции как пришло
    account_id     UInt64,                      -- FK-логика: -> accounts.account_id
    amount         Decimal(18, 2),
    currency       LowCardinality(String),      -- 'RUB'/'USD'/'EUR'
    merchant       String,
    country        FixedString(2),              -- ISO2: 'RU','US',...
    status         LowCardinality(String),      -- 'APPROVED'/'PENDING'/'DECLINED'
    payload        String,                      -- сырой JSON/blob (как в ТЗ)
    ingested_at    DateTime64(3, 'UTC') DEFAULT now64(3),
    source         LowCardinality(String)       -- 'kafka'/'http'/'csv'
)
ENGINE = MergeTree
PARTITION BY toYYYYMM(created_at)
ORDER BY (created_at, account_id, transaction_id)
SETTINGS index_granularity = 8192;

/* Полезные пропуски под аналитику (опционально, но обычно стоит сделать сразу) */
CREATE INDEX IF NOT EXISTS idx_transactions_account
ON antifraud.transactions (account_id)
TYPE minmax GRANULARITY 4;

CREATE INDEX IF NOT EXISTS idx_transactions_status
ON antifraud.transactions (status)
TYPE set(100) GRANULARITY 4;

CREATE INDEX IF NOT EXISTS idx_transactions_country
ON antifraud.transactions (country)
TYPE set(300) GRANULARITY 4;
