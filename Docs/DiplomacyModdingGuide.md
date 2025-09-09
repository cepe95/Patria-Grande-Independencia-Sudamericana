# Sistema de Diplomacia - Guía para Modders

## Resumen
El sistema de diplomacia de "Patria Grande: Independencia Sudamericana" permite gestionar las relaciones entre facciones de manera flexible y extensible. Este documento explica cómo los modders pueden extender y personalizar el sistema.

## Arquitectura del Sistema

### DiplomacyManager (Sistema Central)
- **Ubicación**: `Systems/DiplomacyManager.gd`
- **Función**: Gestiona todas las relaciones diplomáticas y propuestas
- **Autoload**: Disponible globalmente como `DiplomacyManager`

### FactionData (Datos de Facción)
- **Ubicación**: `Data/Factions/FactionData.gd`
- **Función**: Métodos de conveniencia para interactuar con el sistema diplomático
- **Integración**: Cada facción puede consultar y aplicar efectos diplomáticos

### DiplomacyPanel (Interfaz de Usuario)
- **Ubicación**: `Scripts/UI/DiplomacyPanel.gd`
- **Función**: Panel de interfaz para que el jugador gestione relaciones diplomáticas
- **Señales**: Comunica acciones diplomáticas al HUD principal

## Estados Diplomáticos

### Estados Predefinidos
```gdscript
enum DiplomaticStatus {
    NEUTRAL,     # Estado inicial, no hay relaciones establecidas
    PEACE,       # Paz formal (requiere acuerdo previo)
    ALLIANCE,    # Alianza (cooperación activa)
    TRADE,       # Tratado comercial (beneficios económicos)
    WAR,         # Guerra declarada
    HOSTILE      # Hostilidad sin guerra formal
}
```

### Agregando Estados Personalizados
```gdscript
# En tu mod, puedes registrar nuevos estados
func _ready():
    DiplomacyManager.add_custom_diplomatic_status("VASSAL", 100)
    DiplomacyManager.add_custom_diplomatic_status("PROTECTORATE", 101)
```

## Tipos de Propuestas

### Propuestas Predefinidas
```gdscript
enum ProposalType {
    DECLARE_WAR,
    PROPOSE_PEACE,
    PROPOSE_ALLIANCE,
    PROPOSE_TRADE
}
```

### Agregando Propuestas Personalizadas
```gdscript
# Registrar nuevos tipos de propuestas
func _ready():
    DiplomacyManager.add_custom_proposal_type("TRIBUTE_DEMAND", 200)
    DiplomacyManager.add_custom_proposal_type("MARRIAGE_ALLIANCE", 201)
```

## Validación de Acciones

### Reglas de Validación Predefinidas
El sistema incluye reglas básicas:
- No se puede hacer paz sin guerra previa
- No se pueden hacer alianzas durante guerra
- No se puede comerciar durante guerra

### Agregando Reglas Personalizadas
```gdscript
# Definir función de validación personalizada
func no_war_on_sundays(sender: String, receiver: String, proposal_type) -> bool:
    var current_day = Time.get_datetime_dict_from_system()["weekday"]
    if proposal_type == DiplomacyManager.ProposalType.DECLARE_WAR and current_day == 0:
        return false  # No guerra los domingos
    return true

func _ready():
    # Registrar la regla personalizada
    DiplomacyManager.register_custom_validation_rule("no_war_on_sundays", no_war_on_sundays)
```

## Efectos Diplomáticos

### Efectos en Recursos
Las facciones pueden aplicar efectos automáticos basados en su estado diplomático:

```gdscript
# En FactionData.gd - métodos que puedes sobrescribir
func apply_trade_bonus():
    # Bonificaciones por tratados comerciales
    var trade_partners = get_trade_partners()
    var bonus = trade_partners.size() * 10
    recursos["dinero"] += bonus

func apply_war_penalties():
    # Penalizaciones por guerra
    var enemies = get_all_enemies()
    var penalty = enemies.size() * 5
    recursos["moral"] = max(0, recursos["moral"] - penalty)

func apply_alliance_benefits():
    # Beneficios por alianzas
    var allies = get_all_allies()
    var bonus = allies.size() * 2
    recursos["prestigio"] += bonus
```

### Efectos Personalizados
```gdscript
# Crear efectos específicos para tu mod
func apply_custom_diplomatic_effects():
    # Ejemplo: Bonificación por vasallaje
    if get_diplomatic_status_with("Imperio_Romano") == VASSAL_STATUS_ID:
        recursos["proteccion"] += 50
        recursos["autonomia"] -= 10
```

## Eventos y Señales

### Señales Disponibles
```gdscript
# En DiplomacyManager
signal diplomatic_status_changed(faction1: String, faction2: String, old_status, new_status)
signal proposal_received(proposal: DiplomaticProposal)

# En DiplomacyPanel
signal panel_closed
signal diplomatic_action_performed(action: String, target_faction: String)
```

