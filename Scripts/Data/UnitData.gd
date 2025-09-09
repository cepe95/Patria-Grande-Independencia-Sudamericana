extends Resource
class_name UnitData

@export var nombre: String
@export var rama: String         # infanteria, caballeria, artilleria
@export var nivel: int           # 1 = pelotón, etc.
@export var tamaño: int          # cantidad de efectivos
@export var fusionable: bool = true
@export var icono: Texture2D
@export var cantidad: int = 100
@export var moral: int = 50           # Moral de la unidad (0-100)
@export var experiencia: int = 0      # Experiencia de la unidad (0-100)
# Costos de reclutamiento (pago único al crear la unidad)
@export var costos_reclutamiento : Dictionary = {}

# Costos de mantenimiento (consumo por turno)
@export var costos_mantenimiento : Dictionary = {
	"Pan": 0.0,
	"Carne": 0.0,
	"Sables": 0.0,
	"Mosquetes": 0.0,
	"Municion": 0.0,
	"Caballos": 0.0,
	"Cañones": 0.0,
	"Vino": 0.0,
	"Aguardiente": 0.0,
	"Tabaco": 0.0,
	"Biblias": 0.0
}

# DEPRECATED: Usar costos_mantenimiento en su lugar
@export var consumo : Dictionary = {
	"Biblias": 0.01,
	"Vino": 0.01,
	"Verdura": 0.005,
	"Tabaco": 0.001,
	"Fruta": 0.005,
	"Aguardiente": 0.01,
	"Pan": 0.01,
	"Carne": 0.005,
	"Municion": 0.02,
	"Caballos": 0.01,
	"Polvora": 0.015,
	"Dinero": 0.001,
	"Oro": 0.0001,
	"Plata": 0.0005,
	"Cañones": 0.005,
	"Lanzas": 0.01,
	"Mosquetes": 0.01,
	"Sables": 0.01
}
