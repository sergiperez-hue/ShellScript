#!/bin/bash

################################################################################
#           SCRIPT AUXILIAR: VERSIONADO DE RELEASES
# Facilita crear nuevas versiones del script principal
################################################################################

set -u

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MAIN_SCRIPT="1_instalacion_entorno_desarrollo.sh"

print_header() {
    echo -e "\n${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}\n"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_info() {
    echo -e "${CYAN}ℹ $1${NC}"
}

# Leer versión actual
get_current_version() {
    grep "^Versión:" "$SCRIPT_DIR/$MAIN_SCRIPT" | awk -F': ' '{print $2}' | head -1
}

# Crear nueva versión
create_release() {
    local new_version="$1"
    local release_file="$SCRIPT_DIR/${MAIN_SCRIPT%.sh}.$new_version.sh"
    
    print_header "CREANDO RELEASE V$new_version"
    
    if [[ -f "$release_file" ]]; then
        print_error "Release $new_version ya existe"
        return 1
    fi
    
    print_info "Copiando $MAIN_SCRIPT → ${MAIN_SCRIPT%.sh}.$new_version.sh"
    cp "$SCRIPT_DIR/$MAIN_SCRIPT" "$release_file"
    chmod +x "$release_file"
    
    # Actualizar versión en cabecera
    local current_date=$(date '+%Y-%m-%d')
    sed -i "s/^# Versión: .*/# Versión: $new_version/" "$release_file"
    sed -i "s/^# Fecha: .*/# Fecha: $current_date/" "$release_file"
    
    # Actualizar archivo VERSION
    cat > "$SCRIPT_DIR/VERSION" <<EOF
VERSION=$new_version
RELEASE_DATE=$current_date
STATUS=stable
AUTHOR=sysadmin
EOF
    
    print_success "Release creado: $release_file"
    print_info "Versión registrada en VERSION"
    
    echo ""
    print_info "Siguientes pasos:"
    echo "  1. Documenta los cambios en CHANGELOG.md"
    echo "  2. Verifica el script: bash -n '$release_file'"
    echo "  3. Prueba la ejecución si es necesario"
}

# Mostrar información de versión
show_version_info() {
    print_header "INFORMACIÓN DE VERSIÓN"
    
    if [[ -f "$SCRIPT_DIR/VERSION" ]]; then
        echo "Versión actual (en desarrollo):"
        cat "$SCRIPT_DIR/VERSION"
    else
        print_error "Archivo VERSION no encontrado"
    fi
    
    echo ""
    echo "Releases disponibles:"
    ls -1 "$SCRIPT_DIR"/1_instalacion_entorno_desarrollo.*.sh 2>/dev/null | \
        xargs -I {} basename {} | sed 's/1_instalacion_entorno_desarrollo\.\(.*\)\.sh/  - v\1/' || \
        print_info "(ningún release versionado aún)"
}

# MENÚ PRINCIPAL
main() {
    clear
    print_header "GESTOR DE VERSIONADO"
    
    echo "1) Ver información de versión"
    echo "2) Crear nuevo release"
    echo "0) Salir"
    echo ""
    
    echo -ne "${CYAN}Selecciona opción: ${NC}"
    read choice
    
    case $choice in
        1)
            show_version_info
            ;;
        2)
            echo -ne "${CYAN}Ingresa versión (ej: 0.1.0): ${NC}"
            read version
            if [[ -z "$version" ]]; then
                print_error "Versión no puede estar vacía"
            else
                create_release "$version"
            fi
            ;;
        0)
            exit 0
            ;;
        *)
            print_error "Opción no válida"
            ;;
    esac
}

main
