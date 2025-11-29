# 📸 Guía de Capturas para Documentación del Proyecto

## 1. ARQUITECTURA Y ESTADO DEL CLUSTER

### Ver todos los pods en ejecución
```bash
kubectl get pods -n dev -o wide
kubectl get pods -n monitoring -o wide
```
**Captura**: Muestra todos los microservicios funcionando (2/2 Ready)

### Ver todos los deployments con réplicas
```bash
kubectl get deployments -n dev
kubectl get deployments -n monitoring
```
**Captura**: Demuestra escalabilidad (réplicas configuradas)

### Ver arquitectura completa
```bash
kubectl get all -n dev
kubectl get all -n monitoring
```
**Captura**: Vista general de recursos (pods, services, deployments, replicasets)

---

## 2. CONFIGURACIÓN Y SEGURIDAD (ConfigMaps, Secrets, RBAC)

### ConfigMaps configurados
```bash
kubectl get configmaps -n dev
kubectl describe configmap postgres-config -n dev
```
**Captura**: Gestión de configuración centralizada

### Secrets implementados
```bash
kubectl get secrets -n dev
kubectl get secrets -n monitoring
```
**Captura**: Gestión segura de credenciales

### ServiceAccounts y RBAC
```bash
kubectl get serviceaccounts -n dev
kubectl get serviceaccounts -n monitoring
kubectl get roles -n dev
kubectl get rolebindings -n dev
```
**Captura**: Seguridad con permisos mínimos necesarios

---

## 3. RED Y SEGURIDAD (Ingress, TLS, NetworkPolicies)

### Ingress Controllers y reglas
```bash
kubectl get ingress -n dev
kubectl describe ingress api-gateway-ingress -n dev
kubectl describe ingress frontend-ingress -n dev
```
**Captura**: Routing HTTP/HTTPS configurado

### Certificados TLS
```bash
kubectl get secrets -n dev | grep tls
kubectl describe secret ecommerce-tls -n dev
```
**Captura**: Seguridad HTTPS implementada

### NetworkPolicies
```bash
kubectl get networkpolicies -n dev
kubectl describe networkpolicy allow-api-gateway -n dev
```
**Captura**: Seguridad de red entre microservicios

### Services (ClusterIP, NodePort)
```bash
kubectl get services -n dev
kubectl get services -n monitoring
```
**Captura**: Servicios de red configurados

---

## 4. ALMACENAMIENTO Y PERSISTENCIA

### Persistent Volumes y Claims
```bash
kubectl get pv
kubectl get pvc -n dev
kubectl describe pvc postgres-pvc -n dev
```
**Captura**: Persistencia de datos implementada

### StorageClass
```bash
kubectl get storageclass
kubectl describe storageclass standard
```
**Captura**: Configuración de almacenamiento

### Backups (CronJobs)
```bash
kubectl get cronjobs -n dev
kubectl describe cronjob postgres-backup -n dev
kubectl get jobs -n dev | grep backup
```
**Captura**: Estrategia de backup automático

---

## 5. OBSERVABILIDAD Y MONITOREO

### Prometheus funcionando
```bash
kubectl get pods -n monitoring -l app=prometheus
kubectl logs -n monitoring -l app=prometheus --tail=20
```
**Captura**: Prometheus activo recolectando métricas

### Grafana funcionando
```bash
kubectl get pods -n monitoring -l app=grafana
kubectl get service grafana -n monitoring
```
**Captura**: Grafana listo para dashboards

### AlertManager configurado
```bash
kubectl get pods -n monitoring -l app=alertmanager
kubectl get configmap alertmanager-config -n monitoring -o yaml | grep -A 20 "route:"
```
**Captura**: Alertas configuradas

### PrometheusRules (alertas)
```bash
kubectl get prometheusrules -n monitoring
kubectl describe prometheusrule ecommerce-alerts -n monitoring
```
**Captura**: Reglas de alertas definidas

### Zipkin para tracing
```bash
kubectl get pods -n dev -l app=zipkin
kubectl get service zipkin -n dev
```
**Captura**: Tracing distribuido implementado

---

## 6. AUTOSCALING

### Horizontal Pod Autoscalers
```bash
kubectl get hpa -n dev
kubectl describe hpa product-service-hpa -n dev
kubectl describe hpa api-gateway-hpa -n dev
```
**Captura**: Autoscaling configurado por servicio

---

## 7. FRONTEND Y ACCESO

### Frontend deployment
```bash
kubectl get pods -n dev -l app=frontend
kubectl get service frontend -n dev
kubectl get configmap frontend-html -n dev
```
**Captura**: Frontend web implementado

### Acceso al frontend (captura de pantalla del navegador)
```bash
# Abrir en navegador: http://frontend.ecommerce.local
```
**Capturas del navegador**:
1. Tab Dashboard - Métricas generales
2. Tab Productos - Listado de productos
3. Tab Pedidos - Gestión de órdenes
4. Tab Pagos - Estado de pagos
5. Tab Envíos - Seguimiento de envíos
6. Tab Favoritos - Manejo de errores gracefully
7. Tab Usuarios - Explicación de autenticación
8. Tab Monitoreo - Links a herramientas

