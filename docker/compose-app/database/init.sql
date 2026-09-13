CREATE TABLE IF NOT EXISTS orders (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    item VARCHAR(100) NOT NULL,
    status VARCHAR(50) NOT NULL
);

INSERT INTO orders (user_id, item, status)
VALUES
    (1, 'Laptop', 'shipped'),
    (2, 'Monitor', 'processing'),
    (3, 'Keyboard', 'delivered');
