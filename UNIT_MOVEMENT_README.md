# Sistema de Movimiento de Unidades - Patria Grande

## Funcionalidades Implementadas

### 1. Movimiento de Unidades por Arrastre
- **Selección**: Clic izquierdo en una unidad para seleccionarla
- **Arrastre**: Mantener presionado y arrastrar para mover la unidad
- **Validación**: El sistema valida automáticamente posiciones válidas
- **Feedback Visual**: Indicadores visuales muestran área de movimiento y validez

### 2. Panel de Detalles Dinámico
- **Integración**: DetailsPanel unificado que integra DivisionPanel
- **Información Completa**: Muestra estadísticas, composición y estado de la unidad
- **Actualización Automática**: Se actualiza al seleccionar cualquier unidad

### 3. Sistema de Señales para Acciones Futuras
- **Señales Implementadas**: 
  - `division_seleccionada(division)`: Cuando se selecciona una unidad
  - `division_movida(division, nueva_posicion)`: Cuando se mueve una unidad
  - `solicitar_accion(division, tipo_accion)`: Para acciones futuras
- **Acciones Preparadas**: Atacar, fortificar, explorar (clic derecho)

### 4. Validación de Movimiento
- **Límites del Mapa**: Las unidades no pueden salir de los límites definidos
- **Colisiones**: Previene que las unidades se superpongan
- **Rango de Movimiento**: Basado en la movilidad de cada unidad

## Archivos Modificados

### Scripts/Strategic/DivisionInstance.gd
- Implementado sistema de arrastre y colocación
- Añadidos indicadores visuales de movimiento
- Sistema de validación de posiciones
- Preparación para acciones futuras

### Scripts/Strategic/StrategicMap.gd
- Validación de posiciones y colisiones
- Manejo de señales de movimiento
- Métodos auxiliares para gestión de unidades

### Scripts/UI/MainHUD.gd
- Integración con el nuevo DetailsPanel
- Manejo mejorado de selección de unidades

### Scripts/UI/DetailsPanel.gd (NUEVO)
- Panel unificado que integra DivisionPanel
- Muestra información completa de las divisiones
- Sistema de fallback para compatibilidad

### Scripts/Data/DivisionData.gd
- Campos adicionales para información detallada
- Soporte para comandantes y historial

### Scripts/Data/UnitData.gd
- Campos de moral y experiencia añadidos

## Cómo Usar

1. **Seleccionar Unidad**: Clic izquierdo en cualquier división del mapa
2. **Ver Detalles**: El panel de detalles se abre automáticamente
3. **Mover Unidad**: Arrastrar la unidad seleccionada a una nueva posición
4. **Acciones Futuras**: Clic derecho en unidad seleccionada (preparado para expansión)

## Indicadores Visuales

- **Azul**: Unidad seleccionada
- **Verde**: Posición válida para movimiento
- **Rojo**: Posición inválida
- **Área de Movimiento**: Círculo que muestra el rango máximo de movimiento

## Expansiones Futuras

El sistema está preparado para:
- Combate entre unidades
- Fortificación de posiciones
- Exploración de territorio
- Gestión de suministros
- Diplomacia entre facciones

## Estructura Modular

El código sigue las convenciones del repositorio:
- **Scenes/Strategic**: Lógica del mapa y unidades
- **Scenes/UI**: Interfaces de usuario
- **Scripts/Data**: Clases de datos
- **Scripts/UI**: Lógica de interfaz
- **Scripts/Strategic**: Lógica estratégica