---

## 8. MONITOREO - INTERFACES WEB

### Grafana Dashboard
```bash
# Abrir: http://grafana.ecommerce.local
# Usuario: admin / Contraseña: admin123
```
**Capturas del navegador**:
1. Login de Grafana
2. Dashboard de E-commerce (métricas de negocio)
3. Dashboard de Kubernetes (métricas de infraestructura)
4. Panel de Prometheus datasource

### Prometheus UI
```bash
# Abrir: http://prometheus.ecommerce.local
```
**Capturas del navegador**:
1. Prometheus Targets (endpoints monitoreados)
2. Prometheus Alerts (reglas activas)
3. Query de ejemplo: `up{namespace="dev"}`
4. Graph de métrica: `container_memory_usage_bytes`

### Eureka Dashboard (Service Discovery)
```bash
# Abrir: http://eureka.ecommerce.local
```
**Captura**: Todos los microservicios registrados

### Zipkin UI (Distributed Tracing)
```bash
# Abrir: http://zipkin.ecommerce.local
```
**Captura**: Traces de requests entre microservicios

---

## 9. LOGS Y TROUBLESHOOTING

### Logs de microservicios (ejemplo)
```bash
kubectl logs -n dev -l app=product-service --tail=50
kubectl logs -n dev -l app=api-gateway --tail=50
kubectl logs -n dev -l app=order-service --tail=50
```
**Captura**: Logs funcionando correctamente

### Events del cluster
```bash
kubectl get events -n dev --sort-by='.lastTimestamp' | tail -20
kubectl get events -n monitoring --sort-by='.lastTimestamp' | tail -10
```
**Captura**: Actividad del cluster

---

## 10. TESTING Y VALIDACIÓN

### Health checks de servicios
```bash
# Via Ingress
curl -s http://ecommerce.local/actuator/health | jq
curl -s http://ecommerce.local/product-service/actuator/health | jq
curl -s http://ecommerce.local/order-service/actuator/health | jq

# Frontend API
curl -s http://frontend.ecommerce.local/api/product-service/api/products | jq '.collection | length'
curl -s http://frontend.ecommerce.local/api/order-service/api/orders | jq '.collection | length'
```
**Captura**: Servicios respondiendo correctamente

### Métricas de Actuator
```bash
curl -s http://ecommerce.local/actuator/metrics | jq
curl -s http://ecommerce.local/product-service/actuator/prometheus | head -30
```
**Captura**: Métricas expuestas correctamente

---

## 11. NAMESPACES Y ORGANIZACIÓN

### Namespaces configurados
```bash
kubectl get namespaces
kubectl describe namespace dev
kubectl describe namespace monitoring
```
**Captura**: Separación de ambientes

### Resource Quotas y Limits
```bash
kubectl describe namespace dev | grep -A 10 "Resource Quotas"
kubectl get pods -n dev -o json | jq '.items[0].spec.containers[0].resources'
```
**Captura**: Gestión de recursos

---

## 12. DOCUMENTACIÓN DEL PROYECTO

### Archivos de documentación creados
```bash
ls -lh *.md
cat PROJECT-SUMMARY.md
cat DEPLOYMENT-GUIDE.md
cat FRONTEND-DEPLOYMENT-GUIDE.md
cat BACKUP-RESTORE-GUIDE.md
```
**Captura**: Documentación completa generada

### Estructura de archivos K8s
```bash
tree k8s/
```
**Captura**: Organización de manifiestos

---

## 🎯 CHECKLIST DE CAPTURAS CRÍTICAS

### Terminal/CLI (19 capturas):
- [ ] `kubectl get pods -n dev -o wide` (todos los microservicios)
- [ ] `kubectl get pods -n monitoring` (Prometheus, Grafana, AlertManager)
- [ ] `kubectl get deployments -n dev` (réplicas configuradas)
- [ ] `kubectl get configmaps -n dev` (configuración)
- [ ] `kubectl get secrets -n dev` (gestión de secretos)
- [ ] `kubectl get serviceaccounts -n dev` (RBAC)
- [ ] `kubectl get ingress -n dev` (routing)
- [ ] `kubectl get networkpolicies -n dev` (seguridad de red)
- [ ] `kubectl get pvc -n dev` (persistencia)
- [ ] `kubectl get cronjobs -n dev` (backups)
- [ ] `kubectl get hpa -n dev` (autoscaling)
- [ ] `kubectl get services -n dev` (networking)
- [ ] `kubectl describe ingress api-gateway-ingress -n dev` (detalles de routing)
- [ ] `kubectl get prometheusrules -n monitoring` (alertas)
- [ ] `kubectl logs -n dev -l app=product-service --tail=30` (logs)
- [ ] `curl http://ecommerce.local/actuator/health` (health check)
- [ ] `curl http://frontend.ecommerce.local/api/product-service/api/products` (API funcionando)
- [ ] `kubectl get all -n dev` (vista completa dev)
- [ ] `kubectl get all -n monitoring` (vista completa monitoring)

