extends Resource
class_name TownData

@export var nombre: String = ""
@export var tipo: String = "villa" # Ej: villa, ciudad, fortaleza, capital
@export var importancia: int = 1
@export var estado: String = "neutral"
@export var faccion: String = "" # Nombre de la facción que lo controla

@export var recursos: Array[String] = []
@export var manpower: int = 0
@export var unidades_sostenibles: Array[String] = []
@export var oficiales_disponibles: Array[String] = []
@export var comentario: String = ""