### Conectar a Eventos Diplomáticos
```gdscript
func _ready():
    # Escuchar cambios diplomáticos
    DiplomacyManager.diplomatic_status_changed.connect(_on_diplomatic_change)

func _on_diplomatic_change(faction1, faction2, old_status, new_status):
    if new_status == DiplomacyManager.DiplomaticStatus.WAR:
        # Activar música de guerra
        AudioManager.play_war_theme()
    elif new_status == DiplomacyManager.DiplomaticStatus.PEACE:
        # Activar música de paz
        AudioManager.play_peace_theme()
```

## IA Diplomática

### Comportamiento de IA Básico
El sistema incluye IA básica que envía propuestas aleatorias:

```gdscript
# En DiplomacyManager
func _process_ai_proposals():
    # 10% de probabilidad por turno
    if randf() < 0.1:
        _ai_send_random_proposal(sender, receiver)
```

### Personalizando la IA
```gdscript
# Sobrescribir comportamiento de IA para facciones específicas
func custom_ai_behavior(faction_name: String):
    match faction_name:
        "Imperio_Romano":
            # IA agresiva
            if randf() < 0.3:  # 30% probabilidad de guerra
                send_war_proposal()
        "Reino_Pacifico":
            # IA pacífica
            if randf() < 0.2:  # 20% probabilidad de comercio
                send_trade_proposal()
```

## Integración con Otros Sistemas

### Sistema de Turnos
```gdscript
# En MainHUD.gd
func _on_next_turn_pressed():
    # El sistema de diplomacia se procesa automáticamente
    DiplomacyManager.process_turn_events()
```

### Sistema de Eventos
```gdscript
# Las acciones diplomáticas generan eventos automáticamente
func _on_diplomatic_action_performed(action: String, target_faction: String):
    var message = "%s realizada con %s" % [action, target_faction]
    add_event(message, "info")  # Se agrega al log de eventos
```

## Persistencia de Datos

### Guardado de Estado Diplomático
```gdscript
# Para mods que requieran persistencia
func save_diplomatic_state() -> Dictionary:
    return {
        "relations": DiplomacyManager.diplomatic_relations,
        "proposals": DiplomacyManager.pending_proposals,
        "history": DiplomacyManager.diplomatic_history
    }

func load_diplomatic_state(data: Dictionary):
    DiplomacyManager.diplomatic_relations = data.get("relations", {})
    DiplomacyManager.pending_proposals = data.get("proposals", [])
    DiplomacyManager.diplomatic_history = data.get("history", [])
```

## Ejemplos de Mods

### Mod de Vasallaje
```gdscript
# Agregar sistema de vasallaje
const VASSAL_STATUS = 100

func _ready():
    DiplomacyManager.add_custom_diplomatic_status("VASSAL", VASSAL_STATUS)
    DiplomacyManager.add_custom_proposal_type("DEMAND_VASSALAGE", 200)

func can_demand_vassalage(sender: String, receiver: String) -> bool:
    var sender_strength = calculate_military_strength(sender)
    var receiver_strength = calculate_military_strength(receiver)
    return sender_strength > receiver_strength * 2  # Debe ser 2x más fuerte
```

### Mod de Matrimonios Dinásticos
```gdscript
# Sistema de matrimonios entre casas reales
const MARRIAGE_ALLIANCE = 101

func _ready():
    DiplomacyManager.add_custom_diplomatic_status("MARRIAGE_ALLIANCE", MARRIAGE_ALLIANCE)
    DiplomacyManager.add_custom_proposal_type("PROPOSE_MARRIAGE", 201)

func apply_marriage_benefits(faction: FactionData):
    var marriage_partners = get_factions_with_status(faction.nombre, MARRIAGE_ALLIANCE)
    for partner in marriage_partners:
        # Beneficios diplomáticos por matrimonio
        faction.recursos["legitimidad"] += 5
        faction.recursos["prestigio"] += 3
```

## Mejores Prácticas

### 1. Validación Consistente
- Siempre valida las acciones diplomáticas antes de aplicarlas
- Usa las funciones `_can_send_proposal()` y `_can_change_status()`

### 2. Efectos Balanceados
- Los efectos diplomáticos deben ser significativos pero no gamebreaking
- Considera tanto beneficios como penalizaciones

### 3. Retroalimentación al Jugador
- Usa el sistema de eventos para informar al jugador
- Proporciona información clara sobre el estado diplomático

### 4. Compatibilidad
- No modifiques directamente los archivos del sistema base
- Usa las APIs de modder proporcionadas
- Prefija tus IDs personalizados para evitar conflictos

## Troubleshooting

### Problemas Comunes
1. **Estados diplomáticos no cambian**: Verificar reglas de validación
2. **Propuestas no aparecen**: Comprobar que la facción emisora existe
3. **Efectos no se aplican**: Asegurar que `process_turn_events()` se llama

### Debug
```gdscript
# Activar logging diplomático
func _ready():
    DiplomacyManager.debug_mode = true  # Si se implementa

# Ver estado diplomático actual
func debug_diplomatic_status():
    print(DiplomacyManager.generate_diplomatic_report("Patriota"))
```

## Contacto y Soporte

Para dudas sobre modding del sistema de diplomacia:
- Revisar la documentación en el código fuente
- Consultar ejemplos en `Scripts/Tests/DiplomacyTest.gd`
- Usar las APIs de modder documentadas en `DiplomacyManager.gd`

---

*Última actualización: Sistema de Diplomacia v1.0*