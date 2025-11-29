# 🛑 Guía Completa: Pausar y Reanudar Cluster GKE

## 📋 Información de tu Cluster

- **Nombre:** `ecommerce-cluster`
- **Zona:** `us-central1-a`
- **Nodos Actuales:** 8 nodos e2-medium
- **Proyecto GCP:** `axiomatic-fiber-479102-k7`
- **Cuenta:** `ponchoneta.futbol@gmail.com`

---

## 🛑 PASO 1: PAUSAR EL CLUSTER (Escalar a 0 Nodos)

### ⚠️ Antes de Pausar - Verificación

```bash
# 1. Verificar que todo esté funcionando
kubectl get pods -n dev
kubectl get pods -n monitoring

# 2. Verificar servicios críticos
kubectl get pvc -n dev  # Asegurar que los volumes estén Bound
kubectl get cronjobs -n dev  # Ver backups programados

# 3. Opcional: Hacer backup manual antes de pausar
kubectl exec -n dev postgres-0 -- pg_dump -U postgres ecommercedb > backup-pre-pausa.sql

# 4. Ver configuración actual del cluster
gcloud container clusters describe ecommerce-cluster --zone=us-central1-a
```

### 🔴 Comando para Pausar (Escalar a 0 Nodos)

```bash
gcloud container clusters resize ecommerce-cluster \
  --num-nodes=0 \
  --zone=us-central1-a
```

**Salida esperada:**
```
Pool [default-pool] for [ecommerce-cluster] will be resized to 0 node(s) in each zone it spans.

Do you want to continue (Y/n)?  Y

Resizing ecommerce-cluster...done.
Updated [https://container.googleapis.com/v1/projects/axiomatic-fiber-479102-k7/zones/us-central1-a/clusters/ecommerce-cluster].
```

### ✅ Verificar que se Pausó Correctamente

```bash
# Ver nodos (debe estar vacío o mostrar "No resources found")
kubectl get nodes

# Ver estado del cluster
gcloud container clusters describe ecommerce-cluster --zone=us-central1-a | grep currentNodeCount
# Debe mostrar: currentNodeCount: 0

# Ver que los pods ya no están corriendo
kubectl get pods -n dev
kubectl get pods -n monitoring
# Mostrará: No resources found o pods en estado Pending
```

### 💰 Ahorro de Costos

**Antes (8 nodos e2-medium):**
- 8 nodos × $0.0335/hora × 24h = ~$6.43/día
- ~$193/mes

**Después (0 nodos, solo control plane):**
- Control plane: $0.10/hora × 24h = ~$2.40/día  
- ~$72/mes
- **Ahorro: ~$121/mes (63%)**

---

## ▶️ PASO 2: REANUDAR EL CLUSTER (Escalar a 8 Nodos)

### 🟢 Comando para Reanudar

```bash
gcloud container clusters resize ecommerce-cluster \
  --num-nodes=8 \
  --zone=us-central1-a
```

**Salida esperada:**
```
Pool [default-pool] for [ecommerce-cluster] will be resized to 8 node(s) in each zone it spans.

Do you want to continue (Y/n)?  Y

Resizing ecommerce-cluster...⠹
```

**Tiempo estimado:** 3-5 minutos para crear los nodos

### ⏳ Esperar a que los Nodos Estén Ready

```bash
# Ver nodos en tiempo real
watch kubectl get nodes

# O verificar manualmente
kubectl get nodes
```

**Salida esperada (después de 3-5 min):**
```
NAME                                               STATUS   ROLES    AGE   VERSION
gke-ecommerce-cluster-default-pool-xxxxx-xxxx     Ready    <none>   2m    v1.33.5-gke.1201000
gke-ecommerce-cluster-default-pool-xxxxx-xxxx     Ready    <none>   2m    v1.33.5-gke.1201000
... (8 nodos total)
```

### 🚀 Iniciar los Pods Automáticamente

Kubernetes **automáticamente** recreará los pods cuando los nodos estén Ready:

