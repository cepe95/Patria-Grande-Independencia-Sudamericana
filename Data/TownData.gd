extends Resource
class_name TownData

@export var nombre: String = ""
@export var tipo: String = "villa" # Ej: villa, ciudad, fortaleza
@export var importancia: int = 1
@export var estado: String = "neutral" # Ej: neutral, controlado
@export var faccion: String = "" # Nombre de la facción que lo controla
