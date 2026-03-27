#!/bin/bash

###############################################################################
# Descripción: Menú Interactivo de Gestión de Usuarios LDAP
# Autor:       Gemini (Senior Systems Engineer)
# Versión:     1.0.0
###############################################################################

set -euo pipefail

# --- Configuración ---
readonly LOG_FILE="/var/log/ldap_usuarios.log"
readonly GREEN='\033[0;32m'
readonly RED='\033[0;31m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# Solicitar configuración
LDAP_DOMAIN=""
LDAP_USER=""
LDAP_PASS=""
BASE_DN=""

log_info()    { echo -e "${GREEN}[INFO]${NC}  $*" | tee -a "$LOG_FILE" >&2; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC}  $*" | tee -a "$LOG_FILE" >&2; }
log_error()   { echo -e "${RED}[ERROR]${NC} $*" | tee -a "$LOG_FILE" >&2; }
log_success() { echo -e "${GREEN}[✓]${NC}    $*" | tee -a "$LOG_FILE" >&2; }

# --- Función de autenticación ---
get_admin_credentials() {
    if [[ -z "$LDAP_DOMAIN" ]]; then
        read -p "Dominio LDAP [sergi.lab]: " LDAP_DOMAIN
        LDAP_DOMAIN=${LDAP_DOMAIN:-"sergi.lab"}
        BASE_DN="dc=${LDAP_DOMAIN//./,dc=}"
    fi
    
    if [[ -z "$LDAP_USER" ]]; then
        LDAP_USER="cn=admin,$BASE_DN"
    fi
    
    if [[ -z "$LDAP_PASS" ]]; then
        echo -n "Contraseña de administrador LDAP: "
        read -s LDAP_PASS
        echo ""
    fi
}

# --- Función para validar credenciales ---
validate_credentials() {
    if ! ldapsearch -D "$LDAP_USER" -w "$LDAP_PASS" -H ldapi:/// -b "$BASE_DN" -s base dn >/dev/null 2>&1; then
        log_error "Credenciales inválidas."
        LDAP_PASS=""
        return 1
    fi
    return 0
}

# --- OPCIÓN 1: Alta de Usuario ---
add_user() {
    clear
    echo -e "${BLUE}========== ALTA DE USUARIO ==========${NC}\n"
    
    read -p "Usuario (UID) [nuevo_usuario]: " USERNAME
    USERNAME=${USERNAME:-"nuevo_usuario"}
    
    read -p "Nombre completo (CN) [Usuario Nuevo]: " FULLNAME
    FULLNAME=${FULLNAME:-"Usuario Nuevo"}
    
    read -p "Email [usuario@ejemplo.com]: " EMAIL
    EMAIL=${EMAIL:-"usuario@ejemplo.com"}
    
    echo -n "Contraseña del usuario: "
    read -s USER_PASS
    echo ""
    
    read -p "OU para ubicar el usuario [users]: " OU
    OU=${OU:-"users"}
    
    # Generar hash de contraseña
    HASHED_PASS=$(slappasswd -s "$USER_PASS")
    
    # Crear el LDIF
    cat > /tmp/add_user.ldif <<EOF
dn: uid=$USERNAME,ou=$OU,$BASE_DN
objectClass: inetOrgPerson
objectClass: posixAccount
uid: $USERNAME
cn: $FULLNAME
sn: $FULLNAME
mail: $EMAIL
userPassword: $HASHED_PASS
uidNumber: $(date +%s | tail -c 5)
gidNumber: 1000
homeDirectory: /home/$USERNAME
loginShell: /bin/bash
EOF
    
    echo -e "\n${YELLOW}Datos a añadir:${NC}"
    cat /tmp/add_user.ldif
    
    read -p $'\n¿Confirmar alta de usuario? (s/n): ' confirm
    
    if [[ "$confirm" == "s" || "$confirm" == "S" ]]; then
        if ldapadd -D "$LDAP_USER" -w "$LDAP_PASS" -H ldapi:/// -f /tmp/add_user.ldif >/dev/null 2>&1; then
            log_success "Usuario $USERNAME creado exitosamente."
        else
            log_error "Error al crear el usuario $USERNAME."
        fi
    else
        log_warn "Operación cancelada."
    fi
    
    rm -f /tmp/add_user.ldif
    read -p $'\nPresiona ENTER para continuar...'
}

