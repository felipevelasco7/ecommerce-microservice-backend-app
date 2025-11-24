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

## Próximos Pasos

1. Desplegar servicios de negocio restantes (product, order, payment, shipping, favourite)
2. Configurar API Gateway
3. Implementar Network Policies
4. Configurar Ingress Controller
5. Implementar Prometheus + Grafana para monitoreo
6. Configurar CI/CD con GitHub Actions
7. Implementar Horizontal Pod Autoscaler

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
**Versión:** 1.0
**Estado:** ✅ Probado y funcionando
