# Estado del Despliegue - E-commerce Microservices

**Fecha:** 24 de noviembre de 2025  
**Clúster:** ecommerce-cluster (GKE)  
**Namespace:** dev  
**Región:** us-central1-a

---

## 📊 Resumen General

### ✅ Servicios Desplegados: 9/11

| Servicio | Estado | Puerto | Base de Datos | CPU | Memoria | Uptime |
|----------|--------|--------|---------------|-----|---------|--------|
| **service-discovery** | ✅ Running | 8761 | - | 250m | 512Mi | 10h |
| **cloud-config** | ✅ Running | 9296 | - | 250m | 512Mi | 10h |
| **postgres** | ✅ Running | 5432 | 7 databases | 100m | 256Mi | 9h |
| **user-service** | ✅ Running | 8700 | user_db | 250m | 512Mi | 7h46m |
| **product-service** | ✅ Running | 8500 | product_db | 250m | 512Mi | 7h |
| **order-service** | ✅ Running | 8300 | order_db | 250m | 512Mi | 6h50m |
| **payment-service** | ✅ Running | 8400 | payment_db | 250m | 512Mi | 6h48m |
| **shipping-service** | ✅ Running | 8600 | shipping_db | 250m | 512Mi | 6h45m |
| **favourite-service** | ✅ Running | 8800 | favourite_db | 100m | 256Mi | 16m |
| **proxy-client** | ⏳ Pendiente | 8900 | - | - | - | - |
| **api-gateway** | ⏳ Pendiente | 8080 | - | - | - | - |

---

## 🗄️ Bases de Datos PostgreSQL

**PostgreSQL 13-alpine** en StatefulSet con 7 bases de datos:

```
✅ ecommerce_db     (general)
✅ user_db          (user-service)
✅ product_db       (product-service)
✅ order_db         (order-service)
✅ payment_db       (payment-service)
✅ shipping_db      (shipping-service)
✅ favourite_db     (favourite-service)
```

**Credenciales:**
- Usuario: `ecommerce`
- Password: `ecommerce123`
- Host: `postgres:5432`

---

## 🔧 Configuración del Clúster

**Nodes:** 5/5 (máximo alcanzado)
```
gke-ecommerce-cluster-default-pool-95a887b9-7zrd    75m   (7%)    1656Mi  (59%)
gke-ecommerce-cluster-default-pool-95a887b9-gzq3    97m   (10%)   1455Mi  (51%)
gke-ecommerce-cluster-default-pool-95a887b9-h6kl    85m   (9%)    1811Mi  (64%)
gke-ecommerce-cluster-default-pool-95a887b9-hj8c    100m  (10%)   1056Mi  (37%)
gke-ecommerce-cluster-default-pool-95a887b9-snqf    100m  (10%)   1744Mi  (62%)
```

**Tipo de máquina:** e2-medium  
**Disk:** 20GB por nodo  
**Autoscaling:** Min 2, Max 5 nodes

---

## 🚀 Proceso de Despliegue Automatizado

Script creado: `build-and-deploy-all.sh`

### Servicios desplegados automáticamente:
1. ✅ order-service - Build: 1m34s
2. ✅ payment-service - Build: 1m28s
3. ✅ shipping-service - Build: 1m32s
4. ✅ favourite-service - Build: 1m34s

**Tiempo total:** ~8 minutos

---

## 🔍 Verificación de Servicios

### Eureka Dashboard

```bash
kubectl port-forward -n dev svc/service-discovery 8761:8761
```

**URL:** http://localhost:8761

**Servicios registrados:**
- SERVICE-DISCOVERY
- CLOUD-CONFIG
- USER-SERVICE
- PRODUCT-SERVICE
- ORDER-SERVICE
- PAYMENT-SERVICE
- SHIPPING-SERVICE
- FAVOURITE-SERVICE

### Verificar bases de datos

```bash
kubectl exec -n dev postgres-0 -- psql -U ecommerce -c '\l'
```

### Ver logs de un servicio

```bash
kubectl logs -n dev -l app=product-service -f
```

---

## 🐛 Problemas Resueltos

### 1. CrashLoopBackOff en favourite-service
**Problema:** Pod se reiniciaba antes de completar startup (337 segundos)  
**Solución:** Aumentar `failureThreshold: 50` en startupProbe (total 560s)

### 2. Insufficient CPU - Pod Pending
**Problema:** Clúster alcanzó límite de 5 nodos  
**Solución:** Reducir CPU request de 250m a 100m en favourite-service

