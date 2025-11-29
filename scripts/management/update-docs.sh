#!/bin/bash

# Script para actualizar y verificar toda la documentación del proyecto
echo "📚 ACTUALIZANDO DOCUMENTACIÓN DEL PROYECTO"
echo "=========================================="

# Variables
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DOCS_DIR="$PROJECT_ROOT/docs"
DATE=$(date "+%d de %B de %Y")

echo "📁 Directorio del proyecto: $PROJECT_ROOT"
echo "📄 Directorio de docs: $DOCS_DIR"
echo "📅 Fecha: $DATE"
echo ""

# Función para actualizar referencias en archivos
update_file_references() {
    local file="$1"
    local description="$2"
    
    if [ -f "$file" ]; then
        echo "📝 Actualizando $description..."
        
        # Actualizar fecha en archivos
        sed -i '' "s/Fecha: .*/Fecha: $DATE/g" "$file" 2>/dev/null || true
        sed -i '' "s/Última actualización: .*/Última actualización: $DATE/g" "$file" 2>/dev/null || true
        
        # Actualizar referencias al repositorio
        sed -i '' 's|github.com/SelimHorri/ecommerce-microservice-backend-app|github.com/felipevelasco7/ecommerce-microservice-backend-app|g' "$file" 2>/dev/null || true
        
        echo "   ✅ $description actualizado"
    else
        echo "   ⚠️ $file no encontrado"
    fi
}