# --- OPCIÓN 2: Baja de Usuario ---
delete_user() {
    clear
    echo -e "${BLUE}========== BAJA DE USUARIO ==========${NC}\n"
    
    read -p "Usuario (UID) a eliminar: " USERNAME
    
    if [[ -z "$USERNAME" ]]; then
        log_error "Debe proporcionar un usuario."
        read -p $'\nPresiona ENTER para continuar...'
        return
    fi
    
    read -p "OU donde se encuentra el usuario [users]: " OU
    OU=${OU:-"users"}
    
    USER_DN="uid=$USERNAME,ou=$OU,$BASE_DN"
    
    # Verificar que existe
    if ! ldapsearch -D "$LDAP_USER" -w "$LDAP_PASS" -H ldapi:/// -b "$USER_DN" -s base dn 2>&1 | grep -q "dn:"; then
        log_error "Usuario $USERNAME no encontrado en ou=$OU."
        read -p $'\nPresiona ENTER para continuar...'
        return
    fi
    
    echo -e "\n${YELLOW}Usuario a eliminar:${NC}"
    echo "DN: $USER_DN"
    
    read -p $'\n¿Confirmar eliminación del usuario? (s/n): ' confirm
    
    if [[ "$confirm" != "s" && "$confirm" != "S" ]]; then
        log_warn "Operación cancelada."
        read -p $'\nPresiona ENTER para continuar...'
        return
    fi
    
    read -p "Escriba 'CONFIRMAR' para eliminar definitivamente: " confirm_text
    
    if [[ "$confirm_text" == "CONFIRMAR" ]]; then
        if ldapdelete -D "$LDAP_USER" -w "$LDAP_PASS" -H ldapi:/// "$USER_DN" >/dev/null 2>&1; then
            log_success "Usuario $USERNAME eliminado exitosamente."
        else
            log_error "Error al eliminar el usuario $USERNAME."
        fi
    else
        log_warn "Eliminación cancelada."
    fi
    
    read -p $'\nPresiona ENTER para continuar...'
}

# --- OPCIÓN 3: Modificación de Usuario ---
modify_user() {
    clear
    echo -e "${BLUE}========== MODIFICACIÓN DE USUARIO ==========${NC}\n"
    
    read -p "Usuario (UID) a modificar: " USERNAME
    
    if [[ -z "$USERNAME" ]]; then
        log_error "Debe proporcionar un usuario."
        read -p $'\nPresiona ENTER para continuar...'
        return
    fi
    
    read -p "OU donde se encuentra el usuario [users]: " OU
    OU=${OU:-"users"}
    
    USER_DN="uid=$USERNAME,ou=$OU,$BASE_DN"
    
    # Verificar que existe
    if ! ldapsearch -D "$LDAP_USER" -w "$LDAP_PASS" -H ldapi:/// -b "$USER_DN" -s base dn 2>&1 | grep -q "dn:"; then
        log_error "Usuario $USERNAME no encontrado en ou=$OU."
        read -p $'\nPresiona ENTER para continuar...'
        return
    fi
    
    echo -e "\n${YELLOW}¿Qué desea modificar?${NC}"
    echo "1. Nombre completo (CN)"
    echo "2. Email"
    echo "3. Contraseña"
    echo "4. Cancelar"
    read -p "Seleccione opción: " modify_option
    
    case $modify_option in
        1)
            read -p "Nuevo nombre completo: " NEW_CN
            cat > /tmp/modify_user.ldif <<EOF
dn: $USER_DN
changetype: modify
replace: cn
cn: $NEW_CN
EOF
            ;;
        2)
            read -p "Nuevo email: " NEW_EMAIL
            cat > /tmp/modify_user.ldif <<EOF
dn: $USER_DN
changetype: modify
replace: mail
mail: $NEW_EMAIL
EOF
            ;;
        3)
            echo -n "Nueva contraseña: "
            read -s NEW_PASS
            echo ""
            HASHED_PASS=$(slappasswd -s "$NEW_PASS")
            cat > /tmp/modify_user.ldif <<EOF