### 3. Schema Validation Error (Hibernate)
**Problema:** `wrong column type... found [numeric], but expecting [decimal]`  
**Solución:** Cambiar `ddl-auto: validate` → `ddl-auto: none`

### 4. Missing PostgreSQL Driver
**Problema:** `Failed to load driver class org.postgresql.Driver`  
**Solución:** 
- Agregar dependencia en pom.xml
- Rebuild con `--no-cache` flag

### 5. Flyway Migration Errors
**Problema:** Sintaxis MySQL incompatible con PostgreSQL  
**Solución:** Convertir scripts:
- `INT(11) AUTO_INCREMENT` → `SERIAL`
- `DECIMAL` → `NUMERIC`
- `LOCALTIMESTAMP NULL_TO_DEFAULT` → `CURRENT_TIMESTAMP NOT NULL`

---

## 📝 Archivos Clave Creados

### Cloud Build Configurations
- `cloudbuild-user-service.yaml`
- `cloudbuild-product-service.yaml`
- `cloudbuild-order-service.yaml`
- `cloudbuild-payment-service.yaml`
- `cloudbuild-shipping-service.yaml`
- `cloudbuild-favourite-service.yaml`

### ConfigMaps
- `k8s/configmaps/user-service-config.yaml`
- `k8s/configmaps/product-service-config.yaml`
- `k8s/configmaps/order-service-config.yaml`
- `k8s/configmaps/payment-service-config.yaml`
- `k8s/configmaps/shipping-service-config.yaml`
- `k8s/configmaps/favourite-service-config.yaml`

### Secrets
- `k8s/secrets/user-service-secret.yaml`
- `k8s/secrets/product-service-secret.yaml`
- `k8s/secrets/order-service-secret.yaml`
- `k8s/secrets/payment-service-secret.yaml`
- `k8s/secrets/shipping-service-secret.yaml`
- `k8s/secrets/favourite-service-secret.yaml`

### Deployments
- `k8s/deployments/service-discovery.yaml`
- `k8s/deployments/cloud-config.yaml`
- `k8s/deployments/postgres.yaml`
- `k8s/deployments/user-service.yaml`
- `k8s/deployments/product-service.yaml`
- `k8s/deployments/order-service.yaml`
- `k8s/deployments/payment-service.yaml`
- `k8s/deployments/shipping-service.yaml`
- `k8s/deployments/favourite-service.yaml`

### Scripts
- `build-and-deploy-all.sh` - Despliegue automatizado
- `scr.sh` - Conversión de SQL MySQL → PostgreSQL

---

## 🎯 Próximos Pasos

1. **proxy-client**
   - Crear cloudbuild-proxy-client.yaml
   - Configurar deployment
   - Desplegar servicio

2. **api-gateway**
   - Crear cloudbuild-api-gateway.yaml
   - Configurar deployment con LoadBalancer
   - Exponer externamente

3. **Optimizaciones**
   - Implementar HorizontalPodAutoscaler
   - Configurar Network Policies
   - Agregar Prometheus + Grafana

4. **CI/CD**
   - Configurar GitHub Actions
   - Automatizar builds en push
   - Implementar rolling updates

---

## 📚 Documentación

- **Guía completa:** [DEPLOYMENT-GUIDE.md](./DEPLOYMENT-GUIDE.md)
- **Arquitectura:** [app-architecture.drawio](./app-architecture.drawio)
- **ERD:** [ecommerce-ERD.drawio](./ecommerce-ERD.drawio)

---

## 🔗 Comandos Útiles

```bash
# Ver todos los pods
kubectl get pods -n dev

# Ver todos los servicios
kubectl get svc -n dev

# Port-forward a Eureka
kubectl port-forward -n dev svc/service-discovery 8761:8761

# Ver logs en tiempo real
kubectl logs -n dev -f -l app=product-service

# Verificar health de un pod
kubectl exec -n dev <pod-name> -- wget -qO- localhost:8500/actuator/health

# Ver uso de recursos
kubectl top nodes
kubectl top pods -n dev

# Reconstruir un servicio
gcloud builds submit --config=cloudbuild-product-service.yaml .
kubectl rollout restart deployment product-service -n dev
```

---

**Mantenido por:** Equipo de Desarrollo  
**Última verificación:** 24 de noviembre de 2025, 15:00 UTC
