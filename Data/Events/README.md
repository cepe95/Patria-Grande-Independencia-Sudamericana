# Sistema de Eventos - Guía para Modders

## Introducción

El sistema de eventos de Patria Grande: Independencia Sudamericana permite crear eventos históricos y aleatorios que enriquecen la experiencia de juego. Este documento explica cómo crear y configurar eventos personalizados.

## Tipos de Eventos

### 1. Eventos Históricos (event_type: 0)
- Se disparan en fechas específicas
- Representan eventos históricos reales
- Se configuran con `trigger_date`

### 2. Eventos Aleatorios (event_type: 1)
- Se disparan aleatoriamente durante el juego
- Probabilidad controlada por `random_chance`
- Pueden repetirse si `can_repeat: true`

### 3. Eventos Disparados (event_type: 2)
- Se activan por condiciones específicas del juego
- Configurados con `trigger_conditions`

## Estructura de Archivo JSON

Los eventos se definen en archivos JSON en la carpeta `Data/Events/`. Cada archivo puede contener un evento único o un array de eventos.

### Formato Básico

```json
{
  "id": "id_unico_evento",
  "title": "Título del Evento",
  "description": "Descripción detallada del evento...",
  "event_type": 0,
  "image_path": "res://Assets/Events/imagen.png",
  "trigger_date": "1816/07/09",
  "trigger_turn": -1,
  "random_chance": 0.0,
  "trigger_conditions": [],
  "has_choices": true,
  "choices": [
    {
      "text": "Opción 1",
      "effects": [
        {"type": 0, "resource": "dinero", "amount": -100}
      ]
    }
  ],
  "effects": [
    {"type": 0, "resource": "moral", "amount": 10}
  ],
  "can_repeat": false,
  "priority": 5,
  "category": "político"
}
```

## Campos Obligatorios

- **id**: Identificador único del evento (string)
- **title**: Título del evento (string)
- **description**: Descripción del evento (string)
- **event_type**: Tipo de evento (0=histórico, 1=aleatorio, 2=disparado)

## Campos Opcionales

### Condiciones de Activación
- **trigger_date**: Fecha de activación (formato "AAAA/MM/DD")
- **trigger_turn**: Turno específico (-1 para cualquier turno)
- **random_chance**: Probabilidad de activación (0.0 a 1.0)
- **trigger_conditions**: Array de condiciones personalizadas

### Contenido
- **image_path**: Ruta a imagen del evento
- **category**: Categoría del evento (político, militar, económico, social)
- **priority**: Prioridad de visualización (0-10)

### Opciones
- **has_choices**: Si el evento tiene opciones de decisión
- **choices**: Array de opciones disponibles
- **can_repeat**: Si el evento puede repetirse

## Tipos de Efectos

### Cambio de Recursos (type: 0)
```json
{"type": 0, "resource": "dinero", "amount": -50}
{"type": 0, "resource": "comida", "amount": 100}
{"type": 0, "resource": "municion", "amount": -25}
{"type": 0, "resource": "moral", "amount": 15}
```

### Cambio Diplomático (type: 1)
```json
{"type": 1, "faction": "Realistas", "relation_change": -10}
{"type": 1, "faction": "Patriotas", "relation_change": 15}
```

### Cambio de Unidades (type: 2)
```json
{"type": 2, "unit_type": "infantry", "amount": 1, "location": "Buenos Aires"}
```

### Efecto Personalizado (type: 3)
```json
{"type": 3, "custom_effect": "increase_recruitment_rate", "value": 0.2}
```

## Recursos Disponibles

- **dinero**: Recursos económicos
- **comida**: Suministros alimentarios
- **municion**: Suministros militares
- **moral**: Moral de las tropas

## Ejemplos Prácticos

### Evento Histórico Simple
```json
{
  "id": "grito_dolores",
  "title": "El Grito de Dolores",
  "description": "Miguel Hidalgo lanza el grito que inicia la independencia mexicana.",
  "event_type": 0,
  "trigger_date": "1810/09/16",
  "effects": [
    {"type": 0, "resource": "moral", "amount": 15}
  ],
  "can_repeat": false,
  "category": "político"
}
```

### Evento Aleatorio con Opciones
```json
{
  "id": "motin_tropas",
  "title": "Motín de Tropas",
  "description": "Las tropas amenazan con rebelarse por falta de pago.",
  "event_type": 1,
  "random_chance": 0.05,
  "has_choices": true,
  "choices": [
    {
      "text": "Pagar soldadas inmediatamente",
      "effects": [
        {"type": 0, "resource": "dinero", "amount": -200},
        {"type": 0, "resource": "moral", "amount": 20}
      ]
    },
    {
      "text": "Imponer disciplina militar",
      "effects": [
        {"type": 0, "resource": "moral", "amount": -10}
      ]
    }
  ],
  "can_repeat": true,
  "category": "militar"
}
```

## Buenas Prácticas

1. **IDs Únicos**: Usa IDs descriptivos y únicos
2. **Fechas Históricas**: Verifica las fechas históricas reales
3. **Balance**: Equilibra costos y beneficios de las decisiones
4. **Coherencia**: Mantén coherencia histórica y temática
5. **Probabilidades**: Usa probabilidades bajas para eventos aleatorios (0.01-0.10)

## Instalación de Eventos Personalizados

1. Crea tu archivo JSON en `Data/Events/`
2. Sigue el formato especificado
3. El juego cargará automáticamente el archivo al iniciar
4. Usa nombres descriptivos para los archivos (ej: `eventos_argentina.json`)

## Depuración

- Revisa la consola del juego para errores de carga
- Verifica la sintaxis JSON con un validador
- Comprueba que los recursos referenciados existen
- Prueba los eventos con probabilidades altas durante desarrollo