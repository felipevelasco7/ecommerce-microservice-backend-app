# 🛍️ Guía de Uso del Frontend E-Commerce

## Acceso Rápido

### Paso 1: Configurar /etc/hosts

```bash
sudo nano /etc/hosts
```

Agregar:
```
35.223.30.48    frontend.ecommerce.local
```

### Paso 2: Abrir en el Navegador

🛒 **URL**: http://frontend.ecommerce.local

⚠️ **IMPORTANTE**: 
- Usa **HTTP** (no HTTPS) para el frontend
- La página cargará automáticamente sin advertencias de seguridad
- Verás el estado de todos los microservicios en tiempo real

---

## 📱 Interfaz de Usuario

El frontend es una **Single Page Application (SPA)** construida con HTML5, CSS3 y JavaScript vanilla que se comunica directamente con el **API Gateway** para consumir todos los microservicios.

### Funcionalidades Disponibles

#### 📊 1. Dashboard de Estado de Servicios
- **Monitoreo en tiempo real** de todos los microservicios
- **Indicadores visuales** (verde = online, rojo = offline)
- **Contador de instancias** de cada servicio
- **Auto-refresh** cada 30 segundos

#### 📦 2. Catálogo de Productos
- **Carga automática** desde el Product Service
- **Visualización de productos** con:
  - Título del producto
  - Precio en tiempo real
  - Stock disponible
  - SKU único
  - Categoría (Electrónica, Moda, Juegos)
- **Interfaz responsive** con grid adaptable

#### 🛒 3. Carrito de Compras
- **Agregar productos al carrito** con un click
- **Contador visual** en el header (badge rojo)
- **Notificaciones** al agregar productos
- **Almacenamiento local** (persiste en el navegador)
- **Vista del carrito** con resumen y total

#### 📊 4. Links de Monitoreo
- **Acceso directo** a herramientas de observabilidad:
  - Grafana (dashboards y métricas)
  - Prometheus (queries y alertas)
  - Zipkin (trazas distribuidas)
  - Eureka (service discovery)
- **Apertura en nueva pestaña** para no perder el contexto

---

## 🎯 Flujo Completo de Compra (Demo)

### Escenario: Usuario Compra un Producto

#### 1️⃣ Registro/Login
```
1. Ir a https://shop.ecommerce.local
2. Click en "Registrarse" o "Login"
3. Ingresar credenciales
```

#### 2️⃣ Navegar Catálogo
```
1. Ver productos destacados en la página principal
2. Filtrar por categoría (Ej: "Electrónica")
3. Click en un producto para ver detalles
```

#### 3️⃣ Agregar al Carrito
```
1. Seleccionar cantidad deseada
2. Click en "Agregar al Carrito"
3. Continuar comprando o ir al carrito
```

#### 4️⃣ Revisar Carrito
```
1. Click en icono del carrito
2. Revisar productos y cantidades
3. Modificar si es necesario
4. Click en "Proceder al Pago"
```

#### 5️⃣ Checkout
```
1. Ingresar/Confirmar dirección de envío
2. Seleccionar método de pago
3. Revisar resumen de la orden
4. Click en "Confirmar Compra"
```

#### 6️⃣ Confirmación
```
1. Ver número de orden generado
2. Ver detalles de envío
3. Recibir confirmación en pantalla
4. Redirección a "Mis Órdenes"
```

---

## 🔍 Verificar Funcionamiento Backend

Mientras usas el frontend, puedes ver la actividad en los microservicios:

### Ver Trazas en Zipkin
```bash
# En otra terminal
open http://zipkin.ecommerce.local

# O con /etc/hosts configurado
```

Cada acción en el frontend genera trazas distribuidas que puedes ver en tiempo real.

### Ver Métricas en Grafana
```bash
# Acceder a Grafana
open https://grafana.ecommerce.local

# Login: admin / admin123
```

Dashboard muestra:
- Requests por segundo
- Latencia de cada servicio
- Uso de recursos (CPU/Memoria)
- Errores y excepciones

### Ver Servicios en Eureka
```bash
open http://eureka.ecommerce.local
```

Muestra todos los servicios registrados y su estado (UP/DOWN).

---

## 🐛 Troubleshooting

### Problema: "Conexión rechazada" o "No se puede acceder"

**Solución 1**: Verificar que /etc/hosts esté configurado
```bash
cat /etc/hosts | grep shop.ecommerce.local
```

**Solución 2**: Verificar que el proxy-client esté corriendo
```bash
kubectl get pods -n dev | grep proxy-client
```

**Solución 3**: Verificar el Ingress
```bash
kubectl get ingress -n dev proxy-client-ingress
```

### Problema: "Certificado no válido"

**Es normal** - Estamos usando un certificado auto-firmado. Simplemente acepta la advertencia en tu navegador.

### Problema: "404 Not Found" en algunas páginas

**Causa**: El proxy-client puede no tener rutas configuradas.

**Verificar logs**:
```bash
kubectl logs -n dev -l app=proxy-client --tail=100
```

### Problema: Errores en formularios (400 Bad Request)

**Causa**: Campos requeridos faltantes o validación fallida.

