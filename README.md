# HSA13_hw9_isolations_locks


| Проблема              | READ UNCOMMITTED | READ COMMITTED | REPEATABLE READ | SERIALIZABLE |
|----------------------|-----------------|----------------|----------------|--------------|
| Lost Update          | ✅ Можливо       | ✅ Можливо      | ✅ Можливо      | ❌ Виключено  |
| Dirty Read           | ✅ Можливо       | ❌ Виключено    | ❌ Виключено    | ❌ Виключено  |
| Non-Repeatable Read  | ✅ Можливо       | ✅ Можливо      | ❌ Виключено    | ❌ Виключено  |
| Phantom Read         | ✅ Можливо       | ✅ Можливо      | ✅ Можливо      | ❌ Виключено  |

## create table

```SQL
USE hsa13;


CREATE TABLE accounts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50),
    balance INT
) ENGINE=InnoDB;

INSERT INTO accounts (name, balance) VALUES ('Alice', 1000), ('Bob', 1500);
12:59:06	INSERT INTO accounts (name, balance) VALUES ('Alice', 1000), ('Bob', 1500)	2 row(s) affected Records: 2  Duplicates: 0  Warnings: 0	0.016 sec
```
```SQL

SELECT * FROM accounts;
13:02:26	SELECT * FROM accounts LIMIT 0, 100000	2 row(s) returned	0.000 sec / 0.000 sec

# id, name, balance
'1', 'Alice', '1000'
'2', 'Bob', '1500'

```

## LOST UPDATE 

### Step 1 sesshion1 

```SQL

SET autocommit = 0;
SHOW VARIABLES LIKE 'autocommit';
# Variable_name, Value
# 'autocommit', 'OFF'

SHOW VARIABLES LIKE 'innodb_flush_log_at_trx_commit';
# Variable_name, Value
# 'innodb_flush_log_at_trx_commit', '2'

SHOW VARIABLES LIKE 'tx_isolation';
#Variable_name

SET GLOBAL TRANSACTION ISOLATION LEVEL REPEATABLE READ;
START TRANSACTION  WITH CONSISTENT SNAPSHOT;
-- SELECT balance FROM accounts WHERE id = 1;
-- 13:04:10	SELECT balance FROM accounts WHERE id = 1 LIMIT 0, 100000	1 row(s) returned	0.000 sec / 0.000 sec

# balance
#'1000'

UPDATE accounts SET balance = balance + 500 WHERE id = 1;
13:04:10	UPDATE accounts SET balance = balance + 500 WHERE id = 1	1 row(s) affected Rows matched: 1  Changed: 1  Warnings: 0	0.000 sec


```


### Step 2 sesshion2 

```SQL

SHOW ENGINE INNODB STATUS;
SET autocommit = 0;
SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;

START TRANSACTION  WITH CONSISTENT SNAPSHOT;
SELECT balance FROM accounts WHERE id = 1;
13:04:10	SELECT balance FROM accounts WHERE id = 1 LIMIT 0, 100000	1 row(s) returned	0.000 sec / 0.000 sec

# balance
'1000'

UPDATE accounts SET balance = balance + 500 WHERE id = 1;
13:12:47	UPDATE accounts SET balance = balance - 200 WHERE id = 1	1 row(s) affected Rows matched: 1  Changed: 1  Warnings: 0	0.000 sec

COMMIT;
13:12:47	COMMIT	0 row(s) affected	0.016 sec

SELECT balance FROM accounts WHERE id = 1;
13:15:20	SELECT balance FROM accounts WHERE id = 1 LIMIT 0, 100000	1 row(s) returned	0.000 sec / 0.000 sec

# balance
'800'


```

### Step 3 sesshion1 

```SQL


COMMIT;
13:12:47	COMMIT	0 row(s) affected	0.016 sec


SELECT balance FROM accounts WHERE id = 1;
13:15:20	SELECT balance FROM accounts WHERE id = 1 LIMIT 0, 100000	1 row(s) returned	0.000 sec / 0.000 sec

# balance
'800'


```

### solution (Lost Update)

1. SELECT balance FROM accounts WHERE id = 1 FOR UPDATE;
2. SET SESSION TRANSACTION ISOLATION LEVEL SERIALIZABLE;




