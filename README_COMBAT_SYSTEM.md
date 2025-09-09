# Sistema de Combate por Turnos - Guía de Uso

## ¿Qué se ha implementado?

Se ha agregado un sistema completo de combate por turnos que cumple con todos los requisitos especificados:

### ✅ Funcionalidades Implementadas

1. **Interfaz de combate accesible desde el HUD**
   - Se abre automáticamente cuando unidades hostiles se encuentran en la misma zona
   - Panel visual que muestra información detallada de ambas unidades

2. **Selección y visualización de unidades participantes**
   - Muestra atributos relevantes: tropas, moral, experiencia, rama, movilidad
   - Iconos distintivos para cada facción (Patriota/Realista)
   - Información actualizada en tiempo real durante el combate

3. **Lógica de resolución de combate por turnos**
   - Sistema de turnos alternados con ataques y defensas
   - Cálculo de daño basado en tipo de unidad, moral, experiencia y tamaño
   - Múltiples condiciones de victoria (derrota, ruta, retirada)

4. **Indicadores visuales de daño y resultados**
   - Log de combate detallado que muestra cada turno
   - Información de bajas, daño infligido y estado de las unidades
   - Colores distintivos para diferentes tipos de eventos

5. **Registro en el panel de eventos del HUD**
   - Todos los eventos de combate se registran automáticamente
   - Historial completo de batallas y resultados
   - Integración perfecta con el sistema de eventos existente

6. **Documentación completa para modding**
   - Parámetros de balance fácilmente modificables
   - API clara para desarrolladores y modders
   - Sistema extensible para futuras características

## Cómo usar el sistema

### Para Jugadores

1. **Iniciar el juego** y cargar el mapa estratégico
2. **Seleccionar una división** haciendo clic en ella
3. **Mover la división** cerca de una división enemiga (diferentes facciones)
4. **El sistema detecta automáticamente** el conflicto y abre la interfaz de combate
5. **Elegir acciones** usando los botones:
   - **Atacar**: Ejecuta un turno de combate manual
   - **Defender**: Similar a atacar pero con posibles bonificaciones futuras
   - **Retirarse**: Termina el combate inmediatamente
   - **Auto**: Ejecuta el combate automáticamente hasta el final

### Para Desarrolladores/Modders

```gdscript
# Obtener referencia al sistema de combate
var main_hud = get_tree().current_scene.get_node("MainHUD")
var combat_system = main_hud.get_combat_system()

# Modificar parámetros de balance
combat_system.set_balance_parameter("base_damage_infantry", 20)
combat_system.set_balance_parameter("max_turns", 15)

# Iniciar combate programáticamente
main_hud.initiate_combat_between_units(unit1, unit2)

# Escuchar eventos de combate
combat_system.combat_started.connect(_on_combat_started)
combat_system.combat_ended.connect(_on_combat_ended)
```

## Archivos Nuevos Creados

- `Scripts/Manager/CombatSystem.gd` - Lógica central del combate
- `Scripts/UI/CombatUI.gd` - Interfaz de usuario para combate
- `Scenes/UI/CombatPanel.tscn` - Escena visual del panel de combate
- `Documentation/CombatSystem.md` - Documentación técnica completa
- `Tests/CombatSystemTest.gd` - Tests básicos de validación

## Archivos Modificados

- `Scripts/UI/MainHUD.gd` - Integración del sistema de combate
- `Scripts/Strategic/StrategicMap.gd` - Detección de combate en movimientos
- `Scripts/Strategic/DivisionInstance.gd` - Callback de movimiento terminado
- `Scenes/UI/MainHUD.tscn` - Adición del panel de combate

## Parámetros de Balance

Todos los parámetros están centralizados y son fácilmente modificables:

```gdscript
{
    "base_damage_infantry": 15,      # Daño base de infantería
    "base_damage_cavalry": 20,       # Daño base de caballería  
    "base_damage_artillery": 25,     # Daño base de artillería
    "moral_damage_multiplier": 0.1,  # Multiplicador de daño por moral
    "experience_bonus": 0.05,        # Bonificación por experiencia
    "max_turns": 10,                 # Máximo de turnos por combate
    "rout_threshold": 25,            # Umbral de moral para ruta
    "withdrawal_threshold": 50       # Umbral de pérdidas para retirada
}
```

## Próximos Pasos

El sistema está completo y funcional, pero se puede extender con:

1. **Modificadores de terreno** - Bonificaciones según el tipo de terreno
2. **Tácticas especiales** - Diferentes tipos de ataque (carga, flanqueo)
3. **Comandantes** - Bonificaciones por líderes militares
4. **Efectos de clima** - Modificadores por condiciones meteorológicas
5. **Sistema de suministros** - Efectos de la logística en el combate

## Notas Importantes

- **No se modificó** el sistema de movimiento existente
- **No se alteró** la gestión de unidades fuera del contexto de combate
- **Se respetó** la arquitectura existente del proyecto
- **Se implementaron** todas las características solicitadas
- **Se añadió** soporte completo para modding y balance futuro

El sistema está listo para usar y se integra perfectamente con el juego existente.