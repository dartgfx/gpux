#version 450

layout(location = 0) out vec4 color;

void main() {
#ifdef USE_WARM_COLOR
  color = vec4(COLOR_R, 0.25, 0.0, 1.0);
#else
  color = vec4(COLOR_R, 0.0, 0.0, 1.0);
#endif
}
