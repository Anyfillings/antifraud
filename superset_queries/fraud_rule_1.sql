-- счета и клиенты в топ 1% по сумме транзакций из ATM
WITH atm AS (
  SELECT
    t.account_id,
    a.client_id,
    t.amount,
    t.currency,
    t.created_at,
    t.transaction_id
  FROM antifraud.transactions t
  INNER JOIN antifraud.accounts a ON a.account_id = t.account_id
  WHERE t.merchant = 'ATM'
),
p AS (
  SELECT quantileExact(0.99)(amount) AS p99
  FROM atm
)
SELECT
  account_id,
  client_id,
  transaction_id,
  created_at,
  amount,
  currency,
  p.p99 AS atm_p99
FROM atm
CROSS JOIN p
WHERE amount >= p.p99
ORDER BY amount DESC, created_at DESC
LIMIT 500;
