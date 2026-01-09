-- счета и клиенты в топ 1% по частоте транзакций каждого мерчанда
WITH acc_merchant AS (
  SELECT
    t.merchant,
    t.account_id,
    any(a.client_id) AS client_id,
    count() AS tx_cnt
  FROM antifraud.transactions t
  INNER JOIN antifraud.accounts a ON a.account_id = t.account_id
  GROUP BY
    t.merchant,
    t.account_id
),
p99 AS (
  SELECT
    merchant,
    quantileExact(0.99)(tx_cnt) AS p99_cnt
  FROM acc_merchant
  GROUP BY merchant
)
SELECT
  am.merchant,
  am.account_id,
  am.client_id,
  am.tx_cnt,
  p.p99_cnt
FROM acc_merchant am
INNER JOIN p99 p USING (merchant)
WHERE am.tx_cnt >= p.p99_cnt
ORDER BY am.merchant, am.tx_cnt DESC, am.account_id
LIMIT 1000;