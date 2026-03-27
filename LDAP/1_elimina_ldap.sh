#!/bin/bash

###############################################################################
# Descripción: Desinstalación Total y Purga de OpenLDAP (Debian 12+)
# Autor:       Gemini (Senior Systems Engineer)
# Versión:     1.1.0
# Licencia:    GPL-3.0
###############################################################################

set -euo pipefail
IFS=$'\n\t'

# --- Colores para Logging ---
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m'

log_info()    { echo -e "${GREEN}[INFO]${NC}  $*"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $*"; }

# --- Validación de Privilegios ---
if [[ "${EUID}" -ne 0 ]]; then
    log_error "Se requiere ROOT para desinstalar servicios del sistema."
    exit 1
fi

stop_services() {
    log_info "Deteniendo servicios de LDAP..."
    systemctl stop slapd || log_warn "El servicio slapd no estaba ejecutándose."
}

purge_packages() {
    log_info "Purgando paquetes y archivos de configuración..."
    # 'purge' elimina archivos de configuración, 'autoremove' limpia dependencias
    export DEBIAN_FRONTEND=noninteractive
    apt-get purge -y slapd ldap-utils
    apt-get autoremove -y
    apt-get autoclean
}

remove_files() {
    log_info "Eliminando rastros en el sistema de archivos..."
    
    # Directorios críticos de OpenLDAP
    local targets=(
        "/etc/ldap"
        "/var/lib/ldap"
        "/var/run/slapd"
        "/etc/default/slapd"
    )

    for dir in "${targets[@]}"; do
        if [ -e "$dir" ]; then
            log_warn "Eliminando: $dir"
            rm -rf "$dir"
        fi
    done
}

clean_users() {
    log_info "Eliminando usuario y grupo 'openldap'..."
    if id "openldap" &>/dev/null; then
        userdel openldap || log_warn "No se pudo eliminar el usuario openldap (quizás ya no existe)."
    fi
    if getent group "openldap" &>/dev/null; then
        groupdel openldap || log_warn "No se pudo eliminar el grupo openldap."
    fi
}

verify_cleanup() {
    log_info "Verificando que no queden procesos o puertos..."
    if ss -nlt | grep -E ':389|:636' >/dev/null; then
        log_error "¡ALERTA! Los puertos LDAP todavía parecen estar ocupados."
    else
        log_info "Limpieza de puertos verificada."
    fi
}

# --- Ejecución ---
echo -e "${RED}!!! ATENCIÓN: Esto borrará TODA la base de datos LDAP y su configuración !!!${NC}"
read -p "¿Está seguro de que desea continuar? (s/N): " confirm
if [[ ! "$confirm" =~ ^[sS]$ ]]; then
    log_info "Operación cancelada."
    exit 0
fi

stop_services
purge_packages
remove_files
clean_users
verify_cleanup

log_info "El sistema está limpio. Puede volver a ejecutar el script de instalación."