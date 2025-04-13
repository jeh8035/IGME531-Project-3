extends TextureRect

const time_thresh : float = 1/60
var time_i : float = 0.0
var time_count : float = time_thresh

var screen_size : Vector2i

var output_tex : RID
var input_tex : RID
var sampler : RID
var sampler_state : RDSamplerState
var format_in : RDTextureFormat
var view_input : RDTextureView
var sampler_uniform : RDUniform

var output_tex_uniform : RDUniform
var shader : RID

var rd : RenderingDevice

var color : int = 0
const colors = [Color.WHITE, Color.BLACK, Color.BLUE, Color.RED, Color.GREEN, Color.CYAN, Color.MAGENTA, Color.YELLOW]

func _ready() -> void:
	screen_size = Vector2(floor(texture.get_size().x), floor(texture.get_size().y))
	
	# Input texture info
	sampler_uniform = RDUniform.new()
	view_input = RDTextureView.new()
	sampler_state = RDSamplerState.new()
	format_in = RDTextureFormat.new()
	format_in.format = RenderingDevice.DATA_FORMAT_R32G32B32A32_SFLOAT
	format_in.width = screen_size.x
	format_in.height = screen_size.y
	format_in.usage_bits = RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT | RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT | RenderingDevice.TEXTURE_USAGE_STORAGE_BIT | RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT
	
	# Create render device	
	rd = RenderingServer.create_local_rendering_device()
	var shader_file : RDShaderFile = load("res://main.glsl")
	
	
	var shader_spirv: RDShaderSPIRV = shader_file.get_spirv()
	shader = rd.shader_create_from_spirv(shader_spirv)
	
	var format := RDTextureFormat.new()
	format.format = RenderingDevice.DATA_FORMAT_R32G32B32A32_SFLOAT
	format.width = screen_size.x
	format.height = screen_size.y
	format.usage_bits = RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT | RenderingDevice.TEXTURE_USAGE_STORAGE_BIT | RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT
	
	var view := RDTextureView.new()
	
	# Output Image
	var output_image := Image.create(format.width, format.height, false, Image.FORMAT_RGBAF)
	output_tex = rd.texture_create(format, view, [output_image.get_data()])
	output_tex_uniform = RDUniform.new()
	output_tex_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	output_tex_uniform.binding = 0
	output_tex_uniform.add_id(output_tex)

	# Input image
	_setup_compute_shader()


func _setup_compute_shader():
	sampler = rd.sampler_create(sampler_state)

	var img := texture.get_image()
	img.convert(Image.FORMAT_RGBAF)
	
	if input_tex: rd.free_rid(input_tex)
	input_tex = rd.texture_create(format_in, view_input, [img.get_data()])
	sampler_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_SAMPLER_WITH_TEXTURE
	sampler_uniform.binding = 1
	sampler_uniform.clear_ids()
	sampler_uniform.add_id(sampler)
	sampler_uniform.add_id(input_tex)
	var uniform_set := rd.uniform_set_create([output_tex_uniform, sampler_uniform], shader, 0)

	var pipeline := rd.compute_pipeline_create(shader)
	var compute_list := rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
	rd.compute_list_bind_uniform_set(compute_list, uniform_set, 0)
	rd.compute_list_dispatch(compute_list, (screen_size.x - 1) / 8 + 1, (screen_size.x - 1) / 8 + 1, 1)
	rd.compute_list_end()

func _process(delta: float) -> void:
	time_i += delta
	if time_i > time_count:
		time_count += time_thresh
		
		rd.submit()
		rd.sync()
		
		var byte_data : PackedByteArray = rd.texture_get_data(output_tex, 0)
		var image := Image.create_from_data(screen_size.x, screen_size.y, false, Image.FORMAT_RGBAF, byte_data)
		
		if Input.is_action_pressed("mouse_click"):
			var mouse_pos : Vector2 = get_viewport().get_mouse_position()
			mouse_pos *= Vector2(screen_size) / Vector2(get_viewport().size)
			const radius = 20
			for x : int in range(-radius, radius):
				for y : int in range(-radius, radius):
					if pow(x, 2) + pow(y, 2) < pow(radius, 2):
						var abs_pos := mouse_pos + Vector2(x, y)
						abs_pos.x = clamp(abs_pos.x, 0, screen_size.x - 1)
						abs_pos.y = clamp(abs_pos.y, 0, screen_size.y - 1)
						image.set_pixel(abs_pos.x, abs_pos.y, colors[color])
		
		texture = ImageTexture.create_from_image(image)
		
		_setup_compute_shader()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("change_color"):
		color += 1
		if color >= colors.size(): color = 0
		
