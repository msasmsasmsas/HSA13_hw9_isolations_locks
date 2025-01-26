-- Рівні ізоляції, де можлива проблема:
--    READ UNCOMMITTED
--    READ COMMITTED


-- LOST UPDATE
-- step2 sesshion2
SHOW ENGINE INNODB STATUS;
SET autocommit = 0;
SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
-- SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
START TRANSACTION  WITH CONSISTENT SNAPSHOT;
SELECT balance FROM accounts WHERE id = 1  FOR UPDATE;
-- Output: 1000
UPDATE accounts SET balance = balance - 200 WHERE id = 1;

SELECT balance FROM accounts WHERE id = 1;
COMMIT;



-- dirty read
-- Step 2 sesshion2
SET autocommit = 0;
SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;
START TRANSACTION;
SELECT balance FROM accounts WHERE id = 1;
-- balance
--'2000'

-- Output: 2000 (некоректне значення)
COMMIT;



-- NON-REPEATABLE READ
-- Step 2 sesshion2

SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SET GLOBAL TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SELECT @@global.transaction_isolation, @@session.transaction_isolation;
-- SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;
UPDATE accounts SET balance = balance + 500 WHERE id = 1;
-- 15:29:19	UPDATE accounts SET balance = balance + 500 WHERE id = 1	1 row(s) affected Rows matched: 1  Changed: 1  Warnings: 0	0.000 sec

COMMIT;



-- PHANTOM READ

--  Step 2 sesshion2
SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SET autocommit = 0;
START TRANSACTION;

INSERT INTO accounts (name, balance) VALUES ('Charlie', 2000);
COMMIT;
