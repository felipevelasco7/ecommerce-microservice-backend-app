# 🚀 GUÍA DE DESPLIEGUE COMPLETO - E-COMMERCE MICROSERVICES PLATFORM
## Guía Unificada para Recrear el Proyecto desde Cero

### 🎯 **Información del Proyecto**
- **Nombre:** E-commerce Microservices Platform
- **Universidad:** Icesi - Cali, Colombia
- **Curso:** Plataformas Computacionales 2
- **Desarrollador:** Felipe Velasco
- **Fecha:** Noviembre 2025

## 📋 PREREQUISITOS COMPLETOS

### ☁️ **Requerimientos de Infraestructura**
- **Google Cloud Platform Account** con billing habilitado ($50-100/mes estimado)
- **Kubernetes CLI (kubectl)** v1.24+
- **Google Cloud SDK (gcloud)** instalado y configurado
- **Helm** v3.8+ para gestión de paquetes Kubernetes
- **Docker** para builds locales (opcional)
- **Git** para clonar el repositorio
- **Terminal bash/zsh** (Linux/macOS) o PowerShell (Windows)

### 💻 **Recursos de Hardware Recomendados**
- **Cluster GKE:** 8 nodos e2-medium (2 vCPU, 4GB RAM cada uno)
- **Networking:** VPC nativo con subredes privadas
- **Storage:** 100GB SSD para volúmenes persistentes
- **Registry:** Google Container Registry habilitado
- **Load Balancer:** Para acceso externo a servicios

### 🛠️ **Herramientas de Desarrollo (Opcional)**
- **IDE:** IntelliJ IDEA, VS Code, o Eclipse
- **Java:** JDK 11 para desarrollo local
- **Maven:** Para builds locales
- **Postman:** Para testing de APIs

---

## 🎯 PASO 1: PREPARACIÓN DEL ENTORNO

### 1.1 Instalación de Herramientas (macOS/Linux)

```bash
# 1. Instalar Google Cloud SDK
curl https://sdk.cloud.google.com | bash
exec -l $SHELL

# 2. Instalar kubectl
gcloud components install kubectl

# 3. Instalar Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# 4. Verificar instalaciones
gcloud --version
kubectl version --client
helm version
```

### 1.2 Configuración de Google Cloud

```bash
# 1. Autenticación en Google Cloud
gcloud auth login
gcloud auth application-default login

# 2. Crear y configurar proyecto
export PROJECT_ID="ecommerce-microservices-$(date +%s)"
gcloud projects create $PROJECT_ID --name="E-commerce Microservices"
gcloud config set project $PROJECT_ID

# 3. Habilitar billing (requerido para GKE)
# Nota: Debes habilitar billing manualmente en la consola de GCP

# 4. Habilitar APIs necesarias
gcloud services enable container.googleapis.com
gcloud services enable containerregistry.googleapis.com
gcloud services enable compute.googleapis.com
gcloud services enable monitoring.googleapis.com
gcloud services enable cloudbuild.googleapis.com

# 5. Configurar región y zona por defecto
gcloud config set compute/region us-central1
gcloud config set compute/zone us-central1-a

# 6. Verificar configuración
gcloud config list
```

### 1.3 Clonar y Preparar el Repositorio

```bash
# 1. Clonar el repositorio del proyecto
git clone https://github.com/felipevelasco7/ecommerce-microservice-backend-app.git
cd ecommerce-microservice-backend-app

# 2. Verificar estructura completa del proyecto
ls -la
# Deberías ver: microservices/, k8s/, helm/, .github/workflows/, docs/, scripts/, etc.

# 3. Configurar variables de entorno globales
export CLUSTER_NAME="ecommerce-cluster"
export REGION="us-central1-a"
export ZONE="us-central1-a"
export REGISTRY="gcr.io/$PROJECT_ID"
export NAMESPACE_DEV="dev"
export NAMESPACE_MONITORING="monitoring"

# 4. Crear archivo de variables para persistencia
cat > .env <<EOF
PROJECT_ID=$PROJECT_ID
CLUSTER_NAME=$CLUSTER_NAME
REGION=$REGION
ZONE=$ZONE
REGISTRY=$REGISTRY
NAMESPACE_DEV=$NAMESPACE_DEV
NAMESPACE_MONITORING=$NAMESPACE_MONITORING
EOF

echo "✅ Variables configuradas correctamente"
echo "📁 Estructura del proyecto verificada"
echo "🔧 Listo para crear el cluster GKE"
```

### 1.4 Estructura del Proyecto (Referencia)

```
📦 ecommerce-microservice-backend-app/
├── 📁 microservices/              # Código fuente de todos los microservicios
│   ├── api-gateway/               # Gateway principal (Puerto 80)
│   ├── user-service/              # Gestión de usuarios (Puerto 8700)
│   ├── product-service/           # Catálogo de productos (Puerto 8500)
│   ├── order-service/             # Procesamiento de pedidos (Puerto 8300)
│   ├── payment-service/           # Procesamiento de pagos (Puerto 8400)
│   ├── shipping-service/          # Gestión de envíos (Puerto 8600)
│   ├── favourite-service/         # Lista de favoritos (Puerto 8800)
│   ├── service-discovery/         # Eureka Server (Puerto 8761)
│   ├── cloud-config/              # Configuración centralizada (Puerto 9296)
│   ├── proxy-client/              # Proxy cliente (Puerto 8900)
│   └── frontend/                  # Interfaz web (Puerto 80)
├── 📁 k8s/                        # Manifiestos de Kubernetes
│   ├── deployments/               # Deployments por microservicio
│   ├── services/                  # Services de Kubernetes
│   ├── configmaps/               # Configuraciones
│   ├── secrets/                   # Secretos
│   ├── monitoring/                # Stack de monitoreo
│   ├── autoscaling/              # HPA y KEDA
│   ├── network-policies/          # Políticas de red
│   └── namespaces/               # Definición de namespaces
├── 📁 scripts/                    # Scripts de automatización
│   ├── deployment/               # Scripts de despliegue
│   ├── testing/                  # Scripts de testing
│   └── management/               # Scripts de gestión
├── 📁 docs/                       # Documentación completa
├── 📁 .github/workflows/          # Pipelines CI/CD
└── 📄 README.md                   # Documentación principal
```

---

## 🏗️ PASO 2: CREACIÓN DEL CLUSTER GKE

### 2.1 Crear Cluster Kubernetes con Configuración Completa

```bash
# 1. Cargar variables de entorno
source .env

# 2. Crear cluster GKE con configuración optimizada para microservicios
gcloud container clusters create $CLUSTER_NAME \
    --zone=$ZONE \
    --num-nodes=8 \
    --machine-type=e2-medium \
    --disk-size=50GB \
    --disk-type=pd-ssd \
    --enable-autorepair \
    --enable-autoupgrade \
    --enable-autoscaling \
    --min-nodes=6 \
    --max-nodes=12 \
    --enable-network-policy \
    --enable-ip-alias \
    --enable-monitoring \
    --enable-logging \
    --enable-cloud-logging \
    --enable-cloud-monitoring \
    --addons=HorizontalPodAutoscaling,HttpLoadBalancing,NodeLocalDNS \
    --workload-pool=$PROJECT_ID.svc.id.goog

echo "⏱️  Creación del cluster en progreso... (5-7 minutos)"

# 3. Obtener credenciales del cluster
gcloud container clusters get-credentials $CLUSTER_NAME --zone=$ZONE

# 4. Verificar conectividad y estado
kubectl cluster-info
kubectl get nodes -o wide

# 5. Verificar que tienes 8 nodos listos
echo "✅ Verificando que todos los nodos estén Ready:"
kubectl get nodes | grep Ready | wc -l
# Debe mostrar: 8
```

### 2.2 Configurar Contexto y Permisos

```bash
# 1. Configurar contexto actual
kubectl config current-context

# 2. Crear ClusterRoleBinding para admin
kubectl create clusterrolebinding cluster-admin-binding \
    --clusterrole=cluster-admin \
    --user=$(gcloud config get-value account)

# 3. Verificar permisos
kubectl auth can-i create pods --all-namespaces
kubectl auth can-i create deployments --all-namespaces

# 4. Configurar Docker para Google Container Registry
gcloud auth configure-docker

echo "✅ Cluster GKE creado y configurado exitosamente"
echo "📊 Nodos disponibles: $(kubectl get nodes --no-headers | wc -l)"
echo "🔧 Listo para el siguiente paso: Namespaces"
```

### 2.2 Configurar Permisos de Usuario

```bash
# 1. Obtener tu email de Google Cloud
export USER_EMAIL=$(gcloud config get-value account)

# 2. Crear ClusterRoleBinding para admin
kubectl create clusterrolebinding cluster-admin-binding \
    --clusterrole=cluster-admin \
    --user=$USER_EMAIL

# 3. Verificar permisos
kubectl auth can-i create pods --all-namespaces
```

---

## 📦 PASO 3: CONFIGURACIÓN DE NAMESPACES Y BASE

### 3.1 Crear Estructura de Namespaces

