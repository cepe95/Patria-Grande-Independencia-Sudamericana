extends Node

var food_resources := {}
var economic_resources := {}
var military_resources := {}
var cultural_resources := {}

func _ready():
	load_all_resources()

func load_all_resources():
	food_resources = load_resources_from("res://data/resources/alimentacion/")
	economic_resources = load_resources_from("res://data/resources/economia/")
	military_resources = load_resources_from("res://data/resources/militar/")
	cultural_resources = load_resources_from("res://data/resources/cultural/")

func load_resources_from(path: String) -> Dictionary:
	var dir := DirAccess.open(path)
	var result := {}
	if dir:
		dir.list_dir_begin()
		var file_name := dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres"):
				var full_path := path + file_name
				var res := load(full_path)
				if res:
					result[file_name.get_basename()] = res
			file_name = dir.get_next()
		dir.list_dir_end()
	return result
