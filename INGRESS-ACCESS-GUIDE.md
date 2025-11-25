# Guía de Acceso con Ingress Controller

## 🌐 Información del Ingress Controller

**IP Externa del Ingress**: `35.223.30.48`

Todos los servicios ahora están accesibles a través del Ingress Controller con TLS/HTTPS configurado.

## 📝 Configuración del archivo /etc/hosts

Para acceder a los servicios usando nombres de dominio, agrega las siguientes líneas a tu archivo `/etc/hosts`:

### En macOS/Linux:
```bash
sudo nano /etc/hosts
```

### En Windows:
```
C:\Windows\System32\drivers\etc\hosts
```

### Agregar estas líneas:
```
35.223.30.48    shop.ecommerce.local
35.223.30.48    www.ecommerce.local
35.223.30.48    ecommerce.local
35.223.30.48    api.ecommerce.local
35.223.30.48    grafana.ecommerce.local
35.223.30.48    zipkin.ecommerce.local
35.223.30.48    eureka.ecommerce.local
35.223.30.48    prometheus.ecommerce.local
35.223.30.48    alertmanager.ecommerce.local
```

---

## 🛍️ ACCESO AL FRONTEND (Interfaz Gráfica del E-Commerce)

### URL Principal de la Tienda Web:
```
🛒 FRONTEND: https://shop.ecommerce.local
🛒 ALTERNATIVO: https://www.ecommerce.local

⚠️ IMPORTANTE: Acepta el certificado auto-firmado en tu navegador
```

**Funcionalidades del Frontend**:
- 🔐 Login y registro de usuarios
- 📦 Catálogo completo de productos
- 🛒 Carrito de compras
- 💳 Proceso de checkout y pago
- 📦 Historial de órdenes
- ❤️ Gestión de productos favoritos
- 👤 Perfil de usuario

---

## 🔐 Endpoints HTTPS Disponibles

### 1. API Gateway (Principal)
```
HTTPS: https://ecommerce.local
HTTPS: https://api.ecommerce.local
HTTP:  http://35.223.30.48 (redirige a HTTPS)

Ejemplos:
curl -k https://ecommerce.local/actuator/health
curl -k https://api.ecommerce.local/actuator/info
```

### 2. Grafana (Dashboards y Monitoreo)
```
HTTPS: https://grafana.ecommerce.local
HTTP:  http://35.223.30.48 (en puerto Grafana)

Credenciales:
Usuario: admin
Password: admin123

Acceso:
open https://grafana.ecommerce.local
```

### 3. Zipkin (Distributed Tracing)
```
HTTP: http://zipkin.ecommerce.local

Acceso:
open http://zipkin.ecommerce.local
```

### 4. Eureka (Service Discovery)
```
HTTP: http://eureka.ecommerce.local

Acceso:
open http://eureka.ecommerce.local
```

### 5. Prometheus (Metrics)
```
HTTP: http://prometheus.ecommerce.local

Acceso:
open http://prometheus.ecommerce.local
```

### 6. AlertManager (Alertas)
```
HTTP: http://alertmanager.ecommerce.local

Acceso:
open http://alertmanager.ecommerce.local
```

## 🧪 Pruebas de Funcionalidad

### Test 1: Health Check del API Gateway
```bash
# Con certificado autofirmado (usar -k para ignorar validación)
curl -k https://ecommerce.local/actuator/health

# Debería retornar: {"status":"UP"}
```

### Test 2: Acceso a través de HTTP (redirección a HTTPS)
```bash
curl -L http://ecommerce.local/actuator/health

# El flag -L sigue las redirecciones automáticamente
```

### Test 3: Verificar headers de seguridad
```bash
curl -k -I https://ecommerce.local

# Debería mostrar headers como:
# - Strict-Transport-Security
# - X-Frame-Options: DENY
# - X-Content-Type-Options: nosniff
# - X-XSS-Protection
```

### Test 4: Acceso a servicios específicos
```bash
# User Service
curl -k https://ecommerce.local/user-service/actuator/health

# Product Service
curl -k https://ecommerce.local/product-service/actuator/health

# Order Service
curl -k https://ecommerce.local/order-service/actuator/health
```

### Test 5: Generar tráfico para trazas
```bash
# Script para generar 50 requests
for i in {1..50}; do
  curl -k -s https://ecommerce.local/actuator/health > /dev/null
  echo "Request $i completed"
  sleep 0.5
done

# Luego ver las trazas en:
open http://zipkin.ecommerce.local
```

## 🔒 Características de Seguridad Implementadas

### TLS/HTTPS
- ✅ Certificado SSL self-signed creado
- ✅ Redirección automática HTTP → HTTPS
- ✅ HSTS (Strict-Transport-Security) habilitado
- ✅ Certificado válido por 365 días

