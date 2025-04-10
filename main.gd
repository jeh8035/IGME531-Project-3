extends TextureRect

const thresh : float = 1.0
var i : float = 0.0

var screen_size : Vector2i

var output_tex : RID
var in_tex : RID

var rd : RenderingDevice

func _ready() -> void:
	screen_size = Vector2(floor(texture.get_size().x), floor(texture.get_size().y))
	
	rd = RenderingServer.create_local_rendering_device()
	var shader_file := load("res://main.glsl")
	var shader_spirv: RDShaderSPIRV = shader_file.get_spirv()
	var shader := rd.shader_create_from_spirv(shader_spirv)
	
	var format := RDTextureFormat.new()
	format.format = RenderingDevice.DATA_FORMAT_R32G32B32A32_SFLOAT
	format.width = screen_size.x
	format.height = screen_size.y
	format.usage_bits = RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT | RenderingDevice.TEXTURE_USAGE_STORAGE_BIT | RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT
	
	var view = RDTextureView.new()
	
	# Output Image
	var output_image := Image.create(format.width, format.height, false, Image.FORMAT_RGBAF)
	output_tex = rd.texture_create(format, view, [output_image.get_data()])
	var output_tex_uniform := RDUniform.new()
	output_tex_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	output_tex_uniform.binding = 0
	output_tex_uniform.add_id(output_tex)
	
	# Input image
	var sampler_state := RDSamplerState.new()
	var sampler = rd.sampler_create(sampler_state)

	var format_in := RDTextureFormat.new()
	format_in.format = RenderingDevice.DATA_FORMAT_R32G32B32A32_SFLOAT
	format_in.width = screen_size.x
	format_in.height = screen_size.y
	format_in.usage_bits = RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT | RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT | RenderingDevice.TEXTURE_USAGE_STORAGE_BIT | RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT

	var img := texture.get_image().duplicate(true)
	img.convert(Image.FORMAT_RGBAF)
	var view_input = RDTextureView.new()
	
	in_tex = rd.texture_create(format_in, view_input, [img.get_data()])
	var sampler_uniform := RDUniform.new()
	sampler_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_SAMPLER_WITH_TEXTURE
	sampler_uniform.binding = 1
	sampler_uniform.add_id(sampler)
	sampler_uniform.add_id(in_tex)
	
	
	var uniform_set := rd.uniform_set_create([output_tex_uniform, sampler_uniform], shader, 0)

	var pipeline := rd.compute_pipeline_create(shader)
	var compute_list := rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
	rd.compute_list_bind_uniform_set(compute_list, uniform_set, 0)
	rd.compute_list_dispatch(compute_list, (screen_size.x - 1) / 8 + 1, (screen_size.x - 1) / 8 + 1, 1)
	rd.compute_list_end()


func _process(delta: float) -> void:
	i += delta
	if i > thresh:
		rd.submit()
		rd.sync()
		
		var byte_data : PackedByteArray = rd.texture_get_data(output_tex, 0)
		var image := Image.create_from_data(screen_size.x, screen_size.y, false, Image.FORMAT_RGBAF, byte_data)
		
		texture = ImageTexture.create_from_image(image)
		
		#rd.texture_update(in_tex, 0, rd.texture_get_data(image, 0))
