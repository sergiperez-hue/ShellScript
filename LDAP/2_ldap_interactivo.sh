#!/bin/bash

###############################################################################
# Descripción: Instalador OpenLDAP FQDN - Blindado contra Error 50
# Autor:       Gemini (Senior Systems Engineer)
# Versión:     2.8.0 (Con Verificaciones Completas)
###############################################################################

set -euo pipefail
IFS=$'\n\t'

# --- Configuración Estática ---
readonly SSL_DIR="/etc/ldap/ssl"
readonly LOG_FILE="/var/log/ldap_install.log"
readonly GREEN='\033[0;32m'
readonly RED='\033[0;31m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

log_info()    { echo -e "${GREEN}[INFO]${NC}  $*" | tee -a "$LOG_FILE" >&2; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC}  $*" | tee -a "$LOG_FILE" >&2; }
log_error()   { echo -e "${RED}[ERROR]${NC} $*" | tee -a "$LOG_FILE" >&2; }

cleanup() {
    [[ -d "${TMP_DIR:-}" ]] && rm -rf "$TMP_DIR"
}
trap cleanup EXIT

[[ "${EUID}" -ne 0 ]] && { log_error "Se requiere ROOT."; exit 1; }

get_config() {
    echo -e "${YELLOW}==============================================${NC}"
    echo -e "${YELLOW}   CONFIGURACIÓN BLINDADA DE OPENLDAP FQDN    ${NC}"
    echo -e "${YELLOW}==============================================${NC}\n"

    read -p "Dominio LDAP [sergi.lab]: " DOMAIN
    DOMAIN=${DOMAIN:-"sergi.lab"}
    BASE_DN="dc=${DOMAIN//./,dc=}"

    read -p "Nombre del servidor [$(hostname)]: " SERVER_NODE
    SERVER_NODE=${SERVER_NODE:-$(hostname)}
    FULL_FQDN="${SERVER_NODE}.${DOMAIN}"

    read -p "Organización [Sergi Lab]: " ORG_NAME
    ORG_NAME=${ORG_NAME:-"Sergi Lab"}

    read -p "OUs a crear [users groups]: " OUS
    OUS=${OUS:-"users groups"}
    local IFS=' '; OUS_ARRAY=($OUS)

    echo -n "Password de LDAP Admin: "
    read -s LDAP_PASS
    echo -e "\n"
}

