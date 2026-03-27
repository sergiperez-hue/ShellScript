#!/bin/bash
# QUICK START - Setup Desarrollo Debian 12

echo "
╔════════════════════════════════════════════════════════════════╗
║                   QUICK START v0.0.2                          ║
║          Setup de Desarrollo Debian 12 con GNOME              ║
╚════════════════════════════════════════════════════════════════╝
"

SCRIPT_PATH="/home/sysadmin/Desktop/ShellScript/1_instalacion_entorno_desarrollo.0.0.2.sh"

if [[ ! -f "$SCRIPT_PATH" ]]; then
    echo "❌ Script no encontrado en: $SCRIPT_PATH"
    exit 1
fi

echo "📋 Opciones disponibles:"
echo ""
echo "1️⃣  Instalar TODOS los paquetes (recomendado)"
echo "2️⃣  Abrir menú interactivo"
echo "3️⃣  Desinstalar TODOS (limpiar y resetear VM)"
echo "4️⃣  Ver documentación (README.md)"
echo "5️⃣  Ver guía de testing (TESTING.md)"
echo "0️⃣  Salir"
echo ""

read -p "Selecciona opción: " choice

case $choice in
    1)
        echo ""
        echo "Iniciando instalación completa..."
        sleep 2
        exec bash -c "echo '14' | $SCRIPT_PATH"
        ;;
    2)
        echo ""
        echo "Abriendo menú interactivo..."
        sleep 1
        exec "$SCRIPT_PATH"
        ;;
    3)
        echo ""
        echo "⚠️  ADVERTENCIA: Se desinstalarán TODOS los paquetes"
        echo ""
        read -p "¿Estás seguro? (s/n): " confirm
        if [[ "$confirm" =~ ^[sS]$ ]]; then
            echo ""
            echo "Iniciando desinstalación..."
            sleep 2
            exec bash -c "echo -e '17\\ny\\ny' | $SCRIPT_PATH"
        else
            echo "Cancelado."
        fi
        ;;
    4)
        echo ""
        echo "Abriendo README.md..."
        sleep 1
        less /home/sysadmin/Desktop/ShellScript/README.md
        ;;
    5)
        echo ""
        echo "Abriendo TESTING.md..."
        sleep 1
        less /home/sysadmin/Desktop/ShellScript/TESTING.md
        ;;
    0)
        echo "Saliendo..."
        exit 0
        ;;
    *)
        echo "❌ Opción no válida"
        exit 1
        ;;
esac
