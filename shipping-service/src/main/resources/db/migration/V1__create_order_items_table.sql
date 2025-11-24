
CREATE TABLE IF NOT EXISTS order_items (
	product_id INTEGER NOT NULL,
	order_id INTEGER NOT NULL,
	ordered_quantity INTEGER,
	created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
	updated_at TIMESTAMP,
	PRIMARY KEY (product_id, order_id)
);

