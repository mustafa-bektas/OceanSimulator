# Ocean

**by Mustafa Bektaş**

An exploration of ocean surface rendering techniques

![Ocean Demo](demo/demo.gif)

## Features

**Sum Of Sines Fluid Simulation** (from GPU Gems)
- Sine Wave

**FBM Fluid Simulation**
- Exponential Gerstner-style wave

**Analytical and Derivative Normals For Both**

**Basic "PBR" Water Shader**
- Blinn Phong
- Fresnel Reflectance
- Cubemap Reflections

**Water Drag Effect** (Waves affect each others' positions)

## What's Missing?

- Fast Fourier Transform Fluid Simulation
- Buoyancy
- Wakes and other water interactions

## References

- https://developer.nvidia.com/gpugems/gpugems/part-i-natural-effects/chapter-1-effective-water-simulation-physical-models
- https://iquilezles.org/articles/fbm/
- https://www.shadertoy.com/view/MdXyzX
- http://filmicworlds.com/blog/everything-has-fresnel/
- https://boksajak.github.io/files/CrashCourseBRDF.pdf
