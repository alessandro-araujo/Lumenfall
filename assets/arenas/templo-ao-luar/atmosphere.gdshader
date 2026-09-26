shader_type canvas_item;
render_mode unshaded;

// Driven by the arena clock so pausing also freezes the landscape.
uniform float stage_time = 0.0;

float region(vec2 p, vec4 bounds, float feather) {
	vec2 enter = smoothstep(bounds.xy, bounds.xy + vec2(feather), p);
	vec2 leave = 1.0 - smoothstep(bounds.zw - vec2(feather), bounds.zw, p);
	return enter.x * enter.y * leave.x * leave.y;
}

void fragment() {
	vec2 p = UV;
	vec2 uv = p;
	float t = stage_time;
	// Each banner is pinned at its upper edge. Restrict deformation to cloth.
	float flag_left = region(p, vec4(0.734, 0.376, 0.780, 0.515), 0.007);
	float flag_right = region(p, vec4(0.853, 0.358, 0.911, 0.501), 0.008);
	float flag = max(flag_left, flag_right);
	float hem = clamp((p.y - 0.367) / 0.148, 0.0, 1.0);
	uv.x += flag * hem * (sin(p.y * 65.0 - t * 3.1) * 0.0045
		+ sin(p.y * 109.0 - t * 4.4) * 0.0015);
	uv.y += flag * hem * sin(p.x * 72.0 - t * 3.1) * 0.0018;
	// Breeze moves cloud textures only in the open sky, clear of temple/moon.
	float clouds = region(p, vec4(0.205, 0.035, 0.590, 0.150), 0.025);
	uv.x += clouds * sin(t * 0.27 + p.y * 13.0) * 0.014;
	// Low mist drifting through the distant valley.
	float mist = region(p, vec4(0.278, 0.365, 0.465, 0.570), 0.045);
	uv.x += mist * sin(t * 0.36 + p.y * 18.0) * 0.004;
	// Sway blossom clusters at the sides, leaving the stone floor untouched.
	float canopy = max(region(p, vec4(0.0, 0.0, 0.220, 0.260), 0.018),
		region(p, vec4(0.810, 0.0, 1.0, 0.350), 0.018));
	vec3 original = texture(TEXTURE, p).rgb;
	float pink = smoothstep(0.035, 0.115, original.r - original.g)
		* smoothstep(0.20, 0.44, original.r);
	uv += canopy * pink * vec2(sin(t * 1.5 + p.y * 25.0) * 0.0025,
		cos(t * 1.2 + p.x * 22.0) * 0.0018);
	// Two phase-shifted downward samples avoid a visible reset in the waterfall.
	float water = region(p, vec4(0.027, 0.336, 0.058, 0.482), 0.008);
	float phase = fract(t * 0.48);
	float phase_b = fract(t * 0.48 + 0.5);
	vec2 flow = vec2(sin(p.y * 160.0 + t * 3.0) * 0.001, 0.0);
	vec4 stream_a = texture(TEXTURE, p + flow - vec2(0.0, phase * 0.025));
	vec4 stream_b = texture(TEXTURE, p + flow - vec2(0.0, phase_b * 0.025));
	vec4 color = texture(TEXTURE, uv);
	color = mix(color, mix(stream_a, stream_b, abs(phase - 0.5) * 2.0), water);
	color.rgb += water * (0.035 + 0.035 * sin(p.y * 430.0 - t * 13.0));
	color.rgb *= 1.0 + flag * sin(p.y * 65.0 - t * 3.1) * hem * 0.12;
	COLOR = color;
}