```bash
# Ver pods iniciando
watch kubectl get pods -n dev

# Ver pods de monitoreo
watch kubectl get pods -n monitoring
```

**Proceso automático (5-10 minutos):**
1. ✅ Nodos Ready (3-5 min)
2. ✅ Pods programados en nodos (30 seg)
3. ✅ Init containers ejecutándose (1-2 min)
4. ✅ Postgres iniciando (1 min)
5. ✅ Cloud Config y Eureka (1-2 min)
6. ✅ Microservicios registrándose (2-3 min)
7. ✅ Frontend y Monitoring (1 min)

### 🔍 Verificar que Todo Está Funcionando

```bash
# 1. Verificar todos los pods están Running
kubectl get pods -n dev
kubectl get pods -n monitoring

# Salida esperada: Todos 1/1 Running o 2/2 Running
# api-gateway-xxxxx          1/1     Running
# product-service-xxxxx      1/1     Running
# order-service-xxxxx        1/1     Running
# ...etc

# 2. Verificar servicios
kubectl get services -n dev
kubectl get ingress -n dev

# 3. Verificar PVCs siguen Bound
kubectl get pvc -n dev

# 4. Verificar URLs funcionando
curl -s http://frontend.ecommerce.local | grep -o "<title>.*</title>"
curl -s http://ecommerce.local/actuator/health

# 5. Verificar Eureka
curl -s http://eureka.ecommerce.local/

# 6. Verificar logs de un servicio
kubectl logs -n dev -l app=api-gateway --tail=20
```

### 🌐 Verificar Ingress Controller

Si los Ingress no funcionan, puede ser porque el Load Balancer se recreó con nueva IP:

```bash
# Ver IP del Load Balancer
kubectl get svc -n ingress-nginx ingress-nginx-controller

# Salida:
# NAME                       TYPE           CLUSTER-IP      EXTERNAL-IP      PORT(S)
# ingress-nginx-controller   LoadBalancer   10.XX.XX.XX     34.XX.XX.XX      80:XXXXX/TCP,443:XXXXX/TCP
```

**Si la IP cambió**, actualiza `/etc/hosts`:

```bash
# Ver nueva IP externa
NEW_IP=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo $NEW_IP

# Actualizar /etc/hosts (reemplaza la IP vieja)
sudo nano /etc/hosts

# Debe contener:
# <NEW_IP> ecommerce.local
# <NEW_IP> frontend.ecommerce.local
# <NEW_IP> grafana.ecommerce.local
# <NEW_IP> prometheus.ecommerce.local
# <NEW_IP> eureka.ecommerce.local
# <NEW_IP> zipkin.ecommerce.local
```

### 🎯 Checklist Post-Reanudación

- [ ] 8 nodos en estado Ready
- [ ] Todos los pods en dev namespace Running (1/1)
- [ ] Todos los pods en monitoring namespace Running (1/1)
- [ ] PVC postgres-pvc sigue Bound
- [ ] Ingress tiene EXTERNAL-IP asignada
- [ ] Frontend accesible: http://frontend.ecommerce.local
- [ ] API Gateway accesible: http://ecommerce.local/actuator/health
- [ ] Grafana accesible: http://grafana.ecommerce.local
- [ ] Prometheus accesible: http://prometheus.ecommerce.local
- [ ] Eureka muestra microservicios registrados
- [ ] Datos persisten (productos, órdenes siguen en DB)

---

## 🔄 Script Automatizado para Reanudar con Verificación

Guarda este script como `verify-resume.sh`:

