shader_type spatial;
render_mode blend_mix;

uniform vec4 color: source_color = vec4(0.0, 1.0, 0.0, 0.5);
uniform sampler2D texture_albedo : source_color;

void fragment() {
	ALBEDO = color.rgb;
	ALPHA = color.a;
	ALBEDO = texture(texture_albedo, UV).rgb;
}