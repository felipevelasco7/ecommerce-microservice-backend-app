#!/bin/bash

# Script para reiniciar todos los servicios UNO POR UNO
# Esto evita problemas de recursos en el clúster
# Autor: Sistema de Despliegue
# Fecha: 24 de noviembre de 2025

set -e

NAMESPACE="dev"

echo "╔══════════════════════════════════════════════════════════════════════════════╗"
echo "║         REINICIO SECUENCIAL DE SERVICIOS                                     ║"
echo "╚══════════════════════════════════════════════════════════════════════════════╝"
echo ""
echo "⚙️  Namespace: $NAMESPACE"
echo "⏱️  Estrategia: Uno por uno para evitar sobrecarga del clúster"
echo ""

# Lista de servicios a reiniciar en orden
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

echo "📦 Total de servicios a reiniciar: $TOTAL"
echo ""

# Función para reiniciar un servicio
restart_service() {
    local service=$1
    CURRENT=$((CURRENT + 1))
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "[$CURRENT/$TOTAL] 🔄 Reiniciando: $service"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Verificar si el deployment existe
    if ! kubectl get deployment $service -n $NAMESPACE &> /dev/null; then
        echo "⚠️  El deployment $service no existe, saltando..."
        echo ""
        return
    fi
    
    # Reiniciar el deployment
    echo "⏳ Ejecutando rollout restart..."
    kubectl rollout restart deployment $service -n $NAMESPACE
    
    # Esperar a que esté completamente desplegado
    echo "⏳ Esperando a que el nuevo pod esté listo..."
    if kubectl rollout status deployment $service -n $NAMESPACE --timeout=180s; then
        echo "✅ $service reiniciado exitosamente"
        
        # Mostrar el estado del pod
        echo "📊 Estado del pod:"
        kubectl get pods -n $NAMESPACE -l app=$service --no-headers
        echo ""
        
        # Pequeña pausa entre servicios para estabilidad
        echo "⏸️  Pausa de 10 segundos antes del siguiente servicio..."
        sleep 10
    else
        echo "❌ Error reiniciando $service (timeout)"
        echo "⚠️  Continuando con los demás servicios..."
        echo ""
    fi
}

# Reiniciar todos los servicios
for service in "${SERVICES[@]}"; do
    restart_service "$service"
done

echo "╔══════════════════════════════════════════════════════════════════════════════╗"
echo "║                    ✅ REINICIO COMPLETADO                                    ║"
echo "╚══════════════════════════════════════════════════════════════════════════════╝"
echo ""

# Mostrar estado final de todos los pods
echo "📊 Estado final de todos los pods:"
echo ""
kubectl get pods -n $NAMESPACE
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 VERIFICACIONES RECOMENDADAS:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1️⃣  Verificar que Prometheus está recolectando métricas:"
echo "    kubectl port-forward -n monitoring svc/prometheus 9090:9090"
echo "    # Ir a: http://localhost:9090/targets"
echo "    # Deberías ver los 8 servicios en estado UP"
echo ""
echo "2️⃣  Verificar endpoints /actuator/prometheus en los servicios:"
echo "    API_GATEWAY_IP=\$(kubectl get svc api-gateway -n dev -o jsonpath='{.status.loadBalancer.ingress[0].ip}')"
echo "    curl http://\$API_GATEWAY_IP/user-service/actuator/prometheus"
echo ""
echo "3️⃣  Generar tráfico para crear métricas:"
echo "    ./test.sh"
echo ""
echo "4️⃣  Ver métricas en Grafana:"
echo "    http://34.60.135.215:3000"
echo "    Usuario: admin"
echo "    Contraseña: admin123"
echo ""
echo "5️⃣  Verificar trazas en Zipkin:"
echo "    kubectl port-forward -n dev svc/zipkin 9411:9411"
echo "    # Ir a: http://localhost:9411"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
