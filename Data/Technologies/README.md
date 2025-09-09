# Tecnologías de Ejemplo para Patria Grande

Este directorio contiene ejemplos de tecnologías que pueden ser investigadas en el juego.

## Estructura de una Tecnología

Las tecnologías se definen en el código con los siguientes campos:

```gdscript
{
  "id": "identificador_unico",
  "nombre": "Nombre Visible",
  "descripcion": "Descripción detallada de la tecnología",
  "categoria": "militar|economia|cultura|naval",
  "prerequisitos": ["tech1", "tech2"],
  "costo_investigacion": 100,
  "tiempo_turnos": 5,
  "recursos_requeridos": {
    "dinero": 50,
    "oro": 10
  },
  "bonificaciones": {
    "moral_tropas": 10,
    "generacion_dinero": 15
  },
  "unidades_desbloqueadas": ["nueva_unidad"],
  "edificios_desbloqueados": ["nuevo_edificio"],
  "mecanicas_desbloqueadas": ["nueva_mecanica"],
  "posicion_x": 0,
  "posicion_y": 0,
  "nivel_arbol": 1
}
```

## Tecnologías Implementadas

### Nivel 1 (Tecnologías Básicas)
1. **Disciplina Militar** - Mejora el entrenamiento básico de tropas
2. **Economía Básica** - Principios de administración económica
3. **Diplomacia Inicial** - Bases de relaciones diplomáticas

### Nivel 2 (Tecnologías Avanzadas)
1. **Tácticas Avanzadas** - Requiere Disciplina Militar
2. **Industria Artesanal** - Requiere Economía Básica

## Cómo Agregar Nuevas Tecnologías

1. Editar `Scripts/Manager/TechnologyManager.gd`
2. Agregar la nueva tecnología en `create_example_technologies()`
3. Definir todos los campos necesarios
4. Reiniciar el juego para que se carguen los cambios

## Controles

- **T**: Abrir/cerrar árbol tecnológico
- **Click** en tecnología: Ver detalles
- **Iniciar Investigación**: Comenzar a investigar (si cumple requisitos)
- **Espacio**: Avanzar turno (procesa investigación)

## Mecánicas

- Las tecnologías requieren puntos de investigación para completarse
- Se generan 10 puntos base por turno + bonificaciones de tecnologías completadas
- Se pueden requerir recursos adicionales (dinero, oro, etc.)
- Al completar, se aplican bonificaciones y se desbloquean unidades/edificios
- Las tecnologías aparecen en gris si no se pueden investigar (falta prerequisitos)
- Las tecnologías en investigación aparecen en amarillo
- Las tecnologías completadas aparecen en verde