#!/bin/bash

# Script para pausar el cluster y ahorrar costos
# Autor: Proyecto Final Plataformas 2
# Fecha: 2025-11-25

echo "🛑 Pausando cluster de Kubernetes..."

# Escalar todos los deployments a 0
echo "📉 Escalando deployments a 0 réplicas..."

# Namespace dev
kubectl scale deployment api-gateway --replicas=0 -n dev
kubectl scale deployment product-service --replicas=0 -n dev
kubectl scale deployment order-service --replicas=0 -n dev
kubectl scale deployment payment-service --replicas=0 -n dev
kubectl scale deployment shipping-service --replicas=0 -n dev
kubectl scale deployment favourite-service --replicas=0 -n dev
kubectl scale deployment user-service --replicas=0 -n dev
kubectl scale deployment frontend --replicas=0 -n dev
kubectl scale deployment service-discovery --replicas=0 -n dev
kubectl scale deployment cloud-config --replicas=0 -n dev
kubectl scale deployment postgres --replicas=0 -n dev
kubectl scale deployment proxy-client --replicas=0 -n dev

# Namespace monitoring
kubectl scale deployment prometheus --replicas=0 -n monitoring
kubectl scale deployment grafana --replicas=0 -n monitoring
kubectl scale deployment alertmanager --replicas=0 -n monitoring

# Parar port-forwards activos
echo "🔌 Cerrando port-forwards..."
pkill -f "kubectl port-forward"

echo "✅ Cluster pausado. Todos los pods están en 0 réplicas."
echo "💡 Para reiniciar: ./resume-cluster.sh"
echo "💰 Ahorro estimado: ~90% de costos de compute"
