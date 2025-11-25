#!/bin/bash

# Script para reconstruir todas las imágenes con soporte de Zipkin
# Autor: Sistema de Despliegue Automatizado
# Fecha: 24 de noviembre de 2025

set -e

PROJECT_ID="axiomatic-fiber-479102-k7"
REGION="us-central1"

echo "╔══════════════════════════════════════════════════════════════════════════════╗"
echo "║         RECONSTRUCCIÓN DE IMÁGENES CON SOPORTE ZIPKIN                        ║"
echo "╚══════════════════════════════════════════════════════════════════════════════╝"
echo ""
echo "⚙️  Configuración:"
echo "   - Proyecto GCP: $PROJECT_ID"
echo "   - Región: $REGION"
echo "   - Build con --no-cache para forzar descarga de nuevas dependencias"
echo ""

# Lista de servicios a reconstruir
SERVICES=(
    "user-service"
    "product-service"
    "order-service"
    "payment-service"
    "shipping-service"
    "favourite-service"
    "proxy-client"
    "api-gateway"
)

TOTAL=${#SERVICES[@]}
CURRENT=0

echo "📦 Servicios a reconstruir: $TOTAL"
echo ""

# Función para construir un servicio
build_service() {
    local service=$1
    CURRENT=$((CURRENT + 1))
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "[$CURRENT/$TOTAL] 🔨 Construyendo: $service"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    echo "⏳ Iniciando Cloud Build..."
    
    if gcloud builds submit \
        --config=cloudbuild-${service}.yaml \
        --timeout=20m \
        --project=$PROJECT_ID \
        --region=$REGION \
        --suppress-logs .; then
        echo "✅ $service construido exitosamente"
        echo ""
    else
        echo "❌ Error construyendo $service"
        echo "⚠️  Continuando con los demás servicios..."
        echo ""
    fi
}

# Reconstruir todos los servicios
for service in "${SERVICES[@]}"; do
    build_service "$service"
done

echo "╔══════════════════════════════════════════════════════════════════════════════╗"
echo "║                    RESUMEN DE CONSTRUCCIÓN                                   ║"
echo "╚══════════════════════════════════════════════════════════════════════════════╝"
echo ""
echo "✅ Proceso de construcción completado"
echo "📦 Total de servicios procesados: $TOTAL"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 SIGUIENTES PASOS:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1️⃣  Aplicar ConfigMaps actualizados:"
echo "    kubectl apply -f k8s/configmaps/"
echo ""
echo "2️⃣  Reiniciar deployments (UNO POR UNO para evitar problemas de recursos):"
echo "    kubectl rollout restart deployment user-service -n dev"
echo "    kubectl rollout status deployment user-service -n dev"
echo ""
echo "    kubectl rollout restart deployment product-service -n dev"
echo "    kubectl rollout status deployment product-service -n dev"
echo ""
echo "    # ... (repetir para cada servicio)"
echo ""
echo "3️⃣  Verificar que Zipkin recibe trazas:"
echo "    kubectl port-forward -n dev svc/zipkin 9411:9411"
echo "    # Abrir: http://localhost:9411"
echo ""
echo "4️⃣  Generar tráfico:"
echo "    ./test.sh"
echo ""
echo "5️⃣  Ver trazas en Zipkin:"
echo "    - Clic en 'RUN QUERY' o 'Find Traces'"
echo "    - Ver grafo en pestaña 'Dependencies'"
echo ""
echo "⚠️  IMPORTANTE: Los deployments deben reiniciarse UNO POR UNO"
echo "    para evitar problemas de recursos del clúster."
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