```bash
# 1. Crear todos los namespaces necesarios
kubectl apply -f k8s/namespaces/

# 2. Si no existen los archivos, crearlos:
mkdir -p k8s/namespaces
cat > k8s/namespaces/all-namespaces.yaml <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: dev
  labels:
    environment: development
    pod-security.kubernetes.io/enforce: baseline
    pod-security.kubernetes.io/audit: baseline
    pod-security.kubernetes.io/warn: baseline
---
apiVersion: v1
kind: Namespace
metadata:
  name: monitoring
  labels:
    environment: monitoring
---
apiVersion: v1
kind: Namespace
metadata:
  name: logging
  labels:
    environment: logging
---
apiVersion: v1
kind: Namespace
metadata:
  name: keda
  labels:
    environment: autoscaling
---
apiVersion: v1
kind: Namespace
metadata:
  name: sealed-secrets
  labels:
    environment: security
---
apiVersion: v1
kind: Namespace
metadata:
  name: ingress-nginx
  labels:
    environment: networking
EOF

# 3. Aplicar la configuración
kubectl apply -f k8s/namespaces/all-namespaces.yaml

# 4. Verificar creación y etiquetas
kubectl get namespaces --show-labels

echo "✅ Namespaces creados exitosamente:"
kubectl get namespaces | grep -E "(dev|monitoring|logging|keda|sealed-secrets|ingress-nginx)"
```

### 3.2 Instalar Ingress Controller

```bash
# 1. Agregar repositorio Helm de Nginx
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

# 2. Instalar Nginx Ingress Controller
helm install ingress-nginx ingress-nginx/ingress-nginx \
    --namespace ingress-nginx \
    --create-namespace \
    --set controller.service.type=LoadBalancer

# 3. Esperar a que esté listo
kubectl wait --namespace ingress-nginx \
    --for=condition=ready pod \
    --selector=app.kubernetes.io/component=controller \
    --timeout=300s

# 4. Obtener IP externa
kubectl get svc -n ingress-nginx ingress-nginx-controller
```

### 3.3 Instalar Helm Repositories

```bash
# Agregar todos los repos necesarios
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo add kedacore https://kedacore.github.io/charts
helm repo add sealed-secrets https://bitnami-labs.github.io/sealed-secrets
helm repo update
```

---

## 🔐 PASO 4: CONFIGURACIÓN DE SEGURIDAD

### 4.1 Aplicar Pod Security Standards

```bash
# Aplicar políticas de seguridad
kubectl apply -f k8s/security/pod-security-standards.yaml

# Verificar aplicación
kubectl get namespaces --show-labels
```

### 4.2 Instalar Sealed Secrets

```bash
# 1. Instalar Sealed Secrets Controller
helm install sealed-secrets sealed-secrets/sealed-secrets \
    --namespace sealed-secrets \
    --create-namespace

# 2. Verificar instalación
kubectl get pods -n sealed-secrets
kubectl logs -n sealed-secrets deployment/sealed-secrets-controller
```

### 4.3 Aplicar Network Policies

```bash
# Aplicar políticas de red
kubectl apply -f k8s/security/network-policies.yaml

# Verificar políticas
kubectl get networkpolicy -n dev
```

### 4.4 Configurar RBAC

```bash
# Aplicar roles y bindings
kubectl apply -f k8s/rbac/

# Verificar RBAC
kubectl get clusterroles | grep ecommerce
kubectl get rolebindings -n dev
```

---

## 📊 PASO 5: DESPLIEGUE DEL STACK DE MONITOREO

### 5.1 Instalar Prometheus

```bash
# 1. Instalar Prometheus con configuración personalizada
helm install prometheus prometheus-community/kube-prometheus-stack \
    --namespace monitoring \
    --create-namespace \
    --values k8s/monitoring/prometheus-values.yaml

# 2. Verificar instalación
kubectl get pods -n monitoring
kubectl get svc -n monitoring
```

### 5.2 Configurar Grafana

```bash
# 1. Obtener password de admin de Grafana
kubectl get secret -n monitoring prometheus-grafana \
    -o jsonpath="{.data.admin-password}" | base64 --decode
echo

# 2. Hacer port-forward para acceder (opcional)
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80 &

# 3. Aplicar dashboards personalizados
kubectl apply -f k8s/monitoring/grafana-dashboards/
```

### 5.3 Instalar Sistema de Logging

```bash
# 1. Aplicar configuración de Loki
kubectl apply -f k8s/monitoring/loki-deployment.yaml

# 2. Aplicar DaemonSet de Promtail
kubectl apply -f k8s/monitoring/promtail-simple.yaml

# 3. Verificar logging stack
kubectl get pods -n logging
kubectl logs -n logging deployment/loki
```

---

## ⚡ PASO 6: CONFIGURACIÓN DE AUTOSCALING

### 6.1 Instalar KEDA

```bash
# 1. Instalar KEDA vía Helm
helm install keda kedacore/keda \
    --namespace keda \
    --create-namespace

# 2. Verificar instalación
kubectl get pods -n keda
kubectl get crd | grep keda
```

### 6.2 Configurar Metrics Server (si no está instalado)

```bash
# Verificar si metrics server existe
kubectl get deployment metrics-server -n kube-system

# Si no existe, instalarlo
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

---

## 🗄️ PASO 7: CONFIGURACIÓN DE ALMACENAMIENTO

### 7.1 Crear StorageClass

```bash
# Aplicar StorageClass personalizada
kubectl apply -f k8s/storage/gke-storage-class.yaml

# Verificar creación
kubectl get storageclass
```

### 7.2 Crear Persistent Volumes

```bash
# Aplicar PVs y PVCs
kubectl apply -f k8s/storage/

# Verificar volúmenes
kubectl get pv,pvc -A
```

---

## 🚀 PASO 8: DESPLIEGUE COMPLETO DE MICROSERVICIOS

### 8.1 Crear Base de Datos PostgreSQL

```bash
# 1. Crear ConfigMap para PostgreSQL
cat > k8s/deployments/postgres.yaml <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: postgres-config
  namespace: dev
data:
  POSTGRES_DB: ecommerce_db
  POSTGRES_USER: ecommerce
---
apiVersion: v1
kind: Secret
metadata:
  name: postgres-secret
  namespace: dev
type: Opaque
data:
  POSTGRES_PASSWORD: ZWNvbW1lcmNlMTIz  # ecommerce123 en base64
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-pvc
  namespace: dev
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
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
          name: postgres
        env:
        - name: POSTGRES_DB
          valueFrom:
            configMapKeyRef:
              name: postgres-config
              key: POSTGRES_DB
        - name: POSTGRES_USER
          valueFrom:
            configMapKeyRef:
              name: postgres-config
              key: POSTGRES_USER
        - name: POSTGRES_PASSWORD
          valueFrom:
            secretKeyRef:
              name: postgres-secret
              key: POSTGRES_PASSWORD
        volumeMounts:
        - name: postgres-storage
          mountPath: /var/lib/postgresql/data
        resources:
          requests:
            memory: "512Mi"
            cpu: "250m"
          limits:
            memory: "1Gi"
            cpu: "500m"
      volumes:
      - name: postgres-storage
        persistentVolumeClaim:
          claimName: postgres-pvc
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
  type: ClusterIP
EOF

# 2. Desplegar PostgreSQL
kubectl apply -f k8s/deployments/postgres.yaml

# 3. Esperar a que PostgreSQL esté listo
echo "⏱️ Esperando que PostgreSQL esté listo..."
kubectl wait --for=condition=ready pod -l app=postgres -n dev --timeout=300s

# 4. Verificar PostgreSQL
kubectl get pods -n dev -l app=postgres
kubectl logs -n dev -l app=postgres --tail=10

echo "✅ PostgreSQL desplegado exitosamente"
```

### 8.2 Aplicar ConfigMaps y Secrets para Microservicios

```bash
# 1. Crear directorio si no existe
mkdir -p k8s/configmaps k8s/secrets

# 2. Aplicar todas las configuraciones existentes
if [ -d "k8s/configmaps" ] && [ "$(ls -A k8s/configmaps)" ]; then
    kubectl apply -f k8s/configmaps/
fi

# 3. Crear secrets básicos si no existen
kubectl create secret generic database-credentials \
    --from-literal=username=ecommerce \
    --from-literal=password=ecommerce123 \
    --namespace=dev \
    --dry-run=client -o yaml | kubectl apply -f -

# 4. Verificar configuraciones
kubectl get configmaps -n dev
kubectl get secrets -n dev

echo "✅ ConfigMaps y Secrets configurados"
```

### 8.3 Construir y Desplegar Todos los Microservicios

```bash
# 1. Script automático para construir todas las imágenes Docker
echo "🔨 Construyendo todas las imágenes Docker..."

# Lista de servicios en orden de dependencias
SERVICES=(
    "service-discovery:8761"
    "cloud-config:9296" 
    "user-service:8700"
    "product-service:8500"
    "order-service:8300"
    "payment-service:8400"
    "shipping-service:8600"
    "favourite-service:8800"
    "proxy-client:8900"
    "api-gateway:8080"
    "frontend:80"
)

# 2. Construir imágenes usando Cloud Build
for service_info in "${SERVICES[@]}"; do
    service_name="${service_info%:*}"
    port="${service_info#*:}"
    
    echo "🔨 Construyendo $service_name..."
    
    # Crear cloudbuild.yaml dinámicamente
    cat > cloudbuild-$service_name.yaml <<EOF
