ATTACH TABLE _ UUID '9bddafba-9459-4aa1-ae8a-7923ed729006'
(
    `id` UInt32,
    `code` LowCardinality(String),
    `title` String,
    `description` String,
    `threshold` Nullable(Float64),
    `enabled` UInt8,
    `severity` LowCardinality(String),
    `created_at` DateTime64(3, 'UTC') DEFAULT now64(3)
)
ENGINE = MergeTree
ORDER BY (id, code)
SETTINGS index_granularity = 8192
