# mpv-config

A high quality MPV configuration for rendering traditional live TV, video disc formats, and modern streaming content. Beyond upscaling, the configuration includes optimizations for colorspace, dithering, debanding, motion interpolation, anti-ringing, and chroma reconstruction. FFmpeg's BWDIF filter is applied automatically to interlaced content such as broadcast TV and interlaced Blu-rays.

Tested on a **Mac Studio (M1 Max)** and **MacBook Air (M4)** with mpv v0.41.1, libplacebo v7.360.0, FFmpeg 8.0.1, and MoltenVK v1.4.1 on macOS Tahoe 26.3.

For a detailed write-up of the approach, benchmarks, and background reading, see: https://freetime.mikeconnelly.com/archives/5371


## Renderer

This configuration uses `vo=gpu-next`, mpv's libplacebo-based renderer (the default since mpv 0.41). On macOS, `gpu-api=vulkan` via MoltenVK is required — there is no native Metal backend in libplacebo, and OpenGL is deprecated on Apple platforms. MoltenVK translates Vulkan calls to Metal transparently.

Linux and Windows users should also use `gpu-api=vulkan`. Windows users experiencing issues can fall back to `gpu-api=d3d11`.

See: https://github.com/mpv-player/mpv/wiki/GPU-Next-vs-GPU


## Installation

On macOS, place all files in:

```
~/.config/mpv/
```

The shaders should go in:

```
~/.config/mpv/shaders/
```

