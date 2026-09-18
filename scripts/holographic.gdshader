shader_type canvas_item;

void fragment() {
	vec4 fish = COLOR;
	float sweep = UV.x * 1.3 + UV.y * 0.7 - TIME * 0.35;
	vec3 rainbow = 0.65 + 0.35 * cos(6.28318 * (sweep + vec3(0.0, 0.333, 0.667)));
	float shine = pow(max(0.0, sin(sweep * 6.28318)), 14.0);
	// Preserve the sprite silhouette and dark details under the shifting foil colours.
	float lightness = dot(fish.rgb, vec3(0.299, 0.587, 0.114));
	COLOR = vec4(mix(fish.rgb, rainbow * (0.35 + lightness * 0.65), 0.7) + shine * 0.22, fish.a);
}
