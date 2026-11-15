shader_type canvas_item;
// Globo de Marte en tiempo real: esfera facetada (celdas de Voronoi) con rotación y luz.
// Es una representación artística del juego, no un mapa de datos de la NASA.
uniform float spin = 0.0;   // longitud central, en radianes
uniform float tilt = 0.25;  // inclinación de la vista
uniform vec3 base_color : source_color = vec3(0.79, 0.38, 0.25);

vec3 hash3(vec3 p) {
	p = vec3(dot(p, vec3(127.1, 311.7, 74.7)), dot(p, vec3(269.5, 183.3, 246.1)), dot(p, vec3(113.5, 271.9, 124.6)));
	return fract(sin(p) * 43758.5453);
}

// Devuelve un valor aleatorio constante por celda: da el aspecto low-poly.
float cell(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	float best = 8.0;
	float value = 0.0;
	for (int x = -1; x <= 1; x++) for (int y = -1; y <= 1; y++) for (int z = -1; z <= 1; z++) {
		vec3 g = vec3(float(x), float(y), float(z));
		vec3 o = hash3(i + g);
		float d = length(g + o - f);
		if (d < best) { best = d; value = o.x; }
	}
	return value;
}

void fragment() {
	vec2 p = (UV - 0.5) * 2.0;
	float r2 = dot(p, p);
	if (r2 > 1.0) {
		float glow = smoothstep(1.18, 1.0, sqrt(r2));
		COLOR = vec4(1.0, 0.62, 0.36, glow * 0.22);
	} else {
		vec3 n = vec3(p.x, -p.y, sqrt(1.0 - r2));
		float ct = cos(tilt); float st = sin(tilt);
		n = vec3(n.x, n.y * ct - n.z * st, n.y * st + n.z * ct);
		float cs = cos(spin); float ss = sin(spin);
		vec3 s = vec3(n.x * cs + n.z * ss, n.y, -n.x * ss + n.z * cs);
		float big = cell(s * 2.6);
		float small = cell(s * 7.0 + 11.0);
		vec3 dark = base_color * 0.62;
		vec3 light = base_color * 1.22 + vec3(0.06, 0.03, 0.0);
		vec3 col = mix(dark, light, big * 0.7 + small * 0.3);
		col = mix(col, vec3(0.96, 0.9, 0.82), smoothstep(0.86, 0.95, abs(s.y)));  // casquetes polares
		vec3 view_n = vec3(p.x, -p.y, sqrt(1.0 - r2));
		float lit = clamp(dot(view_n, normalize(vec3(-0.55, 0.6, 0.6))), 0.0, 1.0);
		col *= 0.42 + 0.78 * lit;
		col += vec3(1.0, 0.55, 0.3) * pow(1.0 - view_n.z, 3.0) * 0.35;
		COLOR = vec4(col, 1.0);
	}
}