```bash
#!/bin/bash

echo "🚀 Reanudando cluster ecommerce-cluster..."
echo ""

# 1. Escalar a 8 nodos
echo "📈 Escalando a 8 nodos..."
gcloud container clusters resize ecommerce-cluster \
  --num-nodes=8 \
  --zone=us-central1-a \
  --quiet

echo ""
echo "⏳ Esperando a que los nodos estén Ready (esto toma 3-5 minutos)..."
sleep 180  # 3 minutos

# 2. Esperar nodos
kubectl wait --for=condition=Ready nodes --all --timeout=300s

echo ""
echo "✅ Nodos listos. Esperando a que los pods inicien..."
sleep 60

# 3. Esperar pods críticos
echo "⏳ Esperando PostgreSQL..."
kubectl wait --for=condition=ready pod -l app=postgres -n dev --timeout=120s

echo "⏳ Esperando Eureka..."
kubectl wait --for=condition=ready pod -l app=service-discovery -n dev --timeout=120s

echo "⏳ Esperando API Gateway..."
kubectl wait --for=condition=ready pod -l app=api-gateway -n dev --timeout=180s

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
INGRESS_IP=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "🌐 IP del Ingress Controller: $INGRESS_IP"
echo ""
echo "⚠️  Verifica que /etc/hosts tenga esta IP para:"
echo "   - ecommerce.local"
echo "   - frontend.ecommerce.local"
echo "   - grafana.ecommerce.local"
echo "   - prometheus.ecommerce.local"
echo "   - eureka.ecommerce.local"
echo "   - zipkin.ecommerce.local"
echo ""

# 5. Test health
echo "🏥 Probando health de API Gateway..."
sleep 10
curl -s http://ecommerce.local/actuator/health || echo "❌ API Gateway no responde (verifica /etc/hosts)"

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
```

**Uso:**
```bash
chmod +x verify-resume.sh
./verify-resume.sh
```

---

## ⚡ Comandos Rápidos de Referencia

### Pausar (0 nodos)
```bash
gcloud container clusters resize ecommerce-cluster --num-nodes=0 --zone=us-central1-a
```

### Reanudar (8 nodos)
```bash
gcloud container clusters resize ecommerce-cluster --num-nodes=8 --zone=us-central1-a
```

### Escalar a Menos Nodos (Ahorro Parcial)
```bash
# 4 nodos (ahorro ~50%)
gcloud container clusters resize ecommerce-cluster --num-nodes=4 --zone=us-central1-a

# 3 nodos (ahorro ~62%, mínimo recomendado)
gcloud container clusters resize ecommerce-cluster --num-nodes=3 --zone=us-central1-a
```

### Ver Estado
```bash
# Ver nodos
kubectl get nodes

# Ver todos los recursos
kubectl get all -n dev
kubectl get all -n monitoring

# Ver si hay problemas
kubectl get events -n dev --sort-by='.lastTimestamp' | tail -20
```

---

## 🐛 Troubleshooting Común

### Problema 1: Pods en Pending después de reanudar

**Causa:** Nodos aún no están Ready

**Solución:**
```bash
# Ver estado de nodos
kubectl get nodes

# Esperar más tiempo (3-5 min total)
kubectl wait --for=condition=Ready nodes --all --timeout=300s
```

### Problema 2: Pods en CrashLoopBackOff

**Causa:** Postgres no ha iniciado completamente

**Solución:**
```bash
# Verificar Postgres
kubectl get pods -n dev -l app=postgres

# Ver logs
kubectl logs -n dev postgres-0 --tail=50

# Esperar a que Postgres esté Ready
kubectl wait --for=condition=ready pod -l app=postgres -n dev --timeout=180s

# Reiniciar pods problemáticos
kubectl rollout restart deployment product-service order-service payment-service -n dev
```

### Problema 3: Ingress no responde (404 o connection refused)

**Causa:** IP del Load Balancer cambió

**Solución:**
```bash
# Ver nueva IP
kubectl get svc -n ingress-nginx ingress-nginx-controller

# Actualizar /etc/hosts con la nueva EXTERNAL-IP
sudo nano /etc/hosts
```

### Problema 4: Data perdida en Postgres

**Causa:** PVC no se restauró correctamente (muy raro)

**Solución:**
```bash
# Verificar PVC
kubectl get pvc -n dev

# Debe mostrar:
# postgres-pvc   Bound   pvc-xxxxx   10Gi   RWO   standard   XXd

# Si está Lost o Pending, revisar PV
kubectl get pv

# Restaurar desde backup
kubectl exec -n dev postgres-0 -- psql -U postgres ecommercedb < backup-pre-pausa.sql
```

