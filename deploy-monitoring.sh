#!/bin/bash

# Script para desplegar Prometheus + Grafana
# Autor: Sistema de Monitoreo
# Fecha: 24 de noviembre de 2025

set -e

echo "╔══════════════════════════════════════════════════════════════════════════════╗"
echo "║         DESPLIEGUE DE PROMETHEUS + GRAFANA                                   ║"
echo "╚══════════════════════════════════════════════════════════════════════════════╝"
echo ""

# Paso 1: Crear namespace de monitoreo
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "1️⃣  Creando namespace 'monitoring'..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
kubectl apply -f k8s/monitoring/00-namespace.yaml
echo ""

# Paso 2: Desplegar Prometheus
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "2️⃣  Desplegando Prometheus..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
kubectl apply -f k8s/monitoring/01-prometheus-config.yaml
kubectl apply -f k8s/monitoring/02-prometheus-rbac.yaml
kubectl apply -f k8s/monitoring/03-prometheus-deployment.yaml
echo ""

# Esperar a que Prometheus esté listo
echo "⏳ Esperando a que Prometheus esté listo..."
kubectl wait --for=condition=available --timeout=120s deployment/prometheus -n monitoring
echo "✅ Prometheus desplegado exitosamente"
echo ""

# Paso 3: Desplegar Grafana
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "3️⃣  Desplegando Grafana..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
kubectl apply -f k8s/monitoring/04-grafana-deployment.yaml
echo ""

# Esperar a que Grafana esté listo
echo "⏳ Esperando a que Grafana esté listo..."
kubectl wait --for=condition=available --timeout=120s deployment/grafana -n monitoring
echo "✅ Grafana desplegado exitosamente"
echo ""

# Paso 4: Mostrar información
echo "╔══════════════════════════════════════════════════════════════════════════════╗"
echo "║                    ✅ DESPLIEGUE COMPLETADO                                  ║"
echo "╚══════════════════════════════════════════════════════════════════════════════╝"
echo ""

# Obtener IPs
echo "📊 Información de servicios:"
echo ""
kubectl get svc -n monitoring
echo ""

# Esperar a que Grafana obtenga IP externa
echo "⏳ Esperando IP externa de Grafana..."
for i in {1..30}; do
    GRAFANA_IP=$(kubectl get svc grafana -n monitoring -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
    if [ -n "$GRAFANA_IP" ]; then
        break
    fi
    sleep 5
done

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 ACCESO A LOS SERVICIOS:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🔍 PROMETHEUS:"
echo "   Port-forward: kubectl port-forward -n monitoring svc/prometheus 9090:9090"
echo "   URL: http://localhost:9090"
echo ""
echo "📊 GRAFANA:"
if [ -n "$GRAFANA_IP" ]; then
    echo "   URL Externa: http://$GRAFANA_IP:3000"
fi
echo "   Port-forward: kubectl port-forward -n monitoring svc/grafana 3000:3000"
echo "   URL Local: http://localhost:3000"
echo "   Usuario: admin"
echo "   Contraseña: admin123"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📝 PRÓXIMOS PASOS:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1️⃣  Reconstruir imágenes con Micrometer Prometheus:"
echo "    ./rebuild-with-zipkin.sh"
echo ""
echo "2️⃣  Redesplegar servicios:"
echo "    ./redeploy-with-zipkin.sh"
echo ""
echo "3️⃣  Acceder a Grafana y configurar dashboards"
echo ""
echo "4️⃣  Verificar métricas en Prometheus:"
echo "    kubectl port-forward -n monitoring svc/prometheus 9090:9090"
echo "    http://localhost:9090/targets"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
