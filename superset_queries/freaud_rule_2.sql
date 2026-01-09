-- счета и клиенты, которые только выводят деньги из ATM
WITH per_acc AS (
  SELECT
    t.account_id,
    any(a.client_id) AS client_id,
    countIf(t.merchant = 'ATM') AS atm_cnt,
    countIf(t.merchant != 'ATM') AS non_atm_cnt,
    count() AS total_cnt
  FROM antifraud.transactions t
  INNER JOIN antifraud.accounts a ON a.account_id = t.account_id
  GROUP BY t.account_id
)
SELECT
  account_id,
  client_id,
  total_cnt AS tx_total,
  atm_cnt AS tx_atm
FROM per_acc
WHERE total_cnt > 0
  AND atm_cnt > 0
  AND non_atm_cnt = 0
ORDER BY tx_total DESC
LIMIT 500;