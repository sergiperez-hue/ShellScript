# CHANGELOG - Instalación Entorno Desarrollo

## [0.0.4] - 2026-03-27

### Arreglado
- **Firefox instalación más confiable**: Implementa método oficial de Mozilla
  - Descarga clave GPG desde `https://packages.mozilla.org/apt/repo-signing-key.gpg`
  - Verifica fingerprint: `35BAA0B33E9EB396F59CA838C0BA5CE6DC6315A3`
  - Configura repositorio official con firma digital
  - Establece prioridad APT correcta para paquetes de Mozilla
  - Evita instalación alternativa o desactualizada

- **Desinstalación estable**: Protege integridad del sistema GNOME
  - Elimina `gnome-keyring` de la lista de desinstalación
  - Resuelve problema: GNOME no arranca después de desinstalar/reinstalar
  - Mantiene `startx` funcionando correctamente tras reset de entorno de desarrollo
  - Desinstalación selectiva: solo remueve herramientas de desarrollo, no de sistema

### Mejorado
- Proceso de instalación Firefox más seguro con verificación de GPG
- Desinstalación más segura y predecible en entornos VM
- Comentarios mejorados en código explicando protecciones de GNOME

### Caso de Uso
- Instalación Firefox desde fuente oficial certificada
- Ciclos de instalación/desinstalación en VM sin desestabilizar GNOME
- Reutilización de VM sin necesidad de restauración de snapshots

---

## [0.0.3] - 2026-03-27

### Arreglado
- **VS Code desde .deb oficial**: se utiliza descarga directa
  (https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64)
- Descarga en `/tmp/vscode-linux-x64.deb` y `sudo apt install -y` local
- Añadida segunda tentativa con `sudo apt --fix-broken install` si hay dependencias
- Elimina la dependencia de actualización de índice de `packages.microsoft.com`

### Mejorado
- Entfernung de configuración de repositorio APT Microsoft para minimizar fallos de repos
- Proceso determinista y reproducible en entornos aislados
- Se conservaron funciones de desinstalación y tests VM

---

## [0.0.2] - 2026-03-27

### Agregado
- **Función de Desinstalación Completa**: Nueva sección de desinstalación (opciones 15-17)
- **uninstall_firefox()**: Desinstala Firefox y limpia repositorios
- **uninstall_git()**: Desinstala Git
- **uninstall_vscode()**: Desinstala VS Code y limpia repositorios Microsoft
- **uninstall_github_cli()**: Desinstala GitHub CLI y limpia repositorios
- **uninstall_python()**: Desinstala Python 3 y herramientas
- **uninstall_nodejs()**: Desinstala Node.js y limpia repos NodeSource
- **uninstall_lua()**: Desinstala Lua
- **uninstall_typescript()**: Desinstala TypeScript globalmente
- **uninstall_build_tools()**: Desinstala herramientas de compilación
- **uninstall_all()**: Desinstala TODO con confirmación de seguridad
- Limpiar automático de repositorios y repositorios NO-OFICIALES agregados
- Limpieza de paquetes no necesarios con `apt autoremove`
- **Menú reorganizado**: Secciones de Instalación, Desinstalación y Control

### Caso de Uso
- Perfecto para pruebas de instalación/desinstalación en máquinas virtuales
- Permite resetear VM completamente antes de nuevas pruebas
- Confirmación doble de seguridad en `uninstall_all()`

### Notas
- **IMPORTANTE**: Las opciones de desinstalación están completamente probadas antes de integración
- Todas las desinstalaciones respetan la integridad del sistema
- Se recomienda usar en VM de pruebas, no en sistemas de producción

---

## [0.0.1] - 2026-03-27

### Arreglado
- **Issue #1 - Firefox**: Cambio a instalar desde repositorio oficial de Mozilla para garantizar versión actualizada (firefox-esr)
- **Issue #2 - VS Code**: Configuración correcta de clave GPG usando gpg --dearmor en lugar de apt-key (deprecated en Debian 12)
- Mejor manejo de errores en instalación de VS Code y Firefox

### Mejorado
- Firefox ahora se instala desde repos de Mozilla con actualización automática
- VS Code ahora usa método correcto de verificación de clave GPG compatible con Debian 12
- Mejor logging y mensajes de estado en ambas funciones

---

## [0.0.0] - 2026-03-27

### Agregado
- Script principal consolidado: `1_instalacion_entorno_desarrollo.sh`
- Soporte para ejecución como root (configura sudoers automáticamente)
- Soporte para ejecución como sysadmin (menú interactivo completo)
- Instalación de Firefox (última versión)
- Instalación de Git con SSH key generation
- Instalación de Visual Studio Code desde repo oficial Microsoft
- Instalación de GitHub CLI (gh)
- Instalación de build-essentials y herramientas de desarrollo
- Instalación de Python 3 + pip
- Instalación de Node.js LTS + npm (desde NodeSource)
- Instalación de Lua 5.4
- Instalación de TypeScript global
- Configuración de GitHub (nombre, email, SSH keys)
- Creación de repositorio Development local y remoto
- Instalación de extensiones VS Code (Copilot, Git Graph, Python, etc.)
- Sistema de logging en `~/setup_development.log`
- Menú interactivo con 14 opciones + "Instalar TODO"
- Validaciones en cada paso (detecta si herramientas ya están instaladas)
- Resumen final de instalaciones
- Sistema de versionado en nombre de archivo y cabecera

### Notas
- Primera versión estable
- Validada sintaxis bash
- Arquitectura modular con funciones reutilizables
- Soporta modo root para setup sudoers
- Soporta menú completo para sysadmin

---

## Versionado

### Estructura del Nombre
```
1_instalacion_entorno_desarrollo.{MAJOR}.{MINOR}.{PATCH}.sh
```

- **MAJOR**: Cambios significativos en funcionalidad (1.0.0, 2.0.0)
- **MINOR**: Nuevas características compatibles (0.1.0, 0.2.0)
- **PATCH**: Correcciones de bugs (0.0.1, 0.0.2)

### Archivos de Versión
- `1_instalacion_entorno_desarrollo.sh` → **Rama principal (development)**
- `1_instalacion_entorno_desarrollo.0.0.0.sh` → **Release v0.0.0 (stable)**
- Archivos legacy en carpeta `/Legacy/`

### Cómo Contribuir

1. **Para cambios menores**: Edita `1_instalacion_entorno_desarrollo.sh`
2. **Cuando quieras hacer release**: 
   ```bash
   cp 1_instalacion_entorno_desarrollo.sh 1_instalacion_entorno_desarrollo.X.Y.Z.sh
   ```
3. **Actualiza esta versión en el comentario de cabecera del archivo versionado**
4. **Documenta los cambios en CHANGELOG.md**

---

## Historial de Cambios Planeados

### Próximas Versiones (Propuestas)

#### v0.1.0
- [ ] Menú para seleccionar extensiones VS Code
- [ ] Soporte para Docker instalación opcional
- [ ] Configuración automática de .gitconfig

#### v0.2.0
- [ ] Instalación de IDEs adicionales (PyCharm, WebStorm)
- [ ] Soporte para otros lenguajes (Rust, Go, Java)
- [ ] Backup automático de configuraciones

#### v1.0.0
- [ ] GUI interactiva (Yad/Zenity)
- [ ] Soporte para múltiples sabores de Linux
- [ ] Sistema de perfiles (mínimo, standard, full)

---

**Última Actualización**: 2026-03-27
