ATTACH TABLE _ UUID '6cf2a182-0213-4c07-969d-45874ded60a0'
(
    `id` UInt64,
    `transaction_id` String,
    `created_at` DateTime64(3, 'UTC'),
    `account_id` UInt64,
    `amount` Decimal(18, 2),
    `currency` LowCardinality(String),
    `merchant` String,
    `country` FixedString(2),
    `status` LowCardinality(String),
    `payload` String,
    `ingested_at` DateTime64(3, 'UTC') DEFAULT now64(3),
    `source` LowCardinality(String),
    INDEX idx_transactions_account account_id TYPE minmax GRANULARITY 4,
    INDEX idx_transactions_status status TYPE set(100) GRANULARITY 4,
    INDEX idx_transactions_country country TYPE set(300) GRANULARITY 4
)
ENGINE = MergeTree
PARTITION BY toYYYYMM(created_at)
ORDER BY (created_at, account_id, transaction_id)
SETTINGS index_granularity = 8192
