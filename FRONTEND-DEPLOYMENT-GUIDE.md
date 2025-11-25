# Guía Completa de Despliegue del Frontend E-Commerce

## 📋 Índice
1. [Descripción General](#descripción-general)
2. [Arquitectura](#arquitectura)
3. [Prerequisitos](#prerequisitos)
4. [Paso 1: Crear el Frontend HTML](#paso-1-crear-el-frontend-html)
5. [Paso 2: Desplegar en Kubernetes](#paso-2-desplegar-en-kubernetes)
6. [Paso 3: Configurar Ingress](#paso-3-configurar-ingress)
7. [Paso 4: Configurar DNS Local](#paso-4-configurar-dns-local)
8. [Paso 5: Verificar Funcionamiento](#paso-5-verificar-funcionamiento)
9. [Troubleshooting](#troubleshooting)
10. [Comandos de Mantenimiento](#comandos-de-mantenimiento)

---

## Descripción General

Este frontend es una **Single Page Application (SPA)** que proporciona una interfaz gráfica web para el sistema de e-commerce basado en microservicios. Características principales:

- ✅ **Visualización de estado** de los 8 microservicios en tiempo real
- ✅ **Catálogo de productos** con información de stock y precios
- ✅ **Carrito de compras** funcional
- ✅ **Enlaces directos** a herramientas de monitoreo (Grafana, Prometheus, Zipkin, Eureka)
- ✅ **Diseño responsivo** con gradientes modernos
- ✅ **Sin dependencias externas** - HTML5 + CSS3 + Vanilla JavaScript puro

---

## Arquitectura

```
┌─────────────────────────────────────────────────────────────────┐
│                         Usuario (Navegador)                      │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             │ HTTP
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│              Nginx Ingress Controller (35.223.30.48)            │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  Host: frontend.ecommerce.local                          │  │
│  │                                                            │  │
│  │  Path: /          → Frontend Service (nginx:alpine)      │  │
│  │  Path: /api/*     → API Gateway (rewrite: /*)            │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                             │
              ┌──────────────┴──────────────┐
              │                             │
              ▼                             ▼
    ┌─────────────────┐         ┌─────────────────────┐
    │ Frontend Service│         │  API Gateway Service│
    │  (ClusterIP)    │         │    (ClusterIP)      │
    │   Port: 80      │         │    Port: 80         │
    └────────┬────────┘         └──────────┬──────────┘
             │                             │
             ▼                             ▼
    ┌─────────────────┐         ┌─────────────────────┐
    │ Frontend Pods   │         │  API Gateway Pods   │
    │  (2 replicas)   │         │    (2 replicas)     │
    │                 │         │                     │
    │ nginx:alpine    │         │  Spring Cloud GW    │
    │ HTML from       │         │  Routes to:         │
    │ ConfigMap       │         │  - product-service  │
    │                 │         │  - user-service     │
    │                 │         │  - order-service    │
    │                 │         │  - payment-service  │
    │                 │         │  - shipping-service │
    │                 │         │  - favourite-service│
    └─────────────────┘         └─────────────────────┘
```

**Flujo de datos:**

1. Usuario accede a `http://frontend.ecommerce.local`
2. Ingress Controller enruta a Frontend Service
3. nginx sirve el HTML estático desde ConfigMap
4. JavaScript hace peticiones AJAX a `/api/*`
5. Ingress reescribe `/api/*` → `/*` y enruta a API Gateway
6. API Gateway distribuye a microservicios correspondientes
7. Respuesta JSON regresa al navegador

---

## Prerequisitos

### Software Requerido
- ✅ Kubernetes cluster funcionando (GKE, minikube, etc.)
- ✅ `kubectl` configurado y conectado al cluster
- ✅ Nginx Ingress Controller instalado
- ✅ Microservicios de e-commerce desplegados en namespace `dev`

### Verificar Prerequisitos

```bash
# Verificar kubectl
kubectl version --client

# Verificar conexión al cluster
kubectl cluster-info

# Verificar Ingress Controller
kubectl get pods -n ingress-nginx

# Verificar microservicios
kubectl get pods -n dev

# Verificar API Gateway
kubectl get svc -n dev api-gateway
```

**Salida esperada:**
- Ingress Controller: 1 pod Running
- API Gateway: 2+ pods Running
- Otros servicios: product-service, user-service, etc. Running

---

## Paso 1: Crear el Frontend HTML

### 1.1 Crear directorio

```bash
cd /ruta/a/tu/proyecto/ecommerce-microservice-backend-app
mkdir -p frontend
cd frontend
```

### 1.2 Crear archivo index.html

```bash
# El archivo completo está en:
# ecommerce-microservice-backend-app/frontend/index.html
```

**Componentes clave del HTML:**

```javascript
// API Base URL (rutas relativas para evitar CORS)
const API_BASE = '/api';

// Endpoints principales
/api/actuator/health              // Estado de microservicios
/api/product-service/api/products // Catálogo de productos
```

**Estructura de la respuesta de productos:**

```json
{
  "collection": [
    {
      "productId": 1,
      "productTitle": "asus",
      "imageUrl": "xxx",
      "sku": "dfqejklejrkn",
      "priceUnit": 0.0,
      "quantity": 50,
      "category": {
        "categoryId": 1,
        "categoryTitle": "Computer"
      }
    }
  ]
}
```

**Nota importante:** La API devuelve `collection`, no `content`. El código lo maneja:

```javascript
const productList = products?.collection || products?.content || [];
```

---

## Paso 2: Desplegar en Kubernetes

### 2.1 Crear ConfigMap con el HTML

```bash
kubectl create configmap frontend-html -n dev \
  --from-file=index.html=/Users/felipevelasco79/Documents/Icesi/Plataformas2/Proyecto-Final-Google/ecommerce-microservice-backend-app/frontend/index.html
```

**Verificar ConfigMap:**

```bash
kubectl get configmap frontend-html -n dev

# Ver tamaño (debe ser ~14KB)
kubectl get configmap frontend-html -n dev -o yaml | grep -A 1 "index.html:" | head -5
```

### 2.2 Crear Deployment

Crear archivo `k8s/deployments/frontend.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
  namespace: dev
  labels:
    app: frontend
    version: v1
spec:
  replicas: 2
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
        version: v1
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        ports:
        - containerPort: 80
          name: http
        resources:
          requests:
            memory: "32Mi"
            cpu: "50m"
          limits:
            memory: "64Mi"
            cpu: "100m"
        volumeMounts:
        - name: html
          mountPath: /usr/share/nginx/html
          readOnly: true
        livenessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 10
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 5
      volumes:
      - name: html
        configMap:
          name: frontend-html
```

**Aplicar:**

```bash
kubectl apply -f k8s/deployments/frontend.yaml
```

### 2.3 Crear Service

Crear archivo `k8s/services/frontend-service.yaml`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: frontend
  namespace: dev
  labels:
    app: frontend
spec:
  type: ClusterIP
  selector:
    app: frontend
  ports:
  - port: 80
    targetPort: 80
    protocol: TCP
    name: http
```

**Aplicar:**

```bash
kubectl apply -f k8s/services/frontend-service.yaml
```

### 2.4 Verificar Despliegue

```bash
# Ver pods
kubectl get pods -n dev -l app=frontend

# Ver logs
kubectl logs -n dev -l app=frontend --tail=20

# Ver servicio
kubectl get svc -n dev frontend

# Probar servicio internamente (port-forward temporal)
kubectl port-forward -n dev svc/frontend 8080:80 &
curl http://localhost:8080
# Debe devolver el HTML
killall kubectl  # Detener port-forward
```

---

## Paso 3: Configurar Ingress

### 3.1 Actualizar archivo de Ingress

Editar `k8s/ingress/api-gateway-ingress.yaml` y agregar al final:

```yaml
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: frontend-ingress
  namespace: dev
  annotations:
    kubernetes.io/ingress.class: "nginx"
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
    
    # Rewrite /api/* to /* for API Gateway
    nginx.ingress.kubernetes.io/rewrite-target: /$2
    
    # Security headers for web UI
    nginx.ingress.kubernetes.io/configuration-snippet: |
      more_set_headers "X-Frame-Options: SAMEORIGIN";
      more_set_headers "X-Content-Type-Options: nosniff";
    
spec:
  ingressClassName: nginx
  rules:
  # Frontend web UI
  - host: frontend.ecommerce.local
    http:
      paths:
      # Proxy /api requests to API Gateway (with rewrite)
      - path: /api(/|$)(.*)
        pathType: ImplementationSpecific
        backend:
          service:
            name: api-gateway
            port:
              number: 80
      # Serve frontend static files
      - path: /
        pathType: Prefix
        backend:
          service:
            name: frontend
            port:
              number: 80
```

**Explicación de la configuración:**

- **`nginx.ingress.kubernetes.io/rewrite-target: /$2`**: Reescribe `/api/actuator/health` → `/actuator/health`
- **`path: /api(/|$)(.*)`**: Captura grupo $2 con todo después de `/api/`
- **Orden de paths**: `/api/*` primero (más específico), `/` después (catch-all)

### 3.2 Aplicar Ingress

```bash
kubectl apply -f k8s/ingress/api-gateway-ingress.yaml
```

### 3.3 Verificar Ingress

```bash
# Ver todos los Ingress
kubectl get ingress -n dev

# Ver detalles del frontend-ingress
kubectl describe ingress frontend-ingress -n dev

# Ver IP del Ingress Controller
kubectl get ingress -n dev frontend-ingress -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

**Salida esperada:**

```
NAME               CLASS   HOSTS                      ADDRESS         PORTS   AGE
frontend-ingress   nginx   frontend.ecommerce.local   35.223.30.48    80      1m
```

### 3.4 Actualizar CORS en API Gateway Ingress (si es necesario)

Si tienes problemas de CORS, verifica que el API Gateway Ingress tenga:

```yaml
annotations:
  nginx.ingress.kubernetes.io/enable-cors: "true"
  nginx.ingress.kubernetes.io/cors-allow-methods: "GET, POST, PUT, DELETE, OPTIONS"
  nginx.ingress.kubernetes.io/cors-allow-origin: "http://frontend.ecommerce.local"
  nginx.ingress.kubernetes.io/cors-allow-credentials: "false"
  nginx.ingress.kubernetes.io/cors-allow-headers: "DNT,Keep-Alive,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization"
```

---

## Paso 4: Configurar DNS Local

### 4.1 Obtener IP del Ingress Controller

```bash
INGRESS_IP=$(kubectl get ingress -n dev frontend-ingress -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo $INGRESS_IP
```

### 4.2 Agregar entradas a /etc/hosts

**En macOS/Linux:**

```bash
# Agregar frontend
sudo bash -c "echo '$INGRESS_IP    frontend.ecommerce.local' >> /etc/hosts"

# Agregar dominios de monitoreo
sudo bash -c "echo '$INGRESS_IP    grafana.ecommerce.local prometheus.ecommerce.local zipkin.ecommerce.local eureka.ecommerce.local' >> /etc/hosts"

# Verificar
cat /etc/hosts | grep ecommerce
```

**Resultado esperado:**

```
35.223.30.48    frontend.ecommerce.local
35.223.30.48    ecommerce.local
35.223.30.48    grafana.ecommerce.local prometheus.ecommerce.local zipkin.ecommerce.local eureka.ecommerce.local
```

**En Windows:**

```powershell
# Ejecutar PowerShell como Administrador
$INGRESS_IP = "35.223.30.48"  # Reemplazar con tu IP
Add-Content -Path C:\Windows\System32\drivers\etc\hosts -Value "$INGRESS_IP    frontend.ecommerce.local"
Add-Content -Path C:\Windows\System32\drivers\etc\hosts -Value "$INGRESS_IP    grafana.ecommerce.local prometheus.ecommerce.local zipkin.ecommerce.local eureka.ecommerce.local"

# Verificar
Get-Content C:\Windows\System32\drivers\etc\hosts | Select-String "ecommerce"
```

---

## Paso 5: Verificar Funcionamiento

### 5.1 Probar desde línea de comando

```bash
# Probar frontend (HTML)
curl http://frontend.ecommerce.local | head -20

# Probar API a través del proxy (debe devolver JSON)
curl http://frontend.ecommerce.local/api/actuator/health | head -20

# Probar productos
curl http://frontend.ecommerce.local/api/product-service/api/products
```

**Salidas esperadas:**

1. Primera petición: HTML con `<title>E-Commerce Dashboard</title>`
2. Segunda petición: JSON con `"status": "UP"`
3. Tercera petición: JSON con `"collection": [...]`

### 5.2 Probar desde navegador

1. **Abrir navegador** (Chrome, Firefox, Safari)

2. **Acceder a:** `http://frontend.ecommerce.local`

3. **Verificar elementos visibles:**

   ✅ **Header morado degradado** con título "E-Commerce Dashboard"
   
   ✅ **Sección "Estado de Microservicios"** con 8 tarjetas:
   - FAVOURITE-SERVICE ✅ Online (1)
   - PROXY-CLIENT ✅ Online (1)
   - API-GATEWAY ✅ Online (2)
   - PAYMENT-SERVICE ✅ Online (1)
   - ORDER-SERVICE ✅ Online (1)
   - PRODUCT-SERVICE ✅ Online (1)
   - SHIPPING-SERVICE ✅ Online (1)
   - USER-SERVICE ✅ Online (1)
   
   ✅ **Sección "Catálogo de Productos"** con tarjetas de productos:
   - asus ($0.00, Stock: 50)
   - hp ($0.00, Stock: 50)
   - dell, lenovo, toshiba, acer, samsung, macbook, etc.
   
   ✅ **Botones "Agregar al carrito"** funcionales
   
   ✅ **Contador de carrito** en el header (🛒 0)
   
   ✅ **Enlaces a herramientas** funcionando:
   - 📊 Grafana → `http://grafana.ecommerce.local`
   - 📈 Prometheus → `http://prometheus.ecommerce.local:9090`
   - 🔍 Zipkin → `http://zipkin.ecommerce.local`
   - 🌐 Eureka → `http://eureka.ecommerce.local`

4. **Abrir DevTools** (F12 o clic derecho → Inspeccionar)

5. **Ir a pestaña Console**

   ✅ **Sin errores** (excepto favicon 404 que es normal)
   
   ✅ Mensaje: `🚀 Iniciando E-Commerce...`
   
   ✅ Mensaje: `✅ Aplicación cargada`

6. **Ir a pestaña Network**

   ✅ `GET /api/actuator/health` → Status 200
   
   ✅ `GET /api/product-service/api/products` → Status 200

### 5.3 Probar funcionalidad del carrito

1. **Hacer clic en "Agregar al carrito"** en cualquier producto
2. **Verificar que:**
   - Botón cambia a "✅ En carrito"
   - Contador en header incrementa (🛒 1, 🛒 2, etc.)
   - Aparece alerta: "Producto agregado al carrito"

---

## Troubleshooting

### Problema 1: Página en blanco

**Síntomas:**
- Navegador muestra página blanca
- DevTools Console sin errores

**Causa:** ConfigMap vacío o no montado correctamente

**Solución:**

```bash
# Verificar tamaño del ConfigMap
kubectl get configmap frontend-html -n dev -o yaml | grep -A 1 "index.html:"

# Si está vacío, recrear
kubectl delete configmap frontend-html -n dev
kubectl create configmap frontend-html -n dev \
  --from-file=index.html=/ruta/completa/al/frontend/index.html

# Reiniciar pods
kubectl rollout restart deployment frontend -n dev
kubectl rollout status deployment frontend -n dev
```

### Problema 2: Error 404 en /api/*

**Síntomas:**
- Console: `GET http://frontend.ecommerce.local/api/actuator/health 404`
- Servicios no cargan

**Causa:** Ingress rewrite no configurado correctamente

**Solución:**

```bash
# Verificar configuración del Ingress
kubectl get ingress frontend-ingress -n dev -o yaml | grep -A 5 "rewrite"

# Debe tener:
# nginx.ingress.kubernetes.io/rewrite-target: /$2

# Si no está, editar y aplicar
kubectl edit ingress frontend-ingress -n dev
# O
kubectl apply -f k8s/ingress/api-gateway-ingress.yaml

# Verificar que funciona
curl http://frontend.ecommerce.local/api/actuator/health
```

### Problema 3: Error 403 Forbidden

**Síntomas:**
- Console: `GET http://frontend.ecommerce.local/api/product-service/api/products 403`

**Causa:** Problema de CORS entre frontend (HTTP) y API (HTTPS)

**Solución:**

```bash
# Verificar anotaciones CORS en API Gateway Ingress
kubectl get ingress api-gateway-ingress -n dev -o yaml | grep cors

# Debe tener:
# nginx.ingress.kubernetes.io/enable-cors: "true"
# nginx.ingress.kubernetes.io/cors-allow-origin: "http://frontend.ecommerce.local"

# Si no está, agregar y aplicar
kubectl apply -f k8s/ingress/api-gateway-ingress.yaml
```

### Problema 4: "No se pudieron cargar los productos"

**Síntomas:**
- Mensaje de error en la sección de productos
- Console: Error en respuesta JSON

**Causa:** API devuelve `collection` pero código busca `content`

**Solución:**

```bash
# Verificar respuesta de la API
curl http://frontend.ecommerce.local/api/product-service/api/products | grep -o "collection\|content"

# Si devuelve "collection", el código ya lo maneja con:
# const productList = products?.collection || products?.content || [];

# Verificar que el ConfigMap tenga el código actualizado
kubectl get configmap frontend-html -n dev -o yaml | grep -A 2 "collection"

# Si no está actualizado, recrear ConfigMap
kubectl delete configmap frontend-html -n dev
kubectl create configmap frontend-html -n dev --from-file=index.html=/ruta/al/index.html
kubectl rollout restart deployment frontend -n dev
```

### Problema 5: DNS no resuelve

**Síntomas:**
- Navegador: "No se puede acceder al sitio"
- curl: `Could not resolve host`

**Solución:**

```bash
# Verificar /etc/hosts
cat /etc/hosts | grep frontend.ecommerce.local

# Si no está, agregar
INGRESS_IP=$(kubectl get ingress -n dev frontend-ingress -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
sudo bash -c "echo '$INGRESS_IP    frontend.ecommerce.local' >> /etc/hosts"

# Probar resolución
ping -c 2 frontend.ecommerce.local

# Limpiar caché DNS (macOS)
sudo dscacheutil -flushcache
sudo killall -HUP mDNSResponder
```

### Problema 6: Pods no inician

**Síntomas:**
```
kubectl get pods -n dev -l app=frontend
NAME                        READY   STATUS             RESTARTS   AGE
frontend-xxx                0/1     ImagePullBackOff   0          2m
```

**Causa:** Imagen nginx:alpine no se puede descargar

**Solución:**

```bash
# Verificar eventos
kubectl describe pod -n dev -l app=frontend

# Si es problema de red, usar imagen alternativa
kubectl set image deployment/frontend -n dev nginx=nginx:1.25-alpine

# O verificar pull policy
kubectl get deployment frontend -n dev -o yaml | grep imagePullPolicy
```

### Problema 7: ConfigMap demasiado grande

**Síntomas:**
- Error al crear ConfigMap: `Request entity too large`

**Causa:** HTML excede límite de ConfigMap (1MB)

**Solución:**

```bash
# Verificar tamaño
ls -lh frontend/index.html

# Si es > 1MB, optimizar:
# 1. Minificar CSS/JS
# 2. Remover comentarios
# 3. O usar solución alternativa (hostPath volume)

# Alternativa: Crear imagen Docker personalizada
cd frontend
cat > Dockerfile << 'EOF'
FROM nginx:alpine
COPY index.html /usr/share/nginx/html/
EOF

docker build -t tu-registry/ecommerce-frontend:v1 .
docker push tu-registry/ecommerce-frontend:v1

# Actualizar deployment para usar imagen personalizada
kubectl set image deployment/frontend -n dev nginx=tu-registry/ecommerce-frontend:v1
```

---

## Comandos de Mantenimiento

### Actualizar contenido del frontend

```bash
# 1. Editar archivo
nano frontend/index.html

# 2. Eliminar ConfigMap antiguo
kubectl delete configmap frontend-html -n dev

# 3. Crear ConfigMap nuevo
kubectl create configmap frontend-html -n dev \
  --from-file=index.html=/ruta/completa/al/frontend/index.html

# 4. Reiniciar deployment
kubectl rollout restart deployment frontend -n dev

# 5. Verificar rollout
kubectl rollout status deployment frontend -n dev

# 6. Probar en navegador (limpiar caché: Cmd+Shift+R)
```

### Ver logs en tiempo real

```bash
# Logs de todos los pods del frontend
kubectl logs -n dev -l app=frontend -f --tail=100

# Logs de un pod específico
kubectl logs -n dev frontend-xxxxxxxxxx-xxxxx -f

# Logs del Ingress Controller
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller --tail=50
```

### Escalar frontend

```bash
# Aumentar réplicas
kubectl scale deployment frontend -n dev --replicas=3

# Verificar
kubectl get pods -n dev -l app=frontend

# Regresar a 2
kubectl scale deployment frontend -n dev --replicas=2
```

### Probar conectividad interna

```bash
# Port-forward al frontend
kubectl port-forward -n dev svc/frontend 8080:80 &

# Probar
curl http://localhost:8080

# Detener port-forward
killall kubectl

# Port-forward al API Gateway
kubectl port-forward -n dev svc/api-gateway 8081:80 &
curl http://localhost:8081/actuator/health
killall kubectl
```

### Reiniciar completamente el frontend

```bash
# Eliminar todo
kubectl delete deployment frontend -n dev
kubectl delete service frontend -n dev
kubectl delete ingress frontend-ingress -n dev
kubectl delete configmap frontend-html -n dev

# Recrear (en orden)
kubectl create configmap frontend-html -n dev --from-file=index.html=/ruta/al/index.html
kubectl apply -f k8s/deployments/frontend.yaml
kubectl apply -f k8s/services/frontend-service.yaml
kubectl apply -f k8s/ingress/api-gateway-ingress.yaml

# Verificar
kubectl get all -n dev -l app=frontend
```

### Verificar estado completo

```bash
# Script de verificación completo
cat > verify-frontend.sh << 'EOF'
#!/bin/bash
echo "=== FRONTEND VERIFICATION ==="
echo ""

echo "1. ConfigMap:"
kubectl get configmap frontend-html -n dev
echo ""

echo "2. Deployment:"
kubectl get deployment frontend -n dev
echo ""

echo "3. Pods:"
kubectl get pods -n dev -l app=frontend
echo ""

echo "4. Service:"
kubectl get svc frontend -n dev
echo ""

echo "5. Ingress:"
kubectl get ingress frontend-ingress -n dev
echo ""

echo "6. DNS Resolution:"
cat /etc/hosts | grep frontend.ecommerce.local
echo ""

echo "7. HTTP Test:"
curl -I http://frontend.ecommerce.local 2>&1 | head -5
echo ""

echo "8. API Proxy Test:"
curl -I http://frontend.ecommerce.local/api/actuator/health 2>&1 | head -5
echo ""

echo "=== VERIFICATION COMPLETE ==="
EOF

chmod +x verify-frontend.sh
./verify-frontend.sh
```

### Monitorear recursos

```bash
# Uso de CPU/memoria
kubectl top pods -n dev -l app=frontend

# Métricas detalladas
kubectl describe deployment frontend -n dev | grep -A 10 "Limits\|Requests"

# HPA (si está configurado)
kubectl get hpa -n dev frontend
```

---

## Notas Adicionales

### Seguridad

1. **Headers de seguridad** ya configurados en Ingress:
   - `X-Frame-Options: SAMEORIGIN` - Previene clickjacking
   - `X-Content-Type-Options: nosniff` - Previene MIME sniffing

2. **SSL/TLS:** El frontend usa HTTP pero el API Gateway usa HTTPS. El proxy en Ingress maneja la conversión.

3. **CORS:** Configurado para permitir solo `http://frontend.ecommerce.local`

### Performance

1. **nginx:alpine** - Imagen ligera (~23MB)
2. **ConfigMap** - Evita rebuild de imagen para cambios en HTML
3. **2 réplicas** - Alta disponibilidad y balanceo de carga
4. **Resource limits** - 64Mi memoria, 100m CPU por pod

### Escalabilidad

```bash
# Auto-scaling (opcional)
kubectl autoscale deployment frontend -n dev --cpu-percent=50 --min=2 --max=10

# Verificar HPA
kubectl get hpa -n dev
```

### Backup

```bash
# Backup del ConfigMap
kubectl get configmap frontend-html -n dev -o yaml > backup-frontend-configmap.yaml

# Backup del Deployment
kubectl get deployment frontend -n dev -o yaml > backup-frontend-deployment.yaml

# Backup del Service
kubectl get svc frontend -n dev -o yaml > backup-frontend-service.yaml

# Backup del Ingress
kubectl get ingress frontend-ingress -n dev -o yaml > backup-frontend-ingress.yaml
```

### Restore

```bash
# Restaurar todo desde backups
kubectl apply -f backup-frontend-configmap.yaml
kubectl apply -f backup-frontend-deployment.yaml
kubectl apply -f backup-frontend-service.yaml
kubectl apply -f backup-frontend-ingress.yaml
```

---

## Recursos Útiles

- **Documentación de Nginx Ingress:** https://kubernetes.github.io/ingress-nginx/
- **ConfigMaps en Kubernetes:** https://kubernetes.io/docs/concepts/configuration/configmap/
- **Debugging Ingress:** `kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller`

---

## Conclusión

Este frontend proporciona una interfaz web moderna para el sistema de e-commerce, permitiendo:

✅ Visualización en tiempo real del estado de microservicios
✅ Navegación de catálogo de productos
✅ Funcionalidad de carrito de compras
✅ Acceso rápido a herramientas de monitoreo

**URL de acceso:** `http://frontend.ecommerce.local`

**Mantenimiento:** Actualizar el ConfigMap y hacer rollout restart del deployment.

---

*Última actualización: 25 de noviembre de 2025*