## DIRTY READ

### Step 1 sesshion1
```sql
SET autocommit = 0;
SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
START TRANSACTION;
UPDATE accounts SET balance = balance + 1000 WHERE id = 1;
-- 15:10:44	UPDATE accounts SET balance = balance + 1000 WHERE id = 1	1 row(s) affected Rows matched: 1  Changed: 1  Warnings: 0	0.000 sec
```
### Step 2 sesshion2

```sql
SET autocommit = 0;
SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
START TRANSACTION;
SELECT balance FROM accounts WHERE id = 1;
# balance
#'2000'
-- Output: 2000 (некоректне значення)

COMMIT;
```

### Step 3 sesshion1

```sql
ROLLBACK;
-- 15:12:23	ROLLBACK	0 row(s) affected	0.000 sec
```

### solution (dirty read)

```sql
SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;
START TRANSACTION;
SELECT balance FROM accounts WHERE id = 1;
# balance
#'1000'
COMMIT;
```
## NON-REPEATABLE READ

### Step 1 sesshion1
```sql
SET autocommit = 0;
SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;
SET GLOBAL TRANSACTION ISOLATION LEVEL READ COMMITTED;
SELECT @@global.transaction_isolation, @@session.transaction_isolation;
-- 15:28:17	SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ	0 row(s) affected	0.000 sec

START TRANSACTION;
-- 15:28:17	START TRANSACTION	0 row(s) affected	0.000 sec
SELECT balance FROM accounts WHERE id = 1;
-- 15:28:17	SELECT balance FROM accounts WHERE id = 1 LIMIT 0, 100000	1 row(s) returned	0.000 sec / 0.000 sec
-- Output: 1000
```
### Step 2 sesshion2

```sql
SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;
SET GLOBAL TRANSACTION ISOLATION LEVEL READ COMMITTED;
SELECT @@global.transaction_isolation, @@session.transaction_isolation;

UPDATE accounts SET balance = balance + 500 WHERE id = 1;
-- 15:29:19	UPDATE accounts SET balance = balance + 500 WHERE id = 1	1 row(s) affected Rows matched: 1  Changed: 1  Warnings: 0	0.000 sec
COMMIT;
```


### Step 3 sesshion1

```sql
START TRANSACTION  WITH CONSISTENT SNAPSHOT;
SELECT balance FROM accounts WHERE id = 1;
# balance
# '1500'

-- Output: 1500 (неповторюване читання)
COMMIT;
```


## solution (non-repeatable read)



```sql
### Step 1 sesshion1
SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SET GLOBAL TRANSACTION ISOLATION LEVEL REPEATABLE READ;

SELECT @@global.transaction_isolation, @@session.transaction_isolation;
START TRANSACTION  WITH CONSISTENT SNAPSHOT;
SELECT balance FROM accounts WHERE id = 1;
# balance
# '1000'

### Step 2 sesshion2

UPDATE accounts SET balance = balance + 500 WHERE id = 1;
-- 15:29:19	UPDATE accounts SET balance = balance + 500 WHERE id = 1	1 row(s) affected Rows matched: 1  Changed: 1  Warnings: 0	0.000 sec
COMMIT;


### Step 3 sesshion1
SELECT balance FROM accounts WHERE id = 1;
-- Output: 1000 (неповторюване читання)

COMMIT;
```

## PHANTOM READ

### Step 1 sesshion1

```sql
SET SESSION autocommit = 0;
SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SET GLOBAL TRANSACTION ISOLATION LEVEL REPEATABLE READ;

SELECT @@global.transaction_isolation, @@session.transaction_isolation;
START TRANSACTION;
SELECT COUNT(*) FROM accounts;
-- Очікуваний результат: 2
```

### Step 2 sesshion2

```sql
SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SET autocommit = 0;
START TRANSACTION;

INSERT INTO accounts (name, balance) VALUES ('Charlie', 2000);
COMMIT;
```

### Step 3 sesshion1

```sql 

SELECT COUNT(*) FROM accounts;
# COUNT(*)
#'2'


COMMIT;
```

## solution (phantom read)

1. SET SESSION TRANSACTION ISOLATION LEVEL SERIALIZABLE;
