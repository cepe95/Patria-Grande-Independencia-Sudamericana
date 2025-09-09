# Sistema de Reclutamiento Contextual

## Descripción
El sistema de reclutamiento contextual permite reclutar unidades solo cuando una división del jugador está ubicada exactamente en un pueblo en el mapa estratégico.

## Características Implementadas

### 1. Detección de Posición
- **Rango de Reclutamiento**: 50 unidades (más estricto que el rango de captura de 100 unidades)
- **Detección Automática**: El sistema detecta automáticamente cuando una división entra o sale de un pueblo
- **Señales**: Se emiten señales `division_en_pueblo` y `division_sale_pueblo` para comunicación entre componentes

### 2. Interfaz de Usuario
- **Botón Contextual**: Aparece un botón "Reclutar en [Nombre del Pueblo]" en el DetailsPanel cuando:
  - Una división está seleccionada
  - La división está dentro del rango de reclutamiento de un pueblo
- **Ocultamiento Automático**: El botón se oculta automáticamente cuando la división se mueve fuera del pueblo

### 3. Menú de Reclutamiento
- **Diálogo Modal**: Al hacer clic en "Reclutar Unidades" se abre un diálogo con las unidades disponibles
- **Unidades por Tipo de Pueblo**:
  - **Villas**: Solo Pelotón de Infantería
  - **Ciudades Medianas**: Pelotón y Compañía de Infantería
  - **Ciudades Grandes**: Compañía, Batallón de Infantería y Escuadrón de Caballería
  - **Capitales**: Todas las unidades disponibles
- **Información Detallada**: Cada unidad muestra nombre, tamaño e icono

### 4. Mecánicas de Reclutamiento
- **Adición a División**: Las unidades reclutadas se agregan automáticamente a la división
- **Actualización de Estadísticas**: Se actualiza la cantidad total de la división
- **Valores Iniciales**: Las unidades reclutadas reciben moral inicial (50) y experiencia inicial (0)
- **Registro de Eventos**: Se registra cada reclutamiento en el log de eventos

## Cómo Usar el Sistema

### 1. Movimiento de Divisiones
- **Click Izquierdo**: Seleccionar una división
- **Click Derecho**: Mover la división seleccionada al punto clickeado

### 2. Reclutamiento
1. Selecciona una división (click izquierdo)
2. Mueve la división cerca de un pueblo (click derecho)
3. Cuando la división esté en rango, aparecerá el botón "Reclutar en [Pueblo]" en el panel de detalles
4. Haz click en el botón para abrir el menú de reclutamiento
5. Selecciona la unidad deseada y haz click en "Reclutar"
6. La unidad se agregará automáticamente a tu división

### 3. Pueblos de Prueba
El sistema incluye tres pueblos de prueba:
- **Villa Independencia** (cerca de división patriota): Villa con reclutamiento básico
- **Ciudad Real** (cerca de división realista): Ciudad mediana con más opciones
- **Capital del Virreinato** (centro del mapa): Capital con todas las unidades disponibles

## Estructura Técnica

### Clases Modificadas
- **TownInstance.gd**: Detección de divisiones y señalización
- **StrategicMap.gd**: Gestión de señales y creación de pueblos de prueba
- **MainHUD.gd**: Interfaz de reclutamiento y diálogos
- **UnitData.gd**: Campos de moral y experiencia agregados

### Señales Implementadas
- `division_en_pueblo(division, town)`: Emitida cuando una división llega al rango de reclutamiento
- `division_sale_pueblo(division, town)`: Emitida cuando una división sale del rango

### Grupos de Nodos
- **"unidades"**: Divisiones para detección por pueblos
- **"towns"**: Pueblos para búsqueda de señales

## Expansiones Futuras

### Posibles Mejoras
1. **Costos de Reclutamiento**: Implementar costo en recursos/dinero
2. **Tiempo de Reclutamiento**: Agregar turnos de espera para reclutamiento
3. **Límites de Manpower**: Basar reclutamiento en manpower del pueblo
4. **Unidades Especiales**: Unidades únicas por región/facción
5. **Requisitos de Tecnología**: Unlockear unidades con investigación
6. **Experiencia de Oficiales**: Requerir oficiales para unidades avanzadas

### Integración Adicional
- **Sistema de Economía**: Conectar con recursos del juego
- **Sistema de Turnos**: Integrar con mecánicas de turno
- **IA**: Permitir que la IA también reclute usando este sistema
- **Multijugador**: Soporte para reclutamiento en partidas multijugador

## Notas de Desarrollo
- El sistema sigue las convenciones modulares del repositorio
- Todas las funciones incluyen documentación
- Se mantiene compatibilidad con el código existente
- El sistema es fácilmente extensible para nuevas funcionalidades