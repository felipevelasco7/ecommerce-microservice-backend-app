# Guía de Prueba - Sistema E-Commerce

## 🛍️ ACCESO GRÁFICO - LA FORMA MÁS FÁCIL

### ⚡ Inicio Rápido

```bash
# 1. Agregar al /etc/hosts
echo "35.223.30.48    frontend.ecommerce.local" | sudo tee -a /etc/hosts

# 2. Abrir en el navegador
open http://frontend.ecommerce.local  # macOS
# o
xdg-open http://frontend.ecommerce.local  # Linux
```

### 🎯 ¿Qué verás?

**Interfaz Web Completa** con:
- ✅ **Estado en tiempo real** de los 6 microservicios
- ✅ **Catálogo de productos** con diseño moderno
- ✅ **Carrito de compras** funcional
- ✅ **Links directos** a Grafana, Prometheus, Zipkin, Eureka

### 🚀 Script Automático de Demo

```bash
# Ejecuta este comando y todo se abrirá automáticamente
./start-demo.sh
```

Este script:
1. Verifica configuración
2. Abre el frontend
3. Abre Grafana
4. Abre Zipkin
5. Abre Eureka
6. Genera tráfico de prueba
7. Muestra resumen

---

## 🔧 Pruebas por Línea de Comandos (Opcional)

Si prefieres probar vía API directamente:

## 📋 Pruebas Básicas

### 1. Verificar que Todo Esté Funcionando

```bash
# Health check del API Gateway
curl -k https://35.223.30.48/actuator/health

# Ver servicios registrados
curl -k -s https://35.223.30.48/actuator/health | grep SERVICE
```

**Resultado Esperado**: Deberías ver 6 servicios activos:
- USER-SERVICE
- PRODUCT-SERVICE
- ORDER-SERVICE  
- PAYMENT-SERVICE
- SHIPPING-SERVICE
- FAVOURITE-SERVICE

---

## 🔍 Endpoints de la Aplicación

### User Service (Puerto 8700)

```bash
# Listar usuarios
curl -k https://35.223.30.48/user-service/api/users

# Obtener usuario por ID
curl -k https://35.223.30.48/user-service/api/users/1

# Health check
curl -k https://35.223.30.48/user-service/actuator/health
```

### Product Service (Puerto 8800)

```bash
# Listar productos
curl -k https://35.223.30.48/product-service/api/products

# Buscar producto por ID
curl -k https://35.223.30.48/product-service/api/products/1

# Buscar productos por categoría
curl -k https://35.223.30.48/product-service/api/products/category/1

# Health check
curl -k https://35.223.30.48/product-service/actuator/health
```

### Order Service (Puerto 8600)

```bash
# Listar órdenes
curl -k https://35.223.30.48/order-service/api/orders

# Obtener orden por ID
curl -k https://35.223.30.48/order-service/api/orders/1

# Órdenes de un usuario
curl -k https://35.223.30.48/order-service/api/orders/user/1

# Health check
curl -k https://35.223.30.48/order-service/actuator/health
```

### Payment Service (Puerto 8500)

```bash
# Listar pagos
curl -k https://35.223.30.48/payment-service/api/payments

# Obtener pago por ID
curl -k https://35.223.30.48/payment-service/api/payments/1

# Pagos de una orden
curl -k https://35.223.30.48/payment-service/api/payments/order/1

# Health check
curl -k https://35.223.30.48/payment-service/actuator/health
```

### Shipping Service (Puerto 8400)

```bash
# Listar envíos
curl -k https://35.223.30.48/shipping-service/api/shippings

# Obtener envío por ID
curl -k https://35.223.30.48/shipping-service/api/shippings/1

# Envíos de una orden
curl -k https://35.223.30.48/shipping-service/api/shippings/order/1

# Health check
curl -k https://35.223.30.48/shipping-service/actuator/health
```

### Favourite Service (Puerto 8300)

```bash
# Listar favoritos
curl -k https://35.223.30.48/favourite-service/api/favourites

# Favoritos de un usuario
curl -k https://35.223.30.48/favourite-service/api/favourites/user/1

# Health check
curl -k https://35.223.30.48/favourite-service/actuator/health
```

---

## 🎯 Flujo Completo de Compra (E2E Testing)

### Paso 1: Ver Productos Disponibles
```bash
curl -k https://35.223.30.48/product-service/api/products
```

### Paso 2: Agregar a Favoritos
```bash
curl -X POST -k https://35.223.30.48/favourite-service/api/favourites \
  -H "Content-Type: application/json" \
  -d '{
    "userId": 1,
    "productId": 1
  }'
```

### Paso 3: Crear una Orden
```bash
curl -X POST -k https://35.223.30.48/order-service/api/orders \
  -H "Content-Type: application/json" \
  -d '{
    "userId": 1,
    "products": [
      {"productId": 1, "quantity": 2}
    ]
  }'
```

### Paso 4: Procesar Pago
```bash
curl -X POST -k https://35.223.30.48/payment-service/api/payments \
  -H "Content-Type: application/json" \
  -d '{
    "orderId": 1,
    "amount": 100.00,
    "method": "CREDIT_CARD"
  }'
```

### Paso 5: Crear Envío
```bash
curl -X POST -k https://35.223.30.48/shipping-service/api/shippings \
  -H "Content-Type: application/json" \
  -d '{
    "orderId": 1,
    "address": "123 Main St",
    "city": "Cali"
  }'
```

---

## 📊 Monitoreo y Observabilidad

### Acceder a las Herramientas de Monitoreo

#### Opción A: Desde el Navegador (Requiere /etc/hosts)

