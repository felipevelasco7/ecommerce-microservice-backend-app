# 🚀 GUÍA DE DESPLIEGUE PASO A PASO - E-COMMERCE MICROSERVICES

## 📋 PREREQUISITOS

### ☁️ **Requerimientos de Infraestructura**
- **Google Cloud Platform Account** con billing habilitado
- **Kubernetes CLI (kubectl)** v1.24+
- **Google Cloud SDK (gcloud)** instalado y configurado
- **Helm** v3.8+
- **Docker** para builds locales (opcional)
- **Git** para clonar el repositorio

### 💻 **Recursos Mínimos Recomendados**
- **GKE Cluster:** 6-8 nodos e2-medium (2 vCPU, 4GB RAM cada uno)
- **Networking:** VPC con subredes privadas
- **Storage:** 100GB SSD para volúmenes persistentes
- **Registry:** Google Container Registry habilitado

---

## 🎯 PASO 1: PREPARACIÓN DEL ENTORNO

### 1.1 Configuración de Google Cloud

```bash
# 1. Autenticación en Google Cloud
gcloud auth login
gcloud auth application-default login

# 2. Configurar proyecto (reemplazar con tu PROJECT_ID)
export PROJECT_ID="tu-project-id"
gcloud config set project $PROJECT_ID

# 3. Habilitar APIs necesarias
gcloud services enable container.googleapis.com
gcloud services enable containerregistry.googleapis.com
gcloud services enable compute.googleapis.com
gcloud services enable monitoring.googleapis.com

# 4. Configurar región por defecto
gcloud config set compute/zone us-central1-a
```

### 1.2 Clonar y Preparar el Repositorio

```bash
# 1. Clonar el repositorio
git clone https://github.com/SelimHorri/ecommerce-microservice-backend-app.git
cd ecommerce-microservice-backend-app

# 2. Verificar estructura del proyecto
ls -la
# Deberías ver: k8s/, helm/, .github/workflows/, etc.

# 3. Configurar variables de entorno
export CLUSTER_NAME="ecommerce-cluster"
export REGION="us-central1-a"
export REGISTRY="gcr.io/$PROJECT_ID"
```

---

## 🏗️ PASO 2: CREACIÓN DEL CLUSTER GKE

### 2.1 Crear Cluster Kubernetes

```bash
# 1. Crear cluster GKE con configuración optimizada
gcloud container clusters create $CLUSTER_NAME \
    --zone=$REGION \
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
    --enable-logging

# 2. Obtener credenciales del cluster
gcloud container clusters get-credentials $CLUSTER_NAME --zone=$REGION

# 3. Verificar conectividad
kubectl cluster-info
kubectl get nodes
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

## 📦 PASO 3: INSTALACIÓN DE COMPONENTES BASE

### 3.1 Crear Namespaces

```bash
# Crear todos los namespaces necesarios
kubectl apply -f k8s/namespaces/

# Verificar creación
kubectl get namespaces
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

## 🚀 PASO 8: DESPLIEGUE DE MICROSERVICIOS

### 8.1 Aplicar ConfigMaps y Secrets

```bash
# 1. Aplicar todas las configuraciones
kubectl apply -f k8s/configmaps/

# 2. Crear secrets básicos (temporal, luego usar Sealed Secrets)
kubectl create secret generic database-credentials \
    --from-literal=username=admin \
    --from-literal=password=secretpassword \
    --namespace=dev

# 3. Verificar configuraciones
kubectl get configmaps -n dev
kubectl get secrets -n dev
```

### 8.2 Desplegar Servicios de Infraestructura

```bash
# 1. Service Discovery (Eureka)
kubectl apply -f k8s/deployments/service-discovery/

# 2. Cloud Config Server
kubectl apply -f k8s/deployments/cloud-config/

# 3. Esperar a que estén listos
kubectl wait --for=condition=ready pod \
    -l app=service-discovery -n dev --timeout=300s
kubectl wait --for=condition=ready pod \
    -l app=cloud-config -n dev --timeout=300s
```

### 8.3 Desplegar Microservicios Core

```bash
# Desplegar en orden de dependencias
echo "Desplegando User Service..."
kubectl apply -f k8s/deployments/user-service/
kubectl wait --for=condition=ready pod -l app=user-service -n dev --timeout=300s

echo "Desplegando Product Service..."
kubectl apply -f k8s/deployments/product-service/
kubectl wait --for=condition=ready pod -l app=product-service -n dev --timeout=300s

echo "Desplegando Order Service..."
kubectl apply -f k8s/deployments/order-service/
kubectl wait --for=condition=ready pod -l app=order-service -n dev --timeout=300s

echo "Desplegando Payment Service..."
kubectl apply -f k8s/deployments/payment-service/
kubectl wait --for=condition=ready pod -l app=payment-service -n dev --timeout=300s

echo "Desplegando Shipping Service..."
kubectl apply -f k8s/deployments/shipping-service/
kubectl wait --for=condition=ready pod -l app=shipping-service -n dev --timeout=300s

echo "Desplegando Favourite Service..."
kubectl apply -f k8s/deployments/favourite-service/
kubectl wait --for=condition=ready pod -l app=favourite-service -n dev --timeout=300s
```

