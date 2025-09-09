extends Resource
class_name ResourceData

# Definición de datos para recursos económicos del juego
# Utilizado para configurar recursos de manera modular y accesible para modders

@export var id: String = ""
@export var nombre: String = ""
@export var categoria: String = ""  # "alimentacion", "economia", "militar", "cultural"
@export var descripcion: String = ""
@export var icon_path: String = ""
@export var base_value: float = 1.0  # Valor base del recurso
@export var es_consumible: bool = true  # Si se consume por turno
@export var production_rate: float = 0.0  # Producción base por turno
@export var consumption_rate: float = 0.0  # Consumo base por turno
@export var storage_limit: int = -1  # Límite de almacenamiento (-1 = ilimitado)

# Modificadores económicos
@export var trade_value: float = 1.0  # Valor en comercio
@export var production_cost: Dictionary = {}  # Recursos necesarios para producir este recurso
@export var production_buildings: Array[String] = []  # Edificios que pueden producir este recurso

# Efectos estratégicos
@export var affects_morale: float = 0.0  # Impacto en moral
@export var affects_research: float = 0.0  # Impacto en investigación
@export var affects_diplomacy: float = 0.0  # Impacto en diplomacia

func _init():
	# Valores por defecto
	pass

func get_display_name() -> String:
	return nombre if nombre != "" else id

func get_total_value(cantidad: int) -> float:
	return cantidad * base_value

func can_produce() -> bool:
	return production_rate > 0.0

func can_consume() -> bool:
	return es_consumible and consumption_rate > 0.0

func get_net_change() -> float:
	return production_rate - consumption_rate

func is_strategic_resource() -> bool:
	return affects_morale != 0.0 or affects_research != 0.0 or affects_diplomacy != 0.0