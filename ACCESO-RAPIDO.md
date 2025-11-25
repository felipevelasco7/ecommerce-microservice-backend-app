# 🚀 ACCESO RÁPIDO AL E-COMMERCE

## ✅ CONFIGURACIÓN NECESARIA (Una sola vez)

### Paso 1: Agregar a /etc/hosts

```bash
sudo nano /etc/hosts
```

Agregar esta línea:
```
35.223.30.48    frontend.ecommerce.local
```

Guardar (Ctrl+O, Enter, Ctrl+X)

---

## 🛍️ ABRIR LA TIENDA

### En tu navegador, ve a:

```
http://frontend.ecommerce.local
```

⚠️ **IMPORTANTE**: Usa **HTTP** (no HTTPS) para el frontend

---

## 📊 MONITOREO (Opcionales)

Si quieres ver el monitoreo, agrega también estas líneas a /etc/hosts:

```
35.223.30.48    grafana.ecommerce.local
35.223.30.48    prometheus.ecommerce.local
35.223.30.48    zipkin.ecommerce.local
35.223.30.48    eureka.ecommerce.local
```

Luego abre:
- **Grafana**: https://grafana.ecommerce.local (admin/admin123)
- **Prometheus**: http://prometheus.ecommerce.local
- **Zipkin**: http://zipkin.ecommerce.local
- **Eureka**: http://eureka.ecommerce.local

---

## 🎯 ¿QUÉ VAS A VER EN EL FRONTEND?

1. **Estado de Microservicios** - Ver cuáles servicios están online
2. **Catálogo de Productos** - Ver productos disponibles
3. **Agregar al Carrito** - Funcionalidad de e-commerce
4. **Links a Monitoreo** - Acceso rápido a Grafana, Prometheus, etc.

---

## 🔧 TROUBLESHOOTING

### No carga la página
```bash
# Verificar que el frontend esté corriendo
kubectl get pods -n dev | grep frontend

# Ver logs si hay errores
kubectl logs -n dev -l app=frontend
```

### Sale "Cannot GET /"
Verifica que hayas agregado `frontend.ecommerce.local` a `/etc/hosts`

### Página en blanco
```bash
# Reiniciar el frontend
kubectl rollout restart deployment frontend -n dev
kubectl rollout status deployment frontend -n dev
```

---

## 🎬 DEMO PARA PRESENTACIÓN

1. Abre **http://frontend.ecommerce.local** en el navegador
2. Muestra el estado de los microservicios (deberían estar en verde)
3. Scroll al catálogo de productos
4. Click en "Agregar al Carrito" en un producto
5. Muestra el contador del carrito incrementando
6. Abre Zipkin en otra pestaña para ver las trazas
7. Abre Grafana para ver las métricas en tiempo real

---

**IP del Ingress**: `35.223.30.48`  
**Namespace**: `dev`  
**Servicios Activos**: 6 microservicios + API Gateway
