ATTACH TABLE _ UUID '1f1a0b5d-9936-496d-8a38-e0f77dcd9c93'
(
    `client_id` UInt64,
    `first_name` String,
    `last_name` String,
    `birth_date` Date,
    `country` LowCardinality(String),
    `created_at` DateTime64(3, 'UTC'),
    `ingested_at` DateTime64(3, 'UTC') DEFAULT now64(3)
)
ENGINE = MergeTree
ORDER BY client_id
SETTINGS index_granularity = 8192
