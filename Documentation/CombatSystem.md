# Sistema de Combate por Turnos - Patria Grande: Independencia Sudamericana

## Descripción General

El sistema de combate por turnos permite que unidades de facciones enemigas se enfrenten en batallas estratégicas cuando se encuentran en la misma zona del mapa. El sistema está diseñado para ser modular, configurable y extensible.

## Componentes del Sistema

### 1. CombatSystem.gd
**Ubicación:** `Scripts/Manager/CombatSystem.gd`

**Responsabilidades:**
- Maneja la lógica central del combate por turnos
- Calcula daño, bajas y resultados de combate
- Emite señales para integración con la UI
- Gestiona parámetros de balance configurables

**Clases Internas:**
- `CombatResult`: Almacena el resultado final de un combate
- `CombatTurnData`: Almacena información de cada turno de combate

### 2. CombatUI.gd
**Ubicación:** `Scripts/UI/CombatUI.gd`

**Responsabilidades:**
- Interfaz visual para el combate
- Muestra estadísticas de las unidades combatientes
- Permite al jugador elegir acciones (atacar, defender, retirarse, automático)
- Registra y muestra el log de combate

### 3. CombatPanel.tscn
**Ubicación:** `Scenes/UI/CombatPanel.tscn`

**Descripción:**
- Escena de la interfaz de combate
- Contiene paneles para mostrar unidades, log de combate y botones de acción

## Integración con el Sistema Existente

### MainHUD.gd
- Se agrega referencia al `CombatUI`
- Se inicializa el `CombatSystem` como nodo hijo
- Se conectan las señales de combate
- Se implementa detección de conflictos entre unidades

### StrategicMap.gd
- Se agregan métodos para detectar combate cuando las unidades se mueven
- Funciones para encontrar unidades hostiles en rango
- Integración con el HUD para iniciar combates

### DivisionInstance.gd
- Se agrega callback cuando termina el movimiento
- Notifica al mapa estratégico para verificar combates

## Mecánicas de Combate

### Detección de Combate
- Las unidades entran en combate cuando están a menos de 50 píxeles de distancia
- Solo unidades de facciones diferentes pueden combatir
- Se verifica automáticamente al finalizar movimientos y al cambiar turno

### Cálculo de Daño
El daño se calcula usando la siguiente fórmula:

```
daño_final = daño_base × factor_moral × factor_experiencia × factor_tamaño
```

Donde:
- **daño_base**: Depende del tipo de unidad (infantería: 15, caballería: 20, artillería: 25)
- **factor_moral**: `1.0 + (moral - 50) × 0.1 / 50.0`
- **factor_experiencia**: `1.0 + experiencia × 0.05 / 100.0`
- **factor_tamaño**: `min(cantidad_total / 100.0, 2.0)` (máximo 2x)

### Condiciones de Victoria
El combate termina cuando:
- Una unidad es completamente eliminada (cantidad_total ≤ 0)
- La moral de una unidad cae por debajo del umbral de ruta (25)
- Las pérdidas exceden el umbral de retirada (50% de bajas)
- Se alcanza el máximo de turnos (10)

### Tipos de Victoria
- **Defeat**: Una unidad es completamente eliminada
- **Rout**: Una unidad huye por baja moral
- **Withdrawal**: Retirada estratégica por pérdidas o por decisión del jugador

## Parámetros de Balance

Los siguientes parámetros pueden modificarse para ajustar el balance del combate:

```gdscript
var combat_balance := {
    "base_damage_infantry": 15,      # Daño base de infantería
    "base_damage_cavalry": 20,       # Daño base de caballería
    "base_damage_artillery": 25,     # Daño base de artillería
    "moral_damage_multiplier": 0.1,  # Multiplicador de daño por moral
    "experience_bonus": 0.05,        # Bonificación por experiencia
    "terrain_modifier": 1.0,         # Modificador de terreno (futuro)
    "max_turns": 10,                 # Máximo de turnos por combate
    "rout_threshold": 25,            # Umbral de moral para ruta
    "withdrawal_threshold": 50       # Umbral de pérdidas para retirada
}
```

## API para Modders

