#!/bin/bash

################################################################################
#                   DESARROLLO ENVIRONMENT SETUP DEBIAN 12
#          Script interactivo para configurar entorno de desarrollo
#
# Versión: 0.0.2
# Fecha: 2026-03-27
# Descripción: Setup inicial de desarrollo en Debian 12 con GNOME
#              (Python, Node.js, Lua, TypeScript, Git, GitHub, VS Code)
# Cambios en 0.0.2:
#              - Agregado: Función completa de desinstalación de todos los paquetes
#              - Agregado: Opción en menú para desinstalar (para pruebas en VM)
# Cambios en 0.0.1:
#              - Arreglo: Firefox ahora se instala desde repos de Mozilla
#              - Arreglo: VS Code configuración de clave GPG corregida (issue #1)
################################################################################

set -u  # Salir si hay variable no definida

# COLORES
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ARCHIVO DE LOG
LOG_FILE="$HOME/setup_development.log"
START_TIME=$(date '+%Y-%m-%d %H:%M:%S')

################################################################################
# FUNCIONES AUXILIARES
################################################################################

log_message() {
    local msg="$1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $msg" >> "$LOG_FILE"
}

print_header() {
    echo -e "\n${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
    log_message "[SUCCESS] $1"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
    log_message "[ERROR] $1"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
    log_message "[WARNING] $1"
}

print_info() {
    echo -e "${CYAN}ℹ $1${NC}"
    log_message "[INFO] $1"
}

# Verificar si es root
check_sudo() {
    if [[ $EUID -ne 0 ]]; then
        print_error "Este script debe ejecutarse con sudo"
        exit 1
    fi
}

# Configurar sudoers para sysadmin (cuando el script se ejecuta como root)
setup_sysadmin_sudo() {
    print_header "CONFIGURACIÓN DE SUDOERS PARA SYSADMIN"

    if [[ $(id -un) != "root" ]]; then
        print_error "Esta función debe ejecutarse como root"
        return 1
    fi

    if [[ -f "/etc/sudoers.d/sysadmin" ]]; then
        print_warning "El archivo /etc/sudoers.d/sysadmin ya existe"
    else
        echo "sysadmin ALL=(ALL:ALL) NOPASSWD:ALL" > /etc/sudoers.d/sysadmin
        chmod 440 /etc/sudoers.d/sysadmin
        print_success "Agregado usuario sysadmin a sudoers (NOPASSWD)"
    fi

    if visudo -c -f /etc/sudoers.d/sysadmin >/dev/null 2>&1; then
        print_success "Archivo sudoers válido"
    else
        print_error "Error de sintaxis en sudoers. Se revertirá la configuración"
        rm -f /etc/sudoers.d/sysadmin
        exit 1
    fi

    echo ""
    print_info "Listo: ahora ejecuta este script como sysadmin:" 
    echo "  /home/sysadmin/Desktop/ShellScript/1_instalacion_entorno_desarrollo.sh"
    exit 0
}

# Verificar si el usuario actual tiene sudo
ensure_sudo_available() {
    if [[ $EUID -eq 0 ]]; then
        setup_sysadmin_sudo
    fi

    if ! sudo -n true 2>/dev/null; then
        print_error "El usuario $(id -un) no tiene acceso a sudo"
        echo "Ejecuta este script como root para configurar sudoers:"
        echo "  su -c '/home/sysadmin/Desktop/ShellScript/1_instalacion_entorno_desarrollo.sh'"
        exit 1
    fi
}

# Verificar si una herramienta está instalada
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Menú de selección simple (Si/No)
confirm() {
    local prompt="$1"
    local response
    
    while true; do
        read -p "$(echo -e ${CYAN}$prompt${NC}) (s/n): " response
        case "$response" in
            [sS]|[yY]) return 0 ;;
            [nN]) return 1 ;;
            *) echo "Por favor, responde 's' o 'n'" ;;
        esac
    done
}

