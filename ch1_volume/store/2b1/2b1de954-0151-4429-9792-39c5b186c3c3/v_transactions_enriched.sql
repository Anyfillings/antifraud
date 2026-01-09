ATTACH VIEW _ UUID '9170d8ca-025d-4246-971a-cb64845f3b03'
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
    `ingested_at` DateTime64(3, 'UTC'),
    `source` LowCardinality(String),
    `client_id` UInt64
)
AS SELECT
    t.*,
    a.client_id
FROM antifraud.transactions AS t
LEFT JOIN antifraud.accounts AS a ON a.account_id = t.account_id
