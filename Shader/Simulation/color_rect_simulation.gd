extends ColorRect

var sim_shader = preload("res://Shader/Simulation/sim.gdshader")
var col_shader = preload("res://Shader/Simulation/color.gdshader")

var sim_a : SubViewport
var sim_b : SubViewport
var col_a : SubViewport
var col_b : SubViewport

var sim_rect_a : ColorRect
var sim_rect_b : ColorRect
var col_rect_a : ColorRect
var col_rect_b : ColorRect

var last_mouse_pos = Vector2.ZERO
var is_mouse_down = false
var sim_time = 0.0
var frame = 0

func _ready():
	# Internal simulation resolution (Lower = faster, Higher = crisper)
	var res = Vector2(800, 450)
	
	# Generate the Viewport Buffers
	sim_a = _create_viewport(res); sim_b = _create_viewport(res)
	col_a = _create_viewport(res); col_b = _create_viewport(res)
	
	sim_rect_a = _create_rect(sim_shader, res); sim_rect_b = _create_rect(sim_shader, res)
	col_rect_a = _create_rect(col_shader, res); col_rect_b = _create_rect(col_shader, res)
	
	sim_a.add_child(sim_rect_a); sim_b.add_child(sim_rect_b)
	col_a.add_child(col_rect_a); col_b.add_child(col_rect_b)
	
	add_child(sim_a); add_child(sim_b)
	add_child(col_a); add_child(col_b)
	
	# Setup the final display shader to draw the buffers to the screen
	self.material = ShaderMaterial.new()
	var display_shader = Shader.new()
	display_shader.code = """
	shader_type canvas_item;
	uniform sampler2D tex_display;
	void fragment() {
		vec4 c = texture(tex_display, UV);
		if (UV.y < 0.005 || UV.y > 0.995) c = vec4(0.0); // Cutoff edges
		COLOR = c;
	}
	"""
	self.material.shader = display_shader

func _create_viewport(res: Vector2) -> SubViewport:
	var vp = SubViewport.new()
	vp.size = res
	vp.render_target_clear_mode = SubViewport.CLEAR_MODE_NEVER
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.transparent_bg = true
	return vp
	
func _create_rect(shader: Shader, res: Vector2) -> ColorRect:
	var cr = ColorRect.new()
	cr.size = res
	var mat = ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("resolution", res)
	cr.material = mat
	return cr

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		is_mouse_down = event.pressed
		
func _process(delta):
	sim_time += delta
	var mouse_pos = get_local_mouse_position()
	
	# Map mouse input for the shader
	var m_vec = Vector4(mouse_pos.x, mouse_pos.y, 1.0 if is_mouse_down else 0.0, 0.0)
	var lm_vec = Vector4(last_mouse_pos.x, last_mouse_pos.y, 1.0 if is_mouse_down else 0.0, 0.0)
	
	var current_sim : ColorRect
	var current_col : ColorRect
	var out_tex : Texture2D
	
	# PING-PONG TEXTURE SWAPPING
	# We alternate which viewport is reading and which is writing every frame.
	if frame % 2 == 0:
		sim_rect_a.material.set_shader_parameter("tex_sim", sim_b.get_texture())
		col_rect_a.material.set_shader_parameter("tex_sim", sim_a.get_texture())
		col_rect_a.material.set_shader_parameter("tex_color", col_b.get_texture())
		current_sim = sim_rect_a
		current_col = col_rect_a
		out_tex = col_a.get_texture()
	else:
		sim_rect_b.material.set_shader_parameter("tex_sim", sim_a.get_texture())
		col_rect_b.material.set_shader_parameter("tex_sim", sim_b.get_texture())
		col_rect_b.material.set_shader_parameter("tex_color", col_a.get_texture())
		current_sim = sim_rect_b
		current_col = col_rect_b
		out_tex = col_b.get_texture()
		
	# Update Uniforms
	current_sim.material.set_shader_parameter("time", sim_time)
	current_sim.material.set_shader_parameter("mouse", m_vec)
	current_sim.material.set_shader_parameter("last_mouse", lm_vec)
	
	current_col.material.set_shader_parameter("time", sim_time)
	current_col.material.set_shader_parameter("mouse", m_vec)
	current_col.material.set_shader_parameter("last_mouse", lm_vec)
	
	self.material.set_shader_parameter("tex_display", out_tex)
	
	last_mouse_pos = mouse_pos
	frame += 1
