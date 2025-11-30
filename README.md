# 🛒 E-commerce Microservices Platform
### Plataforma de E-commerce Basada en Microservicios | Universidad Icesi | Plataformas Computacionales 2

[![Java](https://img.shields.io/badge/Java-11-orange.svg)](https://openjdk.java.net/projects/jdk/11/)
[![Spring Boot](https://img.shields.io/badge/Spring%20Boot-2.7.0-brightgreen.svg)](https://spring.io/projects/spring-boot)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-GKE-blue.svg)](https://cloud.google.com/kubernetes-engine)
[![Docker](https://img.shields.io/badge/Docker-Containerized-2496ED.svg)](https://www.docker.com/)

## 🎯 **Descripción del Proyecto**

Plataforma completa de e-commerce implementada con arquitectura de microservicios, desplegada en Google Kubernetes Engine (GKE) con observabilidad completa, autoscaling inteligente y seguridad avanzada.

### ⭐ **Características Principales**
- 🏗️ **11 Microservicios** independientes y escalables
- 🌐 **Frontend web** moderno e interactivo  
- 📊 **Observabilidad completa** con Prometheus, Grafana y Zipkin
- 🔒 **Seguridad robusta** con Network Policies y Pod Security Standards
- 🚀 **Autoscaling inteligente** con KEDA y HPA
- ⚡ **CI/CD automatizado** con 60+ pipelines GitHub Actions
- 🔄 **Service Discovery** con Eureka Server
- 💾 **Persistencia** con PostgreSQL y Redis

## 🏗️ **Arquitectura del Sistema**

### 📋 **Estructura de Carpetas Organizada**

```
📦 ecommerce-microservice-backend-app/
├── 📁 microservices/              # 🎯 Código fuente de microservicios
│   ├── api-gateway/               # 🚪 Gateway principal y enrutamiento (Puerto 80)
│   ├── user-service/              # 👤 Gestión de usuarios y autenticación (Puerto 8700)
│   ├── product-service/           # 📦 Catálogo de productos y inventario (Puerto 8500)
│   ├── order-service/             # 🛍️ Procesamiento y gestión de pedidos (Puerto 8300)
│   ├── payment-service/           # 💳 Procesamiento de pagos y facturación (Puerto 8400)
│   ├── shipping-service/          # 🚚 Gestión de envíos y logística (Puerto 8600)
│   ├── favourite-service/         # ❤️ Lista de favoritos y wishlists (Puerto 8800)
│   ├── service-discovery/         # 🔍 Eureka Server - Service Registry (Puerto 8761)
│   ├── cloud-config/              # ⚙️ Configuración centralizada (Puerto 9296)
│   ├── proxy-client/              # 🔄 Proxy cliente y load balancing (Puerto 8900)
│   └── frontend/                  # 🌐 Interfaz web React/Angular (Puerto 80)
│
├── 📁 k8s/                        # ☸️ Manifiestos Kubernetes completos
│   ├── deployments/               # 🚀 Deployments por cada microservicio
│   ├── services/                  # 🔗 Servicios Kubernetes y LoadBalancers
│   ├── ingress/                   # 🌐 Reglas Ingress y enrutamiento externo
│   ├── configmaps/               # ⚙️ Configuraciones por ambiente
│   ├── secrets/                   # 🔐 Secretos y Sealed Secrets seguros
│   ├── monitoring/                # 📊 Stack completo: Prometheus + Grafana + Loki + Zipkin
│   ├── network-policies/          # 🛡️ Políticas de red y microsegmentación
│   ├── autoscaling/              # 📈 KEDA ScaledObjects y métricas customizadas
│   ├── security/                  # 🔒 Pod Security Standards y políticas
│   ├── rbac/                     # 👥 Roles, ServiceAccounts y permisos
│   ├── namespaces/               # 📦 Separación de ambientes (dev, staging, prod)
│   ├── backup/                   # 💾 Configuraciones de backup automatizado
│   ├── hpa/                      # 📊 Horizontal Pod Autoscalers
│   └── testing/                  # 🧪 Jobs de testing y validación
│
├── 📁 helm/                       # Helm Charts
│   ├── Chart.yaml                # Metadatos del chart
│   └── values.yaml               # Valores de configuración
│
├── 📁 .github/workflows/          # 🔄 CI/CD Pipelines automatizados
│   ├── *-pipeline-dev-*.yml      # 🚧 Pipelines de desarrollo
│   ├── *-pipeline-stage-*.yml    # 🧪 Pipelines de staging  
│   ├── *-pipeline-prod-*.yml     # 🚀 Pipelines de producción
│   ├── blue-green-deployment.yml # 🔄 Despliegue Blue-Green
│   ├── canary-deployment.yml     # 🐦 Despliegue Canary
│   ├── security-compliance-*.yml # 🔒 Validaciones de seguridad
│   └── emergency-rollback.yml    # ⚡ Rollback de emergencia
│
├── 📁 docs/                       # Documentación
│   ├── README.md                 # Documentación principal
│   ├── DOCUMENTACION-PROYECTO-FINAL-CORREGIDA.md  # Doc completa del proyecto
│   ├── GUIA-DESPLIEGUE-COMPLETO.md               # Guía paso a paso
│   ├── guides/                   # Guías específicas
│   │   ├── DEPLOYMENT-GUIDE.md   # Guía de despliegue
│   │   ├── TESTING-GUIDE.md      # Guía de testing
│   │   ├── FRONTEND-GUIDE.md     # Guía del frontend
│   │   ├── ZIPKIN-SETUP.md       # Configuración Zipkin
│   │   └── *.md                  # Otras guías especializadas
│   ├── architecture/             # Documentación de arquitectura
│   │   └── ARCHITECTURE-DIAGRAMS.md
│   └── operations/               # Manuales operativos
│       ├── MANUAL-OPERACIONES.md
│       └── PAUSA-REANUDACION-CLUSTER.md
│
├── 📁 scripts/                    # 🔧 Scripts de automatización avanzada
│   ├── deployment/               # 🚀 Scripts de despliegue y build
│   │   ├── build-all-services.sh      # 🏗️ Construcción masiva de servicios
│   │   ├── build-and-deploy-all.sh    # 🔄 Build + Deploy en un solo comando
│   │   ├── deploy-all-services.sh     # 📦 Despliegue completo a Kubernetes
│   │   ├── deploy-monitoring.sh       # 📊 Setup del stack de observabilidad
│   │   ├── add-service-accounts.sh    # 👤 Configuración de Service Accounts
│   │   └── update-dockerfiles.sh      # 🐳 Actualización masiva de Dockerfiles
│   ├── testing/                  # 🧪 Suite completa de testing
│   │   ├── test-ecommerce.sh         # 🛒 Testing end-to-end del e-commerce
│   │   ├── test.sh                   # 🔍 Tests unitarios y de integración  
│   │   └── generar-evidencias.sh     # 📋 Generación automática de evidencias
│   └── management/               # ⚙️ Gestión operacional del cluster
│       ├── restart-services.sh       # 🔄 Reinicio inteligente de servicios
│       ├── pause-cluster.sh          # ⏸️ Pausa del cluster (ahorro costos)
│       ├── resume-cluster.sh         # ▶️ Reanudación del cluster
│       ├── rebuild-clean.sh          # 🧹 Rebuild completo con clean build
│       ├── rebuild-with-zipkin.sh    # 🔍 Rebuild habilitando Zipkin tracing
│       ├── redeploy-with-zipkin.sh   # 📊 Redeploy con observabilidad completa
│       ├── start-demo.sh             # 🎯 Inicio rápido para demos
│       ├── verify-resume.sh          # ✅ Verificación post-reanudación
│       ├── verify.sh                 # 🔍 Verificación de estado general
│       ├── scr.sh                    # 🗄️ Scripts de migración DB
│       └── db.sh                     # 💾 Gestión de base de datos
│
├── 📁 ci-cd/                      # Configuraciones CI/CD
│   ├── cloudbuild/               # Google Cloud Build
│   │   ├── cloudbuild-*.yaml     # Builds por servicio
│   │   └── cloudbuild.yaml       # Build principal
│   └── azure/                    # Azure DevOps
│       └── azure-pipelines.yml
│
├── 📁 assets/                     # Recursos estáticos
│   ├── diagrams/                 # Diagramas de arquitectura
│   ├── screenshots/              # Capturas de pantalla
│   │   └── capturas/            # Evidencias del proyecto
│   └── dashboards/               # Dashboards Grafana
│       └── grafana-ecommerce-dashboard.json
│
├── 📁 .mvn/                       # Maven wrapper
├── 📄 pom.xml                     # Configuración Maven principal
├── 📄 compose.yml                 # Docker Compose (desarrollo local)
├── 📄 mvnw                        # Maven wrapper script
├── 📄 mvnw.cmd                    # Maven wrapper Windows
├── 📄 system.properties           # Propiedades del sistema
└── 📄 security-suppressions.xml   # Configuración de seguridad
```

## 🚀 **Inicio Rápido**

### 🎯 **Opción 1: Despliegue Automatizado (Recomendado)**
```bash
# 1. Clonar el repositorio
git clone https://github.com/felipevelasco7/ecommerce-microservice-backend-app.git
cd ecommerce-microservice-backend-app

# 2. Configurar GCP y Kubernetes
gcloud auth login
gcloud config set project YOUR_PROJECT_ID
gcloud container clusters get-credentials ecommerce-cluster --zone us-central1-a

# 3. Despliegue completo con un comando
./scripts/deployment/build-and-deploy-all.sh
```

### ⚡ **Opción 2: Demo Rápido**
```bash
# Iniciar demo completo (incluye datos de prueba)
./scripts/management/start-demo.sh

# Generar evidencias automáticamente
./scripts/testing/generar-evidencias.sh
```

### 🧪 **Testing y Validación**
```bash
# Testing completo end-to-end
./scripts/testing/test-ecommerce.sh

# Verificar estado del cluster
./scripts/management/verify.sh

# Port-forward para acceso local
kubectl port-forward -n dev svc/api-gateway 8080:80
kubectl port-forward -n dev svc/frontend 3000:80
```

### 📊 **Acceso a Servicios**
| Servicio | URL Local | URL Producción |
|----------|-----------|----------------|
| **Frontend** | http://localhost:3000 | https://ecommerce.yourdomian.com |
| **API Gateway** | http://localhost:8080 | https://api.yourdomain.com |
| **Grafana** | http://localhost:3001 | https://grafana.yourdomain.com |
| **Prometheus** | http://localhost:9090 | - |
| **Zipkin** | http://localhost:9411 | - |
| **Eureka** | http://localhost:8761 | - |

### 📚 **Documentación Detallada**
- **📖 [Documentación Técnica Completa](docs/DOCUMENTACION-PROYECTO-FINAL.md)**
- **🚀 [Guía de Despliegue Paso a Paso](docs/GUIA-DESPLIEGUE-COMPLETO.md)**
- **🧪 [Guía de Testing](docs/guides/TESTING-GUIDE.md)**
- **🔧 [Manual de Operaciones](docs/operations/MANUAL-OPERACIONES.md)**
- **📊 [Setup de Monitoreo](docs/guides/ZIPKIN-SETUP.md)**

## 🏛️ **Arquitectura Técnica**

### 🎯 **Stack Tecnológico**
| Categoría | Tecnologías |
|-----------|-------------|
| **Backend** | Java 11, Spring Boot 2.7, Spring Cloud |
| **Frontend** | HTML5, CSS3, JavaScript, Bootstrap |
| **Base de Datos** | PostgreSQL, Redis |
| **Contenedores** | Docker, Kubernetes (GKE) |
| **Service Mesh** | Eureka Server, Spring Cloud Gateway |
| **Observabilidad** | Prometheus, Grafana, Loki, Zipkin |
| **CI/CD** | GitHub Actions, Google Cloud Build |
| **Seguridad** | Pod Security Standards, Network Policies, Sealed Secrets |
| **Autoscaling** | KEDA, Horizontal Pod Autoscaler |

### 📊 **Métricas del Proyecto**
- 🏗️ **11 Microservicios** independientes y escalables
- 🔄 **60+ Pipelines CI/CD** automatizados  
- 📊 **Stack completo de observabilidad** (Prometheus + Grafana + Zipkin + Loki)
- ⚡ **Autoscaling inteligente** con KEDA y métricas customizadas
- 🔒 **Seguridad avanzada** con Network Policies y Pod Security Standards
- ☁️ **Cloud-native** desplegado en Google Kubernetes Engine (GKE)
- 📱 **Frontend responsivo** con interfaz moderna
- 💾 **Persistencia completa** con PostgreSQL y Redis
- 🔍 **Service Discovery** con Eureka Server
- 📈 **Métricas en tiempo real** y alertas automáticas

### 🌐 **Flujo de Datos**
```
[Usuario] → [Frontend] → [API Gateway] → [Microservicios] → [Bases de Datos]
                ↓              ↓              ↓                    ↓
          [Ingress]    [Load Balancer]  [Service Mesh]     [Persistent Volumes]
                ↓              ↓              ↓                    ↓
         [Prometheus] ← [Grafana] ← [Zipkin Tracing] ← [Application Logs]
```

## 🎯 **Cumplimiento de Requerimientos del Proyecto**

| Categoría | Peso | Estado | Implementación | Ubicación |
|-----------|------|---------|---------------|-----------|
| **Arquitectura e Infraestructura** | 15% | ✅ 100% | 11 microservicios + frontend + GKE | `microservices/`, `k8s/deployments/` |
| **Red y Seguridad** | 15% | ✅ 100% | Network Policies + Pod Security + mTLS | `k8s/network-policies/`, `k8s/security/` |
| **Configuración y Secretos** | 10% | ✅ 100% | ConfigMaps + Sealed Secrets + Env vars | `k8s/configmaps/`, `k8s/secrets/` |
| **CI/CD y Despliegue** | 15% | ✅ 100% | 60+ pipelines + Helm + GitOps | `.github/workflows/`, `helm/`, `ci-cd/` |
| **Almacenamiento** | 10% | ✅ 100% | PostgreSQL + Redis + Persistent Volumes | `k8s/deployments/*-db.yaml` |
| **Observabilidad** | 15% | ✅ 100% | Prometheus + Grafana + Zipkin + Loki | `k8s/monitoring/` |
| **Autoscaling** | 10% | ✅ 100% | KEDA + HPA + Métricas customizadas | `k8s/autoscaling/`, `k8s/hpa/` |
| **Documentación** | 10% | ✅ 100% | Docs completa + Guías + Diagramas | `docs/`, `assets/diagrams/` |

### 🏆 **Funcionalidades Adicionales Implementadas**
- 🔄 **Blue-Green Deployments** para cero downtime
- 🐦 **Canary Deployments** para releases seguros  
- 📊 **Dashboards personalizados** en Grafana
- 🔍 **Distributed Tracing** completo con Zipkin
- ⚡ **Emergency Rollback** automatizado
- 🛡️ **Security Compliance** con validaciones automáticas
- 💾 **Backup automatizado** de bases de datos
- 📈 **Métricas de negocio** y técnicas en tiempo real

### 🎮 **Demo y Testing**
- ✅ **Demo funcional completo** con datos de prueba
- ✅ **Testing end-to-end** automatizado
- ✅ **Load testing** con métricas de performance  
- ✅ **Security testing** con validaciones automáticas
- ✅ **Chaos engineering** para validar resilencia

### 📞 **Contacto y Soporte**
- **👨‍💻 Desarrollador:** Felipe Velasco
- **🏫 Universidad:** Icesi - Cali, Colombia  
- **📚 Curso:** Plataformas Computacionales 2
- **📧 Email:** [felipe.velasco@u.icesi.edu.co](mailto:felipe.velasco@u.icesi.edu.co)
- **🔗 GitHub:** [Felipevelasco7/ecommerce-microservice-backend-app](https://github.com/felipevelasco7/ecommerce-microservice-backend-app)
- **📅 Fecha:** Noviembre 2024



**🚀 ¡Listo para producción!** | **📊 Observabilidad completa** | **🔒 Seguridad empresarial** | **⚡ Escalabilidad automática**
