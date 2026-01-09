ATTACH MATERIALIZED VIEW _ UUID '4a54b9e3-816c-43d0-b1c4-bbc4aebee805' TO antifraud.transactions
(
    `id` UInt64,
    `transaction_id` String,
    `created_at` DateTime64(3, 'UTC'),
    `account_id` UInt64,
    `amount` Decimal(18, 2),
    `currency` String,
    `merchant` String,
    `country` FixedString(2),
    `status` String,
    `payload` String,
    `source` String
)
AS SELECT
    toUInt64(cityHash64(transaction_id)) AS id,
    transaction_id,
    created_at,
    account_id,
    amount,
    currency,
    merchant,
    country,
    status,
    payload,
    source
FROM antifraud.kafka_transactions