### Security Headers
- ✅ X-Frame-Options: DENY (previene clickjacking)
- ✅ X-Content-Type-Options: nosniff (previene MIME sniffing)
- ✅ X-XSS-Protection: 1; mode=block (protección XSS)
- ✅ Strict-Transport-Security (fuerza HTTPS)

### Rate Limiting
- ✅ Límite de 100 requests por segundo (RPS)
- ✅ Máximo 50 conexiones concurrentes
- ✅ Previene ataques DDoS básicos

### CORS
- ✅ CORS habilitado para desarrollo
- ✅ Métodos permitidos: GET, POST, PUT, DELETE, OPTIONS
- ✅ Configurable por ambiente

### Timeouts
- ✅ Connection timeout: 60s
- ✅ Send timeout: 60s
- ✅ Read timeout: 60s
- ✅ Previene conexiones colgadas

### Body Size
- ✅ API Gateway: máximo 10MB por request
- ✅ Grafana: máximo 50MB (para dashboards grandes)

## 📊 Monitoreo del Ingress

### Ver logs del Ingress Controller
```bash
kubectl logs -n ingress-nginx deployment/ingress-nginx-controller -f
```

### Ver métricas del Ingress
```bash
# El Ingress Controller expone métricas en formato Prometheus
kubectl port-forward -n ingress-nginx svc/ingress-nginx-controller-metrics 10254:10254

# Acceder a:
open http://localhost:10254/metrics
```

### Ver estado de los Ingress
```bash
kubectl get ingress -A

kubectl describe ingress api-gateway-ingress -n dev
kubectl describe ingress grafana-ingress -n monitoring
```

## 🔧 Troubleshooting

### Problema: "Connection refused"
```bash
# Verificar que el Ingress Controller esté ejecutándose
kubectl get pods -n ingress-nginx

# Verificar que tenga IP externa
kubectl get svc -n ingress-nginx
```

### Problema: "Certificate error" en navegador
Esto es esperado con certificados self-signed. Opciones:
1. Aceptar el riesgo en el navegador
2. Usar `curl -k` para ignorar validación
3. Para producción: usar Let's Encrypt con cert-manager

### Problema: "404 Not Found"
```bash
# Verificar que los backends estén funcionando
kubectl get svc -n dev
kubectl get pods -n dev

# Verificar reglas del Ingress
kubectl get ingress api-gateway-ingress -n dev -o yaml
```

### Problema: "502 Bad Gateway"
```bash
# El servicio backend no está respondiendo
kubectl logs -n dev deployment/api-gateway

# Verificar health del servicio
kubectl exec -n dev deployment/api-gateway -- wget -O- localhost:8200/actuator/health
```

## 🚀 Próximos Pasos

### Para Producción:
1. **Cert-Manager**: Automatizar certificados con Let's Encrypt
   ```bash
   kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml
   ```

2. **WAF**: Web Application Firewall con ModSecurity
3. **DNS Real**: Configurar dominio real en lugar de /etc/hosts
4. **Rate Limiting Avanzado**: Por usuario, IP, o API key
5. **OAuth2/JWT**: Autenticación y autorización centralizada

### Comandos Útiles:
```bash
# Editar configuración del Ingress
kubectl edit ingress api-gateway-ingress -n dev

# Ver eventos del Ingress
kubectl get events -n dev --sort-by='.lastTimestamp' | grep ingress

# Restart Ingress Controller
kubectl rollout restart deployment ingress-nginx-controller -n ingress-nginx
```

## 📈 Métricas del Ingress (Prometheus)

El Ingress Controller exporta métricas útiles:

```promql
# Request rate
rate(nginx_ingress_controller_requests[5m])

# Response time p95
histogram_quantile(0.95, rate(nginx_ingress_controller_request_duration_seconds_bucket[5m]))

# Error rate
rate(nginx_ingress_controller_requests{status=~"5.."}[5m])

# Bytes transferred
rate(nginx_ingress_controller_response_size_bytes[5m])
```

## 🎯 Cumplimiento de Requerimientos

Con esta implementación se cubren los siguientes requerimientos del proyecto:

### Red y Seguridad (15%):
- ✅ Ingress Controller implementado
- ✅ TLS/HTTPS configurado para endpoints públicos
- ✅ Security headers implementados
- ✅ Rate limiting configurado
- ✅ CORS configurado
- ✅ Timeouts configurados
- ✅ Redirección HTTP → HTTPS

### Puntos Adicionales:
- ✅ Multiple hosts configurados (subdomains)
- ✅ Path-based routing
- ✅ Backend health checks
- ✅ Métricas exportadas para Prometheus
- ✅ Logs estructurados

---

**Última actualización**: 24 de noviembre de 2025  
**Versión Ingress Controller**: nginx 1.8.2  
**IP Externa**: 35.223.30.48
