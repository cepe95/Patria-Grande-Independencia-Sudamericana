extends Resource
class_name CiudadResource

## Custom Resource para el sistema de ciudades de Patria Grande
## 
## Este resource define las propiedades básicas de una ciudad en el juego.
## Para expandir o editar ciudades:
## 1. Modifica las propiedades @export según necesites
## 2. Crea nuevos archivos .tres en Data/Ciudades/ usando este resource
## 3. Ajusta pos_mapa según las coordenadas del mapa (resolución 1152x768)
## 4. El CityManager puede cargar todas las ciudades desde Data/Ciudades/
##
## Propiedades principales:
## - nombre: Nombre de la ciudad
## - tipo: Tipo de ciudad (villa, ciudad, capital, etc.)
## - poblacion: Número de habitantes
## - pos_mapa: Posición en el mapa como Vector2
## - recursos_base: Recursos que produce la ciudad
## - produccion_actual: Producción actual de recursos
## - capacidad_reclutamiento: Capacidad para reclutar unidades
## - especiales: Características especiales de la ciudad
## - ultimo_tick: Último tick de actualización procesado

@export var nombre: String = ""
@export var tipo: String = "ciudad"
@export var poblacion: int = 0
@export var pos_mapa: Vector2 = Vector2.ZERO
@export var recursos_base: Array[String] = []
@export var produccion_actual: Dictionary = {}
@export var capacidad_reclutamiento: int = 0
@export var especiales: Array[String] = []
@export var ultimo_tick: int = 0