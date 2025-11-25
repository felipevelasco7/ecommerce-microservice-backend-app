# Manual de Operaciones - E-Commerce Microservices Platform

## Tabla de Contenidos
1. [Información General](#información-general)
2. [Arquitectura del Sistema](#arquitectura-del-sistema)
3. [Requisitos Previos](#requisitos-previos)
4. [Despliegue Inicial](#despliegue-inicial)
5. [Operaciones Diarias](#operaciones-diarias)
6. [Monitoreo y Observabilidad](#monitoreo-y-observabilidad)
7. [Escalabilidad](#escalabilidad)
8. [Seguridad](#seguridad)
9. [Troubleshooting](#troubleshooting)
10. [Respaldo y Recuperación](#respaldo-y-recuperación)
11. [Apéndices](#apéndices)

---

## 1. Información General

### 1.1 Descripción del Proyecto
Plataforma de e-commerce basada en arquitectura de microservicios desplegada en Google Kubernetes Engine (GKE). El sistema implementa patrones de diseño modernos incluyendo service discovery, configuración centralizada, distributed tracing y auto-escalado.

### 1.2 Información del Cluster
- **Nombre**: ecommerce-cluster
- **Proyecto GCP**: axiomatic-fiber-479102-k7
- **Región**: us-central1-a
- **Nodos**: 8 x e2-medium (2 vCPU, 4GB RAM)
- **Namespaces**: dev, qa, prod, monitoring

### 1.3 Componentes Principales
| Componente | Tipo | Puerto | Descripción |
|------------|------|--------|-------------|
| API Gateway | Gateway | 8200 | Punto de entrada principal |
| Proxy Client | Gateway | 8100 | Cliente proxy alternativo |
| User Service | Backend | 8700 | Gestión de usuarios |
| Product Service | Backend | 8800 | Catálogo de productos |
| Order Service | Backend | 8600 | Procesamiento de órdenes |
| Payment Service | Backend | 8500 | Procesamiento de pagos |
| Shipping Service | Backend | 8400 | Gestión de envíos |
| Favourite Service | Backend | 8300 | Favoritos de usuarios |
| Service Discovery | Infraestructura | 8761 | Eureka Server |
| Cloud Config | Infraestructura | 9296 | Configuración centralizada |
| PostgreSQL | Base de datos | 5432 | Almacenamiento persistente |
| Zipkin | Observabilidad | 9411 | Distributed tracing |
| Prometheus | Monitoreo | 9090 | Recolección de métricas |
| Grafana | Visualización | 3000 | Dashboards |

---

## 2. Arquitectura del Sistema

### 2.1 Diagrama de Arquitectura General
```
                                   ┌─────────────────┐
                                   │   Internet      │
                                   └────────┬────────┘
                                            │
                            ┌───────────────┴────────────────┐
                            │                                │
                    ┌───────▼────────┐            ┌─────────▼─────────┐
                    │  API Gateway   │            │   Proxy Client    │
                    │  LoadBalancer  │            │   LoadBalancer    │
                    └───────┬────────┘            └─────────┬─────────┘
                            │                                │
                            └───────────────┬────────────────┘
                                            │
                            ┌───────────────▼────────────────┐
                            │    Service Discovery (Eureka)  │
                            └───────────────┬────────────────┘
                                            │
            ┌───────────────────────────────┼───────────────────────────────┐
            │                               │                               │
    ┌───────▼────────┐          ┌──────────▼──────────┐        ┌──────────▼──────────┐
    │  User Service  │          │  Product Service    │        │  Order Service      │
    └───────┬────────┘          └──────────┬──────────┘        └──────────┬──────────┘
            │                               │                               │
            │                               │                   ┌───────────┴──────────┐
            │                               │                   │                      │
    ┌───────▼────────┐          ┌──────────▼──────────┐  ┌─────▼─────┐    ┌─────────▼─────┐
    │Payment Service │          │ Shipping Service    │  │  Payment  │    │   Shipping    │
    └───────┬────────┘          └──────────┬──────────┘  │  Service  │    │   Service     │
            │                               │              └─────┬─────┘    └─────────┬─────┘
            │                               │                    │                    │
            └───────────────────────────────┴────────────────────┴────────────────────┘
                                            │
                                  ┌─────────▼──────────┐
                                  │    PostgreSQL      │
                                  │   StatefulSet      │
                                  │   (PVC 10GB)       │
                                  └────────────────────┘

    Observability Stack:
    ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
    │   Zipkin    │     │ Prometheus  │     │   Grafana   │
    │  (Tracing)  │     │  (Metrics)  │     │ (Dashboard) │
    └─────────────┘     └─────────────┘     └─────────────┘
```

### 2.2 Flujo de Comunicación
1. Cliente → LoadBalancer (API Gateway/Proxy Client)
2. Gateway → Service Discovery (registro/descubrimiento)
3. Gateway → Cloud Config (configuración)
4. Gateway → Microservices (routing)
5. Microservices → PostgreSQL (persistencia)
6. Microservices → Zipkin (trazas)
7. Microservices → Prometheus (métricas)

---

## 3. Requisitos Previos

### 3.1 Herramientas Necesarias
```bash
# Verificar instalación
gcloud --version          # Google Cloud SDK
kubectl version --client  # Kubernetes CLI
docker --version         # Docker (para builds locales)
```

### 3.2 Configuración de GCP
```bash
# Autenticación
gcloud auth login
gcloud config set project axiomatic-fiber-479102-k7

# Configurar kubectl
gcloud container clusters get-credentials ecommerce-cluster \
    --zone us-central1-a \
    --project axiomatic-fiber-479102-k7
```

### 3.3 Verificación de Acceso
```bash
# Verificar conexión al cluster
kubectl cluster-info

# Listar nodos
kubectl get nodes

# Verificar namespaces
kubectl get namespaces
```

---

## 4. Despliegue Inicial

### 4.1 Orden de Despliegue
El orden es crítico debido a las dependencias entre servicios:

```bash
# 1. Namespaces
kubectl apply -f k8s/namespaces/

# 2. ConfigMaps y Secrets
kubectl apply -f k8s/configmaps/
kubectl apply -f k8s/secrets/

# 3. Base de datos (PostgreSQL)
kubectl apply -f k8s/deployments/postgres.yaml

# Esperar a que PostgreSQL esté listo
kubectl wait --for=condition=ready pod -l app=postgres -n dev --timeout=180s

# 4. Servicios de infraestructura
kubectl apply -f k8s/deployments/service-discovery.yaml
kubectl apply -f k8s/deployments/cloud-config.yaml

# Esperar a que Eureka esté listo
kubectl wait --for=condition=ready pod -l app=service-discovery -n dev --timeout=180s

# 5. Microservicios de negocio (orden sugerido)
kubectl apply -f k8s/deployments/user-service.yaml
kubectl apply -f k8s/deployments/product-service.yaml
kubectl apply -f k8s/deployments/payment-service.yaml
kubectl apply -f k8s/deployments/shipping-service.yaml
kubectl apply -f k8s/deployments/order-service.yaml
kubectl apply -f k8s/deployments/favourite-service.yaml

# 6. Gateways
kubectl apply -f k8s/deployments/proxy-client.yaml
kubectl apply -f k8s/deployments/api-gateway.yaml

# 7. Observabilidad
kubectl apply -f k8s/deployments/zipkin.yaml
kubectl apply -f k8s/monitoring/

# 8. Auto-escalado (HPA)
kubectl apply -f k8s/hpa/

# 9. Network Policies (Seguridad)
kubectl apply -f k8s/network-policies/
```

### 4.2 Script de Despliegue Automatizado
```bash
# Usar el script proporcionado
./deploy-all-services.sh
```

### 4.3 Verificación Post-Despliegue
```bash
# Verificar todos los pods
kubectl get pods -n dev

# Verificar servicios
kubectl get svc -n dev

# Verificar HPAs
kubectl get hpa -n dev

# Verificar Network Policies
kubectl get networkpolicy -n dev

# Verificar que Eureka tenga todos los servicios registrados
kubectl port-forward -n dev svc/service-discovery 8761:8761 &
# Abrir: http://localhost:8761
```

---

## 5. Operaciones Diarias

### 5.1 Verificación del Estado del Sistema
```bash
# Estado general
kubectl get pods -n dev
kubectl get svc -n dev
kubectl get hpa -n dev

# Logs de un servicio específico
kubectl logs -n dev deployment/user-service --tail=100 -f

# Logs de todos los pods de un servicio
kubectl logs -n dev -l app=user-service --tail=50

# Ver eventos recientes
kubectl get events -n dev --sort-by='.lastTimestamp' | tail -20
```

### 5.2 Acceso a los Servicios

#### Port Forwarding para Desarrollo/Debug
```bash
# API Gateway
kubectl port-forward -n dev svc/api-gateway 8080:80 &

# Eureka Dashboard
kubectl port-forward -n dev svc/service-discovery 8761:8761 &

# Zipkin UI
kubectl port-forward -n dev svc/zipkin 9411:9411 &

# Prometheus
kubectl port-forward -n monitoring svc/prometheus 9090:9090 &

# Grafana (también disponible vía LoadBalancer)
kubectl port-forward -n monitoring svc/grafana 3000:3000 &
```

#### IPs Externas (LoadBalancers)
```bash
# Obtener IP del API Gateway
kubectl get svc api-gateway -n dev -o jsonpath='{.status.loadBalancer.ingress[0].ip}'

# Obtener IP de Grafana
kubectl get svc grafana -n monitoring -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

### 5.3 Generar Tráfico de Prueba
```bash
# Script de pruebas automatizado
./test.sh

# Prueba manual de endpoints
API_GATEWAY=$(kubectl get svc api-gateway -n dev -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

curl http://$API_GATEWAY/actuator/health
curl http://$API_GATEWAY/user-service/actuator/health
curl http://$API_GATEWAY/product-service/actuator/health
```

### 5.4 Actualización de Servicios

#### Actualizar un Servicio Específico
```bash
# Reconstruir imagen
gcloud builds submit --config=cloudbuild-user-service.yaml \
    --region=us-central1 .

# Reiniciar deployment para usar nueva imagen
kubectl rollout restart deployment user-service -n dev

# Monitorear el rollout
kubectl rollout status deployment user-service -n dev
```

#### Rollback en Caso de Problemas
```bash
# Ver historial de despliegues
kubectl rollout history deployment user-service -n dev

# Rollback a la versión anterior
kubectl rollout undo deployment user-service -n dev

# Rollback a una versión específica
kubectl rollout undo deployment user-service -n dev --to-revision=2
```

### 5.5 Actualización de Configuración
```bash
# Actualizar ConfigMap
kubectl apply -f k8s/configmaps/user-service-config.yaml

# Reiniciar pods para cargar nueva configuración
kubectl rollout restart deployment user-service -n dev
```

---

## 6. Monitoreo y Observabilidad

### 6.1 Prometheus
**Acceso**: http://PROMETHEUS_IP:9090 o `kubectl port-forward -n monitoring svc/prometheus 9090:9090`

#### Queries Útiles
```promql
# CPU usage por servicio
rate(process_cpu_usage[5m])

# Memoria heap usada
jvm_memory_used_bytes{area="heap"}

# Request rate
rate(http_server_requests_seconds_count[5m])

# Response time p95
histogram_quantile(0.95, rate(http_server_requests_seconds_bucket[5m]))

# Errores HTTP 5xx
rate(http_server_requests_seconds_count{status=~"5.."}[5m])
```

#### Verificar Targets
1. Ir a **Status → Targets**
2. Verificar que todos los servicios estén **UP** (verde)
3. Si alguno está **DOWN**, revisar logs y network policies

### 6.2 Grafana
**Acceso**: http://34.60.135.215:3000
**Credenciales**: admin / admin123

#### Dashboards Disponibles
1. **E-Commerce Microservices Dashboard** (personalizado)
   - Request rate por servicio
   - Memory usage
   - Response time p95
   - JVM threads
   - HTTP errors

2. **Dashboards Importados**
   - JVM (Micrometer) - ID 4701
   - Spring Boot Statistics - ID 11378
   - Spring Boot APM - ID 12900

### 6.3 Zipkin
**Acceso**: http://localhost:9411 (port-forward)

#### Uso
1. Generar tráfico: `./test.sh`
2. En Zipkin UI, hacer clic en **"RUN QUERY"**
3. Ver trazas individuales haciendo clic en ellas
4. Ir a **Dependencies** para ver el grafo de servicios

#### Interpretar Trazas
- **Trace ID**: Identificador único de la transacción completa
- **Span ID**: Identificador de cada paso en la traza
- **Service Name**: Servicio que generó el span
- **Duration**: Tiempo de ejecución

### 6.4 Logs Centralizados
```bash
# Logs de un pod específico
kubectl logs -n dev <pod-name>

# Logs con follow
kubectl logs -n dev <pod-name> -f

# Logs de un container específico (si el pod tiene múltiples)
kubectl logs -n dev <pod-name> -c <container-name>

# Logs de todos los pods de un deployment
kubectl logs -n dev -l app=user-service --all-containers=true

# Logs con timestamp
kubectl logs -n dev <pod-name> --timestamps

# Últimas N líneas
kubectl logs -n dev <pod-name> --tail=100
```

---

## 7. Escalabilidad

### 7.1 Horizontal Pod Autoscaler (HPA)

#### Estado Actual de HPAs
```bash
# Ver todos los HPAs
kubectl get hpa -n dev

# Detalles de un HPA específico
kubectl describe hpa user-service-hpa -n dev
```

#### Configuración de HPAs
| Servicio | Min | Max | CPU Target | Memory Target |
|----------|-----|-----|------------|---------------|
| API Gateway | 2 | 10 | 60% | 75% |
| User Service | 1 | 5 | 70% | 80% |
| Product Service | 1 | 5 | 70% | 80% |
| Order Service | 1 | 5 | 70% | 80% |
| Payment Service | 1 | 5 | 70% | 80% |
| Shipping Service | 1 | 3 | 70% | - |

#### Modificar HPA
```bash
# Editar HPA existente
kubectl edit hpa user-service-hpa -n dev

# O aplicar cambios desde archivo
kubectl apply -f k8s/hpa/microservices-hpa.yaml
```

### 7.2 Escalado Manual
```bash
# Escalar a N réplicas
kubectl scale deployment user-service -n dev --replicas=3

# Verificar escalado
kubectl get deployment user-service -n dev
```

### 7.3 Verificar Métricas
```bash
# Métricas del Metrics Server
kubectl top nodes
kubectl top pods -n dev

# Métricas de un pod específico
kubectl top pod <pod-name> -n dev
```

### 7.4 Prueba de Auto-Escalado
```bash
# Generar carga (ejemplo con apache bench)
AB_COUNT=10000
AB_CONCURRENT=50
API_IP=$(kubectl get svc api-gateway -n dev -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

ab -n $AB_COUNT -c $AB_CONCURRENT http://$API_IP/actuator/health

# Monitorear HPA durante la carga
watch -n 2 kubectl get hpa -n dev
```

---

## 8. Seguridad

### 8.1 Network Policies

#### Políticas Implementadas
1. **default-deny-ingress**: Denegar todo tráfico entrante por defecto
2. **allow-from-api-gateway**: Permitir tráfico desde gateways
3. **postgres-allow-backend**: Solo servicios autorizados a PostgreSQL
4. **eureka-allow-all-services**: Todos los servicios a Eureka
5. **cloud-config-allow-all**: Todos los servicios a Config Server
6. **zipkin-allow-all**: Todos los servicios a Zipkin
7. **api-gateway-allow-external**: Internet → API Gateway
8. **Políticas específicas por servicio**: Control granular

#### Verificar Network Policies
```bash
# Listar todas las políticas
kubectl get networkpolicy -n dev

# Detalles de una política
kubectl describe networkpolicy postgres-allow-backend -n dev
```

#### Probar Conectividad
```bash
# Desde un pod, probar conexión a otro servicio
kubectl exec -it -n dev deployment/user-service -- \
    wget -qO- http://postgres:5432 --timeout=2

# Debería funcionar si está permitido, timeout si está bloqueado
```

### 8.2 Secrets Management
```bash
# Listar secrets
kubectl get secrets -n dev

# Ver detalles (NO muestra valores)
kubectl describe secret postgres-secret -n dev

# Decodificar un secret (usar con cuidado)
kubectl get secret postgres-secret -n dev -o jsonpath='{.data.SPRING_DATASOURCE_PASSWORD}' | base64 -d
```

### 8.3 RBAC (Role-Based Access Control)
```bash
# Ver roles en el namespace
kubectl get roles -n dev
kubectl get rolebindings -n dev

# Ver cluster roles (Prometheus usa esto)
kubectl get clusterroles | grep prometheus
kubectl get clusterrolebindings | grep prometheus
```

### 8.4 Mejores Prácticas de Seguridad
- ✅ Network Policies implementadas
- ✅ Secrets para credenciales sensibles
- ✅ ConfigMaps para configuración no sensible
- ✅ RBAC para Prometheus
- ⚠️ **Pendiente**: Implementar TLS/SSL en los endpoints externos
- ⚠️ **Pendiente**: Implementar Pod Security Policies
- ⚠️ **Pendiente**: Escaneo de imágenes con vulnerabilidades

---

## 9. Troubleshooting

### 9.1 Problemas Comunes

#### Pod en estado CrashLoopBackOff
```bash
# Ver logs del pod
kubectl logs -n dev <pod-name> --previous

# Ver eventos
kubectl describe pod -n dev <pod-name>

# Verificar recursos
kubectl top pod -n dev <pod-name>

# Verificar init containers
kubectl logs -n dev <pod-name> -c <init-container-name>
```

**Causas comunes**:
- Dependencias no disponibles (Eureka, Config, DB)
- Configuración incorrecta
- Recursos insuficientes
- Imagen incorrecta

#### Pod en estado Pending
```bash
# Ver por qué no se puede programar
kubectl describe pod -n dev <pod-name>
```

**Causas comunes**:
- Recursos insuficientes en el cluster
- Node selectors no coinciden
- Taints en los nodos

**Solución temporal**:
```bash
# Eliminar pods duplicados para liberar recursos
kubectl delete pod <old-pod-name> -n dev --force --grace-period=0
```

#### Service no accesible
```bash
# Verificar que el service existe
kubectl get svc -n dev <service-name>

# Verificar endpoints
kubectl get endpoints -n dev <service-name>

# Debe haber IPs, si está vacío, los pods no están Ready
```

#### HPA no escala
```bash
# Verificar que Metrics Server está funcionando
kubectl get deployment metrics-server -n kube-system

# Verificar métricas disponibles
kubectl get --raw /apis/metrics.k8s.io/v1beta1/nodes
kubectl get --raw /apis/metrics.k8s.io/v1beta1/namespaces/dev/pods

# Ver eventos del HPA
kubectl describe hpa <hpa-name> -n dev
```

#### Network Policy bloqueando tráfico legítimo
```bash
# Temporalmente deshabilitar una policy
kubectl delete networkpolicy <policy-name> -n dev

# Probar conectividad
# ...

# Re-aplicar policy
kubectl apply -f k8s/network-policies/microservices-network-policies.yaml
```

### 9.2 Comandos de Debug

#### Ejecutar shell en un pod
```bash
# Bash (si disponible)
kubectl exec -it -n dev <pod-name> -- /bin/bash

# Sh (más común en imágenes slim)
kubectl exec -it -n dev <pod-name> -- /bin/sh

# Ejecutar comando específico
kubectl exec -it -n dev <pod-name> -- curl localhost:8700/actuator/health
```

#### Port-forward para debug
```bash
# Forward port local al pod
kubectl port-forward -n dev <pod-name> 8080:8700
```

#### Copiar archivos desde/hacia pod
```bash
# Desde pod a local
kubectl cp dev/<pod-name>:/app/logs/app.log ./local-app.log

# Desde local a pod
kubectl cp ./config.yaml dev/<pod-name>:/tmp/config.yaml
```

### 9.3 Health Checks

#### Verificar Endpoints de Health
```bash
# Via port-forward
kubectl port-forward -n dev svc/user-service 8700:8700 &
curl http://localhost:8700/actuator/health

# Via API Gateway
API_IP=$(kubectl get svc api-gateway -n dev -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
curl http://$API_IP/user-service/actuator/health
```

#### Verificar Servicios Registrados en Eureka
```bash
kubectl port-forward -n dev svc/service-discovery 8761:8761 &
curl http://localhost:8761/eureka/apps | grep '<application>'
```

---

## 10. Respaldo y Recuperación

### 10.1 Respaldo de PostgreSQL

#### Crear Backup Manual
```bash
# Crear directorio para backups
mkdir -p backups

# Backup completo
kubectl exec -n dev postgres-0 -- pg_dumpall -U ecommerce > backups/backup-$(date +%Y%m%d-%H%M%S).sql

# Backup de base de datos específica
kubectl exec -n dev postgres-0 -- pg_dump -U ecommerce user_db > backups/user_db-$(date +%Y%m%d).sql
```

#### Restaurar Backup
```bash
# Restaurar desde backup
cat backups/backup-20251124.sql | kubectl exec -i -n dev postgres-0 -- psql -U ecommerce
```

#### Backup Automatizado (Cronjob)
```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: postgres-backup
  namespace: dev
spec:
  schedule: "0 2 * * *"  # Diario a las 2 AM
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: backup
            image: postgres:13-alpine
            command:
            - /bin/sh
            - -c
            - pg_dumpall -h postgres -U ecommerce > /backup/backup-$(date +\%Y\%m\%d).sql
            env:
            - name: PGPASSWORD
              valueFrom:
                secretKeyRef:
                  name: postgres-secret
                  key: POSTGRES_PASSWORD
            volumeMounts:
            - name: backup-volume
              mountPath: /backup
          restartPolicy: OnFailure
          volumes:
          - name: backup-volume
            persistentVolumeClaim:
              claimName: postgres-backup-pvc
```

### 10.2 Respaldo de Configuración
```bash
# Exportar todos los recursos del namespace
kubectl get all -n dev -o yaml > backups/dev-namespace-$(date +%Y%m%d).yaml

# Exportar ConfigMaps
kubectl get configmaps -n dev -o yaml > backups/configmaps-$(date +%Y%m%d).yaml

# Exportar Secrets (CUIDADO: contiene datos sensibles)
kubectl get secrets -n dev -o yaml > backups/secrets-$(date +%Y%m%d).yaml

# Encriptar backup de secrets
gpg -c backups/secrets-$(date +%Y%m%d).yaml
rm backups/secrets-$(date +%Y%m%d).yaml
```

### 10.3 Disaster Recovery

#### Escenario: Cluster Completo Perdido
1. Crear nuevo cluster
2. Aplicar manifests en orden (ver sección 4.1)
3. Restaurar base de datos desde backup
4. Verificar funcionamiento

#### Escenario: Namespace Corrupto
```bash
# Eliminar namespace (CUIDADO: borra todo)
kubectl delete namespace dev

# Recrear desde backups
kubectl create namespace dev
kubectl apply -f backups/configmaps-DATE.yaml
kubectl apply -f backups/secrets-DATE.yaml
kubectl apply -f k8s/deployments/
```

#### Escenario: PersistentVolume Corrupto
```bash
# Identificar PVC
kubectl get pvc -n dev

# Crear snapshot (si está configurado)
kubectl get volumesnapshot -n dev

# Restaurar desde snapshot o recrear con backup de datos
```

---

## 11. Apéndices

### 11.1 Variables de Entorno Importantes

#### PostgreSQL
- `POSTGRES_USER`: ecommerce
- `POSTGRES_PASSWORD`: (en secret)
- `POSTGRES_DB`: ecommerce_db

#### Microservicios
- `SPRING_PROFILES_ACTIVE`: dev
- `EUREKA_CLIENT_SERVICEURL_DEFAULTZONE`: http://service-discovery:8761/eureka/
- `SPRING_CONFIG_IMPORT`: optional:configserver:http://cloud-config:9296/
- `SPRING_ZIPKIN_BASE_URL`: http://zipkin:9411

### 11.2 Puertos de Servicios
```
PostgreSQL:         5432
Eureka:             8761
Cloud Config:       9296
Zipkin:             9411
Prometheus:         9090
Grafana:            3000
API Gateway:        80 (externo), 8200 (interno)
Proxy Client:       80 (externo), 8100 (interno)
User Service:       8700
Product Service:    8800
Order Service:      8600
Payment Service:    8500
Shipping Service:   8400
Favourite Service:  8300
```

### 11.3 Scripts Útiles

#### Script de Health Check Completo
```bash
#!/bin/bash
# health-check-all.sh

NAMESPACE="dev"
SERVICES=(
    "user-service:8700"
    "product-service:8800"
    "order-service:8600"
    "payment-service:8500"
    "shipping-service:8400"
    "favourite-service:8300"
    "api-gateway:8200"
    "proxy-client:8100"
)

echo "=== Health Check de Todos los Servicios ==="
for service in "${SERVICES[@]}"; do
    name="${service%:*}"
    port="${service#*:}"
    
    kubectl exec -n $NAMESPACE deployment/$name -- \
        wget -qO- localhost:$port/actuator/health 2>/dev/null
    
    if [ $? -eq 0 ]; then
        echo "✅ $name - OK"
    else
        echo "❌ $name - FAIL"
    fi
done
```

#### Script de Limpieza de Recursos
```bash
#!/bin/bash
# cleanup.sh - Eliminar pods en estado Error/Completed

kubectl delete pods -n dev --field-selector status.phase=Failed
kubectl delete pods -n dev --field-selector status.phase=Succeeded
```

### 11.4 Checklist de Deployment

- [ ] ConfigMaps actualizados
- [ ] Secrets creados
- [ ] PostgreSQL funcionando
- [ ] Service Discovery (Eureka) UP
- [ ] Cloud Config UP
- [ ] Todos los microservicios registrados en Eureka
- [ ] API Gateway accesible externamente
- [ ] Database migrations ejecutadas
- [ ] HPAs configurados y funcionando
- [ ] Network Policies aplicadas
- [ ] Monitoring stack (Prometheus/Grafana) funcionando
- [ ] Zipkin recibiendo trazas
- [ ] Logs accesibles
- [ ] Backups configurados

### 11.5 Contactos y Escalamiento

**Equipo de Operaciones**
- Email: ops@ecommerce.com
- Slack: #ecommerce-ops
- On-call: PagerDuty

**Niveles de Escalamiento**
1. Nivel 1: DevOps Engineer (troubleshooting básico)
2. Nivel 2: Platform Engineer (problemas de cluster)
3. Nivel 3: Arquitecto (decisiones de arquitectura)

### 11.6 SLAs y Objetivos

**Service Level Objectives (SLO)**
- Uptime: 99.9% mensual
- Latencia p95: < 500ms
- Error rate: < 0.1%

**Recovery Time Objective (RTO)**
- Servicio crítico: 15 minutos
- Servicio no crítico: 1 hora

**Recovery Point Objective (RPO)**
- Database: 1 hora (backups cada hora)
- Configuración: 24 horas

---

## Fin del Manual

**Última actualización**: 24 de noviembre de 2025
**Versión**: 1.0
**Mantenido por**: Equipo de Platform Engineering

Para preguntas o sugerencias sobre este manual, crear un issue en el repositorio o contactar al equipo de operaciones.
