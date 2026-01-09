ATTACH TABLE _ UUID 'ff69a7b7-07fd-4ac0-8612-d7bfc67e0657'
(
    `id` UInt64,
    `transaction_id` String,
    `account_id` UInt64,
    `rule_code` LowCardinality(String),
    `severity` LowCardinality(String),
    `description` String,
    `created_at` DateTime64(3, 'UTC') DEFAULT now64(3),
    `resolved` UInt8 DEFAULT 0
)
ENGINE = MergeTree
PARTITION BY toYYYYMM(created_at)
ORDER BY (created_at, account_id, rule_code, transaction_id)
SETTINGS index_granularity = 8192