### 8.4 Desplegar API Gateway

```bash
# 1. Desplegar API Gateway (último)
kubectl apply -f k8s/deployments/api-gateway/

# 2. Verificar que esté listo
kubectl wait --for=condition=ready pod \
    -l app=api-gateway -n dev --timeout=300s
```

### 8.5 Desplegar Frontend

```bash
# Desplegar interfaz web
kubectl apply -f k8s/deployments/frontend/

# Verificar despliegue
kubectl get pods -n dev -l app=frontend
```

---

## ⚙️ PASO 9: CONFIGURACIÓN DE AUTOSCALING

### 9.1 Aplicar HPAs

```bash
# Aplicar Horizontal Pod Autoscalers
kubectl apply -f k8s/autoscaling/hpa/

# Verificar HPAs
kubectl get hpa -n dev
```

### 9.2 Configurar KEDA ScaledObjects

```bash
# Aplicar ScaledObjects para event-driven autoscaling
kubectl apply -f k8s/autoscaling/keda-scaledobjects.yaml

# Verificar ScaledObjects
kubectl get scaledobjects -n dev
kubectl describe scaledobject api-gateway-scaler -n dev
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

## ✅ PASO 11: VERIFICACIÓN Y TESTING

### 11.1 Verificar Estado General

```bash
# Script de verificación completa
echo "=== VERIFICACIÓN COMPLETA DEL DESPLIEGUE ==="
echo ""

echo "1. Verificando nodos del cluster:"
kubectl get nodes

echo -e "\n2. Verificando namespaces:"
kubectl get namespaces

echo -e "\n3. Verificando microservicios:"
kubectl get pods -n dev

echo -e "\n4. Verificando monitoreo:"
kubectl get pods -n monitoring

echo -e "\n5. Verificando logging:"
kubectl get pods -n logging

echo -e "\n6. Verificando autoscaling:"
kubectl get pods -n keda
kubectl get hpa -n dev
kubectl get scaledobjects -n dev

echo -e "\n7. Verificando servicios:"
kubectl get svc -n dev

echo -e "\n8. Verificando ingress:"
kubectl get ingress -n dev

echo -e "\n9. Verificando almacenamiento:"
kubectl get pv,pvc -A
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

### 13.2 URLs de Acceso

```bash
# Obtener URLs de acceso
echo "📍 URLS DE ACCESO:"
echo "=================="

# Ingress IP
INGRESS_IP=$(kubectl get svc -n ingress-nginx ingress-nginx-controller \
    -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "🌐 API Gateway: http://$INGRESS_IP"
echo "🌐 Frontend: http://$INGRESS_IP/frontend"

# Port-forwards para desarrollo
echo ""
echo "🔧 PORT-FORWARDS PARA DESARROLLO:"
echo "kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80"
echo "kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090"
echo "kubectl port-forward -n dev svc/api-gateway 8080:8080"
```

---

## 🆘 TROUBLESHOOTING COMÚN

### Problema 1: Pods en Pending

```bash
# Verificar recursos del cluster
kubectl describe nodes | grep -A 5 "Allocated resources"
kubectl top nodes

# Verificar eventos
kubectl get events --sort-by='.lastTimestamp' -n dev
```

### Problema 2: ImagePullBackOff

```bash
# Verificar acceso al registry
gcloud auth configure-docker
docker pull gcr.io/$PROJECT_ID/user-service:latest

# Verificar secrets de registry
kubectl get secrets -n dev | grep registry
```

### Problema 3: Services no responden

```bash
# Test de conectividad
kubectl run debug --image=curlimages/curl --rm -it --restart=Never -- \
    curl -v http://service-name.namespace.svc.cluster.local:port

# Verificar endpoints
kubectl get endpoints -n dev
```

### Problema 4: Monitoring no funciona

```bash
# Verificar targets de Prometheus
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
# Ir a http://localhost:9090/targets

# Verificar configuración
kubectl get configmap -n monitoring | grep prometheus
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

---

*Esta guía te permitirá recrear completamente el entorno e-commerce microservices desde cero. Sigue cada paso en orden y verifica antes de continuar al siguiente.*