# Menú de selección múltiple
select_options() {
    local prompt="$1"
    shift
    local options=("$@")
    local selected=()
    
    PS3=$(echo -e "${CYAN}${prompt}${NC} ")
    
    echo "Selecciona instalaciones (escribe números separados por espacios, 0 para finalizar):"
    for i in "${!options[@]}"; do
        echo "$((i+1))) ${options[$i]}"
    done
    echo "0) Finalizar selección"
    
    read -p "Tu selección: " choices
    
    for choice in $choices; do
        if [[ $choice -ge 1 && $choice -le ${#options[@]} ]]; then
            selected+=("${options[$((choice-1))]}")
        fi
    done
    
    printf '%s\n' "${selected[@]}"
}

################################################################################
# ACTUALIZACIÓN DEL SISTEMA
################################################################################

update_system() {
    print_header "ACTUALIZANDO SISTEMA"
    
    print_info "Actualizando índices de paquetes..."
    if sudo apt update -qq; then
        print_success "Índices actualizados"
    else
        print_error "Error al actualizar índices"
        return 1
    fi
    
    if confirm "¿Deseas hacer upgrade del sistema (apt upgrade)?"; then
        print_info "Ejecutando upgrade..."
        if sudo apt upgrade -y -qq; then
            print_success "Sistema actualizado"
        else
            print_error "Error en upgrade"
            return 1
        fi
    fi
}

################################################################################
# INSTALACIÓN DE HERRAMIENTAS BASE
################################################################################

install_build_tools() {
    print_info "Instalando herramientas de compilación..."
    if sudo apt install -y -qq build-essential curl wget git-lfs gnome-keyring; then
        print_success "Herramientas de compilación instaladas"
        log_message "Build-tools, curl, wget, git-lfs, gnome-keyring instalados"
    else
        print_error "Error al instalar herramientas de compilación"
        return 1
    fi
}

install_firefox() {
    if command_exists firefox; then
        FIREFOX_VERSION=$(firefox --version 2>/dev/null || echo "desconocida")
        print_warning "Firefox ya está instalado: $FIREFOX_VERSION"
        return 0
    fi
    
    print_info "Instalando Firefox (ESR - última versión estable)..."
    
    # Agregar repositorio oficial de Mozilla
    if ! grep -q "mozilla.debian" /etc/apt/sources.list /etc/apt/sources.list.d/* 2>/dev/null; then
        print_info "Agregando repositorio de Mozilla..."
        echo "deb http://deb.debian.org/debian-mozilla/ bookworm-backports main" | sudo tee /etc/apt/sources.list.d/mozilla.list >/dev/null
        curl https://keys.openpgp.org/vks/v1/by-fingerprint/A887DBA236B287F51D02D4AEBA3522EB4C27C3D2 | sudo tee /etc/apt/trusted.gpg.d/debian-mozilla.asc >/dev/null 2>&1
        sudo apt update -qq >/dev/null 2>&1
    fi
    
    if sudo apt install -y -qq firefox-esr; then
        FIREFOX_VERSION=$(firefox --version 2>/dev/null || echo "Versión desconocida")
        print_success "Firefox instalado: $FIREFOX_VERSION"
        log_message "Firefox instalado con última versión ESR"
    else
        print_error "Error al instalar Firefox"
        return 1
    fi
}

install_git() {
    if command_exists git; then
        GIT_VERSION=$(git --version)
        print_warning "Git ya está instalado: $GIT_VERSION"
        return 0
    fi
    
    print_info "Instalando Git..."
    if sudo apt install -y -qq git; then
        GIT_VERSION=$(git --version)
        print_success "Git instalado: $GIT_VERSION"
        log_message "Git instalado"
    else
        print_error "Error al instalar Git"
        return 1
    fi
}

install_vscode() {
    if command_exists code; then
        VSCODE_VERSION=$(code --version 2>/dev/null | head -1 || echo "versión desconocida")
        print_warning "VS Code ya está instalado: $VSCODE_VERSION"
        return 0
    fi
    
    print_info "Instalando Visual Studio Code..."
    
    # Descargar e instalar clave GPG de Microsoft
    print_info "Configurando repositorio de Microsoft..."
    if ! curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | sudo tee /usr/share/keyrings/microsoft-archive-keyring.gpg >/dev/null 2>&1; then
        print_error "Error al descargar clave GPG de Microsoft"
        return 1
    fi
    
    # Agregar repositorio
    echo "deb [arch=amd64,arm64,armhf signed-by=/usr/share/keyrings/microsoft-archive-keyring.gpg] https://packages.microsoft.com/repos/code stable main" | \
        sudo tee /etc/apt/sources.list.d/vscode.list >/dev/null 2>&1
    
    print_info "Actualizando índices de paquetes..."
    if ! sudo apt update -qq >/dev/null 2>&1; then
        print_error "Error al actualizar índices de paquetes"
        return 1
    fi
    
    if sudo apt install -y -qq code; then
        VSCODE_VERSION=$(code --version 2>/dev/null | head -1 || echo "versión desconocida")
        print_success "Visual Studio Code instalado: $VSCODE_VERSION"
        log_message "VS Code instalado correctamente"
    else
        print_error "Error al instalar VS Code"
        return 1
    fi
}

install_github_cli() {
    if command_exists gh; then
        GH_VERSION=$(gh --version | head -n1)
        print_warning "GitHub CLI ya está instalado: $GH_VERSION"
        return 0
    fi
    
    print_info "Instalando GitHub CLI..."
    if curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg >/dev/null 2>&1 && \
       echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null && \
       sudo apt update -qq && \
       sudo apt install -y -qq gh; then
        print_success "GitHub CLI instalado"
        log_message "GitHub CLI instalado"
    else
        print_error "Error al instalar GitHub CLI"
        return 1
    fi
}

################################################################################
# INSTALACIÓN DE LENGUAJES DE PROGRAMACIÓN
################################################################################

install_python() {
    if command_exists python3; then
        PYTHON_VERSION=$(python3 --version)
        print_warning "Python ya está instalado: $PYTHON_VERSION"
        return 0
    fi
    
    print_info "Instalando Python3 y pip..."
    if sudo apt install -y -qq python3 python3-pip python3-venv; then
        PYTHON_VERSION=$(python3 --version)
        print_success "Python instalado: $PYTHON_VERSION"
        log_message "Python3 y pip instalados"
    else
        print_error "Error al instalar Python"
        return 1
    fi
}

install_nodejs() {
    if command_exists node; then
        NODE_VERSION=$(node --version)
        print_warning "Node.js ya está instalado: $NODE_VERSION"
        return 0
    fi
    
    print_info "Instalando Node.js y npm..."
    if curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash - >/dev/null 2>&1 && \
       sudo apt install -y -qq nodejs; then
        NODE_VERSION=$(node --version)
        NPM_VERSION=$(npm --version)
        print_success "Node.js instalado: $NODE_VERSION, npm: $NPM_VERSION"
        log_message "Node.js y npm instalados"
    else
        print_error "Error al instalar Node.js"
        return 1
    fi
}

install_lua() {
    if command_exists lua; then
        LUA_VERSION=$(lua -v)
        print_warning "Lua ya está instalado: $LUA_VERSION"
        return 0
    fi
    
    print_info "Instalando Lua..."
    if sudo apt install -y -qq lua5.4; then
        LUA_VERSION=$(lua -v)
        print_success "Lua instalado: $LUA_VERSION"
        log_message "Lua instalado"
    else
        print_error "Error al instalar Lua"
        return 1
    fi
}

install_typescript() {
    if ! command_exists node; then
        print_error "Node.js no está instalado. Por favor, instala Node.js primero"
        return 1
    fi
    
    if command_exists tsc; then
        TSC_VERSION=$(tsc --version)
        print_warning "TypeScript ya está instalado: $TSC_VERSION"
        return 0
    fi
    
    print_info "Instalando TypeScript globalmente..."
    if sudo npm install -g typescript >/dev/null 2>&1; then
        TSC_VERSION=$(tsc --version)
        print_success "TypeScript instalado: $TSC_VERSION"
        log_message "TypeScript instalado"
    else
        print_error "Error al instalar TypeScript"
        return 1
    fi
}

################################################################################
# CONFIGURACIÓN DE GITHUB
################################################################################

configure_github() {
    print_header "CONFIGURACIÓN DE GITHUB"
    
    # Verificar que Git esté instalado
    if ! command_exists git; then
        print_error "Git no está instalado. Por favor, instálalo primero"
        return 1
    fi
    
    # Obtener nombre y email
    print_info "Ingresa tus datos de GitHub:"
    read -p "$(echo -e ${CYAN}Nombre completo:${NC}) " github_name
    read -p "$(echo -e ${CYAN}Email de GitHub:${NC}) " github_email
    
    # Configurar Git globalmente
    print_info "Configurando Git localmente..."
    git config --global user.name "$github_name"
    git config --global user.email "$github_email"
    print_success "Git configurado con: $github_name <$github_email>"
    log_message "Git configurado: $github_name <$github_email>"
    
    # Generar claves SSH si no existen
    if [[ ! -f "$HOME/.ssh/id_rsa" ]]; then
        print_info "Generando claves SSH..."
        ssh-keygen -t rsa -b 4096 -f "$HOME/.ssh/id_rsa" -N "" >/dev/null 2>&1
        print_success "Claves SSH generadas"
        log_message "Claves SSH generadas"
    else
        print_warning "Las claves SSH ya existen"
    fi
    
    # Mostrar clave pública
    print_info "Tu clave SSH pública (cópiala a GitHub):"
    echo -e "${YELLOW}"
    cat "$HOME/.ssh/id_rsa.pub"
    echo -e "${NC}"
    
    # Autenticar con GitHub CLI si está disponible
    if command_exists gh; then
        if confirm "¿Deseas autenticarte con GitHub CLI?"; then
            print_info "Abriendo GitHub CLI auth..."
            gh auth login
            print_success "Autenticación completada"
            log_message "GitHub CLI autenticación completada"
        fi
    fi
}

setup_development_repo() {
    print_header "CONFIGURACIÓN DEL REPOSITORIO DEVELOPMENT"
    
    local DEV_DIR="$HOME/Development"
    
    # Crear directorio si no existe
    if [[ ! -d "$DEV_DIR" ]]; then
        print_info "Creando directorio $DEV_DIR..."
        mkdir -p "$DEV_DIR"
        print_success "Directorio creado"
        log_message "Directorio Development creado"
    else
        print_warning "El directorio Development ya existe"
    fi
    
    # Inicializar repositorio Git si no existe
    if [[ ! -d "$DEV_DIR/.git" ]]; then
        print_info "Inicializando repositorio Git..."
        cd "$DEV_DIR"
        git init >/dev/null 2>&1
        
        # Crear archivo README
        cat > "$DEV_DIR/README.md" <<EOF
# Development Repository

Repositorio principal de desarrollo configurado el $(date '+%Y-%m-%d %H:%M:%S')

## Estructura
- projectos personales
- experimentos
- prácticas

## Herramientas
$(if command_exists python3; then echo "- Python $(python3 --version)"; fi)
$(if command_exists node; then echo "- Node.js $(node --version)"; fi)
$(if command_exists lua; then echo "- Lua $(lua -v | cut -d' ' -f1-2)"; fi)
EOF
        
        git add README.md >/dev/null 2>&1
        git commit -m "Commit inicial: repositorio creado el $(date '+%Y-%m-%d')" >/dev/null 2>&1
        print_success "Repositorio Git inicializado"
        log_message "Repositorio Development inicializado"
    else
        print_warning "El repositorio Git ya existe en Development"
    fi
    
    # Crear repositorio remoto en GitHub si GitHub CLI está disponible
    if command_exists gh; then
        if confirm "¿Deseas crear el repositorio 'Development' en GitHub?"; then
            cd "$DEV_DIR"
            if gh repo create Development --local --source=. --description="Repositorio de desarrollo" >/dev/null 2>&1; then
                print_success "Repositorio remoto 'Development' creado en GitHub"
                log_message "Repositorio remoto creado en GitHub"
            else
                print_warning "No se pudo crear el repositorio remoto (podría existir)"
                log_message "Intento de crear repo remoto - posible que ya exista"
            fi
        fi
    fi
}

################################################################################
# CONFIGURACIÓN DE VS CODE
################################################################################

install_vscode_extensions() {
    print_header "INSTALACIÓN DE EXTENSIONES VS CODE"
    
    if ! command_exists code; then
        print_error "VS Code no está instalado"
        return 1
    fi
    
    print_info "Instalando extensiones de VS Code..."
    
    # Extensiones recomendadas
    local extensions=(
        "GitHub.copilot"
        "GitHub.vscode-pull-request-github"
        "mhutchie.git-graph"
        "ms-python.python"
        "ms-python.vscode-pylance"
        "esbenp.prettier-vscode"
        "dbaeumer.vscode-eslint"
        "ms-vscode.cpptools"
        "lua.lua"
    )
    
    for ext in "${extensions[@]}"; do
        print_info "Instalando: $ext..."
        if code --install-extension "$ext" --force >/dev/null 2>&1; then
            print_success "Instalada: $ext"
            log_message "Extensión instalada: $ext"
        else
            print_warning "No se pudo instalar: $ext (podría ya estar instalada)"
        fi
    done
}

################################################################################
# FUNCIONES DE DESINSTALACIÓN (para pruebas y limpieza)
################################################################################

uninstall_firefox() {
    if ! command_exists firefox; then
        print_warning "Firefox no está instalado"
        return 0
    fi
    
    print_info "Desinstalando Firefox..."
    if sudo apt remove -y -qq firefox-esr firefox; then
        print_success "Firefox desinstalado"
        log_message "Firefox desinstalado"
    else
        print_warning "Error al desinstalar Firefox (podría no estar instalado)"
    fi
}

uninstall_git() {
    if ! command_exists git; then
        print_warning "Git no está instalado"
        return 0
    fi
    
    print_info "Desinstalando Git..."
    if sudo apt remove -y -qq git; then
        print_success "Git desinstalado"
        log_message "Git desinstalado"
    else
        print_warning "Error al desinstalar Git"
    fi
}

uninstall_vscode() {
    if ! command_exists code; then
        print_warning "VS Code no está instalado"
        return 0
    fi
    
    print_info "Desinstalando Visual Studio Code..."
    if sudo apt remove -y -qq code; then
        print_success "VS Code desinstalado"
        log_message "VS Code desinstalado"
        # Limpiar repositorio de VS Code
        sudo rm -f /etc/apt/sources.list.d/vscode.list
        sudo rm -f /usr/share/keyrings/microsoft-archive-keyring.gpg
    else
        print_warning "Error al desinstalar VS Code"
    fi
}

uninstall_github_cli() {
    if ! command_exists gh; then
        print_warning "GitHub CLI no está instalado"
        return 0
    fi
    
    print_info "Desinstalando GitHub CLI..."
    if sudo apt remove -y -qq gh; then
        print_success "GitHub CLI desinstalado"
        log_message "GitHub CLI desinstalado"
        # Limpiar repositorio de GitHub CLI
        sudo rm -f /etc/apt/sources.list.d/github-cli.list
        sudo rm -f /usr/share/keyrings/githubcli-archive-keyring.gpg
    else
        print_warning "Error al desinstalar GitHub CLI"
    fi
}

uninstall_python() {
    if ! command_exists python3; then
        print_warning "Python3 no está instalado"
        return 0
    fi
    
    print_info "Desinstalando Python 3..."
    if sudo apt remove -y -qq python3 python3-pip python3-venv; then
        print_success "Python 3 desinstalado"
        log_message "Python 3 desinstalado"
    else
        print_warning "Error al desinstalar Python 3"
    fi
}

uninstall_nodejs() {
    if ! command_exists node; then
        print_warning "Node.js no está instalado"
        return 0
    fi
    
    print_info "Desinstalando Node.js..."
    if sudo apt remove -y -qq nodejs; then
        print_success "Node.js desinstalado"
        log_message "Node.js desinstalado"
        # Limpiar repositorio de NodeSource
        sudo rm -f /etc/apt/sources.list.d/nodesource.list
    else
        print_warning "Error al desinstalar Node.js"
    fi
}

uninstall_lua() {
    if ! command_exists lua; then
        print_warning "Lua no está instalado"
        return 0
    fi
    
    print_info "Desinstalando Lua..."
    if sudo apt remove -y -qq lua5.4; then
        print_success "Lua desinstalado"
        log_message "Lua desinstalado"
    else
        print_warning "Error al desinstalar Lua"
    fi
}

uninstall_typescript() {
    if ! command_exists tsc; then
        print_warning "TypeScript no está instalado"
        return 0
    fi
    
    print_info "Desinstalando TypeScript..."
    if sudo npm uninstall -g typescript >/dev/null 2>&1; then
        print_success "TypeScript desinstalado"
        log_message "TypeScript desinstalado"
    else
        print_warning "Error al desinstalar TypeScript"
    fi
}

uninstall_all() {
    print_header "DESINSTALACIÓN COMPLETA"
    print_warning "ADVERTENCIA: Esto desinstalará TODOS los paquetes y herramientas"
    echo ""
    
    if ! confirm "¿Estás COMPLETAMENTE seguro de que deseas continuar?"; then
        print_info "Desinstalación cancelada"
        return
    fi
    
    echo ""
    print_info "Iniciando desinstalación completa..."
    
    uninstall_vscode_extensions_cleanup
    uninstall_firefox
    uninstall_git
    uninstall_vscode
    uninstall_github_cli
    uninstall_python
    uninstall_nodejs
    uninstall_lua
    uninstall_typescript
    uninstall_build_tools
    
    echo ""
    print_header "LIMPIEZA FINAL"
    
    # Limpiar repositorios agregados
    print_info "Limpiando repositorios adicionales..."
    sudo rm -f /etc/apt/sources.list.d/mozilla.list
    sudo rm -f /etc/apt/sources.list.d/vscode.list
    sudo rm -f /etc/apt/sources.list.d/github-cli.list
    sudo rm -f /etc/apt/sources.list.d/nodesource.list
    sudo rm -f /usr/share/keyrings/mozilla-*.asc
    sudo rm -f /usr/share/keyrings/microsoft-*.gpg
    sudo rm -f /usr/share/keyrings/githubcli-*.gpg
    print_success "Repositorios removidos"
    
    # Actualizar índices
    print_info "Actualizando índices de paquetes..."
    sudo apt update -qq >/dev/null 2>&1
    
    # Limpiar paquetes no necesarios
    print_info "Limpiando paquetes no necesarios..."
    sudo apt autoremove -y -qq >/dev/null 2>&1
    sudo apt autoclean -qq >/dev/null 2>&1
    
    print_success "Desinstalación completa finalizada"
    log_message "=== DESINSTALACIÓN COMPLETA FINALIZADA ==="
}

uninstall_build_tools() {
    print_info "Desinstalando herramientas de compilación..."
    if sudo apt remove -y -qq build-essential curl wget git-lfs gnome-keyring; then
        print_success "Herramientas de compilación desinstaladas"
        log_message "Build-tools desinstalados"
    else
        print_warning "Error al desinstalar herramientas de compilación"
    fi
}

uninstall_vscode_extensions_cleanup() {
    if command_exists code; then
        print_info "Limpiando extensiones de VS Code..."
        # Las extensiones se borran automáticamente con VS Code
        print_success "Extensiones limpiadas"
    fi
}

################################################################################
# MENÚ INTERACTIVO PRINCIPAL
################################################################################

main_menu() {
    clear
    print_header "CONFIGURADOR DE ENTORNO DE DESARROLLO DEBIAN 12"
    
    echo "Este script configurará tu entorno para:"
    echo "  • Firefox + Git + Visual Studio Code"
    echo "  • Lenguajes: Python, Node.js, Lua, TypeScript"
    echo "  • Integración con GitHub y GitHub Copilot"
    echo ""
    
    if ! confirm "¿Deseas continuar?"; then
        print_info "Script cancelado"
        exit 0
    fi
    
    # Verificar permisos sudo
    print_info "Verificando permisos de sudo..."
    if ! sudo -n true 2>/dev/null; then
        if ! sudo -v 2>/dev/null; then
            echo ""
            print_error "No tienes permisos de sudo configurados"
            echo ""
            print_info "SOLUCIÓN: Necesita ejecutar primero como root:"
            echo ""
            echo -e "${YELLOW}  su root${NC}"
            echo -e "${YELLOW}  /home/sysadmin/Desktop/ShellScript/setup_sudoers.sh${NC}"
            echo ""
            print_info "O en una línea:"
            echo ""
            echo -e "${YELLOW}  su -c '/home/sysadmin/Desktop/ShellScript/setup_sudoers.sh'${NC}"
            echo ""
            print_warning "Luego podrás ejecutar este script normalmente"
            exit 1
        fi
    fi
    
    # Menú de selección
    print_header "SELECCIONA LO QUE DESEAS INSTALAR"
    
    echo "═══ INSTALACIÓN =══"
    echo "1) Actualizar sistema (apt update + upgrade)"
    echo "2) Instalar herramientas base (build-tools, curl, wget, etc.)"
    echo "3) Instalar Firefox"
    echo "4) Instalar Git"
    echo "5) Instalar Visual Studio Code"
    echo "6) Instalar GitHub CLI"
    echo "7) Instalar Python 3 + pip"
    echo "8) Instalar Node.js + npm"
    echo "9) Instalar Lua"
    echo "10) Instalar TypeScript"
    echo "11) Configurar GitHub (SSH + usuario)"
    echo "12) Crear/preparar repositorio Development"
    echo "13) Instalar extensiones de VS Code"
    echo "14) INSTALAR TODO (opción rápida)"
    echo ""
    echo "═══ DESINSTALACIÓN (para pruebas) =══"
    echo "15) Desinstalar Firefox"
    echo "16) Desinstalar VS Code"
    echo "17) Desinstalar TODOS los paquetes (para limpiar VM)"
    echo ""
    echo "═══ CONTROL =══"
    echo "0) Salir"
    echo ""
    
    local choice
    while true; do
        read -p "$(echo -e ${CYAN}Selecciona opción:${NC}) " choice
        
        case $choice in
            1) update_system ;;
            2) install_build_tools ;;
            3) install_firefox ;;
            4) install_git ;;
            5) install_vscode ;;
            6) install_github_cli ;;
            7) install_python ;;
            8) install_nodejs ;;
            9) install_lua ;;
            10) install_typescript ;;
            11) configure_github ;;
            12) setup_development_repo ;;
            13) install_vscode_extensions ;;
            14) install_all ;;
            15) uninstall_firefox ;;
            16) uninstall_vscode ;;
            17) uninstall_all ;;
            0) 
                print_success "Script finalizado"
                show_summary
                exit 0
                ;;
            *)
                print_warning "Opción no válida"
                ;;
        esac
        
        echo ""
        if ! confirm "¿Deseas continuar en el menú?"; then
            print_success "Script finalizado"
            show_summary
            exit 0
        fi
        echo ""
        main_menu
        break
    done
}

install_all() {
    print_header "INSTALACIÓN COMPLETA"
    print_warning "Se instalarán todas las herramientas y lenguajes"
    
    if ! confirm "¿Estás seguro?"; then
        print_info "Instalación cancelada"
        return
    fi
    
    update_system
    install_build_tools
    install_firefox
    install_git
    install_vscode
    install_github_cli
    install_python
    install_nodejs
    install_lua
    install_typescript
    configure_github
    setup_development_repo
    install_vscode_extensions
    
    print_success "Instalación completa finalizada"
}

show_summary() {
    print_header "RESUMEN DE INSTALACIÓN"
    
    echo "Herramientas instaladas:"
    command_exists firefox && echo "  ✓ Firefox $(firefox --version 2>/dev/null || '')" || echo "  ✗ Firefox"
    command_exists git && echo "  ✓ Git $(git --version)" || echo "  ✗ Git"
    command_exists code && echo "  ✓ Visual Studio Code" || echo "  ✗ Visual Studio Code"
    command_exists gh && echo "  ✓ GitHub CLI" || echo "  ✗ GitHub CLI"
    
    echo ""
    echo "Lenguajes instalados:"
    command_exists python3 && echo "  ✓ Python $(python3 --version)" || echo "  ✗ Python"
    command_exists node && echo "  ✓ Node.js $(node --version)" || echo "  ✗ Node.js"
    command_exists lua && echo "  ✓ Lua" || echo "  ✗ Lua"
    command_exists tsc && echo "  ✓ TypeScript" || echo "  ✗ TypeScript"
    
    echo ""
    echo "Repositorios:"
    [[ -d "$HOME/Development/.git" ]] && echo "  ✓ Development repo" || echo "  ✗ Development repo"
    
    echo ""
    print_info "Log guardado en: $LOG_FILE"
}

################################################################################
# ENTRADA PRINCIPAL
################################################################################

# Inicializar log
{
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║     INICIO DE CONFIGURACIÓN DE DESARROLLO DEBIAN 12       ║"
    echo "║     Iniciado: $START_TIME                         ║"
    echo "╚════════════════════════════════════════════════════════════╝"
} > "$LOG_FILE"

# Verificar sudo y posiblemente configurar sudoers si se ejecuta como root
ensure_sudo_available

# Ejecutar menú principal
main_menu
