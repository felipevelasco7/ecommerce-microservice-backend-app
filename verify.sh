#!/bin/bash

echo "=== VERIFICACIÓN DE USER-SERVICE ==="
echo ""

echo "1. ¿Tiene PostgreSQL en pom.xml?"
grep -A 3 "postgresql" user-service/pom.xml || echo "❌ NO ENCONTRADO - NECESITA AGREGARSE"
echo ""

echo "2. Estado del pod:"
kubectl get pods -n dev -l app=user-service
echo ""

echo "3. Logs recientes (últimas 30 líneas):"
POD_NAME=$(kubectl get pods -n dev -l app=user-service -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ ! -z "$POD_NAME" ]; then
    kubectl logs -n dev $POD_NAME -c user-service --tail=30 2>/dev/null || echo "Contenedor aún iniciando..."
else
    echo "No hay pods de user-service"
fi
echo ""

echo "4. Verificar registro en Eureka:"
echo "Ejecuta: kubectl port-forward -n dev svc/service-discovery 8761:8761"
echo "Visita: http://localhost:8761"
echo ""

echo "=== FIN DE VERIFICACIÓN ==="