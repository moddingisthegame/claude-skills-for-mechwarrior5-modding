# UE5 rendering — Lumen, Nanite, Virtual Shadow Maps, materials

Sources: Epic UE5 docs (`lumen-global-illumination-and-reflections-in-unreal-engine`
pinned to 5.5; `nanite-virtualized-geometry-in-unreal-engine` — see the Nanite
version caveat below), cross-checked against
`MW5Clans/Config/DefaultEngine.ini` in the installed Clans Editor.

## What Clans actually ships

These are literal lines from `Config/DefaultEngine.ini`. They are the ground
truth for any "how does Clans render X" question:

```ini
; Global illumination and reflections
r.ReflectionMethod=2                   ; Lumen
r.Lumen.HardwareRayTracing=False       ; software ray tracing only
r.RayTracing=False
r.RayTracing.HybridTranslucencySupport=True
r.Lumen.TraceMeshSDFs=0                ; Global Tracing, not Detail Tracing
r.GenerateMeshDistanceFields=True      ; prerequisite for Lumen software tracing
r.LumenScene.DirectLighting.MaxLightsPerTile=4
r.Lumen.Reflection.MaxRoughnessToTrace=0.2
r.Lumen.Reflections.RadianceCache=1
r.ReflectionCaptureResolution=64

; Shadows and textures
r.Shadow.Virtual.Enable=1              ; Virtual Shadow Maps
r.VirtualTextures=True

; Nanite
r.Nanite.Streaming.Imposters=0

; Post-process defaults, all off
r.DefaultFeature.Bloom=False
r.DefaultFeature.AmbientOcclusion=False
r.DefaultFeature.AutoExposure=False
r.DefaultFeature.MotionBlur=False
r.DefaultFeature.AutoExposure.ExtendDefaultLuminanceRange=True
r.DefaultFeature.AutoExposure.Bias=1.000000

; Skin cache
r.SkinCache.CompileShaders=True
```

Reading these together: Clans is a **fully dynamic, software-Lumen,
Virtual-Shadow-Map** project with post-process defaults deliberately disabled
(so effects come from Post Process Volumes, not engine defaults) and **no
hardware ray tracing anywhere**.

## Lumen

**Lumen** is UE5's "fully dynamic global illumination and reflections system,"
rendering diffuse interreflection with infinite bounces plus indirect specular
across large environments.

### The consequence that matters most to modders

Epic states that enabling Lumen **disables precomputed static lighting and
hides all lightmaps**, and that **static lights are not supported** (they get
stored in the disabled lightmaps).

For a modder coming from Mercs this is a hard break:

- **There is no "Build Lighting" step.** No Lightmass, no bake, no waiting.
- **Lightmap UVs on imported meshes do not drive direct lighting.** Do not
  spend effort on lightmap UV density for that reason. *(They may still matter
  for other systems — unverified.)*
- **Static light mobility is effectively unavailable.** Use Stationary or
  Movable.

### Software vs Hardware Ray Tracing

| Mode | How it traces | Clans |
|---|---|---|
| **Software** | against **mesh distance fields**; needs `Generate Mesh Distance Fields` | **this is what Clans uses** |
| **Hardware** | uses the GPU's RT cores; higher quality, but costly above ~100,000 instances | disabled (`r.Lumen.HardwareRayTracing=False`, `r.RayTracing=False`) |

Software mode itself has two sub-options, and Clans picks the cheaper one:

- **Detail Tracing** — traces individual mesh distance fields, higher quality.
- **Global Tracing** — uses a lower-detail **global** distance field, faster.

`r.Lumen.TraceMeshSDFs=0` selects Global Tracing. **Expect softer and less
precise indirect lighting on small or thin geometry than a default UE5 project
gives you.** If a modder reports that a small object isn't bouncing light
convincingly, this setting is the reason, and it is a project-wide decision
rather than a bug in their asset.

`r.Lumen.Reflection.MaxRoughnessToTrace=0.2` similarly means Lumen only traces
reflections on fairly sharp surfaces; rougher materials fall back to cheaper
approximations.

### Lumen's documented limitations

- Static lights unsupported (above).
- **Clear coat** materials support low roughness only on the top layer; bottom
  layers appear glossy regardless.
- Small, bright **emissive** areas can produce noise artifacts — relevant for
  mech cockpit displays and weapon glow.
- **Global lighting changes propagate slowly** (multiple seconds) compared to
  local changes.

## Nanite

> **Version caveat, read this first.** Epic's current Nanite page serves
> **UE 5.8** content, and the `?application_version=5.5` pin did not hold when
> this file was written. The facts below are from that 5.8 page. Core Nanite
> behavior has been stable since 5.0, but **the supported-mesh-type list in
> particular expanded after 5.5** — Nanite skeletal mesh support was not
> production-ready in 5.5. Treat the mesh-type list as **`[verify in 5.5]`**
> and do not promise a Clans modder that Nanite skeletal meshes work.

**Enabling it on a static mesh**, three ways:

1. Check **Build Nanite** in the FBX import options.
2. In the Static Mesh Editor, under Nanite Settings, enable **Enable Nanite
   Support**.
3. Select meshes in the Content Browser, right-click → **Nanite → Enable**.

**Material limitations** — these are the ones that bite:

- **Only `Opaque` and `Masked` blend modes are supported.** When an
  unsupported material is detected, "a default material is assigned to the
  mesh along with a warning." If a modder's Nanite mesh renders as grey
  checkerboard, this is almost always why.
- **Translucent blend mode is unsupported**, and **mesh decals are not
  supported** on Nanite geometry.
- **Wireframe rendering is unsupported.**
- **World Position Offset has limited support** — meshes using WPO
  displacement get split into smaller clusters, so heavy WPO costs
  performance.
- **Per-vertex tangents are not stored**; tangent space is derived in the
  pixel shader. Custom expression nodes may produce artifacts because they
  lack analytic derivative support.

`r.Nanite.Streaming.Imposters=0` in Clans disables Nanite imposter streaming —
a memory/quality trade PGI made project-wide.

## Virtual Shadow Maps and Virtual Textures

Both are on (`r.Shadow.Virtual.Enable=1`, `r.VirtualTextures=True`).

**Virtual Shadow Maps** are the UE5 shadowing path designed to pair with
Nanite, giving consistent high-resolution shadows without the cascade seams
UE4's CSM produced. Practical note: VSM cost scales with the number of
shadow-casting lights and with geometry that invalidates cached shadow pages —
**moving lights and WPO materials are the expensive cases.**

**Virtual Textures** stream texture data on demand. The project also defines a
`[/Script/Engine.VirtualTexturePoolConfig]` section. A modder importing very
large textures should know that VT changes the streaming behavior but does not
remove the memory cost of the source asset.

## Material Instances — unchanged from UE4

This part did not change, and Mercs knowledge transfers:

- A **Material Instance Constant** is a child of a parent Material exposing
  only the parameters the parent chose to expose.
- Editing an instance does **not** trigger a shader recompile; editing the
  parent Material does, for every instance.
- Prefer instancing over duplicating a material graph.

The UE5 additions worth knowing are **Substrate** (a newer material
architecture) — **not enabled in this project**, so do not reference it — and
the Nanite tangent/derivative caveats above.
