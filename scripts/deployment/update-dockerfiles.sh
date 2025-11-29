#!/bin/bash
# Script para actualizar todos los Dockerfiles

SERVICES=(
  "service-discovery"
  "cloud-config"
  "api-gateway"
  "proxy-client"
  "user-service"
  "product-service"
  "order-service"
  "payment-service"
  "shipping-service"
  "favourite-service"
)

for SERVICE in "${SERVICES[@]}"; do
  echo "Actualizando Dockerfile de $SERVICE..."
  
  cat > "$SERVICE/Dockerfile" <<EOF
FROM eclipse-temurin:11-jre-alpine

LABEL maintainer="ecommerce-project"

WORKDIR /app

ARG JAR_FILE=$SERVICE/target/*.jar
COPY \${JAR_FILE} app.jar

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "app.jar"]
EOF

done

echo "✅ Todos los Dockerfiles actualizados"