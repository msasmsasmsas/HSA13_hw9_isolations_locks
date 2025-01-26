-- Рівні ізоляції, де можлива проблема:
--    READ UNCOMMITTED
--    READ COMMITTED
--    REPEATABLE READ
SET autocommit = 0;
SHOW VARIABLES LIKE 'autocommit';
-- Variable_name, Value
-- 'autocommit', 'OFF'

SHOW VARIABLES LIKE 'innodb_flush_log_at_trx_commit';
-- Variable_name, Value
-- 'innodb_flush_log_at_trx_commit', '2'

SHOW VARIABLES LIKE 'tx_isolation';
--Variable_name

SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
START TRANSACTION;

UPDATE accounts SET balance = 1000 WHERE id = 1;
commit;
START TRANSACTION;
SELECT balance FROM accounts WHERE id = 1;
commit;
-- balance
--'1000'



-- LOST UPDATE
-- Step 1 sesshion1
-- step1
SET TRANSACTION ISOLATION LEVEL  REPEATABLE READ;
SET GLOBAL TRANSACTION ISOLATION LEVEL REPEATABLE READ;
-- SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
-- SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;

SELECT @@global.transaction_isolation, @@session.transaction_isolation;
START TRANSACTION  WITH CONSISTENT SNAPSHOT;
-- SELECT balance FROM accounts WHERE id = 1;
-- Output: 1000

UPDATE accounts SET balance = balance + 500 WHERE id = 1;

SELECT balance FROM accounts WHERE id = 1;
-- Затримка перед комітом

-- 00:10:23	UPDATE accounts SET balance = balance + 500 WHERE id = 1	1 row(s) affected Rows matched: 1  Changed: 1  Warnings: 0	0.000 sec

SHOW ENGINE INNODB STATUS;
-- step3
COMMIT;
SELECT balance FROM accounts WHERE id = 1;
rollback
-- solution

-- options1
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE

-- options2
SET SQL_SAFE_UPDATES = 0;
START TRANSACTION;

SELECT balance FROM accounts WHERE name = 'Alice' FOR UPDATE;
UPDATE accounts SET balance = balance + 500 WHERE name = 'Alice';
COMMIT;
SET SQL_SAFE_UPDATES = 1;

UPDATE accounts SET balance = 1000 WHERE id =1;




-- dirty read
-- Step 1 sesshion1
SET autocommit = 0;
SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
START TRANSACTION;
UPDATE accounts SET balance = balance + 1000 WHERE id = 1;
-- 15:10:44	UPDATE accounts SET balance = balance + 1000 WHERE id = 1	1 row(s) affected Rows matched: 1  Changed: 1  Warnings: 0	0.000 sec

-- Step 3 sesshion1

ROLLBACK;
-- 15:12:23	ROLLBACK	0 row(s) affected	0.000 sec






-- NON-REPEATABLE READ

-- Step 1 sesshion1
SET autocommit = 0;
SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SET GLOBAL TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SELECT @@global.transaction_isolation, @@session.transaction_isolation;
-- 15:28:17	SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ	0 row(s) affected	0.000 sec

START TRANSACTION;
-- 15:28:17	START TRANSACTION	0 row(s) affected	0.000 sec

SELECT balance FROM accounts WHERE id = 1;
-- 15:28:17	SELECT balance FROM accounts WHERE id = 1 LIMIT 0, 100000	1 row(s) returned	0.000 sec / 0.000 sec

-- Output: 1000
SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SET GLOBAL TRANSACTION ISOLATION LEVEL REPEATABLE READ;

SELECT @@global.transaction_isolation, @@session.transaction_isolation;
START TRANSACTION  WITH CONSISTENT SNAPSHOT;
SELECT balance FROM accounts WHERE id = 1;
-- balance
-- '1000'

-- Output: 1500 (неповторюване читання)
COMMIT;




-- PHANTOM READ
-- Step 1 sesshion1
SET SESSION autocommit = 0;
SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SET GLOBAL TRANSACTION ISOLATION LEVEL REPEATABLE READ;

SELECT @@global.transaction_isolation, @@session.transaction_isolation;
START TRANSACTION;
SELECT COUNT(*) FROM accounts;
-- Очікуваний результат: 2

 -- Step 3 sesshion1


SELECT COUNT(*) FROM accounts;
-- COUNT(*)
--'2'


COMMIT;

