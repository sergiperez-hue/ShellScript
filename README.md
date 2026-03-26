# 🚀 Setup Desarrollo Debian 12

Script interactivo para configurar un entorno completo de desarrollo en Debian 12 con GNOME.

## 📋 Contenido

- **1_instalacion_entorno_desarrollo.sh** → Script unificado (root o sysadmin)
- **setup_sudoers.sh** → Legacy / auxiliar (opcional)
- **instalacion_visual_studio_code_v0.sh** → Legacy / versión anterior de menú
- **README.md** → Este archivo

---

## 🔐 Paso 1: Configurar Sudoers (IMPORTANTE - Solo una vez)

Si el usuario `sysadmin` no está en sudoers, ejecuta este script como root:

### Opción A: Usando `su` con contraseña root
```bash
su -c '/home/sysadmin/Desktop/ShellScript/setup_sudoers.sh'
# Ingresa contraseña de root cuando se pida
```

### Opción B: Cambiar a root y ejecutar
```bash
su root
/home/sysadmin/Desktop/ShellScript/setup_sudoers.sh
exit
```

**✓ Esto agregará a sysadmin en sudoers sin contraseña**

---

## ▶️ Paso 2: Ejecutar Script Principal

Una vez configurado sudoers, ejecuta el script principal como sysadmin:

```bash
/home/sysadmin/Desktop/ShellScript/hola.sh
```

O con antecedentes:
```bash
bash /home/sysadmin/Desktop/ShellScript/hola.sh
```

---

## 📦 Qué Instala

### Herramientas Base
- Firefox (última versión)
- Git
- Visual Studio Code
- GitHub CLI
- Build-essentials, curl, wget, git-lfs
- GNOME Keyring (almacenamiento seguro)

### Lenguajes de Programación
- Python 3 + pip
- Node.js LTS + npm
- Lua 5.4
- TypeScript

### Configuración GitHub
- Genera claves SSH (RSA 4096)
- Configura usuario/email en Git
- Autenticación GitHub CLI
- Repositorio "Development" local y remoto

### Extensiones VS Code
- GitHub Copilot
- GitHub Pull Requests & Issues
- Git Graph
- Python + Pylance
- Prettier & ESLint
- C/C++ Tools
- Lua

---

## 🎯 Menú Principal

Al ejecutar `hola.sh` verás un menú con opciones:

```
1) Actualizar sistema
2) Instalar herramientas base
3) Instalar Firefox
4) Instalar Git
5) Instalar Visual Studio Code
6) Instalar GitHub CLI
7) Instalar Python 3 + pip
8) Instalar Node.js + npm
9) Instalar Lua
10) Instalar TypeScript
11) Configurar GitHub (SSH + usuario)
12) Crear/preparar repositorio Development
13) Instalar extensiones de VS Code
14) INSTALAR TODO (opción rápida)
0) Salir
```

- Selecciona números individuales para instalaciones específicas
- Usa `14` para instalar todo de una vez
- El script detecta si algo ya está instalado

---

## 📊 Verificación

Después de instalar, el script mostrará un resumen con lo que se instaló:

```
✓ Firefox
✓ Git
✓ Visual Studio Code
✓ Python 3.11...
✓ Node.js v18...
```

---

## 📝 Log de Instalación

Todos los eventos se registran en:
```
~/setup_development.log
```

---

## 🔧 Troubleshooting

### Error: "No tienes permisos de sudo"
**Solución**: Ejecuta primero `setup_sudoers.sh` como root

### Error: "Firefox no se puede instalar"
**Solución**: El sistema suele tenarlo en repositorios, intenta manualmente:
```bash
sudo apt install -y firefox
```

### GitHub CLI no se autentica
**Solución**: Ejecuta manualmente después:
```bash
gh auth login
```

### VS Code no instala extensiones
**Solución**: Intenta manualmente:
```bash
code --install-extension <extension-id>
```

---

## ⚙️ Requisitos Previos

- Debian 12 con GNOME
- Conexión a Internet
- Acceso a contraseña de root (solo para setup_sudoers.sh)
- ~2GB libres en disco

---

## 📌 Notas Importantes

- El script es **idempotente**: puede ejecutarse múltiples veces sin problemas
- Detecta automáticamente si las herramientas ya están instaladas
- Use `NOPASSWD` en sudoers (sin contraseña) para mayor comodidad
- El repositorio "Development" se crea en `$HOME/Development`
- Los logs se guardan en `$HOME/setup_development.log`

---

## 🆘 Ayuda

Si algo no funciona:

1. Revisa el log: `cat ~/setup_development.log`
2. Intenta la operación manualmente
3. Verifica conexión a Internet
4. Asegúrate que tienes permisos de sudo: `sudo whoami`

---

**Creado para Debian 12 - Marzo 2026**
