# Sistema de Investigación - Documentación para Modders

## Introducción

El sistema de investigación científica y tecnológica de Patria Grande permite a los jugadores desarrollar nuevas tecnologías que afectan los sistemas militar, económico y diplomático del juego. Este documento explica cómo crear y modificar tecnologías mediante archivos de configuración.

## Estructura de Archivos

Las tecnologías se definen en archivos JSON ubicados en la carpeta `Data/Research/`:

- `military_technologies.json` - Tecnologías militares
- `economic_technologies.json` - Tecnologías económicas  
- `diplomatic_technologies.json` - Tecnologías diplomáticas

Puedes crear archivos adicionales siguiendo el mismo formato para organizar mejor tus tecnologías personalizadas.

## Formato de Tecnología

Cada tecnología se define con la siguiente estructura JSON:

```json
{
  "id": "identificador_unico",
  "name": "Nombre Visible",
  "description": "Descripción detallada de la tecnología",
  "category": "categoria",
  "research_cost": 150,
  "research_time": 8,
  "required_technologies": ["tech1", "tech2"],
  "required_resources": {
    "dinero": 300,
    "municion": 50
  },
  "effects": {
    "efecto_general": 1.2
  },
  "military_benefits": {
    "infantry_attack": 15,
    "unit_morale": 5
  },
  "economic_benefits": {
    "resource_generation": 25,
    "trade_income": 20
  },
  "diplomatic_benefits": {
    "trade_relations": 15
  },
  "icon_path": "res://Assets/Icons/Tech/mi_tecnologia.png",
  "era": "colonial",
  "is_secret": false
}
```

## Campos Obligatorios

### Identificación
- **id**: Identificador único de la tecnología (string, sin espacios)
- **name**: Nombre que se muestra al jugador
- **description**: Descripción detallada visible en el panel de investigación

### Categoría y Era
- **category**: Categoría de la tecnología ("militar", "economia", "diplomacia", "cultural")
- **era**: Era histórica ("colonial", "independencia", "republica")

### Costos
- **research_cost**: Puntos de investigación necesarios (número entero)
- **research_time**: Tiempo estimado en turnos (número entero)

## Campos Opcionales

### Requisitos
- **required_technologies**: Array de IDs de tecnologías prerrequisito
- **required_resources**: Diccionario de recursos necesarios para iniciar la investigación

### Beneficios
- **effects**: Efectos generales de la tecnología
- **military_benefits**: Beneficios específicos para el sistema militar
- **economic_benefits**: Beneficios específicos para el sistema económico  
- **diplomatic_benefits**: Beneficios específicos para el sistema diplomático

### Metadatos
- **icon_path**: Ruta al icono de la tecnología (por defecto: icono genérico)
- **is_secret**: Si es true, la tecnología está oculta hasta cumplir requisitos

## Tipos de Beneficios

### Beneficios Militares
```json
"military_benefits": {
  "infantry_attack": 15,     // Bonus de ataque de infantería (+15)
  "unit_morale": 10,         // Bonus de moral de unidades (+10)
  "mobility": 20,            // Bonus de movilidad (+20)
  "defensive_bonus": 25,     // Bonus defensivo (+25)
  "command_range": 50,       // Aumento de rango de comando (+50)
  "recruitment_rate": 30     // Aumento en velocidad de reclutamiento (+30%)
}
```

### Beneficios Económicos
```json
"economic_benefits": {
  "resource_generation": 25,  // Aumento en generación de recursos (+25%)
  "trade_income": 20,         // Aumento en ingresos comerciales (+20%)
  "gold_production": 40,      // Aumento en producción de oro (+40%)
  "population_growth": 15,    // Aumento en crecimiento poblacional (+15%)
  "tax_income": 30           // Aumento en ingresos por impuestos (+30%)
}
```

### Beneficios Diplomáticos
```json
"diplomatic_benefits": {
  "patriot_relations": 30,      // Mejora relaciones patriotas (+30)
  "trade_relations": 15,        // Mejora relaciones comerciales (+15)
  "alliance_stability": 40,     // Mejora estabilidad de alianzas (+40)
  "negotiation_bonus": 25,      // Bonus en negociaciones (+25)
  "intelligence_gathering": 20  // Mejora recolección de inteligencia (+20)
}
```

## Árbol de Dependencias

Las tecnologías pueden requerir otras tecnologías como prerrequisito:

