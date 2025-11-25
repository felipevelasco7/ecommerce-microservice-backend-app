# 🚀 ACCESO RÁPIDO - URLs del Proyecto

## ⚡ CONFIGURACIÓN INICIAL (Solo una vez)

```bash
# Agregar a /etc/hosts
sudo nano /etc/hosts
```

Copiar y pegar estas líneas:
```
35.223.30.48    frontend.ecommerce.local
35.223.30.48    grafana.ecommerce.local
35.223.30.48    prometheus.ecommerce.local
35.223.30.48    zipkin.ecommerce.local
35.223.30.48    eureka.ecommerce.local
35.223.30.48    alertmanager.ecommerce.local
35.223.30.48    ecommerce.local
```

---

## 🛒 APLICACIÓN E-COMMERCE

### Frontend Web (Interfaz Gráfica)
```
http://frontend.ecommerce.local
```
**Lo que verás**:
- ✅ Estado de 6 microservicios en tiempo real
- 📦 Catálogo de productos interactivo
- 🛒 Carrito de compras funcional
- 🔗 Links a herramientas de monitoreo

### API Gateway (Backend)
```
https://35.223.30.48
https://ecommerce.local
```

**Health Check**:
```bash
curl -k https://35.223.30.48/actuator/health
```

---

## 📊 MONITOREO Y OBSERVABILIDAD

### Grafana (Dashboards)
```
https://grafana.ecommerce.local
```
**Credenciales**:
- Usuario: `admin`
- Password: `admin123`

### Prometheus (Métricas)
```
http://prometheus.ecommerce.local
```

### Zipkin (Distributed Tracing)
```
http://zipkin.ecommerce.local
```

### Eureka (Service Discovery)
```
http://eureka.ecommerce.local
```

### AlertManager (Alertas)
```
http://alertmanager.ecommerce.local
```

---

## 🎯 ENDPOINTS API (vía API Gateway)

### Productos
```bash
# Listar todos los productos
curl -k https://35.223.30.48/product-service/api/products

# Producto por ID
curl -k https://35.223.30.48/product-service/api/products/1

# Productos por categoría
curl -k https://35.223.30.48/product-service/api/products/category/1
```

### Usuarios
```bash
# Listar usuarios
curl -k https://35.223.30.48/user-service/api/users

# Usuario por ID
curl -k https://35.223.30.48/user-service/api/users/1

# Usuario por username
curl -k https://35.223.30.48/user-service/api/users/username/admin
```

### Órdenes
```bash
# Listar órdenes
curl -k https://35.223.30.48/order-service/api/orders

# Orden por ID
curl -k https://35.223.30.48/order-service/api/orders/1

# Órdenes de un usuario
curl -k https://35.223.30.48/order-service/api/orders/user/1
```

### Pagos
```bash
# Listar pagos
curl -k https://35.223.30.48/payment-service/api/payments

# Pago por ID
curl -k https://35.223.30.48/payment-service/api/payments/1

# Pagos de una orden
curl -k https://35.223.30.48/payment-service/api/payments/order/1
```

### Envíos
```bash
# Listar envíos
curl -k https://35.223.30.48/shipping-service/api/shippings

# Envío por ID
curl -k https://35.223.30.48/shipping-service/api/shippings/1

# Envíos de una orden
curl -k https://35.223.30.48/shipping-service/api/shippings/order/1
```

### Favoritos
```bash
# Listar favoritos
curl -k https://35.223.30.48/favourite-service/api/favourites

# Favoritos de un usuario
curl -k https://35.223.30.48/favourite-service/api/favourites/user/1
```

---

## 🎬 DEMO AUTOMÁTICA

```bash
# Ejecutar script que abre todo
./start-demo.sh
```

Este script:
1. ✅ Verifica configuración
2. 🌐 Abre frontend en navegador
3. 📊 Abre Grafana
4. 🔍 Abre Zipkin
5. 🌐 Abre Eureka
6. 📈 Genera tráfico de prueba
7. 📋 Muestra resumen del sistema

---

## 🔧 COMANDOS ÚTILES DE KUBERNETES

```bash
# Ver todos los pods
kubectl get pods -n dev

# Ver servicios
kubectl get svc -n dev

# Ver HPAs (auto-scaling)
kubectl get hpa -n dev

# Ver Ingress
kubectl get ingress -A

# Ver Network Policies
kubectl get networkpolicy -n dev

# Ver ServiceAccounts
kubectl get sa -n dev

# Ver logs de un servicio
kubectl logs -n dev -l app=product-service --tail=50

# Ver uso de recursos
kubectl top pods -n dev
```

---

## 📈 GENERAR CARGA (Para Demo de Auto-Scaling)

```bash
# Opción 1: Curl loop
for i in {1..500}; do 
  curl -s http://frontend.ecommerce.local > /dev/null &
done

# Opción 2: Kubernetes load generator
kubectl run -i --tty load-generator --rm --image=busybox --restart=Never -- /bin/sh -c "while sleep 0.01; do wget -q -O- http://frontend.ecommerce.local; done"

# Ver HPAs escalando en tiempo real
watch kubectl get hpa -n dev
```

---

## 🐛 TROUBLESHOOTING

### Frontend no carga
```bash
# Verificar pods
kubectl get pods -n dev | grep frontend

# Verificar Ingress
kubectl get ingress -n dev frontend-ingress

# Verificar logs
kubectl logs -n dev -l app=frontend
```

### Servicios no aparecen en Eureka
```bash
# Verificar Eureka
kubectl get pods -n dev | grep eureka

# Logs de Eureka
kubectl logs -n dev -l app=service-discovery --tail=100
```

### Productos no cargan en frontend
```bash
# Verificar product-service
kubectl get pods -n dev | grep product

# Logs
kubectl logs -n dev -l app=product-service --tail=50

# Health check directo
curl -k https://35.223.30.48/product-service/actuator/health
```

---

## 📋 CHECKLIST DE VERIFICACIÓN

Antes de presentar, verifica:

- [ ] Frontend carga: http://frontend.ecommerce.local
- [ ] Grafana accesible: https://grafana.ecommerce.local
- [ ] Zipkin muestra trazas: http://zipkin.ecommerce.local
- [ ] Eureka muestra 6 servicios: http://eureka.ecommerce.local
- [ ] API Gateway responde: `curl -k https://35.223.30.48/actuator/health`
- [ ] Productos cargan: `curl -k https://35.223.30.48/product-service/api/products`
- [ ] HPAs activos: `kubectl get hpa -n dev`
- [ ] Todos los pods Running: `kubectl get pods -n dev`

---

## 📞 IP PRINCIPAL

```
35.223.30.48
```

Esta IP da acceso a TODO el sistema a través del Ingress Controller.

---

**💡 TIP**: Guarda este documento como favorito del navegador para acceso rápido durante la presentación.