### Problema 5: Muchos pods en ImagePullBackOff

**Causa:** Docker Hub rate limit o imágenes no disponibles

**Solución:**
```bash
# Ver cuál imagen falla
kubectl describe pod <pod-name> -n dev

# Reconstruir y pushear imágenes si es necesario
cd /path/to/service
docker build -t <your-registry>/service:latest .
docker push <your-registry>/service:latest

# Actualizar deployment con nueva imagen
kubectl set image deployment/<service> <service>=<new-image> -n dev
```

---

## 📊 Monitoreo de Costos

### Ver Costos en GCP Console

1. **Console → Billing → Reports**
2. Filtrar por:
   - Service: Compute Engine
   - SKU: N1 Standard (o E2)
   - Time range: Last 30 days

### Estimación de Ahorro

| Configuración | Costo/Día | Costo/Mes | Ahorro |
|--------------|-----------|-----------|--------|
| 8 nodos e2-medium | $6.43 | $193 | - |
| 4 nodos e2-medium | $3.62 | $109 | 43% |
| 3 nodos e2-medium | $2.82 | $85 | 56% |
| 0 nodos (pausado) | $2.40 | $72 | 63% |

**Control Plane siempre activo:** $72/mes (no se puede eliminar sin borrar el cluster)

---

## 🎓 Buenas Prácticas

### ✅ ANTES de Pausar:
1. Hacer backup manual de Postgres
2. Verificar que los PVC están Bound
3. Documentar la IP del Ingress actual
4. Tomar capturas de pantalla del proyecto funcionando
5. Exportar configuraciones críticas

### ✅ DESPUÉS de Reanudar:
1. Verificar todos los pods están Running
2. Verificar Ingress IP en /etc/hosts
3. Probar URLs principales
4. Verificar data persiste (productos, órdenes)
5. Revisar logs por errores

### ⚠️ NO Recomendado:
- Pausar durante demos o presentaciones
- Pausar sin verificar backups
- Pausar con cronjobs en ejecución
- Escalar a menos de 3 nodos en producción

---

## 📅 Estrategias de Ahorro

### Opción 1: Pausar Nocturno (Automatizado)
```bash
# Pausar a las 11 PM
0 23 * * * gcloud container clusters resize ecommerce-cluster --num-nodes=0 --zone=us-central1-a --quiet

# Reanudar a las 7 AM
0 7 * * * gcloud container clusters resize ecommerce-cluster --num-nodes=8 --zone=us-central1-a --quiet
```
**Ahorro:** ~40% del costo mensual

### Opción 2: Pausar Fines de Semana
```bash
# Viernes 6 PM → Pausar
0 18 * * 5 gcloud container clusters resize ecommerce-cluster --num-nodes=0 --zone=us-central1-a --quiet

# Lunes 8 AM → Reanudar
0 8 * * 1 gcloud container clusters resize ecommerce-cluster --num-nodes=8 --zone=us-central1-a --quiet
```
**Ahorro:** ~28% del costo mensual

### Opción 3: Reducir Nodos (Mantener Activo)
```bash
# Reducir a 3 nodos permanentemente
gcloud container clusters resize ecommerce-cluster --num-nodes=3 --zone=us-central1-a
```
**Ahorro:** ~56% del costo mensual  
**Ventaja:** Siempre disponible, solo pods críticos con 1 réplica

---

## 📞 Soporte y Referencias

- **Documentación GKE:** https://cloud.google.com/kubernetes-engine/docs/how-to/resizing-a-cluster
- **Costos GKE:** https://cloud.google.com/kubernetes-engine/pricing
- **Calculadora GCP:** https://cloud.google.com/products/calculator

**Proyecto:** axiomatic-fiber-479102-k7  
**Cluster:** ecommerce-cluster  
**Zona:** us-central1-a  
**Nodos:** 8 × e2-medium
