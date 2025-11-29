CREATE TABLE IF NOT EXISTS verification_tokens (
    verification_token_id SERIAL PRIMARY KEY,
    credential_id INTEGER,
    verif_token VARCHAR(255),
    expire_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP
);
