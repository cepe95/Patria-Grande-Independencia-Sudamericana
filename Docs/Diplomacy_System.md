# Sistema de Diplomacia - Patria Grande: Independencia Sudamericana

## Descripción General

El sistema de diplomacia permite a los jugadores interactuar con otras facciones a través de relaciones políticas, comerciales y militares. El sistema está diseñado para ser modular y fácilmente configurable para permitir modificaciones por parte de la comunidad.

## Características Principales

### 1. Estados Diplomáticos
- **Desconocido**: Sin contacto previo
- **Hostil**: Relación muy negativa
- **Poco Amistoso**: Tensiones menores
- **Neutral**: Sin acuerdos especiales
- **Amistoso**: Relaciones cordiales
- **Aliado**: Pacto de cooperación
- **Vasallo**: Relación de subordinación
- **Guerra**: Conflicto activo

### 2. Acciones Diplomáticas
- **Alianzas**: Pactos de cooperación militar y política
- **Acuerdos Comerciales**: Beneficios económicos mutuos
- **Declaraciones de Guerra**: Inicio de hostilidades formales
- **Tratados de Paz**: Fin de conflictos
- **Pactos de No Agresión**: Acuerdos de no atacarse
- **Acceso Militar**: Permisos para mover tropas

### 3. Sistema de Opinión
- Rango de -100 a +100
- Influye en la probabilidad de éxito de propuestas
- Decae gradualmente con el tiempo
- Se modifica por eventos y acciones

### 4. Eventos Aleatorios
- Escaramuzas fronterizas
- Disputas comerciales
- Intercambios culturales
- Incidentes militares
- Reuniones diplomáticas
- Cooperación en recursos

## Uso del Sistema

### Acceso al Panel de Diplomacia
1. **Botón de Diplomacia**: En el panel de eventos del HUD principal
2. **Atajo de Teclado**: Ctrl+D
3. **Tecla ESC**: Para cerrar el panel

### Navegación del Panel
1. **Lista de Facciones**: Muestra todas las facciones conocidas con sus estados
2. **Panel de Detalles**: Información detallada de la facción seleccionada
3. **Acciones Disponibles**: Botones para enviar propuestas diplomáticas
4. **Eventos Recientes**: Historia de interacciones diplomáticas

### Indicadores Visuales
- **Colores de Estado**: Cada estado diplomático tiene un color asociado
- **Iconos de Tratados**: Símbolos para acuerdos activos (💰 Comercio, ⚔️ Acceso Militar)
- **Medidor de Opinión**: Indicador visual del nivel de opinión
- **Notificaciones**: Eventos diplomáticos en el log principal

## Atajos de Teclado

- `Ctrl + D`: Abrir panel de diplomacia
- `ESC`: Cerrar panel de diplomacia (si está abierto)
- `Espacio`: Avanzar turno (procesa eventos diplomáticos)

## Configuración para Modders

### Archivo de Configuración Principal
**Ubicación**: `Data/Diplomacy/diplomatic_events.json`

### Estructura de Eventos Aleatorios
```json
{
  "random_events": [
    {
      "name": "evento_personalizado",
      "description": "Descripción del evento entre {faction_a} y {faction_b}",
      "probability": 0.05,
      "opinion_change": -15,
      "status_requirements": ["NEUTRAL", "UNFRIENDLY"],
      "prerequisites": {
        "min_turn": 5,
        "exclude_player": false
      }
    }
  ]
}
```

### Personalización de Propuestas
```json
{
  "proposal_types": {
    "custom_proposal": {
      "name": "Propuesta Personalizada",
      "description": "Descripción de la propuesta",
      "base_success_probability": 0.6,
      "opinion_modifiers": {
        "min_opinion": 20,
        "opinion_bonus_per_10": 0.1
      },
      "effects": {
        "custom_effect": true
      }
    }
  }
}
```

### Personalidades de IA
```json
{
  "faction_personalities": {
    "MiFaccion": {
      "aggression": "normal",
      "trade_preference": 0.7,
      "alliance_preference": 0.8,
      "independence_support": 0.9
    }
  }
}
```

### Modificadores de Opinión
```json
{
  "opinion_modifiers": {
    "base_decay_per_turn": 1,
    "war_opinion_penalty": -50,
    "alliance_opinion_bonus": 30,
    "faction_ideology_bonus": {
      "same_ideology": 10,
      "opposing_ideology": -20
    }
  }
}
```

## Integración con Otros Sistemas

### FactionManager
- Las facciones deben estar registradas en FactionManager
- Personalidades diplomáticas se configuran en FactionData
- Recursos diplomáticos se almacenan en el sistema de facciones

### MainHUD
- Eventos diplomáticos aparecen en el log de eventos
- Notificaciones especiales para propuestas del jugador
- Integración con el sistema de turnos

### Recursos
- Algunos acuerdos pueden tener costos en recursos
- Acuerdos comerciales pueden proporcionar bonificaciones
- Guerra afecta la economía de las facciones

## Eventos del Sistema

### Señales Disponibles
- `diplomatic_status_changed(faction_a, faction_b, new_status)`
- `diplomatic_proposal_received(from_faction, to_faction, proposal_type, details)`
- `diplomatic_event_occurred(event_type, description, factions_involved)`

### Uso de Señales
```gdscript
# Conectar a eventos diplomáticos
DiplomacyManager.diplomatic_status_changed.connect(_on_diplomatic_change)

func _on_diplomatic_change(faction_a: String, faction_b: String, new_status: int):
    # Manejar cambio diplomático
    pass
```

## Limitaciones y Consideraciones

### Rendimiento
- Los eventos aleatorios se procesan una vez por turno
- La IA evalúa decisiones cada 3 turnos por defecto
- El sistema está optimizado para manejar múltiples facciones

### Balanceado
- Las probabilidades están calibradas para el gameplay base
- Los modders pueden ajustar todas las probabilidades y efectos
- La decadencia de opinión previene relaciones estáticas

### Expansibilidad
- Nuevos tipos de propuestas se pueden agregar fácilmente
- Los eventos pueden tener efectos personalizados
- Las personalidades de IA son completamente configurables

## Ejemplo de Mod

Para crear un nuevo evento diplomático:

1. Editar `Data/Diplomacy/diplomatic_events.json`
2. Agregar el evento a la sección `random_events`
3. Configurar probabilidad, efectos y requisitos
4. Opcionalmente agregar localización personalizada

```json
{
  "name": "intercambio_prisioneros",
  "description": "Intercambio de prisioneros mejora relaciones entre {faction_a} y {faction_b}",
  "probability": 0.02,
  "opinion_change": 20,
  "status_requirements": ["HOSTILE", "WAR"],
  "effects": {
    "prisoner_exchange": true,
    "moral_bonus": 5
  }
}
```

## Debugging y Testing

### Consola de Debug
El sistema incluye logs detallados para debugging:
- `✓` para operaciones exitosas
- `⚠` para advertencias
- `❌` para errores

### Test Scene
Usar `Scenes/Test/DiplomacyTest.tscn` para probar funcionalidades:
- Relaciones diplomáticas básicas
- Envío y respuesta de propuestas
- Eventos aleatorios
- Cambios de estado

### Comandos de Consola
```gdscript
# Cambiar estado diplomático manualmente
DiplomacyManager.set_diplomatic_status("Patriota", "Realista", DiplomaticRelation.RelationStatus.ALLIED)

# Enviar propuesta
DiplomacyManager.send_diplomatic_proposal("Patriota", "Realista", "alliance")

# Disparar evento aleatorio
DiplomacyManager.trigger_random_event(event_config)
```