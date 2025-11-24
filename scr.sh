#!/bin/bash

set -e

echo "🔧 CORRIGIENDO TODOS LOS SCRIPTS DE MIGRACIÓN PARA POSTGRESQL"
echo "============================================================="
echo ""

cd user-service/src/main/resources/db/migration/

# Backup de todos los archivos originales
echo "📦 Creando backups..."
for file in *.sql; do
    cp "$file" "${file}.mysql.bak"
done
echo "✅ Backups creados"
echo ""

# V1 - Ya lo actualizaste, pero lo incluyo para estar seguros
cat > V1__create_users_table.sql <<'EOF'
CREATE TABLE IF NOT EXISTS users (
    user_id SERIAL PRIMARY KEY,
    first_name VARCHAR(255),
    last_name VARCHAR(255),
    image_url VARCHAR(255) DEFAULT 'https://bootdey.com/img/Content/avatar/avatar7.png',
    email VARCHAR(255) DEFAULT 'springxyzabcboot@gmail.com',
    phone VARCHAR(255) DEFAULT '+21622125144',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP
);
EOF

# V2 - INSERT está bien, no necesita cambios
cat > V2__insert_users_table.sql <<'EOF'
INSERT INTO users (first_name, last_name) VALUES
('selim', 'horri'),
('amine', 'ladjimi'),
('omar', 'derouiche'),
('admin', 'admin');
EOF

# V3 - Corregir address table
cat > V3__create_address_table.sql <<'EOF'
CREATE TABLE IF NOT EXISTS address (
    address_id SERIAL PRIMARY KEY,
    user_id INTEGER,
    full_address VARCHAR(255),
    postal_code VARCHAR(255),
    city VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP
);
EOF

# V4 - INSERT está bien
cat > V4__insert_address_table.sql <<'EOF'
INSERT INTO address (user_id, full_address, postal_code, city) VALUES
(1, 'carthage byrsa', '2016', 'carthage'),
(2, 'carthage byrsa', '2016', 'carthage'),
(3, 'carthage byrsa', '2016', 'carthage'),
(4, 'carthage byrsa', '2016', 'carthage'),
(2, 'kram', '2015', 'kram'),
(1, 'kram', '2015', 'kram');
EOF

# V5 - Corregir credentials table
cat > V5__create_credentials_table.sql <<'EOF'
CREATE TABLE IF NOT EXISTS credentials (
    credential_id SERIAL PRIMARY KEY,
    user_id INTEGER,
    username VARCHAR(255),
    password VARCHAR(255),
    role VARCHAR(255),
    is_enabled BOOLEAN DEFAULT false,
    is_account_non_expired BOOLEAN DEFAULT true,
    is_account_non_locked BOOLEAN DEFAULT true,
    is_credentials_non_expired BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP
);
EOF

# V6 - INSERT está bien
cat > V6__insert_credentials_table.sql <<'EOF'
INSERT INTO credentials (user_id, username, password, role, is_enabled) VALUES
(1, 'selimhorri', '$2a$04$/S7cWjHPZul03sPEivycWeKTBvLyjYdaRWmeaFbiqKy9es/3W4QB6', 'ROLE_USER', true),
(2, 'amineladjimi', '$2a$04$8D8OuqPbE4LhRckvtBAHrOmpeWmE92xNNVtyK8Z/lrJFjsImpjBkm', 'ROLE_USER', true),
(3, 'omarderouiche', '$2a$04$jelNGcF4wFHJirT5Pm7jPO8812QE/3tIWIs1DNnajS68iG4aKUqvS', 'ROLE_USER', true),
(4, 'admin', '$2a$04$1G4TwSzwf5JwZ4dKCXG1Zu1Qh3WIY9JNaM9vF6Ff05QDfyPg7nSxO', 'ROLE_USER', true);
EOF

# V7 - Corregir verification_tokens table
cat > V7__create_verification_tokens_table.sql <<'EOF'
CREATE TABLE IF NOT EXISTS verification_tokens (
    verification_token_id SERIAL PRIMARY KEY,
    credential_id INTEGER,
    verif_token VARCHAR(255),
    expire_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP
);
EOF

