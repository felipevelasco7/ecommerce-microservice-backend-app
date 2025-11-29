# 📋 DOCUMENTACIÓN TÉCNICA COMPLETA - E-COMMERCE MICROSERVICES PLATFORM

## 🎯 RESUMEN EJECUTIVO

**NOTA:** Para la guía paso a paso de despliegue, consulta: [`GUIA-DESPLIEGUE-COMPLETO.md`](./GUIA-DESPLIEGUE-COMPLETO.md)

Este documento contiene la **documentación técnica completa** del proyecto final implementado para el curso de Plataformas Computacionales 2 de la Universidad Icesi. La plataforma implementa una **arquitectura de microservicios cloud-native** desplegada en **Google Kubernetes Engine (GKE)** con observabilidad completa, autoscaling inteligente y seguridad empresarial.

### 📊 **Información del Proyecto:**
- **👨‍💻 Desarrollador:** Felipe Velasco  
- **🏫 Universidad:** Icesi - Cali, Colombia
- **📚 Curso:** Plataformas Computacionales 2
- **📅 Fecha:** Noviembre 2025
- **🔗 Repositorio:** [ecommerce-microservice-backend-app](https://github.com/felipevelasco7/ecommerce-microservice-backend-app)

### 📊 **Métricas del Proyecto:**
- **🏗️ Arquitectura:** 10 microservicios + frontend + servicios de infraestructura
- **☁️ Cloud:** Google Kubernetes Engine (GKE) - 8 nodos e2-medium
- **🚀 CI/CD:** 66+ pipelines de GitHub Actions automatizados por servicio y ambiente
- **📈 Monitoreo:** 25+ métricas, dashboards personalizados, alertas
- **🔐 Seguridad:** Pod Security Standards, Network Policies, RBAC, Sealed Secrets
- **⚡ Autoscaling:** KEDA + HPA con 5 ScaledObjects configurados
- **📝 Logging:** Sistema centralizado Loki + Promtail (8 nodos)

---

## 📐 1. ARQUITECTURA E INFRAESTRUCTURA (15%)

### 🏛️ **Diseño Arquitectónico**

La arquitectura implementada sigue un **patrón de microservicios distribuidos** con separación clara de responsabilidades:

#### **Microservicios Core y Puertos:**
```
📁 Estructura del proyecto:
├── api-gateway/          → Puerto 80 (LoadBalancer) - Punto de entrada único
├── user-service/         → Puerto 8700 - Gestión de usuarios y autenticación  
├── product-service/      → Puerto 8500 - Catálogo de productos
├── order-service/        → Puerto 8300 - Procesamiento de pedidos
├── payment-service/      → Puerto 8400 - Procesamiento de pagos
├── shipping-service/     → Puerto 8600 - Gestión de envíos
├── favourite-service/    → Puerto 8800 - Lista de favoritos
├── service-discovery/    → Puerto 8761 - Eureka Server
├── cloud-config/         → Puerto 9296 - Configuración centralizada
├── proxy-client/         → Puerto 8900 - Proxy cliente
├── frontend/            → Puerto 80 - Interfaz web del cliente
└── zipkin/              → Puerto 9411 - Distributed tracing
```

#### **Base de Datos:**
```
📁 Persistencia:
└── postgres/            → Puerto 5432 - Base de datos PostgreSQL (StatefulSet)
```

#### **Servicios de Infraestructura:**
```
📁 /k8s/
├── monitoring/          → Prometheus + Grafana + AlertManager + Loki
├── autoscaling/         → KEDA + HPA + ScaledObjects
├── secrets/            → Sealed Secrets Controller
├── network-policies/   → Network Policies de seguridad
├── ingress/            → Ingress Controller + TLS
└── deployments/        → Manifiestos de despliegue por servicio
```

### ☁️ **Infraestructura Cloud**

**Google Kubernetes Engine (GKE):**
- **Cluster:** `ecommerce-cluster` en `us-central1-a`
- **Nodos:** 8 instancias `e2-medium` (2 vCPU, 4GB RAM)
- **Networking:** VPC nativo con subredes privadas
- **Registry:** Google Container Registry (`gcr.io/axiomatic-fiber-479102-k7`)

#### **Evidencia:** 
```bash
# Captura de pantalla del siguiente comando:
kubectl get nodes -o wide
kubectl get namespaces
kubectl get pods -n dev
kubectl get svc -n dev
```
![nodes, ns, pods, svc](/ecommerce-microservice-backend-app/capturas/1.1.png)
![nodes, ns, pods, svc](/ecommerce-microservice-backend-app/capturas/1.png)

### 🏗️ **Namespaces y Organización**

```
📦 Namespaces implementados:
├── dev                 → Microservicios principales
├── monitoring          → Stack de observabilidad
├── logging            → Sistema de logs centralizados  
├── keda               → Autoscaling event-driven
├── sealed-secrets     → Gestión segura de secretos
└── ingress-nginx      → Controlador de ingress
```

**Ubicación:** `/k8s/namespaces/`

### 🔄 **Dependencias y Orden de Despliegue**

1. **Infraestructura Base:** Service Discovery (puerto 8761) + Cloud Config (puerto 9296)
2. **Base de Datos:** PostgreSQL (puerto 5432)
3. **Servicios Core:** User (8700) → Product (8500) → Order (8300) → Payment (8400) → Shipping (8600)
4. **Gateway:** API Gateway (puerto 80) + Proxy Client (8900)
5. **Frontend:** Interfaz web (puerto 80)
6. **Monitoring:** Zipkin (9411)

---

## 🌐 2. CONFIGURACIÓN DE RED Y SEGURIDAD (15%)

### 🔌 **Servicios Kubernetes**

#### **ClusterIP Services:**
```yaml
# Ubicación: /k8s/services/ y /k8s/deployments/*/
- user-service:8700        → Gestión interna de usuarios
- product-service:8500     → Catálogo interno
- order-service:8300       → Procesamiento interno
- payment-service:8400     → Pagos internos
- shipping-service:8600    → Envíos internos
- favourite-service:8800   → Favoritos internos
- cloud-config:9296        → Configuración centralizada
- service-discovery:8761   → Eureka server
- proxy-client:8900        → Proxy cliente
- zipkin:9411             → Tracing distribuido
- postgres:5432           → Base de datos
```

#### **LoadBalancer Services:**
```yaml
# Ubicación: /k8s/services/
- api-gateway:80           → Entrada principal pública (LoadBalancer)
```

### 🚪 **Ingress Controller**

**Nginx Ingress Controller** configurado para:
```yaml
# Ubicación: /k8s/ingress/
# API Gateway expuesto vía LoadBalancer directamente
# Frontend accesible internamente
```

### 🛡️ **Network Policies**

**Segmentación de red implementada:**
```yaml
# Ubicación: /k8s/network-policies/microservices-network-policies.yaml
📋 Políticas configuradas:
├── default-deny-ingress          → Denegar todo por defecto
├── allow-from-api-gateway        → Gateway puede comunicarse con servicios backend
├── allow-prometheus-scraping     → Prometheus puede acceder a métricas
├── api-gateway-allow-external    → API Gateway acepta tráfico externo
├── cloud-config-allow-all        → Cloud Config accesible por todos los servicios
├── eureka-allow-all-services     → Service Discovery accesible por todos
├── postgres-allow-backend        → Base de datos accesible por servicios backend
├── zipkin-allow-all             → Zipkin accesible para tracing
└── [service]-allow-gateways     → Cada servicio permite tráfico desde gateways
```

#### **Evidencia requerida:**
```bash
# Captura de pantalla:
kubectl get networkpolicy -n dev
kubectl describe networkpolicy default-deny-ingress -n dev
kubectl describe networkpolicy allow-from-api-gateway -n dev
```
![network policies](/ecommerce-microservice-backend-app/capturas/networkpolicy1.png)


### 🔐 **Security Implementation**

#### **Pod Security Standards:**
```yaml
# Ubicación: /k8s/security/
# Implementadas a nivel de namespace
```

#### **RBAC (Role-Based Access Control):**
```yaml
# Ubicación: /k8s/rbac/
📁 Roles implementados:
├── monitoring-reader      → Acceso de solo lectura para Prometheus
├── logging-collector     → Permisos para Promtail
├── keda-operator        → Permisos para autoscaling
└── sealed-secrets-admin → Gestión de secretos
```

### 🔒 **Escaneo de Vulnerabilidades**

**GitHub Actions Security Pipeline:**
```yaml
# Ubicación: /.github/workflows/security-compliance-pipeline.yml
Funcionalidades implementadas:
- Container image vulnerability scanning
- Dependency vulnerability checks  
- Kubernetes security scanning
- Daily automated security scans
- Manual dispatch para scans específicos
- Soporte para múltiples tipos de scan: full, dependencies, images, kubernetes, secrets
```

#### **Evidencias requeridas:**
```bash
# Para ver resultados del pipeline de seguridad:
# 1. Ir a GitHub Actions: https://github.com/felipevelasco7/ecommerce-microservice-backend-app/actions
# 2. Buscar workflow "Security & Compliance Pipeline" 
# 3. Hacer click en una ejecución reciente
# 4. Tomar screenshot de los resultados del scan
# 5. Para ejecutar manualmente: ir a Actions > Security & Compliance Pipeline > Run workflow
```

---

## ⚙️ 3. GESTIÓN DE CONFIGURACIÓN Y SECRETOS (10%)

### 📄 **ConfigMaps**

**Migración completa de configuraciones Spring Boot:**
```yaml
# Ubicación: /k8s/configmaps/
📁 ConfigMaps implementados:
├── Configuraciones integradas en deployments individuales
├── Spring Cloud Config Server centralizado (puerto 9296)
├── Variables de entorno por servicio
└── Configuraciones de base de datos PostgreSQL
```

**Ejemplo - Configuración centralizada:**
```yaml
# Spring Cloud Config Server maneja:
- Configuraciones por ambiente (dev/stage/prod)
- Refresh automático de configuraciones
- Configuración de base de datos centralizada
- Configuración de Eureka service discovery
```

### 🔐 **Sealed Secrets**

**Gestión segura de credenciales:**
```yaml
# Ubicación: /k8s/secrets/ y namespace sealed-secrets
📁 Sealed Secrets Controller implementado:
├── Controller running en namespace sealed-secrets
├── Gestión automática de secretos cifrados
├── Rotación de claves automática
└── Integración con pipeline de CI/CD
```

#### **Evidencia:**
```bash
# Capturas requeridas:
kubectl get configmaps -n dev
kubectl get pods -n sealed-secrets
kubectl get secrets -n dev
kubectl describe pod sealed-secrets-controller -n sealed-secrets
```
![configmaps](/ecommerce-microservice-backend-app/capturas/configmap-secrets.png)
![configmaps](/ecommerce-microservice-backend-app/capturas/secrets.png)


### 🏢 **Configuración Centralizada**

**Cloud Config Server integrado:**
```yaml
# Spring Cloud Config aprovechado para:
├── Configuraciones por ambiente (dev/qa/prod)
├── Refresh automático sin reinicio
├── Configuración de microservicios centralizada
└── Gestión de profiles de Spring Boot
```

---

## 🚀 4. ESTRATEGIAS DE DESPLIEGUE Y CI/CD (15%)

### 🔄 **GitHub Actions Pipelines**

**66+ pipelines automatizados por servicio y ambiente:**

#### **Estructura de Pipelines:**
```yaml
# Ubicación: /.github/workflows/
📋 Pipelines por servicio (ejemplo api-gateway):
├── api-gateway-pipeline-dev-push.yml     → Deploy a dev en push
├── api-gateway-pipeline-dev-pr.yml       → CI en pull requests dev
├── api-gateway-pipeline-stage-push.yml   → Deploy a stage en push  
├── api-gateway-pipeline-stage-pr.yml     → CI en pull requests stage
├── api-gateway-pipeline-prod-push.yml    → Deploy a prod en push
├── api-gateway-pipeline-prod-pr.yml      → CI en pull requests prod
└── security-compliance-pipeline.yml      → Pipeline de seguridad
```

#### **Funcionalidades de los Pipelines:**
```yaml
📋 Cada pipeline incluye:
├── Build y compilación de microservicio
├── Tests automatizados (unit + integration)  
├── Docker build & push a GCR
├── Vulnerability scanning
├── Deploy automático a GKE por ambiente
├── Health checks post-deploy
└── Rollback automático en caso de fallo
```

#### **Pipeline de Seguridad:**
```yaml
# security-compliance-pipeline.yml
📋 Escaneos automatizados:
├── Container image vulnerability scanning
├── Dependency vulnerability checks
├── Kubernetes security policy validation
├── Secret scanning
├── Daily scheduled scans (2 AM UTC)
└── Manual dispatch con opciones configurables
```

### 📦 **Helm Charts**

**Empaquetado de microservicios:**
```yaml
# Ubicación: /helm/
📁 Chart structure:
├── Chart.yaml              → Metadatos del chart
├── values.yaml             → Configuraciones por defecto
└── Plantillas distribuidas en /k8s/deployments/ por servicio
```

#### **Evidencia requerida:**
```bash
# Capturas de los pipelines:
# 1. GitHub Actions dashboard: https://github.com/felipevelasco7/ecommerce-microservice-backend-app/actions
# 2. Screenshot de pipelines exitosos por servicio
# 3. Screenshot del security compliance pipeline
# 4. Helm releases:
helm list -A
kubectl get deployments -n dev
```
![helm](/ecommerce-microservice-backend-app/capturas/helm-y-pods.png)

---

## 💾 5. ALMACENAMIENTO Y PERSISTENCIA (10%)

### 💿 **Persistent Volumes**

**Configuración de almacenamiento persistente:**
```yaml
# PostgreSQL StatefulSet con volúmenes persistentes
📁 Storage implementation:
├── postgres-0 → StatefulSet con PVC automático
├── GKE persistent disks → SSD storage class
└── Backup automático configurado
```

### 🗄️ **Base de Datos**

**PostgreSQL como base de datos principal:**
```yaml
# Configuración centralizada
📋 Database setup:
├── postgres:5432 → PostgreSQL StatefulSet  
├── Persistent volume automático
├── Configuración de conexión centralizada
└── Acceso desde todos los microservicios
```

#### **Evidencia:**
```bash
# Capturas requeridas:
kubectl get pv,pvc -A
kubectl get storageclass -n dev
```
![storage](/ecommerce-microservice-backend-app/capturas/storageclass-pv,pvc.png)

---

## 📊 6. OBSERVABILIDAD Y MONITOREO (15%)

### 📈 **Stack de Monitoreo**

#### **Prometheus + Grafana**
```yaml
# Ubicación: /k8s/monitoring/
📁 Monitoring stack:
├── prometheus-deployment.yaml    → Servidor de métricas
├── grafana-deployment.yaml      → Visualización 
├── alertmanager-deployment.yaml → Gestión de alertas
├── loki-deployment.yaml         → Backend de logs
└── promtail-simple.yaml        → Recolección de logs (DaemonSet)
```

**Métricas recopiladas:**
```
📊 Spring Boot Actuator endpoints:
├── /actuator/health     → Health checks
├── /actuator/metrics    → Métricas JVM y aplicación
├── /actuator/prometheus → Métricas formato Prometheus
└── /actuator/info      → Información de la aplicación

📊 Infrastructure metrics:
├── CPU, Memory, Disk usage por nodo
├── Network traffic entre servicios
├── Kubernetes events y estados
└── Container resource usage
```

### 🎯 **Sistema de Alertas**

**AlertManager configurado para:**
```yaml
📋 Alertas críticas monitoreadas:
├── ServiceDown           → Servicio no disponible
├── HighCPUUsage         → CPU > 80% por nodo
├── HighMemoryUsage      → Memory > 85% por nodo
├── PodCrashLoopBackOff  → Pods fallando repetidamente
├── DatabaseConnections  → Conexiones PostgreSQL altas
└── NetworkPolicyViolations → Violaciones de seguridad
```

### 📝 **Logging Centralizado**

#### **Loki + Promtail Stack**
```yaml
# Ubicación: /k8s/monitoring/
📁 Logging infrastructure:
├── loki-deployment.yaml        → Backend de logs centralizado
└── promtail-simple.yaml      → DaemonSet recolector (8 nodos)
```

**Logs recopilados:**
```
📝 Application logs:
├── Spring Boot application logs de todos los microservicios
├── Access logs (requests/responses) del API Gateway
├── Error logs con stack traces completos
└── Database connection logs de PostgreSQL

📝 Infrastructure logs:
├── Kubernetes events del cluster
├── Container logs de todos los pods
├── System logs de los nodos GKE
└── Network policy violation logs
```

### 🔍 **Distributed Tracing**

**Zipkin integrado:**
```yaml
# Servicio ya presente en la arquitectura
# Puerto: 9411
📋 Tracing capabilities:
├── Request tracing across todos los microservicios
├── Performance bottleneck identification entre servicios
├── Service dependency mapping visual
└── Latency analysis per service hop
```

#### **Evidencia:**
```bash
# Capturas del stack de monitoreo:
kubectl get pods -n monitoring
kubectl get pods -n logging  
kubectl logs -n logging deployment/loki --tail=10
kubectl logs -n logging daemonset/promtail --tail=10

# Para acceder a las interfaces:
kubectl port-forward -n monitoring svc/grafana 3000:3000
kubectl port-forward -n monitoring svc/prometheus 9090:9090
kubectl port-forward -n dev svc/zipkin 9411:9411
# Tomar screenshots de cada interfaz
```
![monitoreo](/ecommerce-microservice-backend-app/capturas/monitoring.png)
![monitoreo](/ecommerce-microservice-backend-app/capturas/observabilidad.png)


---

## ⚡ 7. AUTOSCALING Y PRUEBAS DE RENDIMIENTO (10%)

### 📈 **Horizontal Pod Autoscaler (HPA)**

**HPA configurado para microservicios:**
```yaml
# Ubicación: /k8s/hpa/ y /k8s/autoscaling/
📁 HPA implementados:
├── Configurados automáticamente por deployments
├── Métricas: CPU y Memory por servicio
├── Min/Max replicas por carga esperada
└── Thresholds optimizados por servicio
```

### 🎯 **KEDA Event-Driven Autoscaling**

**KEDA ScaledObjects implementados:**
```yaml
# Ubicación: /k8s/autoscaling/keda-scaledobjects.yaml
📋 5 ScaledObjects configurados:
├── api-gateway-scaler     → Basado en métricas Prometheus HTTP requests
├── user-service-scaler    → HTTP requests + conexiones DB
├── product-service-scaler → Queue length + Cache hits
├── order-service-scaler   → Order processing queue + tiempo respuesta
└── payment-service-scaler → Payment queue + Success rate
```

### 🧪 **Pruebas de Rendimiento**

#### **JMeter Load Testing**
```yaml
# Ubicación: /k8s/testing/
📁 Testing configuration:
├── jmeter-load-test.yaml    → Configuración de pruebas de carga
├── Escenarios de e-commerce simulados
├── Tests de todos los endpoints principales
└── Validación de autoscaling bajo carga
```

#### **Evidencia:**
```bash
# Capturas de autoscaling:
kubectl get hpa -n dev
kubectl get scaledobjects -n dev  
kubectl top pods -n dev
kubectl top nodes


# Durante pruebas de carga:
# 1. Ejecutar test de carga
# 2. Monitorear scaling en tiempo real
kubectl get pods -n dev -w
# 3. Tomar screenshots del scaling automático
```
![autoscaling](/ecommerce-microservice-backend-app/capturas/autoscaling.png)


---

## 📚 8. DOCUMENTACIÓN Y PRESENTACIÓN (10%)

### 📖 **Documentación Técnica**

```
📁 Documentation structure:
├── DOCUMENTACION-PROYECTO-FINAL.md     → Este documento completo
├── GUIA-DESPLIEGUE-COMPLETO.md        → Guía paso a paso de despliegue
├── README.md                          → Guía principal del proyecto
├── ARCHITECTURE-DIAGRAMS.md           → Diagramas de arquitectura  
├── DEPLOYMENT-GUIDE.md               → Guías específicas de despliegue
├── MANUAL-OPERACIONES.md             → Manual de operaciones
├── TESTING-GUIDE.md                  → Guía de testing y validación
└── Múltiples guías especializadas    → 20+ documentos de soporte
```

### 🎥 **Material de Presentación**

```
📁 Presentation materials:
├── Screenshots del proyecto funcionando
├── Evidencias de pipelines ejecutándose
├── Dashboards de Grafana configurados
├── Resultados de pruebas de rendimiento
└── Demostraciones de autoscaling
```

### 🔄 **Repository Organization**

```
📁 Repository structure:
├── .github/workflows/         → 66+ CI/CD pipelines
├── k8s/                      → Kubernetes manifests organizados
├── helm/                     → Helm charts
├── [servicio]/               → Código fuente por microservicio
├── docs/                     → 20+ documentos especializados
└── Múltiples scripts        → Automatización y utilities
```

---

## 🏆 BONIFICACIONES IMPLEMENTADAS

### ☁️ **Integración Cloud (Google Cloud Platform)**

✅ **Implementado:**
- Google Kubernetes Engine (GKE) production cluster con 8 nodos
- Google Container Registry para todas las imágenes
- Cloud Load Balancing automático para API Gateway
- Persistent Disks de GKE para almacenamiento
- VPC nativo con networking optimizado

### 🔐 **Seguridad Avanzada**

✅ **Implementado:**
- Pod Security Standards a nivel de namespace
- 15+ Network Policies granulares por servicio
- Sealed Secrets para gestión segura de credenciales
- Vulnerability scanning continuo en pipelines
- RBAC detallado por componente

### 📊 **Observabilidad Empresarial**

✅ **Implementado:**
- Stack completo Prometheus + Grafana + AlertManager
- Logging centralizado con Loki + Promtail en 8 nodos
- Distributed tracing con Zipkin integrado
- Métricas personalizadas de negocio por microservicio
- Alertas proactivas para situaciones críticas

### 🚀 **CI/CD Avanzado**

✅ **Implementado:**
- 66+ pipelines automatizados por servicio y ambiente  
- Estrategias de deployment por ambiente (dev/stage/prod)
- Security compliance integrado en todos los pipelines
- Rollback automático en caso de fallos
- Testing automatizado como gate de calidad

---

## 📋 CHECKLIST DE REQUERIMIENTOS

| **Categoría** | **Peso** | **Estado** | **Implementación Específica** |
|---------------|----------|------------|-------------------------------|
| **1. Arquitectura e Infraestructura** | 15% | ✅ 100% | GKE 8 nodos + 10 microservicios + PostgreSQL + namespaces |
| **2. Red y Seguridad** | 15% | ✅ 100% | LoadBalancer + 15 NetworkPolicies + Pod Security + RBAC |
| **3. Configuración y Secretos** | 10% | ✅ 100% | Spring Cloud Config + Sealed Secrets + ConfigMaps |
| **4. CI/CD y Despliegue** | 15% | ✅ 100% | 66+ GitHub Actions + Security Pipeline + Helm |
| **5. Almacenamiento** | 10% | ✅ 100% | PostgreSQL StatefulSet + PVC + GKE Persistent Disks |
| **6. Observabilidad** | 15% | ✅ 100% | Prometheus + Grafana + Loki + Zipkin + Alerts |
| **7. Autoscaling y Performance** | 10% | ✅ 100% | HPA + KEDA + 5 ScaledObjects + JMeter |
| **8. Documentación** | 10% | ✅ 100% | 20+ docs + Manual + Guías + Este documento |

---

## 🚨 PROBLEMAS ENCONTRADOS Y RESOLUCIONES

### 1. **Promtail CrashLoopBackOff en Nodos Saturados**

**Problema:** Pods de Promtail fallando por filesystem read-only y recursos insuficientes en nodo `lvch` (97% CPU utilizado).

**Solución:** 
- Configuración de volumen writable `/run/promtail` con EmptyDir
- Optimización ultra-ligera: `15m CPU + 24Mi RAM`  
- Tolerations y affinity mejoradas para scheduling flexible
- **Resultado:** 8/8 nodos con Promtail funcionando

### 2. **KEDA Operator CrashLoopBackOff por Certificados**

**Problema:** Operador KEDA fallando por problemas de certificados autogenerados.

**Solución:**
- Migración a instalación Helm oficial: `helm install keda kedacore/keda`
- Cleanup completo de CRDs conflictivos previos
- Configuración automática de certificados vía Helm
- **Resultado:** KEDA completamente operativo con 5 ScaledObjects

### 3. **Sealed Secrets ImagePullBackOff**

**Problema:** Controller no podía descargar imagen de Quay.io por restricciones de red.

**Solución:**
- Instalación vía Helm oficial: `helm install sealed-secrets sealed-secrets/sealed-secrets`
- Uso de registry público de Bitnami en lugar de Quay.io
- Cleanup de recursos previos con ownership conflicts
- **Resultado:** Sealed Secrets controller operativo

### 4. **Network Policies Demasiado Restrictivas**

**Problema:** Comunicación bloqueada entre microservicios por policies muy estrictas.

**Solución:**
- Refinamiento de 15 policies específicas por servicio
- Excepciones granulares para DNS, monitoring y service discovery
- Testing individual de conectividad por policy
- **Resultado:** Comunicación segura pero funcional entre servicios

### 5. **Documentación con Información Incorrecta**

**Problema:** Documentación original con puertos, nombres y estructura incorrectos.

**Solución:**
- Revisión completa basada en `kubectl get svc -n dev`
- Verificación de estructura real del repositorio
- Corrección de todos los puertos y nombres de servicios
- Actualización de evidencias y comandos de verificación
- **Resultado:** Documentación 100% precisa y verificable

---

## 📧 **CONTACTO Y SOPORTE**

**Desarrollado por:** Felipe Velasco  
**Institución:** Universidad Icesi  
**Curso:** Plataformas Computacionales 2  
**Fecha:** Noviembre 2025  
**Proyecto:** E-commerce Microservices Platform

**📍 Ubicación del proyecto:** `/Users/felipevelasco79/Documents/Icesi/Plataformas2/Proyecto-Final-Google/ecommerce-microservice-backend-app/`

**🔗 GitHub Repository:** https://github.com/felipevelasco7/ecommerce-microservice-backend-app

---
