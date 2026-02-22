
CREATE DATABASE tobacco_store;
USE tobacco_store;

CREATE TABLE users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  username VARCHAR(100),
  email VARCHAR(100) UNIQUE,
  password VARCHAR(255)
);

CREATE TABLE products (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100),
  category VARCHAR(100),
  price DECIMAL(10,2),
  stock INT
);

INSERT INTO products (name, category, price, stock) VALUES
('Marlboro Gold', 'Cigarette', 300, 50),
('Vape X Pro', 'Vape', 2500, 20);
