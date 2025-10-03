#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Video Publishing Pipeline - Setup${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if .env exists
if [ ! -f .env ]; then
    echo -e "${YELLOW}⚠️  No se encontró archivo .env${NC}"
    echo -e "Creando desde .env.example..."
    cp .env.example .env
    echo -e "${GREEN}✓ Archivo .env creado${NC}"
    echo -e "${RED}❗ IMPORTANTE: Edita el archivo .env con tus credenciales antes de continuar${NC}"
    echo ""
    read -p "Presiona Enter después de configurar el archivo .env..."
fi

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}❌ Docker no está corriendo${NC}"
    echo -e "Por favor inicia Docker Desktop e intenta de nuevo."
    exit 1
fi

echo -e "${GREEN}✓ Docker está corriendo${NC}"
echo ""

# Check Docker Compose version
if docker compose version > /dev/null 2>&1; then
    DOCKER_COMPOSE="docker compose"
else
    DOCKER_COMPOSE="docker-compose"
fi

echo -e "${BLUE}Verificando estructura de directorios...${NC}"
mkdir -p output temp

# Check for intro/outro files
if [ ! -f "templates/intro.mp4" ]; then
    echo -e "${YELLOW}⚠️  No se encontró templates/intro.mp4${NC}"
    echo -e "   El procesamiento continuará sin intro"
fi

if [ ! -f "templates/outro.mp4" ]; then
    echo -e "${YELLOW}⚠️  No se encontró templates/outro.mp4${NC}"
    echo -e "   El procesamiento continuará sin outro"
fi

echo ""
echo -e "${BLUE}¿Qué deseas hacer?${NC}"
echo "1) Iniciar todos los servicios"
echo "2) Construir imágenes y luego iniciar"
echo "3) Ver logs en tiempo real"
echo "4) Detener todos los servicios"
echo "5) Limpiar todo y reiniciar"
echo "6) Ver estado de servicios"
echo "7) Salir"
echo ""
read -p "Selecciona una opción (1-7): " option

case $option in
    1)
        echo -e "${BLUE}Iniciando servicios...${NC}"
        $DOCKER_COMPOSE up -d
        echo -e "${GREEN}✓ Servicios iniciados${NC}"
        echo ""
        echo -e "${BLUE}Accede a n8n en: ${NC}http://localhost:5678"
        echo -e "${BLUE}Usuario: ${NC}$(grep N8N_USER .env | cut -d '=' -f2)"
        echo ""
        echo -e "Ver logs: ${YELLOW}$DOCKER_COMPOSE logs -f${NC}"
        ;;
    2)
        echo -e "${BLUE}Construyendo imágenes...${NC}"
        $DOCKER_COMPOSE build --no-cache
        echo -e "${GREEN}✓ Imágenes construidas${NC}"
        echo ""
        echo -e "${BLUE}Iniciando servicios...${NC}"
        $DOCKER_COMPOSE up -d
        echo -e "${GREEN}✓ Servicios iniciados${NC}"
        echo ""
        echo -e "${BLUE}Accede a n8n en: ${NC}http://localhost:5678"
        ;;
    3)
        echo -e "${BLUE}Mostrando logs (Ctrl+C para salir)...${NC}"
        $DOCKER_COMPOSE logs -f
        ;;
    4)
        echo -e "${BLUE}Deteniendo servicios...${NC}"
        $DOCKER_COMPOSE down
        echo -e "${GREEN}✓ Servicios detenidos${NC}"
        ;;
    5)
        echo -e "${RED}⚠️  Esto eliminará todos los contenedores, volúmenes y datos de n8n${NC}"
        read -p "¿Estás seguro? (yes/no): " confirm
        if [ "$confirm" = "yes" ]; then
            echo -e "${BLUE}Limpiando...${NC}"
            $DOCKER_COMPOSE down -v
            docker system prune -f
            echo -e "${GREEN}✓ Sistema limpiado${NC}"
            echo ""
            echo -e "${BLUE}Reconstruyendo...${NC}"
            $DOCKER_COMPOSE build --no-cache
            $DOCKER_COMPOSE up -d
            echo -e "${GREEN}✓ Sistema reiniciado${NC}"
        else
            echo -e "${YELLOW}Operación cancelada${NC}"
        fi
        ;;
    6)
        echo -e "${BLUE}Estado de servicios:${NC}"
        echo ""
        $DOCKER_COMPOSE ps
        echo ""
        echo -e "${BLUE}Uso de recursos:${NC}"
        docker stats --no-stream
        ;;
    7)
        echo -e "${BLUE}¡Hasta luego!${NC}"
        exit 0
        ;;
    *)
        echo -e "${RED}Opción inválida${NC}"
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}✓ Operación completada${NC}"
