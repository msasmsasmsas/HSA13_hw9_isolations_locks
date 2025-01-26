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

SET GLOBAL TRANSACTION ISOLATION LEVEL REPEATABLE READ;
START TRANSACTION;
SELECT balance FROM accounts WHERE id = 1;
13:04:10	SELECT balance FROM accounts WHERE id = 1 LIMIT 0, 100000	1 row(s) returned	0.000 sec / 0.000 sec

# balance
'1000'

UPDATE accounts SET balance = balance + 500 WHERE id = 1;
13:04:10	UPDATE accounts SET balance = balance + 500 WHERE id = 1	1 row(s) affected Rows matched: 1  Changed: 1  Warnings: 0	0.000 sec


```


### Step 2 sesshion2 

```SQL

START TRANSACTION;
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
'1300'


```

### Step 3 sesshion1 

```SQL


COMMIT;
13:12:47	COMMIT	0 row(s) affected	0.016 sec


SELECT balance FROM accounts WHERE id = 1;
13:15:20	SELECT balance FROM accounts WHERE id = 1 LIMIT 0, 100000	1 row(s) returned	0.000 sec / 0.000 sec

# balance
'1300'


```
