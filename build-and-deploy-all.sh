#!/bin/bash

set -e

# Change to script directory
cd "$(dirname "$0")"

PROJECT_ID=$(gcloud config get-value project)

echo "🚀 DESPLIEGUE AUTOMATIZADO DE TODOS LOS MICROSERVICIOS"
echo "======================================================"
echo "Project ID: $PROJECT_ID"
echo ""

# Array de servicios: nombre:puerto:base_de_datos
SERVICES=(
    "order-service:8300:order_db"
    "payment-service:8400:payment_db"
    "shipping-service:8600:shipping_db"
    "favourite-service:8800:favourite_db"
)

# Función para construir un servicio
build_service() {
    local SERVICE_NAME=$1
    echo ""
    echo "🏗️  Construyendo $SERVICE_NAME..."
    echo "=================================="
    
    gcloud builds submit --config=cloudbuild-${SERVICE_NAME}.yaml .
    
    if [ $? -eq 0 ]; then
        echo "✅ Build de $SERVICE_NAME exitoso"
        return 0
    else
        echo "❌ Build de $SERVICE_NAME falló"
        return 1
    fi
}

# Función para desplegar un servicio
deploy_service() {
    local SERVICE_NAME=$1
    local PORT=$2
    local DB_NAME=$3
    
    echo ""
    echo "📦 Desplegando $SERVICE_NAME..."
    echo "==============================="
    
    # Aplicar ConfigMap y Secret
    kubectl apply -f k8s/configmaps/${SERVICE_NAME}-config.yaml
    kubectl apply -f k8s/secrets/${SERVICE_NAME}-secret.yaml || true
    
    # Actualizar PROJECT_ID en deployment y aplicar
    sed "s/PROJECT_ID/$PROJECT_ID/g" k8s/deployments/${SERVICE_NAME}.yaml | kubectl apply -f -
    
    echo "✅ $SERVICE_NAME desplegado"
    sleep 3
}

# Construir y desplegar cada servicio
for service_info in "${SERVICES[@]}"; do
    IFS=':' read -r service port db <<< "$service_info"
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  Procesando: $service"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Construir
    if build_service "$service"; then
        # Desplegar
        deploy_service "$service" "$port" "$db"
    else
        echo "⚠️  Saltando despliegue de $service debido a error en build"
    fi
done

echo ""
echo "🎉 ¡Proceso completado!"
echo ""
echo "📊 Estado de todos los pods:"
kubectl get pods -n dev
echo ""
echo "🔍 Servicios en Eureka:"
echo "kubectl port-forward -n dev svc/service-discovery 8761:8761"
echo "Luego visita: http://localhost:8761"