steps:
  - name: 'gcr.io/cloud-builders/mvn'
    args: ['clean', 'package', '-DskipTests', '-f', '$service_name/pom.xml']
  - name: 'gcr.io/cloud-builders/docker'
    args: ['build', '-t', 'gcr.io/$PROJECT_ID/$service_name:latest', 
           '-t', 'gcr.io/$PROJECT_ID/$service_name:1.0.0', 
           '-f', '$service_name/Dockerfile', '.']

images:
  - 'gcr.io/$PROJECT_ID/$service_name:latest'
  - 'gcr.io/$PROJECT_ID/$service_name:1.0.0'

timeout: 1200s
options:
  machineType: 'E2_HIGHCPU_8'
  diskSizeGb: 100
EOF
    
    # Construir imagen
    gcloud builds submit --config=cloudbuild-$service_name.yaml . &
done

# 3. Esperar a que todas las construcciones terminen
wait
echo "✅ Todas las imágenes construidas exitosamente"

# 4. Verificar imágenes en el registry
gcloud container images list --repository=gcr.io/$PROJECT_ID
```

### 8.4 Desplegar Servicios de Infraestructura

```bash
# 1. Service Discovery (Eureka Server)
echo "🚀 Desplegando Service Discovery (Eureka)..."

cat > k8s/deployments/service-discovery.yaml <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: service-discovery
  namespace: dev
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
        image: gcr.io/$PROJECT_ID/service-discovery:latest
        ports:
        - containerPort: 8761
        env:
        - name: SPRING_PROFILES_ACTIVE
          value: "dev"
        resources:
          requests:
            memory: "512Mi"
            cpu: "250m"
          limits:
            memory: "1Gi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /actuator/health
            port: 8761
          initialDelaySeconds: 120
          periodSeconds: 30
        readinessProbe:
          httpGet:
            path: /actuator/health
            port: 8761
          initialDelaySeconds: 60
          periodSeconds: 10
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
  - port: 8761
    targetPort: 8761
  type: ClusterIP
EOF

kubectl apply -f k8s/deployments/service-discovery.yaml

# 2. Cloud Config Server
echo "🚀 Desplegando Cloud Config Server..."

cat > k8s/deployments/cloud-config.yaml <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cloud-config
  namespace: dev
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
        image: gcr.io/$PROJECT_ID/cloud-config:latest
        ports:
        - containerPort: 9296
        env:
        - name: SPRING_PROFILES_ACTIVE
          value: "dev"
        - name: EUREKA_CLIENT_SERVICE_URL_DEFAULTZONE
          value: "http://service-discovery:8761/eureka/"
        resources:
          requests:
            memory: "512Mi"
            cpu: "250m"
          limits:
            memory: "1Gi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /actuator/health
            port: 9296
          initialDelaySeconds: 120
          periodSeconds: 30
        readinessProbe:
          httpGet:
            path: /actuator/health
            port: 9296
          initialDelaySeconds: 60
          periodSeconds: 10
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
  - port: 9296
    targetPort: 9296
  type: ClusterIP
EOF

kubectl apply -f k8s/deployments/cloud-config.yaml

# 3. Esperar a que los servicios base estén listos
echo "⏱️ Esperando que los servicios de infraestructura estén listos..."
kubectl wait --for=condition=ready pod -l app=service-discovery -n dev --timeout=300s
kubectl wait --for=condition=ready pod -l app=cloud-config -n dev --timeout=300s

echo "✅ Servicios de infraestructura desplegados exitosamente"
```

### 8.5 Desplegar Microservicios de Negocio

```bash
# Script para desplegar todos los microservicios de negocio
echo "🚀 Desplegando microservicios de negocio..."

# Función para crear deployment genérico
create_microservice_deployment() {
    local service=$1
    local port=$2
    local db_name=$3
    
    cat > k8s/deployments/$service.yaml <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $service
  namespace: dev
spec:
  replicas: 1
  selector:
    matchLabels:
      app: $service
  template:
    metadata:
      labels:
        app: $service
    spec:
      initContainers:
      - name: wait-for-eureka
        image: curlimages/curl:latest
        command: ['sh', '-c']
        args:
          - |
            echo "Esperando Service Discovery..."
            until curl -f http://service-discovery:8761/actuator/health; do
              echo "Service Discovery no disponible, esperando..."
              sleep 10
            done
            echo "Service Discovery disponible!"
      - name: wait-for-postgres
        image: postgres:13-alpine
        command: ['sh', '-c']
        args:
          - |
            echo "Esperando PostgreSQL..."
            until pg_isready -h postgres -p 5432 -U ecommerce; do
              echo "PostgreSQL no disponible, esperando..."
              sleep 5
            done
            echo "PostgreSQL disponible!"
        env:
        - name: PGPASSWORD
          valueFrom:
            secretKeyRef:
              name: postgres-secret
              key: POSTGRES_PASSWORD
      containers:
      - name: $service
        image: gcr.io/$PROJECT_ID/$service:latest
        ports:
        - containerPort: $port
        env:
        - name: SPRING_PROFILES_ACTIVE
          value: "dev"
        - name: EUREKA_CLIENT_SERVICE_URL_DEFAULTZONE
          value: "http://service-discovery:8761/eureka/"
        - name: SPRING_CONFIG_IMPORT
          value: "optional:configserver:http://cloud-config:9296/"
        - name: SPRING_DATASOURCE_URL
          value: "jdbc:postgresql://postgres:5432/$db_name"
        - name: SPRING_DATASOURCE_USERNAME
          value: "ecommerce"
        - name: SPRING_DATASOURCE_PASSWORD
          valueFrom:
            secretKeyRef:
              name: postgres-secret
              key: POSTGRES_PASSWORD
        resources:
          requests:
            memory: "512Mi"
            cpu: "250m"
          limits:
            memory: "1Gi"
            cpu: "500m"
        startupProbe:
          httpGet:
            path: /actuator/health
            port: $port
          initialDelaySeconds: 60
          periodSeconds: 10
          failureThreshold: 30
        livenessProbe:
          httpGet:
            path: /actuator/health
            port: $port
          initialDelaySeconds: 120
          periodSeconds: 30
          failureThreshold: 3
        readinessProbe:
          httpGet:
            path: /actuator/health
            port: $port
          initialDelaySeconds: 60
          periodSeconds: 10
          failureThreshold: 3
---
apiVersion: v1
kind: Service
metadata:
  name: $service
  namespace: dev
spec:
  selector:
    app: $service
  ports:
  - port: $port
    targetPort: $port
  type: ClusterIP
EOF
}

# Crear y desplegar cada microservicio
BUSINESS_SERVICES=(
    "user-service:8700:user_db"
    "product-service:8500:product_db"
    "order-service:8300:order_db"
    "payment-service:8400:payment_db"
    "shipping-service:8600:shipping_db"
    "favourite-service:8800:favourite_db"
)

for service_info in "${BUSINESS_SERVICES[@]}"; do
    IFS=':' read -r service port db_name <<< "$service_info"
    
    echo "🚀 Desplegando $service en puerto $port con base de datos $db_name..."
    
    # Crear base de datos si no existe
    kubectl exec -n dev postgres-0 -- psql -U ecommerce -d postgres -c "CREATE DATABASE $db_name;" 2>/dev/null || echo "Base de datos $db_name ya existe"
    
    # Crear deployment
    create_microservice_deployment $service $port $db_name
    kubectl apply -f k8s/deployments/$service.yaml
    
    # Esperar a que esté listo antes del siguiente
    echo "⏱️ Esperando que $service esté listo..."
    kubectl wait --for=condition=ready pod -l app=$service -n dev --timeout=600s
    
    echo "✅ $service desplegado exitosamente"
done

echo "🎉 Todos los microservicios de negocio desplegados exitosamente"
```

### 8.6 Desplegar Gateway y Frontend

```bash
# 1. Desplegar Proxy Client
echo "🚀 Desplegando Proxy Client..."

cat > k8s/deployments/proxy-client.yaml <<EOF
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
      containers:
      - name: proxy-client
        image: gcr.io/$PROJECT_ID/proxy-client:latest
        ports:
        - containerPort: 8900
        env:
        - name: SPRING_PROFILES_ACTIVE
          value: "dev"
        - name: EUREKA_CLIENT_SERVICE_URL_DEFAULTZONE
          value: "http://service-discovery:8761/eureka/"
        resources:
          requests:
            memory: "256Mi"
            cpu: "100m"
          limits:
            memory: "512Mi"
            cpu: "250m"
        startupProbe:
          httpGet:
            path: /actuator/health
            port: 8900
          initialDelaySeconds: 60
          periodSeconds: 10
          failureThreshold: 20
        livenessProbe:
          httpGet:
            path: /actuator/health
            port: 8900
          initialDelaySeconds: 120
          periodSeconds: 30
        readinessProbe:
          httpGet:
            path: /actuator/health
            port: 8900
          initialDelaySeconds: 60
          periodSeconds: 10
---
apiVersion: v1
kind: Service
metadata:
  name: proxy-client
  namespace: dev
spec:
  selector:
    app: proxy-client
  ports:
  - port: 8900
    targetPort: 8900
  type: ClusterIP
EOF

kubectl apply -f k8s/deployments/proxy-client.yaml

# 2. Desplegar API Gateway con LoadBalancer
echo "🚀 Desplegando API Gateway..."

cat > k8s/deployments/api-gateway.yaml <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-gateway
  namespace: dev
