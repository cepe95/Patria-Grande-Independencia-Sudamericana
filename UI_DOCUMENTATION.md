# Documentación Visual del Sistema de Tecnologías

## Flujo de Usuario

### 1. Acceso al Sistema
```
MainHUD -> Tecla T -> TechnologyPanel (se abre)
```

### 2. Navegación del Árbol
```
TechnologyPanel
├── Header (Título + Recursos + Cerrar)
├── TreeContainer (ScrollContainer)
│   └── TreeGrid (Botones de tecnologías organizados espacialmente)
└── DetailsContainer
    ├── Nombre de tecnología
    ├── Descripción
    ├── Costos y requisitos
    ├── Barra de progreso (si está en investigación)
    └── Botón "Iniciar Investigación"
```

### 3. Estados Visuales de Tecnologías
- **🔘 Gris**: No disponible (falta prerequisitos)
- **⚪ Blanco**: Disponible para investigar
- **🟡 Amarillo**: En investigación actual
- **🟢 Verde**: Completada

### 4. Integración con Turnos
```
Espacio (Next Turn) -> TechnologyManager.process_turn() -> 
Progreso +10 puntos -> Notificación si se completa
```

## Ubicación en MainHUD

```
MainHUD.tscn
└── UI (CanvasLayer)
    ├── ResourceBar (existente)
    ├── CityUnitListPanel (existente)
    ├── DetailsPanel (existente)
    ├── EventPanel (existente)
    ├── PauseMenu (existente)
    └── TechnologyPanel (NUEVO - visible=false por defecto)
```

## Eventos y Notificaciones

```
EventPanel muestra:
- "Presiona T para abrir el árbol tecnológico" (al inicio)
- "Investigación iniciada: [Nombre]" (al iniciar)
- "¡Investigación completada: [Nombre]!" (al completar)
- "Efectos obtenidos: +X moral, +Y dinero..." (detalle de efectos)
```

## Estructura del Árbol Tecnológico

```
Nivel 1:     [Disciplina]  [Economía]   [Diplomacia]
                 |            |             |
Nivel 2:     [Tácticas]   [Industria]       
```

Posiciones (x, y, nivel):
- Disciplina Militar: (0, 0, 1)
- Economía Básica: (1, 0, 1)  
- Diplomacia Inicial: (2, 0, 1)
- Tácticas Avanzadas: (0, 1, 2) - requiere Disciplina
- Industria Artesanal: (1, 1, 2) - requiere Economía