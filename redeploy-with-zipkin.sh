#!/bin/bash

# Script para redesplegar servicios con soporte Zipkin
# Redespliega UNO POR UNO para evitar problemas de recursos
# Autor: Sistema de Despliegue Automatizado
# Fecha: 24 de noviembre de 2025

set -e

NAMESPACE="dev"

echo "╔══════════════════════════════════════════════════════════════════════════════╗"
echo "║         REDESPLIEGUE DE SERVICIOS CON ZIPKIN (UNO POR UNO)                   ║"
echo "╚══════════════════════════════════════════════════════════════════════════════╝"
echo ""

# Lista de servicios a redesplegar
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

echo "📦 Servicios a redesplegar: $TOTAL"
echo "⏱️  Tiempo estimado: ~15-20 minutos"
echo ""

# Paso 1: Aplicar ConfigMaps
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "1️⃣  Aplicando ConfigMaps actualizados..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if kubectl apply -f k8s/configmaps/; then
    echo "✅ ConfigMaps aplicados exitosamente"
    echo ""
else
    echo "❌ Error aplicando ConfigMaps"
    exit 1
fi

# Función para redesplegar un servicio
redeploy_service() {
    local service=$1
    CURRENT=$((CURRENT + 1))
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "[$CURRENT/$TOTAL] 🔄 Redesplegando: $service"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    # Verificar que el deployment existe
    if ! kubectl get deployment $service -n $NAMESPACE &>/dev/null; then
        echo "⚠️  Deployment $service no encontrado, saltando..."
        echo ""
        return
    fi
    
    # Reiniciar deployment
    echo "⏳ Reiniciando deployment..."
    kubectl rollout restart deployment $service -n $NAMESPACE
    
    # Esperar a que esté listo
    echo "⏳ Esperando a que el deployment esté listo..."
    if kubectl rollout status deployment $service -n $NAMESPACE --timeout=5m; then
        echo "✅ $service redesplegado exitosamente"
        echo ""
        
        # Verificar estado del pod
        echo "📊 Estado del pod:"
        kubectl get pods -n $NAMESPACE -l app=$service
        echo ""
        
        # Pequeña pausa antes del siguiente servicio
        if [ $CURRENT -lt $TOTAL ]; then
            echo "⏸️  Esperando 10 segundos antes del siguiente servicio..."
            sleep 10
            echo ""
        fi
    else
        echo "⚠️  Timeout esperando a $service"
        echo "📋 Estado actual del pod:"
        kubectl get pods -n $NAMESPACE -l app=$service
        echo ""
        echo "📋 Últimos eventos:"
        kubectl describe pod -n $NAMESPACE -l app=$service | grep -A 10 "Events:"
        echo ""
        echo "❓ ¿Continuar con los demás servicios? (y/n)"
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            echo "❌ Despliegue cancelado"
            exit 1
        fi
        echo ""
    fi
}

# Paso 2: Redesplegar servicios uno por uno
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "2️⃣  Redesplegando servicios..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

for service in "${SERVICES[@]}"; do
    redeploy_service "$service"
done

# Resumen final
echo "╔══════════════════════════════════════════════════════════════════════════════╗"
echo "║                    DESPLIEGUE COMPLETADO                                     ║"
echo "╚══════════════════════════════════════════════════════════════════════════════╝"
echo ""
echo "✅ Todos los servicios han sido redesplegados"
echo ""

# Verificar estado final
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 ESTADO FINAL DE TODOS LOS PODS:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
kubectl get pods -n $NAMESPACE
echo ""

# Contar pods Running
RUNNING_PODS=$(kubectl get pods -n $NAMESPACE --field-selector=status.phase=Running --no-headers | wc -l | tr -d ' ')
echo "📊 Pods en estado Running: $RUNNING_PODS"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 VERIFICAR ZIPKIN:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1️⃣  Activar port-forward de Zipkin:"
echo "    kubectl port-forward -n dev svc/zipkin 9411:9411"
echo ""
echo "2️⃣  Generar tráfico:"
echo "    ./test.sh"
echo ""
echo "3️⃣  Ver trazas en Zipkin:"
echo "    Abrir: http://localhost:9411"
echo "    - Clic en 'RUN QUERY' o 'Find Traces'"
echo "    - Ver grafo en pestaña 'Dependencies'"
echo ""
echo "4️⃣  Verificar logs de un servicio (ejemplo user-service):"
echo "    kubectl logs -n dev -l app=user-service --tail=50 | grep -i zipkin"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