spec:
  replicas: 2
  selector:
    matchLabels:
      app: api-gateway
  template:
    metadata:
      labels:
        app: api-gateway
    spec:
      containers:
      - name: api-gateway
        image: gcr.io/$PROJECT_ID/api-gateway:latest
        ports:
        - containerPort: 8080
        env:
        - name: SPRING_PROFILES_ACTIVE
          value: "dev"
        - name: EUREKA_CLIENT_SERVICE_URL_DEFAULTZONE
          value: "http://service-discovery:8761/eureka/"
        - name: SPRING_CONFIG_IMPORT
          value: "optional:configserver:http://cloud-config:9296/"
        resources:
          requests:
            memory: "512Mi"
            cpu: "250m"
          limits:
            memory: "1Gi"
            cpu: "500m"
        startupProbe:
          httpGet:
            path: /actuator/health
            port: 8080
          initialDelaySeconds: 60
          periodSeconds: 10
          failureThreshold: 20
        livenessProbe:
          httpGet:
            path: /actuator/health
            port: 8080
          initialDelaySeconds: 120
          periodSeconds: 30
        readinessProbe:
          httpGet:
            path: /actuator/health
            port: 8080
          initialDelaySeconds: 60
          periodSeconds: 10
---
apiVersion: v1
kind: Service
metadata:
  name: api-gateway
  namespace: dev
spec:
  selector:
    app: api-gateway
  ports:
  - port: 80
    targetPort: 8080
  type: LoadBalancer
EOF

kubectl apply -f k8s/deployments/api-gateway.yaml

# 3. Desplegar Frontend
echo "🚀 Desplegando Frontend..."

cat > k8s/deployments/frontend.yaml <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
  namespace: dev
spec:
  replicas: 2
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
      - name: frontend
        image: gcr.io/$PROJECT_ID/frontend:latest
        ports:
        - containerPort: 80
        resources:
          requests:
            memory: "128Mi"
            cpu: "50m"
          limits:
            memory: "256Mi"
            cpu: "100m"
---
apiVersion: v1
kind: Service
metadata:
  name: frontend
  namespace: dev
spec:
  selector:
    app: frontend
  ports:
  - port: 80
    targetPort: 80
  type: LoadBalancer
EOF

kubectl apply -f k8s/deployments/frontend.yaml

# 4. Esperar a que todos estén listos
echo "⏱️ Esperando que Gateway y Frontend estén listos..."
kubectl wait --for=condition=ready pod -l app=proxy-client -n dev --timeout=300s
kubectl wait --for=condition=ready pod -l app=api-gateway -n dev --timeout=300s
kubectl wait --for=condition=ready pod -l app=frontend -n dev --timeout=300s

echo "✅ Gateway y Frontend desplegados exitosamente"
```

---

## ⚙️ PASO 9: CONFIGURACIÓN COMPLETA DE AUTOSCALING

### 9.1 Instalar y Configurar KEDA

```bash
# 1. Instalar KEDA para autoscaling event-driven
helm repo add kedacore https://kedacore.github.io/charts
helm repo update

helm install keda kedacore/keda \
    --namespace keda \
    --create-namespace \
    --set prometheus.metricServer.enabled=true \
    --set prometheus.operator.enabled=true

# 2. Verificar instalación de KEDA
kubectl get pods -n keda
kubectl get crd | grep keda

echo "✅ KEDA instalado exitosamente"
```

### 9.2 Configurar Horizontal Pod Autoscalers (HPA)

```bash
# 1. Verificar que Metrics Server esté funcionando
kubectl get deployment metrics-server -n kube-system

# 2. Crear HPAs para los microservicios principales
cat > k8s/autoscaling/microservices-hpa.yaml <<EOF
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: api-gateway-hpa
  namespace: dev
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: api-gateway
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 60
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 75
---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: user-service-hpa
  namespace: dev
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: user-service
  minReplicas: 1
  maxReplicas: 5
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: product-service-hpa
  namespace: dev
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: product-service
  minReplicas: 1
  maxReplicas: 5
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: order-service-hpa
  namespace: dev
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: order-service
  minReplicas: 1
  maxReplicas: 5
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
EOF

# 3. Aplicar HPAs
mkdir -p k8s/autoscaling
kubectl apply -f k8s/autoscaling/microservices-hpa.yaml

# 4. Verificar HPAs
kubectl get hpa -n dev
kubectl describe hpa api-gateway-hpa -n dev

echo "✅ HPAs configurados exitosamente"
```

### 9.3 Configurar KEDA ScaledObjects (Opcional - Avanzado)

```bash
# 1. Crear ScaledObjects para autoscaling basado en métricas externas
cat > k8s/autoscaling/keda-scaledobjects.yaml <<EOF
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: api-gateway-scaler
  namespace: dev
spec:
  scaleTargetRef:
    name: api-gateway
  minReplicaCount: 2
  maxReplicaCount: 10
  triggers:
  - type: prometheus
    metadata:
      serverAddress: http://prometheus-kube-prometheus-prometheus.monitoring.svc.cluster.local:9090
      metricName: http_requests_per_second
      threshold: "100"
      query: sum(rate(http_server_requests_seconds_total{job="api-gateway"}[2m]))
---
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: user-service-scaler
  namespace: dev
spec:
  scaleTargetRef:
    name: user-service
  minReplicaCount: 1
  maxReplicaCount: 5
  triggers:
  - type: prometheus
    metadata:
      serverAddress: http://prometheus-kube-prometheus-prometheus.monitoring.svc.cluster.local:9090
      metricName: jvm_memory_usage
      threshold: "0.8"
      query: jvm_memory_used_bytes{job="user-service"} / jvm_memory_max_bytes{job="user-service"}
EOF

# 2. Aplicar ScaledObjects (solo si Prometheus está configurado)
kubectl apply -f k8s/autoscaling/keda-scaledobjects.yaml

# 3. Verificar ScaledObjects
kubectl get scaledobjects -n dev
kubectl describe scaledobject api-gateway-scaler -n dev

