extends Resource
class_name FactionData

@export var nombre: String
@export var color: Color
@export var bandera_path: String
@export var ideologia: String
@export var recursos := {
	# Alimentación
	"pan": 0,
	"carne": 0,
	"fruta": 0,
	"verdura": 0,
	"vino": 0,
	"aguardiente": 0,
	"tabaco": 0,

	# Economía
	"dinero": 0,
	"oro": 0,
	"plata": 0,

	# Militar
	"municion": 0,
	"polvora": 0,
	"mosquetes": 0,
	"sables": 0,
	"lanzas": 0,
	"cañones": 0,
	"caballos": 0,

	# Cultural
	"biblias": 0,

	# Estado estratégico
	"moral": 100,
	"prestigio": 0
}

# Nuevo: Estado diplomático
@export var diplomatic_personality: String = "normal"  # peaceful, normal, aggressive, warmonger
@export var known_factions: Array[String] = []
@export var diplomatic_modifiers: Dictionary = {
	"aggression": 0.3,
	"trade_preference": 0.5,
	"alliance_preference": 0.5,
	"independence_support": 0.5
}
