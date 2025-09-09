# Sistema de Guardado y Carga - Patria Grande: Independencia Sudamericana

## Descripción General

El sistema de guardado y carga permite a los jugadores preservar el estado de sus partidas y reanudarlas posteriormente. Está diseñado siguiendo las mejores prácticas de Godot y es extensible para futuras mejoras.

## Componentes Principales

### 1. GameState (Scripts/Data/GameState.gd)
Clase Resource que contiene todos los datos necesarios para guardar/cargar una partida:
- **Datos básicos**: turno actual, recursos, selecciones
- **Datos de ciudades**: información de todas las ciudades
- **Datos de unidades**: información de todas las unidades militares
- **Datos de facciones**: estado de cada facción
- **Log de eventos**: historial para preservar la narrativa

### 2. SaveLoadManager (Scripts/Manager/SaveLoadManager.gd)
Gestor centralizado que maneja todas las operaciones de guardado y carga:
- **Guardado**: Usa `ResourceSaver` para guardar GameState en `user://saves/`
- **Carga**: Usa `ResourceLoader` para cargar archivos .save
- **Gestión**: Lista, elimina y organiza archivos de guardado
- **Señales**: Emite eventos para notificar el estado de las operaciones

### 3. LoadGameUI (Scripts/UI/LoadGameUI.gd)
Interfaz de usuario para seleccionar y cargar partidas guardadas:
- **Lista archivos**: Muestra partidas disponibles con metadatos
- **Selección**: Permite elegir qué partida cargar
- **Eliminación**: Opción para borrar partidas no deseadas
- **Feedback**: Mensajes de éxito/error

### 4. PauseMenuUI (Scripts/UI/PauseMenuUI.gd)
Menú de pausa mejorado con opciones de guardado y carga:
- **Guardar**: Acceso rápido para guardar la partida actual
- **Cargar**: Abre el menú de carga de partidas
- **Atajos**: F5 para guardar, F9 para cargar

## Integración con MainHUD

El MainHUD ha sido actualizado para trabajar con el sistema:

```gdscript
# Guardar partida
func save_game():
    var save_manager = get_save_load_manager()
    var game_state = GameState.new()
    game_state.set_from_main_hud(self)
    save_manager.save_game(game_state)

# Cargar partida
func load_game(filename: String = ""):
    if filename.is_empty():
        show_load_game_menu()
    else:
        var save_manager = get_save_load_manager()
        var game_state = save_manager.load_game(filename)
        apply_loaded_game_state(game_state)
```

## Ubicación de Archivos

Los archivos de guardado se almacenan en:
- **Ruta**: `user://saves/`
- **Formato**: `.save` (archivos de resource de Godot)
- **Nomenclatura**: `save_YYYYMMDD_HHMMSS.save`

## Uso para Jugadores

### Guardar Partida
1. **Desde pausa**: Presionar ESC → "Guardar Partida" o F5
2. **Automático**: El sistema genera nombres únicos por fecha

### Cargar Partida
1. **Menú principal**: Botón "Cargar Partida" (solo si hay guardados)
2. **Durante juego**: ESC → "Cargar Partida" o F9
3. **Selección**: Lista con nombre, turno, fecha y tamaño

## Personalización para Modders

### Extender GameState
```gdscript
# Agregar nuevos datos a guardar
extends GameState

@export var custom_data: Dictionary = {}

func set_from_main_hud(main_hud: Control):
    super.set_from_main_hud(main_hud)
    # Agregar datos personalizados
    custom_data = main_hud.get_custom_data()
```

### Conectar señales del SaveLoadManager
```gdscript
SaveLoadManager.save_completed.connect(_on_save_completed)
SaveLoadManager.load_completed.connect(_on_load_completed)

func _on_save_completed(success: bool, message: String):
    if success:
        show_notification("Guardado exitoso")
    else:
        show_error("Error: " + message)
```

### Personalizar UI de carga
```gdscript
# Extender LoadGameUI para agregar filtros o información adicional
extends LoadGameUI

func create_save_entry(save_file: Dictionary, index: int) -> Control:
    var entry = super.create_save_entry(save_file, index)
    # Agregar información personalizada
    add_custom_info(entry, save_file)
    return entry
```

## Convenciones y Mejores Prácticas

1. **Datos serializables**: Solo guardar datos que Godot puede serializar automáticamente
2. **Referencias por ID**: No guardar referencias directas a nodos, usar IDs únicos
3. **Versionado**: Usar `GameState.version` para compatibilidad hacia atrás
4. **Validación**: Verificar integridad de datos al cargar
5. **Límites**: El sistema limpia automáticamente archivos antiguos (máx. 50)

## Solución de Problemas

### Error "No se pudo crear directorio de guardado"
- Verificar permisos de escritura en el directorio user://
- Asegurar que Godot tenga acceso al sistema de archivos

### Error "Archivo de guardado corrupto"
- El archivo puede estar dañado o ser de una versión incompatible
- Eliminar el archivo problemático desde el menú de carga

### La lista de partidas no se actualiza
- Usar el botón "Actualizar" en el menú de carga
- Verificar que el SaveLoadManager esté correctamente autoloaded

## Futuras Mejoras

- **Guardado automático**: Implementar guardado automático cada cierto tiempo
- **Múltiples slots**: Sistema de slots de guardado nombrados por el usuario
- **Compresión**: Comprimir archivos de guardado para ahorrar espacio
- **Metadatos extendidos**: Capturas de pantalla, estadísticas de la partida
- **Guardado en la nube**: Integración con servicios de almacenamiento online