echo "✅ KEDA ScaledObjects configurados"
```

### 9.4 Probar Autoscaling

```bash
# 1. Generar carga para probar autoscaling
API_GATEWAY_IP=$(kubectl get svc api-gateway -n dev -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

if [ ! -z "$API_GATEWAY_IP" ]; then
    echo "🧪 Generando carga para probar autoscaling..."
    
    # Instalar apache bench si no existe
    if ! command -v ab &> /dev/null; then
        echo "Instalando apache bench..."
        # En macOS: brew install httpd
        # En Ubuntu: sudo apt-get install apache2-utils
    fi
    
    # Generar carga
    ab -n 10000 -c 50 http://$API_GATEWAY_IP/actuator/health &
    
    # Monitorear HPA en tiempo real
    echo "📊 Monitoreando HPAs (Ctrl+C para parar):"
    watch -n 5 kubectl get hpa -n dev
else
    echo "⚠️ IP externa no disponible aún, inténtalo más tarde"
fi
```

---

## 🌐 PASO 10: CONFIGURACIÓN DE INGRESS

### 10.1 Aplicar Ingress Rules

```bash
# Aplicar reglas de Ingress
kubectl apply -f k8s/ingress/

# Verificar Ingress
kubectl get ingress -n dev
kubectl describe ingress ecommerce-ingress -n dev
```

### 10.2 Configurar DNS (Opcional)

```bash
# Obtener IP externa del Load Balancer
export INGRESS_IP=$(kubectl get svc -n ingress-nginx ingress-nginx-controller \
    -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

echo "Configura tu DNS para apuntar a: $INGRESS_IP"
echo "Ejemplo: api.ecommerce.local -> $INGRESS_IP"
```

---

## ✅ PASO 11: VERIFICACIÓN COMPLETA Y TESTING

### 11.1 Verificar Estado General del Sistema

```bash
# Script completo de verificación del despliegue
cat > verify-deployment.sh <<'EOF'
#!/bin/bash
echo "🔍 VERIFICACIÓN COMPLETA DEL DESPLIEGUE E-COMMERCE MICROSERVICES"
echo "=================================================================="
echo ""

# 1. Verificar cluster
echo "1️⃣ Estado del cluster:"
kubectl cluster-info --context=$(kubectl config current-context) | head -3
kubectl get nodes -o wide
echo ""

# 2. Verificar namespaces
echo "2️⃣ Namespaces del proyecto:"
kubectl get namespaces | grep -E "(dev|monitoring|logging|keda|sealed-secrets|ingress-nginx)"
echo ""

# 3. Verificar todos los pods
echo "3️⃣ Estado de todos los microservicios:"
kubectl get pods -n dev -o wide
echo ""

# 4. Contar pods por estado
RUNNING=$(kubectl get pods -n dev --no-headers | grep Running | wc -l)
PENDING=$(kubectl get pods -n dev --no-headers | grep Pending | wc -l)
ERROR=$(kubectl get pods -n dev --no-headers | grep -E "Error|CrashLoop|ImagePull" | wc -l)

echo "📊 Resumen de pods:"
echo "   ✅ Running: $RUNNING"
echo "   ⏳ Pending: $PENDING" 
echo "   ❌ Con errores: $ERROR"
echo ""

# 5. Verificar servicios y IPs externas
echo "4️⃣ Servicios y acceso externo:"
kubectl get svc -n dev
echo ""

# 6. Obtener IPs externas importantes
API_GATEWAY_IP=$(kubectl get svc api-gateway -n dev -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
FRONTEND_IP=$(kubectl get svc frontend -n dev -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)

if [ ! -z "$API_GATEWAY_IP" ]; then
    echo "🌐 API Gateway IP: $API_GATEWAY_IP"
    echo "   Prueba: curl http://$API_GATEWAY_IP/actuator/health"
fi

if [ ! -z "$FRONTEND_IP" ]; then
    echo "🌐 Frontend IP: $FRONTEND_IP"
    echo "   Acceso: http://$FRONTEND_IP"
fi
echo ""

# 7. Verificar bases de datos
echo "5️⃣ Verificando bases de datos:"
kubectl exec -n dev postgres-0 -- psql -U ecommerce -d postgres -c "\l" | grep -E "(user_db|product_db|order_db|payment_db|shipping_db|favourite_db)"
echo ""

# 8. Verificar registro en Eureka
echo "6️⃣ Verificando Service Discovery:"
echo "   Port-forward: kubectl port-forward -n dev svc/service-discovery 8761:8761"
echo "   URL: http://localhost:8761"
echo ""

# 9. Verificar recursos del cluster
echo "7️⃣ Uso de recursos:"
kubectl top nodes 2>/dev/null || echo "Metrics server no disponible"
echo ""

# 10. Mostrar eventos recientes
echo "8️⃣ Eventos recientes (últimos 10):"
kubectl get events -n dev --sort-by='.lastTimestamp' | tail -10
echo ""

echo "🎉 VERIFICACIÓN COMPLETADA"
echo "=========================="
EOF

chmod +x verify-deployment.sh
./verify-deployment.sh
```

### 11.2 Testing de Conectividad y Health Checks

```bash
# 1. Test de health endpoints de todos los servicios
echo "🧪 Testing health endpoints..."

SERVICES=(
    "service-discovery:8761"
    "cloud-config:9296"
    "user-service:8700"
    "product-service:8500"
    "order-service:8300"
    "payment-service:8400"
    "shipping-service:8600"
    "favourite-service:8800"
    "proxy-client:8900"
    "api-gateway:8080"
)

for service_info in "${SERVICES[@]}"; do
    service_name="${service_info%:*}"
    port="${service_info#*:}"
    
    echo "Testing $service_name..."
    
    # Test health endpoint
    kubectl run test-$service_name --image=curlimages/curl --rm -it --restart=Never --quiet -- \
        curl -s -f http://$service_name.$NAMESPACE_DEV.svc.cluster.local:$port/actuator/health > /dev/null
    
    if [ $? -eq 0 ]; then
        echo "✅ $service_name health check OK"
    else
        echo "❌ $service_name health check FAILED"
    fi
done

echo ""
echo "🔍 Para debugging detallado:"
echo "kubectl logs -n dev -l app=SERVICE_NAME --tail=50"
echo "kubectl describe pod -n dev POD_NAME"
```

### 11.3 Configurar Monitoreo con Zipkin

```bash
# 1. Desplegar Zipkin para tracing distribuido
echo "📊 Desplegando Zipkin para distributed tracing..."

cat > k8s/deployments/zipkin.yaml <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: zipkin
  namespace: dev
spec:
  replicas: 1
  selector:
    matchLabels:
      app: zipkin
  template:
    metadata:
      labels:
        app: zipkin
    spec:
      containers:
      - name: zipkin
        image: openzipkin/zipkin:latest
        ports:
        - containerPort: 9411
        env:
        - name: STORAGE_TYPE
          value: mem
        resources:
          requests:
            memory: "256Mi"
            cpu: "100m"
          limits:
            memory: "512Mi"
            cpu: "250m"
---
apiVersion: v1
kind: Service
metadata:
  name: zipkin
  namespace: dev
spec:
  selector:
    app: zipkin
  ports:
  - port: 9411
    targetPort: 9411
  type: LoadBalancer
EOF

kubectl apply -f k8s/deployments/zipkin.yaml

# 2. Esperar a que Zipkin esté listo
kubectl wait --for=condition=ready pod -l app=zipkin -n dev --timeout=180s

# 3. Obtener IP de Zipkin
ZIPKIN_IP=$(kubectl get svc zipkin -n dev -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "📊 Zipkin UI disponible en: http://$ZIPKIN_IP:9411"

echo "✅ Zipkin desplegado exitosamente"
```

### 11.2 Health Checks

```bash
# Verificar health de servicios críticos
kubectl get pods -n dev | grep -v Running

# Test de conectividad básica
kubectl run test-pod --image=curlimages/curl --rm -it --restart=Never -- \
    curl -s http://api-gateway.dev.svc.cluster.local:8080/actuator/health

# Verificar métricas de Prometheus
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090 &
# Acceder a http://localhost:9090 y verificar targets
```

### 11.3 Aplicar Pruebas de Carga (Opcional)

```bash
# Aplicar configuración de JMeter
kubectl apply -f k8s/testing/jmeter-load-test.yaml

# Ejecutar test básico
kubectl run jmeter-test --image=justb4/jmeter --rm -it --restart=Never -- \
    jmeter -n -t /test-plans/basic-load-test.jmx
```

---

## 🔧 PASO 12: CONFIGURACIÓN DE CI/CD

### 12.1 Configurar GitHub Actions

```bash
# 1. Crear service account para GitHub Actions
kubectl create serviceaccount github-actions -n dev
kubectl create clusterrolebinding github-actions-binding \
    --clusterrole=cluster-admin \
    --serviceaccount=dev:github-actions

# 2. Obtener token del service account
kubectl get secret $(kubectl get serviceaccount github-actions -n dev \
    -o jsonpath='{.secrets[0].name}') -n dev -o jsonpath='{.data.token}' | base64 --decode
```

### 12.2 Configurar Secrets de GitHub

**En tu repositorio de GitHub, agregar estos secrets:**

```
SECRETS A CONFIGURAR EN GITHUB:
- GCP_PROJECT_ID: tu-project-id
- GKE_CLUSTER: ecommerce-cluster
- GKE_ZONE: us-central1-a
- GCP_SA_KEY: (JSON key del service account)
- KUBE_CONFIG_DATA: (base64 del kubeconfig)
- SLACK_WEBHOOK: (webhook para notificaciones)
```

### 12.3 Activar Workflows

```bash
# Los workflows se activarán automáticamente en:
# - Push a main branch
# - Pull requests
# - Dispatch manual

# Verificar workflows en: https://github.com/tu-usuario/tu-repo/actions
```

---

## 📋 PASO 13: VALIDACIÓN FINAL

### 13.1 Checklist de Validación

```bash
#!/bin/bash
echo "🔍 CHECKLIST DE VALIDACIÓN FINAL"
echo "================================="

# 1. Cluster y nodos
echo "✅ Verificando cluster..."
kubectl cluster-info > /dev/null && echo "✅ Cluster OK" || echo "❌ Cluster ERROR"

# 2. Namespaces
echo "✅ Verificando namespaces..."
NAMESPACES=$(kubectl get ns --no-headers | wc -l)
[[ $NAMESPACES -ge 6 ]] && echo "✅ Namespaces OK ($NAMESPACES)" || echo "❌ Namespaces ERROR"

# 3. Microservicios
echo "✅ Verificando microservicios..."
RUNNING_PODS=$(kubectl get pods -n dev --no-headers | grep Running | wc -l)
[[ $RUNNING_PODS -ge 10 ]] && echo "✅ Microservicios OK ($RUNNING_PODS running)" || echo "❌ Microservicios ERROR"

# 4. Monitoreo
echo "✅ Verificando monitoreo..."
kubectl get pods -n monitoring --no-headers | grep -q Running && echo "✅ Monitoring OK" || echo "❌ Monitoring ERROR"

# 5. Logging
echo "✅ Verificando logging..."
kubectl get pods -n logging --no-headers | grep -q Running && echo "✅ Logging OK" || echo "❌ Logging ERROR"

# 6. Autoscaling
echo "✅ Verificando autoscaling..."
kubectl get pods -n keda --no-headers | grep -q Running && echo "✅ KEDA OK" || echo "❌ KEDA ERROR"

# 7. Ingress
echo "✅ Verificando ingress..."
kubectl get svc -n ingress-nginx --no-headers | grep -q LoadBalancer && echo "✅ Ingress OK" || echo "❌ Ingress ERROR"

echo ""
echo "🎉 VALIDACIÓN COMPLETADA"
echo "========================"
```

### 13.2 URLs de Acceso y Información de Conectividad

```bash
# Script para obtener todas las URLs importantes
cat > get-access-urls.sh <<'EOF'
#!/bin/bash
echo "🌐 URLS DE ACCESO DEL E-COMMERCE MICROSERVICES"
echo "==============================================="
echo ""

# Obtener IPs externas
API_GATEWAY_IP=$(kubectl get svc api-gateway -n dev -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
FRONTEND_IP=$(kubectl get svc frontend -n dev -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
ZIPKIN_IP=$(kubectl get svc zipkin -n dev -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
GRAFANA_IP=$(kubectl get svc prometheus-grafana -n monitoring -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)

echo "🚀 APLICACIÓN PRINCIPAL:"
if [ ! -z "$API_GATEWAY_IP" ]; then
    echo "   API Gateway: http://$API_GATEWAY_IP"
    echo "   Health Check: http://$API_GATEWAY_IP/actuator/health"
    echo "   Swagger UI: http://$API_GATEWAY_IP/swagger-ui.html"
else
    echo "   ⏳ API Gateway LoadBalancer aún no tiene IP externa"
fi

if [ ! -z "$FRONTEND_IP" ]; then
    echo "   Frontend Web: http://$FRONTEND_IP"
else
    echo "   ⏳ Frontend LoadBalancer aún no tiene IP externa"
fi

echo ""
echo "📊 MONITOREO Y OBSERVABILIDAD:"

if [ ! -z "$ZIPKIN_IP" ]; then
    echo "   Zipkin Tracing: http://$ZIPKIN_IP:9411"
else
    echo "   ⏳ Zipkin LoadBalancer aún no tiene IP externa"
    echo "   Port-forward: kubectl port-forward -n dev svc/zipkin 9411:9411"
fi

if [ ! -z "$GRAFANA_IP" ]; then
    echo "   Grafana Dashboards: http://$GRAFANA_IP"
    echo "   Credenciales: admin / (obtener con siguiente comando)"
else
    echo "   Grafana: kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80"
fi

echo "   Prometheus: kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090"
echo "   Eureka Discovery: kubectl port-forward -n dev svc/service-discovery 8761:8761"

echo ""
echo "🔑 CREDENCIALES:"
echo "   Grafana Password:"
kubectl get secret -n monitoring prometheus-grafana -o jsonpath="{.data.admin-password}" 2>/dev/null | base64 --decode 2>/dev/null || echo "     (Grafana no instalado)"
echo ""

echo ""
echo "🧪 TESTING ENDPOINTS:"
if [ ! -z "$API_GATEWAY_IP" ]; then
    echo "   curl http://$API_GATEWAY_IP/actuator/health"
    echo "   curl http://$API_GATEWAY_IP/user-service/actuator/health"
    echo "   curl http://$API_GATEWAY_IP/product-service/actuator/health"
fi

echo ""
echo "📱 COMANDOS ÚTILES:"
echo "   Ver todos los servicios: kubectl get svc -n dev"
echo "   Ver logs: kubectl logs -n dev -l app=SERVICE_NAME"
echo "   Escalar servicio: kubectl scale deployment SERVICE_NAME -n dev --replicas=3"
echo "   Ver HPA: kubectl get hpa -n dev"

echo ""
echo "💡 NOTA: Si las IPs externas muestran <pending>, espera unos minutos"
echo "   y ejecuta este script nuevamente."
EOF

chmod +x get-access-urls.sh
./get-access-urls.sh

# Guardar URLs en archivo para referencia
./get-access-urls.sh > URLS_ACCESO.txt
echo ""
echo "📝 URLs guardadas en: URLS_ACCESO.txt"
```

### 13.3 Configuración DNS Local (Opcional)

```bash
# Para acceso más fácil, agregar entradas al archivo hosts local
API_GATEWAY_IP=$(kubectl get svc api-gateway -n dev -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
FRONTEND_IP=$(kubectl get svc frontend -n dev -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

if [ ! -z "$API_GATEWAY_IP" ] && [ ! -z "$FRONTEND_IP" ]; then
    echo "🌐 Agregando entradas DNS locales..."
    
    # Crear script para actualizar hosts
    cat > update-hosts.sh <<EOF
#!/bin/bash
# Backup del archivo hosts
sudo cp /etc/hosts /etc/hosts.backup

# Agregar entradas para el proyecto
echo "" | sudo tee -a /etc/hosts
echo "# E-commerce Microservices Project" | sudo tee -a /etc/hosts
echo "$API_GATEWAY_IP    api.ecommerce.local" | sudo tee -a /etc/hosts
echo "$FRONTEND_IP       frontend.ecommerce.local" | sudo tee -a /etc/hosts

echo "✅ DNS local configurado"
echo "Ahora puedes usar:"
echo "  http://api.ecommerce.local"
echo "  http://frontend.ecommerce.local"
EOF
    
    chmod +x update-hosts.sh
    echo "Ejecuta: sudo ./update-hosts.sh para configurar DNS local"
else
    echo "⏳ Esperando IPs externas para configurar DNS local"
fi
```

---

## 🆘 TROUBLESHOOTING COMPLETO Y SOLUCIONES

### 🔧 Script de Diagnóstico Automático

```bash
# Crear script de diagnóstico completo
cat > diagnose-issues.sh <<'EOF'
#!/bin/bash
echo "🔍 DIAGNÓSTICO AUTOMÁTICO DE PROBLEMAS"
echo "======================================"
echo ""

# 1. Verificar recursos del cluster
echo "1️⃣ RECURSOS DEL CLUSTER:"
kubectl top nodes 2>/dev/null || echo "Metrics server no disponible"
kubectl describe nodes | grep -A 5 "Allocated resources" | head -20
echo ""

# 2. Pods con problemas
echo "2️⃣ PODS CON PROBLEMAS:"
kubectl get pods -n dev | grep -v Running | grep -v Completed
echo ""

# 3. Eventos recientes de error
echo "3️⃣ EVENTOS DE ERROR RECIENTES:"
kubectl get events -n dev --field-selector type=Warning --sort-by='.lastTimestamp' | tail -10
echo ""

# 4. Verificar imágenes
echo "4️⃣ VERIFICANDO IMÁGENES EN REGISTRY:"
gcloud container images list --repository=gcr.io/$PROJECT_ID --limit=5
echo ""

# 5. Servicios sin endpoints
echo "5️⃣ SERVICIOS SIN ENDPOINTS:"
for svc in $(kubectl get svc -n dev --no-headers | awk '{print $1}'); do
    endpoints=$(kubectl get endpoints $svc -n dev --no-headers | awk '{print $2}')
    if [ "$endpoints" == "<none>" ]; then
        echo "❌ $svc no tiene endpoints"
    fi
done
echo ""

# 6. LoadBalancers pendientes
echo "6️⃣ LOADBALANCERS PENDIENTES:"
kubectl get svc -n dev --no-headers | grep LoadBalancer | grep '<pending>'
echo ""

echo "✅ DIAGNÓSTICO COMPLETADO"
EOF

chmod +x diagnose-issues.sh
./diagnose-issues.sh
```

### 🚨 Problemas Comunes y Soluciones

#### Problema 1: Pods en Pending - Recursos Insuficientes

```bash
# Síntomas: Pods stuck en Pending
# Causa: Insuficientes recursos CPU/Memory

# Solución 1: Verificar y liberar recursos
kubectl describe nodes | grep -A 10 "Non-terminated pods"
kubectl delete pods -n dev --field-selector status.phase=Failed
kubectl delete pods -n dev --field-selector status.phase=Succeeded

# Solución 2: Reducir requests de recursos
kubectl patch deployment user-service -n dev -p '{"spec":{"template":{"spec":{"containers":[{"name":"user-service","resources":{"requests":{"cpu":"100m","memory":"256Mi"}}}]}}}}'

# Solución 3: Escalar el cluster
gcloud container clusters resize $CLUSTER_NAME --num-nodes=10 --zone=$ZONE
```

#### Problema 2: ImagePullBackOff - Problemas de Registry

```bash
# Síntomas: Pods muestran ImagePullBackOff o ErrImagePull
# Causa: Imagen no existe o problemas de autenticación

# Solución 1: Verificar autenticación
gcloud auth configure-docker
gcloud auth print-access-token | docker login -u oauth2accesstoken --password-stdin https://gcr.io

# Solución 2: Verificar que la imagen existe
gcloud container images list --repository=gcr.io/$PROJECT_ID
gcloud container images list-tags gcr.io/$PROJECT_ID/user-service

# Solución 3: Reconstruir imagen
gcloud builds submit --config=cloudbuild-user-service.yaml .

# Solución 4: Usar imagen alternativa temporalmente
kubectl set image deployment/user-service user-service=gcr.io/$PROJECT_ID/user-service:latest -n dev
```

#### Problema 3: CrashLoopBackOff - Aplicación no Inicia

```bash
# Síntomas: Pods se reinician constantemente
# Causa: Error en la aplicación, dependencias no disponibles

# Diagnóstico detallado
kubectl describe pod -n dev $(kubectl get pods -n dev | grep user-service | awk '{print $1}')
kubectl logs -n dev -l app=user-service --previous --tail=100

# Solución 1: Verificar dependencias
kubectl get pods -n dev | grep -E "(postgres|service-discovery|cloud-config)"

# Solución 2: Aumentar tiempos de probe
kubectl patch deployment user-service -n dev -p '{
  "spec": {
    "template": {
      "spec": {
        "containers": [{
          "name": "user-service",
          "startupProbe": {
            "failureThreshold": 60,
            "periodSeconds": 10
          }
        }]
      }
    }
  }
}'

# Solución 3: Verificar configuración de variables de entorno
kubectl describe deployment user-service -n dev | grep -A 20 "Environment:"
```

#### Problema 4: Services no Responden - Network Issues

```bash
# Síntomas: Timeouts al conectar a servicios
# Causa: Network policies, DNS, o configuración incorrecta

# Diagnóstico de conectividad
kubectl run debug-pod --image=curlimages/curl --rm -it --restart=Never -- sh

# Desde el pod debug:
# curl http://user-service.dev.svc.cluster.local:8700/actuator/health
# nslookup user-service.dev.svc.cluster.local

# Verificar endpoints y servicios
kubectl get endpoints -n dev
kubectl describe svc user-service -n dev

# Verificar network policies
kubectl get networkpolicy -n dev
kubectl describe networkpolicy -n dev
```

#### Problema 5: LoadBalancer IP Pendiente

```bash
# Síntomas: External IP shows <pending>
# Causa: Cuotas de GCP, region sin LB, configuración incorrecta

# Verificar cuotas
gcloud compute project-info describe --project=$PROJECT_ID

# Verificar que la región soporte LoadBalancers
gcloud compute regions describe us-central1

# Solución temporal: usar NodePort
kubectl patch svc api-gateway -n dev -p '{"spec":{"type":"NodePort"}}'

# Obtener IP de nodo + puerto
kubectl get nodes -o wide
kubectl get svc api-gateway -n dev
```

#### Problema 6: Base de Datos Connection Issues

```bash
# Síntomas: Microservicios no pueden conectar a PostgreSQL
# Causa: PostgreSQL no ready, credenciales incorrectas

# Verificar PostgreSQL
kubectl get pods -n dev -l app=postgres
kubectl logs -n dev postgres-0 --tail=50

# Test de conectividad a DB
kubectl exec -n dev postgres-0 -- pg_isready -U ecommerce

# Verificar secretos
kubectl get secret postgres-secret -n dev -o yaml

# Recrear secret si es necesario
kubectl delete secret postgres-secret -n dev
kubectl create secret generic postgres-secret \
  --from-literal=POSTGRES_PASSWORD=ecommerce123 \
  --namespace=dev
```

### 🔄 Scripts de Recuperación Automática

```bash
# Script de restart inteligente
cat > smart-restart.sh <<'EOF'
#!/bin/bash
echo "🔄 RESTART INTELIGENTE DE SERVICIOS"
echo "=================================="

# Restart servicios en orden de dependencias
SERVICES=("postgres" "service-discovery" "cloud-config" "user-service" "product-service" "order-service" "payment-service" "shipping-service" "favourite-service" "proxy-client" "api-gateway" "frontend")

for service in "${SERVICES[@]}"; do
    echo "🔄 Restarting $service..."
    kubectl rollout restart deployment/$service -n dev 2>/dev/null || echo "⚠️ $service no es deployment"
    
    if [ "$service" != "postgres" ] && [ "$service" != "frontend" ]; then
        echo "⏳ Esperando que $service esté ready..."
        kubectl wait --for=condition=ready pod -l app=$service -n dev --timeout=300s
    fi
    
    echo "✅ $service restarted"
done

echo "🎉 Restart completo terminado"
EOF

chmod +x smart-restart.sh

# Script de limpieza
cat > cleanup-failed-pods.sh <<'EOF'
#!/bin/bash
echo "🧹 LIMPIEZA DE PODS FALLIDOS"
echo "============================"

# Eliminar pods fallidos
kubectl delete pods -n dev --field-selector status.phase=Failed
kubectl delete pods -n dev --field-selector status.phase=Succeeded

# Eliminar pods en ImagePullBackOff por más de 10 minutos
kubectl get pods -n dev --field-selector status.phase=Pending -o json | \
jq -r '.items[] | select(.status.containerStatuses[]?.state.waiting.reason == "ImagePullBackOff") | .metadata.name' | \
xargs -I {} kubectl delete pod {} -n dev

echo "✅ Limpieza completada"
EOF

chmod +x cleanup-failed-pods.sh
```

---

## 🧹 CLEANUP (OPCIONAL)

### Eliminar Todo el Despliegue

```bash
# ⚠️ CUIDADO: Esto eliminará TODO

# 1. Eliminar aplicaciones
kubectl delete namespace dev
kubectl delete namespace monitoring
kubectl delete namespace logging
kubectl delete namespace keda
kubectl delete namespace sealed-secrets

# 2. Eliminar Ingress Controller
helm uninstall ingress-nginx -n ingress-nginx
kubectl delete namespace ingress-nginx

# 3. Eliminar cluster completo
gcloud container clusters delete $CLUSTER_NAME --zone=$REGION
```

---

## 📞 SOPORTE

**Si tienes problemas durante el despliegue:**

1. **Verificar logs:** `kubectl logs -f deployment/nombre-servicio -n dev`
2. **Describir recursos:** `kubectl describe pod nombre-pod -n dev`
3. **Verificar eventos:** `kubectl get events --sort-by='.lastTimestamp' -n dev`
4. **Consultar documentación:** Ver `DOCUMENTACION-PROYECTO-FINAL.md`

**Tiempo estimado de despliegue completo:** 45-60 minutos

**Recursos necesarios:** ~$50-100/mes en GCP para ambiente de desarrollo

## 🤖 SCRIPT DE DESPLIEGUE AUTOMÁTICO COMPLETO

### 📦 Despliegue con Un Solo Comando

```bash
# Crear script maestro de despliegue completo
cat > deploy-ecommerce-complete.sh <<'EOF'
#!/bin/bash
set -e  # Exit on any error

echo "🚀 DESPLIEGUE AUTOMÁTICO COMPLETO E-COMMERCE MICROSERVICES"
echo "==========================================================="
echo ""
echo "Este script desplegará completamente la plataforma e-commerce"
echo "Tiempo estimado: 45-60 minutos"
echo ""
read -p "¿Continuar? (y/N): " confirm
if [[ $confirm != [yY] ]]; then
    echo "Despliegue cancelado"
    exit 0
fi

# Cargar variables
source .env 2>/dev/null || {
    echo "❌ Archivo .env no encontrado. Ejecuta primero los pasos 1-3 manualmente."
    exit 1
}

echo "📊 Configuración:"
echo "   Proyecto: $PROJECT_ID"
echo "   Cluster: $CLUSTER_NAME"
echo "   Región: $ZONE"
echo ""

# Función para mostrar progreso
show_progress() {
    echo ""
    echo "🎯 PASO $1: $2"
    echo "$(printf '=%.0s' {1..60})"
}

# Función para verificar prerequisitos
check_prerequisites() {
    show_progress "0" "VERIFICANDO PREREQUISITOS"
    
    command -v gcloud >/dev/null 2>&1 || { echo "❌ gcloud CLI no encontrado"; exit 1; }
    command -v kubectl >/dev/null 2>&1 || { echo "❌ kubectl no encontrado"; exit 1; }
    command -v helm >/dev/null 2>&1 || { echo "❌ helm no encontrado"; exit 1; }
    
    # Verificar autenticación
    gcloud auth list --filter="status:ACTIVE" --format="value(account)" | grep -q . || {
        echo "❌ No hay cuenta activa en gcloud. Ejecuta: gcloud auth login"
        exit 1
    }
    
    # Verificar conexión al cluster
    kubectl cluster-info >/dev/null 2>&1 || {
        echo "❌ No conectado al cluster. Ejecuta: gcloud container clusters get-credentials $CLUSTER_NAME --zone=$ZONE"
        exit 1
    }
    
    echo "✅ Todos los prerequisitos verificados"
}

# 1. Crear namespaces
deploy_namespaces() {
    show_progress "1" "CREANDO NAMESPACES"
    
    mkdir -p k8s/namespaces
    cat > k8s/namespaces/all-namespaces.yaml <<YAML
apiVersion: v1
kind: Namespace
metadata:
  name: dev
---
apiVersion: v1
kind: Namespace
metadata:
  name: monitoring
---
apiVersion: v1
kind: Namespace
metadata:
  name: keda
YAML
    
    kubectl apply -f k8s/namespaces/all-namespaces.yaml
    echo "✅ Namespaces creados"
}

# 2. Desplegar PostgreSQL
deploy_database() {
    show_progress "2" "DESPLEGANDO BASE DE DATOS"
    
    kubectl apply -f - <<YAML
apiVersion: v1
kind: ConfigMap
metadata:
  name: postgres-config
  namespace: dev
data:
  POSTGRES_DB: ecommerce_db
  POSTGRES_USER: ecommerce
---
apiVersion: v1
kind: Secret
metadata:
  name: postgres-secret
  namespace: dev
type: Opaque
data:
  POSTGRES_PASSWORD: ZWNvbW1lcmNlMTIz
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-pvc
  namespace: dev
spec:
  accessModes: [ReadWriteOnce]
  resources:
    requests:
      storage: 10Gi
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
        env:
        - name: POSTGRES_DB
          valueFrom:
            configMapKeyRef:
              name: postgres-config
              key: POSTGRES_DB
        - name: POSTGRES_USER
          valueFrom:
            configMapKeyRef:
              name: postgres-config
              key: POSTGRES_USER
        - name: POSTGRES_PASSWORD
          valueFrom:
            secretKeyRef:
              name: postgres-secret
              key: POSTGRES_PASSWORD
        volumeMounts:
        - name: postgres-storage
          mountPath: /var/lib/postgresql/data
        resources:
          requests:
            memory: "512Mi"
            cpu: "250m"
      volumes:
      - name: postgres-storage
        persistentVolumeClaim:
          claimName: postgres-pvc
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
  type: ClusterIP
YAML
    
    kubectl wait --for=condition=ready pod -l app=postgres -n dev --timeout=300s
    echo "✅ PostgreSQL desplegado y listo"
}

# 3. Construir todas las imágenes
build_images() {
    show_progress "3" "CONSTRUYENDO IMÁGENES DOCKER"
    
    SERVICES=("service-discovery" "cloud-config" "user-service" "product-service" "order-service" "payment-service" "shipping-service" "favourite-service" "proxy-client" "api-gateway" "frontend")
    
    for service in "${SERVICES[@]}"; do
        echo "🔨 Construyendo $service..."
        gcloud builds submit --config=cloudbuild-$service.yaml . > build-$service.log 2>&1 &
    done
    
    echo "⏳ Esperando que terminen todas las construcciones..."
    wait
    echo "✅ Todas las imágenes construidas"
}

# 4. Desplegar microservicios
deploy_microservices() {
    show_progress "4" "DESPLEGANDO MICROSERVICIOS"
    
    # Servicios de infraestructura primero
    INFRA_SERVICES=("service-discovery:8761" "cloud-config:9296")
    
    for service_info in "${INFRA_SERVICES[@]}"; do
        service_name="${service_info%:*}"
        port="${service_info#*:}"
        
        echo "🚀 Desplegando $service_name..."
        
        # Aplicar desde archivos k8s si existen, sino crear básico
        if [ -f "k8s/deployments/$service_name.yaml" ]; then
            kubectl apply -f k8s/deployments/$service_name.yaml
        else
            kubectl create deployment $service_name --image=gcr.io/$PROJECT_ID/$service_name:latest -n dev
            kubectl expose deployment $service_name --port=$port --target-port=$port -n dev
        fi
        
        kubectl wait --for=condition=ready pod -l app=$service_name -n dev --timeout=300s
    done
    
    # Servicios de negocio
    BUSINESS_SERVICES=("user-service:8700" "product-service:8500" "order-service:8300" "payment-service:8400" "shipping-service:8600" "favourite-service:8800")
    
    for service_info in "${BUSINESS_SERVICES[@]}"; do
        service_name="${service_info%:*}"
        port="${service_info#*:}"
        
        echo "🚀 Desplegando $service_name..."
        
        if [ -f "k8s/deployments/$service_name.yaml" ]; then
            kubectl apply -f k8s/deployments/$service_name.yaml
        else
            kubectl create deployment $service_name --image=gcr.io/$PROJECT_ID/$service_name:latest -n dev
            kubectl expose deployment $service_name --port=$port --target-port=$port -n dev
        fi
        
        kubectl wait --for=condition=ready pod -l app=$service_name -n dev --timeout=600s
    done
    
    # Gateways
    GATEWAY_SERVICES=("proxy-client:8900" "api-gateway:8080")
    
    for service_info in "${GATEWAY_SERVICES[@]}"; do
        service_name="${service_info%:*}"
        port="${service_info#*:}"
        
        echo "🚀 Desplegando $service_name..."
        
        if [ -f "k8s/deployments/$service_name.yaml" ]; then
            kubectl apply -f k8s/deployments/$service_name.yaml
        else
            kubectl create deployment $service_name --image=gcr.io/$PROJECT_ID/$service_name:latest -n dev
            
            if [ "$service_name" = "api-gateway" ]; then
                kubectl expose deployment $service_name --port=80 --target-port=$port --type=LoadBalancer -n dev
            else
                kubectl expose deployment $service_name --port=$port --target-port=$port -n dev
            fi
        fi
        
        kubectl wait --for=condition=ready pod -l app=$service_name -n dev --timeout=300s
    done
    
    echo "✅ Todos los microservicios desplegados"
}

# 5. Configurar autoscaling
setup_autoscaling() {
    show_progress "5" "CONFIGURANDO AUTOSCALING"
    
    # Instalar KEDA si no existe
    if ! kubectl get namespace keda >/dev/null 2>&1; then
        helm repo add kedacore https://kedacore.github.io/charts >/dev/null 2>&1
        helm repo update >/dev/null 2>&1
        helm install keda kedacore/keda --namespace keda --create-namespace >/dev/null 2>&1
    fi
    
    # Crear HPAs básicos
    kubectl autoscale deployment api-gateway --cpu-percent=60 --min=2 --max=10 -n dev >/dev/null 2>&1
    kubectl autoscale deployment user-service --cpu-percent=70 --min=1 --max=5 -n dev >/dev/null 2>&1
    kubectl autoscale deployment product-service --cpu-percent=70 --min=1 --max=5 -n dev >/dev/null 2>&1
    
    echo "✅ Autoscaling configurado"
}

# 6. Verificación final
final_verification() {
    show_progress "6" "VERIFICACIÓN FINAL"
    
    echo "📊 Estado del despliegue:"
    kubectl get pods -n dev
    echo ""
    
    echo "🌐 Servicios:"
    kubectl get svc -n dev
    echo ""
    
    echo "📈 HPAs:"
    kubectl get hpa -n dev 2>/dev/null || echo "HPAs no configurados"
    echo ""
    
    API_GATEWAY_IP=$(kubectl get svc api-gateway -n dev -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
    
    if [ ! -z "$API_GATEWAY_IP" ]; then
        echo "✅ API Gateway disponible en: http://$API_GATEWAY_IP"
        echo "🧪 Test: curl http://$API_GATEWAY_IP/actuator/health"
    else
        echo "⏳ API Gateway IP aún no asignada"
    fi
}

# Ejecución principal
main() {
    check_prerequisites
    deploy_namespaces
    deploy_database
    build_images
    deploy_microservices
    setup_autoscaling
    final_verification
    
    echo ""
    echo "🎉 DESPLIEGUE COMPLETO EXITOSO"
    echo "=============================="
    echo ""
    echo "📋 Próximos pasos:"
    echo "1. Ejecuta: ./get-access-urls.sh para obtener todas las URLs"
    echo "2. Configura monitoreo con Prometheus/Grafana si lo deseas"
    echo "3. Ejecuta testing con: ./verify-deployment.sh"
    echo ""
    echo "⏱️ Tiempo total: $(( SECONDS / 60 )) minutos"
}

# Ejecutar
main
EOF

chmod +x deploy-ecommerce-complete.sh

echo "📦 Script de despliegue automático creado: deploy-ecommerce-complete.sh"
echo ""
echo "🚀 PARA DESPLEGAR AUTOMÁTICAMENTE TODO EL PROYECTO:"
echo "    ./deploy-ecommerce-complete.sh"
echo ""
echo "⚠️ IMPORTANTE: Asegúrate de haber ejecutado los pasos 1-3 manualmente primero"
echo "   (Configuración GCP, creación cluster, variables de entorno)"
```

---

## 📋 RESUMEN Y CHECKLIST FINAL

### ✅ Checklist de Completitud

**Antes del despliegue:**
- [ ] Cuenta GCP con billing habilitado
- [ ] gcloud CLI instalado y autenticado  
- [ ] kubectl instalado
- [ ] Helm instalado
- [ ] Proyecto GCP creado
- [ ] APIs habilitadas (Container, Registry, Compute, Monitoring)

**Durante el despliegue:**
- [ ] Cluster GKE creado (8 nodos e2-medium)
- [ ] Namespaces creados (dev, monitoring, keda)
- [ ] PostgreSQL desplegado y listo
- [ ] Todas las imágenes construidas en GCR
- [ ] Service Discovery (Eureka) funcionando
- [ ] Cloud Config Server funcionando
- [ ] Todos los microservicios de negocio desplegados
- [ ] API Gateway con LoadBalancer externo
- [ ] Frontend desplegado
- [ ] HPAs configurados
- [ ] Zipkin para tracing (opcional)

**Después del despliegue:**
- [ ] Todos los pods en estado Running
- [ ] Servicios registrados en Eureka
- [ ] API Gateway accesible externamente
- [ ] Base de datos con esquemas creados
- [ ] Health checks respondiendo
- [ ] LoadBalancer IPs asignadas

### 🎯 Información del Proyecto Final

**📊 Métricas de Implementación:**
- ✅ **11 Microservicios** independientes y escalables
- ✅ **PostgreSQL** con múltiples bases de datos
- ✅ **Service Discovery** con Eureka
- ✅ **API Gateway** con enrutamiento inteligente
- ✅ **Autoscaling** con HPA y KEDA
- ✅ **Observabilidad** con Zipkin tracing
- ✅ **Cloud-native** en GKE
- ✅ **CI/CD ready** con GitHub Actions
- ✅ **Seguridad** con Network Policies
- ✅ **Alta disponibilidad** con LoadBalancers

**⏱️ Tiempos de Despliegue:**
- Manual (siguiendo guía paso a paso): 60-90 minutos
- Automático (script completo): 45-60 minutos
- Solo microservicios (sin infraestructura): 30-45 minutos

**💰 Costos Estimados (GCP):**
- Desarrollo/Testing: $50-80/mes
- Producción: $150-250/mes

**🔗 Enlaces Importantes:**
- Repositorio: https://github.com/felipevelasco7/ecommerce-microservice-backend-app
- Documentación: `docs/`
- Scripts: `scripts/`
- Manifiestos K8s: `k8s/`

---

*Esta guía completa te permite recrear desde cero la plataforma e-commerce microservices. Cada paso está diseñado para ser ejecutado independientemente y verificado antes de continuar. Para soporte o dudas, consulta la documentación adicional en la carpeta `docs/` o contacta al equipo de desarrollo.*

**Última actualización:** 29 de noviembre de 2025  
**Versión:** 2.0 Unificada  
**Autor:** Felipe Velasco - Universidad Icesi