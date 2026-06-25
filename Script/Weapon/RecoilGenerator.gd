@tool
extends Path2D
class_name RecoilGenerator

@export_category("Recoil Settings")
@export var magazine_size : int = 30
## How much to scale the drawing down. 
@export var recoil_scale : float = 0.01 

@export_category("Action")
## Click this to generate AND copy the code to your clipboard!
@export var generate_and_copy : bool = false :
	set(value):
		generate_and_copy = false 
		if Engine.is_editor_hint():
			_generate_gdscript_array()

@export_category("Generated Code")
## The text will also appear here just in case you want to see it.
@export_multiline var gdscript_output : String = ""

func _generate_gdscript_array():
	if not curve:
		print("Error: No curve drawn!")
		return
		
	var new_pattern : Array[Vector2] = []
	var total_length = curve.get_baked_length()
	var previous_point = curve.sample_baked(0.0)
	
	new_pattern.append(Vector2.ZERO)
	
	for i in range(1, magazine_size):
		var percent_along_curve = float(i) / float(magazine_size - 1)
		var distance = total_length * percent_along_curve
		
		var current_point = curve.sample_baked(distance)
		var kick_delta = (current_point - previous_point) * recoil_scale
		
		new_pattern.append(kick_delta)
		previous_point = current_point
		
	# --- FORMATTING AS GDSCRIPT ---
	# We start building the string block
	var code_string = "[\n"
	
	for v in new_pattern:
		# Use %.4f to round floats so you don't get ugly numbers like "0.10000000149"
		# Also, Godot's 2D Y-axis goes DOWN. If your 3D recoil needs to go UP, 
		# you might want to invert the Y axis here by making it -v.y
		code_string += "\tVector2(%.4f, %.4f),\n" % [v.x, v.y]
		
	code_string += "]"
	
	# Output to the inspector
	gdscript_output = code_string
	
	# --- AUTO COPY TO CLIPBOARD ---
	DisplayServer.clipboard_set(code_string)
	
	print("Success! Recoil array copied to clipboard. Ready to paste!")
