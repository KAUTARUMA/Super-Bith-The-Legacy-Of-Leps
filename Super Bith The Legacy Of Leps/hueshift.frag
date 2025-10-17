#version 120

uniform sampler2D iChannel0;
uniform float shift_amount = 0.0;

#define PI 3.14159265358979323846

vec4 shift_hue(in vec4 color, in float shift) {
	// The unit gray vector in RGB color space.
	vec3 gray = vec3(0.57735);

	// Project color onto gray axis.
	vec3 projection = gray * dot(gray, color.rgb);

	// Vector from gray axis to original color.
	vec3 U = color.rgb - projection;

	// Vector perpendicular to gray axis and U.
	vec3 V = cross(gray, U);

	// Rotate U and V around the gray axis.
	vec3 shifted = U * cos(shift * 2.0 * PI) + V * sin(shift * 2.0 * PI) + projection;

	return vec4(shifted, color.a);
}

void main()
{
    vec4 c = texture2D(iChannel0, gl_TexCoord[0].xy);

    gl_FragColor = shift_hue(c * gl_Color, shift_amount);
}