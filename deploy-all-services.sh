#!/bin/bash

set -e

PROJECT_ID=$(gcloud config get-value project)

echo "🚀 DESPLEGANDO TODOS LOS MICROSERVICIOS"
echo "========================================"
echo "Project ID: $PROJECT_ID"
echo ""

# Función para desplegar un servicio
deploy_service() {
    local SERVICE_NAME=$1
    local PORT=$2
    local DB_NAME=$3
    
    echo ""
    echo "📦 Desplegando $SERVICE_NAME..."
    echo "================================"
    
    # Aplicar ConfigMap y Secret
    kubectl apply -f k8s/configmaps/${SERVICE_NAME}-config.yaml
    kubectl apply -f k8s/secrets/${SERVICE_NAME}-secret.yaml
    
    # Actualizar PROJECT_ID en deployment
    sed "s/PROJECT_ID/$PROJECT_ID/g" k8s/deployments/${SERVICE_NAME}.yaml | kubectl apply -f -
    
    echo "✅ $SERVICE_NAME desplegado"
    sleep 5
}

# Servicios a desplegar (product-service ya está en build)
echo "⏳ Esperando a que termine el build de product-service..."
echo ""

# Una vez que product-service esté listo, desplegar todos los servicios
services=(
    "product-service:8500:product_db"
    "order-service:8300:order_db"
    "payment-service:8400:payment_db"
    "shipping-service:8600:shipping_db"
    "favourite-service:8200:favourite_db"
)

for service_info in "${services[@]}"; do
    IFS=':' read -r service port db <<< "$service_info"
    deploy_service "$service" "$port" "$db"
done

echo ""
echo "🎉 Todos los servicios desplegados!"
echo ""
echo "📊 Estado de los pods:"
kubectl get pods -n dev
echo ""
echo "🌐 Port-forward a Eureka:"
echo "kubectl port-forward -n dev svc/service-discovery 8761:8761"