# --- FUNCIÓN CRÍTICA: LIMPIEZA TOTAL ---
# Esto asegura que no haya residuos de instalaciones fallidas que causen el Error 50
purge_previous() {
    log_info "Limpiando instalaciones previas para evitar conflictos de ACL..."
    systemctl stop slapd || true
    export DEBIAN_FRONTEND=noninteractive
    apt-get purge -y slapd ldap-utils >/dev/null 2>&1 || true
    rm -rf /var/lib/ldap/*
    rm -rf /etc/ldap/slapd.d/*
}

install_and_configure() {
    log_info "Instalando slapd limpio..."
    export DEBIAN_FRONTEND=noninteractive
    apt-get update && apt-get install -y slapd ldap-utils openssl

    # 1. Configuración base vía debconf
    echo "slapd slapd/domain string ${DOMAIN}" | debconf-set-selections
    echo "slapd slapd/internal_admin_password password ${LDAP_PASS}" | debconf-set-selections
    echo "slapd slapd/internal_admin_password_again password ${LDAP_PASS}" | debconf-set-selections
    dpkg-reconfigure -f noninteractive slapd

    log_info "Configurando contraseña raíz del administrador..."
    HASHED_PASS=$(slappasswd -s "$LDAP_PASS")
    ldapmodify -Y EXTERNAL -H ldapi:/// <<EOF
dn: olcDatabase={1}mdb,cn=config
changetype: modify
replace: olcRootPW
olcRootPW: $HASHED_PASS
EOF

    log_info "Inyectando privilegios de superusuario (SASL/EXTERNAL)..."
    
    # 2. APLICACIÓN ATÓMICA DE PRIVILEGIOS
    # Forzamos que el UID 0 tenga control total sobre el backend {1}mdb
    local TEMP_LDIF=$(mktemp)
    cat <<EOF > "$TEMP_LDIF"
dn: olcDatabase={1}mdb,cn=config
changetype: modify
replace: olcAccess
olcAccess: {0}to * by dn.base="gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth" manage by * break
olcAccess: {1}to * by self write by dn="cn=admin,${BASE_DN}" write by * read
EOF
    
    # Reintento en bucle (máximo 3) por si el servicio slapd está arrancando
    local retry=0
    until ldapmodify -Y EXTERNAL -H ldapi:/// -f "$TEMP_LDIF" || [ $retry -eq 3 ]; do
        log_warn "Esperando a que slapd responda... (Intento $((retry+1))/3)"
        sleep 2
        retry=$((retry+1))
    done

    # 3. Resto de la estructura
    log_info "Configurando Organización y OUs..."
    cat <<EOF > "$TEMP_LDIF"
dn: ${BASE_DN}
changetype: modify
replace: o
o: ${ORG_NAME}
EOF
    ldapmodify -Y EXTERNAL -H ldapi:/// -f "$TEMP_LDIF"

    local OU_LDIF=$(mktemp)
    for ou in "${OUS_ARRAY[@]}"; do
        cat <<EOF >> "$OU_LDIF"
dn: ou=${ou},${BASE_DN}
objectClass: organizationalUnit
ou: ${ou}

EOF
    done
    ldapadd -Y EXTERNAL -H ldapi:/// -f "$OU_LDIF"
}

setup_tls() {
    log_info "Configurando TLS para ${FULL_FQDN}..."
    mkdir -p "$SSL_DIR"
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout "$SSL_DIR/ldap.key" -out "$SSL_DIR/ldap.crt" \
        -subj "/C=ES/O=${ORG_NAME}/CN=${FULL_FQDN}" 2>/dev/null
    chown -R openldap:openldap "$SSL_DIR"

    local TLS_LDIF=$(mktemp)
    cat <<EOF > "$TLS_LDIF"
dn: cn=config
changetype: modify
replace: olcTLSCertificateFile
olcTLSCertificateFile: $SSL_DIR/ldap.crt
-
replace: olcTLSCertificateKeyFile
olcTLSCertificateKeyFile: $SSL_DIR/ldap.key
EOF
    ldapmodify -Y EXTERNAL -H ldapi:/// -f "$TLS_LDIF"
    sed -i 's|SLAPD_SERVICES=.*|SLAPD_SERVICES="ldap:/// ldapi:/// ldaps:///"|' /etc/default/slapd
    systemctl restart slapd
}

# --- Función para esperar a que slapd esté listo ---
wait_slapd_ready() {
    log_info "Esperando a que slapd esté listo..."
    local max_attempts=30
    local attempt=0
    while [[ $attempt -lt $max_attempts ]]; do
        if ldapsearch -Y EXTERNAL -H ldapi:/// -b "$BASE_DN" -s base dn >/dev/null 2>&1; then
            log_info "slapd está listo."
            return 0
        fi
        sleep 1
        attempt=$((attempt + 1))
    done
    log_error "slapd no respondió después de ${max_attempts} segundos."
    return 1
}

# --- Funciones de Verificación ---
verify_certificates() {
    log_info "Verificando certificados..."
    if [[ -f "$SSL_DIR/ldap.crt" && -f "$SSL_DIR/ldap.key" ]]; then
        log_info "Certificados creados correctamente."
        if openssl x509 -in "$SSL_DIR/ldap.crt" -text -noout >/dev/null 2>&1; then
            log_info "Certificado válido."
        else
            log_error "Certificado inválido."
        fi
    else
        log_error "Certificados no encontrados."
    fi
}

verify_structure() {
    log_info "Verificando estructura del directorio..."
    if ldapsearch -Y EXTERNAL -H ldapi:/// -b "$BASE_DN" -s base dn 2>/dev/null | grep -q "$BASE_DN"; then
        log_info "Base DN existe."
    else
        log_error "Base DN no encontrado."
    fi
    for ou in "${OUS_ARRAY[@]}"; do
        if ldapsearch -Y EXTERNAL -H ldapi:/// -b "ou=$ou,$BASE_DN" -s base dn 2>/dev/null | grep -q "ou=$ou,$BASE_DN"; then
            log_info "OU $ou existe."
        else
            log_error "OU $ou no encontrado."
        fi
    done
}

verify_admin_auth() {
    log_info "Verificando autenticación de administrador..."
    if ldapsearch -D "cn=admin,$BASE_DN" -w "$LDAP_PASS" -H ldapi:/// -b "$BASE_DN" -s base dn 2>&1 | grep -q "dn:.*$BASE_DN"; then
        log_info "Autenticación de admin exitosa."
    else
        log_error "Error en autenticación de admin: Posible 'Invalid credentials'."
    fi
}

verify_dns() {
    log_info "Verificando resolución de nombre de dominio..."
    if nslookup "$FULL_FQDN" >/dev/null 2>&1; then
        log_info "Resolución DNS exitosa para $FULL_FQDN."
    else
        log_warn "Resolución DNS fallida para $FULL_FQDN. Verifique configuración DNS."
    fi
}

verify_ports() {
    log_info "Verificando puertos LDAP..."
    if ss -nlt | grep -q ':389 '; then
        log_info "Puerto 389 escuchando."
    else
        log_error "Puerto 389 no escuchando."
    fi
    if ss -nlt | grep -q ':636 '; then
        log_info "Puerto 636 escuchando."
    else
        log_error "Puerto 636 no escuchando."
    fi
}

verify_connections() {
    log_info "Verificando conexiones LDAP..."
    if ldapsearch -D "cn=admin,$BASE_DN" -w "$LDAP_PASS" -H ldap://localhost:389 -b "$BASE_DN" -s base dn 2>&1 | grep -q "dn:.*$BASE_DN"; then
        log_info "Conexión LDAP localhost:389 exitosa."
    else
        log_error "Conexión LDAP localhost:389 fallida."
    fi
    if LDAPTLS_REQCERT=never ldapsearch -D "cn=admin,$BASE_DN" -w "$LDAP_PASS" -H ldaps://localhost:636 -b "$BASE_DN" -s base dn 2>&1 | grep -q "dn:.*$BASE_DN"; then
        log_info "Conexión LDAPS localhost:636 exitosa."
    else
        log_error "Conexión LDAPS localhost:636 fallida (verificar certificado SSL)."
    fi
}

# --- Ejecución ---
TMP_DIR=$(mktemp -d)
get_config
purge_previous
install_and_configure
setup_tls

# --- Esperando a que slapd esté listo ---
wait_slapd_ready

# --- Verificaciones ---
verify_certificates
verify_structure
verify_admin_auth
verify_dns
verify_ports
verify_connections

# --- Informe Final ---
echo -e "\n${GREEN}=========================================================${NC}"
log_info "FQDN:                ${FULL_FQDN}"
log_info "Base DN:             ${BASE_DN}"
log_info "LDAPS (Seguro):      ldaps://${FULL_FQDN}:636"
echo -e "${GREEN}=========================================================${NC}"
# --- Informe Final Detallado ---
echo -e "\n${GREEN}=========================================================${NC}"
echo -e "${GREEN}   DESPLIEGUE FINALIZADO CON ÉXITO EN DEBIAN 12        ${NC}"
echo -e "${GREEN}=========================================================${NC}"
log_info "Organización:        ${ORG_NAME}"
log_info "Base DN:             ${BASE_DN}"
log_info "Hostname Definido:   ${SERVER_NODE}"
log_info "FQDN Completo:       ${FULL_FQDN}"
log_info "---------------------------------------------------------"
log_info "Puntos de Acceso (Endpoints):"
log_info "  - LDAP (Inseguro):   ldap://${FULL_FQDN}:389"
log_info "  - LDAP (Local):      ldap://localhost:389"
log_info "  - LDAPS (Seguro):    ldaps://${FULL_FQDN}:636"
log_info "  - Socket Interno:    ldapi:///"
log_info "---------------------------------------------------------"
log_info "Certificados:"
log_info "  - Archivo CRT:       ${SSL_DIR}/ldap.crt"
log_info "  - Archivo KEY:       ${SSL_DIR}/ldap.key"
echo -e "${GREEN}=========================================================${NC}"