extends RefCounted
class_name MapRoom

enum Type { UNASSIGNED, MONSTER, ELITE, REST, SHOP, EVENT, TREASURE }

var x: int
var y: int
var room_type: Type = Type.UNASSIGNED
var next_nodes: Array[MapRoom] = [] # Nodes connected above this one
var parents: Array[MapRoom] = []    # Nodes connected below this one

func _init(_x: int, _y: int):
	x = _x
	y = _y
