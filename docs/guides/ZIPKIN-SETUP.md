# Configuración de Zipkin para Trazas Distribuidas

## 🔍 Problema Actual

**Zipkin está desplegado y corriendo**, pero **NO está recibiendo trazas** de los microservicios porque les falta la configuración necesaria.

## ✅ Solución: Habilitar Spring Cloud Sleuth + Zipkin

### Paso 1: Agregar Dependencia Maven

Agrega esta dependencia en el `pom.xml` de **CADA microservicio**:

```xml
<!-- Después de spring-cloud-starter-netflix-eureka-client -->
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-sleuth</artifactId>
</dependency>
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-sleuth-zipkin</artifactId>
</dependency>
```

**Servicios a actualizar:**
- ✅ user-service/pom.xml
- ✅ product-service/pom.xml
- ✅ order-service/pom.xml
- ✅ payment-service/pom.xml
- ✅ shipping-service/pom.xml
- ✅ favourite-service/pom.xml
- ✅ proxy-client/pom.xml
- ✅ api-gateway/pom.xml

### Paso 2: Configurar Zipkin en application-dev.yml

Agrega esta configuración en `src/main/resources/application-dev.yml` de **CADA servicio**:

```yaml
spring:
  zipkin:
    base-url: http://zipkin:9411  # URL del servicio Zipkin en Kubernetes
    enabled: true
  sleuth:
    sampler:
      probability: 1.0  # 1.0 = 100% de trazas (para desarrollo)
```

**⚠️ IMPORTANTE:** En producción, usa `probability: 0.1` (10% de trazas) para no sobrecargar Zipkin.

### Paso 3: Actualizar ConfigMaps (Alternativa)

Si no quieres modificar los archivos de configuración, puedes agregar la URL de Zipkin en los ConfigMaps:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: user-service-config
  namespace: dev
data:
  SPRING_PROFILES_ACTIVE: "dev"
  EUREKA_CLIENT_SERVICEURL_DEFAULTZONE: "http://service-discovery:8761/eureka/"
  SPRING_CONFIG_IMPORT: "optional:configserver:http://cloud-config:9296"
  SPRING_ZIPKIN_BASE_URL: "http://zipkin:9411"  # ← AGREGAR ESTA LÍNEA
  SPRING_SLEUTH_SAMPLER_PROBABILITY: "1.0"       # ← AGREGAR ESTA LÍNEA
```

**Servicios a actualizar:**
- k8s/configmaps/user-service-config.yaml
- k8s/configmaps/product-service-config.yaml
- k8s/configmaps/order-service-config.yaml
- k8s/configmaps/payment-service-config.yaml
- k8s/configmaps/shipping-service-config.yaml
- k8s/configmaps/favourite-service-config.yaml
- k8s/configmaps/proxy-client-config.yaml
- k8s/configmaps/api-gateway-config.yaml

### Paso 4: Reconstruir Imágenes Docker

Después de agregar las dependencias Maven, **debes reconstruir TODAS las imágenes**:

```bash
# Reconstruir cada servicio
gcloud builds submit --config=cloudbuild-user-service.yaml .
gcloud builds submit --config=cloudbuild-product-service.yaml .
gcloud builds submit --config=cloudbuild-order-service.yaml .
gcloud builds submit --config=cloudbuild-payment-service.yaml .
gcloud builds submit --config=cloudbuild-shipping-service.yaml .
gcloud builds submit --config=cloudbuild-favourite-service.yaml .
gcloud builds submit --config=cloudbuild-proxy-client.yaml .
gcloud builds submit --config=cloudbuild-api-gateway.yaml .
```

**⏱️ Tiempo estimado:** ~20-25 minutos (todos los builds)

### Paso 5: Redesplegar Servicios

Si usaste ConfigMaps (Paso 3):

```bash
# Aplicar ConfigMaps actualizados
kubectl apply -f k8s/configmaps/

# Reiniciar deployments para que carguen la nueva configuración
kubectl rollout restart deployment -n dev user-service
kubectl rollout restart deployment -n dev product-service
kubectl rollout restart deployment -n dev order-service
kubectl rollout restart deployment -n dev payment-service
kubectl rollout restart deployment -n dev shipping-service
kubectl rollout restart deployment -n dev favourite-service
kubectl rollout restart deployment -n dev proxy-client
kubectl rollout restart deployment -n dev api-gateway

