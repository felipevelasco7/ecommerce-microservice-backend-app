
CREATE TABLE IF NOT EXISTS payments (
	payment_id SERIAL PRIMARY KEY,
	order_id INTEGER,
	is_payed BOOLEAN,
	payment_status VARCHAR(255),
	created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
	updated_at TIMESTAMP
);