**Verificar**: 
- Todos los campos obligatorios estén llenos
- Formato de datos correcto (email, números, etc.)
- Logs del servicio correspondiente:
```bash
kubectl logs -n dev -l app=order-service --tail=50
kubectl logs -n dev -l app=payment-service --tail=50
```

---

## 📊 Arquitectura del Frontend

```
┌─────────────────────────────────────────────┐
│         NAVEGADOR WEB                       │
│   https://shop.ecommerce.local              │
└───────────────────┬─────────────────────────┘
                    │ HTTPS (TLS)
                    ▼
┌─────────────────────────────────────────────┐
│     NGINX INGRESS CONTROLLER                │
│     IP: 35.223.30.48                        │
│     - Session Affinity (cookies)            │
│     - Security Headers                      │
└───────────────────┬─────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────┐
│     PROXY-CLIENT SERVICE                    │
│     (Spring Boot + Thymeleaf)               │
│     Puerto: 8900                            │
│     - Spring Security + JWT                 │
│     - OpenFeign Clients                     │
│     - Server-side rendering                 │
└───────────────────┬─────────────────────────┘
                    │
        ┌───────────┼───────────┬──────────┐
        ▼           ▼           ▼          ▼
    ┌──────┐   ┌──────┐   ┌──────┐   ┌──────┐
    │USER  │   │PROD  │   │ORDER │   │PAY   │
    │SVC   │   │SVC   │   │SVC   │   │SVC   │
    └──────┘   └──────┘   └──────┘   └──────┘
        ▼           ▼           ▼          ▼
    ┌──────┐   ┌──────┐   ┌──────┐   ┌──────┐
    │SHIP  │   │FAV   │   │EUREKA│   │CONFIG│
    │SVC   │   │SVC   │   │      │   │      │
    └──────┘   └──────┘   └──────┘   └──────┘
```

### Tecnologías Utilizadas

- **Frontend Framework**: Spring Boot 2.5 + Thymeleaf
- **Seguridad**: Spring Security + JWT
- **Cliente HTTP**: OpenFeign (comunicación con microservicios)
- **Service Discovery**: Eureka Client
- **Trazabilidad**: Spring Cloud Sleuth + Zipkin
- **Métricas**: Micrometer + Prometheus
- **Session Management**: Cookie-based con Redis (opcional)

---

## 🎬 Script de Demo Automatizado

Si necesitas demostrar el sistema sin interacción manual:

```bash
#!/bin/bash

echo "🛍️ DEMO E-COMMERCE AUTOMATIZADO"
echo "================================"

API="https://shop.ecommerce.local"

# 1. Verificar que el frontend esté arriba
echo -e "\n1️⃣ Verificando frontend..."
curl -k -s -o /dev/null -w "Status: %{http_code}\n" $API

# 2. Generar tráfico simulado
echo -e "\n2️⃣ Generando tráfico de usuarios..."
for i in {1..20}; do
  curl -k -s $API > /dev/null
  curl -k -s $API/products > /dev/null 2>&1
  curl -k -s $API/cart > /dev/null 2>&1
  echo -n "."
done
echo " ✓"

# 3. Verificar servicios backend
echo -e "\n3️⃣ Verificando servicios backend..."
kubectl get pods -n dev | grep -E "(user|product|order|payment|shipping|favourite)-service" | grep Running

# 4. Ver métricas
echo -e "\n4️⃣ Acceso a monitoreo:"
echo "   📊 Grafana: https://grafana.ecommerce.local"
echo "   🔍 Zipkin: http://zipkin.ecommerce.local"
echo "   📈 Prometheus: http://prometheus.ecommerce.local"

echo -e "\n✅ Demo completado!"
echo "   Ahora abre https://shop.ecommerce.local en tu navegador"
```

Guardar como `demo-frontend.sh` y ejecutar:
```bash
chmod +x demo-frontend.sh
./demo-frontend.sh
```

---

## 📝 Notas Importantes

1. **Persistencia de Datos**: Los datos están almacenados en PostgreSQL, así que tus órdenes y usuarios se mantienen entre reinicios.

2. **Session Affinity**: El Ingress usa cookies para mantener la sesión con el mismo pod.

3. **Security Headers**: El frontend tiene headers de seguridad configurados (X-Frame-Options, HSTS, etc.).

4. **Rate Limiting**: Hay límites de 100 requests/segundo por IP.

5. **JWT Tokens**: La autenticación usa JWT tokens con expiración de 24 horas.

---

## 🎯 Objetivos de la Demo

Para la presentación del proyecto, demuestra:

✅ **Login funcional** - Autenticación de usuarios  
✅ **Catálogo de productos** - Microservicio de productos  
✅ **Agregar al carrito** - Estado de sesión  
✅ **Proceso de checkout** - Integración de múltiples servicios  
✅ **Confirmación de orden** - Microservicio de órdenes  
✅ **Pago procesado** - Microservicio de pagos  
✅ **Envío creado** - Microservicio de shipping  
✅ **Trazas en Zipkin** - Observabilidad distribuida  
✅ **Métricas en Grafana** - Monitoreo en tiempo real  
✅ **Auto-scaling** - Ver HPAs escalando pods  

---

**¡Disfruta explorando tu E-Commerce en Kubernetes!** 🚀
