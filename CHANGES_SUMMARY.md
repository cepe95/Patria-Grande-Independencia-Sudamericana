# Resumen de Cambios - Sistema de Guardado y Carga

## Nuevos Atajos de Teclado

### En el Juego (MainHUD)
- **F5**: Guardar partida rápidamente
- **F9**: Abrir menú de carga de partidas
- **Ctrl+S**: Guardar partida (atajo alternativo)
- **ESC**: Pausar juego (ya existía)

### En el Menú de Pausa
- **F5**: Guardar partida desde pausa
- **F9**: Cargar partida desde pausa
- **ESC**: Continuar juego

### En el Menú de Carga
- **Enter**: Cargar partida seleccionada
- **ESC**: Cancelar carga

## Nuevos Elementos de UI

### Menú Principal (MainMenu)
- **Botón "Cargar Partida"**: Mejorado para mostrar mensaje si no hay partidas guardadas
- **Integración**: Conecta directamente con el sistema de carga

### Menú de Pausa (PauseMenuUI) - NUEVO DISEÑO COMPLETO
- **"Continuar"**: Reanuda el juego
- **"Guardar Partida"**: Guarda el estado actual
- **"Cargar Partida"**: Abre el menú de selección de partidas
- **"Configuración"**: Placeholder para futuras opciones
- **"Salir al Menú Principal"**: Con confirmación para evitar pérdida de datos

### Menú de Carga (LoadGameUI) - COMPLETAMENTE NUEVO
- **Lista de partidas**: Muestra todas las partidas guardadas
- **Información detallada**: Nombre, turno, fecha de guardado, tamaño de archivo
- **Selección visual**: Resalta la partida seleccionada
- **Botones de acción**:
  - "Actualizar": Refresca la lista
  - "Eliminar": Borra la partida seleccionada (con confirmación)
  - "Cargar": Carga la partida seleccionada
  - "Cancelar": Cierra el menú
- **Mensaje sin partidas**: Texto informativo cuando no hay guardados

### MainHUD - Funciones Mejoradas
- **Integración transparente**: Las funciones save_game() y load_game() ahora son completamente funcionales
- **Feedback visual**: Mensajes en el log de eventos para todas las operaciones
- **Error handling**: Manejo robusto de errores con mensajes descriptivos

## Ubicación de Archivos de Guardado

```
user://saves/
├── save_20241209_143022.save
├── save_20241209_150315.save
└── save_20241209_152147.save
```

## Flujo de Usuario

### Guardar Partida
1. Durante el juego: F5 o ESC → "Guardar Partida"
2. El sistema genera automáticamente un nombre único
3. Confirmación en el log de eventos

### Cargar Partida desde Menú Principal
1. Clic en "Cargar Partida"
2. Si no hay partidas: mensaje informativo
3. Si hay partidas: abre el menú de selección
4. Seleccionar partida y hacer clic en "Cargar"
5. El juego se carga directamente en el estado guardado

### Cargar Partida durante el Juego
1. ESC → "Cargar Partida" o F9
2. Misma interfaz que desde el menú principal
3. Advierte sobre pérdida de progreso no guardado

## Características Técnicas

- **Formato**: Archivos .save usando ResourceSaver/ResourceLoader de Godot
- **Datos guardados**: Turno, recursos, ciudades, unidades, eventos, selecciones
- **Límite**: Máximo 50 archivos (limpieza automática)
- **Compresión**: Archivos binarios optimizados de Godot
- **Validación**: Verificación de integridad al cargar
- **Versionado**: Sistema de versiones para compatibilidad futura