ATTACH TABLE _ UUID '131908e9-f24f-474b-b94e-19d8793dcb7f'
(
    `account_id` UInt64,
    `client_id` UInt64,
    `iban` String,
    `currency` LowCardinality(String),
    `opened_at` DateTime64(3, 'UTC'),
    `status` LowCardinality(String),
    `ingested_at` DateTime64(3, 'UTC') DEFAULT now64(3)
)
ENGINE = MergeTree
ORDER BY (account_id, client_id)
SETTINGS index_granularity = 8192