### Modificar Parámetros de Balance
```gdscript
# Obtener referencia al sistema de combate
var combat_system = main_hud.get_combat_system()

# Modificar parámetros
combat_system.set_balance_parameter("base_damage_infantry", 20)
combat_system.set_balance_parameter("max_turns", 15)

# Obtener parámetros actuales
var current_damage = combat_system.get_balance_parameter("base_damage_infantry")
var all_params = combat_system.get_all_balance_parameters()
```

### Iniciar Combate Programáticamente
```gdscript
# Desde el MainHUD
main_hud.initiate_combat_between_units(unit1, unit2)

# Directamente desde el sistema
combat_system.start_combat(division_data1, division_data2)
```

### Escuchar Eventos de Combate
```gdscript
# Conectar señales del sistema de combate
combat_system.combat_started.connect(_on_combat_started)
combat_system.combat_ended.connect(_on_combat_ended)
combat_system.turn_completed.connect(_on_turn_completed)
```

## Eventos del Sistema

### Señales Emitidas
- `combat_started(attacker: DivisionData, defender: DivisionData)`: Cuando inicia un combate
- `combat_ended(result: CombatResult)`: Cuando termina un combate
- `turn_completed(turn_data: CombatTurnData)`: Cuando se completa un turno

### Integración con Event Log
Todos los eventos importantes del combate se registran automáticamente en el panel de eventos del HUD:
- Inicio de combate
- Resultados de combate
- Bajas y pérdidas
- Retiradas y derrotas

## Extensiones Futuras

### Características Planificadas
1. **Modificadores de Terreno**: Bonificaciones/penalizaciones según el terreno
2. **Tácticas Especiales**: Diferentes tipos de ataque (carga, flanqueo, etc.)
3. **Comandantes**: Bonificaciones por líderes militares
4. **Moral de Facción**: Efectos de combate en la moral general
5. **Suministros**: Efectos de la logística en el combate
6. **Clima**: Modificadores por condiciones meteorológicas

### Soporte para Modding
El sistema está diseñado para ser fácilmente modificable:
- Parámetros de balance en Dictionary modificable
- Lógica de cálculo en métodos separados
- Señales para hooks de modding
- Clases de datos extensibles

## Uso del Sistema

### Para Jugadores
1. Mueve unidades cerca de unidades enemigas
2. El sistema detecta automáticamente conflictos
3. Se abre la interfaz de combate mostrando las unidades
4. Elige acciones: Atacar, Defender, Retirarse, o Combate Automático
5. Observa los resultados en el log de combate
6. El combate termina automáticamente según las condiciones de victoria

### Para Desarrolladores
1. El sistema se inicializa automáticamente con el MainHUD
2. Los combates se detectan automáticamente en movimientos
3. Se puede iniciar combate manualmente llamando `initiate_combat_between_units()`
4. Los resultados se registran automáticamente en el sistema de eventos
5. El balance se puede ajustar modificando `combat_balance`

## Archivos Modificados

- `Scripts/UI/MainHUD.gd`: Integración del sistema de combate
- `Scripts/Strategic/StrategicMap.gd`: Detección de combate en movimientos
- `Scripts/Strategic/DivisionInstance.gd`: Callback de movimiento terminado
- `Scenes/UI/MainHUD.tscn`: Adición del CombatUI

## Archivos Nuevos

- `Scripts/Manager/CombatSystem.gd`: Lógica central del combate
- `Scripts/UI/CombatUI.gd`: Interfaz de usuario para combate
- `Scenes/UI/CombatPanel.tscn`: Escena de la interfaz de combate
- `Documentation/CombatSystem.md`: Esta documentación

## Consideraciones de Rendimiento

- El sistema solo verifica combates cuando es necesario (movimientos, cambio de turno)
- Los cálculos de combate son eficientes y se realizan solo durante combates activos
- La UI de combate se oculta cuando no hay combate activo
- Se evitan búsquedas innecesarias de unidades mediante verificaciones de distancia

## Testing

Para probar el sistema:
1. Inicia el juego y ve al mapa estratégico
2. Selecciona una división y muévela cerca de una división enemiga
3. El sistema debería detectar el conflicto y mostrar la interfaz de combate
4. Prueba diferentes acciones de combate
5. Verifica que los resultados se registren en el panel de eventos