Agregar a `/etc/hosts`:
```
35.223.30.48    grafana.ecommerce.local
35.223.30.48    prometheus.ecommerce.local
35.223.30.48    zipkin.ecommerce.local
35.223.30.48    alertmanager.ecommerce.local
35.223.30.48    eureka.ecommerce.local
```

Luego abrir:
- **Grafana**: https://grafana.ecommerce.local
  - Usuario: `admin`
  - Contraseña: `admin123`
  
- **Prometheus**: http://prometheus.ecommerce.local
- **Zipkin**: http://zipkin.ecommerce.local
- **AlertManager**: http://alertmanager.ecommerce.local
- **Eureka**: http://eureka.ecommerce.local

#### Opción B: Port-Forward (No requiere /etc/hosts)

```bash
# Grafana
kubectl port-forward -n monitoring svc/grafana 3000:3000
# Abrir: http://localhost:3000 (admin/admin123)

# Prometheus
kubectl port-forward -n monitoring svc/prometheus 9090:9090
# Abrir: http://localhost:9090

# Zipkin
kubectl port-forward -n dev svc/zipkin 9411:9411
# Abrir: http://localhost:9411

# AlertManager
kubectl port-forward -n monitoring svc/alertmanager 9093:9093
# Abrir: http://localhost:9093

# Eureka
kubectl port-forward -n dev svc/service-discovery 8761:8761
# Abrir: http://localhost:8761
```

---

## 🔥 Generar Carga para Pruebas

### Generar Tráfico para Ver Trazas en Zipkin

```bash
# Ejecutar 100 requests
for i in {1..100}; do
  curl -k -s https://35.223.30.48/actuator/health > /dev/null
  curl -k -s https://35.223.30.48/user-service/actuator/info > /dev/null
  curl -k -s https://35.223.30.48/product-service/actuator/info > /dev/null
  echo -n "."
done
echo "✓ Hecho!"
```

Luego ve a Zipkin para ver las trazas distribuidas.

### Probar Auto-Scaling (HPA)

```bash
# Generar carga en el API Gateway
kubectl run -i --tty load-generator --rm --image=busybox --restart=Never -- /bin/sh -c "while sleep 0.01; do wget -q -O- https://35.223.30.48/actuator/health; done"

# En otra terminal, ver el escalado
watch kubectl get hpa -n dev
```

---

## 🧪 Verificar Características Implementadas

### 1. Service Discovery (Eureka)
```bash
curl -k -s https://35.223.30.48/actuator/health | grep -A 20 "eureka"
```

### 2. Circuit Breakers
```bash
curl -k -s https://35.223.30.48/actuator/health | grep -A 10 "circuitBreakers"
```

### 3. Auto-Scaling (HPA)
```bash
kubectl get hpa -n dev
```

### 4. Network Policies
```bash
kubectl get networkpolicy -n dev
```

### 5. Backups Automáticos
```bash
kubectl get cronjob -n dev
kubectl get job -n dev | grep backup
```

### 6. Alertas Configuradas
```bash
# Ver reglas de alertas en Prometheus
curl -s http://35.223.30.48/api/v1/rules -H "Host: prometheus.ecommerce.local" | grep -o '"name":"[^"]*"' | head -20
```

### 7. TLS/HTTPS
```bash
curl -k -I https://35.223.30.48 | grep -E "(HTTP|strict-transport|x-frame)"
```

### 8. RBAC y ServiceAccounts
```bash
kubectl get sa -n dev
kubectl get rolebinding -n dev
```

---

## 📈 Métricas en Prometheus

Queries útiles en Prometheus (http://prometheus.ecommerce.local):

```promql
# Request rate por servicio
rate(http_server_requests_seconds_count[5m])

# Uso de CPU de pods
rate(container_cpu_usage_seconds_total{pod=~".*-service.*"}[5m])

# Uso de memoria
container_memory_usage_bytes{pod=~".*-service.*"}

# Estado de HPAs
kube_horizontalpodautoscaler_status_current_replicas

# Pods en estado Running
kube_pod_status_phase{phase="Running"}
```

---

## 🎬 Demo Rápido en 5 Minutos

```bash
# 1. Verificar salud del sistema (30 seg)
curl -k https://35.223.30.48/actuator/health

# 2. Ver servicios registrados (30 seg)
curl -k -s https://35.223.30.48/actuator/health | grep SERVICE

# 3. Probar un endpoint de negocio (30 seg)
curl -k https://35.223.30.48/product-service/api/products

# 4. Generar tráfico para trazas (1 min)
for i in {1..50}; do curl -k -s https://35.223.30.48/actuator/health > /dev/null; echo -n "."; done

# 5. Ver Grafana (1 min)
# Abrir: https://grafana.ecommerce.local (admin/admin123)

# 6. Ver Zipkin (1 min)
# Abrir: http://zipkin.ecommerce.local

# 7. Ver Prometheus (1 min)
# Abrir: http://prometheus.ecommerce.local

# 8. Ver HPA funcionando (30 seg)
kubectl get hpa -n dev
```

---

## ✅ Checklist de Verificación

- [ ] API Gateway responde (HTTPS)
- [ ] 6 microservicios registrados en Eureka
- [ ] Circuit Breakers en estado CLOSED
- [ ] HPA muestra métricas de CPU/memoria
- [ ] Network Policies aplicadas (15 políticas)
- [ ] Backup CronJob configurado
- [ ] Prometheus scrapeando métricas
- [ ] AlertManager con reglas activas
- [ ] Grafana accesible
- [ ] Zipkin mostrando trazas
- [ ] Ingress con TLS funcionando
- [ ] ServiceAccounts asignados

---

**Proyecto**: E-Commerce Microservices  
**Plataforma**: Google Kubernetes Engine (GKE)  
**Score Actual**: ~77-82/100 puntos  
**Fecha**: Noviembre 2025
