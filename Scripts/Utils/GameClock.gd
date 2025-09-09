extends Node

signal date_changed(new_date)
signal campaign_finished

@export var seconds_per_day: float = 0.5 # Puedes ajustar la velocidad del tiempo aquí

var start_date: Date
var end_date: Date
var current_date: Date

var running := false
var _elapsed := 0.0

func _ready():
	add_to_group("game_clock")  # Agregar a grupo para fácil identificación
	start_date = Date.new(1816, 1, 1)
	end_date = Date.new(1818, 1, 1)
	current_date = start_date.copy()

func _process(delta):
	if running:
		_elapsed += delta
		while _elapsed >= seconds_per_day:
			_elapsed -= seconds_per_day
			advance_day()

func advance_day():
	current_date.next_day()
	emit_signal("date_changed", current_date)
	if current_date.is_greater_or_equal(end_date):
		running = false
		emit_signal("campaign_finished")

func start_clock():
	running = true

func pause_clock():
	running = false

func reset_clock():
	current_date = start_date.copy()
	_elapsed = 0.0
