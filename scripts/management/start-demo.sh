#!/bin/bash

# Script de Demo - E-Commerce Microservices
# Abre todas las interfaces necesarias para la demostración

echo "🚀 Iniciando Demo del E-Commerce..."
echo "===================================="

# Colores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Verificar /etc/hosts
echo -e "\n${BLUE}1️⃣ Verificando configuración de /etc/hosts...${NC}"

if grep -q "frontend.ecommerce.local" /etc/hosts; then
    echo -e "${GREEN}✅ /etc/hosts ya configurado${NC}"
else
    echo -e "${YELLOW}⚠️  Necesitas agregar al /etc/hosts:${NC}"
    echo -e "   ${YELLOW}35.223.30.48    frontend.ecommerce.local${NC}"
    echo -e "   ${YELLOW}35.223.30.48    grafana.ecommerce.local${NC}"
    echo -e "   ${YELLOW}35.223.30.48    zipkin.ecommerce.local${NC}"
    echo -e "   ${YELLOW}35.223.30.48    eureka.ecommerce.local${NC}"
    echo ""
    read -p "¿Quieres que lo agregue automáticamente? (s/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        cat << EOF | sudo tee -a /etc/hosts
35.223.30.48    frontend.ecommerce.local
35.223.30.48    grafana.ecommerce.local
35.223.30.48    zipkin.ecommerce.local
35.223.30.48    eureka.ecommerce.local
35.223.30.48    prometheus.ecommerce.local
35.223.30.48    alertmanager.ecommerce.local
EOF
        echo -e "${GREEN}✅ /etc/hosts actualizado${NC}"
    fi
fi

# Verificar que los servicios estén corriendo
echo -e "\n${BLUE}2️⃣ Verificando estado de servicios...${NC}"

kubectl get pods -n dev | grep -E "(frontend|product|user|order|payment|shipping|favourite)" | grep Running > /dev/null
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Servicios corriendo${NC}"
    kubectl get pods -n dev | grep -E "(frontend|product|user|order|payment|shipping|favourite)" | grep Running | wc -l | xargs echo "   Pods activos:"
else
    echo -e "${YELLOW}⚠️  Algunos servicios pueden no estar listos${NC}"
fi

# Verificar Ingress
echo -e "\n${BLUE}3️⃣ Verificando Ingress Controller...${NC}"
kubectl get ingress -n dev frontend-ingress -o jsonpath='{.status.loadBalancer.ingress[0].ip}' > /dev/null 2>&1
if [ $? -eq 0 ]; then
    IP=$(kubectl get ingress -n dev frontend-ingress -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    echo -e "${GREEN}✅ Ingress activo en IP: $IP${NC}"
else
    echo -e "${YELLOW}⚠️  Ingress no tiene IP asignada aún${NC}"
fi

# Abrir el frontend
echo -e "\n${BLUE}4️⃣ Abriendo Frontend E-Commerce...${NC}"
sleep 2
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    open http://frontend.ecommerce.local
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux
    xdg-open http://frontend.ecommerce.local
else
    echo "Abre manualmente: http://frontend.ecommerce.local"
fi
echo -e "${GREEN}✅ Frontend abierto en el navegador${NC}"

# Abrir Grafana
echo -e "\n${BLUE}5️⃣ Abriendo Grafana...${NC}"
sleep 2
if [[ "$OSTYPE" == "darwin"* ]]; then
    open https://grafana.ecommerce.local
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    xdg-open https://grafana.ecommerce.local
fi
echo -e "${GREEN}✅ Grafana abierto (usuario: admin, password: admin123)${NC}"

# Abrir Zipkin
echo -e "\n${BLUE}6️⃣ Abriendo Zipkin...${NC}"
sleep 2
if [[ "$OSTYPE" == "darwin"* ]]; then
    open http://zipkin.ecommerce.local
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    xdg-open http://zipkin.ecommerce.local
fi
echo -e "${GREEN}✅ Zipkin abierto${NC}"

# Abrir Eureka
echo -e "\n${BLUE}7️⃣ Abriendo Eureka Service Discovery...${NC}"
sleep 2
if [[ "$OSTYPE" == "darwin"* ]]; then
    open http://eureka.ecommerce.local
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    xdg-open http://eureka.ecommerce.local
fi
echo -e "${GREEN}✅ Eureka abierto${NC}"

# Generar tráfico de prueba
echo -e "\n${BLUE}8️⃣ Generando tráfico de prueba...${NC}"
for i in {1..20}; do
    curl -s http://frontend.ecommerce.local > /dev/null 2>&1
    echo -n "."
done
echo ""
echo -e "${GREEN}✅ Tráfico generado - revisa Zipkin para ver las trazas${NC}"

# Mostrar información de HPA
echo -e "\n${BLUE}9️⃣ Estado de Auto-Scaling (HPA):${NC}"
kubectl get hpa -n dev 2>/dev/null
if [ $? -ne 0 ]; then
    echo -e "${YELLOW}⚠️  No hay HPAs configurados${NC}"
fi

# Mostrar resumen
echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}🎉 DEMO INICIADA CORRECTAMENTE${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${BLUE}📱 URLs Abiertas en tu Navegador:${NC}"
echo -e "   🛒 Frontend:    http://frontend.ecommerce.local"
echo -e "   📊 Grafana:     https://grafana.ecommerce.local"
echo -e "   🔍 Zipkin:      http://zipkin.ecommerce.local"
echo -e "   🌐 Eureka:      http://eureka.ecommerce.local"
echo ""
echo -e "${BLUE}🔌 URLs Adicionales:${NC}"
echo -e "   📈 Prometheus:  http://prometheus.ecommerce.local"
echo -e "   🚨 AlertMgr:    http://alertmanager.ecommerce.local"
echo ""
echo -e "${BLUE}💡 Comandos Útiles:${NC}"
echo -e "   Ver pods:       ${YELLOW}kubectl get pods -n dev${NC}"
echo -e "   Ver HPAs:       ${YELLOW}kubectl get hpa -n dev${NC}"
echo -e "   Ver Ingress:    ${YELLOW}kubectl get ingress -A${NC}"
echo -e "   Logs frontend:  ${YELLOW}kubectl logs -n dev -l app=frontend${NC}"
echo ""
echo -e "${BLUE}🎬 Pasos para la Demo:${NC}"
echo -e "   1. Muestra el frontend y navega productos"
echo -e "   2. Agrega productos al carrito"
echo -e "   3. Ve a Zipkin y muestra las trazas"
echo -e "   4. Ve a Grafana y muestra el dashboard"
echo -e "   5. Ejecuta: ${YELLOW}kubectl get pods -n dev -w${NC} para ver pods en vivo"
echo ""
echo -e "${GREEN}✨ ¡Buena suerte con tu presentación!${NC}"
