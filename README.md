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

## Lost Update 

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
2. SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;


## dirty read 

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

SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
START TRANSACTION;
SELECT balance FROM accounts WHERE id = 1;
# balance
#'2000'
-- Output: 2000 (некоректне значення)

COMMIT;
