#!/bin/bash

# Script para agregar ServiceAccounts a todos los Deployments
# Este script actualiza los deployments para usar sus ServiceAccounts correspondientes

echo "🔐 Actualizando Deployments con ServiceAccounts..."

# Array de servicios y sus respectivos ServiceAccounts
declare -A services=(
    ["api-gateway"]="api-gateway-sa"
    ["user-service"]="user-service-sa"
    ["product-service"]="product-service-sa"
    ["order-service"]="order-service-sa"
    ["payment-service"]="payment-service-sa"
    ["shipping-service"]="shipping-service-sa"
    ["favourite-service"]="favourite-service-sa"
    ["proxy-client"]="proxy-client-sa"
    ["service-discovery"]="service-discovery-sa"
    ["cloud-config"]="cloud-config-sa"
    ["zipkin"]="zipkin-sa"
    ["postgres"]="postgres-sa"
)

# Función para actualizar un deployment
update_deployment() {
    local service=$1
    local sa=$2
    
    echo "  ➤ Actualizando $service con ServiceAccount $sa..."
    
    kubectl patch deployment $service -n dev --patch "
spec:
  template:
    spec:
      serviceAccountName: $sa
      automountServiceAccountToken: true
"
    
    if [ $? -eq 0 ]; then
        echo "    ✅ $service actualizado correctamente"
    else
        echo "    ❌ Error actualizando $service"
    fi
}

# Actualizar todos los deployments
for service in "${!services[@]}"; do
    update_deployment "$service" "${services[$service]}"
done

echo ""
echo "✅ Todos los Deployments han sido actualizados con ServiceAccounts"
echo ""
echo "📋 Verificando ServiceAccounts..."
kubectl get sa -n dev

echo ""
echo "🔍 Verificando que los pods se hayan reiniciado con los nuevos ServiceAccounts..."
kubectl get pods -n dev -o custom-columns=NAME:.metadata.name,SERVICE_ACCOUNT:.spec.serviceAccountName

echo ""
echo "✅ Proceso completado!"
