# Costos de Reclutamiento y Mantenimiento por Unidad

Este documento define los costos de recursos necesarios para el reclutamiento y mantenimiento de todas las unidades militares del juego Patria Grande: Independencia Sudamericana.

## Recursos Utilizados

El sistema utiliza los siguientes recursos:

### Alimentación
- **Pan**: Alimento básico para las tropas
- **Carne**: Proteína esencial para mantener la moral y fuerza
- **Vino**: Bebida alcohólica para celebraciones y moral
- **Aguardiente**: Licor fuerte para templanza en batalla

### Recursos Militares
- **Sables**: Armas blancas para combate cuerpo a cuerpo
- **Mosquetes**: Armas de fuego para infantería
- **Munición**: Balas y pólvora para las armas de fuego
- **Caballos**: Monturas para caballería y transporte de artillería
- **Cañones**: Artillería pesada para asedios y batallas

### Recursos Culturales/Religiosos
- **Tabaco**: Para mantener la moral y tradiciones
- **Biblias**: Para el apoyo espiritual y educación de las tropas

## Infantería

| Unidad      | Hombres | Reclutamiento (por unidad)                                                                              | Mantenimiento (por turno, por unidad)               |
|-------------|---------|---------------------------------------------------------------------------------------------------------|-----------------------------------------------------|
| Pelotón     |   50    | Pan: 100, Carne: 50, Sables: 2, Mosquetes: 2, Munición: 10, Vino: 5, Aguardiente: 5, Tabaco: 10, Biblias: 1  | Pan: 10, Carne: 5, Munición: 2, Tabaco: 2, Vino: 1, Aguardiente: 1, Biblias: 0.2  |
| Compañía    |  150    | Pan: 300, Carne: 150, Sables: 6, Mosquetes: 6, Munición: 30, Vino: 15, Aguardiente: 15, Tabaco: 30, Biblias: 2| Pan: 30, Carne: 15, Munición: 6, Tabaco: 6, Vino: 3, Aguardiente: 3, Biblias: 0.4 |
| Batallón    |  450    | Pan: 900, Carne: 450, Sables: 18, Mosquetes: 18, Munición: 90, Vino: 45, Aguardiente: 45, Tabaco: 90, Biblias: 4| Pan: 90, Carne: 45, Munición: 18, Tabaco: 18, Vino: 9, Aguardiente: 9, Biblias: 0.8|
| Regimiento  | 1350    | Pan: 2700, Carne: 1350, Sables: 54, Mosquetes: 54, Munición: 270, Vino: 135, Aguardiente: 135, Tabaco: 270, Biblias: 8| Pan: 270, Carne: 135, Munición: 54, Tabaco: 54, Vino: 27, Aguardiente: 27, Biblias: 1.6|

## Caballería

| Unidad      | Hombres | Reclutamiento (por unidad)                                                                                        | Mantenimiento (por turno, por unidad)                     |
|-------------|---------|-------------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------|
| Escuadrón   |   30    | Pan: 90, Carne: 60, Caballos: 30, Sables: 3, Munición: 5, Vino: 3, Aguardiente: 5, Tabaco: 8, Biblias: 1          | Pan: 9, Carne: 6, Caballos: 3, Munición: 2, Tabaco: 2, Vino: 1, Aguardiente: 1, Biblias: 0.2     |
| Compañía    |   90    | Pan: 270, Carne: 180, Caballos: 90, Sables: 9, Munición: 15, Vino: 9, Aguardiente: 15, Tabaco: 24, Biblias: 2      | Pan: 27, Carne: 18, Caballos: 9, Munición: 6, Tabaco: 6, Vino: 3, Aguardiente: 3, Biblias: 0.4   |
| Regimiento  |  270    | Pan: 810, Carne: 540, Caballos: 270, Sables: 27, Munición: 45, Vino: 27, Aguardiente: 45, Tabaco: 72, Biblias: 4   | Pan: 81, Carne: 54, Caballos: 27, Munición: 18, Tabaco: 18, Vino: 9, Aguardiente: 9, Biblias: 0.8|

## Artillería

| Unidad           | Hombres | Reclutamiento (por unidad)                                                                                                  | Mantenimiento (por turno, por unidad)            |
|------------------|---------|----------------------------------------------------------------------------------------------------------------------------|--------------------------------------------------|
| Batería Pequeña  |   30    | Pan: 100, Carne: 50, Cañones: 2, Munición: 40, Caballos: 4, Vino: 3, Aguardiente: 5, Tabaco: 8, Biblias: 1                 | Pan: 10, Carne: 5, Munición: 8, Caballos: 1, Tabaco: 2, Vino: 1, Aguardiente: 1, Biblias: 0.2   |
| Batería Mediana  |   60    | Pan: 200, Carne: 100, Cañones: 4, Munición: 80, Caballos: 8, Vino: 6, Aguardiente: 10, Tabaco: 16, Biblias: 2              | Pan: 20, Carne: 10, Munición: 16, Caballos: 2, Tabaco: 4, Vino: 2, Aguardiente: 2, Biblias: 0.4 |
| Batería Grande   |   90    | Pan: 300, Carne: 150, Cañones: 6, Munición: 120, Caballos: 12, Vino: 9, Aguardiente: 15, Tabaco: 24, Biblias: 3            | Pan: 30, Carne: 15, Munición: 24, Caballos: 3, Tabaco: 6, Vino: 3, Aguardiente: 3, Biblias: 0.6 |

## Notas de Implementación

### Reclutamiento
- Los costos de reclutamiento se pagan una sola vez al crear la unidad
- La ciudad debe tener suficientes recursos almacenados para completar el reclutamiento
- El reclutamiento falla si no hay recursos suficientes

### Mantenimiento
- Los costos de mantenimiento se consumen cada turno mientras la unidad exista
- Si una ciudad no puede proporcionar mantenimiento, la moral de las unidades baja
- Las unidades sin mantenimiento adecuado pueden desertar o perder efectividad

### Balance Económico
- Las ciudades generan recursos según su tamaño e importancia
- Los costos están balanceados para que las ciudades pequeñas puedan mantener pelotones/escuadrones
- Las ciudades grandes pueden sostener unidades más grandes y numerosas
- Los recursos culturales/religiosos son importantes para mantener la moral alta