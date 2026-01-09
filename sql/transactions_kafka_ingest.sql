DROP VIEW IF EXISTS antifraud.mv_transactions;
DROP TABLE IF EXISTS antifraud.kafka_transactions;

CREATE TABLE antifraud.kafka_transactions
(
    transaction_id String,
    created_at     DateTime64(3, 'UTC'),
    account_id     UInt64,
    amount         Decimal(18, 2),
    currency       String,
    merchant       String,
    country        FixedString(2),
    status         String,
    payload        String,
    source         String
)
ENGINE = Kafka
SETTINGS
    kafka_broker_list = 'kafka:9092',
    kafka_topic_list = 'transactions',
    kafka_group_name = 'ch_transactions_consumer',
    kafka_format = 'JSONEachRow',
    kafka_num_consumers = 2,
    kafka_max_block_size = 10000;

CREATE MATERIALIZED VIEW antifraud.mv_transactions
TO antifraud.transactions
AS
SELECT
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
FROM antifraud.kafka_transactions;
