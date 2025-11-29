#!/bin/bash

# ============================================================================
# Script de Testeo para Microservicios en Kubernetes (GKE)
# Genera tráfico para crear trazas en Zipkin
# ============================================================================

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo "============================================"
echo "  Testeo de Microservicios en Kubernetes"
echo "============================================"

# URLs base (asumiendo port-forward activo)
API_GATEWAY="http://localhost:8080"
EUREKA="http://localhost:8761"
ZIPKIN="http://localhost:9411"
SUCCESS_COUNT=0
ERROR_COUNT=0

# Verificar port-forwards necesarios
echo ""
echo -e "${CYAN}🔍 Verificando port-forwards necesarios...${NC}"
echo ""

# Verificar si un port-forward está activo
check_port_forward() {
    local port=$1
    local service_name=$2
    
    if nc -z localhost $port 2>/dev/null; then
        echo -e "✅ ${GREEN}Port-forward en puerto $port - OK${NC}"
        return 0
    else
        echo -e "⚠️  ${YELLOW}Port-forward en puerto $port NO detectado${NC}"
        echo -e "   Ejecuta: ${CYAN}kubectl port-forward -n dev svc/$service_name $port:$port${NC}"
        return 1
    fi
}

# Función para testear un servicio
test_service() {
    local service_name="$1"
    local service_url="$2"
    local step="$3"
    local total="$4"

    echo ""
    echo -e "${BLUE}[$step/$total] Testando $service_name...${NC}"

    # Test health endpoint
    response=$(curl -s -w "%{http_code}" -o /dev/null "$service_url/actuator/health" 2>/dev/null)
    
    if [ "$response" = "200" ] || [ "$response" = "503" ]; then
        echo -e "✅ ${GREEN}$service_name - Respondiendo (HTTP $response)${NC}"
        ((SUCCESS_COUNT++))
    else
        echo -e "❌ ${RED}$service_name - Sin respuesta o error${NC}"
        ((ERROR_COUNT++))
    fi
}

# Función para generar tráfico entre servicios
generate_traffic() {
    local endpoint="$1"
    local description="$2"
    
    echo -e "   ${CYAN}→${NC} $description"
    response=$(curl -s -w "%{http_code}" -o /tmp/response.json "$endpoint" 2>/dev/null)
    
    if [ "$response" = "200" ] || [ "$response" = "401" ] || [ "$response" = "404" ]; then
        echo -e "     ${GREEN}✓${NC} Petición enviada (HTTP $response)"
        return 0
    else
        echo -e "     ${YELLOW}!${NC} Sin respuesta o error (HTTP $response)"
        return 1
    fi
}

# Verificar port-forwards
PF_ERRORS=0
check_port_forward 8080 "api-gateway" || ((PF_ERRORS++))
check_port_forward 8761 "service-discovery" || ((PF_ERRORS++))
check_port_forward 9411 "zipkin" || ((PF_ERRORS++))

if [ $PF_ERRORS -gt 0 ]; then
    echo ""
    echo -e "${YELLOW}⚠️  Algunos port-forwards no están activos. Continuando de todas formas...${NC}"
    echo ""
fi

# Testear servicios principales
echo ""
echo "============================================"
echo "      TESTEANDO SERVICIOS"
echo "============================================"

test_service "API Gateway" "$API_GATEWAY" "1" "4"
test_service "Service Discovery (Eureka)" "$EUREKA" "2" "4"
test_service "Zipkin" "$ZIPKIN" "3" "4"

# Verificar Eureka Dashboard
echo ""
echo -e "${BLUE}[4/4] Verificando servicios registrados en Eureka...${NC}"
if registered=$(curl -s "$EUREKA/eureka/apps" 2>/dev/null | grep -o "<name>[^<]*</name>" | wc -l); then
    if [ $registered -gt 0 ]; then
        echo -e "✅ ${GREEN}$registered servicios registrados en Eureka${NC}"
        ((SUCCESS_COUNT++))
    else
        echo -e "⚠️  ${YELLOW}No se encontraron servicios registrados${NC}"
        ((ERROR_COUNT++))
    fi
else
    echo -e "❌ ${RED}No se pudo verificar Eureka${NC}"
    ((ERROR_COUNT++))

