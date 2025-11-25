# Diagramas de Arquitectura - E-commerce Microservices

## 1. Arquitectura General del Sistema

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          GOOGLE CLOUD PLATFORM (GKE)                        │
│                                                                             │
│  ┌────────────────────────────────────────────────────────────────────┐    │
│  │                      KUBERNETES CLUSTER                            │    │
│  │                                                                    │    │
│  │  ┌──────────────────────────────────────────────────────────┐     │    │
│  │  │              NAMESPACE: dev / qa / prod                  │     │    │
│  │  │                                                          │     │    │
│  │  │  ┌────────────────┐                                     │     │    │
│  │  │  │  LoadBalancer  │ ←── Internet (34.31.129.29)        │     │    │
│  │  │  │  API-GATEWAY   │                                     │     │    │
│  │  │  └────────┬───────┘                                     │     │    │
│  │  │           │                                             │     │    │
│  │  │           ├─────────────────┬─────────────┬────────────┤     │    │
│  │  │           ▼                 ▼             ▼            ▼     │    │
│  │  │  ┌──────────────┐  ┌──────────────┐  ┌──────────┐  ┌──────┐│    │
│  │  │  │ USER-SERVICE │  │PRODUCT-SERVICE│  │  ORDER   │  │PAYMENT││   │
│  │  │  │ ClusterIP    │  │  ClusterIP    │  │ SERVICE  │  │SERVICE││   │
│  │  │  └──────┬───────┘  └──────┬────────┘  └────┬─────┘  └──┬───┘│    │
│  │  │         │                  │                │           │    │    │
│  │  │  ┌──────────────┐  ┌──────────────┐  ┌──────────┐  ┌──────┐│    │
│  │  │  │  SHIPPING    │  │  FAVOURITE   │  │  PROXY   │  │ZIPKIN││   │
│  │  │  │  SERVICE     │  │  SERVICE     │  │  CLIENT  │  │      ││   │
│  │  │  └──────┬───────┘  └──────┬────────┘  └────┬─────┘  └──────┘│   │
│  │  │         │                  │                │                │    │
│  │  │         └──────────────────┴────────────────┘                │    │
│  │  │                            ▼                                 │    │
│  │  │                  ┌──────────────────┐                        │    │
│  │  │                  │   POSTGRESQL     │                        │    │
│  │  │                  │   StatefulSet    │                        │    │
│  │  │                  │  (PVC Storage)   │                        │    │
│  │  │                  └──────────────────┘                        │    │
│  │  │                                                              │    │
│  │  │  ┌─────────────────────────────────────────────────┐        │    │
│  │  │  │        SERVICIOS DE INFRAESTRUCTURA             │        │    │
│  │  │  │  ┌─────────────┐      ┌─────────────┐          │        │    │
│  │  │  │  │   EUREKA    │      │CLOUD-CONFIG │          │        │    │
│  │  │  │  │  (Service   │      │  (Config    │          │        │    │
│  │  │  │  │  Discovery) │      │  Server)    │          │        │    │
│  │  │  │  └─────────────┘      └─────────────┘          │        │    │
│  │  │  └─────────────────────────────────────────────────┘        │    │
│  │  │                                                              │    │
│  │  └──────────────────────────────────────────────────────────────┘    │
│  └────────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────┘
```

## 2. Flujo de Comunicación entre Servicios

```
┌──────────┐
│  Client  │
└────┬─────┘
     │ HTTP Request
     ▼
┌─────────────────────────────────────┐
│      API-GATEWAY (Port 80)          │
│  ┌───────────────────────────┐      │
│  │  Spring Cloud Gateway     │      │
│  │  - Routing                │      │
│  │  - Load Balancing         │      │
│  │  - Circuit Breaker        │      │
│  └───────────────────────────┘      │
└─────┬───────────────────────────────┘
      │
      │ Service Discovery via Eureka
      ▼
┌──────────────────────────────────────┐
│   EUREKA (Service Discovery)         │
│   - Registro de servicios            │
│   - Health Checks                    │
│   - Load Balancing                   │
└──────────────────────────────────────┘
      │
      │ Routes to:
      ├──────────────┬──────────────┬──────────────┐
      ▼              ▼              ▼              ▼
┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐
│  USER    │  │ PRODUCT  │  │  ORDER   │  │ PAYMENT  │
│ SERVICE  │  │ SERVICE  │  │ SERVICE  │  │ SERVICE  │
│          │  │          │  │          │  │          │
│ Port:    │  │ Port:    │  │ Port:    │  │ Port:    │
│ 8700     │  │ 8500     │  │ 8300     │  │ 8400     │
└────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘
     │            │              │              │
     └────────────┴──────────────┴──────────────┘
                  │
                  ▼
         ┌─────────────────┐
         │   PostgreSQL    │
         │   - user_db     │
         │   - product_db  │
         │   - order_db    │
         │   - payment_db  │
         └─────────────────┘