On Windows, the config folder is `%APPDATA%\mpv\`. On Linux, `~/.config/mpv/`.


## Files

| File | Purpose |
|------|---------|
| `mpv.conf` | Main configuration |
| `shaders/ArtCNN_C4F16.glsl` | Luma upscaling — 2x CNN doubler (primary, used by default) |
| `shaders/ArtCNN_C4F32.glsl` | Luma upscaling — 2x CNN doubler (higher quality; commented out) |
| `shaders/ravu-zoom-ar-r3.hook` | Luma upscaling — arbitrary ratio for 720p and SD content |
| `shaders/ravu-lite-ar-r4.hook` | Luma upscaling — lighter 2x doubler fallback (commented out) |
| `shaders/CfL_Prediction.glsl` | Chroma upscaling — luma-correlated reconstruction (primary) |
| `shaders/CfL_Prediction_Lite.glsl` | Chroma upscaling — lighter alternative (commented out) |
| `shaders/SSimDownscaler.glsl` | Luma downscaling — perceptual downscaler (optional; see note in config) |
| `shaders/SSimSuperRes.glsl` | Luma upscaling correction — removes ringing from built-in scalers (optional) |
| `shaders/adaptive-sharpen.glsl` | Post-processing — adaptive sharpening (optional) |
| `shaders/filmgrain.glsl` | Post-processing — synthetic film grain (optional) |

> **Note on removed shaders:** `FSRCNNX_x2_8-0-4-1.glsl` and `KrigBilateral.glsl` were removed from this repository. FSRCNNX has been superseded by ArtCNN for luma upscaling — it produces more ringing at comparable performance. KrigBilateral has been superseded by CfL_Prediction for chroma upscaling, which benchmarks significantly higher and avoids chromaloc issues. See the [upscaler analysis](https://artoriuz.github.io/blog/mpv_upscaling.html) for details.


## Upscaling Strategy

All profiles follow a single principle: **highest quality upscale in the fewest passes, preferring a single upscale to the output resolution where possible.**

Two shader strategies are used depending on the source resolution:

**ArtCNN_C4F16** is a fixed 2x CNN luma doubler. It is used when the source height multiplied by 2 equals the display height — i.e. a clean 2x relationship exists (e.g. 1080p → 4K). It performs the entire upscale in one pass and activates only when the scale factor exceeds 1.3x.

**ravu-zoom-ar-r3** is an arbitrary-ratio upscaler. It is used when no clean 2x relationship exists (e.g. 720p → 4K, or any SD content). It scales directly to the output resolution in a single pass, avoiding the two-step chain that would result from applying a 2x doubler first and then rescaling the remainder.

**CfL_Prediction** handles chroma reconstruction for all YUV 4:2:0 content, regardless of luma shader. It infers chroma from luma correlation, which is more accurate than conventional bilinear chroma upscaling.

The `scale=ewa_lanczos` and `dscale=catmull_rom` fallbacks handle content that does not match any profile, the final RGB output pass, and situations where ArtCNN's 1.3x threshold is not reached (e.g. 1080p on a non-4K display like the MacBook Air's 2560×1664 panel).

For a detailed mathematical analysis of these upscalers: https://artoriuz.github.io/blog/mpv_upscaling.html


## Conditional Profiles

The configuration uses mpv's built-in conditional profiles (`profile-cond`) — no external scripts like `auto-profiles.lua` are required. Profiles are matched automatically based on source resolution and frame rate:

| Profile | Source | Notes |
|---------|--------|-------|
| `4k60` | 2160p ≥ 31fps | No upscaling or interpolation needed |
| `4k30` | 2160p < 31fps | Common for camera footage and streaming |
| `full-hd60` | 1080p progressive ≥ 31fps | Progressive ATSC broadcast |
| `full-hd30` | 1080p progressive < 31fps | Blu-ray, NextGen TV/ATSC 3.0 |
| `full-hd-interlaced` | 1080i | HDTV, interlaced Blu-rays; BWDIF applied |
| `hd` | 720p | HDTV, Blu-ray |
| `sdtv-ntsc` | 480p/480i | NTSC DVD; BWDIF applied |
| `sdtv-pal` | 576p/576i | PAL broadcast and DVD; BWDIF applied |


## Self-Service Configuration

A dedicated section at the top of `mpv.conf` consolidates the settings most likely to need adjustment for different hardware or display configurations. These are the only lines most users should need to change:

- **GPU API** — `vulkan` for macOS/Linux/Windows; `d3d11` for Windows fallback
- **Display geometry** — `autofit=100%` by default (adapts to any display); optionally override with `geometry=3840x2160` for a dedicated 4K display
- **HiDPI scaling** — `no-hidpi-window-scale` for macOS; remove on other platforms
- **Refresh rate** — `display-fps-override=60`; change to match your display (120, 240, etc.)
- **Subtitle font** — `SFProRounded-Medium` for macOS; replace or remove on other platforms
- **Shader tier** — comments in each profile indicate lighter fallback shaders if your GPU cannot sustain the defaults


## Performance Notes

Shader cost scales with both GPU capability and output resolution. On lower-powered hardware, the CfL and ArtCNN shaders can be replaced with their `_Lite` variants, or with `ravu-lite-ar-r4` for luma upscaling. The comments in each profile show the exact substitution.

The M1 Max and M4 handle all shaders in this configuration at 4K/60fps without dropped frames. Performance on other hardware will vary. If you experience frame drops, check mpv's on-screen stats (`i` key, then `2` for shader info) to identify the bottleneck.


## Non-macOS Users

The core rendering pipeline (`vo=gpu-next`, `gpu-api=vulkan`, conditional profiles, and all shaders) is platform-agnostic and will work on Linux and Windows. The following settings are macOS-specific and should be removed or replaced on other platforms:

- `no-hidpi-window-scale`
- `macos-title-bar-appearance`
- `macos-title-bar-material`
- `macos-fs-animation-duration`
- `sub-font="SFProRounded-Medium"` — replace with a font available on your system

HDR passthrough (`target-colorspace-hint`) and ICC profile settings are commented out in the config with guidance on when to enable them. These are particularly relevant for Windows and Linux users with HDR-capable displays.


## References

- MPV options reference: https://github.com/mpv-player/mpv/blob/master/DOCS/man/options.rst
- GPU-Next vs GPU: https://github.com/mpv-player/mpv/wiki/GPU-Next-vs-GPU
- Video output shader stage diagram: https://github.com/mpv-player/mpv/wiki/Video-output---shader-stage-diagram
- Upscaler analysis and benchmarks: https://artoriuz.github.io/blog/mpv_upscaling.html
- Configuration write-up and background: https://freetime.mikeconnelly.com/archives/5371
