#!/bin/bash

set -e

echo "🏗️  CONSTRUYENDO TODOS LOS SERVICIOS"
echo "===================================="
echo ""

# Lista de servicios a construir
SERVICES=(
    "product-service"
    "order-service"
    "payment-service"
    "shipping-service"
    "favourite-service"
)

# Contador de éxitos
SUCCESS_COUNT=0
TOTAL=${#SERVICES[@]}

for SERVICE in "${SERVICES[@]}"; do
    echo ""
    echo "🔨 Construyendo $SERVICE..."
    echo "--------------------------------"
    
    if gcloud builds submit --config=cloudbuild-${SERVICE}.yaml .; then
        echo "✅ $SERVICE construido exitosamente"
        ((SUCCESS_COUNT++))
    else
        echo "❌ Error construyendo $SERVICE"
    fi
done

echo ""
echo "========================================"
echo "📊 Resultados: $SUCCESS_COUNT/$TOTAL servicios construidos"
echo "========================================"
