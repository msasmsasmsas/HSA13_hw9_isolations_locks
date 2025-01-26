USE hsa13;

CREATE TABLE employees (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50),
    salary DECIMAL(10,2)
) ENGINE=InnoDB;

INSERT INTO employees (name, salary) VALUES
('John Doe', 5000),
('Jane Smith', 6000);