dn: $USER_DN
changetype: modify
replace: userPassword
userPassword: $HASHED_PASS
EOF
            ;;
        4)
            log_warn "Operación cancelada."
            read -p $'\nPresiona ENTER para continuar...'
            return
            ;;
        *)
            log_error "Opción inválida."
            read -p $'\nPresiona ENTER para continuar...'
            return
            ;;
    esac
    
    echo -e "\n${YELLOW}Cambios a realizar:${NC}"
    cat /tmp/modify_user.ldif
    
    read -p $'\n¿Confirmar modificación? (s/n): ' confirm
    
    if [[ "$confirm" == "s" || "$confirm" == "S" ]]; then
        if ldapmodify -D "$LDAP_USER" -w "$LDAP_PASS" -H ldapi:/// -f /tmp/modify_user.ldif >/dev/null 2>&1; then
            log_success "Usuario $USERNAME modificado exitosamente."
        else
            log_error "Error al modificar el usuario $USERNAME."
        fi
    else
        log_warn "Operación cancelada."
    fi
    
    rm -f /tmp/modify_user.ldif
    read -p $'\nPresiona ENTER para continuar...'
}

# --- OPCIÓN 4: Consulta de Usuario ---
query_user() {
    clear
    echo -e "${BLUE}========== CONSULTA DE USUARIO ==========${NC}\n"
    
    read -p "Usuario (UID) a consultar: " USERNAME
    
    if [[ -z "$USERNAME" ]]; then
        log_error "Debe proporcionar un usuario."
        read -p $'\nPresiona ENTER para continuar...'
        return
    fi
    
    read -p "OU donde se encuentra el usuario [users]: " OU
    OU=${OU:-"users"}
    
    USER_DN="uid=$USERNAME,ou=$OU,$BASE_DN"
    
    echo -e "\n${YELLOW}Información del usuario:${NC}\n"
    
    if ldapsearch -D "$LDAP_USER" -w "$LDAP_PASS" -H ldapi:/// -b "$USER_DN" -s base; then
        log_success "Consulta completada."
    else
        log_error "Usuario $USERNAME no encontrado."
    fi
    
    read -p $'\nPresiona ENTER para continuar...'
}

# --- OPCIÓN 5: Listado Completo de Usuarios ---
list_all_users() {
    clear
    echo -e "${BLUE}========== LISTADO DE USUARIOS ==========${NC}\n"
    
    read -p "OU a listar [users]: " OU
    OU=${OU:-"users"}
    
    echo -e "\n${YELLOW}Usuarios en ou=$OU,$BASE_DN:${NC}\n"
    
    ldapsearch -D "$LDAP_USER" -w "$LDAP_PASS" -H ldapi:/// -b "ou=$OU,$BASE_DN" -s sub "(objectClass=inetOrgPerson)" uid cn mail
    
    log_success "Listado completado."
    read -p $'\nPresiona ENTER para continuar...'
}

# --- Menú principal ---
show_menu() {
    clear
    echo -e "${BLUE}=========================================================${NC}"
    echo -e "${BLUE}     MENÚ DE GESTIÓN DE USUARIOS LDAP                  ${NC}"
    echo -e "${BLUE}=========================================================${NC}\n"
    
    echo "1. Alta de usuario (crear)"
    echo "2. Baja de usuario (eliminar)"
    echo "3. Modificación de usuario"
    echo "4. Consulta de usuario"
    echo "5. Listado completo de usuarios"
    echo "6. Salir"
    echo ""
    read -p "Seleccione opción (1-6): " option
}

# --- Función principal ---
main() {
    [[ "${EUID}" -ne 0 ]] && { log_error "Se requiere ROOT."; exit 1; }
    
    get_admin_credentials
    
    if ! validate_credentials; then
        log_error "No se pudo validar las credenciales de administrador."
        exit 1
    fi
    
    log_success "Credenciales validadas."
    
    while true; do
        show_menu
        
        case $option in
            1)
                add_user
                ;;
            2)
                delete_user
                ;;
            3)
                modify_user
                ;;
            4)
                query_user
                ;;
            5)
                list_all_users
                ;;
            6)
                log_info "Saliendo del menú de usuarios."
                exit 0
                ;;
            *)
                log_error "Opción inválida. Intente de nuevo."
                read -p $'\nPresiona ENTER para continuar...'
                ;;
        esac
    done
}

main "$@"
