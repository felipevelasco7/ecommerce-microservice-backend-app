# Guía de Despliegue - E-commerce Microservices en Google Kubernetes Engine (GKE)

## Índice
1. [Configuración Inicial de GCP](#1-configuración-inicial-de-gcp)
2. [Creación del Clúster GKE](#2-creación-del-clúster-gke)
3. [Preparación de Namespaces](#3-preparación-de-namespaces)
4. [Despliegue de PostgreSQL](#4-despliegue-de-postgresql)
5. [Construcción de Imágenes Docker](#5-construcción-de-imágenes-docker)
6. [Despliegue de Servicios Core](#6-despliegue-de-servicios-core)
7. [Migración de Scripts SQL a PostgreSQL](#7-migración-de-scripts-sql-a-postgresql)
8. [Despliegue de User Service](#8-despliegue-de-user-service)
9. [Verificación del Sistema](#9-verificación-del-sistema)
10. [Troubleshooting](#10-troubleshooting)

---

## 1. Configuración Inicial de GCP

### 1.1 Instalar Google Cloud SDK (macOS)

```bash
# Descargar e instalar gcloud CLI
curl https://sdk.cloud.google.com | bash

# Reiniciar el shell
exec -l $SHELL

# Verificar instalación
gcloud --version
```

### 1.2 Inicializar y Autenticar

```bash
# Inicializar gcloud
gcloud init

# Autenticar con tu cuenta de Google
gcloud auth login

# Configurar proyecto
export PROJECT_ID="ecommerce-microservices-final"
gcloud config set project $PROJECT_ID

# Si el proyecto no existe, crearlo
gcloud projects create $PROJECT_ID --name="E-commerce Microservices"
```

### 1.3 Habilitar APIs Necesarias

```bash
# Habilitar APIs de Google Cloud
gcloud services enable container.googleapis.com
gcloud services enable containerregistry.googleapis.com
gcloud services enable cloudbuild.googleapis.com
```

---

## 2. Creación del Clúster GKE

### 2.1 Crear Clúster

```bash
# Crear clúster GKE con autoscaling
gcloud container clusters create ecommerce-cluster \
    --zone=us-central1-a \
    --num-nodes=3 \
    --machine-type=e2-medium \
    --disk-size=20 \
    --enable-autoscaling \
    --min-nodes=2 \
    --max-nodes=5 \
    --enable-autorepair \
    --enable-autoupgrade
```

**Tiempo estimado:** 5-7 minutos

### 2.2 Conectar kubectl al Clúster

```bash
# Obtener credenciales del clúster
gcloud container clusters get-credentials ecommerce-cluster --zone=us-central1-a

# Verificar conexión
kubectl cluster-info
kubectl get nodes
```

**Verificación esperada:** Deberías ver 3 nodos en estado `Ready`

---

## 3. Preparación de Namespaces

### 3.1 Crear Estructura de Directorios

```bash
cd ecommerce-microservice-backend-app
mkdir -p k8s/{namespaces,configmaps,secrets,deployments,services}
```

### 3.2 Crear Archivo de Namespaces

```bash
cat > k8s/namespaces/namespaces.yaml <<'EOF'
apiVersion: v1
kind: Namespace
metadata:
  name: dev
  labels:
    name: dev
    environment: development
---
apiVersion: v1
kind: Namespace
metadata:
  name: qa
  labels:
    name: qa
    environment: quality-assurance
---
apiVersion: v1
kind: Namespace
metadata:
  name: prod
  labels:
    name: prod
    environment: production
EOF
```

### 3.3 Aplicar Namespaces

```bash
kubectl apply -f k8s/namespaces/namespaces.yaml

# Verificar
kubectl get namespaces
```

---

## 4. Despliegue de PostgreSQL

### 4.1 Crear Configuración de PostgreSQL

```bash
cat > k8s/deployments/postgres.yaml <<'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: postgres-config
  namespace: dev
data:
  POSTGRES_USER: ecommerce
  POSTGRES_DB: ecommerce_db
  POSTGRES_MULTIPLE_DATABASES: user_db,product_db,order_db,payment_db,shipping_db,favourite_db
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: postgres-initdb
  namespace: dev
data:
  init-databases.sh: |
    #!/bin/bash
    set -e
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
        CREATE DATABASE user_db;
        CREATE DATABASE product_db;
        CREATE DATABASE order_db;
        CREATE DATABASE payment_db;
        CREATE DATABASE shipping_db;
        CREATE DATABASE favourite_db;
        GRANT ALL PRIVILEGES ON DATABASE user_db TO $POSTGRES_USER;
        GRANT ALL PRIVILEGES ON DATABASE product_db TO $POSTGRES_USER;
        GRANT ALL PRIVILEGES ON DATABASE order_db TO $POSTGRES_USER;
        GRANT ALL PRIVILEGES ON DATABASE payment_db TO $POSTGRES_USER;
        GRANT ALL PRIVILEGES ON DATABASE shipping_db TO $POSTGRES_USER;
        GRANT ALL PRIVILEGES ON DATABASE favourite_db TO $POSTGRES_USER;
    EOSQL
---
apiVersion: v1
kind: Secret
metadata:
  name: postgres-secret
  namespace: dev
type: Opaque
data:
  POSTGRES_PASSWORD: ZWNvbW1lcmNlMTIz # ecommerce123 en base64
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres
  namespace: dev
spec:
  serviceName: postgres
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
      - name: postgres
        image: postgres:13-alpine
        ports:
        - containerPort: 5432
        envFrom:
        - configMapRef:
            name: postgres-config
        - secretRef:
            name: postgres-secret
        volumeMounts:
        - name: postgres-storage
          mountPath: /var/lib/postgresql/data
          subPath: postgres
        - name: initdb
          mountPath: /docker-entrypoint-initdb.d
        resources:
          requests:
            memory: "256Mi"
            cpu: "100m"
          limits:
            memory: "512Mi"
            cpu: "500m"
      volumes:
      - name: initdb
        configMap:
          name: postgres-initdb
  volumeClaimTemplates:
  - metadata:
      name: postgres-storage
    spec:
      accessModes: [ "ReadWriteOnce" ]
      resources:
        requests:
          storage: 5Gi
---
apiVersion: v1
kind: Service
metadata:
  name: postgres
  namespace: dev
spec:
  selector:
    app: postgres
  ports:
    - port: 5432
      targetPort: 5432
  clusterIP: None
EOF
```

### 4.2 Desplegar PostgreSQL

```bash
kubectl apply -f k8s/deployments/postgres.yaml

# Esperar a que esté listo
kubectl wait --for=condition=ready pod/postgres-0 -n dev --timeout=180s

# Verificar bases de datos creadas
kubectl exec -n dev postgres-0 -- psql -U ecommerce -c '\l'
```

**Bases de datos esperadas:**
- ecommerce_db
- user_db
- product_db
- order_db
- payment_db
- shipping_db
- favourite_db

---

## 5. Construcción de Imágenes Docker

### 5.1 Actualizar Dockerfiles

Todos los servicios necesitan usar una imagen base válida.

```bash
# Actualizar Dockerfile de service-discovery
cat > service-discovery/Dockerfile <<'EOF'
FROM eclipse-temurin:11-jre-alpine

LABEL maintainer="ecommerce-project"

WORKDIR /app

ARG JAR_FILE=service-discovery/target/*.jar
COPY ${JAR_FILE} app.jar

EXPOSE 8761

ENTRYPOINT ["java", "-jar", "app.jar"]
EOF
```

**Repetir para todos los servicios**, ajustando el puerto EXPOSE según:
- service-discovery: 8761
- cloud-config: 9296
- api-gateway: 8080
- proxy-client: 8900
- user-service: 8700
- product-service: 8500
- order-service: 8300
- payment-service: 8400
- shipping-service: 8600
- favourite-service: 8800

### 5.2 Crear Archivo de Cloud Build para User Service

```bash
cat > cloudbuild-user-service.yaml <<'EOF'
steps:
  # Build user-service SIN CACHÉ
  - name: 'gcr.io/cloud-builders/mvn'
    args: ['clean', 'package', '-pl', 'user-service', '-am', '-DskipTests', '-U']
  
  - name: 'gcr.io/cloud-builders/docker'
    args: 
      - 'build'
      - '--no-cache'
      - '-t'
      - 'gcr.io/$PROJECT_ID/user-service:0.1.0'
      - '-t'
      - 'gcr.io/$PROJECT_ID/user-service:latest'
      - '-f'
      - 'user-service/Dockerfile'
      - '.'

images:
  - 'gcr.io/$PROJECT_ID/user-service:0.1.0'
  - 'gcr.io/$PROJECT_ID/user-service:latest'

timeout: 600s
options:
  machineType: 'E2_HIGHCPU_8'
EOF
```

### 5.3 Configurar Docker para GCR

```bash
gcloud auth configure-docker
```

---

## 6. Despliegue de Servicios Core

### 6.1 Service Discovery (Eureka)

```bash
cat > k8s/deployments/service-discovery.yaml <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: service-discovery
  namespace: dev
  labels:
    app: service-discovery
spec:
  replicas: 1
  selector:
    matchLabels:
      app: service-discovery
  template:
    metadata:
      labels:
        app: service-discovery
    spec:
      containers:
      - name: service-discovery
        image: gcr.io/PROJECT_ID/service-discovery:0.1.0
        ports:
        - containerPort: 8761
        env:
        - name: SPRING_PROFILES_ACTIVE
          value: "dev"
        - name: EUREKA_INSTANCE_HOSTNAME
          value: "service-discovery"
        - name: EUREKA_CLIENT_REGISTER_WITH_EUREKA
          value: "false"
        - name: EUREKA_CLIENT_FETCH_REGISTRY
          value: "false"
        resources:
          requests:
            memory: "512Mi"
            cpu: "250m"
          limits:
            memory: "1Gi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /actuator/health/liveness
            port: 8761
          initialDelaySeconds: 90
          periodSeconds: 10
          failureThreshold: 5
        readinessProbe:
          httpGet:
            path: /actuator/health/readiness
            port: 8761
          initialDelaySeconds: 60
          periodSeconds: 5
          failureThreshold: 3
---
apiVersion: v1
kind: Service
metadata:
  name: service-discovery
  namespace: dev
spec:
  selector:
    app: service-discovery
  ports:
    - protocol: TCP
      port: 8761
      targetPort: 8761
  type: ClusterIP
EOF
```

**Desplegar:**

```bash
export PROJECT_ID=$(gcloud config get-value project)
sed "s/PROJECT_ID/$PROJECT_ID/g" k8s/deployments/service-discovery.yaml | kubectl apply -f -

# Verificar
kubectl get pods -n dev -w
```

### 6.2 Cloud Config Server

```bash
cat > k8s/deployments/cloud-config.yaml <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cloud-config
  namespace: dev
  labels:
    app: cloud-config
spec:
  replicas: 1
  selector:
    matchLabels:
      app: cloud-config
  template:
    metadata:
      labels:
        app: cloud-config
    spec:
      containers:
      - name: cloud-config
        image: gcr.io/PROJECT_ID/cloud-config:0.1.0
        ports:
        - containerPort: 9296
        env:
        - name: SPRING_PROFILES_ACTIVE
          value: "dev"
        - name: EUREKA_CLIENT_SERVICEURL_DEFAULTZONE
          value: "http://service-discovery:8761/eureka/"
        - name: EUREKA_INSTANCE_PREFER_IP_ADDRESS
          value: "true"
        resources:
          requests:
            memory: "512Mi"
            cpu: "250m"
          limits:
            memory: "1Gi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /actuator/health/liveness
            port: 9296
          initialDelaySeconds: 90
          periodSeconds: 10
          failureThreshold: 3
        readinessProbe:
          httpGet:
            path: /actuator/health/readiness
            port: 9296
          initialDelaySeconds: 60
          periodSeconds: 5
          failureThreshold: 3
---
apiVersion: v1
kind: Service
metadata:
  name: cloud-config
  namespace: dev
spec:
  selector:
    app: cloud-config
  ports:
    - protocol: TCP
      port: 9296
      targetPort: 9296
  type: ClusterIP
EOF
```

**Desplegar:**

```bash
sed "s/PROJECT_ID/$PROJECT_ID/g" k8s/deployments/cloud-config.yaml | kubectl apply -f -
```

---

## 7. Migración de Scripts SQL a PostgreSQL

Los scripts de Flyway están escritos para MySQL y deben convertirse a sintaxis PostgreSQL.

### 7.1 Cambios Necesarios

**MySQL → PostgreSQL:**
- `INT(11) AUTO_INCREMENT` → `SERIAL`
- `INT(11)` → `INTEGER`
- `LOCALTIMESTAMP NULL_TO_DEFAULT` → `CURRENT_TIMESTAMP`
- `DEFAULT false` → `DEFAULT false` (sin cambios en BOOLEAN)

### 7.2 Actualizar application-dev.yml

```bash
cat > user-service/src/main/resources/application-dev.yml <<'EOF'
server:
  port: 8700

management:
  endpoints:
    web:
      exposure:
        include: "*"

spring:
  datasource:
    url: ${SPRING_DATASOURCE_URL:jdbc:postgresql://localhost:5432/user_db}
    username: ${SPRING_DATASOURCE_USERNAME:ecommerce}
    password: ${SPRING_DATASOURCE_PASSWORD:ecommerce123}
    driver-class-name: org.postgresql.Driver
  jpa:
    show-sql: true
    hibernate:
      ddl-auto: update
    properties:
      hibernate:
        dialect: org.hibernate.dialect.PostgreSQLDialect
        use_sql_comments: true
        format_sql: true

logging:
  level:
    org:
      hibernate:
        SQL: DEBUG
      springframework:
        web: DEBUG
        data: DEBUG
      boot:
        autoconfigure:
          data:
            rest: DEBUG
            jpa: DEBUG
            orm: DEBUG
EOF
```

### 7.3 Actualizar Scripts de Migración

**V1 - create_users_table.sql:**

```sql
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
```

**V3 - create_address_table.sql:**

```sql
CREATE TABLE IF NOT EXISTS address (
    address_id SERIAL PRIMARY KEY,
    user_id INTEGER,
    full_address VARCHAR(255),
    postal_code VARCHAR(255),
    city VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP
);
```

**V5 - create_credentials_table.sql:**

```sql
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
```

**V7 - create_verification_tokens_table.sql:**

```sql
CREATE TABLE IF NOT EXISTS verification_tokens (
    verification_token_id SERIAL PRIMARY KEY,
    credential_id INTEGER,
    verif_token VARCHAR(255),
    expire_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP
);
```

### 7.4 Script Automatizado para Actualizar Migraciones

Usa el script `scr.sh` incluido en el repositorio que actualiza automáticamente todos los archivos SQL.

---

## 8. Despliegue de User Service

### 8.1 Crear ConfigMaps y Secrets

```bash
cat > k8s/deployments/user-service.yaml <<'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: user-service-config
  namespace: dev
data:
  SPRING_PROFILES_ACTIVE: "dev"
  EUREKA_CLIENT_SERVICEURL_DEFAULTZONE: "http://service-discovery:8761/eureka/"
  SPRING_CONFIG_IMPORT: "optional:configserver:http://cloud-config:9296/"
  SPRING_DATASOURCE_URL: "jdbc:postgresql://postgres:5432/user_db"
  SPRING_DATASOURCE_USERNAME: "ecommerce"
  SPRING_JPA_HIBERNATE_DDL_AUTO: "update"
---
apiVersion: v1
kind: Secret
metadata:
  name: user-service-secret
  namespace: dev
type: Opaque
data:
  SPRING_DATASOURCE_PASSWORD: ZWNvbW1lcmNlMTIz # ecommerce123
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: user-service
  namespace: dev
  labels:
    app: user-service
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
        command: ['sh', '-c', 'until wget -qO- http://service-discovery:8761/actuator/health 2>/dev/null; do echo "waiting for eureka..."; sleep 3; done; echo "eureka is up"']
      - name: wait-for-postgres
        image: postgres:13-alpine
        command: ['sh', '-c', 'until PGPASSWORD=ecommerce123 psql -h postgres -U ecommerce -d user_db -c "\\q" 2>/dev/null; do echo "waiting for postgres..."; sleep 3; done; echo "postgres is up"']
      containers:
      - name: user-service
        image: gcr.io/PROJECT_ID/user-service:latest
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
          failureThreshold: 5
        readinessProbe:
          httpGet:
            path: /user-service/actuator/health/readiness
            port: 8700
          initialDelaySeconds: 90
          periodSeconds: 5
          failureThreshold: 3
---
apiVersion: v1
kind: Service
metadata:
  name: user-service
  namespace: dev
spec:
  selector:
    app: user-service
  ports:
    - protocol: TCP
      port: 8700
      targetPort: 8700
  type: ClusterIP
EOF
```

### 8.2 Construir Imagen Docker

```bash
# Construir imagen en Cloud Build
gcloud builds submit --config=cloudbuild-user-service.yaml .
```

**Tiempo estimado:** 3-5 minutos

### 8.3 Desplegar User Service

```bash
export PROJECT_ID=$(gcloud config get-value project)
sed "s/PROJECT_ID/$PROJECT_ID/g" k8s/deployments/user-service.yaml | kubectl apply -f -

# Monitorear el despliegue
kubectl get pods -n dev -w

# Ver logs
kubectl logs -n dev -f -l app=user-service -c user-service
```

---

## 9. Verificación del Sistema

### 9.1 Verificar Estado de Pods

```bash
kubectl get pods -n dev
```

**Estado esperado:**
```
NAME                                READY   STATUS    RESTARTS   AGE
cloud-config-xxxxx                  1/1     Running   0          Xm
postgres-0                          1/1     Running   0          Xm
service-discovery-xxxxx             1/1     Running   0          Xm
user-service-xxxxx                  1/1     Running   0          Xm
```

### 9.2 Verificar Servicios

```bash
kubectl get svc -n dev
```

### 9.3 Verificar Eureka Dashboard

```bash
# Port-forward a Eureka
kubectl port-forward -n dev svc/service-discovery 8761:8761

# Abrir en navegador: http://localhost:8761
```

**Servicios registrados esperados:**
- SERVICE-DISCOVERY
- CLOUD-CONFIG
- USER-SERVICE

### 9.4 Verificar Base de Datos

```bash
# Ver bases de datos
kubectl exec -n dev postgres-0 -- psql -U ecommerce -c '\l'

# Ver tablas de user_db
kubectl exec -n dev postgres-0 -- psql -U ecommerce -d user_db -c '\dt'

# Ver datos de usuarios
kubectl exec -n dev postgres-0 -- psql -U ecommerce -d user_db -c "SELECT * FROM users;"
```

### 9.5 Ver Logs

```bash
# Logs de user-service
kubectl logs -n dev -l app=user-service

# Logs en tiempo real
kubectl logs -n dev -f -l app=user-service -c user-service
```

---

## 10. Troubleshooting

### Error: Failed to load driver class org.postgresql.Driver

**Causa:** El driver de PostgreSQL no está incluido en el JAR o la imagen Docker está usando caché vieja.

**Solución:**
```bash
# Verificar que pom.xml tenga la dependencia
grep -A 3 "postgresql" user-service/pom.xml

# Rebuild sin caché
gcloud builds submit --config=cloudbuild-user-service.yaml .

# Forzar pull de nueva imagen
kubectl delete deployment user-service -n dev
kubectl apply -f k8s/deployments/user-service.yaml
```

### Error: Flyway migration failed - syntax error

**Causa:** Scripts SQL tienen sintaxis de MySQL en lugar de PostgreSQL.

**Solución:**
```bash
# Ejecutar script de corrección
./scr.sh

# O manualmente actualizar archivos según la sección 7.3
```

### Error: Pod stuck in "Init:2/3"

**Causa:** El init container no puede conectarse a la base de datos.

**Solución:**
```bash
# Verificar que la base de datos existe
kubectl exec -n dev postgres-0 -- psql -U ecommerce -c '\l' | grep user_db

# Si no existe, crearla manualmente
kubectl exec -n dev postgres-0 -- psql -U ecommerce -d postgres -c "CREATE DATABASE user_db;"
```

### Error: CrashLoopBackOff

**Solución:**
```bash
# Ver logs del pod fallido
kubectl logs -n dev <pod-name> --previous

# Ver eventos
kubectl describe pod -n dev <pod-name>

# Ver logs de init containers
kubectl logs -n dev <pod-name> -c wait-for-eureka
kubectl logs -n dev <pod-name> -c wait-for-postgres
```

### Limpiar y Reiniciar

Si necesitas empezar desde cero:

```bash
# Eliminar todos los recursos del namespace dev
kubectl delete namespace dev

# Recrear namespace
kubectl apply -f k8s/namespaces/namespaces.yaml

# Empezar desde el paso 4
```

---

## Comandos Útiles

### Ver todos los recursos

```bash
kubectl get all -n dev
```

### Ver uso de recursos

```bash
kubectl top nodes
kubectl top pods -n dev
```

### Port-forward a un servicio

```bash
kubectl port-forward -n dev svc/service-discovery 8761:8761
kubectl port-forward -n dev svc/user-service 8700:8700
```

### Ejecutar comando en pod

```bash
kubectl exec -it -n dev postgres-0 -- psql -U ecommerce -d user_db
```

### Ver configuración de un deployment

```bash
kubectl get deployment user-service -n dev -o yaml
```

### Escalar un deployment

```bash
kubectl scale deployment user-service -n dev --replicas=2
```

### Ver logs de Cloud Build

```bash
gcloud builds list
gcloud builds log <BUILD_ID>
```

---

## 11. Despliegue de Microservicios de Negocio

Esta sección documenta el despliegue de los 5 microservicios principales: Product, Order, Payment, Shipping y Favourite.

### 11.1 Preparación Común para Todos los Servicios

#### 11.1.1 Actualizar Dependencias en pom.xml

Agregar el driver de PostgreSQL a cada servicio (product, order, payment, shipping, favourite):

```xml
<dependency>
    <groupId>org.postgresql</groupId>
    <artifactId>postgresql</artifactId>
    <scope>runtime</scope>
</dependency>
```

#### 11.1.2 Actualizar application-dev.yml

Actualizar la configuración de cada servicio para usar PostgreSQL y conectarse a Cloud Config:

```yaml
server:
  port: 8500  # Cambiar según servicio

management:
  endpoints:
    web:
      exposure:
        include: "*"

spring:
  datasource:
    url: ${SPRING_DATASOURCE_URL:jdbc:postgresql://localhost:5432/product_db}
    username: ${SPRING_DATASOURCE_USERNAME:ecommerce}
    password: ${SPRING_DATASOURCE_PASSWORD:ecommerce123}
    driver-class-name: org.postgresql.Driver
  jpa:
    show-sql: true
    hibernate:
      ddl-auto: none  # Importante: usar 'none' para evitar conflictos con Flyway
    properties:
      hibernate:
        dialect: org.hibernate.dialect.PostgreSQLDialect
        use_sql_comments: true
        format_sql: true
  flyway:
    enabled: true
    baseline-on-migrate: true

logging:
  level:
    org:
      hibernate:
        SQL: DEBUG
      springframework:
        web: DEBUG
```

**Puertos por servicio:**
- product-service: 8500
- order-service: 8300
- payment-service: 8400
- shipping-service: 8600
- favourite-service: 8800

**Bases de datos por servicio:**
- product-service: product_db
- order-service: order_db
- payment-service: payment_db
- shipping-service: shipping_db
- favourite-service: favourite_db

#### 11.1.3 Migrar Scripts Flyway a PostgreSQL

**Cambios necesarios en cada archivo SQL de Flyway:**

```sql
-- ANTES (MySQL)
user_id INT(11) AUTO_INCREMENT PRIMARY KEY,
price_unit DECIMAL(10,2),
is_verified BOOLEAN DEFAULT false,
created_at LOCALTIMESTAMP NULL_TO_DEFAULT

-- DESPUÉS (PostgreSQL)
user_id SERIAL PRIMARY KEY,
price_unit NUMERIC(10,2),
is_verified BOOLEAN DEFAULT false,
created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
```

**Script automatizado para actualizar:**

```bash
# Ejecutar desde la raíz del proyecto
./scr.sh
```

O manualmente con sed:

```bash
for service in product-service order-service payment-service shipping-service favourite-service; do
  find $service/src/main/resources/db/migration -name "*.sql" -exec sed -i '' \
    -e 's/INT(11) AUTO_INCREMENT/SERIAL/g' \
    -e 's/INT(11)/INTEGER/g' \
    -e 's/DECIMAL/NUMERIC/g' \
    -e 's/LOCALTIMESTAMP NULL_TO_DEFAULT/CURRENT_TIMESTAMP NOT NULL/g' {} \;
done
```

### 11.2 Crear ConfigMaps y Secrets

Para cada servicio, crear el ConfigMap con la configuración del Cloud Config Server:

```bash
cat > k8s/configmaps/product-service-config.yaml <<'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: product-service-config
  namespace: dev
data:
  SPRING_PROFILES_ACTIVE: "dev"
  EUREKA_CLIENT_SERVICEURL_DEFAULTZONE: "http://service-discovery:8761/eureka/"
  SPRING_CONFIG_IMPORT: "optional:configserver:http://cloud-config:9296"
  SPRING_DATASOURCE_URL: "jdbc:postgresql://postgres:5432/product_db"
  SPRING_DATASOURCE_USERNAME: "ecommerce"
  SPRING_JPA_HIBERNATE_DDL_AUTO: "none"
EOF
```

Crear el Secret:

```bash
cat > k8s/secrets/product-service-secret.yaml <<'EOF'
apiVersion: v1
kind: Secret
metadata:
  name: product-service-secret
  namespace: dev
type: Opaque
data:
  SPRING_DATASOURCE_PASSWORD: ZWNvbW1lcmNlMTIz # ecommerce123
EOF
```

**Repetir para cada servicio:** order, payment, shipping, favourite

### 11.3 Crear Cloud Build Configurations

Crear archivo de build para cada servicio con la flag `--no-cache`:

```bash
cat > cloudbuild-product-service.yaml <<'EOF'
steps:
  - name: 'gcr.io/cloud-builders/mvn'
    id: 'build-jar'
    args: ['clean', 'package', '-pl', 'product-service', '-am', '-DskipTests', '-U']
  
  - name: 'gcr.io/cloud-builders/docker'
    id: 'build-image'
    args: 
      - 'build'
      - '--no-cache'
      - '-t'
      - 'gcr.io/$PROJECT_ID/product-service:0.1.0'
      - '-t'
      - 'gcr.io/$PROJECT_ID/product-service:latest'
      - '-f'
      - 'product-service/Dockerfile'
      - '.'

images:
  - 'gcr.io/$PROJECT_ID/product-service:0.1.0'
  - 'gcr.io/$PROJECT_ID/product-service:latest'

timeout: 600s
options:
  machineType: 'E2_HIGHCPU_8'
EOF
```

**Repetir para:** order-service, payment-service, shipping-service, favourite-service

### 11.4 Crear Deployments de Kubernetes

Crear deployment para cada servicio con configuración de recursos apropiada:

```bash
cat > k8s/deployments/product-service.yaml <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: product-service
  namespace: dev
spec:
  replicas: 1
  selector:
    matchLabels:
      app: product-service
  template:
    metadata:
      labels:
        app: product-service
    spec:
      initContainers:
      - name: wait-for-eureka
        image: busybox:1.36
        command: ['sh', '-c', 'until wget -qO- http://service-discovery:8761/actuator/health 2>/dev/null; do echo "Waiting for Eureka..."; sleep 3; done']
      - name: wait-for-postgres
        image: postgres:13-alpine
        command: ['sh', '-c', 'until PGPASSWORD=ecommerce123 psql -h postgres -U ecommerce -d product_db -c "\\q" 2>/dev/null; do echo "Waiting for PostgreSQL..."; sleep 3; done']
      containers:
      - name: product-service
        image: gcr.io/PROJECT_ID/product-service:latest
        imagePullPolicy: Always
        ports:
        - containerPort: 8500
        envFrom:
        - configMapRef:
            name: product-service-config
        - secretRef:
            name: product-service-secret
        resources:
          requests:
            memory: "512Mi"
            cpu: "250m"
          limits:
            memory: "1Gi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /product-service/actuator/health/liveness
            port: 8500
          initialDelaySeconds: 120
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3
        readinessProbe:
          httpGet:
            path: /product-service/actuator/health/readiness
            port: 8500
          initialDelaySeconds: 90
          periodSeconds: 5
          timeoutSeconds: 3
          failureThreshold: 3
---
apiVersion: v1
kind: Service
metadata:
  name: product-service
  namespace: dev
spec:
  type: ClusterIP
  selector:
    app: product-service
  ports:
  - port: 8500
    targetPort: 8500
    protocol: TCP
EOF
```

**Ajustar para cada servicio:** puertos, nombres de bases de datos, rutas de health checks

### 11.5 Script Automatizado de Despliegue

Crear script para automatizar todo el proceso:

```bash
cat > build-and-deploy-all.sh <<'EOF'
#!/bin/bash
set -e
cd "$(dirname "$0")"

PROJECT_ID=$(gcloud config get-value project)
echo "🚀 Iniciando despliegue automatizado..."

# Lista de servicios a desplegar
SERVICES=("order-service" "payment-service" "shipping-service" "favourite-service")

for SERVICE in "${SERVICES[@]}"; do
    echo ""
    echo "======================================="
    echo "📦 Construyendo ${SERVICE}..."
    echo "======================================="
    
    gcloud builds submit --config=cloudbuild-${SERVICE}.yaml .
    
    if [ $? -eq 0 ]; then
        echo "✅ Build de ${SERVICE} exitoso"
        
        echo ""
        echo "📦 Desplegando ${SERVICE}..."
        echo "==============================="
        
        kubectl apply -f k8s/configmaps/${SERVICE}-config.yaml
        kubectl apply -f k8s/secrets/${SERVICE}-secret.yaml
        sed "s/PROJECT_ID/$PROJECT_ID/g" k8s/deployments/${SERVICE}.yaml | kubectl apply -f -
        
        echo "✅ ${SERVICE} desplegado"
    else
        echo "❌ Error en build de ${SERVICE}"
        exit 1
    fi
done

echo ""
echo "🎉 ¡Proceso completado!"
echo ""
echo "📊 Estado de todos los pods:"
kubectl get pods -n dev

echo ""
echo "🔍 Servicios en Eureka:"
echo "kubectl port-forward -n dev svc/service-discovery 8761:8761"
echo "Luego visita: http://localhost:8761"
EOF

chmod +x build-and-deploy-all.sh
```

### 11.6 Ejecutar Despliegue Automatizado

```bash
# Ejecutar script
./build-and-deploy-all.sh
```

**Tiempo total estimado:** 15-20 minutos para los 4 servicios

### 11.7 Resolución de Problemas Comunes

#### Error: CrashLoopBackOff - Health Check Failures

**Problema:** El pod se reinicia constantemente antes de completar el startup.

**Causa:** Con recursos limitados (100m CPU), la aplicación puede tardar más de 5 minutos en arrancar.

**Solución:** Aumentar tiempos de probes en el deployment:

```yaml
resources:
  requests:
    memory: "256Mi"
    cpu: "100m"
  limits:
    memory: "512Mi"
    cpu: "200m"
startupProbe:
  httpGet:
    path: /favourite-service/actuator/health
    port: 8800
  initialDelaySeconds: 60
  periodSeconds: 10
  timeoutSeconds: 5
  failureThreshold: 50  # 60s + (50 * 10s) = 560 segundos total
livenessProbe:
  httpGet:
    path: /favourite-service/actuator/health/liveness
    port: 8800
  initialDelaySeconds: 30
  periodSeconds: 15
  timeoutSeconds: 5
  failureThreshold: 3
readinessProbe:
  httpGet:
    path: /favourite-service/actuator/health/readiness
    port: 8800
  initialDelaySeconds: 30
  periodSeconds: 10
  timeoutSeconds: 3
  failureThreshold: 3
```

#### Error: Pod Stuck in Pending - Insufficient CPU

**Problema:** `0/5 nodes are available: 5 Insufficient cpu`

**Causa:** El clúster ha alcanzado su límite máximo de nodos y CPU.

**Solución 1 - Reducir recursos del pod:**

```yaml
resources:
  requests:
    memory: "256Mi"
    cpu: "100m"  # Reducido de 250m
  limits:
    memory: "512Mi"
    cpu: "200m"  # Reducido de 500m
```

**Solución 2 - Escalar el clúster:**

```bash
gcloud container clusters update ecommerce-cluster \
    --zone=us-central1-a \
    --max-nodes=8
```

#### Error: Hibernate Schema Validation Failed

**Problema:** `Schema-validation: wrong column type encountered... found [numeric], but expecting [decimal]`

**Causa:** Hibernate valida estrictamente los tipos y PostgreSQL convierte DECIMAL a NUMERIC internamente.

**Solución:** Cambiar `ddl-auto` de `validate` a `none`:

```yaml
spring:
  jpa:
    hibernate:
      ddl-auto: none  # Dejar que Flyway maneje el schema
```

#### Verificar Tiempos de Startup

Ver cuánto tarda cada servicio en arrancar:

```bash
kubectl logs -n dev <pod-name> | grep "Started.*Application in"
```

Ejemplo de salida:
```
Started FavouriteServiceApplication in 337.705 seconds (JVM running for 353.196)
```

### 11.8 Verificación Final

```bash
# Ver todos los pods
kubectl get pods -n dev

# Estado esperado:
# NAME                                 READY   STATUS    RESTARTS   AGE
# cloud-config-xxxxx                   1/1     Running   0          Xh
# favourite-service-xxxxx              1/1     Running   0          Xm
# order-service-xxxxx                  1/1     Running   0          Xm
# payment-service-xxxxx                1/1     Running   0          Xm
# postgres-0                           1/1     Running   0          Xh
# product-service-xxxxx                1/1     Running   0          Xm
# service-discovery-xxxxx              1/1     Running   0          Xh
# shipping-service-xxxxx               1/1     Running   0          Xm
# user-service-xxxxx                   1/1     Running   0          Xh

# Verificar registro en Eureka
kubectl port-forward -n dev svc/service-discovery 8761:8761
# Abrir http://localhost:8761
```

**Servicios esperados en Eureka:**
- SERVICE-DISCOVERY
- CLOUD-CONFIG
- USER-SERVICE
- PRODUCT-SERVICE
- ORDER-SERVICE
- PAYMENT-SERVICE
- SHIPPING-SERVICE
- FAVOURITE-SERVICE

### 11.9 Comandos de Limpieza

Si necesitas redeployar un servicio:

```bash
# Eliminar deployment específico
kubectl delete deployment product-service -n dev

# Reconstruir imagen
gcloud builds submit --config=cloudbuild-product-service.yaml .

# Redesplegar
PROJECT_ID=$(gcloud config get-value project)
sed "s/PROJECT_ID/$PROJECT_ID/g" k8s/deployments/product-service.yaml | kubectl apply -f -

# Monitorear
kubectl get pods -n dev -w
```

### 11.10 Resumen de Configuraciones Críticas

| Servicio | Puerto | DB | CPU Request | Memory Request | Startup Time |
|----------|--------|-----|-------------|----------------|--------------|
| product-service | 8500 | product_db | 250m | 512Mi | ~90s |
| order-service | 8300 | order_db | 250m | 512Mi | ~120s |
| payment-service | 8400 | payment_db | 250m | 512Mi | ~90s |
| shipping-service | 8600 | shipping_db | 250m | 512Mi | ~100s |
| favourite-service | 8800 | favourite_db | 100m | 256Mi | ~337s |

**Nota:** favourite-service tiene recursos reducidos debido a limitaciones del clúster. Si tienes recursos disponibles, aumenta a 250m CPU / 512Mi RAM.

---

## 12. Despliegue de Proxy-Client y API Gateway

### 12.1 Contexto

Después de desplegar los 9 microservicios base, necesitamos completar la arquitectura con:
- **proxy-client**: Cliente proxy para interacciones frontend (puerto 8900)
- **api-gateway**: Gateway principal con acceso externo vía LoadBalancer (puerto 8080)

### 12.2 Desafíos Encontrados

#### Problema 1: Insuficiencia de Recursos CPU

Al desplegar proxy-client, el pod quedó en estado `Pending`:

```bash
kubectl describe pod -n dev proxy-client-xxxxx
# Events: 0/5 nodes are available: 5 Insufficient cpu
```

**Causa:** Clúster alcanzó máximo de 5 nodos con CPU insuficiente para nuevos pods.

**Solución:** Escalar el clúster aumentando el máximo de nodos:

```bash
# Aumentar capacidad del clúster
gcloud container clusters update ecommerce-cluster \
    --zone=us-central1-a \
    --max-nodes=8 \
    --enable-autoscaling

# Verificar creación de nuevo nodo
kubectl get nodes
# El autoscaler creará automáticamente nodos adicionales (5 → 6)
```

**Resultado:** El pod transitó de `Pending` → `Running` en ~60 segundos tras la creación del 6º nodo.

#### Problema 2: Health Checks con 404 en Proxy-Client

El pod proxy-client entraba en `CrashLoopBackOff`:

```bash
kubectl describe pod -n dev proxy-client-xxxxx
# Events: Liveness probe failed: HTTP probe failed with statuscode: 404
#         Readiness probe failed: HTTP probe failed with statuscode: 404
```

**Causa:** La aplicación usa contexto `/app` pero los health checks buscaban `/actuator/health`.

**Solución:** Actualizar el deployment para incluir el contexto correcto:

```yaml
# k8s/deployments/proxy-client.yaml
livenessProbe:
  httpGet:
    path: /app/actuator/health/liveness  # Añadir /app
    port: 8900
readinessProbe:
  httpGet:
    path: /app/actuator/health/readiness  # Añadir /app
    port: 8900
```

#### Problema 3: Pod Duplicado de Favourite-Service

Al restaurar recursos de favourite-service (100m→250m CPU), Kubernetes creó un segundo pod fallido:

```bash
kubectl get pods -n dev
# favourite-service-8dfbcb68-24rsm    1/1     Running          0          50m
# favourite-service-99766fdcc-b8fjj   0/1     InvalidImageName 0          10m
```

**Causa:** El `sed` no reemplazó `PROJECT_ID` en la imagen del deployment, quedando:
```
image: gcr.io/PROJECT_ID/favourite-service:latest  # ❌ Literal incorrecto
```

**Solución:**

```bash
# Aplicar deployment correctamente con sustitución
export PROJECT_ID=$(gcloud config get-value project)
sed "s/PROJECT_ID/$PROJECT_ID/g" k8s/deployments/favourite-service.yaml | kubectl apply -f -

# Eliminar pod fallido
kubectl delete pod -n dev favourite-service-99766fdcc-b8fjj
```

### 12.3 Construcción de Imágenes

#### Proxy-Client

```bash
# Crear cloudbuild-proxy-client.yaml
cat > cloudbuild-proxy-client.yaml << 'EOF'
steps:
  - name: 'maven:3.8.4-openjdk-11'
    id: 'build-jar'
    entrypoint: 'mvn'
    args: ['clean', 'package', '-DskipTests', '-pl', 'proxy-client', '-am']
  
  - name: 'gcr.io/cloud-builders/docker'
    id: 'build-image'
    args: [
      'build',
      '--no-cache',
      '-t', 'gcr.io/$PROJECT_ID/proxy-client:0.1.0',
      '-t', 'gcr.io/$PROJECT_ID/proxy-client:latest',
      '-f', 'proxy-client/Dockerfile',
      '.'
    ]

images:
  - 'gcr.io/$PROJECT_ID/proxy-client:0.1.0'
  - 'gcr.io/$PROJECT_ID/proxy-client:latest'

options:
  machineType: 'E2_HIGHCPU_8'
timeout: '600s'
EOF

# Construir imagen
gcloud builds submit --config=cloudbuild-proxy-client.yaml .
```

**Resultado:** BUILD SUCCESS en 1m31s

#### API Gateway

```bash
# Crear cloudbuild-api-gateway.yaml
cat > cloudbuild-api-gateway.yaml << 'EOF'
steps:
  - name: 'maven:3.8.4-openjdk-11'
    id: 'build-jar'
    entrypoint: 'mvn'
    args: ['clean', 'package', '-DskipTests', '-pl', 'api-gateway', '-am']
  
  - name: 'gcr.io/cloud-builders/docker'
    id: 'build-image'
    args: [
      'build',
      '--no-cache',
      '-t', 'gcr.io/$PROJECT_ID/api-gateway:0.1.0',
      '-t', 'gcr.io/$PROJECT_ID/api-gateway:latest',
      '-f', 'api-gateway/Dockerfile',
      '.'
    ]

images:
  - 'gcr.io/$PROJECT_ID/api-gateway:0.1.0'
  - 'gcr.io/$PROJECT_ID/api-gateway:latest'

options:
  machineType: 'E2_HIGHCPU_8'
timeout: '600s'
EOF

# Construir imagen
gcloud builds submit --config=cloudbuild-api-gateway.yaml .
```

**Resultado:** BUILD SUCCESS en 3m13s

### 12.4 Configuración de Kubernetes

#### Proxy-Client ConfigMap

```bash
cat > k8s/configmaps/proxy-client-config.yaml << 'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: proxy-client-config
  namespace: dev
data:
  SPRING_PROFILES_ACTIVE: "dev"
  EUREKA_CLIENT_SERVICEURL_DEFAULTZONE: "http://service-discovery:8761/eureka/"
  SPRING_CONFIG_IMPORT: "optional:configserver:http://cloud-config:9296"
EOF

kubectl apply -f k8s/configmaps/proxy-client-config.yaml
```

#### API Gateway ConfigMap

```bash
cat > k8s/configmaps/api-gateway-config.yaml << 'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: api-gateway-config
  namespace: dev
data:
  SPRING_PROFILES_ACTIVE: "dev"
  EUREKA_CLIENT_SERVICEURL_DEFAULTZONE: "http://service-discovery:8761/eureka/"
  SPRING_CONFIG_IMPORT: "optional:configserver:http://cloud-config:9296"
EOF

kubectl apply -f k8s/configmaps/api-gateway-config.yaml
```

### 12.5 Deployments

#### Proxy-Client Deployment

```bash
cat > k8s/deployments/proxy-client.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: proxy-client
  namespace: dev
spec:
  replicas: 1
  selector:
    matchLabels:
      app: proxy-client
  template:
    metadata:
      labels:
        app: proxy-client
    spec:
      initContainers:
      - name: wait-for-eureka
        image: busybox:1.36
        command: ['sh', '-c', 'until wget -qO- http://service-discovery:8761/actuator/health 2>/dev/null; do echo "Waiting for Eureka..."; sleep 3; done']
      containers:
      - name: proxy-client
        image: gcr.io/PROJECT_ID/proxy-client:latest
        imagePullPolicy: Always
        ports:
        - containerPort: 8900
        envFrom:
        - configMapRef:
            name: proxy-client-config
        resources:
          requests:
            memory: "512Mi"
            cpu: "250m"
          limits:
            memory: "1Gi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /app/actuator/health/liveness
            port: 8900
          initialDelaySeconds: 120
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3
        readinessProbe:
          httpGet:
            path: /app/actuator/health/readiness
            port: 8900
          initialDelaySeconds: 90
          periodSeconds: 5
          timeoutSeconds: 3
          failureThreshold: 3
---
apiVersion: v1
kind: Service
metadata:
  name: proxy-client
  namespace: dev
spec:
  type: ClusterIP
  selector:
    app: proxy-client
  ports:
  - port: 8900
    targetPort: 8900
    protocol: TCP
EOF

# Desplegar
PROJECT_ID=$(gcloud config get-value project)
sed "s/PROJECT_ID/$PROJECT_ID/g" k8s/deployments/proxy-client.yaml | kubectl apply -f -
```

**Nota importante:** Los health checks incluyen el contexto `/app` porque la aplicación lo requiere.

#### API Gateway Deployment con LoadBalancer

```bash
cat > k8s/deployments/api-gateway.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-gateway
  namespace: dev
spec:
  replicas: 1
  selector:
    matchLabels:
      app: api-gateway
  template:
    metadata:
      labels:
        app: api-gateway
    spec:
      initContainers:
      - name: wait-for-eureka
        image: busybox:1.36
        command: ['sh', '-c', 'until wget -qO- http://service-discovery:8761/actuator/health 2>/dev/null; do echo "Waiting for Eureka..."; sleep 3; done']
      containers:
      - name: api-gateway
        image: gcr.io/PROJECT_ID/api-gateway:latest
        imagePullPolicy: Always
        ports:
        - containerPort: 8080
        envFrom:
        - configMapRef:
            name: api-gateway-config
        resources:
          requests:
            memory: "512Mi"
            cpu: "250m"
          limits:
            memory: "1Gi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /actuator/health/liveness
            port: 8080
          initialDelaySeconds: 120
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3
        readinessProbe:
          httpGet:
            path: /actuator/health/readiness
            port: 8080
          initialDelaySeconds: 90
          periodSeconds: 5
          timeoutSeconds: 3
          failureThreshold: 3
---
apiVersion: v1
kind: Service
metadata:
  name: api-gateway
  namespace: dev
spec:
  type: LoadBalancer
  selector:
    app: api-gateway
  ports:
  - port: 80
    targetPort: 8080
    protocol: TCP
EOF

# Desplegar
PROJECT_ID=$(gcloud config get-value project)
sed "s/PROJECT_ID/$PROJECT_ID/g" k8s/deployments/api-gateway.yaml | kubectl apply -f -
```

**Diferencia clave:** El servicio api-gateway usa `type: LoadBalancer` para obtener una IP pública externa.

### 12.6 Verificación Final

```bash
# Verificar todos los pods
kubectl get pods -n dev

# Resultado esperado (11/11 servicios):
# NAME                                 READY   STATUS    RESTARTS   AGE
# api-gateway-96d8cd7df-kvglq          1/1     Running   0          4m
# cloud-config-6bf65c6667-k4kzx        1/1     Running   0          15h
# favourite-service-67bff5cc9c-pr46c   1/1     Running   0          3h
# order-service-59bcd5669f-wvws4       1/1     Running   0          11h
# payment-service-96f88d57b-rn9sn      1/1     Running   0          11h
# postgres-0                           1/1     Running   0          14h
# product-service-5b5b9c599c-zpzt8     1/1     Running   0          11h
# proxy-client-7486dc6984-rqgpz        1/1     Running   0          4h
# service-discovery-c5c669f7c-86dp4    1/1     Running   0          14h
# shipping-service-6f585f6556-wkc9w    1/1     Running   0          11h
# user-service-658947cdcd-n48zs        1/1     Running   0          12h

# Obtener IP externa del API Gateway
kubectl get svc -n dev api-gateway

# NAME          TYPE           CLUSTER-IP       EXTERNAL-IP    PORT(S)        AGE
# api-gateway   LoadBalancer   34.118.237.222   34.31.129.29   80:30471/TCP   4m

# Probar acceso externo
curl http://34.31.129.29/actuator/health
```

### 12.7 Tabla de Servicios Completa

| Servicio | Puerto | Tipo | IP Externa | Estado |
|----------|--------|------|------------|--------|
| service-discovery | 8761 | ClusterIP | - | ✅ Running |
| cloud-config | 9296 | ClusterIP | - | ✅ Running |
| postgres | 5432 | ClusterIP | - | ✅ Running |
| user-service | 8100 | ClusterIP | - | ✅ Running |
| product-service | 8500 | ClusterIP | - | ✅ Running |
| order-service | 8300 | ClusterIP | - | ✅ Running |
| payment-service | 8400 | ClusterIP | - | ✅ Running |
| shipping-service | 8600 | ClusterIP | - | ✅ Running |
| favourite-service | 8800 | ClusterIP | - | ✅ Running |
| proxy-client | 8900 | ClusterIP | - | ✅ Running |
| api-gateway | 8080 | LoadBalancer | 34.31.129.29 | ✅ Running |

### 12.8 Troubleshooting Específico

#### Pod en Pending por CPU

```bash
# Síntoma
kubectl get pods -n dev
# proxy-client-xxxxx   0/1     Pending   0          5m

# Diagnóstico
kubectl describe pod -n dev proxy-client-xxxxx
# Events: 0/5 nodes are available: 5 Insufficient cpu

# Solución
gcloud container clusters update ecommerce-cluster \
    --zone=us-central1-a \
    --max-nodes=8

# Verificar autoscaling
kubectl get nodes -w
```

#### Health Checks con 404

```bash
# Síntoma
kubectl describe pod -n dev proxy-client-xxxxx
# Events: Liveness probe failed: HTTP probe failed with statuscode: 404

# Diagnóstico - verificar contexto de la aplicación
kubectl logs -n dev proxy-client-xxxxx | grep "Tomcat initialized"
# Tomcat initialized with port(s): 8900 (http)
# Initializing Spring embedded WebApplicationContext
# Root WebApplicationContext: initialization at [/app]

# Solución - actualizar path del health check
# Cambiar /actuator/health → /app/actuator/health
```

#### Pod Duplicado con InvalidImageName

```bash
# Síntoma
kubectl get pods -n dev
# favourite-service-8dfbcb68-24rsm    1/1     Running          0          50m
# favourite-service-99766fdcc-b8fjj   0/1     InvalidImageName 0          10m

# Diagnóstico
kubectl describe pod -n dev favourite-service-99766fdcc-b8fjj | grep Image
# Image: gcr.io/PROJECT_ID/favourite-service:latest  # ❌ Literal

# Solución
export PROJECT_ID=$(gcloud config get-value project)
sed "s/PROJECT_ID/$PROJECT_ID/g" k8s/deployments/favourite-service.yaml | kubectl apply -f -
kubectl delete pod -n dev favourite-service-99766fdcc-b8fjj
```

### 12.9 Restauración de Recursos

Después de escalar el clúster, se pueden restaurar los recursos de favourite-service:

```yaml
# k8s/deployments/favourite-service.yaml
resources:
  requests:
    memory: "512Mi"    # Aumentado de 256Mi
    cpu: "250m"        # Aumentado de 100m
  limits:
    memory: "1Gi"
    cpu: "500m"

# Ajustar startup probe para tiempo reducido
startupProbe:
  httpGet:
    path: /actuator/health/liveness
    port: 8800
  initialDelaySeconds: 60
  periodSeconds: 10
  failureThreshold: 30  # Reducido de 50 (tiempo esperado ~120s vs 337s)
```

---

## 13. Próximos Pasos

1. ✅ Desplegar servicios de negocio (product, order, payment, shipping, favourite)
2. ✅ Desplegar proxy-client con health checks corregidos
3. ✅ Desplegar API Gateway con LoadBalancer y acceso externo
4. ✅ Escalar clúster para recursos adecuados (max-nodes: 5→8)
5. Implementar Network Policies
6. Configurar Ingress Controller
7. Implementar Prometheus + Grafana para monitoreo
8. Configurar CI/CD con GitHub Actions
9. Implementar Horizontal Pod Autoscaler

---

## Variables de Entorno Importantes

```bash
# Guardar en ~/.zshrc o ~/.bashrc
export PROJECT_ID=$(gcloud config get-value project)
export CLUSTER_NAME="ecommerce-cluster"
export CLUSTER_ZONE="us-central1-a"
```

---

## Referencias

- [Google Kubernetes Engine Docs](https://cloud.google.com/kubernetes-engine/docs)
- [Kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [Spring Boot with PostgreSQL](https://www.baeldung.com/spring-boot-postgresql-docker)
- [Flyway Database Migrations](https://flywaydb.org/documentation/)

---

**Última actualización:** 24 de noviembre de 2025
**Versión:** 2.1
**Estado:** ✅ Despliegue completo (11/11 microservicios)

---

## Actualización de Versión

**v2.1 - 24 de noviembre de 2025:**
- ✅ Sección 12 agregada: Despliegue de proxy-client y api-gateway
- ✅ Documentación de escalado del clúster (max-nodes: 5→8)
- ✅ Solución a health checks con contexto /app
- ✅ Corrección de pods duplicados por InvalidImageName
- ✅ Configuración de LoadBalancer para acceso externo
- ✅ Sistema completo: 11/11 microservicios desplegados

**v2.0 - 24 de noviembre de 2025:**
- ✅ Sección 11 agregada: Despliegue automatizado de microservicios de negocio
- ✅ Documentación de troubleshooting para CrashLoopBackOff
- ✅ Configuración de startupProbe para aplicaciones de arranque lento
- ✅ Script de despliegue automatizado (build-and-deploy-all.sh)
- ✅ 9 microservicios desplegados y verificados en GKE
- ✅ Resolución de problemas de recursos (CPU/Memory) en el clúster
