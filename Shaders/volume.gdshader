shader_type spatial;
render_mode unshaded;

uniform lowp float edgefade : hint_range(0, 1) = 0.2;
uniform lowp float globalfade : hint_range(0, 1) = 0.5;
//uniform sampler2D texture: source_color, filter_linear, repeat_disable;

void fragment () {
	float sinvresnel = pow(dot(normalize(NORMAL), normalize(VIEW)), (edgefade*25.0))*(1.0-globalfade);
	ALPHA = sinvresnel;
//	ALBEDO = texture(texture, UV).rgb;
}