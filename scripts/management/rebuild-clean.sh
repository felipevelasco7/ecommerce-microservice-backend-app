#!/bin/bash

# Script para reconstruir TODAS las imágenes con CLEAN BUILD
# Esto asegura que Maven descargue todas las dependencias nuevas

set -e

PROJECT_ID="axiomatic-fiber-479102-k7"
REGION="us-central1"

echo "╔══════════════════════════════════════════════════════════════════════════════╗"
echo "║         CLEAN BUILD DE TODAS LAS IMÁGENES                                    ║"
echo "╚══════════════════════════════════════════════════════════════════════════════╝"
echo ""
echo "⚠️  IMPORTANTE: Esto hará un clean build completo"
echo "   - Borrará todos los .jar compilados"
echo "   - Maven descargará todas las dependencias desde cero"
echo "   - Tomará más tiempo pero garantiza que Micrometer se incluya"
echo ""

# Lista de servicios
SERVICES=(
    "microservices/user-service"
    "microservices/product-service"
    "microservices/order-service"
    "microservices/payment-service"
    "microservices/shipping-service"
    "microservices/favourite-service"
    "microservices/proxy-client"
    "microservices/api-gateway"
)

# Limpiar targets locales primero
echo "🧹 Limpiando directorios target locales..."
for service in "${SERVICES[@]}"; do
    if [ -d "$service/target" ]; then
        rm -rf "$service/target"
        echo "   ✓ $service/target eliminado"
    fi
done
echo ""

TOTAL=${#SERVICES[@]}
CURRENT=0

# Función para construir un servicio
build_service() {
    local service=$1
    CURRENT=$((CURRENT + 1))
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "[$CURRENT/$TOTAL] 🔨 Clean Build: $service"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Crear un Dockerfile temporal con clean build
    cat > "${service}/Dockerfile.clean" <<'EOF'
FROM maven:3.8.4-openjdk-11-slim AS build
WORKDIR /app
COPY pom.xml .
COPY src ./src
RUN mvn clean package -DskipTests -U

FROM openjdk:11-jre-slim
WORKDIR /app
COPY --from=build /app/target/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
EOF
    
    echo "⏳ Iniciando Cloud Build con clean..."
    
    # Crear cloudbuild temporal
    cat > "cloudbuild-${service}-clean.yaml" <<EOF
steps:
  - name: 'gcr.io/cloud-builders/docker'
    args:
      - 'build'
      - '-t'
      - 'gcr.io/$PROJECT_ID/${service}:0.1.0'
      - '-t'
      - 'gcr.io/$PROJECT_ID/${service}:latest'
      - '-f'
      - '${service}/Dockerfile.clean'
      - '${service}'
      - '--no-cache'
images:
  - 'gcr.io/$PROJECT_ID/${service}:0.1.0'
  - 'gcr.io/$PROJECT_ID/${service}:latest'
timeout: '1200s'
EOF
    
    if gcloud builds submit \
        --config=cloudbuild-${service}-clean.yaml \
        --timeout=20m \
        --project=$PROJECT_ID \
        --region=$REGION \
        --suppress-logs .; then
        echo "✅ $service - Clean build exitoso"
        rm -f "cloudbuild-${service}-clean.yaml" "${service}/Dockerfile.clean"
        echo ""
    else
        echo "❌ Error en clean build de $service"
        echo "⚠️  Continuando con los demás servicios..."
        echo ""
    fi
}

# Construir todos los servicios
for service in "${SERVICES[@]}"; do
    build_service "$service"
done

echo "╔══════════════════════════════════════════════════════════════════════════════╗"
echo "║                    ✅ CLEAN BUILD COMPLETADO                                 ║"
echo "╚══════════════════════════════════════════════════════════════════════════════╝"
echo ""
echo "📦 Total de servicios: $TOTAL"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 SIGUIENTE PASO:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Reiniciar los deployments para usar las nuevas imágenes:"
echo "   kubectl rollout restart deployment -n dev user-service"
echo "   kubectl rollout restart deployment -n dev product-service"
echo "   # ... etc para cada servicio"
echo ""
echo "O usa el script de reinicio secuencial"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━