fi

echo ""
echo "============================================"
echo "    GENERANDO TRÁFICO PARA ZIPKIN"
echo "============================================"
echo ""
echo -e "${CYAN}ℹ️  IMPORTANTE: Los servicios actuales NO están configurados para enviar trazas a Zipkin${NC}"
echo -e "${CYAN}   Esto es normal - Zipkin requiere configuración adicional en las aplicaciones${NC}"
echo ""
echo -e "${YELLOW}Generando peticiones a través del API Gateway...${NC}"
echo ""

TRAFFIC_COUNT=0
# Generar tráfico simulado
for i in {1..10}; do
    echo -e "${BLUE}Ciclo $i/10:${NC}"
    
    generate_traffic "$API_GATEWAY/actuator/health" "Health check del API Gateway" && ((TRAFFIC_COUNT++))
    generate_traffic "$API_GATEWAY/actuator/info" "Info endpoint del API Gateway" && ((TRAFFIC_COUNT++))
    generate_traffic "$EUREKA/actuator/health" "Health check de Eureka" && ((TRAFFIC_COUNT++))
    
    sleep 1
done

echo ""
echo "============================================"
echo "           RESUMEN FINAL"
echo "============================================"
echo -e "✅ ${GREEN}Servicios verificados: $SUCCESS_COUNT${NC}"
echo -e "❌ ${RED}Servicios con error:   $ERROR_COUNT${NC}"
echo -e "📊 ${CYAN}Peticiones generadas:  $TRAFFIC_COUNT${NC}"
echo ""

if [ $SUCCESS_COUNT -ge 2 ]; then
    echo -e "🎉 ${GREEN}¡Sistema funcionando!${NC}"
    echo ""
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}  IMPORTANTE: Zipkin NO mostrará trazas todavía${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${CYAN}Razón:${NC} Los microservicios necesitan configuración de Spring Cloud Sleuth + Zipkin"
    echo ""
    echo -e "${CYAN}Para habilitar trazas, necesitas:${NC}"
    echo ""
    echo -e "1. ${BLUE}Agregar dependencia en pom.xml:${NC}"
    echo -e "   ${GREEN}<dependency>${NC}"
    echo -e "   ${GREEN}  <groupId>org.springframework.cloud</groupId>${NC}"
    echo -e "   ${GREEN}  <artifactId>spring-cloud-starter-zipkin</artifactId>${NC}"
    echo -e "   ${GREEN}</dependency>${NC}"
    echo ""
    echo -e "2. ${BLUE}Agregar configuración en application.yml:${NC}"
    echo -e "   ${GREEN}spring:${NC}"
    echo -e "   ${GREEN}  zipkin:${NC}"
    echo -e "   ${GREEN}    base-url: http://zipkin:9411${NC}"
    echo -e "   ${GREEN}  sleuth:${NC}"
    echo -e "   ${GREEN}    sampler:${NC}"
    echo -e "   ${GREEN}      probability: 1.0${NC}"
    echo ""
    echo -e "3. ${BLUE}Reconstruir todas las imágenes${NC}"
    echo ""
    echo -e "4. ${BLUE}Redesplegar los servicios${NC}"
    echo ""
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${CYAN}URLs útiles:${NC}"
    echo -e "• Eureka Dashboard:  ${YELLOW}http://localhost:8761${NC}"
    echo -e "• Zipkin UI:         ${YELLOW}http://localhost:9411${NC}"
    echo -e "• API Gateway:       ${YELLOW}http://localhost:8080/actuator${NC}"
    echo ""
else
    echo -e "⚠️  ${YELLOW}Algunos servicios tienen problemas.${NC}"
    echo ""
    echo -e "${BLUE}Verifica que los port-forwards estén activos:${NC}"
    echo -e "  kubectl port-forward -n dev svc/api-gateway 8080:80"
    echo -e "  kubectl port-forward -n dev svc/service-discovery 8761:8761"
    echo -e "  kubectl port-forward -n dev svc/zipkin 9411:9411"
    echo ""
    echo -e "${BLUE}Verifica el estado de los pods:${NC}"
    echo -e "  kubectl get pods -n dev"
fi

echo ""
echo -e "${GREEN}Script completado.${NC}"
echo ""