```

## 3. Arquitectura de Despliegue en Kubernetes

```
NAMESPACE: dev
═══════════════════════════════════════════════════════════════

ConfigMaps                    Secrets
├── api-gateway-config        ├── order-service-secret
├── user-service-config       ├── payment-service-secret
├── product-service-config    ├── shipping-service-secret
├── order-service-config      └── favourite-service-secret
├── payment-service-config
├── shipping-service-config
├── favourite-service-config
└── proxy-client-config

Deployments (Replicas: 1)     Services (ClusterIP)
├── service-discovery         ├── service-discovery:8761
├── cloud-config              ├── cloud-config:9296
├── api-gateway (LoadBalancer)├── api-gateway:80
├── user-service              ├── user-service:8700
├── product-service           ├── product-service:8500
├── order-service             ├── order-service:8300
├── payment-service           ├── payment-service:8400
├── shipping-service          ├── shipping-service:8600
├── favourite-service         ├── favourite-service:8800
├── proxy-client              ├── proxy-client:8900
└── zipkin                    └── zipkin:9411

StatefulSet                   PersistentVolumeClaim
└── postgres (replicas: 1)    └── postgres-pvc-postgres-0
                                  - Size: 5Gi
                                  - StorageClass: standard-rwo
```

## 4. Flujo de Configuración

```
┌─────────────────────────────────────────────────────────────┐
│                   CONFIGURACIÓN CENTRALIZADA                 │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
                    ┌──────────────────┐
                    │  CLOUD-CONFIG    │
                    │   Server         │
                    │   Port: 9296     │
                    └────────┬─────────┘
                             │
        ┌────────────────────┼────────────────────┐
        │                    │                    │
        ▼                    ▼                    ▼
┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│ ConfigMaps   │    │Environment   │    │  Secrets     │
│ (K8s)        │    │Variables     │    │  (K8s)       │
│              │    │(SPRING_*)    │    │              │
│- Eureka URL  │    │- Profiles    │    │- DB Password │
│- Zipkin URL  │    │- DB URL      │    │              │
└──────────────┘    └──────────────┘    └──────────────┘
        │                    │                    │
        └────────────────────┼────────────────────┘
                             │
                             ▼
                    ┌──────────────────┐
                    │  Microservicio   │
                    │  Spring Boot     │
                    └──────────────────┘
```

## 5. Observabilidad y Monitoreo

```
┌─────────────────────────────────────────────────────────────┐
│                    STACK DE OBSERVABILIDAD                   │
└─────────────────────────────────────────────────────────────┘

┌──────────────┐         ┌──────────────┐         ┌──────────────┐
│   ZIPKIN     │         │  PROMETHEUS  │         │   GRAFANA    │
│  (Tracing)   │         │  (Metrics)   │         │(Visualization)│
│              │         │              │         │              │
│ Port: 9411   │         │ Port: 9090   │         │ Port: 3000   │
└──────┬───────┘         └──────┬───────┘         └──────┬───────┘
       │                        │                        │
       │ Distributed Traces     │ Metrics Collection     │ Dashboards
       │                        │                        │
       └────────────────────────┼────────────────────────┘
                                │
                                ▼
                  ┌──────────────────────────────┐
                  │     MICROSERVICIOS           │
                  │                              │
                  │  ┌────────────────────────┐  │
                  │  │ Spring Boot Actuator  │  │
                  │  │  /actuator/health     │  │
                  │  │  /actuator/metrics    │  │
                  │  │  /actuator/prometheus │  │
                  │  └────────────────────────┘  │
                  └──────────────────────────────┘
```

## 6. Seguridad y Acceso

```
Internet
   │
   ▼
┌──────────────────────────────────────┐
│  Google Cloud Load Balancer          │
│  IP: 34.31.129.29                    │
└────────────┬─────────────────────────┘
             │
             ▼
┌──────────────────────────────────────┐
│  Kubernetes Service                  │
│  Type: LoadBalancer                  │
│  api-gateway                         │
└────────────┬─────────────────────────┘
             │
             ▼
┌──────────────────────────────────────┐
│  API Gateway Pod                     │
│  - Spring Cloud Gateway              │
│  - Circuit Breaker                   │
│  - CORS Configuration                │
└────────────┬─────────────────────────┘
             │
             │ Internal Communication
             ▼
