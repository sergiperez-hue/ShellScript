#!/bin/bash

################################################################################
#                    PREPARACIÓN SUDOERS - PARA EJECUTAR COMO ROOT
#     Script que configura permisos para que sysadmin pueda usar sudo
################################################################################

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

print_header() {
    echo -e "\n${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${CYAN}ℹ $1${NC}"
}

# Verificar que se ejecuta como root
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}════════════════════════════════════════════════════════════${NC}"
    echo -e "${RED}ERROR: Este script DEBE ejecutarse como root${NC}"
    echo -e "${RED}════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo "Ejecuta:"
    echo "  su root"
    echo "  /home/sysadmin/Desktop/ShellScript/setup_sudoers.sh"
    echo ""
    echo "O directamente:"
    echo "  su -c '/home/sysadmin/Desktop/ShellScript/setup_sudoers.sh'"
    exit 1
fi

print_header "CONFIGURACIÓN DE SUDOERS PARA SYSADMIN"

print_info "Este script agregará el usuario 'sysadmin' al archivo sudoers"
print_info "Esto permitirá ejecutar comandos con sudo sin contraseña"

echo ""
read -p "$(echo -e ${CYAN}¿Deseas continuar? (s/n):${NC}) " response
if [[ ! "$response" =~ ^[sS]$ ]]; then
    print_info "Operación cancelada"
    exit 0
fi

# Verificar si sysadmin ya existe en sudoers
if sudo -l -U sysadmin 2>/dev/null | grep -q "ALL=(ALL:ALL)"; then
    print_error "El usuario sysadmin ya tiene acceso a sudoers"
    exit 0
fi

print_info "Agregando 'sysadmin' a sudoers..."

# Usar echo con tee para agregar a sudoers de forma segura
echo "sysadmin ALL=(ALL:ALL) NOPASSWD:ALL" | tee -a /etc/sudoers.d/sysadmin >/dev/null

# Validar la sintaxis
if visudo -c -f /etc/sudoers.d/sysadmin 2>/dev/null; then
    print_success "Configuración agregada correctamente"
    chmod 440 /etc/sudoers.d/sysadmin
    print_success "Permisos de archivo configurados"
else
    print_error "Error en la configuración de sudoers"
    rm -f /etc/sudoers.d/sysadmin
    exit 1
fi

echo ""
print_header "CONFIGURACIÓN COMPLETADA"
echo ""
print_success "El usuario 'sysadmin' ahora puede usar sudo"
echo ""
print_info "Ahora sysadmin puede ejecutar:"
echo "  /home/sysadmin/Desktop/ShellScript/hola.sh"
echo ""
print_info "Para verificar que funciona, ejecuta:"
echo "  su - sysadmin -c 'sudo whoami'"
echo ""
print_info "Debería mostrar: root"
echo ""