### Navegador Web (12 capturas):
- [ ] Frontend - Tab Dashboard
- [ ] Frontend - Tab Productos (grid con 8+ productos)
- [ ] Frontend - Tab Pedidos (tabla con órdenes)
- [ ] Frontend - Tab Pagos (estadísticas de pagos)
- [ ] Frontend - Tab Envíos (shipments)
- [ ] Frontend - Tab Monitoreo (links a herramientas)
- [ ] Grafana - Login
- [ ] Grafana - Dashboard E-commerce
- [ ] Prometheus - Targets (todos UP)
- [ ] Prometheus - Alerts configuradas
- [ ] Eureka - Microservicios registrados
- [ ] Zipkin - Distributed tracing

---

## 📊 COMANDO RÁPIDO PARA VERIFICACIÓN COMPLETA

```bash
# Ejecutar este script para ver resumen de todo
echo "=== PODS ==="
kubectl get pods -n dev
echo ""
echo "=== MONITORING ==="
kubectl get pods -n monitoring
echo ""
echo "=== INGRESS ==="
kubectl get ingress -n dev
echo ""
echo "=== HPA ==="
kubectl get hpa -n dev
echo ""
echo "=== PVC ==="
kubectl get pvc -n dev
echo ""
echo "=== CRONJOBS ==="
kubectl get cronjobs -n dev
echo ""
echo "=== SERVICES ==="
kubectl get services -n dev
echo ""
echo "=== NETWORKPOLICIES ==="
kubectl get networkpolicies -n dev
echo ""
echo "=== CONFIGMAPS ==="
kubectl get configmaps -n dev | grep -v "kube-root-ca"
echo ""
echo "=== SECRETS ==="
kubectl get secrets -n dev | grep -v "default-token"
echo ""
echo "=== SERVICEACCOUNTS ==="
kubectl get serviceaccounts -n dev | grep -v "default"
```

---

## 🌐 URLS PARA ACCESO WEB

```bash
# Asegúrate de tener esto en /etc/hosts:
echo "127.0.0.1 ecommerce.local" | sudo tee -a /etc/hosts
echo "127.0.0.1 frontend.ecommerce.local" | sudo tee -a /etc/hosts
echo "127.0.0.1 grafana.ecommerce.local" | sudo tee -a /etc/hosts
echo "127.0.0.1 prometheus.ecommerce.local" | sudo tee -a /etc/hosts
echo "127.0.0.1 eureka.ecommerce.local" | sudo tee -a /etc/hosts
echo "127.0.0.1 zipkin.ecommerce.local" | sudo tee -a /etc/hosts
```

**URLs de acceso**:
- Frontend: http://frontend.ecommerce.local
- API Gateway: http://ecommerce.local
- Grafana: http://grafana.ecommerce.local (admin/admin123)
- Prometheus: http://prometheus.ecommerce.local
- Eureka: http://eureka.ecommerce.local
- Zipkin: http://zipkin.ecommerce.local

---

## 💡 TIPS PARA CAPTURAS

1. **Terminal**: Usa pantalla completa, fuente legible (14-16pt)
2. **Navegador**: Zoom 100%, oculta bookmarks, modo incógnito si es necesario
3. **Herramienta**: macOS Screenshot (Cmd+Shift+4), Snagit, o similar
4. **Formato**: PNG para mejor calidad
5. **Nombres**: Descriptivos - `01-pods-dev.png`, `02-grafana-dashboard.png`, etc.
6. **Orden**: Sigue el orden del checklist para facilitar la documentación

---

## 📁 ORGANIZACIÓN DE CAPTURAS SUGERIDA

```
capturas/
├── 01-arquitectura/
│   ├── pods-dev.png
│   ├── pods-monitoring.png
│   ├── deployments.png
│   └── all-resources.png
├── 02-configuracion/
│   ├── configmaps.png
│   ├── secrets.png
│   └── rbac-serviceaccounts.png
├── 03-red-seguridad/
│   ├── ingress-rules.png
│   ├── network-policies.png
│   └── tls-certificates.png
├── 04-persistencia/
│   ├── pvc-volumes.png
│   ├── cronjobs-backup.png
│   └── storage-class.png
├── 05-monitoreo/
│   ├── prometheus-targets.png
│   ├── prometheus-alerts.png
│   ├── grafana-dashboard.png
│   └── zipkin-traces.png
├── 06-autoscaling/
│   └── hpa-configured.png
├── 07-frontend/
│   ├── dashboard-tab.png
│   ├── products-tab.png
│   ├── orders-tab.png
│   ├── payments-tab.png
│   ├── shipping-tab.png
│   └── monitoring-tab.png
└── 08-testing/
    ├── health-checks.png
    ├── api-responses.png
    └── logs-services.png
```