# Función para crear índice de documentación
create_docs_index() {
    cat > "$DOCS_DIR/README.md" <<EOF
# 📚 Documentación del Proyecto E-Commerce Microservices

Última actualización: $DATE

## 📖 Documentos Principales

### 🚀 Guías de Despliegue
- **[Guía de Despliegue Completa](./GUIA-DESPLIEGUE-COMPLETO.md)** - Guía paso a paso para recrear el proyecto desde cero
- **[Guía de Despliegue Detallada](./guides/DEPLOYMENT-GUIDE.md)** - Documentación técnica detallada del proceso de despliegue

### 📋 Documentación Técnica
- **[Documentación Completa del Proyecto](./DOCUMENTACION-PROYECTO-FINAL.md)** - Documentación técnica completa y arquitectura

### 🔧 Guías Operacionales
- **[Manual de Operaciones](./operations/MANUAL-OPERACIONES.md)** - Manual para operaciones diarias del sistema
- **[Pausa y Reanudación del Cluster](./operations/PAUSA-REANUDACION-CLUSTER.md)** - Guía para pausar/reanudar el cluster GKE

### 📊 Guías Específicas
- **[URLs de Acceso](./guides/URLS.md)** - Cómo obtener y configurar URLs de acceso
- **[Guía de Testing](./guides/TESTING-GUIDE.md)** - Procedimientos de testing y validación
- **[Guía de Backup y Restauración](./guides/BACKUP-RESTORE-GUIDE.md)** - Procedimientos de backup
- **[Guía de Acceso por Ingress](./guides/INGRESS-ACCESS-GUIDE.md)** - Configuración de ingress
- **[Capturas de Verificación](./guides/CAPTURAS-VERIFICACION.md)** - Evidencias visuales del proyecto

### 🏗️ Arquitectura
- **[Diagramas de Arquitectura](./architecture/ARCHITECTURE-DIAGRAMS.md)** - Diagramas y diseño del sistema

## 🎯 Orden de Lectura Recomendado

Para **desplegar el proyecto desde cero**:
1. Leer el [README principal](../README.md) para entender el proyecto
2. Seguir la [Guía de Despliegue Completa](./GUIA-DESPLIEGUE-COMPLETO.md) paso a paso
3. Usar el [Manual de Operaciones](./operations/MANUAL-OPERACIONES.md) para operaciones diarias
4. Consultar [URLs de Acceso](./guides/URLS.md) para conectarse a los servicios

Para **entender la arquitectura**:
1. [Documentación Completa del Proyecto](./DOCUMENTACION-PROYECTO-FINAL.md)
2. [Diagramas de Arquitectura](./architecture/ARCHITECTURE-DIAGRAMS.md)
3. [Guía de Despliegue Detallada](./guides/DEPLOYMENT-GUIDE.md)

## 🛠️ Scripts de Automatización

Los scripts mencionados en las guías se encuentran en:
- \`scripts/deployment/\` - Scripts de despliegue
- \`scripts/management/\` - Scripts de gestión
- \`scripts/testing/\` - Scripts de testing

## 📞 Soporte

Para dudas o problemas:
1. Consulta la sección de troubleshooting en las guías
2. Revisa los logs con los comandos proporcionados
3. Contacta al equipo de desarrollo

---

**Proyecto:** E-Commerce Microservices Platform  
**Universidad:** Icesi - Cali, Colombia  
**Curso:** Plataformas Computacionales 2  
**Desarrollador:** Felipe Velasco  
**Repositorio:** https://github.com/felipevelasco7/ecommerce-microservice-backend-app
EOF

    echo "📚 Índice de documentación creado: $DOCS_DIR/README.md"
}

# Función para verificar la consistencia de la documentación
verify_docs_consistency() {
    echo ""
    echo "🔍 VERIFICANDO CONSISTENCIA DE LA DOCUMENTACIÓN"
    echo "==============================================="
    
    local issues=0
    
    # Verificar que existan los archivos principales
    local required_files=(
        "$DOCS_DIR/README.md"
        "$DOCS_DIR/GUIA-DESPLIEGUE-COMPLETO.md"
        "$DOCS_DIR/DOCUMENTACION-PROYECTO-FINAL.md"
        "$DOCS_DIR/operations/MANUAL-OPERACIONES.md"
        "$DOCS_DIR/guides/URLS.md"
        "$DOCS_DIR/guides/TESTING-GUIDE.md"
    )
    
    for file in "${required_files[@]}"; do
        if [ -f "$file" ]; then
            echo "✅ $(basename "$file")"
        else
            echo "❌ $(basename "$file") - NO ENCONTRADO"
            ((issues++))
        fi
    done
    
    echo ""
    echo "📊 Resumen de verificación:"
    echo "   Archivos verificados: ${#required_files[@]}"
    echo "   Problemas encontrados: $issues"
    
    if [ $issues -eq 0 ]; then
        echo "   🎉 Toda la documentación está consistente"
    else
        echo "   ⚠️ Se encontraron $issues problemas"
    fi
}

# Función principal
main() {
    cd "$PROJECT_ROOT"
    
    # Actualizar archivos principales
    update_file_references "$DOCS_DIR/README.md" "Índice de documentación"
    update_file_references "$DOCS_DIR/GUIA-DESPLIEGUE-COMPLETO.md" "Guía de despliegue completa"
    update_file_references "$DOCS_DIR/DOCUMENTACION-PROYECTO-FINAL.md" "Documentación técnica"
    update_file_references "$DOCS_DIR/operations/MANUAL-OPERACIONES.md" "Manual de operaciones"
    update_file_references "$DOCS_DIR/guides/URLS.md" "Guía de URLs"
    update_file_references "$DOCS_DIR/guides/DEPLOYMENT-GUIDE.md" "Guía de despliegue detallada"
    update_file_references "$PROJECT_ROOT/README.md" "README principal"
    
    # Crear índice de documentación
    create_docs_index
    
    # Verificar consistencia
    verify_docs_consistency
    
    echo ""
    echo "📝 DOCUMENTACIÓN ACTUALIZADA EXITOSAMENTE"
    echo "========================================"
    echo ""
    echo "📋 Próximos pasos:"
    echo "1. Revisa el índice: cat docs/README.md"
    echo "2. Verifica los enlaces: docs/README.md"
    echo "3. Confirma que toda la información esté actualizada"
    echo ""
    echo "🔗 Archivos principales actualizados:"
    echo "   📖 README.md (principal)"
    echo "   🚀 docs/GUIA-DESPLIEGUE-COMPLETO.md"
    echo "   📋 docs/DOCUMENTACION-PROYECTO-FINAL.md"
    echo "   🔧 docs/operations/MANUAL-OPERACIONES.md"
    echo "   📚 docs/README.md (índice)"
}

# Ejecutar
main