# Esperar a que los pods estén listos
kubectl rollout status deployment -n dev user-service
kubectl rollout status deployment -n dev product-service
# ... etc
```

## 🧪 Probar Zipkin

### 1. Activar Port-Forwards

```bash
# Terminal 1: Zipkin
kubectl port-forward -n dev svc/zipkin 9411:9411

# Terminal 2: API Gateway
kubectl port-forward -n dev svc/api-gateway 8080:80

# Terminal 3: Eureka (opcional)
kubectl port-forward -n dev svc/service-discovery 8761:8761
```

### 2. Generar Tráfico

```bash
# Ejecutar el script de test
chmod +x test.sh
./test.sh
```

O manualmente:

```bash
# Múltiples peticiones para generar trazas
for i in {1..30}; do
  echo "═══ Petición $i ═══"
  curl -s http://localhost:8080/user-service/actuator/health
  curl -s http://localhost:8080/product-service/actuator/health
  curl -s http://localhost:8080/order-service/actuator/health
  curl -s http://localhost:8080/payment-service/actuator/health
  curl -s http://localhost:8080/shipping-service/actuator/health
  curl -s http://localhost:8080/favourite-service/actuator/health
  curl -s http://localhost:8080/app/actuator/health
  echo "✅ Petición $i completada"
  sleep 2
done
```

### 3. Ver Trazas en Zipkin

1. Abre http://localhost:9411 en tu navegador
2. Haz clic en **"RUN QUERY"** o **"🔍 Find Traces"**
3. Deberías ver las trazas de tus peticiones
4. Haz clic en cualquier traza para ver:
   - Servicios involucrados
   - Tiempo de cada llamada
   - Latencia total
   - Errores (si los hay)

### 4. Ver Grafo de Dependencias

1. En Zipkin, ve a la pestaña **"Dependencies"**
2. Selecciona el rango de tiempo
3. Verás el **grafo visual** de dependencias entre microservicios

## ⚙️ Opciones de Configuración Avanzada

### Configurar Sampling (Muestreo)

```yaml
spring:
  sleuth:
    sampler:
      probability: 0.1  # 10% de peticiones rastreadas
```

### Excluir Endpoints del Rastreo

```yaml
spring:
  sleuth:
    web:
      skipPattern: /actuator.*|/health.*
```

### Configurar Nombre del Servicio

```yaml
spring:
  application:
    name: USER-SERVICE  # Nombre que aparecerá en Zipkin
```

## 🚨 Troubleshooting

### "No traces found" en Zipkin

**Causa:** Los servicios no están enviando trazas.

**Solución:**
1. Verifica los logs de los servicios: `kubectl logs -n dev <pod-name>`
2. Busca errores relacionados con Zipkin
3. Verifica que las dependencias Maven estén correctas
4. Confirma que la URL de Zipkin es correcta: `http://zipkin:9411`

### Pods en CrashLoopBackOff después del redeploy

**Causa:** Insuficiente CPU en el clúster.

**Solución:**
```bash
# Ver pods Pending
kubectl get pods -n dev

# Escalar clúster (ya está en max=8)
# Opción 1: Esperar al rolling update gradual
kubectl get pods -n dev -w

# Opción 2: Aumentar máximo de nodos
gcloud container clusters update ecommerce-cluster \
    --zone=us-central1-a \
    --max-nodes=10
```

### Warning en logs: "Connection refused to localhost:9411"

**Causa:** Configuración antigua apuntando a localhost.

**Solución:** Asegúrate de que la URL sea `http://zipkin:9411` (no localhost).

## 📊 Métricas Importantes en Zipkin

- **Trace ID:** Identificador único de cada petición
- **Span ID:** Identificador de cada operación dentro de una traza
- **Duration:** Tiempo total de la petición
- **Service Name:** Nombre del microservicio
- **Annotations:** Eventos específicos (cs, sr, ss, cr)

## 💡 Recomendaciones

1. **Desarrollo:** `probability: 1.0` (100% trazas)
2. **Producción:** `probability: 0.1` (10% trazas) o menos
3. **Alta carga:** `probability: 0.01` (1% trazas)
4. Monitorear el uso de recursos de Zipkin
5. Considerar almacenamiento persistente para Zipkin (Elasticsearch, MySQL)

---

**Última actualización:** 24 de noviembre de 2025  
**Estado:** ✅ Zipkin desplegado, pendiente configuración de servicios
