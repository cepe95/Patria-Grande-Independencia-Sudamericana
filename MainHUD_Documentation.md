# MainHUD - Interfaz Principal Estratégica

## Descripción
MainHUD es la interfaz principal del juego que integra todos los paneles de la UI estratégica y gestiona la comunicación entre el mapa y los controles de interfaz.

## Estructura Visual

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ RESOURCE BAR (Barra Superior)                                              │
│ Dinero: 1000 | Comida: 500 | Munición: 200     Fecha: 1810-Enero Turno: 1 │
├──────────────┬─────────────────────────────────────────┬───────────────────┤
│ CITY/UNIT    │                                         │ DETAILS PANEL     │
│ LIST PANEL   │                                         │ (Visible solo     │
│ (Izquierda)  │           STRATEGIC MAP                 │ al seleccionar)   │
│              │             (Centro)                    │                   │
│ ┌─Ciudades─┐ │                                         │ Detalles de:      │
│ │Buenos Aires│ │                                         │ - Unidades        │
│ │Córdoba     │ │     [Mapa con unidades/ciudades]       │ - Ciudades        │
│ │Montevideo  │ │                                         │ - Estadísticas    │
│ └──────────┘ │                                         │                   │
│ ┌─Unidades─┐ │                                         │                   │
│ │División 1  │ │                                         │                   │
│ │División 2  │ │                                         │                   │
│ └──────────┘ │                                         │                   │
├──────────────┴─────────────────────────────────────────┴───────────────────┤
│ EVENT PANEL (Panel Inferior)                                               │
│ [Turno 1] Bienvenido a Patria Grande    │ Acciones Rápidas:               │
│ [Turno 1] Consulta el panel de ciudades │ [Siguiente Turno] [Pausar]      │
└─────────────────────────────────────────┴─────────────────────────────────┘
```

## Archivos Implementados

### 1. Scenes/UI/MainHUD.tscn
Escena principal con la estructura completa de la interfaz:
- **MainHUD (Control)**: Nodo raíz principal
  - **StrategicMap**: Instancia del mapa estratégico existente
  - **UI (CanvasLayer)**: Capa de interfaz que contiene todos los paneles
    - **ResourceBar**: Barra superior con recursos y fecha/turno
    - **CityUnitListPanel**: Panel lateral izquierdo con listas tabuladas
    - **DetailsPanel**: Panel lateral derecho (oculto por defecto)
    - **EventPanel**: Panel inferior con eventos y acciones rápidas
    - **PauseMenu**: Menú de pausa integrado (oculto por defecto)

### 2. Scripts/UI/MainHUD.gd
Script principal con toda la lógica de conexión y manejo:

#### Características Principales:
- **Gestión de Referencias**: Acceso a todos los nodos de la interfaz
- **Conexión de Señales**: Conecta automáticamente las señales del mapa estratégico
- **Manejo de Recursos**: Sistema de visualización y actualización de recursos
- **Listas Dinámicas**: Poblado automático de ciudades y unidades
- **Panel de Detalles**: Visualización contextual de información detallada
- **Sistema de Eventos**: Log de eventos con diferentes tipos y colores
- **Atajos de Teclado**: ESPACIO (siguiente turno), ESC (pausar/cerrar)

#### Métodos Públicos para Integración:
```gdscript
refresh_interface()                    # Refresca toda la interfaz
get_selected_unit() -> Node           # Obtiene la unidad seleccionada
get_selected_city() -> String         # Obtiene la ciudad seleccionada
update_resources(new_resources)       # Actualiza recursos desde scripts externos
```

#### Métodos Placeholder para Funcionalidad Futura:
```gdscript
move_unit_to_position(unit, pos)      # Movimiento de unidades
start_battle(attacker, defender)      # Sistema de batalla
recruit_unit_in_city(city, type)      # Reclutamiento
manage_city_production(city, resource) # Gestión de producción
show_diplomacy_panel()                # Panel de diplomacia
show_technology_tree()                # Árbol de tecnología
save_game() / load_game()             # Sistema de guardado/carga
```

## Integración con Sistema Existente

### Conexiones Automáticas:
1. **DivisionInstance.division_seleccionada**: Se conecta automáticamente a todas las divisiones
2. **GameClock.date_changed**: Actualiza la fecha en tiempo real
3. **UnitsContainer.child_entered_tree**: Detecta nuevas divisiones

### Recursos y Assets Utilizados:
- `Assets/Icons/Division Patriota.png`
- `Assets/Icons/Division Realista.png`
- `Scenes/Strategic/StrategicMap.tscn`
- `Scenes/UI/PauseMenu.tscn`

## Flujo de Interacción

1. **Inicio**: MainHUD se inicializa y conecta todas las señales
2. **Selección**: Usuario hace clic en unidad/ciudad → Se muestra panel de detalles
3. **Navegación**: Usuario navega por listas → Selección directa desde paneles
4. **Acciones**: Botones de acción rápida → Avance de turno, pausa, etc.
5. **Eventos**: Sistema registra todas las acciones en el log de eventos

## Convenciones Seguidas

- **Estructura de archivos**: Sigue la organización Scenes/UI y Scripts/UI
- **Nomenclatura**: Nombres en español siguiendo el estilo del proyecto
- **Assets**: Utiliza iconos y recursos existentes del proyecto
- **Señales**: Compatible con el sistema de señales existente
- **Estilo visual**: Paneles semitransparentes con colores distintivos

## Testing

Se incluye `Scenes/UI/TestMainHUD.tscn` para pruebas independientes de la interfaz.

## Extensibilidad

El diseño permite fácil extensión para:
- Nuevos tipos de unidades/ciudades
- Sistemas adicionales (diplomacia, tecnología)
- Paneles especializados
- Integración con sistemas de guardado/carga
- Multijugador y sincronización