```json
"required_technologies": ["comercio_regional", "ideologia_libertad"]
```

Esto crea un árbol de dependencias donde el jugador debe investigar las tecnologías base antes de acceder a las avanzadas.

## Recursos Requeridos

Puedes requerir que el jugador tenga ciertos recursos para iniciar la investigación:

```json
"required_resources": {
  "dinero": 500,      // Dinero requerido
  "municion": 100,    // Munición requerida
  "oro": 50,          // Oro requerido
  "moral": 75         // Moral requerida
}
```

Los recursos se consumen al iniciar la investigación.

## Efectos Dinámicos

Los efectos se aplican automáticamente cuando se completa la investigación. Los números pueden ser:

- **Multiplicadores**: Valores > 1.0 (ej: 1.2 = +20%)
- **Bonificaciones**: Valores enteros (ej: 15 = +15 puntos)
- **Porcentajes**: Valores decimales < 1.0 (ej: 0.1 = +10%)

## Ejemplos Prácticos

### Tecnología Militar Básica
```json
{
  "id": "entrenamiento_basico",
  "name": "Entrenamiento Militar Básico",
  "description": "Mejora el entrenamiento básico de las tropas patriotas.",
  "category": "militar",
  "research_cost": 100,
  "research_time": 5,
  "required_technologies": [],
  "required_resources": {
    "dinero": 200
  },
  "military_benefits": {
    "unit_morale": 10,
    "infantry_attack": 5
  },
  "era": "colonial",
  "is_secret": false
}
```

### Tecnología Económica Avanzada
```json
{
  "id": "sistema_bancario",
  "name": "Sistema Bancario Nacional",
  "description": "Establece un sistema bancario que facilita el comercio y aumenta los ingresos.",
  "category": "economia",
  "research_cost": 300,
  "research_time": 15,
  "required_technologies": ["comercio_regional", "mineria_avanzada"],
  "required_resources": {
    "dinero": 1000,
    "oro": 200
  },
  "economic_benefits": {
    "trade_income": 40,
    "tax_income": 25,
    "resource_generation": 20
  },
  "era": "independencia",
  "is_secret": false
}
```

### Tecnología Secreta
```json
{
  "id": "red_espionaje_avanzada",
  "name": "Red de Espionaje Avanzada",
  "description": "Red clandestina de espías que proporciona información crítica sobre el enemigo.",
  "category": "diplomacia", 
  "research_cost": 400,
  "research_time": 20,
  "required_technologies": ["espionaje_avanzado", "red_comunicaciones"],
  "required_resources": {
    "dinero": 800,
    "moral": 100
  },
  "diplomatic_benefits": {
    "intelligence_gathering": 50,
    "counter_intelligence": 40,
    "sabotage_capability": 30
  },
  "military_benefits": {
    "enemy_visibility": 60
  },
  "era": "independencia",
  "is_secret": true
}
```

## Consejos para Modders

1. **IDs Únicos**: Usa IDs descriptivos y únicos para evitar conflictos
2. **Balance**: Las tecnologías costosas deben ofrecer beneficios proporcionales
3. **Progresión**: Crea cadenas lógicas de tecnologías que se complementen
4. **Temática**: Mantén coherencia histórica con la era de independencia sudamericana
5. **Testing**: Prueba las tecnologías en el juego para verificar el balance

## Integración con Otros Sistemas

El sistema de investigación se integra automáticamente con:

- **Sistema Militar**: Los beneficios militares afectan unidades y combate
- **Sistema Económico**: Los beneficios económicos modifican generación de recursos
- **Sistema Diplomático**: Los beneficios diplomáticos influyen en relaciones entre facciones

## Carga de Archivos Personalizados

Para añadir tus propias tecnologías:

1. Crea un nuevo archivo JSON en `Data/Research/`
2. Sigue el formato especificado en este documento
3. El archivo se cargará automáticamente al iniciar el juego
4. Las tecnologías aparecerán en el panel de investigación según sus requisitos

## Resolución de Problemas

- **Tecnología no aparece**: Verifica que el JSON sea válido y esté en la carpeta correcta
- **Error de carga**: Revisa la consola de Godot para mensajes de error específicos
- **Beneficios no funcionan**: Asegúrate de usar los nombres de efectos correctos
- **Dependencias rotas**: Verifica que todas las tecnologías referenciadas existan

---

Para más información sobre el desarrollo del juego, consulta la documentación principal del proyecto.