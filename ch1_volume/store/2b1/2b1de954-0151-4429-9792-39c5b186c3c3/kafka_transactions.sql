ATTACH TABLE _ UUID 'e66580d2-fb57-4861-bb64-5fbb09351040'
(
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
ENGINE = Kafka
SETTINGS kafka_broker_list = 'kafka:9092', kafka_topic_list = 'transactions', kafka_group_name = 'ch_transactions_consumer', kafka_format = 'JSONEachRow', kafka_num_consumers = 2, kafka_max_block_size = 10000