# V8 - INSERT está bien
cat > V8__insert_verification_tokens_table.sql <<'EOF'
INSERT INTO verification_tokens (credential_id, verif_token, expire_date) VALUES
(1, '', '2021-12-31'),
(2, '', '2021-12-31'),
(3, '', '2021-12-31'),
(4, '', '2021-12-31');
EOF

# V9, V10, V11 - Foreign keys están bien
cat > V9__create_address_user_id_fk.sql <<'EOF'
ALTER TABLE address
  ADD CONSTRAINT fk1_assign FOREIGN KEY (user_id) REFERENCES users (user_id);
EOF

cat > V10__create_credentials_user_id_fk.sql <<'EOF'
ALTER TABLE credentials
  ADD CONSTRAINT fk2_assign FOREIGN KEY (user_id) REFERENCES users (user_id);
EOF

cat > V11__create_verification_tokens_credential_id_fk.sql <<'EOF'
ALTER TABLE verification_tokens
  ADD CONSTRAINT fk3_assign FOREIGN KEY (credential_id) REFERENCES credentials (credential_id);
EOF

cd ../../../../../..

echo "✅ Todos los archivos actualizados para PostgreSQL"
echo ""

echo "📋 Verificando archivos corregidos:"
for file in user-service/src/main/resources/db/migration/*.sql; do
    if grep -q "INT(11)\|AUTO_INCREMENT\|NULL_TO_DEFAULT\|LOCALTIMESTAMP" "$file"; then
        echo "❌ $file - Todavía tiene sintaxis MySQL"
    else
        echo "✅ $(basename $file) - OK"
    fi
done
echo ""

echo "🗑️  Limpiando base de datos..."
kubectl exec -n dev postgres-0 -- psql -U ecommerce -d user_db -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public; GRANT ALL ON SCHEMA public TO ecommerce;"
echo "✅ Base de datos limpia"
echo ""

echo "🗑️  Eliminando deployment..."
kubectl delete deployment user-service -n dev --ignore-not-found=true
sleep 3
echo ""

echo "🏗️  Construyendo nueva imagen (con --no-cache)..."
gcloud builds submit --config=cloudbuild-user-service.yaml .

if [ $? -ne 0 ]; then
    echo "❌ Build falló"
    exit 1
fi
echo "✅ Build exitoso"
echo ""

echo "🚀 Desplegando..."
PROJECT_ID=$(gcloud config get-value project)

cat <<YAML | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: user-service
  namespace: dev
spec:
  replicas: 1
  selector:
    matchLabels:
      app: user-service
  template:
    metadata:
      labels:
        app: user-service
    spec:
      initContainers:
      - name: wait-for-eureka
        image: busybox:1.36
        command: ['sh', '-c', 'until wget -qO- http://service-discovery:8761/actuator/health 2>/dev/null; do sleep 3; done']
      - name: wait-for-postgres
        image: postgres:13-alpine
        command: ['sh', '-c', 'until PGPASSWORD=ecommerce123 psql -h postgres -U ecommerce -d user_db -c "\\q" 2>/dev/null; do sleep 3; done']
      containers:
      - name: user-service
        image: gcr.io/$PROJECT_ID/user-service:latest
        imagePullPolicy: Always
        ports:
        - containerPort: 8700
        envFrom:
        - configMapRef:
            name: user-service-config
        - secretRef:
            name: user-service-secret
        resources:
          requests:
            memory: "512Mi"
            cpu: "250m"
          limits:
            memory: "1Gi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /user-service/actuator/health/liveness
            port: 8700
          initialDelaySeconds: 120
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /user-service/actuator/health/readiness
            port: 8700
          initialDelaySeconds: 90
          periodSeconds: 5
YAML

echo "✅ Deployment creado"
echo ""

echo "⏳ Esperando pod..."
sleep 15

echo "📊 Estado:"
kubectl get pods -n dev -l app=user-service
echo ""

echo "📝 Logs (presiona Ctrl+C para salir):"
kubectl logs -n dev -f -l app=user-service -c user-service
EOF