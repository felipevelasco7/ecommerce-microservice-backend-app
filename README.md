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
│       ├── verify.sh    