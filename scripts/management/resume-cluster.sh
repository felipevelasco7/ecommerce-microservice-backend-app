#!/bin/bash

# Script para reanudar el cluster
# Autor: Proyecto Final Plataformas 2
# Fecha: 2025-11-25

echo "▶️ Reanudando cluster de Kubernetes..."

# Restaurar réplicas en orden de dependencias

# 1. Infraestructura base
echo "1️⃣ Iniciando infraestructura base..."
kubectl scale deployment postgres --replicas=1 -n dev
kubectl scale deployment cloud-config --replicas=1 -n dev
kubectl scale deployment service-discovery --replicas=1 -n dev

echo "⏳ Esperando 30s para que la infraestructura se inicie..."
sleep 30

# 2. Microservicios
echo "2️⃣ Iniciando microservicios..."
kubectl scale deployment api-gateway --replicas=2 -n dev
kubectl scale deployment product-service --replicas=2 -n dev
kubectl scale deployment order-service --replicas=2 -n dev
kubectl scale deployment payment-service --replicas=2 -n dev
kubectl scale deployment shipping-service --replicas=2 -n dev
kubectl scale deployment favourite-service --replicas=2 -n dev
kubectl scale deployment user-service --replicas=2 -n dev
kubectl scale deployment proxy-client --replicas=2 -n dev

# 3. Frontend
echo "3️⃣ Iniciando frontend..."
kubectl scale deployment frontend --replicas=2 -n dev

# 4. Monitoring
echo "4️⃣ Iniciando monitoreo..."
kubectl scale deployment prometheus --replicas=1 -n monitoring
kubectl scale deployment grafana --replicas=1 -n monitoring
kubectl scale deployment alertmanager --replicas=1 -n monitoring

echo "⏳ Esperando a que todos los pods estén Ready..."
kubectl wait --for=condition=ready pod -l app=postgres -n dev --timeout=120s
kubectl wait --for=condition=ready pod -l app=service-discovery -n dev --timeout=120s
kubectl wait --for=condition=ready pod -l app=api-gateway -n dev --timeout=120s

echo "✅ Cluster reanudado exitosamente!"
echo ""
echo "📊 Estado de los pods:"
kubectl get pods -n dev
echo ""
kubectl get pods -n monitoring

echo ""
echo "🌐 URLs de acceso:"
echo "  Frontend: http://frontend.ecommerce.local"
echo "  API Gateway: http://ecommerce.local"
echo "  Grafana: http://grafana.ecommerce.local (admin/admin123)"
echo "  Prometheus: http://prometheus.ecommerce.local"
echo "  Eureka: http://eureka.ecommerce.local"
echo "  Zipkin: http://zipkin.ecommerce.local"
