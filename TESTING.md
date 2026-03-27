# GUÍA DE TESTING - v0.0.2

## 🧪 Ciclo de Prueba Instalación/Desinstalación

Versión 0.0.2 incluye funcionalidad completa para pruebas de limpieza en máquinas virtuales.

### 📋 Funciones de Desinstalación Disponibles

| Opción | Función | Limpia |
|--------|---------|--------|
| **15** | `Desinstalar Firefox` | Firefox + repos Mozilla |
| **16** | `Desinstalar VS Code` | VS Code + repos Microsoft |
| **17** | `Desinstalar TODOS los paquetes` | TODO completo + repos |

### 🔄 Flujo de Testing Recomendado

#### Paso 1: Instalar todo (opción 14)
```bash
./1_instalacion_entorno_desarrollo.0.0.2.sh
# Selecciona: 14
# Espera a que complete...
```

#### Paso 2: Verificar instalación
```bash
firefox --version
code --version
git --version
python3 --version
node --version
lua -v
tsc --version
```

#### Paso 3: Desinstalar TODO (opción 17)
```bash
./1_instalacion_entorno_desarrollo.0.0.2.sh
# Selecciona: 17
# Confirma 2 veces (doble verificación de seguridad)
# Espera limpieza completa...
```

#### Paso 4: Verificar limpieza
```bash
firefox --version     # No debería existir
code --version        # No debería existir
git --version         # No debería existir
python3 --version     # No debería existir
node --version        # No debería existir
lua -v                # No debería existir
tsc --version         # No debería existir

# Verificar repos limpios
ls /etc/apt/sources.list.d/   # Debería estar casi vacío
```

### ⚙️ Funciones de Desinstalación Individual

Puedes también desinstalar piezas específicas:

| Opción | Desinstala |
|--------|-----------|
| **15** | Firefox solamente |
| **16** | VS Code solamente |

### 🛡️ Seguridad

- **Doble confirmación** en `uninstall_all()` para evitar accidentes
- Mensajes de validación clara antes de cada desinstalación
- Limpieza automática de repositorios agregados
- `apt autoremove` y `apt autoclean` al finalizar

### 📊 Qué Limpia `uninstall_all()`

```
✓ Firebase
✓ Git
✓ Visual Studio Code + repositorio Microsoft
✓ GitHub CLI + repositorio CLI
✓ Python 3 + pip + venv
✓ Node.js + npm + repositorio NodeSource
✓ Lua
✓ TypeScript
✓ Build essentials y herramientas
✓ Repositorio Mozilla
✓ Todas las claves GPG agregadas
✓ Limpieza de paquetes no necesarios
```

### 🚀 Optimizaciones Futuras

- [ ] Crear snapshots de VM para comparación pre/post
- [ ] Incluir opciones de desinstalación selectiva
- [ ] Validar checksums post-desinstalación
- [ ] Reportes de espacio en disco liberado

### ⚠️ IMPORTANTE

**NO EJECUTAR EN MÁQUINA DE PRODUCCIÓN**

Esta versión está diseñada para:
- ✓ Máquinas virtuales de prueba
- ✓ Laboratorios de desarrollo
- ✓ Testing en snapshots/respaldos

---

**Versión**: 0.0.2  
**Fecha**: 2026-03-27  
**Autor**: sysadmin  
