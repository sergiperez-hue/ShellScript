# GUÍA DE TESTING - v0.0.4

## 🧪 Ciclo de Prueba Instalación/Desinstalación

Versión 0.0.4 incluye mejoras críticas en estabilidad del sistema y confiabilidad de instalación.

### 📋 Funciones de Desinstalación Disponibles

| Opción | Función | Limpia |
|--------|---------|--------|
| **15** | `Desinstalar Firefox` | Firefox + repos Mozilla |
| **16** | `Desinstalar VS Code` | VS Code + repos Microsoft |
| **17** | `Desinstalar TODOS los paquetes` | TODO completo + repos |

### 🔄 Flujo de Testing Recomendado

#### Paso 1: Instalar todo (opción 14)
```bash
./1_instalacion_entorno_desarrollo.0.0.4.sh
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
./1_instalacion_entorno_desarrollo.0.0.4.sh
# Selecciona: 17
# Confirma 2 veces (doble verificación de seguridad)
# Espera limpieza completa...
```

#### Paso 4: Verificar limpieza Y estabilidad del sistema
```bash
# Verificar que las aplicaciones se desinstalaron
firefox --version     # No debería existir
code --version        # No debería existir
git --version         # No debería existir
python3 --version     # No debería existir
node --version        # No debería existir
lua -v                # No debería existir
tsc --version         # No debería existir

# Verificar que GNOME sigue funcionando
startx                # DEBE funcionar correctamente
# O verificar que el entorno gráfico arranca

# Verificar repos limpios
ls /etc/apt/sources.list.d/   # Debería estar casi vacío
```

### ⚙️ Funciones de Desinstalación Individual

Puedes también desinstalar piezas específicas:

| Opción | Desinstala |
|--------|-----------|
| **15** | Firefox solamente |
| **16** | VS Code solamente |

### 🛡️ Seguridad Mejorada v0.0.4

- **Doble confirmación** en `uninstall_all()` para evitar accidentes
- **Protección GNOME**: `gnome-keyring` NO se desinstala (evita que `startx` falle)
- **Firefox oficial**: Instalación desde repositorio Mozilla certificado con GPG
- Mensajes de validación clara antes de cada desinstalación
- Limpieza automática de repositorios agregados
- `apt autoremove` y `apt autoclean` al finalizar

### 📊 Qué Limpia `uninstall_all()` (v0.0.4)

```
✓ Firefox (desde repos oficial Mozilla)
✓ Git
✓ Visual Studio Code + repositorio Microsoft
✓ GitHub CLI + repositorio CLI
✓ Python 3 + pip + venv
✓ Node.js + npm + repositorio NodeSource
✓ Lua
✓ TypeScript
✓ Build essentials y herramientas (EXCEPTO gnome-keyring)
✓ Repositorio Mozilla
✓ Todas las claves GPG agregadas
✓ Limpieza de paquetes no necesarios
```

### 🔧 Mejoras Críticas v0.0.4

#### Firefox - Instalación Confiable
- ✅ Descarga clave GPG oficial de Mozilla
- ✅ Verificación de fingerprint: `35BAA0B33E9EB396F59CA838C0BA5CE6DC6315A3`
- ✅ Configuración de repositorio con firma digital
- ✅ Prioridad APT correcta para paquetes Mozilla

#### Desinstalación - Estabilidad GNOME
- ✅ **PROTEGIDO**: `gnome-keyring` no se desinstala
- ✅ **RESUELTO**: GNOME arranca correctamente después de desinstalar/reinstalar
- ✅ **RESULTADO**: `startx` funciona tras ciclos de limpieza
- ✅ Desinstalación segura para entornos VM

### 🚀 Optimizaciones Futuras

- [ ] Crear snapshots de VM para comparación pre/post
- [ ] Incluir opciones de desinstalación selectiva
- [ ] Validar checksums post-desinstalación
- [ ] Reportes de espacio en disco liberado
- [ ] Verificación automática de estabilidad GNOME post-desinstalación

### ⚠️ IMPORTANTE

**NO EJECUTAR EN MÁQUINA DE PRODUCCIÓN**

Esta versión está diseñada para:
- ✓ Máquinas virtuales de prueba
- ✓ Laboratorios de desarrollo
- ✓ Testing en snapshots/respaldos

**NUEVO EN v0.0.4**: La desinstalación completa ya NO desestabiliza GNOME. Puedes hacer ciclos de instalación/desinstalación sin perder la capacidad de iniciar el entorno gráfico.

---

**Versión**: 0.0.4  
**Fecha**: 2026-03-27  
**Autor**: sysadmin  
