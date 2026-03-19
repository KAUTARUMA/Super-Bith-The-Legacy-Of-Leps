#version 120

uniform sampler2D iChannel0;
uniform float u_colorFactor = 0.0;


void main()
{
	vec4 sample = texture2D(iChannel0, gl_TexCoord[0].xy);
	float grey = 0.21 * sample.r + 0.71 * sample.g + 0.07 * sample.b;
	gl_FragColor = vec4(sample.r * u_colorFactor + grey * (1.0 - u_colorFactor), sample.g * u_colorFactor + grey * (1.0 - u_colorFactor), sample.b * u_colorFactor + grey * (1.0 - u_colorFactor), 1.0);
}
