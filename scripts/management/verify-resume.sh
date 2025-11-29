#!/bin/bash

# Script automatizado para reanudar el cluster y verificar estado
# Autor: Proyecto Final Plataformas 2
# Fecha: 2025-11-25

set -e  # Exit on error

CLUSTER_NAME="ecommerce-cluster"
ZONE="us-central1-a"
NUM_NODES=8

echo "🚀 Reanudando cluster $CLUSTER_NAME..."
echo ""

# 1. Escalar a 8 nodos
echo "📈 Escalando a $NUM_NODES nodos..."
gcloud container clusters resize $CLUSTER_NAME \
  --num-nodes=$NUM_NODES \
  --zone=$ZONE \
  --quiet

echo ""
echo "⏳ Esperando a que los nodos estén Ready (esto toma 3-5 minutos)..."
sleep 180  # 3 minutos

# 2. Esperar nodos
echo "🔍 Verificando nodos..."
kubectl wait --for=condition=Ready nodes --all --timeout=300s || echo "⚠️  Algunos nodos aún no están Ready"

echo ""
echo "✅ Nodos listos. Esperando a que los pods inicien..."
sleep 60

# 3. Esperar pods críticos
echo "⏳ Esperando PostgreSQL..."
kubectl wait --for=condition=ready pod -l app=postgres -n dev --timeout=120s || echo "⚠️  Postgres no está Ready aún"

echo "⏳ Esperando Eureka..."
kubectl wait --for=condition=ready pod -l app=service-discovery -n dev --timeout=120s || echo "⚠️  Eureka no está Ready aún"

echo "⏳ Esperando API Gateway..."
kubectl wait --for=condition=ready pod -l app=api-gateway -n dev --timeout=180s || echo "⚠️  API Gateway no está Ready aún"

echo ""
echo "📊 Estado del cluster:"
echo ""
echo "=== NODOS ==="
kubectl get nodes
echo ""
echo "=== PODS DEV ==="
kubectl get pods -n dev
echo ""
echo "=== PODS MONITORING ==="
kubectl get pods -n monitoring
echo ""
echo "=== INGRESS ==="
kubectl get ingress -n dev
echo ""
echo "=== PVC ==="
kubectl get pvc -n dev
echo ""

# 4. Verificar Ingress IP
INGRESS_IP=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
if [ -n "$INGRESS_IP" ]; then
  echo "🌐 IP del Ingress Controller: $INGRESS_IP"
  echo ""
  echo "⚠️  Verifica que /etc/hosts tenga esta IP para:"
  echo "   $INGRESS_IP ecommerce.local"
  echo "   $INGRESS_IP frontend.ecommerce.local"
  echo "   $INGRESS_IP grafana.ecommerce.local"
  echo "   $INGRESS_IP prometheus.ecommerce.local"
  echo "   $INGRESS_IP eureka.ecommerce.local"
  echo "   $INGRESS_IP zipkin.ecommerce.local"
else
  echo "⚠️  Ingress Controller aún no tiene IP externa asignada"
fi
echo ""

# 5. Test health
echo "🏥 Probando health de API Gateway..."
sleep 10
if curl -s --connect-timeout 5 http://ecommerce.local/actuator/health > /dev/null 2>&1; then
  echo "✅ API Gateway respondiendo correctamente"
else
  echo "⚠️  API Gateway no responde aún (verifica /etc/hosts o espera más tiempo)"
fi

echo ""
echo "✅ Cluster reanudado!"
echo ""
echo "🌐 URLs de acceso:"
echo "   Frontend:   http://frontend.ecommerce.local"
echo "   API:        http://ecommerce.local"
echo "   Grafana:    http://grafana.ecommerce.local (admin/admin123)"
echo "   Prometheus: http://prometheus.ecommerce.local"
echo "   Eureka:     http://eureka.ecommerce.local"
echo "   Zipkin:     http://zipkin.ecommerce.local"
echo ""
echo "💡 Si algo no funciona, espera 2-3 minutos más y vuelve a verificar"
echo "💡 Revisa la guía completa en: PAUSA-REANUDACION-CLUSTER.md"