┌──────────────────────────────────────┐
│  ClusterIP Services (Internal)       │
│  - user-service:8700                 │
│  - product-service:8500              │
│  - order-service:8300                │
│  - etc...                            │
└──────────────────────────────────────┘
```

## 7. Persistencia de Datos

```
┌─────────────────────────────────────────────────────────────┐
│                    POSTGRESQL STATEFULSET                    │
└─────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────┐
│  postgres-0 (Pod)                                            │
│  ┌────────────────────────────────────────────────────────┐  │
│  │  PostgreSQL Container                                  │  │
│  │  Port: 5432                                            │  │
│  │  ┌──────────────────────────────────────────────────┐  │  │
│  │  │  Databases:                                      │  │  │
│  │  │  ├── user_db (schema: flyway_schema_history)    │  │  │
│  │  │  ├── product_db                                  │  │  │
│  │  │  ├── order_db                                    │  │  │
│  │  │  ├── payment_db                                  │  │  │
│  │  │  ├── shipping_db                                 │  │  │
│  │  │  └── favourite_db                                │  │  │
│  │  └──────────────────────────────────────────────────┘  │  │
│  └────────────────────────────────────────────────────────┘  │
│                          │                                    │
│                          ▼                                    │
│  ┌────────────────────────────────────────────────────────┐  │
│  │  PersistentVolumeClaim: postgres-pvc-postgres-0       │  │
│  │  - Storage: 5Gi                                       │  │
│  │  - StorageClass: standard-rwo                         │  │
│  │  - AccessMode: ReadWriteOnce                          │  │
│  └────────────────────────────────────────────────────────┘  │
│                          │                                    │
└──────────────────────────┼────────────────────────────────────┘
                           ▼
              ┌─────────────────────────────┐
              │  Google Persistent Disk     │
              │  (GCE Storage Backend)      │
              └─────────────────────────────┘
```

## 8. Health Checks y Liveness

```
Kubernetes Health Check Strategy
═════════════════════════════════

Para cada microservicio:

┌──────────────────────────────────────────┐
│  Pod Lifecycle                           │
│                                          │
│  ┌────────────────────────────────────┐  │
│  │  Startup Probe                     │  │
│  │  - Initial delay: 30s              │  │
│  │  - Period: 10s                     │  │
│  │  │ Failure threshold: 30           │  │
│  │  - Endpoint: /actuator/health      │  │
│  └────────────┬───────────────────────┘  │
│               │ Success                  │
│               ▼                          │
│  ┌────────────────────────────────────┐  │
│  │  Liveness Probe                    │  │
│  │  - Period: 20s                     │  │
│  │  - Failure threshold: 3            │  │
│  │  - Endpoint: /actuator/health      │  │
│  └────────────┬───────────────────────┘  │
│               │ Continuous               │
│               ▼                          │
│  ┌────────────────────────────────────┐  │
│  │  Readiness Probe                   │  │
│  │  - Period: 10s                     │  │
│  │  - Failure threshold: 3            │  │
│  │  - Endpoint: /actuator/health      │  │
│  └────────────────────────────────────┘  │
└──────────────────────────────────────────┘
```

## 9. Rutas del API Gateway

```
API Gateway Routing Configuration
══════════════════════════════════

Client Request → http://34.31.129.29/{path}
                                │
                                ▼
┌───────────────────────────────────────────────────────────┐
│  Spring Cloud Gateway Routes                              │
├───────────────────────────────────────────────────────────┤
│                                                           │
│  /user-service/**      → lb://USER-SERVICE:8700          │
│  /product-service/**   → lb://PRODUCT-SERVICE:8500       │
│  /order-service/**     → lb://ORDER-SERVICE:8300         │
│  /payment-service/**   → lb://PAYMENT-SERVICE:8400       │
│  /shipping-service/**  → lb://SHIPPING-SERVICE:8600      │
│  /favourite-service/** → lb://FAVOURITE-SERVICE:8800     │
│  /app/**               → lb://PROXY-CLIENT:8900          │
│                                                           │
│  lb:// = Load Balanced via Eureka Service Discovery      │
└───────────────────────────────────────────────────────────┘
```

## 10. Recursos Computacionales

```
Resource Allocation per Service
════════════════════════════════

┌──────────────────┬──────────────┬──────────────┬───────────┐
│    Service       │  CPU Request │  CPU Limit   │  Memory   │
├──────────────────┼──────────────┼──────────────┼───────────┤
│ api-gateway      │    200m      │    500m      │   512Mi   │
│ user-service     │    150m      │    400m      │   512Mi   │
│ product-service  │    150m      │    400m      │   512Mi   │
│ order-service    │    150m      │    400m      │   512Mi   │
│ payment-service  │    150m      │    400m      │   512Mi   │
│ shipping-service │    150m      │    400m      │   512Mi   │
│ favourite-service│    150m      │    400m      │   512Mi   │
│ proxy-client     │    150m      │    300m      │   384Mi   │
│ postgres         │    250m      │    500m      │   1Gi     │
│ zipkin           │    150m      │    300m      │   512Mi   │
│ eureka           │    150m      │    300m      │   384Mi   │
│ cloud-config     │    100m      │    200m      │   256Mi   │
└──────────────────┴──────────────┴──────────────┴───────────┘

Total Cluster Resources:
- Nodes: 8 x e2-medium (2 vCPU, 4GB RAM each)
- Total: 16 vCPUs, 32GB RAM
- Utilization: ~70%
```

---

**Última actualización:** 24 de noviembre de 2025  
**Versión:** 1.0  
**Estado:** Producción en GKE
