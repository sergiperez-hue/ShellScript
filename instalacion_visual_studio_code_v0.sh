#!/bin/bash

################################################################################
#                   DESARROLLO ENVIRONMENT SETUP DEBIAN 12
#          Script interactivo para configurar entorno de desarrollo
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
        print_warning "Firefox ya está instalado"
        return 0
    fi
    
    print_info "Instalando Firefox..."
    if sudo apt install -y -qq firefox; then
        FIREFOX_VERSION=$(firefox --version 2>/dev/null || echo "Versión desconocida")
        print_success "Firefox instalado: $FIREFOX_VERSION"
        log_message "Firefox instalado"
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
        print_warning "VS Code ya está instalado"
        return 0
    fi
    
    print_info "Instalando Visual Studio Code..."
    if sudo apt install -y -qq wget; then
        wget -q https://packages.microsoft.com/keys/microsoft.asc -O- | sudo apt-key add - >/dev/null 2>&1
        echo "deb [arch=amd64,arm64,armhf signed-by=/usr/share/keyrings/microsoft-archive-keyring.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list >/dev/null
        sudo apt update -qq
        if sudo apt install -y -qq code; then
            print_success "Visual Studio Code instalado"
            log_message "VS Code instalado"
        else
            print_error "Error al instalar VS Code"
            return 1
        fi
    else
        print_error "Error al instalar dependencias de VS Code"
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

# Ejecutar menú principal
main_menu
