# Sistema de Diplomacia

## Descripción General

El sistema de diplomacia permite a los jugadores gestionar las relaciones entre facciones en "Patria Grande: Independencia Sudamericana". Los jugadores pueden declarar guerra, hacer la paz, formar alianzas y establecer tratados comerciales con otras facciones.

## Características Principales

### 🤝 Relaciones Diplomáticas
- **Estados disponibles**: Neutral, Paz, Alianza, Tratado Comercial, Guerra, Hostil
- **Relaciones bidireccionales**: Los cambios afectan a ambas facciones
- **Validación contextual**: No se puede declarar la paz sin guerra previa

### 📋 Sistema de Propuestas
- **Propuestas enviables**: Declaración de guerra, paz, alianza, tratado comercial
- **Sistema de aceptación/rechazo**: Las facciones pueden responder a propuestas
- **Limpieza automática**: Las propuestas antiguas se eliminan automáticamente

### 🤖 IA Básica
- **Propuestas automáticas**: Las facciones de IA envían propuestas aleatorias
- **Comportamiento contextual**: La IA considera el estado actual de las relaciones
- **Procesamiento por turnos**: Los eventos diplomáticos se procesan cada turno

### 💰 Efectos en el Juego
- **Bonificaciones comerciales**: Los tratados comerciales generan ingresos adicionales
- **Penalizaciones de guerra**: La guerra reduce la moral de las facciones
- **Beneficios de alianza**: Las alianzas aumentan el prestigio

## Cómo Usar el Sistema

### Acceso al Panel de Diplomacia
1. Abre el juego y ve al HUD principal
2. Haz clic en el botón "Diplomacia" en las acciones rápidas
3. Se abrirá el panel de diplomacia con la lista de facciones

### Gestionar Relaciones
1. **Seleccionar facción**: Haz clic en "Seleccionar" junto a una facción
2. **Ver estado actual**: El panel muestra el estado diplomático actual
3. **Realizar acciones**: Usa los botones disponibles para enviar propuestas
4. **Gestionar propuestas**: Acepta o rechaza propuestas en la sección inferior

### Responder a Propuestas
- Las propuestas dirigidas a tu facción aparecen en la sección "Propuestas Pendientes"
- Cada propuesta tiene botones "Aceptar" y "Rechazar"
- Las decisiones tienen efectos inmediatos en las relaciones

### Ver Reporte Diplomático
- Haz clic en "Reporte Diplomático" para ver un resumen completo
- El reporte muestra todas las relaciones actuales y propuestas pendientes
- Se actualiza automáticamente al cambiar las relaciones

## Reglas de Validación

### Restricciones de Propuestas
- **Guerra**: No se puede declarar guerra si ya están en guerra
- **Paz**: Solo se puede proponer paz durante guerra o hostilidad
- **Alianza**: No se puede hacer alianza durante guerra activa
- **Comercio**: No se puede comerciar durante guerra

### Transiciones de Estado
- **Neutral → Cualquier estado**: Permitido
- **Guerra → Paz**: Requiere propuesta y aceptación
- **Paz → Guerra**: Siempre permitido (romper tratado)
- **Alianza → Guerra**: Permitido (traición)

## Efectos Automáticos

### Cada Turno se Aplican:
- **+10 dinero** por cada socio comercial
- **-5 moral** por cada enemigo en guerra
- **+2 prestigio** por cada aliado

### Eventos Generados:
- Cambios diplomáticos aparecen en el log de eventos
- Diferentes tipos de eventos tienen colores distintivos
- Los eventos incluyen timestamp del turno

## Integración con Otros Sistemas

### Sistema de Turnos
- Los eventos diplomáticos se procesan automáticamente cada turno
- La IA genera propuestas con probabilidad del 10% por turno
- Los efectos económicos se aplican al final de cada turno

### Sistema de Eventos
- Todas las acciones diplomáticas generan eventos en el log
- Los eventos se categorizan por tipo (info, warning, success)
- El histórico de eventos se mantiene durante la partida

### Sistema de Facciones
- Cada facción tiene métodos de conveniencia para consultar relaciones
- Los efectos diplomáticos se aplican directamente a los recursos
- Las relaciones son persistentes entre turnos

## Archivos del Sistema

### Scripts Principales
- `Systems/DiplomacyManager.gd` - Manager principal del sistema
- `Scripts/UI/DiplomacyPanel.gd` - Panel de interfaz de usuario
- `Data/Factions/FactionData.gd` - Métodos de conveniencia para facciones

### Escenas de UI
- `Scenes/UI/DiplomacyPanel.tscn` - Panel de diplomacia
- `Scenes/UI/MainHUD.tscn` - HUD principal (incluye botón de diplomacia)

### Documentación
- `Docs/DiplomacyModdingGuide.md` - Guía completa para modders
- `Scripts/Tests/DiplomacyTest.gd` - Script de pruebas del sistema

## Extensibilidad para Modders

El sistema está diseñado para ser extensible:

### APIs para Modders
- `add_custom_diplomatic_status()` - Agregar nuevos estados
- `add_custom_proposal_type()` - Agregar nuevas propuestas
- `register_custom_validation_rule()` - Agregar reglas personalizadas

### Señales Disponibles
- `diplomatic_status_changed` - Cuando cambia una relación
- `proposal_received` - Cuando se recibe una propuesta
- `diplomatic_action_performed` - Cuando se realiza una acción

### Ejemplos de Extensión
- Sistema de vasallaje
- Matrimonios dinásticos
- Tributos y pagos
- Embajadas y espionaje

## Pruebas y Testing

### Script de Pruebas
Ejecuta `Scripts/Tests/DiplomacyTest.gd` para validar:
- Funcionalidad del DiplomacyManager
- Integración con FactionData
- Reglas de validación
- Sistema de propuestas
- Efectos diplomáticos
- Generación de reportes

### Escena de Pruebas
- `Scenes/Tests/DiplomacyTestScene.tscn` - Escena para ejecutar pruebas
- Muestra resultados en la consola
- Valida que todos los componentes funcionen correctamente

## Notas de Desarrollo

### Versión Actual: 1.0
- ✅ Sistema básico de relaciones diplomáticas
- ✅ Panel de UI funcional
- ✅ Integración con sistema de turnos
- ✅ IA básica para propuestas automáticas
- ✅ Efectos económicos automáticos
- ✅ Documentación para modders

### Futuras Mejoras Posibles
- Diplomacia multi-facción (acuerdos de tres partes)
- Sistema de reputación y credibilidad
- Eventos diplomáticos narrativos
- Condiciones más complejas para propuestas
- Interfaz mejorada con iconos y animaciones

---

Para más información sobre cómo extender el sistema, consulta `Docs/DiplomacyModdingGuide.md`.