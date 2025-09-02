extends Node

var facciones := {}
func _ready():
	var patriota := load("res://Data/Factions/Patriota.tres")
	var realista := load("res://Data/Factions/Realista.tres")
	registrar_faccion(patriota.nombre, patriota)
	registrar_faccion(realista.nombre, realista)


func inicializar_facciones():
	var patriota := FactionData.new()
	patriota.nombre = "Patriota"
	patriota.color = Color(0.2, 0.6, 0.2)
	patriota.bandera_path = "res://assets/facciones/patriota.png"
	patriota.ideologia = "Republicanismo"
	patriota.recursos = {
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

	var realista := FactionData.new()
	realista.nombre = "Realista"
	realista.color = Color(0.6, 0.2, 0.2)
	realista.bandera_path = "res://assets/facciones/realista.png"
	realista.ideologia = "Monarquismo"
	realista.recursos = {
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

	registrar_faccion(patriota.nombre, patriota)
	registrar_faccion(realista.nombre, realista)

func registrar_faccion(nombre: String, data: FactionData):
	facciones[nombre] = data

func obtener_faccion(nombre: String) -> FactionData:
	return facciones.get(nombre, null)

func faccion_existe(nombre: String) -> bool:
	return facciones.has(nombre)

func agregar_recursos(nombre: String, cantidad: int):
	if faccion_existe(nombre):
		facciones[nombre].recursos += cantidad

func reiniciar():
	facciones.clear()
